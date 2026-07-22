import ballerina/workflow;

# Tracks one shipment from dispatch to delivery. The workflow books the courier,
# then durably waits for two external data events — the pickup confirmation and
# the delivery confirmation — notifying the customer at each step.
#
# + ctx - The workflow context
# + shipment - The shipment to track
# + dataEvents - Futures for the courier events this workflow waits on
# + return - The final shipment state, or an error
@workflow:Workflow
function shipmentTrackingWorkflow(workflow:Context ctx, Shipment shipment,
        record {|future<PickupConfirmation> pickedUp; future<DeliveryConfirmation> delivered;|} dataEvents)
        returns ShipmentResult|error {
    string _ = check ctx->callActivity(bookCourier, {"shipment": shipment});

    PickupConfirmation pickup = check wait dataEvents.pickedUp;
    string _ = check ctx->callActivity(notifyCustomer,
            {"orderId": shipment.orderId,
                "message": string `Your order is on the way: ${pickup.courier} ${pickup.trackingNo}`});

    DeliveryConfirmation delivery = check wait dataEvents.delivered;
    string _ = check ctx->callActivity(notifyCustomer,
            {"orderId": shipment.orderId,
                "message": string `Delivered at ${delivery.deliveredAt}, received by ${delivery.receivedBy}`});

    return {
        shipmentId: shipment.shipmentId,
        status: "DELIVERED",
        trackingNo: pickup.trackingNo,
        receivedBy: delivery.receivedBy
    };
}
