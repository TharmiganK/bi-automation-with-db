import order_processing_automation.ordersDB;

final ordersDB:Client ordersDB = check new (ordersDBHost, ordersDBPort, ordersDBUser, ordersDBPassword, ordersDBDatabase);
