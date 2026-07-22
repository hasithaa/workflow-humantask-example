import ballerina/workflow;

# Processes one expense claim: validate, wait for a manager's decision as a human
# task, then reimburse and notify.
#
# + ctx - The workflow context
# + claim - The submitted claim
# + return - The final outcome, or an error
@workflow:Workflow
function expenseApprovalWorkflow(workflow:Context ctx, ExpenseClaim claim) returns ExpenseResult|error {
    boolean valid = check ctx->callActivity(validateClaim, {"claim": claim});
    if !valid {
        return {claimId: claim.claimId, status: "INVALID"};
    } else {

        ApprovalDecision decision = check ctx->awaitHumanTask("approveExpense", "manager",
            payload = {
            "claimId": claim.claimId,
            "employee": claim.employee,
            "amount": claim.amount,
            "purpose": claim.purpose
        },
            title = string `Approve expense claim ${claim.claimId}`,
            description = "Review the claim details and approve or reject the reimbursement.",
            timeout = {days: 3});

        if !decision.approved {
            string _ = check ctx->callActivity(notifyEmployee,
                {"claimId": claim.claimId, "message": string `Claim rejected: ${decision.comment}`});
            return {claimId: claim.claimId, status: "REJECTED"};
        } else {

            string paymentRef = check ctx->callActivity(processReimbursement,
            {"claimId": claim.claimId, "amount": claim.amount});
            string _ = check ctx->callActivity(notifyEmployee,
            {"claimId": claim.claimId, "message": string `Claim approved and paid: ${paymentRef}`});
            return {claimId: claim.claimId, status: "APPROVED", paymentRef};
        }
    }
}
