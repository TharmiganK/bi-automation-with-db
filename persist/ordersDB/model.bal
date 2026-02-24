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
    string customerId;
    @sql:Varchar {length: 200}
    string item;
    @sql:Decimal {precision: [10, 2]}
    decimal amount;
    @sql:Varchar {length: 20}
    string status;
    @sql:Name {value: "placed_at"}
    time:Civil placedAt;
|};
