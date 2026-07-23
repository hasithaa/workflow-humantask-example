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
    Bill[] bills = [];
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

# A supporting bill attached to an expense claim.
#
# + reference - Bill or receipt reference
# + amount - Billed amount
public type Bill record {|
    string reference;
    decimal amount;
|};

# The employee's bill submission for a claim.
#
# + bills - The supporting bills
public type BillSubmission record {|
    Bill[] bills;
|};

# The manager's decision on a newly submitted expense request.
#
# + action - REQUEST_BILL to ask the employee for the supporting bills, or REJECT
# + comment - Reviewer comment shown to the employee
public type RequestDecision record {|
    string action;
    string comment = "";
|};
