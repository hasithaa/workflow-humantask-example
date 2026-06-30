# Workflow Human-Task Example

A small [Ballerina](https://ballerina.io) demo built on the
[`ballerina/workflow`](https://github.com/ballerina-platform/module-ballerina-workflow)
package (0.5.x) that shows the **human-in-the-loop** pattern: when an automated
step fails, a durable workflow pauses and waits for a human to decide what to do
next.

## Scenario

A service accepts shipping requests and forwards them to a downstream shipping
service.

- **Happy path** — the shipping service succeeds and the caller immediately gets
  a `PROCESSED` acknowledgement.
- **Failure path** — the shipping service errors, so a durable workflow
  (`reviewErrorTaskProcess`) is started. It raises a **human task** for a
  `reviewer`, who decides whether to retry. The caller gets a `PENDING`
  acknowledgement carrying the workflow id as `ref`.
  - Reviewer **approves retry** → the shipping call is re-attempted as a durable
    activity (with a manual-retry task on failure) → `PROCESSED`.
  - Reviewer **declines** → the order is acknowledged as `FAILED`.

```
                 POST /processShippingRequest
                            │
                            ▼
                  call shipping service ──── success ──▶ 200 { status: PROCESSED }
                            │
                          failure
                            │
                            ▼
                  workflow:run(reviewErrorTaskProcess)  ──▶ 200 { status: PENDING, ref: <workflowId> }
                            │
                            ▼
                  ctx->awaitHumanTask("reviewErrorTask", "reviewer")   ⏸  (durable wait)
                            │
        reviewer completes the task via the management API
                            │
            ┌───────────────┴────────────────┐
      retryMessage = true              retryMessage = false
            │                                 │
            ▼                                 ▼
   callActivity(callShippingService)   sendShippingAcknolegement(FAILED)
   retryPolicy = ManualRetry
            │
            ▼
   sendShippingAcknolegement(PROCESSED)
```

## Project layout

```
workflow/
├── Ballerina.toml          # package manifest
├── Config.toml             # runtime mode for `bal run` (IN_MEMORY)
├── main.bal                # HTTP service that starts the workflow on failure
├── functions.bal           # @Workflow + @Activity definitions
├── connections.bal         # HTTP client to the downstream shipping service
├── types.bal               # records / enums
└── tests/
    ├── Config.toml         # runtime mode for `bal test` (IN_MEMORY)
    ├── shipping_mock.bal    # mock shipping service on :9000
    └── workflow_test.bal    # workflow + human-task tests
```

## Key `ballerina/workflow` APIs used

| API | Purpose |
| --- | --- |
| `@workflow:Workflow` | Marks `reviewErrorTaskProcess` as a durable workflow. |
| `@workflow:Activity` | Marks `callShippingService` / `sendShippingAcknolegement` as activities. |
| `workflow:run(fn, input)` | Starts an instance; returns the workflow id (a `string`). |
| `ctx->awaitHumanTask(name, roles, payload=…)` | Durably blocks until a human completes the task. |
| `ctx->callActivity(fn, args, T, retryPolicy)` | Runs an activity exactly-once; `workflow:ManualRetry` creates a retry task on failure. |
| `workflow:getWorkflowResult(id, timeout)` | Fetches the completed workflow's result. |

## Running the demo

The workflow runtime is configured in `IN_MEMORY` mode (see `Config.toml`), so
**no external workflow server is required**.

```bash
cd workflow
bal run
```

This starts two listeners:

- the application service on **:8080** (`POST /processShippingRequest`)
- the **management API** on **:8234** (base path `/workflow`), enabled by
  `import ballerina/workflow.management`.

Trigger the failure path (no real shipping service is running, so the call
fails and a workflow is started):

```bash
curl -s -X POST http://localhost:8080/processShippingRequest \
  -H 'Content-Type: application/json' \
  -d '{"orderId":"ORD-1","customerId":"CUST-1","shippingAddress":"1 Main St"}'
# → {"orderId":"ORD-1","status":"PENDING","ref":"<workflowId>"}
```

### Management API (backend for the future UI)

The management module exposes the human-task endpoints the UI will consume:

| Method & path | Description |
| --- | --- |
| `GET /workflow/human-tasks` | List human tasks (role-filtered). |
| `GET /workflow/human-tasks/{taskId}` | Task details + payload. |
| `POST /workflow/human-tasks/{taskId}/complete` | Complete a task with a result. |
| `POST /workflow/human-tasks/{taskId}/fail` | Reject a task. |
| `GET /workflow/workflows/{workflowId}` | Workflow execution info. |
| `GET /workflow/retry-tasks` | Manual retry tasks (from `ManualRetry`). |

Complete a pending review task (use the `ref`/workflow id from above to find the
`taskId`, then):

```bash
curl -s -X POST http://localhost:8234/workflow/human-tasks/<taskId>/complete \
  -H 'Content-Type: application/json' \
  -H 'x-user-roles: reviewer' \
  -d '{"result":{"retryMessage":true}}'
```

## Running the tests

```bash
cd workflow
bal test
```

The tests run entirely in-memory and cover:

- `testReviewerDeclinesRetry` — reviewer declines → workflow result is `FAILED`.
- `testReviewerApprovesRetryAndShippingSucceeds` — reviewer approves, the mocked
  shipping service succeeds on retry → result is `PROCESSED`.
- `testPendingHumanTaskIsListed` — the pending task is discoverable and its
  details are correct via the management API.

`tests/shipping_mock.bal` stands in for the downstream service: orders whose id
starts with `FAIL` return `500`, everything else succeeds.

## Human Task UI

A custom reviewer UI lives in [`humantask_ui/`](humantask_ui) — a Vite + React
SPA with a small backend-for-frontend (BFF) that authenticates users and injects
the `x-user-id` / `x-user-roles` headers the management API expects. It provides
three views: **Review Shipment Errors** (workflows → human tasks + failed
activities), **Review Tasks**, and **Failed Activities**. See its
[README](humantask_ui/README.md) for details.

### Running the full demo (workflow app + management API + UI)

The UI's list endpoints need a real backend, so run the workflow app in `LOCAL`
mode against a Temporal dev server. `workflow/Config.local.toml` enables `LOCAL`
mode, the management API, and (for the demo) disables management-side auth so the
BFF can reach it.

```bash
# 1. Temporal dev server (provides the workflow backend on :7233)
temporal server start-dev

# 2. Workflow app + management API (:8080 app, :8234 management)
cd workflow
BAL_CONFIG_FILES=Config.local.toml bal run

# 3. Reviewer UI (BFF on :3001, web on :5173)
cd humantask_ui
npm install
npm run dev
```

Then trigger a few failing shipping requests (no real shipping service is
running, so each starts a review workflow):

```bash
curl -s -X POST http://localhost:8080/processShippingRequest \
  -H 'Content-Type: application/json' \
  -d '{"orderId":"ORD-1","customerId":"CUST-1","shippingAddress":"1 Main St"}'
```

Open http://localhost:5173 and sign in as `alice` / `alice123`.

> **Note:** `IN_MEMORY` mode (the default `Config.toml`) is great for `bal run`
> curl demos and tests, but its global list endpoints are not implemented, so the
> UI requires `LOCAL`/`SELF_HOSTED` mode as above.
