# A shipment to track from dispatch to delivery.
#
# + shipmentId - Unique identifier of the shipment
# + orderId - The order being fulfilled
# + destination - Delivery address
public type Shipment record {|
    string shipmentId;
    string orderId;
    string destination;
|};

# Courier confirmation that the shipment was picked up.
#
# + courier - The courier company
# + trackingNo - The courier tracking number
public type PickupConfirmation record {|
    string courier;
    string trackingNo;
|};

# Courier confirmation that the shipment was delivered.
#
# + receivedBy - Who signed for the delivery
# + deliveredAt - Delivery timestamp (ISO 8601)
public type DeliveryConfirmation record {|
    string receivedBy;
    string deliveredAt;
|};

# Final state of a tracked shipment.
#
# + shipmentId - The shipment identifier
# + status - The terminal status
# + trackingNo - The courier tracking number
# + receivedBy - Who signed for the delivery
public type ShipmentResult record {|
    string shipmentId;
    string status;
    string trackingNo;
    string receivedBy;
|};
