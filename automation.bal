import order_processing_automation.ordersDB;

import ballerina/log;

public function main() returns error? {
    do {
        PlacedOrdersType[] placedOrders = check ordersDB->/orders.get(whereClause = `status = "PLACED"`);
        if placedOrders.length() == 0 {
            log:printInfo("No new orders to process.");
            return;
        }
        foreach PlacedOrdersType placedOrder in placedOrders {
            ordersDB:Order updatedOrder = check ordersDB->/orders/[placedOrder.orderId].put({
                status: "PROCESSING"
            });
            log:printInfo("Order advanced to PROCESSING", orderId = updatedOrder.orderId);
        }
        log:printInfo("Done - processing orders", count = placedOrders.length());
    } on fail error e {
        log:printError("Error occurred while processing the order", 'error = e);
        return e;
    }
}
