# Performance Optimization & Query Tuning

## Business Context

Database performance directly impacts user experience, operational costs, and system scalability. Slow queries lead to timeout errors, frustrated users, and increased infrastructure spend. These SQL problems demonstrate optimization techniques used by database engineers, backend developers, and platform teams managing production systems.

---

## 🎯 Key Performance Challenges Solved

### **1. Index Strategy & Design**

**Business Problem**: Queries are slow. How do we speed them up without throwing more hardware at the problem?

**Relevant Problems**:

- **I12**: Create index on `LOWER(customer_email)` for case-insensitive lookups
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 554)
  - *Key Technique*: Expression index with query demonstration and EXPLAIN ANALYZE validation
  - *Performance Impact*: Email lookups from table scan (500ms) → index scan (2ms)

- **I23**: Partial index for orders where `status = 'paid'`
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 730)
  - *Key Technique*: `CREATE INDEX ... WHERE` clause to index subset of rows
  - *Benefit**: 60% smaller index size, faster inserts, optimized for common query pattern

- **A3**: BRIN index on `Orders(order_date)` for large sequential data
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1022)
  - *Key Technique*: Block Range INdex for time-series data
  - *When to Use**: Large tables with naturally ordered data (timestamps, IDs)
  - *Benefit**: 95% smaller than B-Tree, fast range queries

- **A4**: GIN index on `Products.Specs` (JSONB)
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1031)
  - *Key Technique*: Generalized Inverted Index for JSONB containment queries
  - *Performance**: `@>` queries from 400ms → 8ms on 1M+ product database

- **A11**: Covering index with INCLUDE clause
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1206)
  - *Key Technique*: `CREATE INDEX ... INCLUDE (column)` for index-only scans
  - *Benefit**: Query never touches table heap, 10x faster for reporting queries

**Index Type Decision Matrix**:
```
Data Pattern          | Index Type | Use Case
----------------------|------------|---------------------------
Exact match lookups   | B-Tree     | WHERE id = X
Time-series ranges    | BRIN       | WHERE date BETWEEN X AND Y
JSONB containment     | GIN        | WHERE json @> '{"key":"val"}'
Full-text search      | GIN        | WHERE text @@ to_tsquery()
Partial dataset       | Partial    | WHERE status = 'active'
Case-insensitive      | Expression | WHERE LOWER(col) = X
```

---

### **2. Query Execution Analysis**

**Business Problem**: Which queries are slow? Where are the bottlenecks?

**Relevant Problems**:

- **I22**: Use EXPLAIN to analyze query execution plan
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 714)
  - *Key Technique*: Read and interpret EXPLAIN output (cost, rows, scan types)
  - *Business Use**: Identify missing indexes, inefficient joins, full table scans

- **A19**: EXPLAIN ANALYZE before/after index optimization
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1352)
  - *Key Technique*: Compare actual execution time with and without indexes
  - *Optimization**: Sequential scan (250ms) → Index scan (3ms) = 83x faster

- **A8**: Compare correlated subquery vs. JOIN performance
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1127)
  - *Key Finding**: JOINs generally 10-100x faster than correlated subqueries on large datasets
  - *Why**: Subqueries execute once per row; JOINs use hash/merge algorithms

**EXPLAIN Output Key Metrics**:
```
Seq Scan         → Table scan (BAD for large tables)
Index Scan       → Uses index (GOOD)
Index Only Scan  → Best case (data in index itself)
Nested Loop      → O(n*m) complexity - watch for large tables
Hash Join        → O(n+m) - good for large datasets
Cost: 0.00..X    → Estimated units (not milliseconds!)
Planning time    → Query optimization overhead
Execution time   → Actual runtime (focus here)
```

---

### **3. Materialized Views for Reporting**

**Business Problem**: Aggregation queries take 10+ seconds. Dashboards time out. How do we pre-compute results?

**Relevant Problems**:

