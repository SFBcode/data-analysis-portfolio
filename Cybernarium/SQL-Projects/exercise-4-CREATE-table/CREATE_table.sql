CREATE TABLE transactions.credit_card (
	id INT PRIMARY KEY,
    iban VARCHAR(34),
    pan VARCHAR(20),
    pin VARCHAR(10),
    cvv VARCHAR(4),
    expiring_date DATE
);

ALTER TABLE transactions.credit_card
MODIFY id VARCHAR(15) NOT NULL;

ALTER TABLE transactions.transaction
MODIFY credit_card_id VARCHAR(15) NOT NULL;

ALTER TABLE transactions.credit_card
MODIFY expiring_date VARCHAR(20);

SHOW CREATE TABLE transactions.credit_card;

ALTER TABLE transactions.transaction
ADD CONSTRAINT fk_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES transactions.credit_card(id);

SELECT * FROM credit_card;

SHOW CREATE TABLE transactions.transaction;
