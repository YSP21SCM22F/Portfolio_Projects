--<<<<<<Data Cleaning>>>>>>--
--[table CustomerAddress]--
SELECT *
FROM Portfolio_Project..CustomerAddress

SELECT DISTINCT state
FROM Portfolio_Project..CustomerAddress

--Change 'New South Wales' to 'NSW' and 'Victoria' to 'VIC' in 'state' field

UPDATE Portfolio_Project..CustomerAddress
SET state = CASE WHEN state = 'New South Wales' THEN 'NSW'
						WHEN state = 'Victoria' THEN 'VIC'
						ELSE state
						END

--[table CustomerDemographic]--
SELECT *
FROM Portfolio_Project..CustomerDemographic

SELECT DISTINCT gender
FROM Portfolio_Project..CustomerDemographic

--Change 'Femal' to 'F', 'Female' to 'F', and 'Male' to 'M' in 'gender' field

UPDATE Portfolio_Project..CustomerDemographic
SET gender = CASE WHEN gender = 'Femal' THEN 'F'
				  WHEN gender = 'Female' THEN 'F'
				  WHEN gender = 'Male' THEN 'M'
				  ELSE gender
				  END

ALTER TABLE Portfolio_Project..CustomerDemographic
Add age int;

--DOB column contains null value

SELECT DOB
FROM Portfolio_Project..CustomerDemographic
ORDER BY 1 ASC

UPDATE Portfolio_Project..CustomerDemographic
SET age = DATEDIFF(year,DOB,GETDATE())

SELECT DOB, age 
FROM Portfolio_Project..CustomerDemographic
ORDER BY 2 DESC

--job_title column contains null value

SELECT *
FROM Portfolio_Project..CustomerDemographic
WHERE job_title IS NULL

--job_industry_category contains 'n/a' value

SELECT DISTINCT(job_industry_category)
FROM Portfolio_Project..CustomerDemographic

SELECT DISTINCT deceased_indicator
FROM Portfolio_Project..CustomerDemographic

/* Filter out gender = 'U
		      job_title is nulll
			  job_industry_category = 'n/a'
			  deceased_indicator = 'Y'
*/

DELETE FROM Portfolio_Project..CustomerDemographic
	   WHERE gender = 'U'OR job_title IS NULL 
	   OR job_industry_category = 'n/a'
	   OR deceased_indicator = 'Y'

--drop column default

ALTER TABLE Portfolio_Project..CustomerDemographic
DROP COLUMN "default"

SELECT * 
FROM Portfolio_Project..CustomerDemographic

ALTER TABLE Portfolio_Project..Transactions
ADD profit float


--[Table Transactions]--

SELECT *
FROM Portfolio_Project..Transactions

SELECT DISTINCT order_status
FROM Portfolio_Project..Transactions

SELECT brand
FROM Portfolio_Project..Transactions
WHERE brand IS NULL

--filter out cancelled order
--filter out blanks in column brand
DELETE FROM Portfolio_Project..Transactions
       WHERE order_status = 'cancelled'OR brand IS NULL

-- Add column profit
ALTER TABLE Portfolio_Project..Transactions
Add profit float

UPDATE Portfolio_Project..Transactions
SET profit = list_price - standard_cost

----Standardize Date Format

ALTER TABLE Portfolio_Project..Transactions
Add transactionDate_Converted Date;

UPDATE Portfolio_Project..Transactions
SET transactionDate_Converted = CONVERT(date, transaction_date)

ALTER TABLE Portfolio_Project..Transactions
Add first_sold_date Date;

UPDATE Portfolio_Project..Transactions
SET first_sold_date = CONVERT(date, product_first_sold_date)

SELECT transaction_date, transactionDate_Converted
FROM Portfolio_Project..Transactions

--<<<<Data Analysis>>>>--
SELECT *
FROM Portfolio_Project..Transactions T
LEFT JOIN Portfolio_Project..CustomerDemographic Cd
ON T.customer_id = Cd.customer_id

