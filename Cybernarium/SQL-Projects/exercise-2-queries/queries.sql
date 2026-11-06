-- Using it JOIN you will make the following queries:

# List of countries that are generating sales.
SELECT DISTINCT country
FROM company AS c
INNER JOIN `transaction` AS t
	ON c.id = t.company_id
WHERE t.declined = 0
	AND c.country IS NOT NULL
ORDER BY c.country;

# From how many countries are sales generated?
SELECT COUNT(DISTINCT c.country) AS total_countries
FROM company AS c
INNER JOIN `transaction` AS t
    ON c.id = t.company_id
WHERE t.declined = 0
  AND c.country IS NOT NULL;

# Identify the company with the highest average sales.
SELECT
    c.id,
    c.company_name,
    AVG(t.amount) AS average_sales
FROM company AS c
INNER JOIN `transaction` AS t
    ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY average_sales DESC
LIMIT 1;