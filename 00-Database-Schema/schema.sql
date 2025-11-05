-- Below is a comprehensive dataset for a business scenario which includes departments, employees, customers, products, suppliers, orders, payments, shipments, inventory, reviews, events/logs, audit logs and product price history.
-- I designed this dataset for PostgreSQL and it includes various data types, constraints and relationships to facilitate complex SQL query practice


-- Create Tables
--Departments And Employees (Self referential managerial ID)
CREATE TABLE Departments (
    Department_ID INT PRIMARY KEY,
    Department_Name VARCHAR(50) NOT NULL,
    Department_Location VARCHAR(50)
);


CREATE TABLE Employees (
    Employee_ID INT PRIMARY KEY,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    Department_ID INT NOT NULL,
    FOREIGN KEY (Department_ID) REFERENCES Departments(Department_ID),
    Manager_ID INT NULL, 
    FOREIGN KEY (Manager_ID) REFERENCES Employees(Employee_ID) ON DELETE SET NULL,
    Salary DECIMAL(10,2) NOT NULL,
    Hire_Date DATE,
    Email VARCHAR(50) UNIQUE
);


--Customers
CREATE TABLE Customers(
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(50) NOT NULL,
    Customer_Email VARCHAR(50) UNIQUE,
    Country VARCHAR(50),
    Created_At TIMESTAMPTZ DEFAULT now() 
);


--Products And Categories 
CREATE TABLE Categories(
    Category_ID INT PRIMARY KEY,
    Category_Name VARCHAR(50)
); 


CREATE TABLE Products(
    Product_ID INT PRIMARY KEY,
    SKU VARCHAR(50) UNIQUE, --SKU = Stock Keeping Unit
    Product_Name VARCHAR(50) NOT NULL,
    Category_ID INT,
    FOREIGN KEY (Category_ID) REFERENCES Categories (Category_ID),
    Price DECIMAL (10, 2) NOT NULL,
    Tags VARCHAR(50),
    Specs  JSONB
);


--Suppliers And Product Suppliers 
CREATE TABLE Suppliers
(
    Supplier_ID INT PRIMARY KEY,
    Supplier_Name VARCHAR(50) NOT NULL,
    Supplier_Country VARCHAR(50)
);


CREATE TABLE Product_Suppliers(
    Supplier_ID INT,
    FOREIGN KEY (Supplier_ID) REFERENCES Suppliers(Supplier_ID),
    Product_ID INT,
    FOREIGN KEY(Product_ID) REFERENCES Products(Product_ID),
    Supply_Price DECIMAL(10,2),
    PRIMARY KEY (Supplier_ID, Product_ID)
);


--Orders 
CREATE TABLE Orders(
    Order_ID INT PRIMARY KEY,
    Customer_ID INT,
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    Order_Date TIMESTAMPTZ NOT NULL DEFAULT now(),
    Status VARCHAR(50), --E.g Pending, Paid, Shipped, Cancelled
    Total_Amount DECIMAL (10,2) NOT NULL,
    Notes VARCHAR(50)
);


--OrderItems
CREATE TABLE Order_Items(
    Order_ID INT,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    Line_Number INT,
    Product_ID INT,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    Quantity INT NOT NULL CHECK (Quantity >0),
    Unit_Price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (Order_ID, Line_Number)
);


--Payments(Multiple Per Order Possible)
CREATE TABLE Payments (
    Payment_ID INT PRIMARY KEY,
    Order_ID INT,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    Amount DECIMAL (10,2) NOT NULL,
    Method VARCHAR(50), --E.g Card, Cash
    Paid_At TIMESTAMPTZ DEFAULT now(),
    Refunded BOOLEAN
);


--Shipments
CREATE TABLE Shipments(
    Shipment_ID INT PRIMARY KEY,
    Order_ID INT,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    Shipped_At TIMESTAMPTZ,
    Delivered_At TIMESTAMPTZ,
    Carrier VARCHAR(50)
);


--Inventory And Warehouses
CREATE TABLE Warehouses(
    Warehouse_ID INT PRIMARY KEY,
    Warehouse_Location VARCHAR (50),
    Capacity INT 
);


CREATE TABLE Inventory(
    Product_ID INT,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    Warehouse_ID INT,
    FOREIGN KEY (Warehouse_ID) REFERENCES Warehouses(Warehouse_ID),
    Quantity INT NOT NULL DEFAULT 0,
    Last_Restocked TIMESTAMPTZ,
    PRIMARY KEY (Product_ID, Warehouse_ID)
);


--Reviews
-- NOTE: The 'Rating' column must be an integer between 1 and 5 (enforced by CHECK constraint). Just a reminder.
CREATE TABLE Reviews(
    Review_ID INT PRIMARY KEY,
    Product_ID INT NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    Customer_ID INT,
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    Rating INT CHECK (Rating >=1 AND Rating <=5),
    Comment VARCHAR (50),
    Created_At TIMESTAMPTZ DEFAULT now()
);


