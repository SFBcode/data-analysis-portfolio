# Exercise 5
# The Human Resources department has identified an error in the account number associated with the credit card with ID CcU-2938. The information that should be displayed for this record is: TR323456312213576817699999. Remember to show that the change was made.

# find the information for id CcU-2938:
SELECT * 
FROM credit_card
WHERE id = "CcU-2938";

# update the iban number:
UPDATE credit_card
SET iban = "TR323456312213576817699999"
WHERE id = "CcU-2938";
