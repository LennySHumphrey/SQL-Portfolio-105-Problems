# Quick Start Guide

Get up and running with SQL Mastery in 5 minutes.

---

## Prerequisites

- **PostgreSQL 15+** installed ([Download](https://www.postgresql.org/download/))
- **VS Code** with SQLTools extension OR **psql** command-line tool OR any PostgreSQL client (pgAdmin, DBeaver, DataGrip) ([Download](https://code.visualstudio.com/Download))
- Basic SQL knowledge (for Basics section)

---

## 🚀 5-Minute Setup

Choose your preferred method:

### **METHOD A: Using VS Code (Recommended for Beginners)**

#### Step 1: Install Extensions
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X or Cmd+Shift+X)
3. Search and install:
   - **SQLTools** by Matheus Teixeira
   - **SQLTools PostgreSQL/Cockroach Driver** by Matheus Teixeira

#### Step 2: Clone the Repository
```bash
git clone https://github.com/LennySHumphrey/SQL-Portfolio-105-Problems.git
cd SQL-Portfolio-105-Problems
```
Or download ZIP from GitHub and extract.

#### Step 3: Create Database Connection
1. In VS Code, click the **SQLTools icon** in left sidebar (looks like a database)
2. Click **"Add New Connection"**
3. Select **PostgreSQL**
4. Fill in:
   - **Connection name**: `sql_practice`
   - **Server**: `localhost`
   - **Port**: `5432`
   - **Database**: `postgres` (we'll create ecommerce_practice next)
   - **Username**: `postgres`
   - **Password**: [your PostgreSQL password]
5. Click **"Test Connection"** → Should show success ✅
6. Click **"Save Connection"**

#### Step 4: Create Database
1. In SQLTools sidebar, right-click your connection → **"New SQL File"**
2. Type and run:
```sql
CREATE DATABASE ecommerce_practice;
```
3. Click **"Run on active connection"** (or press Ctrl+E Ctrl+E)

#### Step 5: Switch to New Database
1. In SQLTools sidebar, click your connection
2. Click **"Edit Connection"**
3. Change **Database** from `postgres` to `ecommerce_practice`
4. Save and reconnect

#### Step 6: Load Schema
1. Open file: `00-Database-Schema/schema.sql`
2. **Select all text** (Ctrl+A or Cmd+A)
3. **Right-click** → **"Run Selected Query"**
   - OR press **Ctrl+E Ctrl+E** (Windows) / **Cmd+E Cmd+E** (Mac)
4. Wait 5-10 seconds for all tables to load

#### Step 7: Verify Setup
Run this query:
```sql
-- Check tables loaded
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

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

✅ **You're ready!** Open `01-Basics/basics-problems.sql` and start solving.

Frankly VS Code is recommended for all levels of mastery in SQL because it allows ease of convenience like sharing and collaborating via GitHub and with documentation files like markdowns.

---

### **METHOD B: Using Command Line (psql)**

#### Step 1: Clone the Repository
```bash
git clone https://github.com/LennySHumphrey/SQL-Portfolio-105-Problems.git
cd SQL-Portfolio-105-Problems
```

#### Step 2: Create Database
```bash
# Open psql
psql -U postgres

# In psql, create database
CREATE DATABASE ecommerce_practice;

# Connect to it
\c ecommerce_practice
```

#### Step 3: Load Schema
```sql
-- In psql, load the schema
\i 00-Database-Schema/schema.sql

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

Explore as much as you can on your journey.

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
- [x] B1-B10 (Completed: 2025-11-15)
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

Remember: The goal isn't to finish fast—it's to build deep understanding.