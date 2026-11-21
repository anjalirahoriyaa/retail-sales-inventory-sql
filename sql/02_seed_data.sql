USE retail_management;

INSERT INTO customers (first_name, last_name, email, phone, city) VALUES
('Aarav','Sharma','aarav.sharma@example.com','9876500001','Meerut'),
('Diya','Verma','diya.verma@example.com','9876500002','Delhi'),
('Kabir','Singh','kabir.singh@example.com','9876500003','Noida'),
('Anaya','Gupta','anaya.gupta@example.com','9876500004','Ghaziabad'),
('Ishaan','Kumar','ishaan.kumar@example.com','9876500005','Hapur'),
('Meera','Jain','meera.jain@example.com','9876500006','Meerut');

INSERT INTO categories (category_name, description) VALUES
('Electronics','Electronic devices and accessories'),
('Home & Kitchen','Useful household products'),
('Stationery','Office and study supplies'),
('Accessories','Everyday personal accessories');

INSERT INTO products
(category_id, product_name, sku, unit_price, stock_quantity, reorder_level) VALUES
(1,'Wireless Mouse','ELEC-MOU-001',799.00,40,8),
(1,'Mechanical Keyboard','ELEC-KEY-002',2499.00,25,5),
(1,'USB-C Hub','ELEC-HUB-003',1499.00,18,4),
(2,'Insulated Water Bottle','HOME-BOT-004',599.00,50,10),
(2,'Desk Lamp','HOME-LAM-005',1299.00,20,5),
(3,'Notebook Pack','STAT-NOT-006',249.00,100,20),
(3,'Gel Pen Set','STAT-PEN-007',149.00,80,15),
(4,'Laptop Sleeve','ACC-SLV-008',899.00,6,8),
(4,'Phone Stand','ACC-STD-009',399.00,30,6),
(1,'Webcam','ELEC-WEB-010',1899.00,12,4);

-- Opening stock movements document the starting inventory.
INSERT INTO inventory_movements
(product_id, movement_type, quantity_change, reference_note)
SELECT product_id, 'OPENING', stock_quantity, 'Initial seed stock'
FROM products;

-- Historical orders. The order-item trigger (created in script 03) will
-- deduct stock and calculate totals when this script is run after script 03.
-- Therefore, run script 03 before this seed script if you want triggers active.
-- To keep the documented setup order simple, these orders are inserted by
-- the optional demo block in 03 after trigger creation; this file seeds
-- master data only.
