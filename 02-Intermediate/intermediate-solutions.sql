-- ============================================
-- INTERMEDIATE SECTION (I1-I35)
-- SQL Practice Problems - Full Solutions with Comments
-- ============================================
-- Author: Lenny Success Humphrey
-- Database: PostgreSQL
-- Schema: E-Commerce Business Database
-- ============================================


--I1 Show full order details; Order_ID, Order_Date, Customer_Name, Product_Name and Quantity(one row per each order item)
SELECT 
    O.Order_ID,
    O.Order_Date,
    C.Customer_Name,
    OI.Quantity,
    P.Product_Name
FROM Orders AS O
LEFT JOIN Customers AS C
ON O.Customer_ID = C.Customer_ID
LEFT JOIN Order_Items AS OI 
ON O.Order_ID = OI.Order_ID
LEFT JOIN Products AS P
ON P.Product_ID = OI.Product_ID 

--The orders of your query is important cause it links them together.
--Eg, the query below will bring an error. It's the same as above but with a differnt order.
SELECT 
    O.Order_ID,
    O.Order_Date,
    C.Customer_Name,
    OI.Quantity,
    P.Product_Name
FROM Orders AS O
LEFT JOIN Customers AS C
ON O.Customer_ID = C.Customer_ID
LEFT JOIN Products AS P
ON P.Product_ID = OI.Product_ID 
LEFT JOIN Order_Items AS OI 
ON O.Order_ID = OI.Order_ID
-- How is it different? There are no links between your JOINS to your previous JOINS or your main table Orders.




--I2 Create a CTE recent_orders of orders from the last 250 days then show the revenue from that CTE
WITH CTE_Recent_Orders AS 
(
    SELECT *
    FROM Orders 
    WHERE Order_Date >= now() - INTERVAL '250 days'
) 
SELECT 
SUM(Total_Amount)
FROM CTE_Recent_Orders




--I3 Use a correlated subquery to find customers whose total spending > average customer spend
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    SUM(O.Total_Amount) AS Total_Spent_By_Customer
FROM Customers AS C
LEFT JOIN Orders AS O
ON C.Customer_ID = O.Customer_ID
GROUP BY  C.Customer_ID 
HAVING SUM(O.Total_Amount) > 
    (
    SELECT 
        TRIM_SCALE(AVG(Total_Amount))
    FROM Orders
    )
--I used WHERE in the beginning and I also forgot that the subquery should only return one column. Stupid mistake, lol. DON'T DO SAME.




--I4 Return latest order(most recent order_date) per customer
SELECT DISTINCT ON (O.Customer_ID)  --This retrieves unique rows based on an order
    O.Customer_ID,
    O.Order_ID,
    O.Order_Date
FROM Orders AS O 
ORDER BY O.Customer_ID, O.Order_Date DESC;
-----OR-----
SELECT DISTINCT ON (O.Customer_ID)  --This retrieves unique rows based on an order
    O.Order_ID,
    O.Customer_ID,
    MAX(O.Order_Date) sorted_order_date
FROM Orders AS O 
GROUP BY O.Order_ID




--I5 Create a view  customer_spend that maps customer_id -> total_spent 
CREATE VIEW customer_spend AS
    (
        SELECT 
            C.Customer_ID,
            C.Customer_Name,
            SUM(O.Total_Amount) AS Total_Spent_By_Customer
        FROM Customers AS C
        LEFT JOIN Orders AS O
        ON C.Customer_ID = O.Customer_ID
        GROUP BY  C.Customer_ID 
        ORDER BY Customer_ID -- Not always necessary
    )
--This was easier to do because I created this table in I3 before linking it to a subquery. Just pulled out what I needed and cast as a VIEW 




--I6 Insert or update the table products (UPSERT) by SKU. If exists, update price. Else Insert.
INSERT INTO Products(Product_ID, SKU, Product_Name, Category_ID, Price)
VALUES 
(21, 'SKU-XYZ', 'New Product', 8, '150' )
ON CONFLICT (SKU)
DO UPDATE SET price = EXCLUDED.price --Primary key Product_ID must be unique so I had to use the next number in series, i.e 9




--I7 Use LAG to show the previous order total for each customer ordered by date 
SELECT 
    Order_ID,
    Customer_ID,
    Order_Date,
    Total_Amount,
    COALESCE(LAG(Total_Amount) OVER(PARTITION BY Customer_ID ORDER BY Order_Date), 0) AS Previous_Order_Amount 
