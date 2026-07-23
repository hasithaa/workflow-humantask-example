# Expense approval agent — durable agentic workflow version

The same expense-approval logic as [`expense-approval`](../expense-approval/), but
driven by a **durable agentic workflow** instead of explicit control flow: the
`expenseAgent` declaration carries the activities (`validateClaim`,
`processReimbursement` gated by a manager review, `notifyEmployee`) and the
`approveExpense` human task, and the model decides the flow from the
instructions — validate, wait for the manager, reimburse or reject, notify.

Everything stays durable: the agent suspends on the human task/review for as
long as the manager takes, surviving restarts.

## Run

```sh
temporal server start-dev   # in another terminal
cp Config.toml.back Config.toml   # then fill in the secrets
bal run
```

```sh
# 1. Submit a claim
curl -X POST localhost:9098/expenses -H 'Content-Type: application/json' \
  -d '{"claimId":"EXP-A1","employee":"nimal","amount":180.50,"purpose":"Team lunch"}'

# 2. Decide the approveExpense task in the ICP inbox (role: manager, e.g. alice)

# 3. Read the outcome (PENDING_APPROVAL while the manager decides)
curl localhost:9098/expenses/EXP-A1
```

## Requirements

- `ballerina/workflow` **0.8.0** and `wso2/icp.runtime.bridge` in the **local** repository.
- Temporal dev server on `localhost:7233`.
- WSO2 model provider credentials and the ICP runtime secret in `Config.toml`.
