import ballerina/workflow;

# Processes one expense claim with two manager reviews: first the request check
# (ask for the supporting bills, or reject), then — once the employee submits the
# bills as a data event — the bill review that decides the reimbursement.
#
# + ctx - The workflow context
# + claim - The submitted claim
# + dataEvents - Futures for the data events this workflow waits on
# + return - The final outcome, or an error
@workflow:Workflow
function expenseApprovalWorkflow(workflow:Context ctx, ExpenseClaim claim,
        record {|future<BillSubmission> billSubmitted;|} dataEvents) returns ExpenseResult|error {
    boolean valid = check ctx->callActivity(validateClaim, {"claim": claim});
    if !valid {
        return {claimId: claim.claimId, status: "INVALID"};
    }

    RequestDecision request = check ctx->awaitHumanTask("checkExpenseRequest", "manager",
            payload = {"claimId": claim.claimId, "employee": claim.employee,
                "amount": claim.amount, "purpose": claim.purpose},
            title = string `Check expense request ${claim.claimId}`,
            description = "Review the new claim: request the supporting bills, or reject it.",
            timeout = {days: 3});
    if request.action == "REJECT" {
        string _ = check ctx->callActivity(notifyEmployee,
                {"claimId": claim.claimId, "message": string `Claim rejected: ${request.comment}`});
        return {claimId: claim.claimId, status: "REJECTED"};
    }

    string _ = check ctx->callActivity(notifyEmployee,
            {"claimId": claim.claimId, "message": "Please submit the supporting bills for your claim."});
    BillSubmission submission = check wait dataEvents.billSubmitted;
    boolean billsValid = check ctx->callActivity(validateBills,
            {"claim": claim, "submission": submission});

    ApprovalDecision decision = check ctx->awaitHumanTask("reviewBills", "manager",
            payload = {"claimId": claim.claimId, "amount": claim.amount,
                "billCount": submission.bills.length(), "billsMatchClaim": billsValid},
            title = string `Review bills for claim ${claim.claimId}`,
            description = "Verify the submitted bills and approve or reject the reimbursement.",
            timeout = {days: 3});
    if !decision.approved {
        string _ = check ctx->callActivity(notifyEmployee,
                {"claimId": claim.claimId, "message": string `Claim rejected: ${decision.comment}`});
        return {claimId: claim.claimId, status: "REJECTED"};
    }

    string paymentRef = check ctx->callActivity(processReimbursement,
            {"claimId": claim.claimId, "amount": claim.amount});
    string _ = check ctx->callActivity(notifyEmployee,
            {"claimId": claim.claimId, "message": string `Claim approved and paid: ${paymentRef}`});
    return {claimId: claim.claimId, status: "APPROVED", paymentRef};
}
