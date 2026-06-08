-- 6 JUNE 2026
-- SQL END TO END
-- E-Commerce Analytics Database
/*
Customers
    |
    |
Orders
    |
    +------ Order_Items ------ Products ------ Categories
    |
Payments
    |
Shipments

Employees
    |
Departments

Suppliers
    |
Products
*/

CREATE DATABASE IF NOT EXISTS ecommerce01;
USE ecommerce01;


#CUSTOMERS TABLE

CREATE TABLE Customers( 
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(50) NOT NULL,
	email VARCHAR(30), 
	gender VARCHAR(5),
	city VARCHAR (30),
	state VARCHAR (30),
	signup_date DATE DEFAULT (CURRENT_DATE)
);

CREATE TABLE Orders(
	order_id INT PRIMARY KEY,
	customer_id INT,
	order_date DATE,
	order_status VARCHAR(20),
	total_amount DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY(customer_id) REFERENCES Customers(customer_id)
);
DESC ORDERS;
-- DROP TABLE IF EXISTS ORDERS;

CREATE TABLE Order_Items(
	order_item_id INT PRIMARY KEY,
	order_id INT,
	product_id INT,
	quantity DECIMAL(5,2),
	unit_price DECIMAL(10,2),
    FOREIGN KEY(order_id) REFERENCES Orders(order_id)
);
DESC Order_Items;

CREATE TABLE Products(
product_id INT PRIMARY KEY,
product_name VARCHAR(50),
category_id INT,
supplier_id INT,
cost_price DECIMAL(10,2),
selling_price DECIMAL(10,2)
);
DESC Products;
DROP TABLE IF EXISTS Products;

CREATE TABLE Categories(
category_id INT PRIMARY KEY,
category_name VARCHAR(50)
);
DESC Categories;


CREATE TABLE Suppliers(
supplier_id INT PRIMARY KEY,
supplier_name VARCHAR(50),
city VARCHAR(30)
);