- **I19**: Create materialized view `Monthly_Revenue_MV` with refresh strategy
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 672)
  - *Key Technique*: `CREATE MATERIALIZED VIEW` + `REFRESH MATERIALIZED VIEW`
  - *Trade-off**: Stale data vs. instant queries

- **A9**: Fast aggregated reports with scheduled refresh
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1159)
  - *Key Technique*: `REFRESH MATERIALIZED VIEW CONCURRENTLY` (no blocking)
  - *Requirement**: Must have unique index for concurrent refresh

- **A14**: Compare real-time compute vs. materialized view
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1239)
  - *Performance**: Real-time: 8.5s | Materialized: 0.05s = 170x faster
  - *Use Case**: Executive dashboards, BI tools, public APIs

**Refresh Strategies**:
```sql
-- Strategy 1: Blocking refresh (simple, but locks table)
REFRESH MATERIALIZED VIEW monthly_revenue_mv;

-- Strategy 2: Concurrent refresh (no locks, requires unique index)
CREATE UNIQUE INDEX ON monthly_revenue_mv (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue_mv;

-- Strategy 3: Scheduled via cron/pg_cron
SELECT cron.schedule('refresh-mv', '0 2 * * *', 
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue_mv$$);
```

**When to Use**:
- ✅ Query runs > 5 seconds
- ✅ Data changes infrequently (hourly/daily)
- ✅ Acceptable staleness (e.g., dashboard updated nightly)
- ❌ Real-time data requirements

---

### **4. Query Rewriting Techniques**

**Business Problem**: Query is logically correct but inefficient. How do we rewrite for speed?

**Relevant Problems**:

- **A8**: Correlated subquery → JOIN transformation
  - *Before**: Subquery executes N times (once per customer)
  - *After**: Single JOIN with GROUP BY
  - *Performance**: 100x faster on 100K+ customers

- **EXISTS vs. IN**: Use EXISTS for large subqueries
  - *Pattern**: `WHERE EXISTS (SELECT 1 ...)` stops at first match
  - *Benefit**: Short-circuits execution, doesn't materialize full result set

- **Window functions vs. Self-joins**: 
  - *Problem**: Finding "previous order" typically done with self-join
  - *Solution**: Use `LAG()` window function (I7)
  - *Performance**: 3-5x faster, more readable

**Optimization Patterns**:
```sql
-- ❌ SLOW: Correlated subquery
SELECT c.customer_id, 
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id)
FROM customers c;

-- ✅ FAST: JOIN + GROUP BY
SELECT c.customer_id, COUNT(o.order_id)
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;

-- ❌ SLOW: Self-join for previous value
SELECT o1.order_id, o2.total_amount AS prev_amount
FROM orders o1
LEFT JOIN orders o2 ON o1.customer_id = o2.customer_id 
    AND o2.order_date < o1.order_date;

-- ✅ FAST: Window function
SELECT order_id, 
    LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date)
FROM orders;
```

---

### **5. Bulk Operations & Safe Migrations**

**Business Problem**: We need to update 10 million rows. How do we avoid locking the table for hours?

**Relevant Problems**:

- **A15**: Efficient bulk upsert from staging table
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1264)
  - *Key Technique*: `INSERT ... ON CONFLICT DO UPDATE` (idempotent upsert)
  - *Performance**: Batch insert 100K rows in 2 seconds vs. 2 minutes for row-by-row

- **A34**: Zero-downtime column type migration
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1709)
  - *Strategy**: Add new column → Backfill in batches → Rename → Drop old
  - *Benefit**: Application stays online during migration

- **I29**: CREATE INDEX CONCURRENTLY to avoid table locks
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 815)
  - *Key Technique*: `CONCURRENTLY` keyword allows writes during index build
  - *Trade-off**: Takes 2-3x longer but no downtime

- **A21**: Safely reindex large tables
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1416)
  - *Best Practice**: `REINDEX INDEX CONCURRENTLY` for production systems

