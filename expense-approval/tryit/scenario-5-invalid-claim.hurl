# md: ### Scenario 5 — Invalid claim (fails validation, no human task)
# md:
# md: `validateClaim` rejects non-positive amounts and empty purposes; the workflow
# md: ends immediately with INVALID and never reaches the manager.
# md:
# md: Run with `hurl scenario-5-invalid-claim.hurl` (no ICP steps needed).

# md: #### POST / — submit a claim with amount 0

POST http://localhost:9096/expenses/
Content-Type: application/json

{
  "claimId": "EXP-105",
  "employee": "nimal",
  "amount": 0,
  "currency": "EUR",
  "purpose": "Misc"
}

HTTP 201
[Captures]
workflowId: jsonpath "$.workflowId"

# md: #### GET /{workflowId} — INVALID

GET http://localhost:9096/expenses/{{workflowId}}
