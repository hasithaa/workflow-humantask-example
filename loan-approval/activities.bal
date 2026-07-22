import ballerina/workflow;

# Validates the shape and business rules of a new application.
#
# + application - The submitted application
# + return - `true` when the application is acceptable, or an error
@workflow:Activity
function validateApplication(LoanApplication application) returns boolean|error {
    return application.amount > 0d && application.termMonths > 0;
}

# Verifies the applicant's identity documents with the registry.
#
# + nic - The applicant NIC
# + return - Whether the identity checks out, or an error
@workflow:Activity
function verifyIdentity(string nic) returns boolean|error {
    return true;
}

# Screens the applicant against the sanctions list.
#
# + nic - The applicant NIC
# + return - Whether the applicant is sanctioned, or an error
@workflow:Activity
function checkSanctionsList(string nic) returns boolean|error {
    return false;
}

# Pulls the applicant's credit history from the bureau and scores it.
#
# + nic - The applicant NIC
# + return - The bureau score, or an error
@workflow:Activity
function fetchBureauScore(string nic) returns int|error {
    return 742;
}

# Executes the core-banking funds transfer.
#
# + accountNo - Account to credit
# + amount - Amount to transfer
# + return - The transfer reference, or an error
@workflow:Activity
function transferFunds(string accountNo, decimal amount) returns string|error {
    return string `TXN-${accountNo}-001`;
}

# Notifies the applicant of the decision.
#
# + applicationId - The application identifier
# + message - The notification text
# + return - A delivery reference, or an error
@workflow:Activity
function notifyApplicant(string applicationId, string message) returns string|error {
    return string `NOTIF-${applicationId}`;
}
