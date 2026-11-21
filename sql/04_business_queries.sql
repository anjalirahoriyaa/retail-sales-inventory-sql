USE retail_management;

-- 1. SELECT, WHERE, ORDER BY, LIMIT
SELECT product_name, unit_price, stock_quantity
FROM products
WHERE is_active = TRUE AND unit_price >= 500
ORDER BY unit_price DESC
LIMIT 5;

-- 2. DISTINCT
SELECT DISTINCT city FROM customers ORDER BY city;

-- 3. Aggregate functions
SELECT
    COUNT(*) AS product_count,
    ROUND(AVG(unit_price), 2) AS average_price,
    MIN(unit_price) AS lowest_price,
    MAX(unit_price) AS highest_price,
    SUM(stock_quantity) AS total_units_in_stock
FROM products;

-- 4. INNER JOIN: product catalogue with category names
SELECT p.product_name, p.sku, c.category_name, p.unit_price
FROM products p
INNER JOIN categories c ON c.category_id = p.category_id
ORDER BY c.category_name, p.product_name;

-- 5. LEFT JOIN: include customers even if they have no orders
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY order_count DESC;

-- 6. RIGHT JOIN: show all categories, including categories without products
SELECT c.category_name, p.product_name
FROM products p
RIGHT JOIN categories c ON c.category_id = p.category_id
ORDER BY c.category_name, p.product_name;

-- 7. GROUP BY and HAVING: categories with catalogue value above threshold
SELECT c.category_name,
       COUNT(p.product_id) AS products_in_category,
       ROUND(AVG(p.unit_price), 2) AS average_product_price
FROM categories c
JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
HAVING AVG(p.unit_price) > 300;

-- 8. Multi-table join: order line details
SELECT o.order_id, o.order_date,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       p.product_name, oi.quantity, oi.unit_price, oi.line_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
ORDER BY o.order_date DESC;

-- 9. Subquery: products priced above the overall average
SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY unit_price DESC;

-- 10. Correlated subquery: customers whose spend is above average customer spend
SELECT c.customer_id, c.first_name, c.last_name,
       fn_customer_lifetime_value(c.customer_id) AS lifetime_value
FROM customers c
WHERE fn_customer_lifetime_value(c.customer_id) >
      (SELECT AVG(customer_total)
       FROM (
           SELECT COALESCE(SUM(total_amount), 0) AS customer_total
           FROM orders
           WHERE order_status <> 'CANCELLED'
           GROUP BY customer_id
       ) AS customer_spend);

-- 11. CTE: revenue by month
WITH monthly_revenue AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
           SUM(total_amount) AS revenue
    FROM orders
    WHERE order_status <> 'CANCELLED'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT sales_month, revenue
FROM monthly_revenue
ORDER BY sales_month;

-- 12. Window function: rank products by units sold
WITH product_sales AS (
    SELECT p.product_id, p.product_name,
           COALESCE(SUM(oi.quantity), 0) AS units_sold
    FROM products p
    LEFT JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT product_name, units_sold,
       DENSE_RANK() OVER (ORDER BY units_sold DESC) AS sales_rank
FROM product_sales
ORDER BY sales_rank, product_name;

-- 13. Running total of revenue by order date
SELECT order_id, order_date, total_amount,
       SUM(total_amount) OVER (
           ORDER BY order_date, order_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_revenue
FROM orders
WHERE order_status <> 'CANCELLED';

-- 14. Views
SELECT * FROM vw_order_summary ORDER BY order_date DESC;
SELECT * FROM vw_product_stock_status ORDER BY stock_quantity;

-- 15. Low-stock alert
SELECT product_name, stock_quantity, reorder_level
FROM products
WHERE is_active = TRUE AND stock_quantity <= reorder_level
ORDER BY stock_quantity;

-- 16. Payment reconciliation
SELECT o.order_id, o.total_amount,
       COALESCE(SUM(CASE WHEN p.payment_status = 'COMPLETED'
                         THEN p.amount ELSE 0 END), 0) AS completed_payments
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <>
       COALESCE(SUM(CASE WHEN p.payment_status = 'COMPLETED'
                         THEN p.amount ELSE 0 END), 0);

-- 17. Inventory movement audit trail
SELECT im.movement_date, p.product_name, im.movement_type,
       im.quantity_change, im.reference_note
FROM inventory_movements im
JOIN products p ON p.product_id = im.product_id
ORDER BY im.movement_date DESC, im.movement_id DESC;

-- 18. UPDATE example (run only if you want to change catalogue price)
-- UPDATE products SET unit_price = unit_price * 1.05 WHERE product_id = 1;

-- 19. DELETE example (safe demonstration using a customer with no orders)
-- DELETE FROM customers WHERE customer_id = 99999;

-- 20. Transaction example: a manual stock restock with audit record
START TRANSACTION;
UPDATE products
SET stock_quantity = stock_quantity + 10
WHERE product_id = 1;
INSERT INTO inventory_movements
(product_id, movement_type, quantity_change, reference_note)
VALUES (1, 'RESTOCK', 10, 'Demo manual restock');
COMMIT;

-- 21. EXPLAIN: inspect index usage and query plan
EXPLAIN
SELECT order_id, order_date, total_amount
FROM orders
WHERE customer_id = 1
ORDER BY order_date DESC;