FROM Orders 
--Note that majority of customerd ordered once so there won't be multiple returns in our query 
--Likewise, using LEAD will find the most recent order for each customer. Even though some won't have a recent order.




--I8 Show with count(*)FILTER : Count paid vs cancelled orders per customer with a single GROUP BY
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    COUNT(O.status) FILTER (Where O.Status = 'paid') AS Paid_Count,
    COUNT(O.status) FILTER (Where O.Status = 'cancelled') AS Cancelled_Count
FROM  customers AS C
LEFT JOIN  Orders AS O 
ON O.Customer_ID = C.Customer_ID
GROUP BY C.Customer_ID, C.Customer_Name




--I9 Use ARRAY AGG to list product names per order as a single aggregated text array
SELECT 
    OI.Product_ID,
    P.Product_name,
    ARRAY_AGG(P.Product_Name ORDER BY P.Product_Name)
FROM Order_Items AS OI 
LEFT JOIN Products AS P
ON OI.Product_ID = P.Product_ID 
GROUP BY  OI.Product_ID, P.product_name




----I10 Write a query that finds top suppliers by total supply value. Join product_suppliers -> suppliers
SELECT  
    PS.Supplier_ID,
    S.Supplier_Name,
    SUM(PS.Supply_Price) AS Total_Supply_Value
FROM product_suppliers AS PS 
LEFT JOIN Suppliers AS S
ON PS.Supplier_ID = S.Supplier_ID
GROUP BY  PS.Supplier_ID, S.Supplier_Name
ORDER BY Total_Supply_Value DESC




----I11 Use a CTE to compute monthly revenue and find the month over month growth percentage
WITH CTE_Total_Monthly_Revenue AS
    (
        SELECT 
        DATE_TRUNC('Month', Order_Date) AS Month,
        SUM(Total_Amount) AS Monthly_Revenue
    FROM Orders 
    GROUP BY 1--(I.e, the 1st column listed in the SELECT atatement. It's quicker, neater.)
    ORDER BY 1
    )
SELECT 
    Month,
    Monthly_Revenue,
    LAG(Monthly_Revenue) OVER (ORDER BY Month) AS Previous_Revenue,
    ROUND( --The round is to prevent excessive numbers turning out later
    CASE 
        WHEN LAG(Monthly_Revenue) OVER (ORDER BY Month)  IS NULL OR LAG(Monthly_Revenue) OVER (ORDER BY Month) = 0 --Have to use both statements for the WHEN statements else you encounter a division by zero error. Once again, thank God for the Internet
        THEN NULL 
        ELSE (Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Month)) / LAG(Monthly_Revenue) OVER (ORDER BY Month) * 100
    END, 1) AS Month_Over_Month_Percentage
FROM CTE_Total_Monthly_Revenue  




----I12 Create an index on lower(Customer_email) for case insensitive lookup and demonstrate the query using LOWER (Email) ='...'. Then test index existence.
CREATE INDEX Idx_Customer_Lower_Email
ON Customers (LOWER(Customer_Email)) --emails are already in lower case but just go ahead and create an index 

--Query Demonstration
Select *
FROM Customers
WHERE LOWER(Customer_Email) = 'amy2@gmail'

--To test for existence and demonstrate that the Index actually works, check below. You should see an Index Scan when you execute this
SET Enable_Seqscan = OFF; -- To force SQL to use Index scan instead of Seq scan cause the latter is more efficient for smaller rows
EXPLAIN ANALYZE 
SELECT *
FROM Customers
WHERE LOWER(Customer_Email) = 'amy2@gmail'

SET Enable_Seqscan = ON; -- Turn back on when you are done.


--For best practice, we can also wrap it in a BEGIN, COMMIT so as to automatically rollback the Enable_Seqscan.
BEGIN;
SET Enable_Seqscan = OFF; 
EXPLAIN(ANALYZE, BUFFERS) -- Added buffers for improved view of performance on our query, it's optional
SELECT *
FROM Customers
WHERE LOWER(Customer_Email) = 'amy2@gmail';
COMMIT; 




