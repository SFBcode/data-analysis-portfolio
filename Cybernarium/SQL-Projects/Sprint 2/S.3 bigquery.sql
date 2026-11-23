-- =====================================================================
-- S03: Introduction to BigQuery and Cloud SQL
-- Project: sprint3-analytics-hisamitsu
-- Steps performed through the UI or Cloud Shell are documented in comments.
-- =====================================================================

-- =====================================================================
-- LEVEL 1: Environment and Hybrid Ingestion (Code-First)
-- =====================================================================

-- --- Exercise 1 --------------------------------------------------------
-- Three datasets (Medallion architecture), each created using a different method:
--   sprint3_bronze -> UI
--   sprint3_silver -> CREATE SCHEMA (below)
--   sprint3_gold   -> bq / Cloud Shell (below, in comment)
-- All three are in the same region (EU) to avoid transfer costs between them.

-- sprint3_bronze: UI (Add data -> Create dataset), EU region. The label
-- cannot be added through the creation dialog; it is added afterwards by
-- editing the dataset, with the description "Raw data as ingested from the Data
-- Lake (Bronze layer)".

-- sprint3_silver: label and description are included directly in CREATE SCHEMA

CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-boulhanna.sprint3_silver`
OPTIONS (
    location = 'EU',
    labels = [('layer', 'silver')],
    description = 'Cleaned and typed data (Silver layer)'
);


-- sprint3_gold: create through Cloud Shell using bq (not SQL):
-- bq mk --location=EU --label=layer:gold --description="Business-ready aggregated data (Gold layer)" --dataset sprint3-analytics-hisamitsu:sprint3_gold

-- --- Exercise 2 --------------------------------------------------------
-- External tables pointing to the Data Lake (gs://bootcamp-data-analytics-public),
-- without moving the data. Everything is STRING: Bronze does not perform
-- data typing; that is handled in Silver.

-- transactions_raw: CSV with ";" delimiter
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw` (
    id STRING,
    card_id STRING,
    business_id STRING,
    `timestamp` STRING,
    amount STRING,
    declined STRING,
    product_ids STRING,
    user_id STRING,
    lat STRING,
    longitude STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1
);

-- companies_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-boulhanna.sprint3_bronze.companies_raw` (
    company_id STRING,
    company_name STRING,
    phone STRING,
    email STRING,
    country STRING,
    website STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
    field_delimiter = ',',
    skip_leading_rows = 1
);

-- american_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-boulhanna.sprint3_bronze.american_users_raw` (
    id STRING,
    name STRING,
    surname STRING,
    phone STRING,
    email STRING,
    birth_date STRING,
    country STRING,
    city STRING,
    postal_code STRING,
    address STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
    skip_leading_rows = 1
);

-- european_users_raw: same schema as american_users_raw.
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-boulhanna.sprint3_bronze.european_users_raw` (
    id STRING,
    name STRING,
    surname STRING,
    phone STRING,
    email STRING,
    birth_date STRING,
    country STRING,
    city STRING,
    postal_code STRING,
    address STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
    skip_leading_rows = 1
);

-- credit_cards_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-boulhanna.sprint3_bronze.credit_cards_raw` (
    id STRING,
    user_id STRING,
    iban STRING,
    pan STRING,
    pin STRING,
    cvv STRING,
    track1 STRING,
    track2 STRING,
    expiring_date STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
    skip_leading_rows = 1
);

-- --- Exercise 3 --------------------------------------------------------
-- products.csv is not in the Data Lake: it is uploaded through the UI
-- (Create table -> Upload) to sprint3_bronze.products_raw. Manual schema,
-- all fields as STRING, Auto detect disabled (for the same reason as in Exercise 2).
-- The only native table in Bronze.
-- Source: 02-s02-relational-databases-mysql/resources/N1-Ex.8__products.csv

-- --- Exercise 4 --------------------------------------------------------
-- a) Native copy of transactions_raw, generated with Gemini.
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw_native` AS
SELECT *
FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw`;

-- b) Processed bytes when reading one column, external vs. native (check the Job Information of each query).
SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw`;
SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw_native`;

-- c) LIMIT does not reduce the bytes read in non-clustered tables. In transactions_raw (external), without ORDER BY, the CSV reader stops as soon as it retrieves 10 rows; with ORDER BY, it still reads the entire file.
SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw` LIMIT 10;
SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw_native` LIMIT 10;

SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw` ORDER BY id LIMIT 10;
SELECT id FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw_native` ORDER BY id LIMIT 10;

