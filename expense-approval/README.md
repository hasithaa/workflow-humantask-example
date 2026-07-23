# Expense approval — durable workflow with two human tasks

A plain durable workflow with **two manager reviews**, both decided in the ICP
task inbox:

1. `checkExpenseRequest` — triage the new claim: request the supporting bills,
   or reject it.
2. After the employee submits the bills (a `billSubmitted` **data event**), the
   workflow validates them (`validateBills`: at least one bill, billed total
   matches the claim) and creates `reviewBills` — approve to reimburse, or
   reject.

The workflow durably suspends on each task and on the bill submission for as
long as they take, surviving restarts. Human tasks are completed through the
ICP UI — the service exposes no task-completion API.

## Run

```sh
temporal server start-dev   # in another terminal
cp Config.toml.back Config.toml   # fill in the ICP runtime secret
bal run
```

```sh
# 1. Submit a claim (starts the workflow)
curl -X POST localhost:9096/expenses -H 'Content-Type: application/json' \
  -d '{"claimId":"EXP-1","employee":"nimal","amount":180.50,"purpose":"Team lunch"}'

# 2. In the ICP task inbox (role: manager, e.g. alice), decide checkExpenseRequest:
#    choose action REQUEST_BILL (or REJECT to end the claim)

# 3. Submit the supporting bills (delivered to the waiting workflow as a data event)
curl -X POST localhost:9096/expenses/EXP-1/bills -H 'Content-Type: application/json' \
  -d '{"bills":[{"reference":"BILL-9","amount":180.50}]}'

# 4. In the ICP task inbox, decide reviewBills: approve to reimburse, or reject

# 5. Read the outcome (IN_REVIEW while a task or the bills are pending)
curl localhost:9096/expenses/EXP-1
```

## Requirements

- `ballerina/workflow` **0.8.0** and `wso2/icp.runtime.bridge` in the **local** repository.
- Temporal dev server on `localhost:7233`.
- ICP running with a `manager`-role user (see the repository README).
