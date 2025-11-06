# Revenue Analysis & Financial Reporting

## Business Context

Revenue analytics drive strategic decisions around pricing, product mix, market expansion, and growth forecasting. These SQL problems demonstrate financial analysis techniques used by business analysts, finance teams, and executive leadership for data-driven planning.

---

## 🎯 Key Business Questions Answered

### **1. Revenue Fundamentals**

**Business Problem**: What are our core revenue metrics? How do we track financial health?

**Relevant Problems**:
- **B9**: Compute total revenue from Orders (`SUM(Total_Amount)`)
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 60)
  - *Key Technique*: Simple SUM aggregation
  - *Business Use*: Top-line revenue for executive dashboards

- **B10**: Compute average order value (AOV)
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 66)
  - *Key Technique*: AVG aggregation with TRIM_SCALE
  - *Business Metric*: AOV = Total Revenue / Number of Orders

- **B11**: Find min and max product price
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 72)
  - *Key Technique*: MIN/MAX aggregation
  - *Business Use*: Price range analysis for market positioning

**Key Metrics Dashboard**:
```
Total Revenue:     $39,385.00
Average Order:     $1,064.45
Total Orders:      36
Total Visitors:    40
Conversion Rate:   90%
```

---

### **2. Time-Series Revenue Trends**

**Business Problem**: Is revenue growing? What's our month-over-month performance?

**Relevant Problems**:
- **I11**: Monthly revenue with month-over-month growth percentage
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 529)
  - *Key Technique*: DATE_TRUNC + CTE + LAG window function + percentage calculation
  - *Business Impact*: Executive reporting on growth trajectory

**Example Output**:
```
Month       | Revenue  | Previous  | MoM Growth %
------------|----------|-----------|-------------
2025-01     | $9,360   | -         | -
2025-02     | $1,140   | $9,360    | -87.8%
2025-03     | $2,090   | $1,140    | +83.3%
2025-04     | $2,110   | $2,090    | +0.96%
```

**Business Insight**: Identify seasonal patterns, growth acceleration/deceleration

---

### **3. Product Performance Analysis**

**Business Problem**: Which products drive revenue? What should we promote/discontinue?

**Relevant Problems**:
- **B13**: Each product with total units sold
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 87)
  - *Key Technique*: LEFT JOIN + SUM + GROUP BY
  - *Business Use*: Sales volume ranking

- **A17**: Product revenue percentile ranking
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1310)
  - *Key Technique*: PERCENT_RANK() window function
  - *Business Use*: Identify top/bottom performers for strategic decisions

