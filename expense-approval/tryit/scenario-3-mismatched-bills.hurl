# md: ### Scenario 3 — Mismatched bills (billed total ≠ claimed amount)
# md:
# md: Flow: submit claim for 180.50 → **ICP: REQUEST_BILL** → submit bills totalling
# md: 120.00 → the `reviewBills` task payload shows `billsMatchClaim: false` so the
# md: manager can reject with a reason → REJECTED.
# md:
# md: Run with `hurl --interactive scenario-3-mismatched-bills.hurl`.

# md: #### POST / — submit the claim

POST http://localhost:9096/expenses/
Content-Type: application/json

{
  "claimId": "EXP-103",
  "employee": "nimal",
  "amount": 180.50,
  "currency": "EUR",
  "purpose": "Team lunch"
}

# md: > In the ICP inbox: decide `checkExpenseRequest` with action `REQUEST_BILL`.

# md: #### POST /{claimId}/bills — bills do NOT add up to the claim

POST http://localhost:9096/expenses/EXP-103/bills
Content-Type: application/json

{
  "bills": [
    {
      "reference": "BILL-7",
      "amount": 120.00
    }
  ]
}

# md: > In the ICP inbox: `reviewBills` shows billsMatchClaim = false — reject with a comment.

# md: #### GET /{claimId} — REJECTED

GET http://localhost:9096/expenses/EXP-103