-- --- Exercise 5 --------------------------------------------------------
-- Top 5 days of 2021 by revenue. timestamp/amount/declined are STRING,
-- hence the use of PARSE_TIMESTAMP and SAFE_CAST. declined = 0 because
-- revenue should not include declined transactions (same criterion as in S02).
SELECT
    DATE(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', `timestamp`)) AS transaction_day,
    SUM(SAFE_CAST(amount AS FLOAT64)) AS daily_income
FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw`
WHERE EXTRACT(YEAR FROM PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', `timestamp`)) = 2021
    AND SAFE_CAST(declined AS INT64) = 0
GROUP BY 1
ORDER BY daily_income DESC
LIMIT 5;

-- --- Exercise 6 --------------------------------------------------------
-- Name, country and date of transactions carried out by companies that
-- made transactions worth between 100 and 200 euros on any of these dates:
-- 29-04-2015, 20-07-2018 or 13-03-2024.
SELECT
    c.company_name,
    c.country,
    EXTRACT(DATE FROM SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) AS transaction_date
FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3-analytics-boulhanna.sprint3_bronze.companies_raw` AS c
    ON t.business_id = c.company_id
WHERE SAFE_CAST(t.amount AS FLOAT64) BETWEEN 100 AND 200
    AND EXTRACT(DATE FROM SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) IN ('2015-04-29', '2018-07-20', '2024-03-13');
-- Note: business_id is in transactions_raw, not company_id.

-- =====================================================================
-- LEVEL 2: Data Cleaning and Transformation (ELT)
-- =====================================================================

-- --- Exercise 1 --------------------------------------------------------
-- products_clean: product_id converted to INT64 (to join with transactions_clean
-- product_ids in Level 3), price/cost without "$" converted to NUMERIC (monetary
-- values), warehouse_id without "WH-" converted to INT64, launch_date converted to DATE.
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_silver.products_clean` AS
SELECT
    SAFE_CAST(id AS INT64) AS product_id,
    product_name AS name,
    SAFE_CAST(REPLACE(price, '$', '') AS NUMERIC) AS price,
    SAFE_CAST(REPLACE(cost, '$', '') AS NUMERIC) AS cost,
    colour,
    weight,
    SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
    category,
    brand,
    SAFE_CAST(launch_date AS DATE) AS launch_date
FROM `sprint3-analytics-boulhanna.sprint3_bronze.products_raw`;

-- --- Exercise 2 --------------------------------------------------------
-- transactions_clean: amount converted to NUMERIC, lat/longitude/user_id
-- converted to numeric types, timestamp parsed, product_ids converted to
-- ARRAY<INT64>. card_id, business_id and declined remain unchanged.
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean` AS
SELECT
    id AS transaction_id,
    card_id,
    business_id,
    SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', `timestamp`) AS `timestamp`,
    IFNULL(SAFE_CAST(amount AS NUMERIC), 0) AS amount,
    declined,
    ARRAY(
        SELECT SAFE_CAST(TRIM(product_id) AS INT64) AS product_id
        FROM UNNEST(SPLIT(product_ids, ',')) AS product_id
    ) AS product_ids,
    SAFE_CAST(user_id AS INT64) AS user_id,
    SAFE_CAST(lat AS FLOAT64) AS lat,
    SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw`;

-- --- Exercise 3 --------------------------------------------------------
-- users_combined: UNION ALL of the US and European users + origin column.
-- id converted to INT64, birth_date converted to DATE ("Jul 2, 1980").
-- postal_code and phone remain STRING: European postal codes are not numeric
-- (e.g. "EC1A 1BB").
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_silver.users_combined` AS
SELECT
    SAFE_CAST(id AS INT64) AS user_id,
    name,
    surname,
    phone,
    email,
    SAFE.PARSE_DATE('%b %e, %Y', birth_date) AS birth_date,
    country,
    city,
    postal_code,
    address,
    'US' AS origin
FROM `sprint3-analytics-boulhanna.sprint3_bronze.american_users_raw`
UNION ALL
SELECT
    SAFE_CAST(id AS INT64) AS user_id,
    name,
    surname,
    phone,
    email,
    SAFE.PARSE_DATE('%b %e, %Y', birth_date) AS birth_date,
    country,
    city,
    postal_code,
    address,
    'EU' AS origin
FROM `sprint3-analytics-hisamitsu.sprint3_bronze.european_users_raw`;

-- --- Exercise 4 --------------------------------------------------------
-- companies_clean: direct copy to a native table. companies_raw already
-- has the key as company_id, so there is no need to rename it. credit_cards_clean
-- is created below, with sensitive fields masked.

-- pin, cvv, track1 and track2 are not copied to Silver: there is no need
-- to retain them, and these are exactly the type of card details that
-- should not be exposed beyond Bronze. pan is masked, keeping only the
-- last 4 digits.
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint3-analytics-boulhanna.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_silver.credit_cards_clean` AS
SELECT
    id AS credit_card_id,
    user_id,
    iban,
    CONCAT('************', SUBSTR(pan, -4)) AS pan_masked,
    SAFE.PARSE_DATE('%m/%d/%y', expiring_date) AS expiring_date
FROM `sprint3-analytics-boulhanna.sprint3_bronze.credit_cards_raw`;

-- --- Data Quality Checks (Bronze -> Silver) -----------------------------
-- Row counts: Bronze and Silver should match; no table should lose rows
-- during the cleaning process.
SELECT
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_bronze.products_raw`) AS products_bronze,
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_silver.products_clean`) AS products_silver,
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw`) AS transactions_bronze,
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean`) AS transactions_silver,
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_bronze.credit_cards_raw`) AS credit_cards_bronze,
    (SELECT COUNT(*) FROM `sprint3-analytics-boulhanna.sprint3_silver.credit_cards_clean`) AS credit_cards_silver;

