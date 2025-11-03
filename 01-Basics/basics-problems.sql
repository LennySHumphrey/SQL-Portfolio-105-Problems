-- ============================================
-- BASICS SECTION (B1-B35)
-- SQL Practice Problems - Questions Only
-- ============================================
-- Before starting, ensure you've loaded the schema:
-- /00-Database-Schema/schema.sql
-- ============================================


These check core SELECT, WHERE, ORDER, LIMIT, DISTINCT, simple aggregates, joins, NULL handling, simple DML, basic indexes, and simple use of JSON/arrays.


B1. Return all columns from customers.

B2. Return name, email, country for customers.

B3. Find all customers from Nigeria.

B4. List customers created after 2024-12-31.

B5. Show unique countries of customers (no duplicates).

B6. Show products ordered by price descending.

B7. Show the 3 cheapest products.

B8. Count total number of customers.

B9. Compute total revenue from orders (SUM(total_amount)).

B10. Compute average order value.

B11. Find max and min product price.

B12. Show number of customers per country (GROUP BY).

B13. Show each product with total units sold (sum quantity) using order_items.

B14. Show each order with its customer name (join orders->customers).

B15. Show customers who have never placed an order.

B16. For order order_id = 2, show its products (name) and quantity (join order_items->products).

B17. For every order item, compute line_total = unit_price * quantity.

B18. Show products that have never been ordered.

B19. Show orders with status = 'pending'.

B20. Insert a new customer (example statement).

B21. Update a customer's country (example: set customer_id=4 country to 'Ghana').

B22. Delete a test customer with a specific id.

B23. Find products priced above the average product price (subquery).

B24. Use COALESCE to show customer email or 'no-email' when NULL.

B25. Use CASE to label orders as 'big' if total_amount >= 500 else 'small'.

B26. Find orders in the last 90 days (use now() / interval).

B27. Use LIKE to find customers whose name starts with 'A'.

B28. Count distinct products ordered per order (COUNT(DISTINCT product_id) per order).

B29. Show customers and the number of orders they placed, sorted desc.

B30. Demonstrate LIMIT and OFFSET: return 2nd page of customers with page size 3.

B31. Show reviews and their product names (join).

B32. Find payments made by method 'card' and total by method (GROUP BY method).

B33. Show the top 3 customers by total spending (sum of order totals).

B34. Show products with tag 'gaming' (use tags array search).

B35. Show events where event_data JSON contains a key utm (JSONB containment or ->> operator).
