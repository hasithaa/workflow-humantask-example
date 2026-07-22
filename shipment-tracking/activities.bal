import ballerina/workflow;

# Books the courier pickup for a shipment.
#
# + shipment - The shipment to dispatch
# + return - The courier booking reference, or an error
@workflow:Activity
function bookCourier(Shipment shipment) returns string|error {
    return string `BOOK-${shipment.shipmentId}`;
}

# Notifies the customer of a shipment status change.
#
# + orderId - The order the shipment belongs to
# + message - The notification text
# + return - A delivery reference, or an error
@workflow:Activity
function notifyCustomer(string orderId, string message) returns string|error {
    return string `NOTIF-${orderId}`;
}
