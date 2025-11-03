-- ============================================
-- ADVANCED SECTION (A1-A35)
-- SQL Practice Problems - Full Solutions with Comments
-- ============================================
-- Author: Lenny Success Humphrey
-- Database: PostgreSQL
-- Schema: E-Commerce Business Database
-- ============================================


-- Note that there will be more comments in this section due to problem complexity. I had to break it down so it would make sense to me who's running the query, it's best practice.

---- A1 Compute a 7 order rolling average of order amounts per customer with ROWS BETWEEN 6 PRECEEDING AND CURRENT ROW 
SELECT 
    Customer_ID,
    Order_Date,
    Total_Amount,
    TRIM_SCALE(AVG(Total_Amount) OVER(PARTITION BY Customer_ID ORDER BY Order_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS Rolling_Average--TRIM_SCALE to remove the trailing zeros, 6 PRECEDING AND CURRENT ROW means a total of 7
FROM Orders 
--Note, we are partitioning via Customer so SQL will return ROWS BETWEEN 6 PRECEDING AND CURRENT ROW for each Customer_ID before moving unto the next. You'd see the effect more if this was a larger dadaset




----A2  Use a recursive CTE to produce an employee reporting chain (manager -> ...) for Employee_ID = 2 
WITH RECURSIVE CTE_Manager_Chain AS 
(
    SELECT 
        Employee_ID,
        First_Name,
        Last_Name,
        Manager_ID,
        1 AS Depth -- Here the level with thw highest number is the highest manager 
    FROM Employees AS E
    WHERE Employee_ID = 17

    UNION ALL

    SELECT  
        E.Employee_ID,
        E.First_Name,
        E.Last_Name,
        E.Manager_ID,
        MC.Depth + 1
    FROM Employees AS E
    JOIN CTE_Manager_Chain AS MC
    ON E.Employee_ID = MC.Manager_ID
    --WHERE E.Employee_ID = 2
)
SELECT * FROM CTE_Manager_Chain 


--OR, for walking down the tree to the employee of each manager than walking up to find the manager of Employee_ID = 2. I just wanted to try this out
WITH RECURSIVE CTE_Manager_Chain AS 
(
    SELECT 
        Employee_ID,
        First_Name,
        Last_Name,
        Manager_ID,
        1 AS Level_From_Employee --Temp level counting from Employee_ID 2
    FROM Employees
    WHERE Employee_ID = 2

    UNION ALL

    SELECT  
        E.Employee_ID,
        E.First_Name,
        E.Last_Name,
        E.Manager_ID,
        MC.Level_From_Employee + 1 -- Temporay level counting from Employee_ID = 2 
    FROM Employees AS E
    JOIN CTE_Manager_Chain AS MC
    ON MC.Manager_ID = E.Employee_ID 
),
Full_Hierarchy AS 
(--Walk down from the tree to the respective employees recursively
      SELECT 
        Employee_ID,
        First_Name,
        Last_Name,
        Manager_ID,
        1 AS Level -- Employee_ID 2 is level one here in this subtree, we are looking for his underlings
    FROM Employees
    WHERE Employee_ID = 2

    UNION ALL

    SELECT  
        E.Employee_ID,
        E.First_Name,
        E.Last_Name,
        E.Manager_ID,
        FH.Level + 1
    FROM Employees AS E
    JOIN Full_Hierarchy AS FH
    ON E.Manager_ID = FH.Employee_ID 
)
SELECT * FROM Full_Hierarchy




---- A3 Create a BRIN Index on Orders(Order_Date) and explain when BRIN is appropriate
CREATE INDEX Idx_Orders_OrderDate_Brin
ON
Orders USING BRIN (Order_Date)
--BRIN Index is faster for large datasets and cheaper(uses less space) than BTree of a normal Index 




---- A4 Create a GIN Index on Products.Specs and query for specs@> '{"wireless": true}'
CREATE INDEX Idx_Products_Specs_Gin
ON Products USING GIN (Specs)
--Query
SELECT * 
FROM Products
WHERE Specs @> '{"wireless": true}' --For searching for existence in JSONB. Also seems JSONB benefits from GIN Index




---- A5 use UNNEST to expand Products.Tags into rows and count tag usage. Note that unnesting is used in a collection fo rows of Arrray or JSON Array and breaking them into multiple rows 
SELECT 
    Tag, 
    Count(*) AS Count --For counting each tag across all rows 
FROM Products, --Yes, include a comma before the UNNEST
UNNEST (String_To_Array(Tags, ','))   AS Tag --String_To_Array(Tags, ',') splits the text string into a text array. Cause if it's still in a text string SQL won't be able to process it. You'll get an error if you try it without string_to_array
GROUP BY Tag
ORDER BY Tag
-- You can also use CROSS JOIN LATERAL to handle this problem.




---- A6 Use Crosstab() (PostGres Table Function) or its equivalent to pivot monthly revenues by category into columns. Explain plaiting 
CREATE EXTENSION IF NOT EXISTS Tablefunc;
SELECT *
FROM Crosstab(
    $$
    SELECT DISTINCT
        DATE_TRUNC ('Month', O.Order_Date) ::DATE AS Month, --Add a double '' '' for month if you are not using the dollar sign delimiter so SQL can parse it properly 
        C.Category_Name AS Category,
        SUM(O.Total_Amount) 
    FROM Orders O 
    INNER JOIN Order_Items AS OI
    ON O.Order_ID = OI.Order_ID
    INNER JOIN Products AS P
    ON OI.Product_ID = P.Product_ID
    INNER JOIN Categories AS C
    ON P.Category_ID = C.Category_ID
    GROUP BY 1, 2 -- I.E, the 1st and second input in the SELECT clause, i.e Month and Category 
    ORDER BY 1, 2 
    $$, -- Yes, comma with delimiter to denote moving onto the next part of the query. Or you can use '', your choice.
    $$
    SELECT DISTINCT 
        Category_Name
    FROM Categories
    ORDER BY 1 -- Adding this to pivot by Category
    $$
)
AS 
CT  (
    Month DATE, Accessories NUMERIC, Appliances NUMERIC, Clothing NUMERIC, Computers NUMERIC, Furniture NUMERIC, Gaming NUMERIC, Mobiles NUMERIC, Office NUMERIC
    ) --Adding NUMERIC will aggregate the total sales for each month with the Category Names as the headers



---- A7 Implement sessionization: group event rows into sessions per customer using gaps greater than 30 minutes, with a recursive or window method 
WITH CTE_Previous_Events AS 
(
    SELECT 
        Event_ID,
        Customer_ID,
        Created_At,
        LAG(Created_At) OVER (PARTITION BY Customer_ID ORDER BY Created_At) AS Prev_At
    FROM Events  
),-- Query to compare previous session time with current ones 
CTE_New_Sessions AS 
(
    SELECT 
        Event_ID,
        Customer_ID,
        Created_At,
        SUM(CASE
            WHEN Prev_At IS NULL OR Created_At - Prev_At > INTERVAL '30 minutes'
            THEN 1
            ELSE 0
        END) OVER (PARTITION BY Customer_ID ORDER BY Created_At) AS Session_Number
        -- Using CASE WHEN to categorize the sessions. If it's new session, i.e this is first event without any pevious, it returns 1. If session also > 30 minutes it returns 1. Else, if its still same session, then 0
        -- The SUM is a running total OVER time, i.e ORDER BY Created_At, so each event inherits a session number. It increases every time we hit a new session, creating session like numbers. 1, 2, 3 and so on(if available).
    FROM CTE_Previous_Events
)--Query to catgegorize new session and extract time that's over 30 minutes 
SELECT 
    Customer_ID,
    Session_Number,
    MIN(Created_At) AS Session_Start,
    MAX(Created_At) Session_End, 
    COUNT(*) AS Events_In_Session
FROM CTE_New_Sessions
GROUP BY Customer_ID, Session_Number
ORDER BY Customer_ID, Session_Number
--This one a very long time, was pretty difficult/confusing. For anyone not at senior level or using aid, it might be very difficult to solve. 




---- A8 Use EXPLAIN ANALYZE to compare two query versions (correlated subquery VS JOIN) and show which one is faster
-- Correlated Subquery
EXPLAIN ANALYZE 
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    (
        SELECT COUNT(*)
        FROM Orders AS O
        WHERE C.Customer_ID = O.Customer_ID-- AND Total_Amount >= 500
    ) AS Orders_Over_500
FROM Customers AS C 

--JOIN Query 
EXPLAIN ANALYZE 
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    COUNT(O.Total_Amount)
FROM Customers AS C 
LEFT JOIN Orders AS O 
ON O.Customer_ID = C.Customer_ID
GROUP BY  C.Customer_ID 
ORDER BY  C.Customer_ID

-- It would be better if the rows are bigger so we can compare the actual time, planning time, rows, and loops. That aside, using EXPLAIN ANALYZE, it seems like JOIN is slower. But it's reverse when the dataset grows in number. 
-- That is because the subquery will run aggregation for each customer(if there are 10,000 customers SQL will run 10,000 aggregations, one per customer, to compute the total and output the result)
-- However, in JOINS, SQL joins the tables and aggregates the query as a group to calculate the total. This is highly efficient. Plus this is a parallelizable query so the batch/bucket aggregation as showm when using EXPLAIN ANALYZE means the query will be quicker.




---- A9 Use CREATE MATERIALIZED VIEW Fast_Customer_Totals for aggregated reports and write a acheduled refresh approach; explain Pros and Cons 
CREATE MATERIALIZED VIEW Fast_Customer_Totals AS
(
SELECT 
    Customer_ID,
    SUM(Total_Amount) AS Total_Spent
FROM Orders 
GROUP BY Customer_ID 
)
--Scheduled Refresh below. Nightly 
REFRESH MATERIALIZED VIEW Fast_Customer_Totals;
--Materialized views are basically snapshots so refresh strategy depends on staleness or influx of data. One con is that it blocks any reads(DQLs like SELECT) until its finished running.
--To avoid blocking reads, use Concurrent refresh casue it's faster. Its con is that there must be at least one unique index in the MATERIALIZED VIEW and it must not be an expression included in the WHERE clause  




---- A10 Build a PL/pgSQL stored procedure to archive old orders to an Orders_Archive table and delete them from Orders inside a transaction, with safety checks 
CREATE TABLE IF NOT EXISTS Orders_Archive (LIKE ORDERS INCLUDING ALL); -- This makes an Orders_Archive table that has similiar schema to Orders. INLCUDING ALL copies everything(Columns, Data types, Indexes, constraints and defaults) but without its data. 

CREATE OR REPLACE FUNCTION Archive_Old_Orders (cutoff_date DATE) -- Takes a single input parameter, this is helpful cause you can input any cutoff date you want each time you run the query
RETURNS VOID AS -- Returns nothing, just performs a set of actions(moving and deleting records)
$$
BEGIN 
    --Safety check below, validates the cut off date 
    IF cutoff_date IS NULL OR cutoff_date > NOW() 
    THEN RAISE EXCEPTION 'Invalid cutoff_date : %', cutoff_date; --'Invalid cutoff_date : %' is the error message template; i.e what will show up if we have an error. % is a placeholder and the cutoff_date afterwards is what will replace the % when the error message shows, to show that the cutoff_date is wrong or inaccurate.
    END IF; -- This safety check cancels everything if this error shows 
    
    INSERT INTO Orders_Archive
    SELECT *
    FROM Orders 
    WHERE Order_Date < cutoff_date; -- This helps to call the data with date in between this period. We have already sepcified cutoff_date as a parameter in the function so it will be exceuted efficiently 
    
    DELETE FROM Orders 
    WHERE Order_Date < cutoff_date; -- After archiving, this is executed next and it deletes all rows from table Orders 
END;
$$ LANGUAGE plpgsql; --Remember, always be mindful of Case inside a function, stick to one, upper or lower.

--Example 
SELECT Archive_Old_Orders ('2023-01-01') -- This calls on the function telling it to archive first and delete all orders BEFORE/less than ('2023-01-01'). Remember that the function returns nothing since it is VOID so this fucntion will just show Archive_Old_Orders executed successfully.

-- You can DECLARE Moved_Counted IN; and RETURN Moved_Counted; to find the number of archived rows. Then GET DIAGONISTICS Moved_Count = ROW_COUNT to get number of rows moved. I think this latter should come before the delete query in the fucntion so it can be parsed and executed properly




---- A11 Create and use a covering index for a heavy reporting query (include INCLUDE clause to make the index covering).
CREATE INDEX Idx_Orders_Customer_Date_Include ON
Orders (Customer_ID, Order_Date) INCLUDE (Total_Amount)
-- INCLUDE specifies Total_Amount should also be stored in the index structure but not as part of the key itself. On the periphery, somewhat
-- Any query involving these 3 columns will be much faster 



---- A12 Implement row-level security example: allow users to only see orders from their own customer_id (policy example).
ALTER TABLE Orders ENABLE ROW LEVEL SECURITY; -- Activates RLS (Row Level Security) for the table
CREATE POLICY Orders_Own_Policy ON Orders -- Policy to restrict data access based on Customer_ID 
FOR SELECT USING (Customer_ID = Current_Setting('App.Current_Customer_ID') :: INT) --::(INT) makes sure users csn only view their own orders 
-- I have the Internet to thank for this one, had no idea how to do it earlier 
-- Anyway, once RLS  is up, users can only SELECT Orders from solely their own Customer_ID 
-- App.Current_customer_ID might not always be correct, this is most likely the default and used to log/store ID of the currently logged in user



---- A13 Use pg_trgm index (GIN/GIN_trgm_ops) for fast fuzzy text search on reviews.comment and show sample ranking queries with similarity() or ts_rank.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX Idx_Reviews_Trgm ON Reviews
USING GIN (Comment GIN_trgm_ops);-- This instrusts SQL to build a GIN Index ON the Comment using GIN_pg_trgm. This tells the GIN Index how to mamge and store these trigrams for efficient searching. Without it, the Index will still work but be much slower 
-- Trigrams are a split of cintinous characters from a string. E.g, laptop can be split into " lap", "lap", "apt", "pto", "top ". By indexing these trigrams,  pg_trgm can find strings that are similiar much, much more effectively. Even if they don't match exactly. Brings better perfomance than using solely LIKE.
-- Remember JSONB benefits from GIN Index while BRIN's benefit is for large datasets. DON't forget 

--Ranking query below 
SELECT *
FROM Reviews 
WHERE Comment LIKE '%laptop%'
ORDER BY Similarity (Comment, 'laptop') DESC



---- A14 Demonstrate query rewriting using materialized summary tables vs real-time compute — show both queries and pros/cons.
SELECT 
    DATE_TRUNC('Month', Order_Date) AS Day,
    SUM(Total_Amount) 
FROM Orders
GROUP BY Day
ORDER BY Day
--Real time compute means data is generated in real time so it is always up to date. The con is that it will take time to execute in cases involving big datasets or complex queries. In such a cae, MV is significantly quicker

--Query rewriting using Materialized View 
CREATE MATERIALIZED VIEW MV_Orders_Summary AS
(
    SELECT 
    DATE_TRUNC('Month', Order_Date) AS Day,
    SUM(Total_Amount) 
FROM Orders
GROUP BY Day
ORDER BY Day
)
SELECT *
FROM MV_Orders_Summary -- Materialized View is precomputed results that are already stored so its much faster in retrival. A con is that it needs constant refreshing to be up to date cause the data is mostly up to date until the last refresh  




---- A15 Implement efficient bulk upsert from a staging table into products preserving sku idempotently.
/*Bulk upsert; inserting many rows (not one by one) from a staging table/temp intermediate table that holds data. If a row does not exist in the target table, then we perform an insert into the table(in this case table Products). If it exists based on a key (e.g SKU)we perform an Update instead.
Preserving SKU idempotently means SKU is the unique identifier in this case and multiple runs or Upserts won't bring up any duplicates or cause unwanted effects in our results */


-- Assume staging table as Staging_Products with rows (SKU, Product_Name, Category_ID, Price)
INSERT INTO Products (SKU, Product_Name, Category_ID, Price)
SELECT -- In case you are wondering why we use SELECT. We are trying to update/copy data from Staging_Products. Using SELECT and specifying the rows will match the data from our staging table to main table Products and mass update at once
    SKU,
    Product_Name, 
    Category_ID, 
    Price
From Staging_Products
ON CONFLICT (SKU) -- This tells SQL that, Hey if we are about to insert a Product with an already existing SKU, don't fail and do something else.
DO UPDATE SET -- This is the something else that it should do
    Product_Name = EXCLUDED.Product_Name,
    Category_ID = EXCLUDED.Category_ID,
    Price = EXCLUDED.Price; 
/*EXCLUDED in the above query is an alias in PostGres and it simply means the new incoming data version about to be inserted but got rejeected due to conflict.
So if there is already an existing row in Product_Name, Category_ID and Price, it is updated accordingly with the new EXCLUDED.Product_Name, EXCLUDED.Category_ID and EXCLUDED.Price. Pretty neat! */


-- Quick one. Just in case you want to update the columns in your relational database and it is difficult to do so and you can't drop the entire table either, you can use Upsert to handle it. 
--Syntax goes like this below
INSERT INTO Table_Name 
VALUES ( /*Values you have to insert go here*/ )
ON CONFLICT (/*Your Primary key you wish to keep idempotent goes here*/)
DO UPDATE SET --e.g below
    Price = EXCLUDED.Price -- Pretty efficient. :)




---- A16 Show how to partition orders by range on order_date, create two partitions for 2024 and 2025, and demonstrate constraint exclusion.
CREATE TABLE Orders_2024 
PARTITION OF Orders 
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE Orders_2025 
PARTITION OF Orders 
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
-- Now, queries against Orders Order_Date will hit only relevant partitions, fulfulling the constraint exclusion 




---- A17 Use window PERCENT_RANK() to compute each product's revenue percentile.
SELECT 
    OI.Product_ID,
    P.Product_Name, 
    SUM(OI.Unit_Price * OI.Quantity) AS Total_Revenue,
    PERCENT_RANK() OVER( ORDER BY SUM(OI.Unit_Price * OI.Quantity) ) AS Percentile_Rank
FROM Products AS P
INNER JOIN Order_Items AS OI --Using INNER JOIN will eliminate the NULLs present. Those NULLs would've affected our Total_Revenue
ON P.Product_ID = OI.Product_ID
GROUP BY OI.Product_ID, P.Product_Name
ORDER BY SUM(OI.Unit_Price * OI.Quantity) ASC 




---- A18 Implement a trigger that updates inventory when an order is inserted (careful: consider transaction and rollback).
CREATE OR REPLACE FUNCTION Reduce_Inventory() -- Reduce inventory because when an order is inserted and about to be taken out, the inventory left will reduce 
RETURNS TRIGGER AS 
$$-- Don't forget your delimiter
BEGIN 
    UPDATE Inventory 
    SET Quantity = Quantity - NEW.Quantity -- Use NEW.Quantity to reference the new, inserted quantity. Using NEW_Quantity will make SQL think it's another variable and throw back an error
    WHERE Product_ID = NEW.Product_ID;
    RETURNING Quantity INTO NEW.Remaining_Quantity;

    IF NOT FOUND OR NEW.Remaining_Quantity < 0
    THEN RAISE EXCEPTION 'Insufficient stock for product %', NEW.Product_ID;
    END IF;

    RETURN NEW; -- Every trigger must return new or old. In this case it returns the row being updated or inserted 
END;
$$ LANGUAGE plpgsql;

--Creating trigger below
CREATE TRIGGER trg_Reduce_Inventory 
AFTER INSERT ON Orders -- After the order is inserted, the function will be executed first to make sure that everything goes smoothly. Added exception for best practice, to cancel the transaction in case of low stock.
FOR EACH ROW EXECUTE PROCEDURE Reduce_Inventory ()
-- The trigger above might give problems when inserting new data in table Orders. In that case, drop TRIGGER and update your table. Else you can create a trigger that allows for update. Just a haeds up and it is totally optional, it's outside the scope of the practice problems after all.




---- A19 Demonstrate writing an optimized query—use EXPLAIN to identify a sequential scan and change it to use an index, show before/after times (explain conceptually if you can't measure).
--To check different queries for an index scan, let's use the query Index made in A11. I have already made the query up there so feel free to check
SET Enable_Seqscan = OFF; -- We need to do this first. Using this will force SQL to show if it's an Index Scan or not. Otherwise it will always show Seq scan because SQL has already determined that it is better and efficient to use Seq scan for tables with small rows rather than Index scan. Using an Index scan in this case can lead to slower querying

EXPLAIN ANALYZE SELECT 
    Customer_ID,
    Order_Date,
    Status,
    Total_Amount
FROM Orders
--The query above does not return an Index scan even after a forced Index scan check. 

SET Enable_Seqscan = OFF;

EXPLAIN ANALYZE SELECT 
    Customer_ID,
    Order_Date,
    Total_Amount 
FROM Orders
-- Using the above query will use the INDEX Idx_Orders_Customer_Date_Include.
--            AND IMPORTANT NOTE BELOW           ---
SET Enable_Seqscan = ON -- I heard that SQL reverts this forced Index scan check after each use but it's better to be on the safe side. Turn it back on after use. And don't use it too much or multiple times in succession, I was raised old school style that if you push it too hard, it'll break. So IDK, you gotta know when it's enough. :)




---- A20 Design a star schema (fact_orders with dimension tables) for BI and write a star-optimized query for monthly revenue by product category and country.
-- I don't know this STAR Schema in depth in SQL for now so it's back to the drawing board for me. I do not think a Star Schema is needed here though, or even possible. Cuase I already created a database 
(SELECT
    DATE_TRUNC('Month', O.Order_Date) :: DATE  AS Month,
    CA.Category_Name AS Product_Category,
    CU.Country AS Customer_Country,
    SUM (OI.Quantity * OI.Unit_Price) AS Monthly_Revenue
FROM Order_Items AS OI
INNER JOIN Orders AS O
ON OI.Order_ID = O.Order_ID
INNER JOIN Products AS PR
ON OI.Product_ID = PR.Product_ID 
INNER JOIN Categories AS CA
ON PR.Category_ID = CA.Category_ID 
INNER JOIN Customers AS CU
ON O.Customer_ID = CU.Customer_ID
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3) -- Here is the query for monthly revenue by product category and country.


SELECT 
    D.month, 
    P.category_name, 
    C.country, 
    SUM(F.amount) AS Revenue
FROM Fact_Orders F
INNER JOIN Dim_Date D 
ON F.Date_ID = D.Date_ID
INNER JOIN Dim_product P 
ON F.product_ID = P.Product_ID
INNER JOIN Dim_customer C 
ON F.Customer_ID = C.Customer_ID
GROUP BY D.Month, P.Category_Name, C.Country;
-- STAR Schema version of the query.




---- A21 Write a procedure to safely reindex a large table with minimal downtime (use CONCURRENTLY, explain steps).
REINDEX INDEX CONCURRENTLY 
Idx_Orders_Customers 
-- This was done so and already explained the steps in I9. I only added a few needed things. Bascically CONCURRENTLY builds the table in the background, fulfiling the minimal downtime condition. It helps to prevent locks on Write operations(on DML queries)

REINDEX TABLE CONCURRENTLY Orders -- As asked in the question, this one Indexes an entire table, E.G, Table Orders. Helps when multiple Indexes in the table is slow and and rebuilds them internally  one by one.




---- A22 Demonstrate how to handle eventual consistency: use an optimistic concurrency control example (version/timestamp columns) to update a row safely.
-- OCC Version is always something. Let's give it a shot. Let's also assume we are using table Products for this practice problem.
ALTER TABLE Products 
ADD COLUMN IF NOT EXISTS Version INT NOT NULL DEFAULT 1; -- First we alter table if needed and add Version column. This tracks the version/how many times a row has been updated. Anyone who reads the row and will have the version shown to user
-- Suppose I read Version = 1 for Product_ID= 9, I then attempt a safe update:

UPDATE Products
SET Price = 200,
    Version = Version + 1 -- i.e +1 means plus a new addition to the version 
WHERE Product_ID = 9 AND Version = 1
RETURNING Product_ID, Version; -- If RETURNING yields 1, then update succeded and the version will advance to Version 2. If RETURNING returns 0 rows, it means someone else change it in the mean time(so that's conflict ). It will be aborted.

-- The query above is perfect for OCC, works fast for simple updates as well. However in a large organization, you will need to wrap this query in a function so you don't rewrite it every time.
--
IF ROW_COUNT = 0 THEN
RAISE NOTICE 'Conflicted Detected. This record was updated by someone else';
END IF; -- I think this is how conflict resolution should look inside the said function.

-- Btw, OCC assumes the best optimistically. Assume conflicts are rare but also possible so we verify before commiting. So transactions can proceed without requring locks.
-- Read phase; reading transaction from DB into local workspace, modifications are made to private copies of the data
-- Validation phaze; verifies that no other transaction has modified the data since it was read by current ongoing transaction. This is verified by TimeStampz or Version numbers to detect conflicts. If validation fails, transaction aborts and restarts 
-- Write Phase; if validation succeeds, changes made by validation are updated and permanently applied to the DB. The local modifocations are written to the DB and other transactions can see the modificattions




-- A23 Use JSONB jsonb_path_query or ->/->> to extract deeply nested fields and index them for speed.
SELECT 
    Event_ID,
    Event_Data ->'qty'->> 'product_id'
FROM Events
WHERE Event_Data @> '{"qty":{"qty":"product_id"}}' -- Keeps bringing out no data for some reason. If you know the reason why, please reach out so I can update comments accordingly, thanks! :)

CREATE INDEX Idx_Event_Data_Utm ON Events
USING GIN (Event_Data) -- GIN for JSONB speed.




--A24 Compute rolling distinct count (distinct users sessionized per day) and discuss complexity and approximate alternatives (HyperLogLog).
WITH Daily_Distinct_Users AS 
(
    SELECT DISTINCT ON (Order_ID) -- Note that Order_ID 5 may appear twice later in your query. So SELECT DISTINCT ON (Order_ID) here in your CTE so you don't get any duplicates on your Order_ID which is acting now as User_ID.
        Order_ID,
        Payment_ID,
        DATE_TRUNC('Day', Paid_At) AS day
    FROM Payments  -- I don't have a table for DB sessions so I'm using this instead.
) 
SELECT 
    Order_ID,
    Day
FROM Daily_Distinct_Users
WHERE Day >= Now() - INTERVAL '250 days' 
--The above is NOT a standard roliing distinct count as we were asked to do, I know. Getting to do so was a bit challenging, I'll show you why below.

--
WITH Daily_Users AS 
(
    SELECT
        Order_ID,
        DATE_TRUNC('Day', Paid_At) AS day
    FROM Payments 
    GROUP BY 2,1
)
SELECT DISTINCT
    Day,
    COUNT(Order_ID) OVER(ORDER BY Day RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW) AS Rolling_Distinct_Users
FROM Daily_Users
GROUP BY Day, Order_ID
ORDER BY Day -- As you can see and as you know, we can't compute DISTINCT on a COUNT aggregation. Maybe some can but currently my PostGres cannot. So that's problem 1, I had to write my query how you are currently viewing it.
-- Then problem 2, doing it this way does not give me unique values after comparing and contrasting later on. Either SQL is treating the gap between the days as 7 day interval and returning double values for rolling distinct OR I made a mistake in writing the query. As always, I am very open to suggestions and corrections.


--If you can tolerate a bit of loss in your data intergrity, use PostGres HyperLogLog. This will provide an approximation of what you are looking for.
-- Using HyperLogLog;
CREATE EXTENSION IF NOT EXISTS hll;
SELECT
    Order_ID,
    DATE_TRUNC('Day', Paid_At) AS day,
    approx_count_distinct(Order_ID) AS Estimated_Distinct_Users
FROM Payments  
GROUP BY 2
ORDER BY 2-- HyperLogLog isn't avalaible here on PostGres at the moment so I could not test. But you get the point.




---- A25 Implement an audit trigger that writes row diffs to audit_logs JSONB on UPDATE; show trigger body.
CREATE OR REPLACE FUNCTION Audit_Orders() -- Doesn't take arguments
RETURNS TRIGGER AS --This will tell SQL to return a trigger and not treat it as a normal query
$$
BEGIN
    INSERT INTO Audit_Logs (Source_Table, Change)
    VALUES
    (
        'Orders', 
        json_build_object -- Constructs a JSONB object from a list of key value pairs via columns or other expressions within a SQL query
        ('old', to_JSONB(OLD), 'new', to_JSONB(NEW)) -- New and old are special trigger variables. Old is row before the update and New is row after the update. Then to_JSONB converts everything to JSONB 
    );
    RETURN NEW;
END; -- This tells SQL to always return the new updated/mofified column
$$ LANGUAGE plpgsql; 
-- The entire function above will be executed when the Trigger is triggered


CREATE TRIGGER Trg_Audit_Orders
AFTER UPDATE ON Orders -- That is, after update is successfully completed
FOR EACH ROW -- Runs for each updated row 
EXECUTE PROCEDURE Audit_Orders();-- Executes the procedure(function) defined above earlier
-- Quick note.Even if Audit_Orders() does not take arguments, every trigger must call a function and every funtion uses (). So make sure to include yours.




---- A26 Show how to avoid deadlocks by ordering updates, give a concrete example with SELECT FOR UPDATE.
-- A deadlock in SQL happens when one transactions locks another from updating. And these transactions are running at the same time. Imagine two people holding the same key to a door and trying to open it at the same time, neither will be able to. That is what a deadlock is 
BEGIN;
SELECT *
FROM Inventory 
WHERE Product_ID = 1 FOR UPDATE
--
BEGIN;
SELECT *
FROM Inventory 
WHERE Product_ID = 1 FOR UPDATE
-- Trying to run the above will not work cause it's a deadlock


BEGIN;
SELECT *
FROM Inventory 
WHERE Product_ID IN (1,2) 
FOR UPDATE -- This prevents deadlocks cause it'll update for ID 1 before moving on to ID 2.  That way, the transactions aren't waiting in opposite directions
-- Always lock in ascending order to prevent issues.




---- A27 Demonstrate a parallelizable query design—what to avoid (e.g., volatile functions), use EXPLAIN to show parallel workers.
EXPLAIN ANALYZE SELECT 
    Customer_ID,
    SUM(Total_Amount)
FROM Orders
GROUP BY Customer_ID -- This is a parallelizable query. Looking at the results by Explain Analyze, you'll seee SQL split it into batches to aggregate. 
-- For more context, a parallelizable query is one that can be safely split into smaller, different parts. By doing that, the DB processes those parts at the same time on multiple cores and combines the results into a single answer. Such queries are also quicker.
-- E.g,say you have a million rows that you wish to aggregate its sum. SQL(PostGres) will split the table into chunks and assign multiple workers to compute each chunk seperately then just adds them up afterwards. Queries like this read a lot of data so splitting makes sense 
-
EXPLAIN ANALYZE SELECT 
    SUM(Total_Amount)
FROM Orders -- This is NOT a parallelizable query because it returns ONLY ONE result, one single total and not a per cstomer breakdown. So SQL will not split the table to aggregate it in parrallel cause frankly, it's not worth it.
-- Also, Volatile functions should be avoided cause they produce different outputs most of the times it's being analyzed. It can't be called a parallelizable query. E.g are fuctions like random(), now().




---- A28 Implement multi-master conflict resolution pattern (conceptual): how to reconcile conflicting updates with a deterministic rule.
    -- To do this, we can use LWW, Last Write WIns. This works by keeping an ID and timestamp of the last update. When encountering two updates that's happening at the same time down to the last millisecond(rare but very much possible), LWW will help merge things smoothly.
    -- During this said merge,  the DB will choose a final value and that will be the one with the newer timestamp. If both timestamps are identical, SQL will pick the greater NodeID numerically or aplhabetically.(NodeID is the identifier for the replica or the writer that made last row update). 
UPDATE Products AS P 
SET Price = Incoming.Price,
    Last_Updated = Incoming.Last_Updated, --if available
    Node_ID = Incoming.Node_ID
FROM Incoming_Updates AS Incoming -- New data that's coming in from another source (table). Cause as you know, we do not have some of this columns in our Product table.
WHERE P.Product_ID = Incoming.Product_ID -- Finds matching products between current products wt=ith incoming ones. 
AND (Incoming.Last_Updated, Incoming.Node_ID) > (P.Last_Updated, P.Node_ID) -- Only updates if incoming record is newer or has a higher Node_ID
-- Note that this query will not work cause the hypothetical table we should get data from is just that. Hypothetical. So keep that in mind.



---- A29 Show how to create a secure view that masks sensitive columns (e.g., show email only masked to non-admins).
CREATE OR REPLACE VIEW Secure_Customers AS 
(
    SELECT 
        Customer_ID,
        Customer_Name,
        CASE 
            WHEN CURRENT_USER IN ('admin', 'superuser') -- CURRENT_USER shows the username or DB role of whovever is quering the system. 
            THEN Customer_Email -- If CURRENT_USER is an admin or has admin privileges, then SQL fully shows Customer_Email
            ELSE rexegp_replace(Customer_Email, '(.)(.*)(@.*)' , '\1***\3') -- If CURRENT_USER is NOT an admin then Customer_Email is masked. And ngl, figuring out the definition for the pattern for this took a while
        END AS Email,
        Country 
    FROM Customers 
)
-- To make more secure, you can resrict acess to the original table 
REVOKE SELECT ON Customers
FROM PUBLIC;
GRANT SELECT ON Secure_Customers TO PUBLIC; --After doing this users without permission will not be able to run SELECT * query cause it'll return permission denied error 




---- A30 Build a recursive window query to find the longest chain length in the employee-manager tree.
-- I'm going to do every single thing step by step and document where necessary. This seems compicated so i do not want to be confused. Ensure you test every step as you go as well.
WITH RECURSIVE CTE_Recursive_Chain AS
(
    -- Anchor Query
    SELECT 
        Employee_ID,
        First_Name,
        Manager_ID,
        ARRAY[Employee_ID] AS Path,-- Saw this online, its helpful to prevent loops and cycles later on. This is creating an array that holds their own element, their own ID. This will help map each employee to their manager in an array format.
        1 AS Level -- I used level so I could understand it more, so it would make more sense when trying to compute.
    FROM Employees
    WHERE Manager_ID IS NULL 

UNION ALL

    --Recursive Query
    SELECT 
        E.Employee_ID, 
        E.First_Name,
        E.Manager_ID,
        CRC.Path || E.Employee_ID, -- For every employee reportng to a specific manager, we extend the Path that's in the Anchor query. That is, take the current path from the manager (CRC.Path) and add the employee's ID(E.Employee_ID) to the end.  
        -- So if CRC.Path = 1 and E.Employee_ID = 2, it'll be {1,2}. And by the way, || means concatnate for arrays. You can seek more tips on this sort queries then filter wth your understanding. 
        Level + 1
    FROM Employees AS E
    INNER JOIN CTE_Recursive_Chain AS CRC
    ON E.Manager_ID = CRC.Employee_ID
)
-- Main Query
SELECT * -- MAX(Level) AS Longest_Chain_Length 
FROM CTE_Recursive_Chain
-- Use MAX(Level) AS Longest_Chain_Length where I specified above if you to get the longest chain length. The Array path that I concatnated already shows this when you view it so there's not much need. But that's what is required of us so that's that. By the way, I feel I designed a pretty good looking and realistic heirachical structure :)




---- A31 Demonstrate combining window functions and aggregates to compute top-N per group and ties handling.
-- Let's demonstrate how to combine window functions and aggregates to compute top-N per group and show ties handling via the table Employees
SELECT *
FROM 
(
    SELECT 
    E.Employee_ID,
    D.Department_ID,
    D.Department_Name,
    E.Salary,
    RANK() OVER(PARTITION BY D.Department_Name ORDER BY E.Salary DESC) AS Salary_Rank, -- To get the salary rank of employees within their respective depaartments. This also handles ties where present.
    SUM(E.Salary) OVER(PARTITION BY D.Department_Name) -- Just like asked in the practice problem, we include aggregate. This shows the total sum of salary per each department.
FROM Employees AS E 
LEFT JOIN Departments AS D
ON E.Department_ID = D.Department_ID
)t
WHERE Salary_Rank <=2 -- Filter to get only the top 2 salaries per department. You can change this value to get any top N value as you wish
-- So breakdown of query. First, I got the salary rank of employees within each department and also the aggregate sum of salary per each department. Then I put that entire query into ANOTHER query to find the top N VALUE(in my case, I pulled up top 2 per group/department).
-- I had to input more data into Employees for this query to make more sense, hence why the Employee table has more data than the rest. It couldn't be helped.




---- A32 Create a function that calculates customer LTV (lifetime value) using historical orders and returns a table.
CREATE OR REPLACE FUNCTION Customer_LTV() --() means the function takes no arguments
RETURNS TABLE --The practice problem said we should return a table so that is what we are doing. This will make SQL return rows and columns for our function like a normal table.
(
    Customer_ID INT,
    Lifetime_Value NUMERIC
)
AS 
$$--Again, This is delimeter used to quote the function's body cause it's clear to understand, it marks the start of the function's code block and the second one marks the end. Everthing in between is traeted as literal code.
BEGIN -- We are beginning using procedural logic, the code inside BEGIN and END will be executed one after another.
    RETURN QUERY -- This means the result of the subsequent query will be what SQL will returns as output after block execution.
    SELECT 
        O.Customer_ID,
        COALESCE(SUM(Total_Amount), 0) AS Lifetime_Value -- Coalesce to handle any eventual NULLs
    FROM Orders AS O --Add your alias
    GROUP BY O.Customer_ID
    ORDER BY O.Customer_ID; --Don't forget your semi colons, SQL just LOVESSS it's semi colons. Tsk
END;
$$ LANGUAGE plpgsql; --Procedural language.


SELECT * 
FROM Customer_LTV() -- Use this to call the function and see the full LTV for the customers.




---- A33 Demonstrate advanced indexing: partial + expression + include to create a high-performance lookup for (LOWER(sku), price range) queries.
-- This is advanced. Research is good.
CREATE INDEX Idx_Lower_Sku 
ON Products(LOWER(SKU), Price) -- LOWER makes search case insesitive, converts all SKU to lower case
INCLUDE (Product_Name, Specs, Tags) 
WHERE Tags IS NOT NULL AND Specs IS NOT NULL -- This entire query above is a covering Index, SQL is able to answer query without needing to touch the main table 




---- A34 Discuss and show a safe, tested migration pattern for changing a column type with minimal downtime.
--Let's say I stored Total_Amount as TEXT rather than NUMERIC. That's a big mistake, normal. And let's say the table I am trying to migrate has hundreds of thousands of rows. Using the usual ',
ALTER TABLE Orders
ALTER COLUMN Total_Amount TYPE NUMERIC
USING Total_Amount :: NUMERIC,
--This above will work but also lock the table for a while. Maybe longer. And that's not good.


--Instead, we FIRST add another different column with the correct data type;
ALTER TABLE Orders
ADD COLUMN Total_Amount_Numeric NUMERIC


--Then backfill/transfer data in small batches so I/we don't lock the entie table. That'll be disastrous :)
UPDATE Orders
SET Total_Amount_Numeric = Total_Amount : NUMERIC -- Link both columns to each other then cast as NUMERIC
WHERE Total_Amount_Numeric IS NULL -- To filter rows that have nothing in them and update emoty rows one by one
LIMIT 50000 
-- This above query will be run repeatedly until all empty batches are filled
-- And Just a heads up, SQL will assign the Total_Amount belonging to a specific ID and match it to the new column being Total_Amount_Numeric. So don't be worried that there will be a mix of rows while doing batch transfer.


--After that, rename when everything has been fully migrated so it can be differentiated propely
ALTER TABLE Orders
RENAME COLUMN Total_Amount TO Total_Amount_Old;
RENAME COLUMN Total_Amount_Numeric TO Total_Amount;

--Then after testing and double checking that everything runs fine, drop the old column, any related triggers and functions and/or views. Very importent as well




---- A35 Using timestamps and timezone data: show conversion, store events in UTC and present them in user timezone; handle daylight saving edge cases.
SELECT 
    Event_ID,
    Created_At AS UTC_Time, -- Assume the timestamp in the DB is in UTC
    Created_At AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Johannesburg' AS My_Time
    -- AT TIME ZONE 'UTC' converts Created_At to UTC(very helpful incase you have timestampz with time zones) and AT TIME ZONE 'Africa/Johannesburg' coverts the alreday converted UTC time to the local time. In my case, Africa.
    -- Can be AT TIME ZONE 'user_timezone' depending on who's runing the query. Either you specify like I did with Johannesburg or you can input your own local timezone. E.G WAT or GMT, whichever you want. Research is good.
FROM Events