----I13 Use JSONB operators, get list of customers with Event_Data = 'query'
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    E.Event_Data
FROM Customers AS C
LEFT JOIN Events AS E 
ON C.Customer_ID = E.Customer_ID
WHERE Event_Data ? 'query'




----I14 Find the products with specs of Weight_g > 1500 (JSONB Numeric extraction)
SELECT *
FROM Products 
WHERE (Specs ->> 'weight_g' ) :: INT > 1500
--You have to cast the results of the WHERE statement to INT else SQL won't return any value cause the argument isn't BOOLEAN(I.E, TRUE or FALSE). Casting to INT and checking for existence of the > 1500 will return a value that exists and is also true.




----I15 Use DISTINCT ON (PostGres specific) to fetch one representative order per customer
SELECT DISTINCT ON (O.Customer_ID)
    O.Customer_ID,
    O.Order_ID,
    C.Customer_Name,
    O.Order_Date,
    O.Status
FROM Orders AS O
LEFT JOIN Customers AS C --So to show the Customer Names
ON C.Customer_ID = O.Customer_ID 
GROUP BY C.Customer_Name, O.Order_ID
ORDER BY  O.Customer_ID, O.Order_ID




---I16 Write a transaction (BEGIN ... COMMIT) that inserts an order and corresponding Order_Items and rolls back an error
BEGIN TRANSACTION;
INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Status, Total_Amount)
VALUES
(9, 7, now(), 'Pending', 155); --Change values up a bit to see if you encounter an error 

--Inserting into Order_Items 
INSERT INTO Order_Items (Order_ID, Line_Number, Product_ID, Quantity, Unit_Price)
VALUES
(Currval('Orders_Order_ID_Seq'), 3, 6, 1, 105); --Currval is ORACLE and PostGres specific 
COMMIT;
ROLLBACK --It rolled back an error. Always remember your ; when writing your transaction queries.




----I17 Use EXISTS to find customers who placed an order for product with Product_ID = 1
SELECT *
FROM Customers AS C
WHERE EXISTS 
(
    SELECT 1 -- This tells SQL to just retrieve a constant value of 1 for the row that matches the criteria without pulling up the entire table or full, actual data since we aren't actually using it. You can use * if you want to, same result
FROM Orders AS O
INNER JOIN Order_Items AS OI --Inner JOIN for matching rows, not LEFT JOIN that returns all rows from left and only matching from right
ON O.Order_ID = OI.Order_ID
WHERE O.Customer_ID = C.Customer_ID AND OI.Product_ID = 1 --There is linking betwwen O and C via Customer_ID
)--Note that this is a correlated subquery, they will not work without each other




----I18 Use UNION ALL to combine two SELECTS; (Customers from Nigeria ) and (Customers from Ghana) with source tag
SELECT 
    *,
    'NG' AS Region
FROM Customers
WHERE Country = 'Nigeria'
UNION ALL
SELECT 
    *,
    'GH' AS Region
FROM Customers
WHERE Country = 'Ghana'




---I19 Create and query a materialized view Monthly_Revenue_MV and show how to REFRESH MATERIALIZED VIEW
CREATE MATERIALIZED VIEW Monthly_Revenue_MV AS 
(
    SELECT 
    DATE_TRUNC('Month', Order_Date) AS Month,
    SUM(Total_Amount) AS Amount_Per_Month
    FROM Orders
    GROUP BY DATE_TRUNC('Month', Order_Date)
    ORDER BY Month  
)




----I20 Use STRING_AGG to show Customer_Name and a comma seperated list of ordered Product_Names
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    STRING_AGG (CONCAT(C.Customer_Name, ' , ',  P.Product_Name), ' ') AS Items_List --Used Concat to mash two together and added the delimetr afterwards
    -- Use this if you don't want to mesh using Concat; STRING_AGG(P.Product_Name, ', ' ORDER BY P.Product_Name) 
FROM Customers AS C
INNER JOIN Orders AS O 
ON C.Customer_ID = O.Customer_ID
INNER JOIN Order_Items AS OI 
ON O.Order_ID = OI.Order_ID
INNER JOIN Products AS P 
ON P.Product_ID = OI.Product_ID
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY C.Customer_ID
--I used INNER JOINS all through to avoid issues involving NULLS




----I21 Use TO_CHAR/date formatting to show the order_date as 'YYYY-MM' for reporting.
SELECT 
    TO_CHAR(Order_Date, 'YYYY-MM') AS Month
