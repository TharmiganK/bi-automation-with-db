# Order Processing Automation

## Scenario

An e-commerce system stores customer orders in a MySQL database. A scheduled automation runs periodically, picks up all newly placed orders, and advances them to `PROCESSING` status — simulating the first step in warehouse fulfilment.

This walkthrough shows how WSO2 BI's **persist database connections** make it straightforward to build that automation. You will create one connector for the orders database and use the generated client to query and update rows in a scheduled `main()` entry point.

---

## What this demonstrates

| Capability | Where it appears |
|---|---|
| Single DB connector | Orders DB (MySQL) |
| Automation trigger | `main()` entry point — runs once per schedule invocation |
| Reading rows with a filter | Get orders where `status = 'PLACED'` |
| Updating a row | Advance each order status to `PROCESSING` |
| Iteration over results | `foreach` loop over the result set |
| Conditional early exit | Skip run when no PLACED orders exist |
| Logging | Per-order progress + final count |

---

## Database

**Orders DB (MySQL, port 3306)** — the order management system:

| Table | Columns |
|---|---|
| `orders` | `order_id` (PK), `customer_id`, `item`, `amount`, `status`, `placed_at` |

Status lifecycle: `PLACED` → `PROCESSING` → `SHIPPED` → `DELIVERED`

The automation only handles the `PLACED → PROCESSING` transition.

---

## Prerequisites

- Docker Desktop installed and running

---

## Step 0 — Start the database

```bash
docker compose -f docker/docker-compose.yml up -d
```

Wait until the container is healthy, then confirm the connection details:

```
orders-db   MySQL   localhost:3306   db=orders_db   user=orders_user   pass=orders_pass
```

---

## Step 1 — Create the Orders DB connector (MySQL)

1. Click `+ Add Artifact`.
2. Select `Connection` from **Other Artifacts**.
3. Click `Connect to a Database`.
4. In the **Introspect Database** form, select `MySQL` as the **Database Type** (the default) and enter the following connection details:

   | Field | Value |
   |---|---|
   | Host | `localhost` |
   | Port | `3306` |
   | Database Name | `orders_db` |
   | Username | `orders_user` |
   | Password | `orders_pass` |

5. Click `Connect & Introspect Database`.
6. In the **Select Tables** form, select `orders` and click `Continue to Connection Details`.
7. In the **Create Connection** form, set the **Connection Name** to `ordersDB` and click `Save Connection`.

---

## Step 2 — Build the automation

1. Click `+ Add Artifact` and select `Automation` from **Automation**.
2. Click `Create`.

### 2.1 — Get PLACED orders

Add a `Get rows from orders` action node from the `ordersDB` connection. Expand **Advanced Configurations** and set:

| Setting | Value |
|---|---|
| Where Clause | `status = "PLACED"` |

Set the **Result** name to `placedOrders`.

From the `Target Type` select the following fields:
- `orderId`
- `status`

### 2.2 — Handle: no orders to process

Add an `If` control node with the condition:

```
placedOrders.length() == 0
```

Inside the If block, add a `Log Info` statement node with the message:

```
No new orders to process.
```

Add a `Return` control node to exit early.

### 2.3 — Loop and update each order

Add a `Foreach` control node
- Set its **Collection** to `placedOrders`
- Set the **Result** name to `placedOrder`
- Set the **Type** to `PlacedOrdersType`

Inside the Foreach block:

1. Add an `Update row in orders` action node from the `ordersDB` connection. Select `orderId` as the key and set its value to `order.orderId`. In the **Value** section, select `status` and set it to `"PROCESSING"`. Give the **Result** name as `updatedOrder`

2. Add a `Log Info` statement node with the message:

   ```
   "Order advanced to PROCESSING"
   ```

   Under **Advanced Configurations** set the following **Additional Values**:
   - **Key** to `orderId`
   - **Value** to `updatedOrder.orderId`

### 2.4 — Log the summary

After the Foreach block, add a `Log Info` statement node with the message:

```
"Done — processing orders"
```

Under **Advanced Configurations** set the following **Additional Values**:
- **Key** to `count`
- **Value** to `placedOrders.length()`

---

## Running the automation

Run the Ballerina program. On first run (with `ORD-001` and `ORD-002` in `PLACED` status) you should see:

```
Order ORD-001 advanced to PROCESSING
Order ORD-002 advanced to PROCESSING
Done — processed 2 orders.
```

Connect to MySQL and confirm both orders are now `PROCESSING`:

```sql
SELECT order_id, status FROM orders;
```

Run the automation again — all orders are already `PROCESSING`, so the early-exit path fires:

```
No new orders to process.
```

---

## Seed data reference

| order_id | customer_id | item | amount | status |
|---|---|---|---|---|
| ORD-001 | CUST-001 | Wireless Headphones | 79.99 | `PLACED` |
| ORD-002 | CUST-002 | USB-C Hub | 34.50 | `PLACED` |
| ORD-003 | CUST-003 | Mechanical Keyboard | 129.00 | `PROCESSING` |
| ORD-004 | CUST-004 | Monitor Stand | 49.99 | `PROCESSING` |

`ORD-001` and `ORD-002` are the actionable records (happy path). `ORD-003` and `ORD-004` are already processing — the `WHERE status = 'PLACED'` filter ensures they are never re-processed.

---

## Resetting to a clean state

```bash
docker compose -f docker/docker-compose.yml down -v && docker compose -f docker/docker-compose.yml up -d
```

This wipes the data volume and re-seeds from the init script, so all test scenarios are reproducible from scratch.

---

## Stopping the database

```bash
docker compose -f docker/docker-compose.yml down
```
