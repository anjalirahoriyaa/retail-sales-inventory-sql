# Retail Sales & Inventory Management System (MySQL 8.0)

A portfolio-ready relational database project that models a small retail business. It manages customers, product categories, products, sales orders, order items, payments, and stock movements. It also includes reusable reporting views, a stored procedure, a stored function, triggers, indexes, and analytical SQL.

## Project highlights

- **Relational design:** seven connected tables with primary keys, foreign keys, unique constraints, and check constraints.
- **Core SQL:** DDL, DML, filtering, sorting, aggregation, grouping, and all common join patterns.
- **Advanced SQL:** subqueries, CTEs, window functions, views, stored procedure, stored function, triggers, and transactions.
- **Business rules:** an order line cannot exceed available stock; inserting an order line deducts inventory and records the movement; order totals are recalculated automatically.
- **Reporting:** monthly revenue, best-selling products, customer lifetime value, low-stock products, and sales rankings.

## Requirements

- MySQL Server **8.0.16 or newer** (CHECK constraints are enforced from 8.0.16).
- MySQL Workbench or another MySQL client.

## Setup (MySQL Workbench)

1. Install and start MySQL Server 8.0.
2. Open MySQL Workbench and connect to your local server.
3. Open `sql/01_schema.sql` and execute the entire script.
4. Open and execute `sql/02_seed_data.sql`.
5. Open and execute `sql/03_views_routines_triggers.sql`.
6. Open and execute `sql/04_business_queries.sql` to explore reports.
7. Run `sql/05_validation.sql`. Each result should show the expected pass status or a sensible non-zero count.

**Important:** Run the scripts in the order above. The schema script drops and recreates the `retail_management` database, so do not run it against a database containing data you need.

## Setup (command line)

From the project folder:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p retail_management < sql/02_seed_data.sql
mysql -u root -p retail_management < sql/03_views_routines_triggers.sql
mysql -u root -p retail_management < sql/04_business_queries.sql
mysql -u root -p retail_management < sql/05_validation.sql
```

The first command creates the database. Replace `root` with your MySQL username if needed.

## How the system works

1. A manager registers customers and product catalogue information.
2. A customer places an order. The `orders` row stores the customer and order status.
3. Each product in the order is recorded in `order_items` with the price at the time of sale. This preserves historical pricing even if the catalogue price changes later.
4. A `BEFORE INSERT` trigger checks that the product is active and enough stock is available.
5. An `AFTER INSERT` trigger deducts stock, writes an `inventory_movements` record, and recalculates the order total.
6. A payment record is added to `payments`.
7. Views and analytical queries turn transactional data into business reports.

The included `sp_place_single_item_order` procedure demonstrates a transaction: it creates an order, inserts an order line, records payment, and commits. If any step fails, its exception handler rolls back the complete operation.

## Try the stored procedure

```sql
CALL sp_place_single_item_order(
    1,       -- customer_id
    1,       -- product_id
    2,       -- quantity
    'UPI'    -- payment_method: CARD, UPI, CASH, BANK_TRANSFER
);
```

Then check the latest order, payment, and stock:

```sql
SELECT * FROM orders ORDER BY order_id DESC LIMIT 1;
SELECT * FROM payments ORDER BY payment_id DESC LIMIT 1;
SELECT product_id, product_name, stock_quantity
FROM products
WHERE product_id = 1;
```

Try ordering more units than are in stock. The trigger rejects the order line and the procedure rolls back the order.

## Repository structure

```text
retail-sales-inventory-sql/
├── README.md
├── .gitignore
├── LICENSE
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed_data.sql
│   ├── 03_views_routines_triggers.sql
│   ├── 04_business_queries.sql
│   └── 05_validation.sql
└── docs/
    ├── data_dictionary.md
    └── interview_guide.md
```

## GitHub upload

1. Create a GitHub account (if you do not already have one).
2. Click **New repository**.
3. Name it `retail-sales-inventory-sql`.
4. Set it to **Public** if you want recruiters to view it.
5. Add the project files by extracting this ZIP and using **Add file → Upload files**, or use Git:

```bash
git init
git add .
git commit -m "Build retail sales and inventory SQL project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/retail-sales-inventory-sql.git
git push -u origin main
```

Replace `YOUR-USERNAME` with your GitHub username. Do not upload passwords, database credentials, or private customer data.

## Resume entry

**Retail Sales & Inventory Management System | MySQL 8.0**
- Designed a relational database for customers, products, orders, payments, and inventory using primary/foreign keys and integrity constraints.
- Implemented joins, subqueries, CTEs, views, stored procedures, functions, triggers, and transaction handling.
- Automated stock deduction and order-total calculation using triggers; developed analytical queries for revenue, product performance, and low-stock monitoring.

Only list the technologies and features you have personally run and can explain in an interview.

## Notes

- This is a database-focused portfolio project, not a web application. It is run through MySQL Workbench or the MySQL command line.
- `RIGHT JOIN` is demonstrated in the query file; it is included for SQL concept coverage even though equivalent `LEFT JOIN` queries are often preferred in production.
- The stored procedure creates one product line per order to keep the procedure beginner-friendly. The underlying schema supports multiple order lines per order.
- For production use, add authentication/authorization, audit policies, returns/refunds, tax/shipping rules, and more comprehensive concurrency controls.
