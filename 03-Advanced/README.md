# Advanced (A1-A35)

## Overview

Production-grade database engineering and enterprise patterns. These problems demonstrate techniques used by senior engineers, DBAs, and architects managing large-scale systems.

**Skill Level**: Senior Analyst to Database Engineer  
**Estimated Time**: 25-35 hours to complete  
**Prerequisites**: Solid understanding of Intermediate concepts

---

## 📚 Topics Covered

### **Advanced Indexing Strategies**
- BRIN indexes for time-series data
- GIN indexes for JSONB and full-text search
- Partial indexes for filtered queries
- Covering indexes with INCLUDE clause
- Expression indexes for computed columns
- pg_trgm for fuzzy text matching

### **Recursive Queries**
- Organizational hierarchies (employee → manager chains)
- Bill of Materials (BOM) explosions
- Graph traversal
- Sessionization with gap detection

### **PL/pgSQL Programming**
- Stored procedures for business logic
- Triggers for automated data integrity
- Exception handling and rollback
- Functions returning tables

### **Query Optimization**
- Execution plan analysis (EXPLAIN ANALYZE)
- Query rewriting techniques
- Parallel execution strategies
- Deadlock prevention patterns

### **Production Operations**
- Zero-downtime migrations
- Bulk operations and batch processing
- Concurrent index creation (REINDEX CONCURRENTLY)
- Row-level security (RLS)
- Audit logging with triggers

### **Advanced Analytics**
- Sessionization with complex time windows
- Rolling distinct counts (HyperLogLog approximations)
- Percentile rankings (PERCENT_RANK)
- Star schema design for BI

---

## 🎯 Key Problems to Master

| Problem | Skill | Production Use Case |
|---------|-------|---------------------|
| **A2** | Recursive CTE | Employee org chart (manager → reports chain) |
| **A7** | Complex Sessionization | User behavior analysis with 30-min gaps |
| **A18** | Trigger + Validation | Auto-update inventory on order insert |
| **A25** | Audit Trigger | Capture row-level changes to JSONB |
| **A34** | Zero-Downtime Migration | Change column type on 10M+ row table |

---

## 🔥 Production-Critical Patterns

### **1. Safe Bulk Operations**
```sql
-- ❌ Locks table for hours
UPDATE orders SET status = 'archived' WHERE created_at < '2020-01-01';

-- ✅ Batch updates with pause
DO $$
BEGIN
    FOR i IN 1..1000 LOOP
        UPDATE orders SET status = 'archived' 
        WHERE order_id IN (
            SELECT order_id FROM orders 
            WHERE created_at < '2020-01-01' 
            AND status != 'archived'
            LIMIT 10000
        );
        PERFORM pg_sleep(0.1); -- Let other queries through
    END LOOP;
END $$;
```

### **2. Recursive Hierarchy Traversal**
```sql
-- Walk up the org chart from employee to CEO
WITH RECURSIVE manager_chain AS (
    SELECT employee_id, manager_id, 1 AS level
    FROM employees WHERE employee_id = 5
    
    UNION ALL
    
    SELECT e.employee_id, e.manager_id, mc.level + 1
    FROM employees e
    JOIN manager_chain mc ON e.employee_id = mc.manager_id
)
SELECT * FROM manager_chain;
```

### **3. Covering Index for Index-Only Scans**
```sql
-- Query never touches table heap (10x faster)
CREATE INDEX idx_covering ON orders (customer_id, order_date) 
INCLUDE (total_amount);

-- This query uses index-only scan
SELECT customer_id, order_date, total_amount 
FROM orders 
WHERE customer_id = 123;
```

---

## 📖 How to Use

### **For System Design Interviews:**
Problems that demonstrate architectural thinking:
- **A16**: Table partitioning by date range
- **A20**: Star schema design for data warehousing
- **A28**: Multi-master conflict resolution (distributed systems)
- **A26**: Deadlock prevention strategies

### **For Technical Deep Dives:**
Show you understand performance at scale:
- **A8**: Compare query approaches with EXPLAIN ANALYZE
- **A19**: Before/after index optimization with metrics
- **A27**: Parallelizable query design principles
- **A24**: Approximate algorithms (HyperLogLog for distinct counts)

---

## ✅ Learning Checkpoints

By the end of this section, you should be able to:

- [ ] Design optimal index strategies for different query patterns
- [ ] Write recursive CTEs for hierarchical data
- [ ] Create stored procedures with error handling
- [ ] Implement triggers for automated data integrity
- [ ] Analyze and optimize query execution plans
- [ ] Perform zero-downtime schema migrations
- [ ] Prevent deadlocks through lock ordering
- [ ] Build audit systems with JSONB change tracking
- [ ] Design partitioning strategies for large tables
- [ ] Implement sessionization with complex time logic