-- New NULLs after SAFE_CAST: a NULL value in Silver that was not empty
-- or NULL in the source indicates a conversion failure (unexpected format),
-- rather than a genuine NULL in the original data.
SELECT
    COUNTIF(p.price IS NULL AND r.price IS NOT NULL AND r.price != '') AS price_cast_failures,
    COUNTIF(p.cost IS NULL AND r.cost IS NOT NULL AND r.cost != '') AS cost_cast_failures,
    COUNTIF(p.launch_date IS NULL AND r.launch_date IS NOT NULL AND r.launch_date != '') AS launch_date_cast_failures
FROM `sprint3-analytics-boulhanna.sprint3_bronze.products_raw` AS r
JOIN `sprint3-analytics-boulhanna.sprint3_silver.products_clean` AS p
    ON SAFE_CAST(r.id AS INT64) = p.product_id;

SELECT
    COUNTIF(t.amount IS NULL) AS amount_cast_failures,
    COUNTIF(t.timestamp IS NULL) AS timestamp_cast_failures,
    COUNTIF(t.user_id IS NULL AND r.user_id != '') AS user_id_cast_failures
FROM `sprint3-analytics-boulhanna.sprint3_bronze.transactions_raw` AS r
JOIN `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean` AS t
    ON r.id = t.transaction_id;

-- Duplicate keys in each Silver table.
SELECT 'products_clean' AS table_name, COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_keys
FROM `sprint3-analytics-boulhanna.sprint3_silver.products_clean`
UNION ALL
SELECT 'transactions_clean', COUNT(*) - COUNT(DISTINCT transaction_id)
FROM `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean`
UNION ALL
SELECT 'credit_cards_clean', COUNT(*) - COUNT(DISTINCT credit_card_id)
FROM `sprint3-analytics-boulhanna.sprint3_silver.credit_cards_clean`;

-- =====================================================================
-- LEVEL 3: Data Presentation and View Creation
-- =====================================================================

-- --- Exercise 1 --------------------------------------------------------
-- Marketing view: company name, phone number and country, average
-- purchase amount and customer classification (Premium if the average > 260€).
-- Declined transactions (declined = '1') are excluded from the calculation:
-- the same criterion used in Level 1, Exercise 5, so that "sales" has the
-- same meaning across all Gold metrics.
CREATE OR REPLACE VIEW `sprint3-analytics-boulhanna.sprint3_gold.v_marketing_kpis` AS
SELECT
    company.company_name,
    company.phone,
    company.country,
    ROUND(AVG(transactions.amount), 2) AS average_amount,
    IF(AVG(transactions.amount) > 260, 'Premium', 'Standard') AS client_tier
FROM `sprint3-analytics-boulhanna.sprint3_silver.companies_clean` AS company
INNER JOIN `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean` AS transactions
    ON company.company_id = transactions.business_id
WHERE transactions.declined = '0'
-- company_id is included in GROUP BY (even though it is not in SELECT)
-- to avoid grouping different companies that share the same name/phone/country.
GROUP BY company.company_id, company.company_name, company.phone, company.country;

-- Submission query. There is no need to sort by client_tier: it is a direct
-- function of average_amount (threshold at 260), so sorting only by
-- average_amount already places Premium customers first.
SELECT *
FROM `sprint3-analytics-boulhanna.sprint3_gold.v_marketing_kpis`
ORDER BY average_amount DESC;

-- --- Exercise 2 --------------------------------------------------------
-- Product ranking: flatten product_ids from transactions_clean and
-- count sales. LEFT JOIN from products_clean to avoid losing products
-- with 0 sales. Excludes declined transactions, using the same
-- criterion as in v_marketing_kpis.
CREATE OR REPLACE TABLE `sprint3-analytics-boulhanna.sprint3_gold.product_sales_ranking` AS
WITH products_sold AS (
    SELECT product_id
    FROM `sprint3-analytics-boulhanna.sprint3_silver.transactions_clean`,
        UNNEST(product_ids) AS product_id
    WHERE declined = '0'
)
SELECT
    products.product_id,
    products.name,
    products.price,
    products.colour,
    COUNT(products_sold.product_id) AS total_sold
FROM `sprint3-analytics-boulhanna.sprint3_silver.products_clean` AS products
LEFT JOIN products_sold ON products.product_id = products_sold.product_id
GROUP BY products.product_id, products.name, products.price, products.colour;

-- --- Exercise 3 --------------------------------------------------------
-- Export: product_sales_ranking table -> "Open in" -> "Connected
-- Sheets". No additional SQL is required.