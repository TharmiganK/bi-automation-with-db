import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

@sql:Name {value: "orders"}
public type Order record {|
    @sql:Name {value: "order_id"}
    @sql:Varchar {length: 36}
    readonly string orderId;
    @sql:Name {value: "customer_id"}
    @sql:Varchar {length: 36}
    @sql:Index {name: "customer_id"}
    string customerId;
    @sql:Name {value: "order_date"}
    time:Date orderDate;
    @sql:Varchar {length: 50}
    string status;
    @sql:Name {value: "shipment_ref"}
    @sql:Varchar {length: 36}
    string? shipmentRef;
    OrderItem[] orderitems;
    @sql:Relation {keys: ["customerId"]}
    Customer customer;
|};

@sql:Name {value: "customers"}
public type Customer record {|
    @sql:Name {value: "customer_id"}
    @sql:Varchar {length: 36}
    readonly string customerId;
    @sql:Varchar {length: 100}
    string name;
    @sql:Varchar {length: 100}
    string email;
    @sql:Name {value: "shipping_address"}
    string shippingAddress;
    Order[] orders;
|};

@sql:Name {value: "order_items"}
public type OrderItem record {|
    @sql:Name {value: "item_id"}
    @sql:Varchar {length: 36}
    readonly string itemId;
    @sql:Name {value: "order_id"}
    @sql:Varchar {length: 36}
    @sql:Index {name: "order_id"}
    string orderId;
    @sql:Name {value: "product_id"}
    @sql:Varchar {length: 36}
    string productId;
    int quantity;
    @sql:Name {value: "unit_price"}
    @sql:Decimal {precision: [10, 2]}
    decimal unitPrice;
    @sql:Relation {keys: ["orderId"]}
    Order 'order;
|};
