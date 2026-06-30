import ballerina/lang.runtime;
import ballerina/test;
import ballerina/workflow;
import ballerina/workflow.management as management;

// Pending human tasks are reported with their fully-qualified name,
// "<workflowType>.<taskName>" (e.g. "reviewErrorTaskProcess.reviewErrorTask").
function matchesTask(string qualifiedName, string taskName) returns boolean {
    return qualifiedName == taskName || qualifiedName.endsWith("." + taskName);
}

// Poll the management API until the workflow reaches its human task, then
// return the task (child workflow) id used to complete it.
function waitForHumanTask(string workflowId, string taskName) returns string|error {
    int attempts = 0;
    while attempts < 50 {
        management:HumanTaskGroup[] groups = check management:listPendingHumanTasks(workflowId);
        foreach management:HumanTaskGroup group in groups {
            if matchesTask(group.taskName, taskName) && group.taskIds.length() > 0 {
                return group.taskIds[0];
            }
        }
        runtime:sleep(0.2);
        attempts += 1;
    }
    return error(string `Timed out waiting for human task '${taskName}' on workflow ${workflowId}`);
}

@test:Config {}
function testReviewerDeclinesRetry() returns error? {
    ShippingProcessReviewDetails input = {
        shippingRequest: {orderId: "ORD-DECLINE", customerId: "CUST-1", shippingAddress: "1 Main St"},
        errorMessage: "connection refused",
        errorCode: "SHIPPING_SERVICE_ERROR"
    };

    string workflowId = check workflow:run(reviewErrorTaskProcess, input);

    string taskId = check waitForHumanTask(workflowId, "reviewErrorTask");
    ShippingProcessReviewResponse decision = {retryMessage: false, comments: "Customer cancelled the order"};
    check management:completeHumanTask(taskId, decision, callerRoles = ["reviewer"]);

    anydata result = check workflow:getWorkflowResult(workflowId, 30);
    ShippingAcknolegement ack = check result.cloneWithType();
    test:assertEquals(ack.orderId, "ORD-DECLINE");
    test:assertEquals(ack.status, FAILED);
}

@test:Config {}
function testReviewerApprovesRetryAndShippingSucceeds() returns error? {
    ShippingProcessReviewDetails input = {
        shippingRequest: {orderId: "ORD-OK", customerId: "CUST-2", shippingAddress: "2 Main St"},
        errorMessage: "downstream timeout",
        errorCode: "SHIPPING_SERVICE_ERROR"
    };

    string workflowId = check workflow:run(reviewErrorTaskProcess, input);

    string taskId = check waitForHumanTask(workflowId, "reviewErrorTask");
    ShippingProcessReviewResponse decision = {retryMessage: true};
    check management:completeHumanTask(taskId, decision, callerRoles = ["reviewer"]);

    anydata result = check workflow:getWorkflowResult(workflowId, 30);
    ShippingAcknolegement ack = check result.cloneWithType();
    test:assertEquals(ack.orderId, "ORD-OK");
    test:assertEquals(ack.status, PROCESSED);
}

@test:Config {}
function testPendingHumanTaskIsListed() returns error? {
    ShippingProcessReviewDetails input = {
        shippingRequest: {orderId: "ORD-LIST", customerId: "CUST-3", shippingAddress: "3 Main St"},
        errorMessage: "service unavailable",
        errorCode: "SHIPPING_SERVICE_ERROR"
    };

    string workflowId = check workflow:run(reviewErrorTaskProcess, input);
    string taskId = check waitForHumanTask(workflowId, "reviewErrorTask");

    // The management API exposes the task details that the UI will render.
    management:HumanTaskInfo info = check management:getHumanTaskInfo(taskId);
    test:assertTrue(matchesTask(info.taskName, "reviewErrorTask"),
            string `unexpected task name: ${info.taskName}`);
    test:assertEquals(info.status, "RUNNING");

    // Clean up so the workflow completes rather than lingering as pending.
    ShippingProcessReviewResponse decision = {retryMessage: false};
    check management:completeHumanTask(taskId, decision, callerRoles = ["reviewer"]);
    _ = check workflow:getWorkflowResult(workflowId, 30);
}
