import ballerina/io;
import ballerina/workflow;

// Durable workflow that handles a failed shipping request by asking a human
// reviewer whether to retry. The whole `input` record is supplied to
// `workflow:run`; the workflow blocks at `awaitHumanTask` until a reviewer
// completes the task through the management API.
@workflow:Workflow
function reviewErrorTaskProcess(workflow:Context ctx, ShippingProcessReviewDetails input)
        returns ShippingAcknolegement|error {

    // Surface the failure context to the reviewer as the human-task payload.
    map<json> taskPayload = {
        orderId: input.shippingRequest.orderId,
        customerId: input.shippingRequest.customerId,
        shippingAddress: input.shippingRequest.shippingAddress,
        errorMessage: input.errorMessage,
        errorCode: input.errorCode
    };

    // Block until a user in the "reviewer" role completes the task.
    ShippingProcessReviewResponse review = check ctx->awaitHumanTask(
        "reviewErrorTask",
        "reviewer",
        payload = taskPayload,
        title = string `Review failed shipping for order ${input.shippingRequest.orderId}`,
        description = input.errorMessage
    );

    if review.retryMessage {
        // Retry the shipping call as a durable activity. On failure a manual
        // retry task is created (workflow:ManualRetry) for an operator to act on.
        _ = check ctx->callActivity(
            callShippingService,
            {request: input.shippingRequest},
            ShippingProcessResponse,
            workflow:ManualRetry
        );
        ShippingAcknolegement ack = {orderId: input.shippingRequest.orderId, status: PROCESSED};
        _ = check ctx->callActivity(sendShippingAcknolegement, {ack: ack}, string);
        return ack;
    }

    // Reviewer declined the retry — acknowledge the order as failed.
    ShippingAcknolegement ack = {orderId: input.shippingRequest.orderId, status: FAILED};
    _ = check ctx->callActivity(sendShippingAcknolegement, {ack: ack}, string);
    return ack;
}

@workflow:Activity
function callShippingService(ShippingRequest request) returns ShippingProcessResponse|error {
    return shippingServiceEP->post("/process", request);
}

@workflow:Activity
function sendShippingAcknolegement(ShippingAcknolegement ack) returns string|error {
    // Mock implementation of delivering the shipping acknowledgement.
    io:println("Sending shipping acknowledgement: ", ack.toJsonString());
    return string `SENT:${ack.orderId}`;
}
