# Interview Guide: Explain Your SQL Project

## 60-second project explanation

"I built a Retail Sales and Inventory Management database in MySQL 8. It stores customers, categories, products, orders, order items, payments, and inventory movements. I designed the relationships using primary and foreign keys and added constraints to protect data quality. When an order item is inserted, a trigger validates available stock, deducts inventory, records the stock movement, and updates the order total. I also created a stored procedure that places an order and records payment inside a transaction, so a failure rolls back the operation. For reporting, I used joins, subqueries, CTEs, views, aggregate functions, and window functions."

## Common interview questions

**1. Why did you split orders and order_items?**  
An order is a header and can contain multiple products. Keeping line items separate models the one-to-many relationship and avoids repeating order/customer data.

**2. Why use a foreign key?**  
It prevents child records from referring to a customer, product, or order that does not exist.

**3. What is the difference between WHERE and HAVING?**  
`WHERE` filters rows before grouping; `HAVING` filters grouped results after aggregation.

**4. What is the difference between DELETE, TRUNCATE, and DROP?**  
`DELETE` removes selected rows, `TRUNCATE` removes all rows from a table, and `DROP` removes the database object itself.

**5. Why use a transaction in the procedure?**  
Order creation, stock deduction, and payment recording form one logical operation. If a step fails, rollback prevents a partially completed order.

**6. What does the trigger do?**  
It rejects invalid or over-stock order lines before insertion. After insertion, it deducts stock, creates an inventory movement, and recalculates the order total.

**7. What is an index?**  
An index helps MySQL find rows faster for suitable filters, joins, and sorts, at the cost of extra storage and slower writes.

**8. Why use a view?**  
A view packages a frequently used query into a reusable virtual table, such as the order summary or stock status report.

**9. What is a CTE?**  
A Common Table Expression is a named temporary result set scoped to one statement. It can make complex queries easier to read.

**10. What is a window function?**  
It calculates a value across related rows without collapsing them into one row per group. This project uses `DENSE_RANK()` and a running `SUM()`.

## Live demonstration checklist

1. Show the seven tables and their relationships in Workbench.
2. Run the order summary view.
3. Run the product ranking query.
4. Call `sp_place_single_item_order` with a valid quantity.
5. Show the new order, payment, stock quantity, and inventory movement.
6. Attempt a quantity larger than available stock and explain the trigger error and transaction rollback.
7. Run `EXPLAIN` on the indexed customer/date lookup.

## Be honest about scope

This is a portfolio database project using sample data. It is not connected to a live payment gateway, warehouse scanner, or customer-facing website. Explain the implemented database behavior rather than claiming those integrations.
