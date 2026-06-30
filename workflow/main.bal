import ballerina/http;
import ballerina/log;
import ballerina/workflow;
// Importing the management module starts its HTTP API (default :8234, base path
// /workflow), which the human-task UI will consume in the next iteration.
import ballerina/workflow.management as _;

service / on new http:Listener(8080) {

    // Attempts to process a shipping request. On success the caller gets an
    // immediate PROCESSED acknowledgement. On failure a durable human-review
    // workflow is started and its id is returned as `ref` for follow-up.
    resource function post processShippingRequest(ShippingRequest payload)
            returns ShippingAcknolegement|error {

        ShippingProcessResponse|error response = shippingServiceEP->post("/process", payload);
        if response is ShippingProcessResponse {
            return {orderId: payload.orderId, status: PROCESSED};
        }

        log:printError("Shipping service call failed; starting review workflow",
                response, orderId = payload.orderId);

        ShippingProcessReviewDetails reviewInput = {
            shippingRequest: payload,
            errorMessage: response.message(),
            errorCode: "SHIPPING_SERVICE_ERROR"
        };
        string workflowId = check workflow:run(reviewErrorTaskProcess, reviewInput);
        return {orderId: payload.orderId, status: PENDING, ref: workflowId};
    }
}