CREATE TABLE Payments(
payment_id INT PRIMARY KEY,
order_id INT,
payment_method VARCHAR(20),
payment_status VARCHAR(20),
payment_date DATE DEFAULT (CURRENT_DATE),
FOREIGN KEY(order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Shipments(
	shipment_id INT PRIMARY KEY,
	order_id INT, 
	shipment_date DATE DEFAULT (CURRENT_DATE), 
	delivery_date DATE,
	shipment_status VARCHAR(20),
    FOREIGN KEY(order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Employees(
	employee_id INT PRIMARY KEY,
	employee_name VARCHAR(20) NOT NULL,
	department_id INT,
	salary DECIMAL(10,2),
	hire_date DATE DEFAULT (CURRENT_DATE),
	manager_id INT
);
DESC EMployees;
CREATE TABLE DEPARTMENTS(
	department_id INT PRIMARY KEY,
	department_name VARCHAR(50)
);

#ADD FOREIGN KEYS TO ALL TABLES WITHIN EACH OTHER.
ALTER TABLE Order_Items
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES Products(product_id);

ALTER TABLE Products
ADD CONSTRAINT fk_category
FOREIGN KEY (category_id)
REFERENCES Categories(category_id);

ALTER TABLE Products
ADD CONSTRAINT fk_supplier
FOREIGN KEY (supplier_id)
REFERENCES Suppliers(supplier_id);

ALTER TABLE Employees
ADD CONSTRAINT fk_department
FOREIGN KEY (department_id)
REFERENCES Departments(department_id);


SELECT 'Customers' AS table_name, COUNT(*) AS record_count
FROM Customers

UNION ALL

SELECT 'Departments', COUNT(*)
FROM Departments

UNION ALL

SELECT 'Employees', COUNT(*)
FROM Employees


UNION ALL

SELECT 'Categories', COUNT(*)
FROM Categories

UNION ALL

SELECT 'Orders', COUNT(*)
FROM Orders

UNION ALL

SELECT 'Products', COUNT(*)
FROM Products

UNION ALL

SELECT 'Order_Items', COUNT(*)
FROM Order_Items

UNION ALL

SELECT 'Payments', COUNT(*)
FROM Payments

UNION ALL

SELECT 'Shipments', COUNT(*)
FROM Shipments

UNION ALL

SELECT 'Suppliers', COUNT(*)
FROM Suppliers;

/*Task 2
Business Question:
Are there any orders whose customer 
does not exist in the Customers table?
This checks referential integrity.*/

#ORPHAN ORDER RECORDS
SELECT * FROM ORDERS O
JOIN CUSTOMERS C
ON O.customer_id = C.customer_id
WHERE O.CUSTOMER_ID IN (C.CUSTOMER_ID);

SELECT * FROM ORDERS O
LEFT JOIN CUSTOMERS C
ON O.customer_id = C.customer_id
WHERE C.CUSTOMER_ID IS NULL;

/*Task 3
# ANTI JOINS
Are there any products that were never ordered?*/
SELECT * FROM PRODUCTS;
-- product_id, product_name, category_id, supplier_id, cost_price, selling_price
SELECT * FROM ORDERS;
-- order_id, customer_id, order_date, order_status, total_amount
SELECT * FROM ORDER_ITEMS;
-- order_item_id, order_id, product_id, quantity, unit_price
#UNSOLD PRODUCTS
SELECT * FROM PRODUCTS
LEFT JOIN ORDER_ITEMS
ON PRODUCTS.PRODUCT_ID = ORDER_ITEMS.PRODUCT_ID
WHERE ORDER_ID IS NULL;

/*Task 4 — First Business KPI*/
/*Which customers generate the most revenue?*/
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,COUNT(O.ORDER_ID) AS No_of_Orders,
SUM(OD.QUANTITY * OD.UNIT_PRICE) AS CALCULATED_REVENUE, 
SUM(O.total_amount) as Revenue
FROM CUSTOMERS C
JOIN ORDERS O 
ON C.CUSTOMER_ID = O.CUSTOMER_ID
JOIN ORDER_ITEMS OD
ON O.ORDER_ID = OD.ORDER_ID
GROUP BY C.CUSTOMER_ID, C.CUSTOMER_NAME
ORDER BY CALCULATED_REVENUE DESC;

-- COUNT OF ORDERS PER CUSTOMER
SELECT C.CUSTOMER_ID, COUNT(C.CUSTOMER_ID) AS COUNT
FROM CUSTOMERS C
JOIN ORDERS O 
ON C.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID
ORDER BY COUNT DESC;


-- Top 10 products by revenue
SELECT P.PRODUCT_ID, P.PRODUCT_NAME,
SUM(OI.QUANTITY * OI.UNIT_PRICE) AS CALCULATED_REVENUE
-- DENSE_RANK() OVER() AS Rank_of_Product 
FROM PRODUCTS P
JOIN ORDER_ITEMS OI
ON P.PRODUCT_ID = OI.PRODUCT_ID
GROUP BY P.PRODUCT_ID, P.PRODUCT_NAME
ORDER BY CALCULATED_REVENUE DESC
LIMIT 10;
-- PRODUCT 36 HAS HIGHEST REVENUE
-- Revenue is fine, but which products are sold the most?
SELECT * FROM PRODUCTS;
SELECT * FROM ORDER_ITEMS; 
SELECT P.PRODUCT_ID, P.PRODUCT_NAME, SUM(OI.QUANTITY) AS Total_Sale 
FROM ORDER_ITEMS AS OI
JOIN PRODUCTS AS P
ON OI.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.PRODUCT_ID, P.PRODUCT_NAME
ORDER BY Total_Sale DESC;

-- Which category generates the highest revenue?
SELECT C.CATEGORY_ID,C.category_name, SUM(OI.QUANTITY*OI.UNIT_PRICE) AS CATEGORY_REVENUE
FROM CATEGORIES AS C
JOIN PRODUCTS AS P
ON C.category_id = P.category_id
JOIN ORDER_ITEMS AS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
GROUP BY C.CATEGORY_ID, C.category_name
ORDER BY CATEGORY_REVENUE DESC;

-- Which category is the MOST PROFITABLE?
SELECT C.CATEGORY_ID,C.category_name, 
SUM(OI.QUANTITY*(P.selling_price - P.cost_price)) AS PROFIT
FROM CATEGORIES AS C
JOIN PRODUCTS AS P
ON C.category_id = P.category_id
JOIN ORDER_ITEMS AS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
GROUP BY C.CATEGORY_ID, C.category_name
ORDER BY PROFIT DESC;


-- Which customers have never placed an order?
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,
		O.ORDER_ID
FROM CUSTOMERS C
LEFT JOIN ORDERS O
ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE ORDER_ID IS NULL;
SELECT * FROM PRODUCTS;
SELECT * FROM CUSTOMERS;

-- Find customers whose spending is above the average customer spending.
SELECT C.CUSTOMER_ID, C.CUSTOMER_NAME,
	SUM(O.TOTAL_AMOUNT) AS Customer_Spending
FROM CUSTOMERS C
JOIN ORDERS O 
ON C.customer_id = O.customer_id
-- WHERE Customer_Spending >
-- 	(SELECT AVG(TOTAL_AMOUNT) AS AVG_SPENDING FROM ORDERS) 
GROUP BY C.CUSTOMER_ID, C.CUSTOMER_NAME
HAVING Customer_Spending >
	(SELECT AVG(TOTAL_AMOUNT) AS AVG_SPENDING FROM ORDERS) 
ORDER BY Customer_Spending DESC;




SELECT AVG(TOTAL_AMOUNT) AS AVG_SPENDING FROM ORDERS;

