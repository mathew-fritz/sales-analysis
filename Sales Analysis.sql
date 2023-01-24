# CSV files were imported beforehand using the table import wizard built into MYSQL Workbench

# Remove strict mode for this session (to avoid issues with datetimes)
SET sql_mode = '';

# DATA IMPORT

-- Create master sales table by appending monthly tables (UNION ALL used to avoid dropping duplicate rows)
DROP TABLE IF EXISTS sales;
CREATE TABLE sales AS
SELECT * FROM sales_january_2019
UNION ALL
SELECT * FROM sales_february_2019
UNION ALL
SELECT * FROM sales_march_2019
UNION ALL
SELECT * FROM sales_april_2019
UNION ALL
SELECT * FROM sales_may_2019
UNION ALL
SELECT * FROM sales_june_2019
UNION ALL
SELECT * FROM sales_july_2019
UNION ALL
SELECT * FROM sales_august_2019
UNION ALL
SELECT * FROM sales_september_2019
UNION ALL
SELECT * FROM sales_october_2019
UNION ALL
SELECT * FROM sales_november_2019
UNION ALL
SELECT * FROM sales_december_2019;

-- Check if master table was succesfully created
SELECT * from sales;

# DATA PREPERATION

-- Find data types of columns and other summary information
DESCRIBE portfolioproject.sales;

-- Rename columns using snake case (lowercase, underscore between words)
ALTER TABLE sales
RENAME COLUMN `Order ID` TO order_id,
RENAME COLUMN Product TO product,
RENAME COLUMN `Quantity Ordered` TO quantity_ordered,
RENAME COLUMN `Price Each` TO price_each,
RENAME COLUMN `Order Date` TO order_date,
RENAME COLUMN `Purchase Address` TO purchase_address;

-- Change date format 
UPDATE sales
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y %H:%i');

-- Convert order date column data type to datetime
ALTER TABLE sales
MODIFY COLUMN order_date DATETIME;

-- Convert 'price_each' column from text to decimal data type (to allow for aggregate functions like sum or average)
ALTER TABLE sales
MODIFY COLUMN price_each DECIMAL(13,2);

-- Create a month column by extracing the month from the orderdate
ALTER TABLE sales
ADD COLUMN month INT(2) AS (MONTH(order_date));

-- Add a ',' between the state and postal code to keep field seperator constant
UPDATE sales
-- The LEFT function extracts characters from the left side of a string (in this case the street, city and state)
-- The RIGHT function extracts characters starting from the right side of a string (in this case the first five characters starting from the right, resulting in the ZIP code)
-- The CONCAT function adds the LEFT and RIGHT function outputs together, along with including a comma before the ZIP code
SET purchase_address = CONCAT(LEFT(purchase_address, LENGTH(purchase_address) -5), ',', RIGHT(purchase_address, 5));

-- Create total_per_row (sales) column by multiplying quantity * price for each row
ALTER TABLE sales
ADD COLUMN total_per_row DECIMAL(13,2) AS (quantity_ordered * price_each);

-- Add state column
ALTER TABLE sales
ADD COLUMN state VARCHAR(255);

-- Extract the state from the purchase address
UPDATE sales
-- Inner query returns a substring (part of the purchase address) containing the state and postal code (seperated by a ',')
-- Outer query returns a substring of the inner query, containg only the state code (such as TX)
SET state =  SUBSTRING_INDEX(SUBSTRING_INDEX(purchase_address, ',', -2), ',', 1);

-- Create quarter column (periods)
ALTER TABLE sales
ADD COLUMN quarter INT;

-- Extract the quarter from the date
UPDATE sales
SET quarter = quarter(order_date);

-- Add city column
alter table sales
add column city VARCHAR(255);

-- Extract the city from the purchase address
UPDATE sales
-- Inner query returns a substring (part of the purchase address) containing the city, state and postal code (seperated by a ',')
-- Outer query returns a substring of the inner query, containg only the city (such as Boston)
SET city = SUBSTRING_INDEX(SUBSTRING_INDEX(purchase_address, ',', -3), ',', 1);

