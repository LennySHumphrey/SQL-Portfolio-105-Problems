# Database Schema Overview

## E-Commerce Business Database

A fully normalized PostgreSQL database modeling a complete e-commerce operation with customer management, order processing, inventory tracking, and organizational structure.

---

## 📋 Table Inventory (15 Tables)

### **Core Business Tables**

#### **Customers**
Stores customer information and account creation tracking.
- **Primary Key**: `Customer_ID`
- **Key Columns**: `Customer_Name`, `Customer_Email` (unique), `Country`, `Created_At` (TIMESTAMPTZ)
- **Records**: 35 customers across multiple countries
- **Notable**: Includes NULL handling for missing emails/countries

#### **Products**
Product catalog with JSON specifications and array-based tags.
- **Primary Key**: `Product_ID`
- **Unique**: `SKU` (Stock Keeping Unit)
- **Key Columns**: `Product_Name`, `Category_ID` (FK), `Price`, `Tags` (VARCHAR), `Specs` (JSONB)
- **Records**: 20 products across 8 categories
- **Notable**: JSONB specs for flexible attributes (e.g., `{"ram_gb":16, "weight_g":2000}`)

#### **Categories**
Product categorization lookup table.
- **Primary Key**: `Category_ID`
- **Categories**: Computers, Mobiles, Accessories, Office, Gaming, Furniture, Appliances, Clothing
- **Records**: 8 categories

#### **Orders**
Customer order headers with status tracking.
- **Primary Key**: `Order_ID`
- **Foreign Key**: `Customer_ID` → Customers
- **Key Columns**: `Order_Date` (TIMESTAMPTZ), `Status` (paid/pending/shipped/cancelled), `Total_Amount`, `Notes`
- **Records**: 37 orders from Jan-Oct 2025
- **Notable**: Includes cancelled orders and various status states

#### **Order_Items**
Line items for each order (many-to-many resolution between Orders and Products).
- **Composite Primary Key**: `(Order_ID, Line_Number)`
- **Foreign Keys**: `Order_ID` → Orders, `Product_ID` → Products
- **Key Columns**: `Quantity` (CHECK > 0), `Unit_Price`
- **Records**: ~40 line items
- **Notable**: Captures historical pricing at time of order

---

### **Financial Tables**

#### **Payments**
Payment transactions supporting multiple payments per order.
- **Primary Key**: `Payment_ID`
- **Foreign Key**: `Order_ID` → Orders
- **Key Columns**: `Amount`, `Method` (card/cash/bank_transfer), `Paid_At` (TIMESTAMPTZ), `Refunded` (BOOLEAN)
- **Records**: 39 payment records including split payments and refunds
- **Notable**: Order #5 has split payments; Order #2 has a refund

#### **Product_Price_History**
Historical pricing for trend analysis and window function practice.
- **Primary Key**: `Product_Price_History_ID`
- **Foreign Key**: `Product_ID` → Products
- **Key Columns**: `Price`, `Effective_From` (DATE)
- **Records**: 20 price history records for LAG/LEAD practice
- **Use Case**: Track price changes over time, compute price trends

---

### **Logistics Tables**

#### **Shipments**
Shipment tracking from dispatch to delivery.
- **Primary Key**: `Shipment_ID`
- **Foreign Key**: `Order_ID` → Orders
- **Key Columns**: `Shipped_At`, `Delivered_At` (both TIMESTAMPTZ), `Carrier`
- **Records**: 36 shipment records
- **Notable**: NULLs indicate in-progress shipments; includes carriers (DHL, FedEx, UPS, Aramex)

#### **Warehouses**
Storage facility locations and capacity.
- **Primary Key**: `Warehouse_ID`
- **Key Columns**: `Warehouse_Location`, `Capacity` (INT)
- **Records**: 4 warehouses (Lagos, Accra, Nairobi, Remote)

#### **Inventory**
Stock levels across warehouses with restock tracking.
- **Composite Primary Key**: `(Product_ID, Warehouse_ID)`
- **Foreign Keys**: `Product_ID` → Products, `Warehouse_ID` → Warehouses
- **Key Columns**: `Quantity` (default 0), `Last_Restocked` (TIMESTAMPTZ)
- **Records**: 30+ inventory records
- **Notable**: Products can exist in multiple warehouses

---

### **Supply Chain Tables**

#### **Suppliers**
Supplier company information.
- **Primary Key**: `Supplier_ID`
- **Key Columns**: `Supplier_Name`, `Supplier_Country`
- **Records**: 8 suppliers globally
- **Notable**: Includes a supplier with no products for JOIN practice

#### **Product_Suppliers**
Many-to-many relationship between products and suppliers with pricing.
- **Composite Primary Key**: `(Supplier_ID, Product_ID)`
- **Foreign Keys**: `Supplier_ID` → Suppliers, `Product_ID` → Products
- **Key Columns**: `Supply_Price`
- **Records**: 21 supply relationships
- **Notable**: Products can have multiple suppliers at different prices

