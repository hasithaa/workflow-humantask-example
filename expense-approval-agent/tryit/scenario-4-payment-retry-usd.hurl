# md: ### Scenario 4 — Payment failure and Human Review retry (USD claim)
# md:
# md: The gated `makePayment` carries a Human Review retry policy. After the
# md: manager approves the payment, the mock gateway rejects the USD currency and
# md: the failure becomes a **retry review task** in the ICP inbox — fix the
# md: inputs (e.g. currency) and retry instead of failing the run.
# md:
# md: Flow: submit USD claim with bills → **ICP: approve the gated payment** →
# md: payment fails → **ICP: retry review — fix the currency and retry** → done.
# md:
# md: Run with `hurl --interactive scenario-4-payment-retry-usd.hurl`.

# md: #### POST / — submit a USD claim with matching bills

POST http://localhost:9098/expenses/
Content-Type: application/json

{
  "claimId": "EXP-A104",
  "employee": "nimal",
  "amount": 250.00,
  "currency": "USD",
  "purpose": "Client dinner",
  "bills": [
    {
      "reference": "BILL-11",
      "amount": 250.00
    }
  ]
}

HTTP 201
[Captures]
instanceId: jsonpath "$.instanceId"

# md: > In the ICP inbox: approve the gated makePayment review. The gateway then
# md: > rejects the USD payment and a retry review task appears — correct the
# md: > currency (e.g. EUR) and retry from the ICP inbox.

# md: #### GET /{instanceId} — COMPLETED once the retried payment succeeds

GET http://localhost:9098/expenses/{{instanceId}}