**Product Revenue Analysis**:
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.price AS list_price,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS total_revenue,
    PERCENT_RANK() OVER (ORDER BY SUM(oi.unit_price * oi.quantity)) AS revenue_percentile
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.status != 'cancelled' OR o.status IS NULL
GROUP BY p.product_id, p.product_name, p.price
ORDER BY total_revenue DESC;
```

**80/20 Rule**: Top 20% of products typically generate 80% of revenue

---

### **4. Category & Segmentation Performance**

**Business Problem**: Which product categories are growing? Where should we invest?

**Relevant Problems**:
- **A6**: Pivot monthly revenue by category (Crosstab)
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1055)
  - *Key Technique*: Crosstab() table function with dynamic column generation
  - *Business Use*: Executive reporting with category columns

**Crosstab Output** (Simplified):
```
Month     | Computers | Mobiles | Accessories | Office
----------|-----------|---------|-------------|-------
2025-01   | $4,200    | $1,080  | $380        | $240
2025-02   | $0        | $500    | $300        | $340
2025-03   | $1,200    | $500    | $80         | $0
```

**Strategic Decision**: Increase marketing spend on high-growth categories

---

### **5. Payment & Refund Reconciliation**

**Business Problem**: Are payments matching orders? What's our refund rate?

**Relevant Problems**:
- **B32**: Total payments by method (card, cash, bank_transfer)
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 294)
  - *Key Technique*: WHERE + GROUP BY method
  - *Business Use*: Payment processor fee optimization

- **I8**: Count paid vs. cancelled orders per customer with FILTER
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 656)
  - *Key Technique*: COUNT() FILTER (WHERE condition)
  - *Business Use*: Customer quality scoring

**Payment Reconciliation**:
```sql
SELECT 
    o.order_id,
    o.total_amount AS order_total,
    SUM(p.amount) FILTER (WHERE p.refunded = FALSE) AS payments_received,
    SUM(p.amount) FILTER (WHERE p.refunded = TRUE) AS refunds_issued,
    o.total_amount - COALESCE(SUM(p.amount) FILTER (WHERE p.refunded = FALSE), 0) AS outstanding_balance
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount != COALESCE(SUM(p.amount) FILTER (WHERE p.refunded = FALSE), 0);
```

**Alert**: Orders with payment discrepancies require investigation

---

### **6. Price Elasticity & Historical Trends**

**Business Problem**: How do price changes impact sales? What's the optimal price point?

**Relevant Problems**:
- **I7**: Use LAG to show previous order total (price history tracking)
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 474)
  - *Key Technique*: LAG() window function partitioned by product
  - *Business Use*: Before/after price change analysis

**Product Price History Analysis**:
```sql
SELECT 
    pph.product_id,
    p.product_name,
    pph.price,
    pph.effective_from,
    LAG(pph.price) OVER (PARTITION BY pph.product_id ORDER BY pph.effective_from) AS previous_price,
    ROUND(100.0 * (pph.price - LAG(pph.price) OVER (PARTITION BY pph.product_id ORDER BY pph.effective_from)) 
        / NULLIF(LAG(pph.price) OVER (PARTITION BY pph.product_id ORDER BY pph.effective_from), 0), 2) AS price_change_pct
FROM product_price_history pph
JOIN products p ON pph.product_id = p.product_id
ORDER BY pph.product_id, pph.effective_from;
```

**Elasticity Test**: Correlate price increases with sales volume changes

---

### **7. Customer Revenue Contribution**

**Business Problem**: Which customers drive the most revenue? How concentrated is our revenue?

**Relevant Problems**:
- **B33**: Top 3 customers by total spending
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 303)
  - *Key Technique*: JOIN + SUM + ORDER BY + LIMIT
  - *Business Use*: Account management prioritization

- **I3**: Customers spending above average
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 408)
  - *Key Technique*: Correlated subquery with HAVING
  - *Business Use*: VIP customer identification

**Revenue Concentration**:
```sql
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        SUM(o.total_amount) AS total_spent,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'paid'
    GROUP BY c.customer_id, c.customer_name
),
revenue_ranking AS (
    SELECT 
        *,
        SUM(total_spent) OVER () AS total_revenue,
        PERCENT_RANK() OVER (ORDER BY total_spent DESC) AS revenue_percentile
    FROM customer_revenue
)
SELECT 
    customer_name,
    total_spent,
    order_count,
    ROUND(100.0 * total_spent / total_revenue, 2) AS pct_of_total_revenue,
    revenue_percentile