--Events/Logs With JSONB For User Actions 
CREATE TABLE Events (
    Event_ID INT PRIMARY KEY,
    Customer_ID INT,
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    Event_Type VARCHAR(50),
    Event_Data JSONB,
    Created_At TIMESTAMPTZ DEFAULT now()
);


--Simple Audit Table
CREATE TABLE Audit_Logs (
    Log_ID INT PRIMARY KEY,
    Source_Table VARCHAR(50),
    Change JSONB, 
    Created_At TIMESTAMPTZ DEFAULT now()
);


--Product Price Table For Lag And Lead Practice 
CREATE TABLE Product_Price_History (
    Product_Price_History_ID INT PRIMARY KEY,
    Product_ID INT NOT NULL,
    FOREIGN KEY (Product_ID) REFERENCES Products (Product_ID),
    Price DECIMAL (10,2),
    Effective_From DATE NOT NULL
);



--Insert Data below

--Departments
INSERT INTO Departments (Department_ID, Department_Name, Department_Location) 
VALUES 
(1, 'Engineering', 'Ghana'),
(2, 'Suppport', 'Kenya'),
(3, 'HR', 'Remote'),
(4, 'Customer Rep', 'Remote'),
(5, 'Business Development', 'Nairaobi'),
(6, 'Social Media Manager', 'Nigeria'),
(7, 'Data Analyst', 'Remote'),
(8, 'Trainees', 'Remote');



--Employees
INSERT INTO Employees (Employee_ID, First_Name, Last_Name, Department_ID, Manager_ID, Salary, Hire_Date, Email)
VALUES 
(1, 'Alice', 'Nnamdi', 1, NULL, 8000, '2021-10-01', 'alicennamdi2@gmail.com'),
(2, 'Jude', 'Kwasi', 4, 1, 4000, '2019-01-29','jude@co'),
(3, 'Mensah', 'Jeremiah', 5, NULL, 3500, '2022-01-01', 'mensah@yahoo.com'),
(4, 'Janet', 'Moses', 7, 5, 3600, '2020-08-24', 'janet.co'),
(5, 'Miriam', 'Frances', 2, 1, 4000, '2019-01-13', 'miriam@email'),
(6, 'Josiah', 'Jameson', 6, 4, 2000, '2020-09-28', 'josiah.online'),
(7, 'Abel', 'Manaseh', 3, 3, 2500, '2020-10-28', 'abelmanaseh2@wagmi' ),
(8, 'Victor', 'Rodney', 1, NULL, 5200, '2023-11-08', 'victor@gmail.com'),
(9, 'Ezekiel', 'John', 1, 1, 7800, '2021-05-19', 'ezekieljohn@email'),
(10, 'Samuel', 'Kofi', 4, 2, 2100, '2018-12-11', 'samuelkofi@mail'),
(11, 'Daniel', 'Osei', 5, 3, 3400, '2022-03-15', 'danielosei@work'),
(12, 'Grace', 'Adu', 7, 5, 3700, '2020-11-20', 'graceadu@data'),
(13, 'Ruth', 'Baah', 2, 5, 3500, '2019-02-25', 'ruthbaah@support'),
(14, 'Peter', 'Mensah', 6, 4, 2000, '2020-10-05', 'petermensah@mail'),
(15, 'Linda', 'Ewusu', 3, 3, 2500, '2020-12-12', 'lindaowusu@hr'),
(16, 'Michael', 'Bami', 8, 12, 1300, '2024-12-01', 'Michaelbami@datatrainee'),
(17, 'Sarah', 'Agyapong', 4, 2, 2200, '2018-11-30', 'sarahagyapong@customer'),
(18, 'Abena', 'Nyarko', 5, 3, 3300, '2022-04-10', 'abena.nyarko@business'),
(19, 'Jamie', 'Jordan', 7, 12, 3800, '2020-12-30', 'yaaasantewaa@data'),
(20, 'Lem', 'Mordu', 8, 13 , 1500, '2025-03-18', 'kwamebadu@supporttrainee'),
(21, 'Nana', 'Kweku', 8, 18, 1200, '2024-10-15', 'nanakwaku@ebusinessdevtrainee');



