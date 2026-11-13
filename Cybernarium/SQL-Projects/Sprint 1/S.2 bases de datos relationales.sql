	-- -- -- Nivel 1
		-- -- Ex.1
    
		-- Creamos la base de datos
    CREATE DATABASE IF NOT EXISTS transactions;
    USE transactions;
    
		-- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(20) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255));
        
		-- Creamos la tabla transaction
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY NOT NULL,
        credit_card_id VARCHAR(20),
        company_id VARCHAR(20), 
        user_id VARCHAR(255),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN);

	ALTER TABLE transaction
    ADD CONSTRAINT fk_company
    FOREIGN KEY (company_id) REFERENCES company(id)
    ON DELETE SET NULL;
    
    -- -- Ex.2
    
	-- List of countries that are generating sales.
SELECT DISTINCT c.country
FROM company AS c
INNER JOIN `transaction` AS t
	ON c.id = t.company_id
WHERE t.declined = 0;

	-- From how many countries are sales generated?
SELECT COUNT(DISTINCT c.country) AS total_countries
FROM company AS c
INNER JOIN `transaction` AS t
    ON c.id = t.company_id
WHERE t.declined = 0;

	-- Identify the company with the highest average sales.
SELECT c.id, c.company_name, ROUND(AVG(t.amount), 2) AS average_sales
FROM company AS c
INNER JOIN `transaction` AS t ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY average_sales DESC
LIMIT 1;

	-- -- Ex.3

	-- It shows all transactions made by companies in Germany.
SELECT *
FROM transaction AS t
WHERE t.company_id in(
	SELECT id 
	FROM company
	WHERE country = "Germany");

	-- Lists companies that have made transactions for an amount greater than the average of all transactions.
SELECT *
FROM company
WHERE id IN (SELECT company_id
			FROM transaction
			WHERE amount > (SELECT AVG(amount)
							FROM transaction));

	-- They will eliminate from the system companies that do not have registered transactions, provide a list of these companies.
SELECT *
FROM company
WHERE company.id NOT IN(SELECT DISTINCT company_id
						FROM transaction);

	-- -- Ex.4
CREATE TABLE transactions.credit_card (
	id VARCHAR(20) PRIMARY KEY NOT NULL,
    iban VARCHAR(255),
    pan VARCHAR(255),
    pin VARCHAR(255),
    cvv VARCHAR(255),
    expiring_date VARCHAR(255)
);

UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y')
LIMIT 5000;

ALTER TABLE credit_card
MODIFY expiring_date DATE;

ALTER TABLE transaction
ADD CONSTRAINT fk_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id)
ON DELETE SET NULL;

		-- -- Ex.5
	-- find the information for id CcU-2938:
SELECT * 
FROM credit_card
WHERE id = "CcU-2938";

	-- update the iban number:
UPDATE credit_card
SET iban = "TR323456312213576817699999"
WHERE id = "CcU-2938";

	-- find the information for id CcU-2938:
SELECT * 
FROM credit_card
WHERE id = "CcU-2938";


		-- -- Ex.6

	-- Add id to credit_card and id to company
INSERT INTO transactions.credit_card (id)
VALUES ('CcU-9999');

INSERT INTO transactions.company (id)
VALUES ('b-9999');

	-- insert info to transaction:
INSERT INTO transaction
(id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES
('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);

		-- -- Ex.7

DESCRIBE credit_card;

ALTER TABLE credit_card
DROP COLUMN pan;

DESCRIBE credit_card;


		-- Ex.8

CREATE DATABASE IF NOT EXISTS sales;
USE sales;

SET GLOBAL local_infile = 1;
SET SQL_SAFE_UPDATES = 0;


-- 1. CREATE TABLES


-- Dimension table: USERS

CREATE TABLE users (
    id VARCHAR(255) NULL,
    name VARCHAR(255) NULL,
    surname VARCHAR(255) NULL,
    phone VARCHAR(255) NULL,
    email VARCHAR(255) NULL,
    birth_date VARCHAR(255) NULL,
    country VARCHAR(255) NULL,
    city VARCHAR(255) NULL,
    postal_code VARCHAR(255) NULL,
    address VARCHAR(255) NULL,
    signup_date VARCHAR(255) NULL,
    user_segment VARCHAR(255) NULL,
    income_band VARCHAR(255) NULL,
    region VARCHAR(255) NULL
);


-- Dimension table: COMPANIES

CREATE TABLE companies (
    company_id VARCHAR(255) NULL,
    company_name VARCHAR(255) NULL,
    phone VARCHAR(255) NULL,
    email VARCHAR(255) NULL,
    country VARCHAR(255) NULL,
    website VARCHAR(255) NULL,
    merchant_category VARCHAR(255) NULL,
    merchant_price_position VARCHAR(255) NULL
);


-- Dimension table: CREDIT_CARDS

CREATE TABLE credit_cards (
    id VARCHAR(255) NULL,
    user_id VARCHAR(255) NULL,
    iban VARCHAR(255) NULL,
    pan VARCHAR(255) NULL,
    pin VARCHAR(255) NULL,
    cvv VARCHAR(255) NULL,
    track1 VARCHAR(255) NULL,
    track2 VARCHAR(255) NULL,
    expiring_date VARCHAR(255) NULL,
    card_type VARCHAR(255) NULL,
    card_renewal_flag VARCHAR(255) NULL
);


-- Fact table: TRANSACTIONS

CREATE TABLE transactions (
    id VARCHAR(255) NULL,
    card_id VARCHAR(255) NULL,
    business_id VARCHAR(255) NULL,
    timestamp VARCHAR(255) NULL,
    amount VARCHAR(255) NULL,
    declined VARCHAR(255) NULL,
    product_ids VARCHAR(255) NULL,
    user_id VARCHAR(255) NULL,
    lat VARCHAR(255) NULL,
    longitude VARCHAR(255) NULL,
    discount_amount VARCHAR(255) NULL,
    tax_amount VARCHAR(255) NULL,
    shipping_amount VARCHAR(255) NULL,
    channel VARCHAR(255) NULL,
    campaign_id VARCHAR(255) NULL,
    device_type VARCHAR(255) NULL,
    is_international VARCHAR(255) NULL,
    decline_reason VARCHAR(255) NULL,
    distance_km VARCHAR(255) NULL
);



-- 2. LOAD USERS


LOAD DATA LOCAL INFILE
"C:/Users/sarab/Downloads/needed/ex8/N1-Ex.8__american_users.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET region = 'America';


LOAD DATA LOCAL INFILE
"C:/Users/sarab/Downloads/needed/ex8/N1-Ex.8__european_users.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city,
 postal_code, address, signup_date, user_segment, income_band)
SET region = 'Europe';


-- Convert USERS dates

UPDATE users
SET birth_date = DATE_FORMAT(
    STR_TO_DATE(birth_date, '%b %e, %Y'),
    '%Y-%m-%d'
)
WHERE birth_date IS NOT NULL
  AND birth_date LIKE '% %';


UPDATE users
SET signup_date = DATE_FORMAT(
    STR_TO_DATE(signup_date, '%d/%m/%Y'),
    '%Y-%m-%d'
)
WHERE signup_date IS NOT NULL
  AND signup_date LIKE '%/%';


-- Set USERS column types and primary key

ALTER TABLE users
MODIFY id VARCHAR(255) NOT NULL,
MODIFY name VARCHAR(255) NOT NULL,
MODIFY surname VARCHAR(255) NOT NULL,
MODIFY birth_date DATE,
MODIFY signup_date DATE,
ADD PRIMARY KEY (id);



-- 3. LOAD COMPANIES


LOAD DATA LOCAL INFILE
"C:/Users/sarab/Downloads/needed/ex8/N1-Ex.8__companies.csv"
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(company_id, company_name, phone, email, country,
 website, merchant_category, merchant_price_position);


-- Set COMPANIES primary key

ALTER TABLE companies
MODIFY company_id VARCHAR(255) NOT NULL,
MODIFY company_name VARCHAR(255) NOT NULL,
ADD PRIMARY KEY (company_id);



-- 4. LOAD CREDIT CARDS

LOAD DATA LOCAL INFILE
"C:/Users/sarab/Downloads/needed/ex8/N1-Ex.8__credit_cards.csv"
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, user_id, iban, pan, pin, cvv, track1, track2,
 expiring_date, card_type, card_renewal_flag);


