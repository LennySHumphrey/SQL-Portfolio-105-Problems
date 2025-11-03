# Inventory & Operations Management

## Business Context

Efficient inventory management directly impacts profitability through reduced carrying costs, minimized stockouts, and optimized warehouse utilization. These SQL problems demonstrate operational analytics used by supply chain analysts, logistics coordinators, and operations managers.

---

## 🎯 Key Business Questions Answered

### **1. Stock Level Monitoring**

**Business Problem**: Which products are at risk of stockout? Where do we have excess inventory?

**Relevant Problems**:
- **I27**: Return products with Boolean `Is_In_Stock` based on inventory quantity
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 778)
  - *Key Technique*: LEFT JOIN + CASE statement with COALESCE for NULL handling
  - *Business Impact*: Real-time stock status for product pages

- **B18**: Show products that have never been ordered
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 149)
  - *Key Technique*: LEFT JOIN with NULL filtering OR NOT EXISTS
  - *Business Use*: Identify slow-moving inventory for clearance

**Sample Output**:

```
Product_ID | Product_Name          | Total_Quantity | Is_In_Stock
-----------|----------------------|----------------|-------------
1          | Laptop Pro           | 17             | TRUE
5          | Unordered Item       | 8              | TRUE
...        | ...                  | 0              | FALSE
```

**Operational Insight**: Products with 0 quantity but active orders → Immediate restock required

---

### **2. Multi-Warehouse Inventory Distribution**

**Business Problem**: How is inventory distributed across locations? Which warehouse should fulfill each order?

**Relevant Problems**:
- **Inventory Table Structure**: Products can exist in multiple warehouses
  - *Schema*: Composite primary key `(Product_ID, Warehouse_ID)`
  - *Business Logic*: Query total inventory across all locations vs. by warehouse

**Multi-Location Query Example**:
```sql
-- Total inventory across all warehouses
SELECT 
    p.product_id,
    p.product_name,
    SUM(i.quantity) AS total_stock,
    COUNT(DISTINCT i.warehouse_id) AS warehouse_count
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(i.quantity) > 0;

-- Stock by warehouse for fulfillment routing
SELECT 
    w.warehouse_location,
    p.product_name,
    i.quantity,
    i.last_restocked
FROM inventory i
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
JOIN products p ON i.product_id = p.product_id
WHERE p.product_id = 1
ORDER BY i.quantity DESC;
```

**Routing Logic**: Ship from nearest warehouse with stock → Reduce shipping time and cost

---

### **3. Supplier Performance Analysis**

**Business Problem**: Which suppliers offer best pricing? Are we over-reliant on single suppliers?

**Relevant Problems**:
- **I10**: Top suppliers by total supply value
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 515)
  - *Key Technique*: JOIN + SUM + GROUP BY + ORDER BY DESC
  - *Business Use*: Negotiate volume discounts with top suppliers

**Supplier Risk Assessment**:
```sql
-- Supplier concentration risk
SELECT 
    s.supplier_name,
    COUNT(DISTINCT ps.product_id) AS products_supplied,
    SUM(ps.supply_price) AS total_supply_value,
    ROUND(100.0 * SUM(ps.supply_price) / 
        (SELECT SUM(supply_price) FROM product_suppliers), 2) AS pct_of_total
FROM suppliers s
JOIN product_suppliers ps ON s.supplier_id = ps.supplier_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY total_supply_value DESC;
```

**Risk Mitigation**: Products with only 1 supplier → Diversify sourcing

---

### **4. Restock Scheduling & Velocity**

**Business Problem**: When should we reorder? What's the optimal reorder point?

**Relevant Problems**:
- **B13**: Show each product with total units sold
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 87)
  - *Key Technique*: LEFT JOIN + SUM + GROUP BY with COALESCE
  - *Business Use*: Calculate sales velocity (units per day)

**Reorder Point Calculation**:
```sql
-- Products needing restock (combining inventory + sales velocity)
WITH sales_velocity AS (
    SELECT 
        oi.product_id,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.quantity) AS total_sold,
        DATE_PART('day', MAX(o.order_date) - MIN(o.order_date)) AS days_span,
        SUM(oi.quantity) / NULLIF(DATE_PART('day', MAX(o.order_date) - MIN(o.order_date)), 0) AS units_per_day
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status != 'cancelled'
    GROUP BY oi.product_id
),
current_stock AS (
    SELECT 
        product_id,
        SUM(quantity) AS total_quantity,
        MAX(last_restocked) AS last_restocked
    FROM inventory
    GROUP BY product_id
)
SELECT 
    p.product_name,
    cs.total_quantity AS current_stock,
    COALESCE(sv.units_per_day, 0) AS daily_velocity,
    CASE 
        WHEN cs.total_quantity / NULLIF(sv.units_per_day, 0) < 7 THEN 'URGENT RESTOCK'
        WHEN cs.total_quantity / NULLIF(sv.units_per_day, 0) < 14 THEN 'REORDER SOON'
        ELSE 'SUFFICIENT'
    END AS restock_status,
    ROUND(cs.total_quantity / NULLIF(sv.units_per_day, 0), 1) AS days_of_stock
FROM products p
LEFT JOIN current_stock cs ON p.product_id = cs.product_id
LEFT JOIN sales_velocity sv ON p.product_id = sv.product_id
ORDER BY days_of_stock ASC NULLS LAST;
```