--Customers
INSERT INTO Customers (Customer_ID, Customer_Name, Customer_Email, Country, Created_At)
VALUES
(1, 'Amy', 'amy2@gmail', 'Kenya', '2024-01-14'),
(2, 'Jules', 'julesheir@gmail', 'Nairaobi', '2024-10-04'),
(3, 'Ada', 'adahottest10@gmail', 'Nigeria', '2024-11-18'),
(4, 'John', 'johnnyblaze@yahoo', 'Ghana', '2024-01-22'),
(5, 'Andy', NULL, NULL, '2024-03-14'),
(6, 'Josef', NULL, 'Rwanda', '2025-05-16'),
(7, 'James', 'bigjames@mail', NULL, '2024-01-14'),
(8, 'Chidi', 'chuks@gmail.com', 'Nigeria', '2025-06-30'),
(9, 'Kofi', 'kofi2@mail', 'Ghana', '2024-07-19'),
(10, 'Lily','lilyrose@yahoo', 'Kenya', '2024-08-25'),
(11, 'Mia', 'mia2024@gmail', 'Nigeria', '2024-09-10'),
(12, 'Noah', 'noahking@mail', 'Singapore', '2024-10-05'),
(13, 'Olivia', 'oliviabest@yahoo', 'Ghana', '2024-11-11'),
(14, 'Paul', 'paulie@gmail', 'USA', '2024-12-01'),
(15, 'Quincy', 'quincyq@mail', 'Canada', '2025-01-20'),
(16, 'Rita', 'ritabest@yahoo', 'UK', '2025-02-14'),
(17, 'Sam', NULL, 'Australia', '2025-03-03'),
(18, 'Tina', 'tinapower@mail', 'South Africa', '2025-04-22'),
(19, 'Uma', 'umaking@yahoo', 'India', '2025-05-30'),
(20, 'Vera', 'veravibes@gmail', 'China', '2025-06-15'),
(21, 'Wale', 'walechamp@mail', 'Nigeria', '2025-07-07'),
(22, 'Xena', 'xenastar@yahoo', 'Ghana', '2025-08-19'),
(23, 'Yara', 'yaralove@gmail', 'Kenya', '2025-09-09'),
(24, 'Zack', NULL, 'USA', '2025-10-31'),
(25, 'Ben', 'benjamin@yahoo', NULL, '2025-11-25'),
(26, 'Cathy', 'cathygirl@gmail', 'Canada', '2025-12-12'),
(27, 'Derek', 'derekpower@mail', 'Australia', '2025-01-18'),
(28, 'Eva', 'evastar@yahoo', 'India', '2025-02-22'),
(29, 'Frank', 'frankie@gmail', 'China', '2025-03-30'),
(30, 'Gina', 'ginaisgood@mail', 'South Africa', '2025-04-14'),
(31, 'Hank', 'hankthetank@yahoo', 'USA', '2025-05-05'),
(32, 'Ivy', 'ivygirl@gmail', 'Canada', '2025-06-21'),
(33, 'Jack', NULL, 'Australia', '2025-07-11'),
(34, 'Kara', 'karakool@mail', 'India', '2025-08-29'),
(35, 'Liam', NULL, NULL, '2025-09-17');



-- Categories
INSERT INTO  Categories (Category_ID, Category_Name)
VALUES 
(1, 'Computers'),
(2, 'Mobiles'),
(3, 'Accessories'),
(4, 'Office'),
(5, 'Gaming'),
(6, 'Furniture'),
(7, 'Appliances'),
(8, 'Clothing');



-- Products (tags and specs JSON)
INSERT INTO Products (Product_ID, SKU, Product_Name, category_id, price, tags, specs) 
VALUES
(1, 'SKU-001','Laptop Pro',1,4200.00,ARRAY['laptop','pro','work'],'{"ram_gb":16,"weight_g":2000}'),
(2, 'SKU-002','Smartphone X',2,500.00,ARRAY['phone','mobile'],'{"screen_in":6.1,"battery_mah":3000}'),
(3, 'SKU-003','Headphones 2',3,300.00,ARRAY['audio','headphones'],'{"wireless":true,"noise_cancel":false}'),
(4, 'SKU-004','Mechanical Keyboard',4,40.00,ARRAY['keyboard','peripheral'],'{"switch":"blue","layout":"uk"}'),
(5, 'SKU-005','Unordered Item',5,1199.00,ARRAY['new'],'{"sample":true}'), -- product never ordered
(6, 'SKU-006','Office Chair',6,1500.00,ARRAY['furniture','office'],'{"material":"leather","wheels":true}'),
(7, 'SKU-007','4K TV',7,800.00,ARRAY['tv','4k'],'{"size_in":55,"smart_tv":true}'),
(8, 'SKU-008','Winter Jacket',8,120.00,ARRAY['clothing','jacket'],'{"size":"L","waterproof":true}'),
(9, 'SKU-009','Gaming Mouse',5,70.00,ARRAY['gaming','mouse'],'{"dpi":16000,"wired":false}'),
(10, 'SKU-010','Bluetooth Speaker',3,150.00,ARRAY['audio','speaker'],'{"battery_mah":5000,"water_resistant":true}'),
(11, 'SKU-011','Smartwatch Z',2,250.00,ARRAY['wearable','smartwatch'],'{"screen_in":1.5,"heart_rate_monitor":true}'),
(12, 'SKU-012','Desk Lamp',4,45.00,ARRAY['lighting','lamp'],'{"led":true,"adjustable_brightness":true}'),
(13, 'SKU-013','External Hard Drive',1,100.00,ARRAY['storage','hard_drive'],'{"capacity_gb":2000,"usb_type":"c"}'),
(14, 'SKU-014','Fitness Tracker',2,80.00,ARRAY['wearable','fitness'],'{"water_resistant":true,"gps":true}'),
(15, 'SKU-015','E-reader',1,120.00,ARRAY['reading','ebook'],'{"screen_in":6,"backlight":true}'),
(16, 'SKU-016','Noise-Cancelling Earbuds',3,200.00,ARRAY['audio','earbuds'],'{"wireless":true,"noise_cancel":true}'),
(17, 'SKU-017','Smart Home Hub',7,180.00,ARRAY['smart_home','hub'],'{"voice_control":true,"wifi_enabled":true}'),
(18, 'SKU-018','4K Monitor',1,300.00,ARRAY['monitor','4k'],'{"size_in":27,"refresh_rate_hz":144}'),
(19, 'SKU-019','Graphic Tablet',1,350.00,ARRAY['tablet','graphic'],'{"pressure_levels":8192,"size_in":10}'),
(20, 'SKU-020','Portable Projector',7,400.00,ARRAY['projector','portable'],'{"resolution":"1080p","battery_life_min":120}');



