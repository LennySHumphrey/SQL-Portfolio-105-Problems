-- ============================================
-- BASICS SECTION (B1-B35)
-- SQL Practice Problems - Full Solutions with Comments
-- ============================================
-- Author: Lenny Success Humphrey
-- Database: PostgreSQL
-- Schema: E-Commerce Business Database
-- ============================================



---- B1 Return all columns from Customers 
SELECT *
FROM Customers 


---- B2 Return name, email, country for Customers 
SELECT 
    Customer_Name,
    Customer_Email,
    Country
FROM Customers 


---- B3 Find all customers from Nigeria 
SELECT 
    Customer_Name,
    Customer_Email,
    Country
FROM Customers 
WHERE Country = 'Nigeria'


---- B4 List all customers created after 2024-12-31 
SELECT *
FROM Customers 
WHERE Created_At > '2024-12-31'


---- B5 Show unique countries of customers (no duplicates)
SELECT DISTINCT 
    Country
FROM Customers 
WHERE Country IS NOT NULL


---- B6 Show products ordered by price descending 
SELECT *
FROM Products
ORDER BY Price DESC


---- B7 Show the 3 cheapest products 
SELECT 
    Product_ID, 
    Product_Name, 
    Price 
FROM Products
ORDER BY Price ASC
LIMIT 3


---- B8 Count the total number of customers 
SELECT 
    COUNT(*) AS Number_Of_Customers
FROM Customers 


---- B9 Compute total revenue from Orders SUM(Total_Amount)
SELECT 
    SUM(Total_Amount) AS Total_Revenue_By_Orders 
FROM Orders 


---- B10 Compute average order value 
SELECT 
    TRIM_SCALE(AVG(Total_Amount)) AS Average_Order_Value  --TRIM_SCALE for removing trailing zeros. TRIM_SCALE may not exist in all PostGres installs, check your version
FROM Orders 


---- B11 Find min and max product price 
SELECT 
    MIN(Price) AS Min_Price,
    MAX(Price) AS Max_Price
FROM Products


---- B12 Show the number of customers per country (GROUP BY)
SELECT 
    COUNT(Customer_ID),
    Country 
FROM Customers 
GROUP BY Country 


---- B13 Show each product with total units sold (sum quantity) using Order_Items
SELECT 
    P.Product_ID,
    P.Product_Name,
    P.Price,
    COALESCE(SUM(OI.Quantity), 0) AS Total_Units_Sold -- To handle NULLs
FROM Products AS P
LEFT JOIN Order_Items AS OI
ON P.Product_ID = OI.Product_ID
GROUP BY P.Product_ID --We should include all columns in the SELECT statement to be safe but PostGres allows grouping via Primary key only. Feel free to add the rest as well. Check for functional dependency in columns in the SELECT clause before doing so, else it won't work.
ORDER BY P.Price 


---- B14 Show each order with its customer name (Join Orders with Customers)
SELECT 
    Order_ID,
    C.Customer_ID,
    C.Customer_Name,
    O.Order_Date,
    O.Total_Amount 
FROM Orders AS O
LEFT JOIN Customers AS C
ON C.Customer_ID = O.Customer_ID 


---- B15 Show customers who have never placed an order
SELECT 
    O.Order_ID,
    C.Customer_ID,
    C.Customer_Name
FROM Customers AS C
LEFT JOIN Orders AS O
ON C.Customer_ID = O.Customer_ID 
WHERE Order_ID IS NULL


---- B16 For Order_ID = 2, shOW its products name and quantity (Join Order_Items to Products)
SELECT 
    O.Order_ID,
    P.Product_Name,
    OI.Quantity 
FROM Orders AS O 
LEFT JOIN Order_Items AS OI
ON O.Order_ID = OI.Order_ID 
LEFT JOIN Products AS P
ON OI.Product_ID = P.Product_ID 
WHERE O.Order_ID = 2


---- B17 For every order item, compute Line_Total = Unit_Price * Quantity 
SELECT 
    OI.Order_ID,
    OI.Line_Number, 
    P.Product_Name,
    OI.Unit_Price,
    OI.Quantity,
    (Unit_Price * Quantity) AS Line_Total
FROM Order_Items AS OI
LEFT JOIN Products AS P
ON OI.Product_ID = P.Product_ID


---- B18 Show products that have never been ordered 
SELECT 
    OI.Order_ID,
    P.Product_ID,
    P.SKU,
    P.Product_Name
FROM Products AS P
LEFT JOIN Order_Items AS OI
ON OI.Product_ID = P.Product_ID
WHERE OI.Order_ID IS NULL 

-- Option 2; NOT EXISTS for a shorter simpler query
SELECT P.*
FROM Products P
WHERE NOT EXISTS -- Filters the results to include only rows that do not return data from the subquery below; basically it will show in Products what does not exist in the subquery linking Products to Order_Items
(
    SELECT 1 
    FROM Order_Items OI 
    WHERE OI.Product_ID = P.Product_ID
)


---- B19 Show orders with status = 'pending'
SELECT *
FROM orders
WHERE status = 'pending'
--Turns out writing Pending instead of pending won't make the query to work. SSMS didn't have this uppercase problem.


---- B20 Insert a new customer
INSERT INTO Customers (customer_id, customer_name, customer_email, country, Created_At)
VALUES
(9, 'Janet', 'bossyjanet@gmail.com', 'Madagascar', '2024-12-12T08:06:00Z')


---- B21  Update a customer's country (example: set customer_id=4 country to 'Ghana')
UPDATE Customers 
SET Country = 'Ghana'
WHERE Customer_ID = 4


---- B22 Delete a test customer with a specific id
DELETE FROM Customers
WHERE customer_id = 9 


---- B23 Find products priced above the average product price (subquery)
SELECT 
    Product_ID,
    Product_Name,
    Price
