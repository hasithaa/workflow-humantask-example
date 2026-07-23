# md: ### Scenario 1 — Happy path (no bills at first; the agent asks for them)
# md:
# md: Flow: submit claim without bills → the agent calls `requestBill` (see the
# md: service log) and waits on the `billSubmitted` channel → submit matching
# md: bills → the agent validates them, gets the gated payment approved
# md: (**ICP: reimbursement review**) and completes.
# md:
# md: Run with `hurl --interactive scenario-1-happy-path.hurl` and complete the
# md: ICP inbox reviews (role: manager, e.g. alice) before continuing past each step.

# md: #### POST / — submit the claim (no bills)

POST http://localhost:9098/expenses/
Content-Type: application/json

{
  "claimId": "EXP-A101",
  "employee": "nimal",
  "amount": 180.50,
  "currency": "EUR",
  "purpose": "Team lunch"
}

HTTP 201
[Captures]
instanceId: jsonpath "$.instanceId"

# md: > Watch the service log: the agent's `requestBill` notification asks for the bills.

# md: #### POST /{instanceId}/bills — matching bills on the agent's billSubmitted channel

POST http://localhost:9098/expenses/{{instanceId}}/bills
Content-Type: application/json

{
  "bills": [
    {
      "reference": "BILL-9",
      "amount": 180.50
    }
  ]
}

# md: > In the ICP inbox: approve the gated makePayment review when it appears.

# md: #### GET /{instanceId} — COMPLETED with the agent's summary (PENDING_APPROVAL while waiting)

GET http://localhost:9098/expenses/{{instanceId}}
