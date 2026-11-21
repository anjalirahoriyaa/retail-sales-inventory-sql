USE retail_management;

DELIMITER $$

CREATE TRIGGER trg_order_items_before_insert
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT NULL;
    DECLARE v_active BOOLEAN DEFAULT FALSE;

    SELECT stock_quantity, is_active
      INTO v_stock, v_active
      FROM products
     WHERE product_id = NEW.product_id
     FOR UPDATE;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Product does not exist';
    END IF;

    IF v_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Product is inactive and cannot be sold';
    END IF;

    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Order quantity must be greater than zero';
    END IF;

    IF NEW.quantity > v_stock THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
END$$

CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
       SET stock_quantity = stock_quantity - NEW.quantity
     WHERE product_id = NEW.product_id;

    INSERT INTO inventory_movements
      (product_id, movement_type, quantity_change, reference_note)
    VALUES
      (NEW.product_id, 'SALE', -NEW.quantity,
       CONCAT('Order #', NEW.order_id));

    UPDATE orders
       SET total_amount = (
           SELECT COALESCE(SUM(line_total), 0)
             FROM order_items
            WHERE order_id = NEW.order_id
       )
     WHERE order_id = NEW.order_id;
END$$

CREATE FUNCTION fn_customer_lifetime_value(p_customer_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(o.total_amount), 0.00)
      INTO v_total
      FROM orders o
     WHERE o.customer_id = p_customer_id
       AND o.order_status <> 'CANCELLED';

    RETURN v_total;
END$$

CREATE PROCEDURE sp_place_single_item_order(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_payment_method VARCHAR(20)
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_method VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_method = UPPER(p_payment_method);

    IF v_method NOT IN ('CARD','UPI','CASH','BANK_TRANSFER') THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Invalid payment method';
    END IF;

    START TRANSACTION;

    SELECT unit_price
      INTO v_unit_price
      FROM products
     WHERE product_id = p_product_id
       AND is_active = TRUE
     FOR UPDATE;

    INSERT INTO orders (customer_id, order_status)
    VALUES (p_customer_id, 'PROCESSING');

    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_quantity, v_unit_price);

    SELECT total_amount
      INTO v_total
      FROM orders
     WHERE order_id = v_order_id;

    INSERT INTO payments
      (order_id, amount, payment_method, payment_status, transaction_reference)
    VALUES
      (v_order_id, v_total, v_method, 'COMPLETED',
       CONCAT('DEMO-', v_order_id, '-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s')));

    COMMIT;

    SELECT v_order_id AS created_order_id,
           v_total AS order_total,
           'SUCCESS' AS result;
END$$

DELIMITER ;

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    o.total_amount,
    COALESCE(p.paid_amount, 0.00) AS paid_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN (
    SELECT order_id, SUM(amount) AS paid_amount
    FROM payments
    WHERE payment_status = 'COMPLETED'
    GROUP BY order_id
) p ON p.order_id = o.order_id;

CREATE OR REPLACE VIEW vw_product_stock_status AS
SELECT
    product_id,
    product_name,
    sku,
    stock_quantity,
    reorder_level,
    CASE
      WHEN stock_quantity = 0 THEN 'OUT OF STOCK'
      WHEN stock_quantity <= reorder_level THEN 'LOW STOCK'
      ELSE 'IN STOCK'
    END AS stock_status
FROM products
WHERE is_active = TRUE;

-- Demo sales are created after the triggers and procedure exist.
CALL sp_place_single_item_order(1, 1, 2, 'UPI');
CALL sp_place_single_item_order(2, 2, 1, 'CARD');
CALL sp_place_single_item_order(3, 4, 3, 'CASH');
CALL sp_place_single_item_order(1, 6, 5, 'UPI');
CALL sp_place_single_item_order(4, 3, 1, 'CARD');
CALL sp_place_single_item_order(5, 8, 1, 'UPI');
CALL sp_place_single_item_order(6, 9, 2, 'CASH');

-- Make historical sample order dates more useful for month-based reports.
UPDATE orders SET order_date = DATE_SUB(NOW(), INTERVAL 3 MONTH) WHERE order_id = 1;
UPDATE orders SET order_date = DATE_SUB(NOW(), INTERVAL 2 MONTH) WHERE order_id = 2;
UPDATE orders SET order_date = DATE_SUB(NOW(), INTERVAL 1 MONTH) WHERE order_id IN (3,4);
