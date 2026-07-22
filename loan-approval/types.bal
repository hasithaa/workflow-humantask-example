# A loan applicant.
#
# + nic - National identity card number
# + name - Full name of the applicant
# + monthlyIncome - Declared monthly income
public type Applicant record {|
    string nic;
    string name;
    decimal monthlyIncome;
|};

# A loan application submitted by a customer.
#
# + applicationId - Unique identifier of the application
# + applicant - The applicant's details
# + amount - Requested loan amount
# + termMonths - Requested repayment term in months
public type LoanApplication record {|
    string applicationId;
    Applicant applicant;
    decimal amount;
    int termMonths;
|};

# Result of the KYC (know-your-customer) child workflow.
#
# + nic - The applicant NIC that was verified
# + identityVerified - Whether the identity documents checked out
# + onSanctionsList - Whether the applicant appears on a sanctions list
public type KycResult record {|
    string nic;
    boolean identityVerified;
    boolean onSanctionsList;
|};

# Result of the credit-scoring child workflow.
#
# + nic - The applicant NIC that was scored
# + score - Credit score in the 300-850 range
# + openDefaults - Number of open defaulted facilities
public type CreditScore record {|
    string nic;
    int score;
    int openDefaults;
|};

# Input for the disbursement child workflow.
#
# + applicationId - The approved application
# + accountNo - Account to credit
# + amount - Amount to disburse
public type DisbursementRequest record {|
    string applicationId;
    string accountNo;
    decimal amount;
|};

# Treasury's release instruction, sent to the waiting disbursement
# workflow as a data event once funds are allocated.
#
# + batchNo - Treasury settlement batch number
# + valueDate - Settlement value date (ISO 8601)
public type FundsRelease record {|
    string batchNo;
    string valueDate;
|};

# Result of the disbursement child workflow.
#
# + applicationId - The application the funds belong to
# + reference - Core-banking transfer reference
# + batchNo - Treasury batch the transfer settled in
public type Disbursement record {|
    string applicationId;
    string reference;
    string batchNo;
|};

# Final decision of the loan application workflow.
#
# + applicationId - The application identifier
# + approved - Whether the loan was approved
# + reason - Human-readable decision reason
# + disbursementRef - Transfer reference when approved and disbursed
public type LoanDecision record {|
    string applicationId;
    boolean approved;
    string reason;
    string disbursementRef?;
|};
