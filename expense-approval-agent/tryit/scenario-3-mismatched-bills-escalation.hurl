# md: ### Scenario 3 — Mismatched bills: the agent escalates to the human task
# md:
# md: The billed total (120.00) does not match the claim (180.50). `validateBills`
# md: fails, so the agent escalates to its single `approveExpense` human task —
# md: the one place a manager decides in this example beyond the gated payment.
# md:
# md: Flow: submit claim → agent asks for bills → submit mismatching bills →
# md: **ICP: decide `approveExpense`** → the agent follows the decision.
# md:
# md: Run with `hurl --interactive scenario-3-mismatched-bills-escalation.hurl`.

# md: #### POST / — submit the claim (no bills)

POST http://localhost:9098/expenses/
Content-Type: application/json

{
  "claimId": "EXP-A103",
  "employee": "nimal",
  "amount": 180.50,
  "currency": "EUR",
  "purpose": "Team lunch"
}

HTTP 201
[Captures]
instanceId: jsonpath "$.instanceId"

# md: > Watch the service log for the agent's requestBill notification.

# md: #### POST /{instanceId}/bills — bills that do NOT match the claim

POST http://localhost:9098/expenses/{{instanceId}}/bills
Content-Type: application/json

{
  "bills": [
    {
      "reference": "BILL-7",
      "amount": 120.00
    }
  ]
}

# md: > In the ICP inbox: the agent escalates — decide `approveExpense` (approve or reject).

# md: #### GET /{instanceId} — the agent's outcome (PENDING_APPROVAL while the task waits)

GET http://localhost:9098/expenses/{{instanceId}}
