import ballerina/workflow;

# Validates an expense claim against the expense policy.
#
# + claim - The submitted claim
# + return - `true` when the claim is claimable, or an error
@workflow:Activity
function validateClaim(ExpenseClaim claim) returns boolean|error {
    return claim.amount > 0d && claim.purpose.trim().length() > 0;
}

# Pays the reimbursement through the payroll system.
#
# + claimId - The claim being reimbursed
# + amount - Amount to pay
# + return - The payment reference, or an error
@workflow:Activity
function processReimbursement(string claimId, decimal amount) returns string|error {
    return string `PAY-${claimId}`;
}

# Notifies the employee of the outcome.
#
# + claimId - The claim identifier
# + message - The notification text
# + return - A delivery reference, or an error
@workflow:Activity
function notifyEmployee(string claimId, string message) returns string|error {
    return string `NOTIF-${claimId}`;
}

# Checks the submitted bills against the claim: at least one bill, and the billed
# total must match the claimed amount.
#
# + claim - The original claim
# + submission - The submitted bills
# + return - `true` when the bills support the claim, or an error
@workflow:Activity
function validateBills(ExpenseClaim claim, BillSubmission submission) returns boolean|error {
    if submission.bills.length() == 0 {
        return false;
    }
    decimal total = 0;
    foreach Bill bill in submission.bills {
        total += bill.amount;
    }
    return total == claim.amount;
}
