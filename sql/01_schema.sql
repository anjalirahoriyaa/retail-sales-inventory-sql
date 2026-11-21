-- Retail Sales & Inventory Management System
-- MySQL 8.0.16+
-- WARNING: this script recreates the database and removes any existing copy.
DROP DATABASE IF EXISTS retail_management;
CREATE DATABASE retail_management
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE retail_management;

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20),
    city VARCHAR(80),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    product_name VARCHAR(120) NOT NULL,
    sku VARCHAR(40) NOT NULL UNIQUE,
    unit_price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 5,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category
      FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT chk_products_price CHECK (unit_price >= 0),
    CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_products_reorder CHECK (reorder_level >= 0),
    INDEX idx_products_category (category_id),
    INDEX idx_products_name (product_name)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status ENUM('PENDING','PROCESSING','SHIPPED','DELIVERED','CANCELLED')
      NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_orders_customer
      FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT chk_orders_total CHECK (total_amount >= 0),
    INDEX idx_orders_customer_date (customer_id, order_date),
    INDEX idx_orders_status (order_status)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT fk_order_items_order
      FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_order_items_product
      FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price CHECK (unit_price >= 0),
    INDEX idx_order_items_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM('CARD','UPI','CASH','BANK_TRANSFER') NOT NULL,
    payment_status ENUM('PENDING','COMPLETED','FAILED','REFUNDED')
      NOT NULL DEFAULT 'PENDING',
    transaction_reference VARCHAR(80) UNIQUE,
    CONSTRAINT fk_payments_order
      FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0),
    INDEX idx_payments_order_status (order_id, payment_status)
) ENGINE=InnoDB;

CREATE TABLE inventory_movements (
    movement_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    movement_type ENUM('OPENING','SALE','RESTOCK','ADJUSTMENT','RETURN') NOT NULL,
    quantity_change INT NOT NULL,
    reference_note VARCHAR(255),
    movement_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_movements_product
      FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_movements_product_date (product_id, movement_date)
) ENGINE=InnoDB;