-- Suppliers Amd Product Suppliers
INSERT INTO Suppliers (Supplier_ID, Supplier_Name, Supplier_Country) 
VALUES
(1, 'SupplyCo','China'),
(2, 'AfricaNGNImport','Nigeria'),
(3, 'TechDistributors','USA'),
(4, 'GadgetWorld','Germany'),
(5, 'OfficeGoods','UK'),
(6, 'LocalSupplies','Ghana'),
(7, 'RemoteSupplies','Remote'),
(8, 'NoProducts','Nowhere'); -- supplier with no products



INSERT INTO Product_Suppliers (supplier_id,product_id,supply_price) 
VALUES
(1,1,9000.00), -- multiple suppliers for product ID 1, you'll notice the same for some other products below.
(1,2,3000.00),
(2,3,400.00),
(3,4,250.00),
(4,5,2000.00),
(5,6,405.00),
(6,1,9500.00), 
(7,2,3200.00), 
(2,7,700.00),
(3,8,100.00),
(4,9,60.00),
(5,10,120.00),
(6,11,220.00),
(7,12,50.00),
(1,13,150.00),
(2,14,90.00),
(3,15,130.00),
(4,16,180.00),
(5,17,160.00),
(6,18,280.00),
(7,19,300.00),
(1,20,450.00);



-- Orders And Order Items (some split payments, refunds)
INSERT INTO Orders (Order_ID, customer_id,order_date,status,total_amount,notes) 
VALUES
(1, 1,'2025-01-05','paid',8200,'Laptop order'),
(2, 2,'2025-01-10','paid',580,'Phone + headphones'),
(3, 1,'2025-02-01','paid',540,'Phone + keyboard'),
(4, 3,'2025-02-15','paid',300,'Monitor'),
(5, 4,'2025-03-01','pending',80,'Headphones pre-order'),
(6, 6,'2024-12-25','cancelled',0,'Christmas test'), -- cancelled order
(7, 5,'2025-01-20','shipped',940,'Office chair'),
(8, 2,'2025-02-28','paid',150,'Gaming mouse'),
(9, 14,'2025-03-10','pending',1200,'Laptop pre-order'),
(10, 17,'2025-03-15','paid',690,'4K TV + speaker'),
(11, 9,'2025-03-20','shipped',400,'Smartphone X'),
(12, 10,'2025-03-25','paid',300,'Headphones 2'),
(13, 11,'2025-03-30','pending',1500,'Office chair'),
(14, 12,'2025-04-05','paid',120,'Winter Jacket'),
(15, 13,'2025-04-10','shipped',800,'4K TV'),
(16, 14,'2025-04-28','paid',70,'Gaming Mouse'),
(17, 15,'2025-05-02','pending',150,'Bluetooth Speaker'),
(18, 16,'2025-05-10','paid',4200,'Laptop Pro'),
(19, 14,'2025-05-15','shipped',500,'Smartphone X'),
(20, 18,'2025-05-20','paid',300,'Headphones 2'),
(21, 19,'2025-06-01','pending',350,'Mechanical Keyboard'),
(22, 20,'2025-06-10','paid',1500,'Office Chair'),
(23, 20,'2025-06-15','shipped',800,'4K TV'),
(24, 22,'2025-06-20','paid',120,'Winter Jacket'),
(25, 23,'2025-07-01','pending',100,'External Hard Drive'),
(26, 24,'2025-07-10','paid',250,'Smartwatch Z'),
(27, 25,'2025-07-15','shipped',45,'Desk Lamp'),
(28, 26,'2025-07-20','paid',200,'Noise-Cancelling Earbuds'),
(29, 27,'2025-08-01','pending',180,'Smart Home Hub'),
(30, 23,'2025-08-10','paid',300,'4K Monitor'),
(31, 23,'2025-08-15','shipped',350,'Graphic Tablet'),
(32, 30,'2025-08-20','paid',400,'Portable Projector'),
(33, 31,'2025-09-01','pending',9200,'Laptop Pro'),
(34, 32,'2025-09-10','paid',3500,'Smartphone X'),
(35, 33,'2025-09-15','shipped',800,'4K TV'),
(36, 31,'2025-09-20','paid',150,'Bluetooth Speaker'),
(37, 25,'2025-10-01','pending',120,'Winter Jacket');