**Batch Update Pattern**:
```sql
-- ❌ DANGEROUS: Updates all rows, locks table
UPDATE orders SET status = 'archived' WHERE order_date < '2020-01-01';

-- ✅ SAFE: Batch updates with limit
DO $$
DECLARE
    rows_updated INT;
BEGIN
    LOOP
        UPDATE orders 
        SET status = 'archived'
        WHERE order_id IN (
            SELECT order_id 
            FROM orders 
            WHERE order_date < '2020-01-01' AND status != 'archived'
            LIMIT 10000
        );
        GET DIAGNOSTICS rows_updated = ROW_COUNT;
        EXIT WHEN rows_updated = 0;
        COMMIT; -- Release locks between batches
        PERFORM pg_sleep(0.1); -- Allow other queries to proceed
    END LOOP;
END $$;
```

---

### **6. Pagination Strategies**

**Business Problem**: Displaying page 1000 of search results takes 30 seconds. How do we paginate efficiently?

**Relevant Problems**:

- **B30**: LIMIT/OFFSET pagination (works but inefficient at scale)
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 274)
  - *Problem**: `OFFSET 10000` still scans first 10,000 rows

- **I30**: Keyset pagination (seek method) - production-grade solution
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 825)
  - *Key Technique*: `WHERE (order_date, order_id) > (last_seen_date, last_seen_id)`
  - *Performance**: O(log n) index lookup vs. O(n) for OFFSET

**Pagination Comparison**:
```sql
-- ❌ OFFSET (slow for deep pages)
SELECT * FROM orders 
ORDER BY order_date DESC 
LIMIT 25 OFFSET 10000; -- Scans 10,025 rows

-- ✅ KEYSET (fast for any page depth)
SELECT * FROM orders
WHERE (order_date, order_id) < ('2025-03-15', 12345)
ORDER BY order_date DESC, order_id DESC
LIMIT 25; -- Index scan only 25 rows
```

**Performance at Scale**:
```
Rows      | OFFSET   | Keyset
----------|----------|--------
25        | 5ms      | 3ms
1,000     | 50ms     | 3ms
100,000   | 2.5s     | 3ms
1,000,000 | 35s      | 3ms
```

---

### **7. Connection Pooling & Query Timeouts**

**Business Problem**: Database connections exhausted. Users getting "too many connections" errors.

**Best Practices**:
- Use connection pooler (PgBouncer, pgpool)
- Set statement timeout: `SET statement_timeout = '30s'`
- Implement query result caching (Redis, Memcached)
- Monitor slow query log

**Timeout Pattern**:
```sql
BEGIN;
SET LOCAL statement_timeout = '5s'; -- Fails if query takes > 5 seconds
SELECT expensive_aggregation() FROM huge_table;
COMMIT;
```

---

### **8. Deadlock Prevention**

**Business Problem**: Transactions occasionally fail with "deadlock detected" errors.

**Relevant Problems**:

- **A26**: Avoid deadlocks by ordering updates
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1540)
  - *Key Technique*: Always lock rows in consistent order (e.g., ORDER BY id)
  - *Pattern**: Use `SELECT ... FOR UPDATE` to explicit lock ordering

**Deadlock Example**:
```sql
-- ❌ CAUSES DEADLOCK (Transaction A locks 1→2, Transaction B locks 2→1)
-- Transaction A:
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 1;
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 2;

-- Transaction B (simultaneous):
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 2;
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 1;

-- ✅ PREVENTS DEADLOCK (both lock in same order)
SELECT * FROM inventory 
WHERE product_id IN (1, 2) 
ORDER BY product_id FOR UPDATE; -- Lock in ascending order

UPDATE inventory SET quantity = quantity - 1 WHERE product_id IN (1, 2);
```

---

### **9. Parallel Query Execution**

**Business Problem**: Single-threaded queries are slow. Can we use multiple CPU cores?

**Relevant Problems**:

- **A27**: Design parallelizable queries
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1564)
  - *Key Technique*: Avoid volatile functions (NOW(), RANDOM()) in WHERE clauses
  - *Configuration**: `SET max_parallel_workers_per_gather = 4;`

**What PostgreSQL Can Parallelize**:
- ✅ Sequential scans on large tables
- ✅ Aggregations (SUM, COUNT, AVG)
- ✅ Hash joins
- ❌ Index scans (usually single-threaded)
- ❌ Queries with volatile functions
- ❌ Small tables (overhead not worth it)

**EXPLAIN shows parallel workers**:
```
Finalize Aggregate (cost=... rows=1)
  -> Gather (workers planned: 4)
       -> Partial Aggregate (cost=...)
            -> Parallel Seq Scan on orders
```

---

### **10. Monitoring & Observability**

**Business Problem**: How do we identify slow queries before users complain?

**Tools & Techniques**:
- **pg_stat_statements**: Track query execution stats
- **EXPLAIN (ANALYZE, BUFFERS)**: Detailed execution metrics
- **auto_explain**: Log slow queries automatically
- **Query tags**: Add comments for tracing in logs

**Find Slowest Queries**:
```sql
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

## 🔧 Technical Skills Demonstrated

### **SQL Techniques**:
- Index design (B-Tree, GIN, BRIN, partial, covering, expression)
- Query execution plan analysis (EXPLAIN ANALYZE)
- Materialized view strategies with refresh patterns
- Transaction management and isolation levels
- Batch processing for large-scale updates
- Keyset pagination for API endpoints

### **Performance Concepts**:
- Query complexity analysis (O(n) vs. O(log n))
- Index selectivity and cardinality
- Lock contention and deadlock avoidance
- Cache hit ratios and buffer management
- Parallel execution and work distribution
- Zero-downtime migration strategies

---

## 💼 Real-World Impact Examples

**E-Commerce Platform**:
- "Optimized product search from 2.5s → 80ms using GIN index on JSONB specs (A4), supporting 10x traffic growth without hardware upgrades"

**SaaS Dashboard**:
- "Reduced executive dashboard load time from 45s → 1.2s by implementing materialized views with hourly refresh (A9)"

**High-Volume API**:
- "Implemented keyset pagination (I30) reducing P99 latency from 8s → 200ms for paginated order history endpoint"

---

## 📊 Interview Talking Points

1. **Problem-Solving**: "I diagnosed a slow customer lookup query using EXPLAIN ANALYZE (I22), discovered a missing index on case-insensitive email search, and created an expression index (I12) that reduced response time from 500ms to 2ms."

2. **Production Experience**: "When migrating a payment_amount column from TEXT to NUMERIC on a 50M row table, I used the batch backfill pattern (A34) to avoid locking, completing the migration with zero downtime over 6 hours."

3. **Scale Thinking**: "I replaced OFFSET pagination with keyset pagination (I30) for our orders API. At 100K+ orders, OFFSET took 2.5 seconds per page vs. 3ms with keyset—an 800x improvement."

4. **Business Impact**: "By creating a partial index on active orders (I23), I reduced index size by 60% and insert time by 30%, saving $2K/month in database storage costs."

---

## 🚀 Performance Checklist

Before deploying to production:

- [ ] Run EXPLAIN ANALYZE on all queries > 100ms
- [ ] Create indexes on foreign keys and WHERE clause columns
- [ ] Use covering indexes for frequently queried column combinations
- [ ] Implement materialized views for expensive aggregations
- [ ] Add statement timeouts to prevent runaway queries
- [ ] Use connection pooling (not direct connections)
- [ ] Test queries with production-scale data (not 100 test rows)
- [ ] Monitor pg_stat_statements for slow query detection
- [ ] Configure autovacuum for table maintenance
- [ ] Set up alerting on connection pool exhaustion

---

[← Back to Main README](/README.md) | [View All Problems](/03-Advanced/)