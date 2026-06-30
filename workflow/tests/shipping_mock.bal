import ballerina/http;

// Mock of the downstream shipping service used by the tests. It listens on the
// same URL configured in connections.bal. Orders whose id starts with "FAIL"
// return a 500 so the failure / manual-retry paths can be exercised.
service /shippingService on new http:Listener(9000) {

    resource function post process(ShippingRequest request)
            returns ShippingProcessResponse|http:InternalServerError {
        if request.orderId.startsWith("FAIL") {
            return {body: string `shipping failed for ${request.orderId}`};
        }
        return {orderId: request.orderId, trackingId: string `TRK-${request.orderId}`};
    }
}
