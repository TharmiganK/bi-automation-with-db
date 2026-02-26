CREATE TABLE customers (
    customer_id VARCHAR(36)  NOT NULL,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL,
    address     VARCHAR(255) NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE products (
    product_id   VARCHAR(36)  NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    price        DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE orders (
    order_id    VARCHAR(36)    NOT NULL,
    customer_id VARCHAR(36)    NOT NULL,
    product_id  VARCHAR(36)    NOT NULL,
    amount      DECIMAL(10, 2) NOT NULL,
    status      VARCHAR(20)    NOT NULL DEFAULT 'PLACED',
    placed_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Seed customers
INSERT INTO customers (customer_id, name, email, address) VALUES
    ('CUST-001', 'John Smith',  'john.smith@example.com',     '123 Main St, San Francisco, CA'),
    ('CUST-002', 'Sarah Johnson', 'sarah.johnson@example.com', '456 Oak Ave, New York, NY'),
    ('CUST-003', 'Michael Brown', 'michael.brown@example.com', '789 Pine Rd, Austin, TX'),
    ('CUST-004', 'Emma Davis',  'emma.davis@example.com',     '321 Elm St, Seattle, WA');

-- Seed products
INSERT INTO products (product_id, product_name, category, price) VALUES
    ('PROD-001', 'Wireless Headphones', 'Electronics', 79.99),
    ('PROD-002', 'USB-C Hub',           'Electronics', 34.50),
    ('PROD-003', 'Mechanical Keyboard', 'Electronics', 129.00),
    ('PROD-004', 'Monitor Stand',       'Accessories', 49.99);

-- Seed orders
-- ORD-001, ORD-002: PLACED — these are the actionable records (happy path)
-- ORD-003, ORD-004: already PROCESSING — confirm they are not re-processed
INSERT INTO orders (order_id, customer_id, product_id, amount, status, placed_at) VALUES
    ('ORD-001', 'CUST-001', 'PROD-001', 79.99,  'PLACED',     '2025-01-15 09:00:00'),
    ('ORD-002', 'CUST-002', 'PROD-002', 34.50,  'PLACED',     '2025-01-15 09:15:00'),
    ('ORD-003', 'CUST-003', 'PROD-003', 129.00, 'PROCESSING', '2025-01-14 14:00:00'),
    ('ORD-004', 'CUST-004', 'PROD-004', 49.99,  'PROCESSING', '2025-01-14 16:30:00');