FROM Orders  




----I22 Use EXPLAIN for a query and explain what the planner shows (use a simple query and interpret)
--Let'use a simple query here, for example the one I used prior in I21
EXPLAIN
    SELECT 
        TO_CHAR(Order_Date, 'YYYY-MM')
    FROM Orders  --Shows affected rows, cost and Seq scan

--We can also use EXPLAIN ANALYZE for a more deeper analysis.
EXPLAIN ANALYZE
    SELECT 
        TO_CHAR(Order_Date, 'YYYY-MM')
    FROM Orders  --This has an added advantage of planning time and execution time and loops




----I23 Build a partial index for orders where status = 'paid' and show query that benefits
--I'll just create a simple partial index for ONLY Status = 'paid'
CREATE INDEX Idx_Orders_Paid
ON Orders(Order_Date)
WHERE Status = 'paid' 
--Example of a simple query that benefits 
SELECT *
FROM Orders
WHERE Status = 'paid' AND Order_Date >= '2025-01-01'




----I24 Use a window aggregate on Payments to show cumulative payments per order/customer
SELECT 
    Payment_ID,
    Order_ID,
    Paid_At,
    Amount,
    SUM(Amount) OVER (PARTITION BY Order_ID ORDER BY Order_ID) AS Cumulatve_Sum 
FROM Payments
ORDER BY Order_ID, Paid_At -- No need for GROUP BY here.




----I25 Use REXGP or SIMILAR TO to find customers with email domains matching '@gmail'
SELECT *
FROM Customers
WHERE Customer_Email SIMILAR TO '%@gmail%'
--This is bacically a turbo charged version of LIKE cause it supports longer strings and can filter better 




---- I26 Use NULLIF or COALESCE in any calculaton when Unit_Price may be zero or NULL
SELECT 
    Order_ID,
    Line_Number,
    Unit_Price,
    Quantity,
    TRIM_SCALE(Unit_Price / NULLIF(Quantity, 0)) AS Price_Per_Unit --Looking for price per each unit. Adding NULLIF also helps to prevent division by zero error, COALESCE can also be used here.
FROM Order_Items 
ORDER BY Order_ID




---- I27 Write a query that returns products and a Boolean Is_In_Stock based on Inventory Quantity > 0 (i.e, JOIN Inventory)
SELECT 
    P.Product_ID,
    P.SKU,
    P.Product_Name,
    COALESCE( SUM(I.Quantity), 0) Total_Quantity,
    CASE 
        WHEN COALESCE( SUM(I.Quantity), 0) > 0 THEN TRUE
        ELSE FALSE 
    END AS Is_In_Stock
FROM Products AS P
LEFT JOIN Inventory AS I
ON P.Product_ID = I.Product_ID
GROUP BY P.Product_ID,P.SKU, P.Product_Name
ORDER BY P.Product_ID




---- I28 Use GROUPING SETS or mutiple GROUP BY queries in one (if avaialable) to show category and product totals in one results (or explain how to emulate)
SELECT 
    P.Product_Name,
    COALESCE(C.Category_Name, 'ALL') AS category,
    SUM(OI.Quantity) AS Quantity_Sold
FROM order_items AS OI
LEFT JOIN Products AS P
ON P.Product_ID = OI.Product_ID 
LEFT JOIN Categories AS C
ON C.Category_ID = P.Category_ID
GROUP BY GROUPING SETS ((C.Category_Name, P.Product_Name), ())
ORDER BY C.Category_Name, P.Product_Name;
-- The empty parenthesis () in the GROUPING SETS is to get the grand total at the end of the results, the ordering method is to ensure it comes last 
-- The COALESCE is to replace the NULL in the grand total row to give it a more plesant look after finishing




---- I29 Use CREATE INDEX CONCURRENTLY (Explain syntax) to avoid locking 
CREATE INDEX CONCURRENTLY 
Idx_Orders_Customers
ON Orders(Customer_ID)
--CONCURRENTLY means that the index can be built in the background without locking the tables whereas normal CREATE INDEX will lock the tables . 
--To avoid locking (writes) means that the usual DML(Insert,Update,Delete) can be done on the Index while still being built. Helps prevent performance issues 




