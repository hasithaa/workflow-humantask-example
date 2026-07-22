import ballerina/io;
import ballerina/workflow;

# Submits one loan application and follows it to a decision. The whole
# process — parent, four children, and every activity — is durable: kill the
# process mid-run, start it again, and it resumes where it left off.
#
# + return - An error when the run fails
public function main() returns error? {
    LoanApplication application = {
        applicationId: "LN-2026-0001",
        applicant: {nic: "912345678V", name: "Nimal Perera", monthlyIncome: 350000d},
        amount: 1500000d,
        termMonths: 48
    };

    string workflowId = check workflow:run(loanApplicationWorkflow, application);
    io:println(string `loan application started -> ${workflowId}`);

    anydata result = check workflow:getWorkflowResult(workflowId, 120);
    io:println(string `decision -> ${result.toString()}`);
}
