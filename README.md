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
| `customers` | `customer_id` (PK), `name`, `email`, `address` |
| `products` | `product_id` (PK), `product_name`, `category`, `price` |
| `orders` | `order_id` (PK), `customer_id` (FK), `product_id` (FK), `amount`, `status`, `placed_at` |

**Relationships:**
- `orders.customer_id` → `customers.customer_id` (many orders per customer)
- `orders.product_id` → `products.product_id` (many orders per product)

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
      | --- | --- |
      | Host | `localhost` |
      | Port | `3306` |
      | Database Name | `orders_db` |
      | Username | `orders_user` |
      | Password | `orders_pass` |

5. Click `Connect & Introspect Database`.
6. In the **Select Tables** form, select all the tables and click `Continue to Connection Details`.
7. In the **Create Connection** form, set the **Connection Name** to `ordersDB` and click `Save Connection`.

      ![Create connector](images/create-connector.gif)

8. Click on the created `ordersDB` connection and click on `View ER Diagram` to view the ER diagram.

      ![View ER diagram](images/view-er-diagram.gif)

> **Note**:
> - Make sure the user you are connecting with has the necessary permissions to access the database and its metadata. Insufficient permissions can lead to introspection failures or incomplete metadata retrieval.
>  - When a table is selected during the connection creation, the other tables that have foreign key relationships with the selected table are automatically included in the selection. This ensures that all relevant tables are available for integration development, even if they were not explicitly selected by the user.
> - The generated client exposes the basic CRUD operations for the selected tables as methods. These methods can be used in the automation to interact with the database without writing raw SQL queries.

### Troubleshooting database connection errors

| Error | Actual message | Suggested resolution |
| --- | --- | --- |
| Connection failed | `Communications link failure. The last packet sent successfully to the server was 0 milliseconds ago.` | The hostname or port may be incorrect, or the database server may be down. Verify the connection details and ensure the database server is running. |
| Access denied | `Access denied for user 'user'@'localhost' (using password: YES)` | The username or password may be incorrect. Double-check the credentials and ensure the user has the necessary permissions to access the database. |
| Unknown database | `Unknown database 'orders_db'` | The specified database does not exist. Verify the database name and ensure it has been created on the server. |

---

## Step 2 — Build the automation

1. Click `+ Add Artifact` and select `Automation` from **Automation**.
2. Click `Create`.

### Step 2.1 — Get PLACED orders

1. Add a `Get rows from orders` action node from the `ordersDB` connection. Expand **Advanced Configurations** and set:

      | Setting | Value |
      | --- | --- |
      | Where Clause | `status = "PLACED"` |

2. Set the **Result** name to `placedOrders`.

3. From the `Target Type` select the following fields:

      - `orderId`
      - `status`

![Get PLACED orders](images/get-orders.gif)

### Step 2.2 — Handle: no orders to process

1. Add an `If` control node with the condition:

      ```txt
      placedOrders.length() == 0
      ```

2. Inside the If block, add a `Log Info` statement node with the message:

      ```txt
      No new orders to process.
      ```

3. Add a `Return` control node to exit early.

![Handle no orders](images/no-orders-check.gif)

### Step 2.3 — Loop and update each order

Add a `Foreach` control node:

- Set its **Collection** to `placedOrders`
- Set the **Result** name to `placedOrder`
- Set the **Type** to `PlacedOrdersType`

Inside the Foreach block:

1. Add an `Update row in orders` action node from the `ordersDB` connection. Select `orderId` as the key and set its value to `order.orderId`. In the **Value** section, select `status` and set it to `"PROCESSING"`. Give the **Result** name as `updatedOrder`.

2. Add a `Log Info` statement node with the message:

      ```txt
      Order advanced to PROCESSING
      ```

      Under **Advanced Configurations** set the following **Additional Values**:

      - **Key** to `orderId`
      - **Value** to `updatedOrder.orderId`

![Update orders in a loop](images/update-orders.gif)

### Step 2.4 — Log the summary

After the Foreach block, add a `Log Info` statement node with the message:

```txt
Done — processing orders
```

Under **Advanced Configurations** set the following **Additional Values**:

- **Key** to `count`
- **Value** to `placedOrders.length()`

---

## Running the automation

Click on the run button to run the automation. It will ask you to create the necessary configuration to connect to the database. Click on `Create Config.toml` and add the database password to the associated configuration.

![Run automation](images/run-automation.gif)

Run the BI project. On first run (with `ORD-001` and `ORD-002` in `PLACED` status) you should see:

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

**Customers:**

| customer_id | name | email | address |
|---|---|---|---|
| CUST-001 | John Smith | john.smith@example.com | 123 Main St, San Francisco, CA |
| CUST-002 | Sarah Johnson | sarah.johnson@example.com | 456 Oak Ave, New York, NY |
| CUST-003 | Michael Brown | michael.brown@example.com | 789 Pine Rd, Austin, TX |
| CUST-004 | Emma Davis | emma.davis@example.com | 321 Elm St, Seattle, WA |

**Products:**

| product_id | product_name | category | price |
|---|---|---|---|
| PROD-001 | Wireless Headphones | Electronics | 79.99 |
| PROD-002 | USB-C Hub | Electronics | 34.50 |
| PROD-003 | Mechanical Keyboard | Electronics | 129.00 |
| PROD-004 | Monitor Stand | Accessories | 49.99 |

**Orders:**

| order_id | customer_id | product_id | amount | status |
|---|---|---|---|---|
| ORD-001 | CUST-001 | PROD-001 | 79.99 | `PLACED` |
| ORD-002 | CUST-002 | PROD-002 | 34.50 | `PLACED` |
| ORD-003 | CUST-003 | PROD-003 | 129.00 | `PROCESSING` |
| ORD-004 | CUST-004 | PROD-004 | 49.99 | `PROCESSING` |

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
