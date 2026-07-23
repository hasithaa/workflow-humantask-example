import ballerina/http;
import ballerina/io;
import ballerina/workflow;
import ballerina/workflow.management;

map<string> claimWorkflows = {};

service /expenses on new http:Listener(9096) {

    # Submits an expense claim and starts its approval workflow.
    #
    # + claim - The expense claim
    # + return - The claim and workflow identifiers, or an error
    resource function post .(ExpenseClaim claim) returns json|error {
        string workflowId = check workflow:run(expenseApprovalWorkflow, claim);
        claimWorkflows[claim.claimId] = workflowId;
        return {claimId: claim.claimId, workflowId, status: "PENDING_REVIEW"};
    }

    # Submits the supporting bills for a claim; the workflow is durably waiting on them
    # after the manager requests the bills.
    #
    # + claimId - The claim identifier
    # + submission - The bills
    # + return - A confirmation, or an error
    resource function post [string claimId]/bills(BillSubmission submission) returns json|error {
        string? workflowId = claimWorkflows[claimId];
        if workflowId is () {
            return error(string `unknown claim: ${claimId}`);
        }
        check workflow:sendData(expenseApprovalWorkflow, workflowId, "billSubmitted", submission);
        return {claimId, status: "BILLS_SUBMITTED"};
    }

    # Reads the outcome of a claim's workflow.
    #
    # + claimId - The claim identifier
    # + return - The workflow result and status, or an error
    resource function get [string claimId]() returns json|error {
        string? workflowId = claimWorkflows[claimId];
        if workflowId is () {
            return error(string `unknown claim: ${claimId}`);
        }
        management:WorkflowExecutionInfo info = check management:getWorkflowInfo(workflowId);
        if info.status == "RUNNING" {
            return {claimId, status: "IN_REVIEW"};
        }
        anydata result = check workflow:getWorkflowResult(workflowId, 30);
        return {claimId, result: check result.cloneWithType(json)};
    }
}

# Prints the endpoints once the worker and service are up.
#
# + return - An error when startup fails
public function main() returns error? {
    io:println("Expense approval service listening on http://localhost:9096/expenses");
    io:println("  1. Submit claim: curl -X POST localhost:9096/expenses -H 'Content-Type: application/json' -d '{\"claimId\":\"EXP-1\",\"employee\":\"nimal\",\"amount\":180.50,\"purpose\":\"Team lunch\"}'");
    io:println("  2. Decide the checkExpenseRequest task in the ICP inbox (role: manager)");
    io:println("  3. Submit bills: curl -X POST localhost:9096/expenses/EXP-1/bills -H 'Content-Type: application/json' -d '{\"bills\":[{\"reference\":\"BILL-9\",\"amount\":180.50}]}'");
    io:println("  4. Decide the reviewBills task in the ICP inbox (role: manager)");
    io:println("  5. Status: curl localhost:9096/expenses/EXP-1");
}
