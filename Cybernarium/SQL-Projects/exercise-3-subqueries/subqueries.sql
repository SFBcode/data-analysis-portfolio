-- Exercise 3 Using only subqueries (without using JOIN):

# It shows all transactions made by companies in Germany.
SELECT *
FROM transaction AS t
WHERE t.company_id in(
	SELECT id 
	FROM company
	WHERE country = "Germany");

# Lists companies that have made transactions for an amount greater than the average of all transactions.
SELECT DISTINCT c.company_name
FROM company AS c
WHERE c.id IN (
	SELECT t.company_id
	FROM transaction AS t
    WHERE t.amount > (SELECT AVG(t.amount)
		FROM transaction AS t
		WHERE declined = 0));

# They will eliminate from the system companies that do not have registered transactions, provide a list of these companies.
SELECT c.company_name
FROM company AS c
WHERE c.id NOT IN (SELECT t.company_id
	FROM transaction AS t)
;