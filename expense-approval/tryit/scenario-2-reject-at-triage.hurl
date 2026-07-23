# md: ### Scenario 2 — Rejected at triage (manager rejects the request check)
# md:
# md: Flow: submit claim → **ICP: decide `checkExpenseRequest` = REJECT** → REJECTED.
# md: The employee is notified and the workflow ends; no bills are ever requested.
# md:
# md: Run with `hurl --interactive scenario-2-reject-at-triage.hurl`.

# md: #### POST / — submit the claim

POST http://localhost:9096/expenses/
Content-Type: application/json

{
  "claimId": "EXP-102",
  "employee": "nimal",
  "amount": 950.00,
  "currency": "EUR",
  "purpose": "Conference tickets"
}

HTTP 201
[Captures]
workflowId: jsonpath "$.workflowId"

# md: > In the ICP inbox: decide `checkExpenseRequest` with action `REJECT` and a comment.

# md: #### GET /{workflowId} — REJECTED

GET http://localhost:9096/expenses/{{workflowId}}