**Alert Threshold**: < 7 days of stock → Trigger purchase order

---

### **5. Automated Inventory Updates**

**Business Problem**: How do we prevent overselling? How to maintain data integrity when orders are placed?

**Relevant Problems**:
- **A18**: Implement trigger that updates inventory when order is inserted
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1325)
  - *Key Technique*: PL/pgSQL trigger with AFTER INSERT + rollback on insufficient stock
  - *Business Impact*: Real-time inventory deduction with validation

**Trigger Logic**:
```sql
-- Simplified version
CREATE OR REPLACE FUNCTION reduce_inventory()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory
    SET quantity = quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
    
    IF NOT FOUND OR (SELECT quantity FROM inventory WHERE product_id = NEW.product_id) < 0
    THEN RAISE EXCEPTION 'Insufficient stock for product %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Business Rule**: Order placement atomically decrements inventory OR fails transaction

---

### **6. Shipment Tracking & Logistics**

**Business Problem**: What's our average delivery time? Which carriers perform best?

**Relevant Problems**:
- **Shipments Table**: Tracks `shipped_at`, `delivered_at`, and `carrier`
  - *Analysis*: Calculate fulfillment SLAs and carrier performance

**Carrier Performance Dashboard**:
```sql
SELECT 
    carrier,
    COUNT(*) AS total_shipments,
    COUNT(delivered_at) AS delivered_count,
    ROUND(100.0 * COUNT(delivered_at) / COUNT(*), 2) AS delivery_rate,
    AVG(EXTRACT(EPOCH FROM (delivered_at - shipped_at))/86400) AS avg_days_to_deliver,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (delivered_at - shipped_at))/86400) AS p95_delivery_days
FROM shipments
WHERE shipped_at IS NOT NULL
GROUP BY carrier
ORDER BY avg_days_to_deliver ASC;
```

**Output**:
```
Carrier    | Total | Delivered | Rate  | Avg Days | P95 Days
-----------|-------|-----------|-------|----------|----------
DHL        | 8     | 8         | 100%  | 3.2      | 4.5
FedEx      | 9     | 9         | 100%  | 3.8      | 5.2
UPS        | 7     | 6         | 85.7% | 4.1      | 6.0
```

**Action**: Negotiate SLA penalties with underperforming carriers

---

### **7. Warehouse Capacity Planning**

**Business Problem**: Are warehouses approaching capacity? Where should we expand?

**Relevant Problems**:
- **Warehouses Table**: Each has defined `capacity` limit
  - *Query*: Calculate utilization percentage and growth trends

**Capacity Analysis**:
```sql
SELECT 
    w.warehouse_location,
    w.capacity AS max_capacity,
    SUM(i.quantity) AS current_units,
    ROUND(100.0 * SUM(i.quantity) / w.capacity, 2) AS utilization_pct,
    CASE 
        WHEN SUM(i.quantity) / w.capacity > 0.9 THEN 'CRITICAL'
        WHEN SUM(i.quantity) / w.capacity > 0.75 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS capacity_status
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_location, w.capacity
ORDER BY utilization_pct DESC;
```

**Planning Rule**: > 75% utilization → Begin expansion planning

---

## 🔧 Technical Skills Demonstrated

### **SQL Techniques**:
- Multi-table JOINs across supply chain entities
- Aggregate functions for inventory totals and averages
- Window functions for running stock levels
- Triggers for automated data integrity
- Date arithmetic for lead time calculations
- CASE statements for status classification

### **Operations Concepts**:
- Safety stock and reorder point calculation
- ABC analysis (inventory prioritization)
- Economic Order Quantity (EOQ) principles
- Just-in-Time (JIT) inventory signals
- Warehouse utilization optimization
- Supplier diversification risk management

---

## 💼 Real-World Applications

**For E-Commerce**:
- Dynamic "In Stock" badges on product pages
- Predictive restocking before stockouts
- Multi-warehouse fulfillment routing

**For Retail**:
- Store transfer recommendations
- Seasonal inventory planning
- Markdown optimization for slow movers

**For Manufacturing**:
- Raw material procurement scheduling
- Work-in-progress (WIP) tracking
- Bill of Materials (BOM) explosion

---

## 📊 Interview Talking Points

1. **System Design**: "I implemented an inventory trigger (A18) that prevents overselling by validating stock levels within the transaction. This eliminated a $50K/month problem with customer order cancellations."

2. **Data Integrity**: "Using composite keys in the inventory table allowed products to exist in multiple warehouses while maintaining referential integrity across 4 locations."

3. **Performance**: "By indexing `(product_id, warehouse_id)` in the inventory table, I reduced stock lookup queries from 800ms to 12ms for our high-traffic product pages."

4. **Business Impact**: "The reorder point query identified 5 products consistently running out of stock. Adjusting reorder logic increased revenue by 8% due to reduced stockouts."

---

## 🚀 Next Steps

- **Revenue Analysis**: See how inventory turnover affects profitability
- **Performance Optimization**: Learn indexing strategies for inventory queries at scale
- **Customer Analytics**: Connect stock availability to customer satisfaction metrics

---

[← Back to Main README](/README.md) | [View All Problems](/01-Basics/)