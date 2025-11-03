# Basics (B1-B35)

## Overview

Foundation SQL operations every data analyst needs. These problems cover core querying, filtering, aggregation, and JOIN patterns that form the basis of all analytical work.

**Skill Level**: Entry-level to Junior Analyst  
**Estimated Time**: 8-12 hours to complete

---

## 📚 Topics Covered

### **Data Retrieval & Filtering**
- SELECT statements (all columns, specific columns)
- WHERE clause conditions (equality, comparison, NULL handling)
- DISTINCT for unique values
- ORDER BY and LIMIT for sorting and pagination
- LIKE patterns for text matching

### **Aggregations**
- COUNT, SUM, AVG, MIN, MAX
- GROUP BY for grouping data
- HAVING for filtering groups

### **JOINs**
- INNER JOIN for matching records
- LEFT JOIN for including non-matches
- Identifying orphaned records (customers without orders, products never ordered)
- Multi-table joins

### **Data Manipulation**
- INSERT new records
- UPDATE existing records
- DELETE records

### **Useful Functions**
- COALESCE for NULL handling
- CASE statements for conditional logic
- Date arithmetic with INTERVAL
- String functions

---

## 🎯 Key Problems to Master

| Problem | Skill | Business Use Case |
|---------|-------|-------------------|
| **B15** | LEFT JOIN + NULL filtering | Find customers who never ordered (churn prevention) |
| **B13** | JOIN + Aggregation | Calculate product sales volume |
| **B23** | Subquery | Find products above average price (pricing analysis) |
| **B26** | Date filtering | Recent activity tracking (engagement metrics) |
| **B33** | TOP N queries | Identify high-value customers (VIP programs) |

---

## 📖 How to Use

### **For Learning:**
1. Open `basics-problems.sql` 
2. Try solving each problem yourself
3. Check your solution against `basics-solutions.sql`
4. Read the comments to understand the "why" behind each approach

### **For Practice:**
```sql
-- Load the schema first
\i 00-Database-Schema/schema.sql

-- Open problems file
\i 01-Basics/basics-problems.sql

-- Try solving B1: Return all columns from Customers
SELECT * FROM customers;

-- Check your answer
\i 01-Basics/basics-solutions.sql
```

---

## ✅ Learning Checkpoints

By the end of this section, you should be able to:

- [ ] Write SELECT queries with multiple conditions
- [ ] Use GROUP BY to aggregate data by dimensions
- [ ] Perform INNER and LEFT JOINs confidently
- [ ] Calculate totals, averages, and counts
- [ ] Handle NULL values appropriately with COALESCE
- [ ] Use CASE for conditional logic
- [ ] Filter dates with INTERVAL arithmetic
- [ ] Identify missing relationships (anti-joins)

---

## 🚀 Next Steps

Once you're comfortable with all 35 basics problems:
- Move to [Intermediate Section](/02-Intermediate/) for CTEs and window functions
- Review [Customer Analytics](/04-Business-Applications/customer-analytics.md) to see how these queries solve business problems

---

## 💡 Tips for Success

**Common Mistakes to Avoid:**
- Forgetting to use GROUP BY with aggregate functions
- Using WHERE instead of HAVING for filtered aggregates
- Not handling NULLs (use COALESCE or IS NULL checks)
- Joining tables without understanding the relationship

**Best Practices:**
- Always use table aliases for readability (`FROM orders O`)
- Use meaningful column aliases in SELECT
- Test queries on small subsets first with LIMIT
- Use EXPLAIN to understand query execution

---

**Estimated Completion**: 35 problems × 15-20 min average = **8-12 hours**

[← Back to Main README](/README.md) | [Next: Intermediate →](/02-Intermediate/)