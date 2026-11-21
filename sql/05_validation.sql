USE retail_management;

-- These checks should return the expected values after scripts 01-04.
SELECT 'tables_created' AS check_name,
       CASE WHEN COUNT(*) = 7 THEN 'PASS' ELSE 'FAIL' END AS result
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE';

SELECT 'seed_customers_present' AS check_name,
       CASE WHEN COUNT(*) >= 6 THEN 'PASS' ELSE 'FAIL' END AS result
FROM customers;

SELECT 'seed_products_present' AS check_name,
       CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END AS result
FROM products;

SELECT 'orders_have_order_items' AS check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE oi.order_item_id IS NULL;

SELECT 'order_totals_match_lines' AS check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM orders o
JOIN (
    SELECT order_id, SUM(line_total) AS calculated_total
    FROM order_items
    GROUP BY order_id
) x ON x.order_id = o.order_id
WHERE o.total_amount <> x.calculated_total;

SELECT 'stock_never_negative' AS check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM products
WHERE stock_quantity < 0;

SELECT 'all_demo_orders_paid' AS check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM orders o
LEFT JOIN payments p
  ON p.order_id = o.order_id AND p.payment_status = 'COMPLETED'
WHERE p.payment_id IS NULL;

-- Inspect the final project data.
SELECT COUNT(*) AS customers FROM customers;
SELECT COUNT(*) AS products FROM products;
SELECT COUNT(*) AS orders FROM orders;
SELECT COUNT(*) AS order_lines FROM order_items;
SELECT COUNT(*) AS payments FROM payments;
SELECT COUNT(*) AS inventory_movements FROM inventory_movements;