-- Convert CREDIT_CARDS expiry dates

-- Handles MM/DD/YY values; leaves already ISO-formatted
-- YYYY-MM-DD values unchanged.

UPDATE credit_cards
SET expiring_date = DATE_FORMAT(
    STR_TO_DATE(expiring_date, '%m/%d/%y'),
    '%Y-%m-%d'
)
WHERE expiring_date IS NOT NULL
  AND expiring_date LIKE '%/%';


-- Set CREDIT_CARDS column types and primary key

ALTER TABLE credit_cards
MODIFY id VARCHAR(255) NOT NULL,
MODIFY user_id VARCHAR(255),
MODIFY expiring_date DATE,
MODIFY card_renewal_flag TINYINT,
ADD PRIMARY KEY (id);


-- 5. LOAD TRANSACTIONS


-- The separator in this CSV file is ";"

LOAD DATA LOCAL INFILE
"C:/Users/sarab/Downloads/needed/ex8/N1-Ex.8__transactions.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, card_id, business_id, timestamp, amount, declined,
 product_ids, user_id, lat, longitude, discount_amount,
 tax_amount, shipping_amount, channel, campaign_id,
 device_type, is_international, decline_reason, distance_km);


-- 6. SET TRANSACTIONS COLUMN TYPES

ALTER TABLE transactions
MODIFY id VARCHAR(255),
MODIFY card_id VARCHAR(255) NULL,
MODIFY business_id VARCHAR(255) NULL,
MODIFY timestamp DATETIME,
MODIFY amount DECIMAL(10,2),
MODIFY declined TINYINT,
MODIFY product_ids VARCHAR(255),
MODIFY user_id VARCHAR(255) NULL,
MODIFY lat DOUBLE,
MODIFY longitude DOUBLE,
MODIFY discount_amount DECIMAL(10,2),
MODIFY tax_amount DECIMAL(10,2),
MODIFY shipping_amount DECIMAL(10,2),
MODIFY channel VARCHAR(255),
MODIFY campaign_id VARCHAR(255),
MODIFY device_type VARCHAR(255),
MODIFY is_international TINYINT,
MODIFY decline_reason VARCHAR(255),
MODIFY distance_km DECIMAL(10,2);


-- 7. CREATE FOREIGN KEYS

-- Transactions -> Credit cards

ALTER TABLE transactions
ADD CONSTRAINT transaction_credit_card_fk
FOREIGN KEY (card_id)
REFERENCES credit_cards(id)
ON DELETE SET NULL;


-- Transactions -> Companies

ALTER TABLE transactions
ADD CONSTRAINT transaction_company_fk
FOREIGN KEY (business_id)
REFERENCES companies(company_id)
ON DELETE SET NULL;


-- Transactions -> Users

ALTER TABLE transactions
ADD CONSTRAINT transaction_user_fk
FOREIGN KEY (user_id)
REFERENCES users(id)
ON DELETE SET NULL;


-- 8. FINISH

SET SQL_SAFE_UPDATES = 1;

-- Check tables

SHOW TABLES;

DESCRIBE users;
DESCRIBE companies;
DESCRIBE credit_cards;
DESCRIBE transactions;

		-- Ex.9
        
	-- Perform a subquery that shows all users with more than 80 transactions using at least 2 tables.