INSERT INTO order_items (order_id,Line_Number,product_id,quantity,unit_price) 
VALUES
(1,1,1,1,1200.00),
(2,1,2,1,500.00),
(2,2,3,1,80.00),
(3,1,2,1,500.00),
(3,2,4,1,240.00),
(4,1,5,1,300.00),
(5,1,3,1,380.00),
(7,1,8,1,150.00),
(9,1,9,1,150.00),
(10,1,7,1,800.00),
(10,2,10,1,150.00),
(11,1,2,1,500.00),
(12,1,3,1,300.00),
(13,1,6,1,1500.00),
(14,1,8,3,120.00),
(15,1,7,1,800.00),
(16,1,9,2,70.00),
(17,1,10,1,150.00),
(18,1,1,1,4200.00),
(19,1,2,1,500.00),
(20,1,3,1,300.00),
(22,1,4,1,350.00),
(23,1,7,1,800.00),
(24,1,8,1,120.00),
(25,1,13,6,100.00),
(26,1,11,1,250.00),
(27,1,12,3,45.00);



-- Payments (split payments example and refund)
INSERT INTO Payments (Payment_ID, Order_ID, Amount, Method, Paid_at, Refunded) 
VALUES
(1, 1,1200,'card','2025-01-05T12:00:00Z',FALSE),
(2, 2,580,'cash','2025-01-10T10:00:00Z',FALSE),
(3, 3,540,'card','2025-02-01T09:00:00Z',FALSE),
(4, 4,300,'bank_transfer','2025-02-16T10:00:00Z',FALSE),
(5, 5,450,'card','2025-03-01T08:00:00Z',FALSE),
(6, 5,490,'cash','2025-03-01T09:00:00Z',FALSE),
(7, 6,0,'card','2024-12-25T00:00:00Z',FALSE),
(8, 7,1500,'card','2025-01-20T11:00:00Z',FALSE),
(9, 8,690,'cash','2025-02-28T14:00:00Z',FALSE),
(10, 2,580,'card','2025-01-15T10:00:00Z',TRUE), -- refund on order 2
(11, 9,1200,'bank_transfer','2025-03-10T12:00:00Z',FALSE),
(12, 10,690,'card','2025-03-15T13:00:00Z',FALSE),
(13, 11,400,'cash','2025-03-20T15:00:00Z',FALSE),
(14, 12,300,'card','2025-03-25T16:00:00Z',FALSE),
(15, 13,1500,'bank_transfer','2025-03-30T10:00:00Z',FALSE),
(16, 14,120,'cash','2025-04-05T11:00:00Z',FALSE),
(17, 15,800,'card','2025-04-10T12:00:00Z',FALSE),
(18, 16,70,'bank_transfer','2025-04-28T13:00:00Z',FALSE),
(19, 17,150,'card','2025-05-02T14:00:00Z',FALSE),
(20, 18,4200,'cash','2025-05-10T15:00:00Z',FALSE),
(21, 19,500,'card','2025-05-15T16:00:00Z',FALSE),
(22, 20,300,'bank_transfer','2025-05-20T10:00:00Z',FALSE),
(23, 21,350,'card','2025-06-01T11:00:00Z',FALSE),
(24, 22,1500,'cash','2025-06-10T12:00:00Z',FALSE),
(25, 23,800,'bank_transfer','2025-06-15T13:00:00Z',FALSE),
(26, 24,120,'card','2025-06-20T14:00:00Z',FALSE),
(27, 25,100,'cash','2025-07-01T15:00:00Z',FALSE),
(28, 26,250,'bank_transfer','2025-07-10T16:00:00Z',FALSE),
(29, 27,45,'card','2025-07-15T10:00:00Z',FALSE),
(30, 28,200,'cash','2025-07-20T11:00:00Z',FALSE),
(31, 29,180,'bank_transfer','2025-08-01T12:00:00Z',FALSE),
(32, 30,300,'card','2025-08-10T13:00:00Z',FALSE),
(33, 31,350,'cash','2025-08-15T14:00:00Z',FALSE),
(34, 32,400,'bank_transfer','2025-08-20T15:00:00Z',FALSE),
(35, 33,9200,'card','2025-09-01T10:00:00Z',FALSE),
(36, 34,3500,'cash','2025-09-10T11:00:00Z',FALSE),
(37, 35,800,'bank_transfer','2025-09-15T12:00:00Z',FALSE),
(38, 36,150,'card','2025-09-20T13:00:00Z',FALSE),
(39, 37,120,'cash','2025-10-01T14:00:00Z',FALSE);



