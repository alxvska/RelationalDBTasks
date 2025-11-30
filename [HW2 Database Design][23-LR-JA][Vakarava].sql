--1.
IF OBJECT_ID('order_items', 'U') IS NOT NULL DROP TABLE order_items;
IF OBJECT_ID('products', 'U') IS NOT NULL DROP TABLE products;
IF OBJECT_ID('orders', 'U') IS NOT NULL DROP TABLE orders;

-- Orders table
CREATE TABLE orders (
    o_id INT IDENTITY(1,1) PRIMARY KEY,
    o_date DATE NOT NULL
);

-- Products table (initial version)
CREATE TABLE products (
    p_name VARCHAR(50) NOT NULL PRIMARY KEY,
    price DECIMAL(10,2) NOT NULL
);

-- Order_Items table (references products by p_name)
CREATE TABLE order_items (
    order_id INT NOT NULL FOREIGN KEY REFERENCES orders(o_id),
    product_name VARCHAR(50) NOT NULL FOREIGN KEY REFERENCES products(p_name),
    amount INT NOT NULL DEFAULT 1 CHECK(amount > 0),
    PRIMARY KEY(order_id, product_name)
);

-- Inserting data

INSERT INTO orders (o_date) VALUES ('2025-11-01');
INSERT INTO orders (o_date) VALUES ('2025-11-10');

INSERT INTO products VALUES ('p1', 3.50);
INSERT INTO products VALUES ('p2', 7.20);

DECLARE @firstOrder INT = (SELECT MIN(o_id) FROM orders);
DECLARE @secondOrder INT = (SELECT MAX(o_id) FROM orders);

INSERT INTO order_items(order_id, product_name)
VALUES
    (@firstOrder, 'p1'),
    (@firstOrder, 'p2');

INSERT INTO order_items(order_id, product_name, amount)
VALUES
    (@secondOrder, 'p1', 2),
    (@secondOrder, 'p2', 4);

-- 3. Modifying schema to match the new structure
ALTER TABLE products ADD p_id INT IDENTITY(1,1);
ALTER TABLE products ADD CONSTRAINT uq_pname UNIQUE (p_name);

-- Finding FK in order_items referencing products (by p_name)
DECLARE @oldFK NVARCHAR(128);

SELECT @oldFK = fk.name
FROM sys.foreign_keys fk
JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE t.name = 'order_items';

-- Drop FK if exists
IF @oldFK IS NOT NULL
    EXEC('ALTER TABLE order_items DROP CONSTRAINT ' + @oldFK);

--Drop old primary key from products
DECLARE @oldPK NVARCHAR(128);

SELECT @oldPK = kc.name
FROM sys.key_constraints kc
JOIN sys.tables t ON kc.parent_object_id = t.object_id
WHERE t.name = 'products' AND kc.type = 'PK';

IF @oldPK IS NOT NULL
    EXEC('ALTER TABLE products DROP CONSTRAINT ' + @oldPK);

--Add new primary key (p_id)
ALTER TABLE products ADD CONSTRAINT pk_products PRIMARY KEY (p_id);

--Adding new fields to order_items
ALTER TABLE order_items ADD 
    p_id INT NULL,
    price DECIMAL(10,2) NULL,
    total DECIMAL(14,2) NULL;

--Filling p_id by matching product_name
UPDATE oi
SET oi.p_id = p.p_id
FROM order_items oi
JOIN products p ON oi.product_name = p.p_name;

--Copying product prices
UPDATE oi
SET oi.price = p.price
FROM order_items oi
JOIN products p ON oi.p_id = p.p_id;

--Calculating totals
UPDATE order_items SET total = amount * price;

--Setting new columns to NOT NULL
ALTER TABLE order_items ALTER COLUMN p_id INT NOT NULL;
ALTER TABLE order_items ALTER COLUMN price DECIMAL(10,2) NOT NULL;
ALTER TABLE order_items ALTER COLUMN total DECIMAL(14,2) NOT NULL;

--Adding check constraint
ALTER TABLE order_items
ADD CONSTRAINT chk_total CHECK (total = amount * price);

--Recreating FK to new primary key
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_pid FOREIGN KEY(p_id) REFERENCES products(p_id);


--4.

-- Renaming p1 → product1
UPDATE products SET p_name = 'product1' WHERE p_name = 'p1';
UPDATE order_items SET product_name = 'product1' WHERE product_name = 'p1';

-- Removing product p2 from the first order
DELETE FROM order_items
WHERE order_id = @firstOrder AND product_name = 'p2';

-- Deleting the second order entirely
DELETE FROM order_items WHERE order_id = @secondOrder;
DELETE FROM orders WHERE o_id = @secondOrder;

-- Updating price of product1 to 5
UPDATE products SET price = 5 WHERE p_name = 'product1';

UPDATE oi
SET oi.price = p.price,
    oi.total = oi.amount * p.price
FROM order_items oi
JOIN products p ON oi.p_id = p.p_id
WHERE p.p_name = 'product1';

-- Adding a new order with today’s date
INSERT INTO orders (o_date) VALUES (CAST(GETDATE() AS DATE));

DECLARE @newOrder INT = SCOPE_IDENTITY();

-- Adding 3 units of product1
INSERT INTO order_items(order_id, product_name, p_id, amount, price, total)
SELECT 
    @newOrder,
    p_name,
    p_id,
    3,
    price,
    3 * price
FROM products
WHERE p_name = 'product1';

-- OUTPUT 
PRINT 'PRODUCTS TABLE';
SELECT * FROM products ORDER BY p_id;

PRINT 'ORDERS TABLE';
SELECT * FROM orders ORDER BY o_id;

PRINT 'ORDER_ITEMS TABLE';
SELECT * FROM order_items ORDER BY order_id, product_name;


