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
        return {claimId: claim.claimId, workflowId, status: "PENDING_APPROVAL"};
    }

    # Completes the pending approval human task for a claim.
    #
    # + taskWorkflowId - The human task's workflow ID (visible in the task inbox / Temporal UI)
    # + decision - The manager's decision
    # + return - A confirmation, or an error
    resource function post tasks/[string taskWorkflowId](ApprovalDecision decision) returns json|error {
        check workflow:completeHumanTask(taskWorkflowId, decision, ["manager"], "manager@acme.com");
        return {taskWorkflowId, status: "COMPLETED"};
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
            return {claimId, status: "PENDING_APPROVAL"};
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
    io:println("  1. Submit:  curl -X POST localhost:9096/expenses -H 'Content-Type: application/json' -d '{\"claimId\":\"EXP-1\",\"employee\":\"nimal\",\"amount\":180.50,\"purpose\":\"Team lunch\"}'");
    io:println("  2. Approve: curl -X POST localhost:9096/expenses/tasks/<taskWorkflowId> -H 'Content-Type: application/json' -d '{\"approved\":true,\"comment\":\"ok\"}'");
    io:println("  3. Status:  curl localhost:9096/expenses/EXP-1");
}
