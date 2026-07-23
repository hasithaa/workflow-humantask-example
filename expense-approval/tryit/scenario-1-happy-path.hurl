# md: ### Scenario 1 — Happy path (EUR claim, matching bills, approved)
# md:
# md: Flow: submit claim → **ICP: decide `checkExpenseRequest` = REQUEST_BILL** →
# md: submit matching bills → **ICP: decide `reviewBills` = approve** → APPROVED.
# md:
# md: Run with `hurl --interactive scenario-1-happy-path.hurl` and complete the
# md: ICP inbox task (role: manager, e.g. alice) before continuing past each step.

# md: #### POST / — submit the claim (starts the workflow)

POST http://localhost:9096/expenses/
Content-Type: application/json

{
  "claimId": "EXP-101",
  "employee": "nimal",
  "amount": 180.50,
  "currency": "EUR",
  "purpose": "Team lunch"
}

# md: #### GET /{claimId} — IN_REVIEW while checkExpenseRequest waits in the ICP inbox

GET http://localhost:9096/expenses/EXP-101

# md: > In the ICP inbox: decide `checkExpenseRequest` with action `REQUEST_BILL`.

# md: #### POST /{claimId}/bills — submit bills matching the claimed amount

POST http://localhost:9096/expenses/EXP-101/bills
Content-Type: application/json

{
  "bills": [
    {
      "reference": "BILL-9",
      "amount": 180.50
    }
  ]
}

# md: > In the ICP inbox: decide `reviewBills` (payload shows billsMatchClaim = true) — approve.

# md: #### GET /{claimId} — APPROVED with the payment reference

GET http://localhost:9096/expenses/EXP-101
