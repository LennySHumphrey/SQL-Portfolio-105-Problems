# Quick Start Guide - SQL Portfolio: 105 Problems

Get up and running with SQL Portfolio in 5 minutes.

---

## Prerequisites

- **PostgreSQL 15+** installed ([Download](https://www.postgresql.org/download/))
- **psql** command-line tool OR any PostgreSQL client (pgAdmin, DBeaver, DataGrip)
- Basic SQL knowledge (for Basics section)

---

## 🚀 5-Minute Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/LennySHumphrey/SQL-Portfolio-105-Problems.git
cd SQL-Portfolio-105-Problems
```

### Step 2: Create Database
```bash
# Open psql
psql -U postgres

# In psql, create database
CREATE DATABASE ecommerce_practice;

# Connect to it
\c ecommerce_practice
```

### Step 3: Load Schema
```sql
-- In psql, load the schema
\i 00-Database-Schema/schema.sql
-- If you want you can also copy and load the tables individually. If you use psql in VS Code, this is the best option for you 

-- Verify tables loaded
\dt

-- Check row counts
SELECT 'Customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'Products', COUNT(*) FROM products
UNION ALL SELECT 'Orders', COUNT(*) FROM orders;
```

**Expected Output:**
```
 table_name | count 
------------|-------
 Customers  |    35
 Products   |    20
 Orders     |    37
```

### Step 4: Try Your First Problem
```sql
-- Open basics problems
\i 01-Basics/basics-problems.sql

-- Try B1: Return all columns from Customers
SELECT * FROM customers LIMIT 5;
```

### Step 5: Check Solution
```sql
-- View solution
\i 01-Basics/basics-solutions.sql
-- Scroll to B1 to compare
```

---

## 📁 File Navigation

### Problems Only (Try First):
- `01-Basics/basics-problems.sql`
- `02-Intermediate/intermediate-problems.sql`
- `03-Advanced/advanced-problems.sql`

### Solutions (Check After):
- `01-Basics/basics-solutions.sql`
- `02-Intermediate/intermediate-solutions.sql`
- `03-Advanced/advanced-solutions.sql`

---

## 🎯 Recommended Learning Path

### Week 1-2: Foundations
```sql
\i 01-Basics/basics-problems.sql
-- Work through B1-B35
```
**Focus**: JOINs, aggregations, filtering

### Week 3-4: Analytics
```sql
\i 02-Intermediate/intermediate-problems.sql
-- Work through I1-I35
```
**Focus**: CTEs, window functions, JSONB

### Week 5-6: Production Patterns
```sql
\i 03-Advanced/advanced-problems.sql
-- Work through A1-A35
```
**Focus**: Optimization, triggers, procedures

---

## 🔧 Useful psql Commands

```sql
\dt                    -- List all tables
\d table_name          -- Describe table structure
\x                     -- Toggle expanded display (better for wide results)
\timing                -- Show query execution time
\! clear               -- Clear screen
\q                     -- Quit psql
```

---

## 💡 Tips for Maximum Learning

### 1. **Try Before Looking**
Spend at least 10 minutes attempting each problem before checking solutions.

### 2. **Understand, Don't Memorize**
Read the solution comments to understand the "why" behind each approach.

### 3. **Experiment**
Modify queries to see what happens:
- Add more WHERE conditions
- Change GROUP BY columns
- Try different JOIN types

### 4. **Use EXPLAIN**
```sql
EXPLAIN ANALYZE 
SELECT * FROM orders WHERE customer_id = 1;
```
Learn to read execution plans early.

### 5. **Build Your Own**
After completing a section, create your own problem and solution.

---

## 🐛 Troubleshooting

### "Permission denied" when loading schema
```bash
# Run psql as superuser
psql -U postgres

# Or grant permissions
GRANT ALL PRIVILEGES ON DATABASE ecommerce_practice TO your_username;
```

### "Relation does not exist"
```sql
-- Check you're in the right database
SELECT current_database();

-- Should show: ecommerce_practice
-- If not, reconnect:
\c ecommerce_practice
```

### Large file won't load in pgAdmin
Use command line instead:
```bash
psql -U postgres -d ecommerce_practice -f 00-Database-Schema/schema.sql
```

### Want to start fresh?
```sql
-- Drop and recreate database
DROP DATABASE ecommerce_practice;
CREATE DATABASE ecommerce_practice;
\c ecommerce_practice
\i 00-Database-Schema/schema.sql
```

---

## 📊 Track Your Progress

Create a simple checklist:

```markdown
### Basics (B1-B35)
- [x] B1-B10 (Completed: 2025-01-15)
- [ ] B11-B20
- [ ] B21-B30
- [ ] B31-B35

### Intermediate (I1-I35)
- [ ] I1-I10
- [ ] I11-I20
- [ ] I21-I30
- [ ] I31-I35

### Advanced (A1-A35)
- [ ] A1-A10
- [ ] A11-A20
- [ ] A21-A30
- [ ] A31-A35
```

---

## 🎓 Next Steps After Basics

1. Read [Customer Analytics](04-Business-Applications/customer-analytics.md) to see business applications
2. Try creating your own dashboard query combining multiple problems
3. Move to Intermediate when you can solve Basics problems without hints

---

## 📬 Need Help?

- **Schema Issues**: Check [schema-overview.md](00-Database-Schema/schema-overview.md)
- **Concept Confusion**: Read section READMEs for explanations
- **Stuck on a Problem**: Review similar solved problems first
- **Found a Bug**: Open an issue on GitHub

---

**Happy Learning! 🎉**

Remember: The goal isn't to finish fast, it's to build deep understanding.