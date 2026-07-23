# Expense approval — durable workflow with a human task

A plain durable workflow demonstrating **human tasks**: the workflow validates an
expense claim, then durably suspends on `ctx->awaitHumanTask("approveExpense",
"manager", ...)` — for up to three days — until a manager submits an
`ApprovalDecision`, then reimburses and notifies.

The task payload (claim details) renders next to the approval form, and the
typed result drives the form schema. The workflow survives restarts while
suspended.

## Run

```sh
temporal server start-dev   # in another terminal
bal run
```

```sh
# 1. Submit a claim (starts the approval workflow)
curl -X POST localhost:9096/expenses -H 'Content-Type: application/json' \
  -d '{"claimId":"EXP-1","employee":"nimal","amount":180.50,"purpose":"Team lunch"}'

# 2. Approve (or reject) the pending approveExpense task. Complete it from the ICP
#    task inbox (role: manager, e.g. alice), or via the API using the task workflow ID
#    shown in the inbox / Temporal UI:
curl -X POST localhost:9096/expenses/tasks/<taskWorkflowId> -H 'Content-Type: application/json' \
  -d '{"approved":true,"comment":"ok"}'

# 3. Read the outcome (PENDING_APPROVAL until the manager decides)
curl localhost:9096/expenses/EXP-1
```

## Requirements

- `ballerina/workflow` **0.8.0** in the **local** repository.
- Temporal dev server on `localhost:7233`.
