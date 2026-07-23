import ballerina/ai;
import ballerina/http;
import ballerina/io;
import ballerina/workflow;

final ai:ModelProvider expenseModel = check ai:getDefaultModelProvider();

final workflow:DurableAgent expenseAgent = check new ({
    systemPrompt: {
        role: "Expense approval assistant",
        instructions: string `Process expense claims end to end. Validate the claim with
validateClaim first; reject invalid claims with a clear reason. Valid claims need a
manager's decision through the approveExpense human task — never reimburse without an
approval. On approval call processReimbursement and notify the employee with the payment
reference; on rejection notify the employee with the rejection reason. Finish with a
one-line summary of the outcome.`
    },
    model: expenseModel,
    activities: [
        validateClaim,
        {activity: processReimbursement, requiresApproval: true, userRoles: "manager"},
        notifyEmployee
    ],
    humanTasks: [
        {
            name: "approveExpense",
            roles: "manager",
            title: "Approve expense claim",
            description: "Review the claim details and approve or reject the reimbursement."
        }
    ],
    maxIter: 12
});

map<string> agentClaims = {};

service /expenses on new http:Listener(9098) {

    # Submits an expense claim to the approval agent.
    #
    # + claim - The expense claim
    # + return - The claim and agent instance identifiers, or an error
    resource function post .(ExpenseClaim claim) returns json|error {
        string instanceId = check expenseAgent.run(claim.toJsonString());
        agentClaims[claim.claimId] = instanceId;
        return {claimId: claim.claimId, instanceId, status: "PROCESSING"};
    }

    # Reads the outcome of a claim without blocking: while the agent is waiting on the
    # manager (the approveExpense task or the reimbursement review) the claim reports
    # PENDING_APPROVAL.
    #
    # + claimId - The claim identifier
    # + return - The agent's summary or the in-progress status, or an error
    resource function get [string claimId]() returns json|error {
        string? instanceId = agentClaims[claimId];
        if instanceId is () {
            return error(string `unknown claim: ${claimId}`);
        }
        string|error result = expenseAgent.getResult(instanceId);
        if result is workflow:AgentBusyError {
            return {claimId, status: "PENDING_APPROVAL"};
        }
        if result is error {
            return result;
        }
        return {claimId, status: "COMPLETED", summary: result};
    }
}

# Prints the endpoints once the worker and service are up.
#
# + return - An error when startup fails
public function main() returns error? {
    io:println("Expense approval agent listening on http://localhost:9098/expenses");
    io:println("  1. Submit: curl -X POST localhost:9098/expenses -H 'Content-Type: application/json' -d '{\"claimId\":\"EXP-A1\",\"employee\":\"nimal\",\"amount\":180.50,\"purpose\":\"Team lunch\"}'");
    io:println("  2. Decide the approveExpense task in the ICP inbox (role: manager)");
    io:println("  3. Status: curl localhost:9098/expenses/EXP-A1");
}
