# Intermediate (I1-I35)

## Overview

Real-world analytical queries and database optimization techniques. These problems introduce CTEs, window functions, JSONB operations, and indexing strategies used in production environments.

**Skill Level**: Mid-level Analyst to Senior Analyst  
**Estimated Time**: 15-20 hours to complete  
**Prerequisites**: Complete Basics section (B1-B35)

---

## 📚 Topics Covered

### **Common Table Expressions (CTEs)**
- Breaking complex queries into readable steps
- Recursive CTEs for hierarchical data
- Multiple CTEs in a single query

### **Window Functions**
- LAG/LEAD for comparing rows
- RANK, ROW_NUMBER, DENSE_RANK for ranking
- Running totals and moving averages
- PARTITION BY for grouped calculations

### **JSONB Operations**
- Extracting nested fields (`->`, `->>`)
- Containment checks (`@>`, `?`)
- Indexing JSONB columns with GIN

### **Performance & Indexing**
- Creating and testing indexes
- EXPLAIN ANALYZE for query optimization
- Partial indexes for subset queries
- Expression indexes for computed values

### **Advanced Data Manipulation**
- UPSERT patterns (INSERT ... ON CONFLICT)
- Transactions with BEGIN/COMMIT/ROLLBACK
- Safe data updates with correlated subqueries

### **PostgreSQL-Specific Features**
- DISTINCT ON for unique row selection
- FILTER clause in aggregations
- ARRAY_AGG and STRING_AGG
- Materialized views

---

## 🎯 Key Problems to Master

| Problem | Skill | Business Use Case |
|---------|-------|-------------------|
| **I11** | CTE + LAG + Date Math | Month-over-month revenue growth tracking |
| **I24** | Window Functions | Cumulative payment tracking per order |
| **I33** | ROW_NUMBER + DELETE | Safe duplicate removal without data loss |
| **I7** | LAG Window Function | Price history and trend analysis |
| **I12** | Expression Index + EXPLAIN | Case-insensitive email lookup optimization |

---

## 🔥 Advanced Techniques Introduced

### **1. CTEs for Readability**
```sql
-- Instead of nested subqueries
WITH recent_orders AS (
    SELECT * FROM orders WHERE order_date >= NOW() - INTERVAL '250 days'
)
SELECT SUM(total_amount) FROM recent_orders;
```

### **2. Window Functions for Analytics**
```sql
-- Running total per customer
SELECT 
    customer_id,
    order_date,
    total_amount,
    SUM(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_date
    ) AS running_total
FROM orders;
```

### **3. UPSERT for Idempotent Operations**
```sql
-- Insert or update if exists
INSERT INTO products (sku, product_name, price)
VALUES ('SKU-123', 'New Product', 99.99)
ON CONFLICT (sku) 
DO UPDATE SET price = EXCLUDED.price;
```

---

## 📖 How to Use

### **For Learning:**
1. Ensure you've completed the Basics section
2. Open `intermediate-problems.sql`
3. Attempt each problem, referring to PostgreSQL docs as needed
4. Compare with `intermediate-solutions.sql` and study the comments

### **For Interview Prep:**
Focus on these high-frequency interview topics:
- **I11**: Month-over-month growth (always asked in growth companies)
- **I7**: LAG/LEAD patterns (comparing sequential rows)
- **I17**: EXISTS patterns (correlated subqueries)
- **I12**: Index creation and validation

---

## ✅ Learning Checkpoints

By the end of this section, you should be able to:

- [ ] Write CTEs to break down complex queries
- [ ] Use LAG/LEAD to compare rows within partitions
- [ ] Apply RANK, ROW_NUMBER for ranking scenarios
- [ ] Query JSONB fields with operators
- [ ] Create and validate indexes with EXPLAIN
- [ ] Implement UPSERT patterns for data synchronization
- [ ] Use DISTINCT ON for efficient deduplication
- [ ] Build materialized views for reporting
- [ ] Handle transactions with proper error handling

---

## 🎓 Real-World Scenarios

### **Business Analytics**
- **I11**: Build month-over-month revenue dashboards
- **I3**: Identify high-value customer segments
- **I4**: Calculate customer recency for churn models

### **Data Engineering**
- **I6**: Implement idempotent data pipelines
- **I16**: Safe multi-table transactions
- **I19**: Pre-compute expensive aggregations

### **Performance Optimization**
- **I12**: Speed up search queries with indexes
- **I22**: Diagnose slow queries with EXPLAIN
- **I29**: Index without downtime using CONCURRENTLY

---

## 💡 Common Challenges

**CTEs vs. Subqueries:**
- CTEs are more readable but sometimes less performant
- Use CTEs for readability unless performance is critical
- Materialized CTEs (future PostgreSQL versions) will solve this

**Window Function Performance:**
- Can be expensive on large datasets
- Ensure PARTITION BY columns are indexed
- Consider materialized views for frequently-run analytics

**JSONB Querying:**
- Always use GIN indexes for containment queries
- Extract to regular columns if queried frequently
- Use `jsonb_to_record()` for complex extractions

---

## 🚀 Next Steps

After completing Intermediate:
- Tackle [Advanced Section](/03-Advanced/) for production patterns
- Review [Performance Optimization](/04-Business-Applications/performance-optimization.md) guide
- Practice explaining window functions in plain English (common interview ask)

---

## 📊 Difficulty Progression

```
Easy (I1-I10):    Basic CTEs, simple window functions
Medium (I11-I25): Complex analytics, indexing, JSONB
Hard (I26-I35):   Advanced patterns, optimization, edge cases
```

**Estimated Completion**: 35 problems × 25-35 min average = **15-20 hours**

[← Back to Basics](/01-Basics/) | [← Main README](/README.md) | [Next: Advanced →](/03-Advanced/)