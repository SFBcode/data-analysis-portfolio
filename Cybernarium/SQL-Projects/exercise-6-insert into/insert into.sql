-- Exercise 6
# In the "transaction" table, enter a new transaction with the following information:

# Id 108B1D1D-5B23-A76C-55EF-C568E49A99DD 
# credit_card_id CcU-9999 
# company_id b-9999 
# user_id 9999 
# lat 829.999 
# longitude -117.999 
# amount 111.11 
# declined 0 

# insert the missing company and credit card first:

# insert info to transaction:
INSERT INTO transactions.transaction
(
id,
credit_card_id,
company_id,
user_id,
lat,
longitude,
amount,
declined
)
VALUES
(
'108B1D1D-5B23-A76C-55EF-C568E49A99DD',
'CcU-9999',
'b-9999',
9999,
829.999,
-117.999,
111.11,
0
);

# Find credit_card id:
SELECT *
FROM credit_card
WHERE id = 'CcU-9999';

# The id is not found. I will insert the id(the only obligatory camp is 'id'):
INSERT INTO transactions.credit_card
(id)
VALUES
('CcU-9999');

# Find company id:
SELECT *
FROM transactions.company
WHERE id = 'b-9999';

# Id is not found. I will insert the id (the only obligatory camp is 'id'):
INSERT INTO transactions.company
(id)
VALUES
('b-9999');

# Finally, find the row created in transaction:
SELECT *
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';
