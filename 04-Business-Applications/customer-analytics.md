# Customer Analytics

## Business Context

Understanding customer behavior, value, and engagement is critical for sustainable growth. These SQL problems demonstrate analytical techniques used by product analysts, marketing teams, and customer success departments to drive data-informed decisions.

---

## 🎯 Key Business Questions Answered

### **1. Customer Lifetime Value (LTV)**

**Business Problem**: Which customers are most valuable? How do we identify high-value segments for targeted retention campaigns?

**Relevant Problems**:
- **A32**: Create a function calculating customer LTV from historical orders
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1676)
  - *Key Technique*: PL/pgSQL table-valued function with aggregation
  - *Business Impact*: Enables automated LTV scoring for CRM integration

- **I3**: Find customers whose total spending exceeds average customer spend
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 406)
  - *Key Technique*: Correlated subquery with HAVING clause
  - *Business Use*: Identify VIP customers for loyalty programs

**Sample Output**:
```
Customer_ID | Customer_Name | Lifetime_Value
------------|---------------|---------------
14          | Paul          | 10,590
20          | Vera          | 2,300
23          | Yara          | 950
```

**Business Insight**: Top 10% of customers drive 60%+ of revenue → Focus retention efforts here

---

### **2. Customer Segmentation**

**Business Problem**: How do we group customers for targeted marketing campaigns?

**Relevant Problems**:
- **B33**: Show top 3 customers by total spending
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 303)
  - *Key Technique*: JOIN + GROUP BY + ORDER BY with LIMIT
  - *Business Use*: Quick executive dashboard metrics

- **B12**: Count customers per country
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 79)
  - *Key Technique*: Simple GROUP BY aggregation
  - *Business Use*: Geographic market sizing for expansion planning

- **I18**: Combine Nigeria and Ghana customers with regional tags
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 656)
  - *Key Technique*: UNION ALL with source labeling
  - *Business Use*: Regional campaign targeting in West Africa

**Segmentation Framework**:
```
Segment        | Criteria                    | Action
---------------|-----------------------------|-----------------
Platinum       | LTV > $5,000               | White-glove support
Gold           | LTV $1,000-$5,000          | Loyalty rewards
Silver         | LTV $500-$1,000            | Upsell campaigns
Bronze         | LTV < $500                 | Engagement nurture
At-Risk        | No orders in 90+ days      | Win-back offers
```

---

### **3. Churn Identification & Prevention**

**Business Problem**: Which customers are at risk of churning? Who needs re-engagement?

**Relevant Problems**:
- **B15**: Find customers who have never placed an order
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 112)
  - *Key Technique*: LEFT JOIN with NULL filtering
  - *Business Impact*: Identify registration abandonment → Trigger onboarding emails

- **I4**: Return latest order date per customer
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 428)
  - *Key Technique*: DISTINCT ON with ORDER BY
  - *Business Use*: Calculate days since last purchase for churn scoring

- **B26**: Find orders in the last 90 days
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 240)
  - *Key Technique*: Date arithmetic with INTERVAL
  - *Business Use*: Define "active" customer cohort

**Churn Risk Model**:
```sql
-- Combining multiple problems into a churn score
SELECT 
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS last_order_date,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    CASE 
        WHEN MAX(o.order_date) < NOW() - INTERVAL '180 days' THEN 'High Risk'
        WHEN MAX(o.order_date) < NOW() - INTERVAL '90 days' THEN 'Medium Risk'
        WHEN COUNT(o.order_id) = 0 THEN 'Inactive Customer'
        ELSE 'Active'
    END AS churn_risk
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
```

---

### **4. Customer Engagement Analysis**

**Business Problem**: How do customers interact with our platform? Which behaviors predict conversion?

**Relevant Problems**:
- **A7**: Sessionization with 30-minute gap detection
  - *Query Location*: `03-Advanced/advanced-solutions.sql` (Line 1088)
  - *Key Technique*: Window functions with LAG + recursive session numbering
  - *Business Impact*: Measure session length, pages per session, conversion rates

- **I13**: List customers with specific event types (e.g., 'search' query)
  - *Query Location*: `02-Intermediate/intermediate-solutions.sql` (Line 587)
  - *Key Technique*: JSONB containment operator `?`
  - *Business Use*: Analyze search behavior for SEO/product discovery

- **B35**: Find events with UTM tracking parameters
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 341)
  - *Key Technique*: JSONB key existence check
  - *Business Use*: Campaign attribution analysis

**Engagement Funnel**:
```
Page View → Add to Cart → Purchase
   100%         15%           8%

[Based on Events table analysis]
```

---

### **5. Customer Acquisition & Retention Metrics**

**Business Problem**: Are we acquiring quality customers? What's our retention curve?

**Relevant Problems**:
- **B4**: List customers created after a specific date
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 25)
  - *Key Technique*: WHERE with timestamp filtering
  - *Business Use*: Cohort definition for retention analysis

- **B29**: Show customers and number of orders placed, sorted descending
  - *Query Location*: `01-Basics/basics-solutions.sql` (Line 262)
  - *Key Technique*: LEFT JOIN + COUNT + GROUP BY
  - *Business Use*: Calculate repeat purchase rate

**Retention Cohort Analysis** (Concept):
```
Month 0 | Month 1 | Month 2 | Month 3
--------|---------|---------|--------
100%    | 45%     | 32%     | 28%

[Build with B4 + I11 month-over-month patterns]
```

---

## 🔧 Technical Skills Demonstrated

### **SQL Techniques**:
- Correlated subqueries for customer comparisons
- Window functions (LAG, LEAD, RANK) for behavioral analysis
- JSONB queries for flexible event tracking
- CTEs for complex multi-step calculations
- Self-joins for sequential event analysis

### **Business Analytics Concepts**:
- Customer Lifetime Value (CLV/LTV) calculation
- RFM Analysis (Recency, Frequency, Monetary)
- Cohort retention tracking
- Churn risk scoring
- Funnel conversion optimization
- Campaign attribution modeling

---

## 💼 Real-World Applications

**For E-Commerce**:
- Personalized product recommendations based on customer segments
- Dynamic pricing for high-LTV customers
- Abandoned cart recovery campaigns

**For SaaS**:
- Usage-based health scoring
- Expansion revenue identification (upsell opportunities)
- Onboarding dropout analysis

**For Marketplaces**:
- Buyer/seller balance metrics
- Power user identification
- Fraud detection patterns

---

## 📊 Interview Talking Points

When discussing these problems in interviews:

1. **Connect to Business Outcomes**: "I used window functions to calculate customer LTV, which helped prioritize retention spend and increased ROI by identifying the top 20% of customers driving 70% of revenue."

2. **Show Trade-offs**: "For churn prediction, I compared correlated subqueries vs. CTEs. The CTE approach was more readable for stakeholders while maintaining performance."

3. **Demonstrate Ownership**: "I designed the sessionization logic (Problem A7) to handle edge cases like midnight sessions and multi-day user journeys."

4. **Explain Impact**: "The 'never ordered' query (B15) reduced customer acquisition cost by 15% when integrated into our onboarding email triggers."

---

## 🚀 Next Steps

- **Inventory Operations**: See how these customers connect to supply chain efficiency
- **Revenue Analysis**: Explore product performance and pricing strategies
- **Performance Optimization**: Learn indexing strategies for customer tables at scale

---

[← Back to Main README](/README.md) | [View All Problems](/02-Intermediate/)