-- Shipments
INSERT INTO shipments (Shipment_ID, Order_ID, Shipped_At, Delivered_At, Carrier) 
VALUES
(1, 1,'2025-01-06T10:00:00Z','2025-01-08T15:00:00Z','DHL'),
(2, 2,'2025-01-11T08:00:00Z','2025-01-14T12:00:00Z','FedEx'),
(3, 3,NULL,NULL,NULL), --Order 3 still being processed, hence the NULLs. Same for a couple others below
(4, 4,'2025-02-17T09:00:00Z',NULL,'UPS'), --Delivered_at is NULL, indicating the shipment is not yet delivered, same for a couple others below
(5, NULL,NULL,NULL,NULL), -- Cancelled order, no shipment
(6, 5,'2025-02-01T11:00:00Z','2025-01-03T13:00:00Z','FedEx'),
(7, 7,'2025-01-21T10:00:00Z','2025-01-25T16:00:00Z','DHL'),
(8, 8,'2025-03-01T11:00:00Z','2025-03-03T13:00:00Z','FedEx'),
(9, 9,'2025-03-01T14:00:00Z','2025-03-03T19:00:00Z','Aramex'),
(10, 10,'2025-03-16T12:00:00Z','2025-03-20T14:00:00Z','UPS'),
(11, 11,'2025-03-21T13:00:00Z','2025-03-25T15:00:00Z','DHL'),
(12, 12,'2025-03-26T14:00:00Z','2025-03-30T16:00:00Z','FedEx'),
(13, 13,'2025-04-01T10:00:00Z','2025-04-09T12:00:00Z','Aramex'),
(14, 14,'2025-04-06T10:00:00Z','2025-04-10T12:00:00Z','UPS'),
(15, 15,'2025-04-11T11:00:00Z','2025-04-15T13:00:00Z','DHL'),
(16, 16,'2025-05-01T09:00:00Z','2025-05-03T11:00:00Z','FedEx'),
(17, 17,'2025-05-03T10:00:00Z','2025-05-07T12:00:00Z','UPS'),
(18, 18,'2025-05-11T08:00:00Z','2025-05-15T10:00:00Z','DHL'),
(19, 19,'2025-05-16T09:00:00Z','2025-05-20T11:00:00Z','FedEx'),
(20, 20,'2025-05-21T10:00:00Z','2025-05-25T12:00:00Z','UPS'),
(21, NULL,NULL,NULL,NULL), --Cancelled Order
(22, 22,'2025-06-11T11:00:00Z','2025-06-15T13:00:00Z','DHL'),
(23, 23,'2025-06-16T12:00:00Z','2025-06-20T14:00:00Z','FedEx'),
(24, 24,'2025-06-21T13:00:00Z','2025-06-25T15:00:00Z','UPS'),
(25, 25,'2025-07-10T12:00:00Z','2025-07-11T14:00:00Z','Amazon Shipping'),
(26, 26,'2025-07-11T10:00:00Z','2025-07-15T12:00:00Z','DHL'),
(27, 27,'2025-07-16T11:00:00Z','2025-07-20T13:00:00Z','FedEx'),
(28, 28,'2025-07-21T12:00:00Z','2025-07-25T14:00:00Z','UPS'),
(29, 29,'2025-07-25T11:00:00Z','2025-07-29T15:00:00Z','UPS'),
(30, 30,'2025-08-11T09:00:00Z','2025-08-15T11:00:00Z','DHL'),
(31, 31,'2025-08-16T10:00:00Z','2025-08-20T12:00:00Z','FedEx'),
(32, 32,'2025-08-21T11:00:00Z','2025-08-25T13:00:00Z','UPS'),
(33, 34,'2025-09-11T08:00:00Z', NULL,'DHL'),
(34, 35,'2025-09-16T09:00:00Z','2025-09-20T11:00:00Z','FedEx'),
(35, 36,'2025-09-21T10:00:00Z','2025-09-25T12:00:00Z','UPS'),
(36, 37,NULL,NULL,NULL); --Order 36 still being processed



-- Warehouses & Inventory
INSERT INTO warehouses (Warehouse_ID, Warehouse_Location, Capacity) 
VALUES 
(1, 'Lagos WH',1000),
(2, 'Accra WH',800),
(3, 'Nairobi WH',600),
(4, 'Remote WH',400);



INSERT INTO inventory (Product_ID, Warehouse_ID, Quantity, Last_Restocked) 
VALUES
--Some Products are in multiple warehouses
(1,1,10,'2025-02-01'),
(2,1,20,'2025-01-20'),
(3,2,5,'2024-12-01'),
(4,2,15,'2025-01-15'),
(5,3,8,'2025-02-10'),
(6,4,12,'2025-01-25'),
(1,2,7,'2025-02-05'),
(2,3,14,'2025-01-30'),
(3,4,9,'2025-02-18'),
(4,1,11,'2025-01-28'),
(5,2,6,'2025-02-12'),
(6,3,10,'2025-01-22'),
(7,1,6,'2025-02-12'),
(8,3,9,'2025-01-18'),
(9,4,11,'2025-02-20'),
(10,1,4,'2025-01-22'),
(11,2,13,'2025-02-15'),
(12,3,10,'2025-01-28'),
(13,4,5,'2025-02-08'),
(14,1,16,'2025-01-12'),
(15,2,7,'2025-02-18'),
(16,3,9,'2025-01-30'),
(17,4,14,'2025-02-25'),
(18,1,8,'2025-01-16'),
(19,2,12,'2025-02-22'),
(20,3,6,'2025-01-24'),
(7,4,10,'2025-02-28'),
(8,1,15,'2025-01-14'),
(9,2,9,'2025-02-10'),
(10,3,11,'2025-01-26'),
(11,4,7,'2025-02-05');



