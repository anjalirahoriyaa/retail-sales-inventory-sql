# Data Dictionary

| Table | Purpose | Important columns |
|---|---|---|
| customers | Customer master data | `customer_id` PK, `email` unique, name, city |
| categories | Product grouping | `category_id` PK, `category_name` unique |
| products | Product catalogue and current stock | `product_id` PK, `category_id` FK, `sku` unique, price, stock |
| orders | Sales order header | `order_id` PK, `customer_id` FK, status, total |
| order_items | Product lines belonging to an order | `order_item_id` PK, `order_id` FK, `product_id` FK, quantity, unit price |
| payments | Payment attempts/records | `payment_id` PK, `order_id` FK, amount, method, status |
| inventory_movements | Auditable stock changes | `movement_id` PK, `product_id` FK, movement type, quantity change |

## Relationships

- One customer can place many orders (1-to-many).
- One category can contain many products (1-to-many).
- One order can contain many order items (1-to-many).
- One product can appear in many order items (1-to-many).
- One order can have multiple payment records (1-to-many).
- One product can have many inventory movement records (1-to-many).

## Design decisions

- `order_items.unit_price` stores the sale-time price, so later catalogue price changes do not rewrite history.
- `line_total` is a stored generated column (`quantity * unit_price`).
- `orders.total_amount` is maintained by the order-item insert trigger.
- `inventory_movements.quantity_change` is positive for stock added and negative for stock removed.
- Foreign keys protect referential integrity; CHECK constraints protect basic numeric rules.
