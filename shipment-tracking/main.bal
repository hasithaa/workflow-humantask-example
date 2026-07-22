import ballerina/http;
import ballerina/io;
import ballerina/workflow;

map<string> shipmentWorkflows = {};

service /shipments on new http:Listener(9097) {

    # Dispatches a shipment and starts its tracking workflow.
    #
    # + shipment - The shipment to track
    # + return - The shipment and workflow identifiers, or an error
    resource function post .(Shipment shipment) returns json|error {
        string workflowId = check workflow:run(shipmentTrackingWorkflow, shipment);
        shipmentWorkflows[shipment.shipmentId] = workflowId;
        return {shipmentId: shipment.shipmentId, workflowId, status: "AWAITING_PICKUP"};
    }

    # Delivers the courier's pickup confirmation to the waiting workflow.
    #
    # + shipmentId - The shipment identifier
    # + pickup - The pickup confirmation
    # + return - A confirmation, or an error
    resource function post [string shipmentId]/pickup(PickupConfirmation pickup) returns json|error {
        string workflowId = check resolveWorkflow(shipmentId);
        check workflow:sendData(shipmentTrackingWorkflow, workflowId, "pickedUp", pickup);
        return {shipmentId, status: "IN_TRANSIT"};
    }

    # Delivers the courier's delivery confirmation to the waiting workflow.
    #
    # + shipmentId - The shipment identifier
    # + delivery - The delivery confirmation
    # + return - A confirmation, or an error
    resource function post [string shipmentId]/delivered(DeliveryConfirmation delivery) returns json|error {
        string workflowId = check resolveWorkflow(shipmentId);
        check workflow:sendData(shipmentTrackingWorkflow, workflowId, "delivered", delivery);
        return {shipmentId, status: "DELIVERED"};
    }

    # Reads the final state of a shipment's workflow.
    #
    # + shipmentId - The shipment identifier
    # + return - The workflow result, or an error
    resource function get [string shipmentId]() returns json|error {
        string workflowId = check resolveWorkflow(shipmentId);
        anydata result = check workflow:getWorkflowResult(workflowId, 30);
        return check result.cloneWithType(json);
    }
}

function resolveWorkflow(string shipmentId) returns string|error {
    string? workflowId = shipmentWorkflows[shipmentId];
    if workflowId is () {
        return error(string `unknown shipment: ${shipmentId}`);
    }
    return workflowId;
}

# Prints the endpoints once the worker and service are up.
#
# + return - An error when startup fails
public function main() returns error? {
    io:println("Shipment tracking service listening on http://localhost:9097/shipments");
    io:println("  1. Dispatch:  curl -X POST localhost:9097/shipments -H 'Content-Type: application/json' -d '{\"shipmentId\":\"SHP-1\",\"orderId\":\"ORD-77\",\"destination\":\"Colombo\"}'");
    io:println("  2. Pickup:    curl -X POST localhost:9097/shipments/SHP-1/pickup -H 'Content-Type: application/json' -d '{\"courier\":\"DHL\",\"trackingNo\":\"DHL-123\"}'");
    io:println("  3. Delivered: curl -X POST localhost:9097/shipments/SHP-1/delivered -H 'Content-Type: application/json' -d '{\"receivedBy\":\"Nimal\",\"deliveredAt\":\"2026-07-23T10:00:00Z\"}'");
    io:println("  4. Result:    curl localhost:9097/shipments/SHP-1");
}