-- Reviews
INSERT INTO reviews (Review_ID, Product_ID, Customer_ID, Rating, Comment, Created_At) 
VALUES
(1, 1,1,5,'Excellent laptop','2025-01-12T09:00:00Z'),
(2, 3,2,4,'Good sound for the price','2025-01-15T10:00:00Z'),
(3, 5,3,3,'Decent monitor','2025-02-20T11:00:00Z'),
(4, 2,1,4,'Great phone overall','2025-02-05T12:00:00Z'),
(5, 4,2,5,'Loving the keyboard!','2025-02-10T13:00:00Z'),
(6, 6,5,2,'Mouse stopped working','2025-03-05T14:00:00Z'),
(7, 8,4,5,'Very comfortable chair','2025-02-25T15:00:00Z'),
(8, 3,6,1,'Poor quality headphones','2025-03-10T16:00:00Z'),
(9, 7,7,4,'Good value for money','2025-03-15T17:00:00Z'),
(10, 9,8,5,'Perfect for gaming','2025-03-20T18:00:00Z'),
(11, 10,9,3,'Average speaker','2025-04-01T09:30:00Z'),
(12, 11,10,4,'Nice smartwatch','2025-04-05T10:45:00Z'),
(13, 12,11,2,'Lamp is too dim','2025-04-10T11:15:00Z'),
(14, 13,12,5,'Fast and reliable hard drive','2025-04-15T12:20:00Z'),
(15, 14,13,4,'Great fitness tracker','2025-04-20T13:25:00Z'),
(16, 15,14,3,'E-reader is okay','2025-04-25T14:30:00Z'),
(17, 16,15,5,'Love these earbuds!','2025-05-01T15:35:00Z'),
(18, 17,16,4,'Smart home hub works well','2025-05-05T16:40:00Z'),
(19, 18,17,2,'Monitor has dead pixels','2025-05-10T17:45:00Z'),
(20, 19,18,5,'Graphic tablet is fantastic','2025-05-15T18:50:00Z'),
(21, 20,19,4,'Projector is bright and clear','2025-05-20T19:55:00Z');



-- Events/Logs For User Actions (JSONB)
INSERT INTO events (Event_ID, Customer_ID, Event_Type, Event_Data, Created_At) 
VALUES
(1, 1,'page_view','{"path":"/product/1","utm":"campaign-x"}', '2025-09-24T09:31:40.3Z'),
(2, 2,'add_to_cart','{"product_id":2,"qty":1}', '2025-09-24T09:35:11Z'),
(3, 3,'purchase','{"order_id":4,"total":300}', '2025-09-25T10:35:28Z'),
(4, 1,'search','{"query":"laptop","results":5}', '2025-09-24T09:33:30Z'),
(5, 4,'page_view','{"path":"/category/3"}', '2025-09-25T11:22:48Z'),
(6, 5,'add_to_cart','{"product_id":6,"qty":2}', '2025-09-25T11:23:33Z'),
(7, 6,'purchase','{"order_id":8,"total":150}', '2025-09-25T11:35:50Z'),
(8, 2,'search','{"query":"gaming mouse","results":2}', '2025-09-24T09:36:41Z'),
(9, 3,'page_view','{"path":"/product/5"}', '2025-09-25T11:00:01Z'),
(10, 4,'add_to_cart','{"product_id":8,"qty":1}', '2025-09-25T12:35:25Z'),
(11, 5,'purchase','{"order_id":12,"total":300}', '2025-09-25T12:45:30Z'),
(12, 16,'search','{"query":"office chair","results":3}', '2025-09-25T13:15:15Z'),
(13, 31,'page_view','{"path":"/category/1"}', '2025-09-24T09:40:20Z'),
(14, 22,'add_to_cart','{"product_id":1,"qty":1}', '2025-09-24T09:42:10Z'),
(15, 33,'purchase','{"order_id":2,"total":580}', '2025-09-25T10:50:45Z'),
(16, 14,'search','{"query":"4K TV","results":4}', '2025-09-25T11:30:05Z'),
(17, 5,'page_view','{"path":"/product/7"}', '2025-09-25T12:10:55Z'),
(18, 27,'add_to_cart','{"product_id":10,"qty":1}', '2025-09-25T13:05:35Z'),
(19, 9,'purchase','{"order_id":18,"total":4200}', '2025-09-24T10:00:00Z'),
(20, 23,'search','{"query":"smartwatch","results":3}', '2025-09-24T09:45:50Z'),
(21, 22,'page_view','{"path":"/category/5"}', '2025-09-25T11:05:15Z'),
(22, 20,'add_to_cart','{"product_id":9,"qty":1}', '2025-09-25T12:40:20Z'),
(23, 5,'purchase','{"order_id":22,"total":1500}', '2025-09-25T13:20:30Z'),
(24, 6,'search','{"query":"desk lamp","results":2}', '2025-09-25T13:45:55Z'),
(25, 10,'page_view','{"path":"/product/3"}', '2025-09-24T09:50:30Z'),
(26, 32,'add_to_cart','{"product_id":4,"qty":1}', '2025-09-24T09:52:15Z'),
(27, 30,'purchase','{"order_id":6,"total":0}', '2025-09-25T10:55:20Z'),
(28, 24,'search','{"query":"headphones","results":4}', '2025-09-25T11:35:40Z'),
(29, 25,'page_view','{"path":"/category/2"}', '2025-09-25T12:15:10Z'),
(30, 6,'add_to_cart','{"product_id":12,"qty":1}', '2025-09-25T13:10:25Z'),
(31, 11,'purchase','{"order_id":34,"total":3500}', '2025-09-24T10:05:30Z'),
(32, 12,'search','{"query":"winter jacket","results":2}', '2025-09-24T09:55:45Z'),
(33, 13,'page_view','{"path":"/product/8"}', '2025-09-25T11:10:20Z'),
(34, 4,'add_to_cart','{"product_id":14,"qty":1}', '2025-09-25T12:45:35Z'),
(35, 15,'purchase','{"order_id":26,"total":250}', '2025-09-25T13:25:40Z'),
(36, 26,'search','{"query":"portable projector","results":1}', '2025-09-25T13:50:10Z'),
(37, 31,'page_view','{"path":"/category/4"}', '2025-09-24T10:10:15Z'),
(38, 2,'add_to_cart','{"product_id":15,"qty":1}', '2025-09-24T10:12:05Z'),
(39, 33,'purchase','{"order_id":30,"total":300}', '2025-09-25T11:15:30Z'),
(40, 4,'search','{"query":"graphic tablet","results":2}', '2025-09-25T11:40:50Z');



