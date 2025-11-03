-- ============================================
-- INTERMEDIATE SECTION (I1-I35)
-- SQL Practice Problems - Questions Only
-- ============================================
-- Before starting, ensure you've loaded the schema:
-- /00-Database-Schema/schema.sql
-- ============================================


These require multi-table joins, CTEs, correlated subqueries, set ops, window basics, views, upsert, prepared statements, JSON queries, partial indexes, aggregation elaborations, and more.


I1. Show full order details: order_id, order_date, customer_name, product_name(s) and quantity (one row per order_item).

I2. Create a CTE recent_orders of orders from last 30 days and then show total revenue from that CTE.

I3. Use a correlated subquery to find customers whose total spending > average customer spend.

I4. Return latest order (most recent order_date) per customer (use window ROW_NUMBER() or DISTINCT ON).

I5. Create a view customer_spend that maps customer_id -> total_spent.

I6. Insert or update a product (UPSERT) by sku — if exists update price; else insert.

I7. Use LAG() to show previous order total for each customer ordered by date.

I8. Show COUNT(*) FILTER usage: count paid vs cancelled orders per customer with a single GROUP BY.

I9. Use ARRAY_AGG to list product names per order as a single aggregated text array.

I10. Write a query that finds top supplier(s) by total supply value (join product_suppliers -> products).

I11. Use a CTE to compute monthly revenue and then find month-over-month growth percentage.

I12. Create an index on lower(email) for case-insensitive lookup and demonstrate the query using LOWER(email) = '...'.

I13. Use JSONB operators: get customers where metadata->>'loyalty' = 'gold'.

I14. Find products with specs->>'weight_g' > 1500 (JSONB numeric extraction).

I15. Use DISTINCT ON (Postgres) to fetch one representative order per customer (most recent).

I16. Write a transaction (BEGIN ... COMMIT) that inserts an order and corresponding order_items and rolls back on error.

I17. Use EXISTS to find customers who placed an order for product with product_id = 1.

I18. Use UNION ALL to combine two SELECTs: (customers from Nigeria) and (customers from Ghana) with source tag.

I19. Create and query a materialized view monthly_revenue_mv and show how to REFRESH MATERIALIZED VIEW.

I20. Use STRING_AGG to show customer_name and a comma-separated list of ordered product_names.

I21. Use TO_CHAR/date formatting to show order_date as 'YYYY-MM' for reporting.

I22. Use EXPLAIN for a query and explain what the planner shows (use a simple query and interpret).

I23. Build a partial index for orders where status = 'paid' and show query that benefits.

I24. Use a window aggregate SUM(amount) OVER (PARTITION BY customer_id ORDER BY paid_at) on payments to show cumulative payments per order/customer.

I25. Use REGEXP or SIMILAR TO to find customers with email domains matching 'example.com'.

I26. Use NULLIF and COALESCE in a calculation when unit_price may be zero or NULL.

I27. Write a query that returns products and a boolean is_in_stock based on inventory qty > 0 (join inventory).

I28. Use GROUPING SETS or multiple GROUP BY queries in one (if available) to show category and product totals in one result (or explain how to emulate).

I29. Use CREATE INDEX CONCURRENTLY (explain syntax) to avoid locking.

I30. Show how to do keyset pagination (seek method) for the orders table by order_date, order_id.

I31. Create a stored SQL function that returns total_spent(customer_id) and demonstrate calling it in a query.

I32. Use a lateral join to fetch the most recent review for each product.

I33. Show how to safely delete duplicates from a table using ROW_NUMBER() partitioned by unique columns.

I34. Use FILTER (WHERE ...) in aggregate to compute sums for different statuses in one pass.

I35. Use EXCEPT to find customers present in customers table but not in payments table (i.e., never paid).