--total profit made by gender
SELECT gender, ROUND(SUM(profit),2) AS total_profit
FROM Portfolio_Project..Transactions T
JOIN Portfolio_Project..CustomerDemographic Cd
ON T.customer_id = Cd.customer_id
GROUP BY gender

--Avg profit by gender
SELECT gender, ROUND(AVG(T.profit),0) AS avg_profit
FROM Portfolio_Project..Transactions T
JOIN Portfolio_Project..CustomerDemographic Cd
ON T.customer_id = Cd.customer_id
GROUP BY gender

--total bike_related_purchases by gender
SELECT gender, SUM(past_3_years_bike_related_purchases) AS total_bike_related_puarchases
FROM Portfolio_Project..CustomerDemographic
GROUP BY gender

--avg bike_related purchases by gender
SELECT gender, AVG(past_3_years_bike_related_purchases) AS avg_bike_related_puarchases
FROM Portfolio_Project..CustomerDemographic
GROUP BY gender

--total number of customers
SELECT COUNT(DISTINCT customer_id) AS total_number_of_customers
FROM Portfolio_Project..Transactions

-----customer demographics-----
ALTER TABLE Portfolio_Project..CustomerDemographic
ADD age_bracket Nvarchar(255);

UPDATE Portfolio_Project..CustomerDemographic
SET age_bracket = (CASE WHEN age < 30 THEN '<30'
						WHEN age < 40 THEN '30-39'
						WHEN age < 50 THEN '40-49'
						WHEN age < 60 THEN '50-59'
						WHEN age < 70 THEN '60-69'
						WHEN age < 80 THEN '70-79'
						ELSE '80+' END)

--number of people by gender in each age bracket
SELECT gender, age_bracket, COUNT(DISTINCT t.customer_id) AS number_of_people
FROM Portfolio_Project..Transactions t  
JOIN Portfolio_Project..CustomerDemographic cd
ON t.customer_id = cd.customer_id
GROUP BY gender, age_bracket
ORDER BY 1,2 DESC

SELECT gender, COUNT(DISTINCT t.customer_id) AS number_of_people
FROM Portfolio_Project..Transactions t  
JOIN Portfolio_Project..CustomerDemographic cd
ON t.customer_id = cd.customer_id
GROUP BY gender

--brand: product line (class: product class) by total quntity sold--
--TOP 10 Goods
WITH CTE AS (
	SELECT *, CONCAT(brand, ': ',product_line, '(class: ',product_class, ')') AS brand_class
	FROM Portfolio_Project..Transactions
)
SELECT TOP 10 brand_class, COUNT(customer_id) AS quantity_sold
FROM CTE
GROUP BY brand_class
ORDER BY 2 DESC

--number of customers in each month
WITH temp AS (
	SELECT MONTH(transactionDate_Converted) AS "month", customer_id
	FROM Portfolio_Project..Transactions
)
SELECT "month", COUNT(DISTINCT customer_id) AS number_of_customers
FROM temp
GROUP BY "month"
ORDER BY 1

--total profit
SELECT ROUND(SUM(profit), 0) AS total_profit
FROM Portfolio_Project..Transactions

--total profit in each month
WITH temp AS (
	SELECT MONTH(transactionDate_Converted) AS "month", profit
	FROM Portfolio_Project..Transactions
)
SELECT "month", ROUND(SUM(profit), 0) AS total_profit
FROM temp
GROUP BY "month"
ORDER BY 1

--total profit in December
SELECT ROUND(SUM(profit), 0) AS total_profit
FROM Portfolio_Project..Transactions
WHERE month(transaction_date) = 12

--total number of customers in each state
SELECT state, COUNT(DISTINCT t.customer_id) AS number_of_customer
FROM Portfolio_Project..Transactions t  
JOIN Portfolio_Project..CustomerAddress ca
ON ca.customer_id = t.customer_id
GROUP BY state
ORDER BY 2 DESC