SELECT u.id, u.name, u.surname
FROM users AS u
WHERE u.id in(
	SELECT t.user_id
	FROM transactions AS t
	GROUP BY t.user_id
	HAVING COUNT(*) > 80);
    
		-- Ex.10
        
	-- Shows the average amount per IBAN of credit cards in the company Donec Ltd, uses at least 2 tables.
	-- company donec: iban: avg amount of credit cards:

SELECT cc.iban, ROUND(AVG(t.amount), 2) AS avg_amount
FROM credit_cards AS cc
INNER JOIN transactions AS t
	ON cc.id = t.card_id
INNER JOIN companies AS cp
	ON t.business_id = cp.company_id
WHERE cp.company_name = "Donec Ltd"
GROUP BY cc.iban;

		-- -- Nivel 2
	-- Ex.1
    
-- Identifies the five days that generated the highest amount of revenue for your business from sales. It shows the date of each transaction along with the total sales.

SELECT 
    DATE(`timestamp`) AS transaction_date,
    SUM(amount) AS total_sales
FROM transactions
GROUP BY DATE(`timestamp`)
ORDER BY total_sales DESC
LIMIT 5;

		-- Ex.2
        
SELECT companies.company_name,
companies.phone,
companies.country,
DATE(transactions. timestamp) AS date,
transactions.amount
FROM companies
INNER JOIN transactions ON transactions.business_id = companies.company_id
WHERE transactions.amount BETWEEN 350 AND 400
AND DATE(transactions.timestamp ) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY transactions.amount DESC;

		-- Ex.3
        
-- Company Transactions by Date and Amount

SELECT cp.company_name, COUNT(*) AS total_transactions,
	CASE
        WHEN COUNT(*) >= 400 THEN '400 or more' 
        ELSE 'Less than 400'
    END AS transaction_category
FROM transactions AS t
INNER JOIN companies AS cp
	ON t.business_id = cp.company_id
GROUP BY cp.company_id, cp.company_name
ORDER BY transaction_category DESC;

	-- Ex.4
    
-- Delete transaction:

SELECT * FROM transactions
WHERE id LIKE "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

SET SQL_SAFE_UPDATES = 0;
DELETE FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM transactions
WHERE id LIKE "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

	-- Ex.5
    
-- VistaMarketing

CREATE OR REPLACE VIEW VistaMarketing AS
SELECT cp.company_name, cp.phone, cp.country, ROUND(AVG(amount), 2) AS avg_purchase
FROM transactions AS t
INNER JOIN companies AS cp 
	ON t.business_id = cp.company_id
GROUP BY cp.company_id, cp.company_name, cp.phone, cp.country
ORDER BY avg_purchase DESC;

SELECT *
FROM VistaMarketing
ORDER BY avg_purchase DESC;

		-- -- Nivel 3
	-- Ex.1
-- Select the three most recent transactions for each card

-- Create the status table
CREATE TABLE credit_card_status (
    credit_card VARCHAR(255),
    transactions TEXT,
    status VARCHAR(20)
);

-- Insert the three most recent transactions per card
INSERT INTO credit_card_status (
    credit_card,
    transactions,
    status
)
WITH ranked_transactions AS (
    SELECT
        t.card_id,
        t.timestamp,
        t.declined,
        ROW_NUMBER() OVER (
            PARTITION BY t.card_id
            ORDER BY t.timestamp DESC, t.id DESC
        ) AS row_num
    FROM transactions AS t
    WHERE t.card_id IS NOT NULL
)

SELECT
    rt.card_id,

    GROUP_CONCAT(
        rt.declined
        ORDER BY rt.row_num
        SEPARATOR ', '
    ) AS transactions,

    CASE
        WHEN COUNT(*) = 3
             AND SUM(
                 CASE
                     WHEN rt.declined = 1 THEN 1
                     ELSE 0
                 END
             ) = 3
        THEN 'INACTIVE'
        ELSE 'ACTIVE'
    END AS status

