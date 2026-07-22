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

Then drive it with the three `curl` commands the service prints: submit a claim,
complete the pending `approveExpense` task (task workflow IDs are visible in the
task inbox / Temporal UI), and read the outcome.

## Requirements

- `ballerina/workflow` **0.8.0** in the **local** repository.
- Temporal dev server on `localhost:7233`.
