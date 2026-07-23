# md: ### Scenario 4 — Payment failure and Human Review retry (USD claim)
# md:
# md: The mock payment gateway rejects USD (and LKR) payments. `makePayment` runs
# md: with a Human Review retry policy (`retryPolicy = "manager"`), so the failure
# md: becomes a **retry review task** in the ICP inbox instead of failing the
# md: workflow — the manager can fix the payment inputs (e.g. currency) and retry.
# md:
# md: Flow: submit USD claim → **ICP: REQUEST_BILL** → submit matching bills →
# md: **ICP: approve `reviewBills`** → payment fails → **ICP: retry review — fix
# md: the currency and retry** → APPROVED.
# md:
# md: Run with `hurl --interactive scenario-4-payment-retry-usd.hurl`.

# md: #### POST / — submit the claim in USD (the gateway will reject it)

POST http://localhost:9096/expenses/
Content-Type: application/json

{
  "claimId": "EXP-104",
  "employee": "nimal",
  "amount": 250.00,
  "currency": "USD",
  "purpose": "Client dinner"
}

# md: > In the ICP inbox: decide `checkExpenseRequest` with action `REQUEST_BILL`.

# md: #### POST /{claimId}/bills — matching bills

POST http://localhost:9096/expenses/EXP-104/bills
Content-Type: application/json

{
  "bills": [
    {
      "reference": "BILL-11",
      "amount": 250.00
    }
  ]
}

# md: > In the ICP inbox: approve `reviewBills`. makePayment now fails on the USD
# md: > currency and a retry review task appears — correct the currency (e.g. EUR)
# md: > and retry the activity from the ICP inbox.

# md: #### GET /{claimId} — APPROVED once the retried payment succeeds

GET http://localhost:9096/expenses/EXP-104