---- I30 Show how to do keyset pagination (seek method) for the Orders Table by Order_Date, Order_ID
--Assuming last seen Order_Date + Order_ID of previous page 

SELECT *
FROM Orders
WHERE (Order_Date, Order_ID) < (TIMESTAMP '2025-03-01', 9)-- Filters records where this is less than this. Both must be met
ORDER BY Order_Date DESC, Order_ID DESC




---- I31 Create a stored SQL function that returns a Total_Spent(Customer_ID) and demonstrate calling it in a query 
CREATE FUNCTION Total_Spent (Customer_ID INT) RETURNS NUMERIC 
AS 
$$ --This is used to quote the function's body cause it's clear to understand, it marks the start of a code block
    SELECT 
        COALESCE(SUM(Total_Amount), 0) --COALESCE to handle NULLS
    FROM Orders 
$$ LANGUAGE SQL STABLE --Must always specfify language. This SQL language here will execute a single, simple query. No need for any variable/error handling or complex tasks that would require plpgsql instead.
-- Results will change over time as orders are added/removed and functions are called hence the use of STABLE. It enusres results are consistent within a single query execution

--Demonstration Query
SELECT 
    O.Customer_ID,
    total_spent
FROM Orders AS O 




---- I32 Use a lateral JOIN to fetch the most recent review for each product
SELECT 
    P.Product_ID,
    R.Review_ID,
    P.Product_Name,
    R.Comment,
    R.Created_At
FROM Products AS P 
INNER JOIN LATERAL --Since we only care about the most recent review, use INNER JOIN to handle the NULLS that will come up and focus only on what we need
(
    SELECT *
    FROM Reviews AS R
    WHERE R.Product_ID = P.Product_ID
    --ORDER BY R.Created_At DESC
    LIMIT 1 --To ensure we get the most recent review per product
)
R ON TRUE --Ensures that the condition on the lateral JOIN is always true 
ORDER BY R.Created_At DESC
LIMIT 1




---- I33 Show how to safely delete duplicates from a table using ROW_NUMBER() partitioned by unique columns 
--First identify the duplicates using a CTE
WITH CTE_Duplicates AS
(
    SELECT 
    Customer_ID, -- In case there is no primary key, use PostGres native function CTID to locate the physical position of the data in the current time, i.e right now
    ROW_NUMBER() OVER (PARTITION BY Customer_Name, Customer_Email, Country ORDER BY Customer_ID) AS RN -- Gives each row a number based on all the grouping via partitions
    -- RN above needs a combination of columns that define uniqueness, hence why I put in different parameters. Cause in a real world scenario, some customers will leave some fields empty/NULL but there are some they are required to input, hence the combination. Else SQL will treat the said NULLs as duplicates, learnt this while I waas computing this cause my table has no duplicates originally.
    FROM Customers
)
--SELECT * FROM CTE_Duplicates WHERE RN > 1; Use this in accordance with your CTE to first test the existence and number of duplicates you mght have.

DELETE FROM Customers 
WHERE Customer_ID IN -- Meaning filter/look up the Customer_ID in the query below and delete their duplicates, i.e WHERE RN > 1
    (
        SELECT 
            Customer_ID
        FROM CTE_Duplicates 
        WHERE RN > 1
    )




---- I34 Use FILTER (WHERE ...) in aggregate to compute sums for different stautses in one pass
SELECT 
    Customer_ID,
    SUM(Total_Amount) FILTER (WHERE Status = 'paid') AS Total_Paid,
    SUM(Total_Amount) FILTER (WHERE Status = 'pending') AS Total_Pending,
    SUM(Total_Amount) FILTER (WHERE Status = 'cancelled') AS Total_Cancelled,
    SUM(Total_Amount) FILTER (WHERE Status = 'shipped') AS Total_Shipped 
FROM Orders 
GROUP BY Customer_ID -- Ensure you use small letters for the statuses as is shown in your table else SQL willl not parse it properly. Use COALESCE to handle NULLs if you wish




---- I35 Use EXCEPT to find customers present in the Customer Table but not in the Pyaments Table (i.e Never Paid)
SELECT DISTINCT
    C.Customer_ID
FROM Customers AS C 
EXCEPT 
SELECT DISTINCT
    O.Customer_ID
FROM Orders AS O
LEFT JOIN Payments AS P
ON O.Order_ID = P.Order_ID