-- Create a hour column
ALTER TABLE sales
ADD COLUMN hour INT;

-- Extract the hour from the order date
UPDATE sales
SET hour = HOUR(order_date);

# DATA ANALYSIS

-- What is the total number of sales?

-- Sum the quantity ordered column
SELECT sum(quantity_ordered)
FROM sales;

-- ANSWER: The total number of sales is 209079.

-- What are the average sales per month?

-- Group total sales by month from highest to lowest
SELECT month, sum(total_per_row) AS sales
FROM sales
GROUP BY month
ORDER BY sales DESC;

-- ANSWER: December had the highest sales at $4 613 443 whle January had the lowest at $1 822 256. 
-- Other months averaged between two to three million in sales. 

-- Which state generated the most sales on average?

-- Group total sales by state from highest to lowest
SELECT state, sum(total_per_row) AS avg_sales
FROM sales
GROUP BY state
ORDER BY avg_sales DESC;

-- ANSWER: California (CA) had the most sales on average with a total of $13 714 774. 
-- The next closest state (New York, "NY") only had $ 4 664 317 in average sales for comparison.

-- When were the best and worst selling periods?

-- Group total sales by quarter from highest to lowest
SELECT quarter, sum(total_per_row) AS sales
FROM sales
GROUP BY quarter
ORDER BY sales DESC;

-- ANSWER: Quarter 4 was most profitable, with sales of $11 549 773 and quarter two was resonably profitable, with sales of $9 121 079. 
-- Quarter's one and three were the least profitable with sales of $6 831 379 and $6 989 803 respectively.  

-- Which products sell best? 

-- Group total sales per product from highest to lowest
SELECT product, count(quantity_ordered) AS number_sold
FROM sales
GROUP BY product
ORDER BY number_sold DESC;

-- ANSWER: The USB-C Charging Cable and Lightning Charging Cable (complement products to the google phone and iPhone respectively) are sold the most at 21903 and 21658 times respectively. 
-- Batteries and headphones are also very popular, being sold around 13325 to 20641 per model. 
-- Next closest product has only been sold 7507 times

-- What city had the highest amount of sales?

-- Group sales by city from highest to lowest
SELECT city, sum(total_per_row) AS sales
FROM sales
GROUP BY city
ORDER BY sales DESC;

-- ANSWER: The city with the highest sales is San Francisco with sales of $8 262 203, over two million higher the next city, Los Angeles. 

-- What products are most often sold together? 

-- Select two products and the amount of times (count) they were sold together
SELECT
  a.product AS product_a,
  b.product AS product_b,
  count(*) AS sold_together
-- Perform a self join on the sales table (based on matching order_id) as we are comparing rows from this table
FROM sales AS a
JOIN sales AS b ON a.order_id = b.order_id
-- This condition ensures unique pairs (otherwise there would be the same two products but in a different order)
AND a.product < b.product
-- Group the orders of both products and display the best selling pairs
GROUP BY a.product, b.product
ORDER BY sold_together DESC;

-- ANSWER: The two most common pairs of products bought together are "iPhone and Lightning Charging Cable" being bought together 1015 times and "Google Phone and USB-C Charging Cable" being bought together 999 times. 
-- Next closest pair is bought 462 times together (iPhone and Wired Headphones). 

-- What time should we display adverstisement to maximize likelihood of customer's buying product? 

-- Group the amount of times that products were ordered by hour from highest to lowest
SELECT hour, count(quantity_ordered) AS frequency
FROM sales
GROUP BY hour
ORDER BY frequency DESC;

-- ANSWER: The 19th hour (7:00pm) is the best time to display advertisements as 12905 products are bought in this hour. 
-- Time ranges of 11-13 (11am to 1pm) and 18-20 (6pm to 8pm) would also be great time ranges to advertise in (average of over 12000 products bought per hour).