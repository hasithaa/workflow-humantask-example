// Status of a shipping request as reported back to the caller / acknowledgement.
enum STATUS {
    PROCESSED,
    FAILED,
    PENDING
}

// Incoming request to ship an order.
type ShippingRequest record {|
    string orderId;
    string customerId;
    string shippingAddress;
|};

// Acknowledgement returned to the caller.
// `ref` carries the workflow id when the request is routed to human review.
type ShippingAcknolegement record {|
    string orderId;
    STATUS status;
    string? ref = ();
|};

// Successful response from the downstream shipping service.
type ShippingProcessResponse record {|
    string orderId;
    string trackingId;
|};

// Input passed to the human-task workflow when a shipping request fails.
// The whole record is handed to `workflow:run` and rehydrated as the
// workflow function's input parameter.
type ShippingProcessReviewDetails record {|
    ShippingRequest shippingRequest;
    string errorMessage;
    string errorCode;
|};

// Decision captured from the human reviewer and delivered back to the
// workflow via the management API's `completeHumanTask`.
type ShippingProcessReviewResponse record {|
    boolean retryMessage;
    string? comments = ();
|};