FROM ranked_transactions AS rt
WHERE rt.row_num <= 3
GROUP BY rt.card_id;


-- Count active credit cards
SELECT COUNT(*) AS active_cards
FROM credit_card_status
WHERE status = 'ACTIVE';

	-- Ex.2
DROP table products;
-- Create a dimention table products:

CREATE TABLE products (
    id VARCHAR(255),
    product_name VARCHAR(255),
    price VARCHAR(255),
    colour VARCHAR(255),
    weight VARCHAR(255),
    warehouse_id VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    cost VARCHAR(255),
    launch_date VARCHAR(255)
);


-- 2. LOAD PRODUCTS DATA

LOAD DATA LOCAL INFILE
'C:/Users/sarab/Downloads/needed/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id,
 category, brand, cost, launch_date);


-- 3. CLEAN PRICE AND COST

SET SQL_SAFE_UPDATES = 0;
UPDATE products
SET
    price = REPLACE(TRIM(price), '$', ''),
    cost = REPLACE(TRIM(cost), '$', '')
WHERE price IS NOT NULL
   OR cost IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

-- 4. MODIFY COLUMN TYPES AND CREATE PRIMARY KEY


ALTER TABLE products
MODIFY id INT NOT NULL,
MODIFY price DECIMAL(10,2),
MODIFY weight DECIMAL(10,2),
MODIFY cost DECIMAL(10,2),
MODIFY launch_date DATE,
ADD PRIMARY KEY (id);


-- 5. MAKE SURE TRANSACTIONS.ID IS A PRIMARY KEY


-- Run this only if transactions.id does not already
-- have a PRIMARY KEY.

ALTER TABLE transactions
ADD PRIMARY KEY (id);


-- 6. CREATE PRODUCT_TRANSACTION TABLE


CREATE TABLE product_transaction (
    transaction_id VARCHAR(255) NOT NULL,
    product_id INT NOT NULL,

    PRIMARY KEY (transaction_id, product_id),

    CONSTRAINT product_transaction_transaction_fk
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(id),

    CONSTRAINT product_transaction_product_fk
        FOREIGN KEY (product_id)
        REFERENCES products(id)
);


-- 7. SPLIT PRODUCT_IDS INTO INDIVIDUAL ROWS


INSERT INTO product_transaction (
    transaction_id,
    product_id
)
WITH RECURSIVE product_transactions AS (

    -- First product ID from each transaction
    SELECT
        t.id AS transaction_id,

        TRIM(
            SUBSTRING_INDEX(t.product_ids, ',', 1)
        ) AS product_id,

        CASE
            WHEN LOCATE(',', t.product_ids) > 0
            THEN TRIM(
                SUBSTRING(
                    t.product_ids,
                    LOCATE(',', t.product_ids) + 1
                )
            )
            ELSE NULL
        END AS remaining_ids

    FROM transactions AS t
    WHERE t.product_ids IS NOT NULL
      AND TRIM(t.product_ids) <> ''

    UNION ALL

    -- Extract the next product ID
    SELECT
        pt.transaction_id,

        TRIM(
            SUBSTRING_INDEX(pt.remaining_ids, ',', 1)
        ) AS product_id,

        CASE
            WHEN LOCATE(',', pt.remaining_ids) > 0
            THEN TRIM(
                SUBSTRING(
                    pt.remaining_ids,
                    LOCATE(',', pt.remaining_ids) + 1
                )
            )
            ELSE NULL
        END AS remaining_ids

    FROM product_transactions AS pt
    WHERE pt.remaining_ids IS NOT NULL
      AND pt.remaining_ids <> ''
)

SELECT
    transaction_id,
    CAST(product_id AS UNSIGNED) AS product_id
FROM product_transactions
WHERE product_id <> '';



-- 8. CHECK RESULTS


SELECT * FROM products;

SELECT * FROM product_transaction;

SELECT COUNT(*) AS total_product_transactions
FROM product_transaction;