-- Audit Logs (JSONB)
INSERT INTO audit_logs (Log_ID, Source_Table, Change) 
VALUES
(1, 'Products','{"action":"INSERT","productId":11,"name":"New Product","price":99.99}'),
(2, 'Orders','{"action":"UPDATE","orderId":3,"status":"shipped"}'),
(3, 'Customers','{"action":"DELETE","customerId":7}'),
(4, 'Employees','{"action":"INSERT","employeeId":9,"name":"New Employee","deptId":2}'),
(5, 'Payments','{"action":"UPDATE","paymentId":5,"refunded":true}'),
(6, 'Shipments','{"action":"INSERT","shipmentId":6,"orderId":8,"carrier":"DHL"}'),
(7, 'Inventory','{"action":"UPDATE","productId":1,"warehouseId":2,"quantity":20}'),
(8, 'Reviews','{"action":"INSERT","reviewId":9,"productId":4,"rating":5}'),
(9, 'Events','{"action":"INSERT","eventId":10,"customerId":3,"eventType":"page_view"}'),
(10, 'Departments','{"action":"UPDATE","deptId":1,"location":"Remote"}'),
(11, 'Suppliers','{"action":"DELETE","supplierId":4}'),
(12, 'Product_Suppliers','{"action":"INSERT","supplierId":5,"productId":6,"supplyPrice":450.00}'),
(13, 'Order_Items','{"action":"UPDATE","orderId":2,"lineNumber":1,"quantity":2}'),
(14, 'Warehouses','{"action":"INSERT","warehouseId":5,"location":"New Location","capacity":500}'),
(15, 'Product_Price_History','{"action":"INSERT","productPriceHistoryId":1,"productId":1,"price":9200,"effectiveFrom":"2025-01-01"}');



-- Product price history (for LAG)
INSERT INTO product_price_history (Product_Price_History_ID, product_id,price,effective_from) 
VALUES
(1, 1,9200,'2024-01-01'),
(2, 1,9100,'2023-01-01'),
(3, 2,3500,'2024-12-01'),
(4, 2,3450,'2023-01-01'),
(5, 3,800,'2024-06-01'),
(6, 3,750,'2023-01-01'),
(7, 4,400,'2024-03-01'),
(8, 4,350,'2023-01-01'),
(9, 5,300,'2024-11-01'),
(10, 5,280,'2023-01-01'),
(11, 6,460,'2024-05-01'),
(12, 6,550,'2023-01-01'),
(13, 7,850,'2024-09-01'),
(14, 7,800,'2023-01-01'),
(15, 8,160,'2024-10-01'),
(16, 8,150,'2023-01-01'),
(17, 9,75,'2024-08-01'),
(18, 9,70,'2023-01-01'),
(19, 10,160,'2024-07-01'),
(20, 10,150,'2023-01-01');


-- End of Script 