FROM (
    SELECT 
    Product_ID,
    Product_Name,
    Price,
    TRIM_SCALE(AVG(Price) OVER()) AS Avg_Price
FROM products
GROUP BY Product_ID, Product_Name
)
WHERE Price > Avg_Price
--OR, sourced out a better query--
SELECT *
FROM Products
WHERE Price > 
(
    SELECT AVG(Price) 
    FROM Products
)--Much shorter, LESSON LEARNED!!!


---- B24 Use COALESCE to show customer email or 'no-email' when NULL
SELECT 
    Customer_ID,
    Customer_Name,
    COALESCE(Customer_Email, 'No Email'),
    COALESCE(Country, 'No Country')
FROM Customers


---- B25 Use CASE to label orders as 'big' if total_amount >= 500 else 'small'
SELECT *,
    CASE 
    WHEN Total_Amount >= 500 THEN 'Big'
    WHEN Total_Amount >=300 THEN 'Medium'
    ELSE 'Small'
    END AS Case_Column
FROM Orders 
ORDER BY Case_Column


---- B26  Find orders in the last 90 days (use now() / interval)
SELECT *
FROM Orders
WHERE Order_Date >= now() - INTERVAL '250 days'
--Had to use 250 days cause 90 days wasn't bringing up any data. My dataset doesn't have data going that far back.


---- B27 Use LIKE to find customers whose name starts with 'A'
SELECT *
FROM customers  
WHERE  Customer_Name LIKE 'A%'


---- B28 Count distinct products ordered per order (COUNT(DISTINCT product_id) per order)
SELECT
    Order_ID,
    COUNT(DISTINCT Product_ID) AS Distinct_Products_Ordered 
FROM Order_Items
GROUP BY Order_ID



---- B29  Show customers and the number of orders they placed, sorted desc
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    COUNT(O.Order_ID) AS Number_Of_Order_Placed_Per_Customer
FROM Customers AS C
LEFT JOIN Orders AS O
ON C.Customer_ID =  O.Customer_ID 
GROUP BY  C.Customer_ID, C.Customer_Name
ORDER BY Customer_ID DESC


---- B30  Demonstrate LIMIT and OFFSET: return 2nd page of customers with page size 3
-- Pagination OFFSET determines how many records to skip from the beginning of the result to reach the desired end result of what we need. LIMIT is the the current page/maximum number of records to retrieve for the current page
-- A simple way to view pagination formula is OFFSET = (page_number-1)*page_size and LIMIT is page_size. So if page_size = 3, then a page 2 offset = (2-1)*3 = 3. 2 is the page in question, 1 is specified in the formula and 3 is the page size.
SELECT *
FROM Customers
LIMIT 3 OFFSET 3
-- When you run the calculations, Page 1 offset = 0, page 2 offset = 3, page 3 offset = 6 and so on. Just my two cents on this use case.


---- B31 Show reviews and their product names (join)
SELECT 
    R.Product_ID,
    R.Comment,
    P.Product_Name
FROM Reviews AS R
LEFT JOIN Products AS P
ON  R.Product_ID = P.Product_ID 
--Made a slight mistake/mixup in values in Product_ID(7,8) when inputting the data into the tables but otherwise it's fine


---- B32 Find payments made by method 'card' and total by method (GROUP BY method)
SELECT 
    Method,
    SUM(Amount) Amount_Paid_Via_Card
FROM Payments
WHERE Method = 'card'
GROUP BY Method


---- B33 Show the top 3 customers by total spending (sum of order totals)
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    SUM(O.Total_Amount) AS Total_Spent_By_Customer
FROM CustomerS AS C
LEFT JOIN Orders AS O
ON C.Customer_ID = O.Customer_ID 
GROUP BY C.Customer_ID , C.Customer_Name
ORDER BY Total_Spent_By_Customer DESC NULLS LAST --Or you can use COALESCE earlier in the query, your choice.
LIMIT 3


---- B34 Show products with tags 'gaming'
-- I will use 'laptop' cause I forgot there is no tag for gaming in my dataset
SELECT *
FROM products 
WHERE 'laptop' = ANY(tags)-- This brings up an error saying the operator must be on the right side. 

SELECT *
FROM products 
WHERE Tags @> ARRAY ['laptop'] --And this one tells me the operator does not exist.


-- The above two errors got me thinking about the data type of Tags column, cause that's where the errror should be from. So I ran this query below to cross check 
SELECT pg_typeof(tags) AS type, tags
FROM products
LIMIT 5; -- After checking data type with this query it tells me why I've been getting an error. Tags is character varying and not an arry data type, I didn't hard code it in when I was creating the table. My bad.
-- A solution is to alter data type as an Array but it requires an additional step to get the value we want. And its too much work for just the basics. So we'll do something else.


SELECT *
FROM products 
WHERE Tags LIKE ANY (ARRAY ['%laptop%']) --This is what will work, thank God for the Internet. %laptop% checks for anywhere there is the value laptop and ANY tests your Tags string agsinst a list of patterns, so basically it returns true if the value matches any of the patterns.




---- B35 Show events where event_data JSON contains a key utm (JSONB containment or ->> operator)
SELECT *
FROM Events
WHERE Event_Data ? 'utm'  -- The ? operator checks for existence in JSONB 

--The above query is accurate but lemme add something else below real quick for clarity sake(mine too.)
SELECT * 
FROM Events
WHERE Event_Data @> '{"utm": "campaign-x"}' -- Differnce betwwen this two? Event_Data @> '{"utm": "campaign-x"}' checks if the JSONB contains this key value pair. So use this for key value and use the ? operator for key/existence of the key 
--And querying JSONB seems(?) more straightforward than ARRAYS. Used to think otherwise.