---

### **Organizational Tables**

#### **Departments**
Company organizational units.
- **Primary Key**: `Department_ID`
- **Key Columns**: `Department_Name`, `Department_Location`
- **Records**: 8 departments (Engineering, Support, HR, etc.)

#### **Employees**
Employee records with self-referential manager hierarchy.
- **Primary Key**: `Employee_ID`
- **Foreign Keys**: `Department_ID` → Departments, `Manager_ID` → Employees (self-referential)
- **Key Columns**: `First_Name`, `Last_Name`, `Salary`, `Hire_Date`, `Email` (unique)
- **Records**: 21 employees with manager relationships
- **Notable**: Self-referential FK enables recursive CTE queries for org charts

---

### **Engagement Tables**

#### **Reviews**
Product reviews with ratings and comments.
- **Primary Key**: `Review_ID`
- **Foreign Keys**: `Product_ID` → Products, `Customer_ID` → Customers
- **Key Columns**: `Rating` (INT, CHECK 1-5), `Comment`, `Created_At` (TIMESTAMPTZ)
- **Records**: 21 reviews with ratings 1-5
- **Use Case**: Sentiment analysis, product quality tracking

#### **Events**
User interaction tracking with JSONB event data.
- **Primary Key**: `Event_ID`
- **Foreign Key**: `Customer_ID` → Customers
- **Key Columns**: `Event_Type` (page_view, add_to_cart, purchase, search), `Event_Data` (JSONB), `Created_At` (TIMESTAMPTZ)
- **Records**: 40 events with structured JSON payloads
- **Use Case**: Sessionization, user behavior analysis, funnel tracking
- **Example JSON**: `{"query":"laptop", "results":5}`, `{"product_id":2, "qty":1}`

---

### **System Tables**

#### **Audit_Logs**
Change tracking for all table modifications.
- **Primary Key**: `Log_ID`
- **Key Columns**: `Source_Table`, `Change` (JSONB), `Created_At` (TIMESTAMPTZ)
- **Records**: 15 audit entries
- **Use Case**: Compliance, debugging, rollback capability
- **Example JSON**: `{"action":"UPDATE", "orderId":3, "status":"shipped"}`

---

## 🔗 Key Relationships

### **Customer Journey Flow**
```
Customers → Orders → Order_Items → Products
         ↓         ↓
      Events    Payments
                   ↓
              Shipments
```

### **Inventory Management Flow**
```
Products ← Product_Suppliers → Suppliers
   ↓
Inventory → Warehouses
```

### **Organizational Hierarchy**
```
Departments → Employees → Manager_ID (self-referential)
```

---

## 📊 Data Characteristics

**Time Range**: Jan 2018 - Oct 2025 (orders concentrated in 2024-2025)

**Geographic Distribution**:
- Customers: Nigeria, Ghana, Kenya, USA, Canada, UK, Australia, South Africa, India, China, Singapore, Rwanda
- Warehouses: Lagos, Accra, Nairobi, Remote
- Suppliers: China, Nigeria, USA, Germany, UK, Ghana

**Data Quality Features**:
- NULL values for realistic scenarios (missing emails, incomplete addresses)
- Cancelled orders (Order #6)
- Unordered products (Product #5)
- Suppliers without products (Supplier #8)
- Split payments and refunds
- In-progress shipments (NULL delivery dates)

---

## 🎯 Query Practice Opportunities

This schema enables practice with:

✅ **Basic Operations**: Filtering, sorting, aggregations, simple joins  
✅ **Advanced Joins**: Self-joins (employees), multiple FK paths, anti-joins  
✅ **JSONB Queries**: Extracting nested fields, containment checks, indexing  
✅ **Window Functions**: Rankings, running totals, LAG/LEAD for trends  
✅ **CTEs**: Recursive (org chart), non-recursive (complex logic breakdown)  
✅ **Transactions**: Multi-table inserts with rollback safety  
✅ **Performance**: Index strategies, EXPLAIN ANALYZE, query optimization  
✅ **Data Integrity**: Triggers, constraints, audit logging  

---

## 📁 Files in This Directory

- **`schema.sql`**: Complete DDL with CREATE TABLE statements and all INSERT data
- **`ERD.png`**: Entity Relationship Diagram (visual schema representation)
- **`schema-overview.md`**: This file - quick reference guide

---

## 🚀 Quick Start

Load the complete schema:
```sql
\i 00-Database-Schema/schema.sql
```

Verify tables loaded:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Check row counts:
```sql
SELECT 
    'Customers' AS table_name, COUNT(*) FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders;
-- Add more as needed
```

---

**Next Step**: Start with [Basics Problems](/01-Basics/) to explore this schema through practical queries!