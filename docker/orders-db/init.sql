CREATE TABLE orders (
    order_id    VARCHAR(36)    NOT NULL,
    customer_id VARCHAR(36)    NOT NULL,
    item        VARCHAR(200)   NOT NULL,
    amount      DECIMAL(10, 2) NOT NULL,
    status      VARCHAR(20)    NOT NULL DEFAULT 'PLACED',
    placed_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id)
);

-- Seed orders
-- ORD-001, ORD-002: PLACED — these are the actionable records (happy path)
-- ORD-003, ORD-004: already PROCESSING — confirm they are not re-processed
INSERT INTO orders (order_id, customer_id, item, amount, status, placed_at) VALUES
    ('ORD-001', 'CUST-001', 'Wireless Headphones', 79.99,  'PLACED',     '2025-01-15 09:00:00'),
    ('ORD-002', 'CUST-002', 'USB-C Hub',           34.50,  'PLACED',     '2025-01-15 09:15:00'),
    ('ORD-003', 'CUST-003', 'Mechanical Keyboard', 129.00, 'PROCESSING', '2025-01-14 14:00:00'),
    ('ORD-004', 'CUST-004', 'Monitor Stand',       49.99,  'PROCESSING', '2025-01-14 16:30:00');