FROM revenue_ranking
ORDER BY total_spent DESC
LIMIT 10;
```

**Risk Assessment**: > 20% revenue from single customer = high concentration risk

---

### **8. Rolling Revenue Metrics**

**Business Problem**: What's our 7-day/30-day rolling average? Are we trending up or down?

**Relevant Problems**:
- **A1**: 7-order rolling average per customer
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 930)
  - *Key Technique*: Window function with ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  - *Business Use*: Smoothed trend analysis for volatile data

**Rolling Average Query**:
```sql
SELECT 
    order_date::DATE,
    SUM(total_amount) AS daily_revenue,
    AVG(SUM(total_amount)) OVER (
        ORDER BY order_date::DATE 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_avg
FROM orders
WHERE status = 'paid'
GROUP BY order_date::DATE
ORDER BY order_date::DATE;
```

**Use Case**: Identify sustained growth vs. one-time spikes

---

### **9. Forecasting & Predictive Analytics**

**Business Problem**: What revenue can we expect next quarter? What's the growth trajectory?

**Relevant Problems**:
- **I11**: Month-over-month growth percentage (foundation for forecasting)
  - *Extension*: Apply linear regression or moving average for projections

**Simple Linear Trend**:
```sql
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS revenue,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', order_date)) AS month_num
    FROM orders
    WHERE status = 'paid'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    revenue,
    -- Simple linear projection (requires regression for accuracy)
    AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_3month_avg
FROM monthly_revenue
ORDER BY month;
```

**Advanced**: Export to Python/R for ARIMA or Prophet models

---

### **10. Profitability & Margin Analysis**

**Business Problem**: Are we profitable per product? What's our gross margin?

**Relevant Problems**:
- **I10**: Supplier pricing comparison (supply cost)
  - *Extension*: Compare `supply_price` vs. `sale_price` for margin calculation

**Margin Analysis**:
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.price AS sale_price,
    MIN(ps.supply_price) AS best_supplier_cost,
    p.price - MIN(ps.supply_price) AS gross_profit_per_unit,
    ROUND(100.0 * (p.price - MIN(ps.supply_price)) / NULLIF(p.price, 0), 2) AS gross_margin_pct
FROM products p
LEFT JOIN product_suppliers ps ON p.product_id = ps.product_id
GROUP BY p.product_id, p.product_name, p.price
ORDER BY gross_margin_pct DESC;
```

**Action**: Products with < 30% margin require price adjustment or cost reduction

---

## 🔧 Technical Skills Demonstrated

### **SQL Techniques**:
- Date truncation and time-series analysis
- Window functions (LAG, LEAD, PERCENT_RANK, rolling aggregates)
- CTEs for multi-step financial calculations
- FILTER for conditional aggregations
- Crosstab for pivot table reporting
- Complex JOIN patterns across financial entities

### **Financial Concepts**:
- Revenue recognition principles
- Average Order Value (AOV) and Customer Lifetime Value (CLV)
- Month-over-Month (MoM) and Year-over-Year (YoY) growth
- Gross margin and contribution margin
- Revenue concentration and diversification risk
- Price elasticity and demand curves

---

## 💼 Real-World Applications

**For SaaS**:
- Monthly Recurring Revenue (MRR) and Annual Recurring Revenue (ARR)
- Churn rate and net revenue retention
- Customer Acquisition Cost (CAC) payback period

**For E-Commerce**:
- Average transaction value optimization
- Product bundling revenue impact
- Seasonal trend forecasting

**For Marketplaces**:
- Take rate (commission) optimization
- Gross Merchandise Value (GMV) tracking
- Seller/buyer revenue contribution

---

## 📊 Interview Talking Points

1. **Business Impact**: "I built a month-over-month revenue dashboard (I11) that identified a 15% decline in March, prompting a targeted campaign that recovered $50K in sales."

2. **Data Quality**: "While calculating payment reconciliation, I discovered $12K in unmatched transactions and implemented a nightly audit trigger to prevent future discrepancies."

3. **Strategic Insight**: "Using product revenue percentiles (A17), I showed that 3 underperforming products were dragging down profitability. Discontinuing them improved margin by 8%."

4. **Technical Depth**: "I optimized the monthly revenue query from 8 seconds to 200ms by creating a materialized view with nightly refreshes, enabling real-time executive dashboards."

---

## 🚀 Next Steps

- **Customer Analytics**: Understand who's driving this revenue
- **Inventory Operations**: See how stock levels impact revenue opportunity
- **Performance Optimization**: Learn indexing for financial queries at scale

---

[← Back to Main README](/README.md) | [View All Problems](/03-Advanced/)