---

## 🎓 Production Scenarios

### **High-Scale E-Commerce**
- **A7**: Sessionization for user events/day
- **A15**: Bulk product catalog sync from suppliers
- **A18**: Real-time inventory deduction on checkout

### **SaaS Platform**
- **A12**: Row-level security for multi-tenant data
- **A9**: Pre-computed dashboards with materialized views
- **A32**: Customer LTV calculation as table-valued function

### **Financial Systems**
- **A25**: Audit trail for compliance
- **A22**: Optimistic concurrency control for transactions
- **A26**: Deadlock-free fund transfers

---

## 💡 Advanced Concepts Explained

### **When to Use BRIN vs B-Tree**
```
BRIN (Block Range INdex):
✅ Time-series data (naturally ordered)
✅ Large tables (10M+ rows)
✅ Range queries (WHERE date BETWEEN)
✅ 95% smaller than B-Tree
❌ Random lookups
❌ Small tables

B-Tree (Default):
✅ Exact matches (WHERE id = X)
✅ Small to medium tables
✅ Frequently updated columns
❌ Very large time-series tables
```

### **Trigger Performance Considerations**
- Triggers execute for EACH ROW (can be slow on bulk operations)
- Use STATEMENT-level triggers when possible
- Avoid complex logic in triggers (call stored procedures instead)
- Test trigger overhead: bulk insert with/without triggers

### **Materialized View Refresh Strategies**
```sql
-- Strategy 1: Full refresh (simple, blocking)
REFRESH MATERIALIZED VIEW mv_name;

-- Strategy 2: Concurrent refresh (no locks, slower)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_name;
-- Requires: UNIQUE index on MV

-- Strategy 3: Incremental (manual, complex but fastest)
-- Track last_updated timestamp and only recompute changed data
```

---

## 🚨 Common Pitfalls

### **Recursive CTE Infinite Loops**
```sql
-- ❌ Can loop forever if circular references exist
WITH RECURSIVE bad_recursion AS (
    SELECT * FROM employees WHERE employee_id = 1
    UNION ALL
    SELECT e.* FROM employees e
    JOIN bad_recursion r ON e.manager_id = r.employee_id
)
SELECT * FROM bad_recursion; -- May never terminate!

-- ✅ Add cycle detection
WITH RECURSIVE safe_recursion AS (
    SELECT employee_id, manager_id, ARRAY[employee_id] AS path
    FROM employees WHERE employee_id = 1
    
    UNION ALL
    
    SELECT e.employee_id, e.manager_id, r.path || e.employee_id
    FROM employees e
    JOIN safe_recursion r ON e.manager_id = r.employee_id
    WHERE e.employee_id != ALL(r.path) -- Prevent cycles
)
SELECT * FROM safe_recursion;
```

### **Trigger Debugging**
- Triggers fail silently if exceptions aren't raised
- Use `RAISE NOTICE` for debugging during development
- Check `pg_trigger` system catalog if trigger not firing
- Remember: BEFORE triggers can modify NEW, AFTER triggers cannot

### **Index Bloat**
- Unused indexes slow down writes (INSERT/UPDATE/DELETE)
- Audit index usage: `SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0`
- Drop unused indexes before bulk operations
- REINDEX periodically on high-churn tables

---

## 🚀 Next Steps

After mastering Advanced:
- Read [Performance Optimization Guide](/04-Business-Applications/performance-optimization.md)
- Study PostgreSQL internals (how indexes work at disk level)
- Contribute to open-source projects requiring complex SQL
- Mentor others through Basics → Advanced progression

---

## 📊 Difficulty Progression

```
Moderate (A1-A10):  Advanced indexing, recursive CTEs
Hard (A11-A25):     Triggers, procedures, optimization
Expert (A26-A35):   Distributed systems, migrations, edge cases
```

**Estimated Completion**: 35 problems × 45-60 min average = **25-35 hours**

---

## 🎤 Interview Showcase Problems

Bring these up in senior/staff-level interviews:
- **A7**: "I implemented sessionization logic handling midnight boundaries and multi-day sessions"
- **A18**: "I built an inventory trigger preventing overselling, with atomic transaction rollback"
- **A34**: "I migrated a 50M row table's column type with zero downtime using batch backfill"

Back these up with solid projects and you are good to go.

---

[← Back to Intermediate](/02-Intermediate/) | [← Main README](/README.md)