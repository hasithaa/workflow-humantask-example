# md: ### Scenario 2 — Bills included upfront (the agent skips the bill request)
# md:
# md: The claim already carries its bills, so the agent validates them right away —
# md: no `requestBill` notification, no waiting on the channel. Only the gated
# md: payment review remains (**ICP inbox**).
# md:
# md: Run with `hurl --interactive scenario-2-bills-upfront.hurl`.

# md: #### POST / — submit the claim WITH bills

POST http://localhost:9098/expenses/
Content-Type: application/json

{
  "claimId": "EXP-A102",
  "employee": "nimal",
  "amount": 95.00,
  "currency": "EUR",
  "purpose": "Office supplies",
  "bills": [
    {
      "reference": "BILL-21",
      "amount": 95.00
    }
  ]
}

# md: > In the ICP inbox: approve the gated makePayment review.

# md: #### GET /{claimId} — COMPLETED (PENDING_APPROVAL while the review waits)

GET http://localhost:9098/expenses/EXP-A102
