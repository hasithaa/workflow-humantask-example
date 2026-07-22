# An expense claim submitted by an employee.
#
# + claimId - Unique identifier of the claim
# + employee - Employee submitting the claim
# + amount - Claimed amount
# + purpose - What the expense was for
public type ExpenseClaim record {|
    string claimId;
    string employee;
    decimal amount;
    string purpose;
|};

# The manager's decision on an expense claim.
#
# + approved - Whether the claim is approved
# + comment - Reviewer comment shown to the employee
public type ApprovalDecision record {|
    boolean approved;
    string comment = "";
|};

# Final outcome of an expense claim.
#
# + claimId - The claim identifier
# + status - APPROVED, REJECTED or INVALID
# + paymentRef - Payment reference when reimbursed
public type ExpenseResult record {|
    string claimId;
    string status;
    string paymentRef?;
|};
