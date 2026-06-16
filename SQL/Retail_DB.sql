-- 1. Create Database
CREATE DATABASE Retail_GP;
USE Retail_GP;

-- 2. Create Dimension Tables
CREATE TABLE Calendar (
    date DATE PRIMARY KEY
);

CREATE TABLE Region (
    region_id INT PRIMARY KEY,
    sales_district VARCHAR(50),
    sales_region VARCHAR(50)
);

CREATE TABLE Stores (
    store_id INT PRIMARY KEY,
    region_id INT FOREIGN KEY REFERENCES Region(region_id),
    store_type VARCHAR(50),
    store_name VARCHAR(50),
    store_street_address VARCHAR(255),
    store_city VARCHAR(50),
    store_state VARCHAR(50),
    store_country VARCHAR(50),
    store_phone VARCHAR(20),
    first_opened_date DATE,
    last_remodel_date DATE,
    total_sqft INT,
    grocery_sqft INT
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_brand VARCHAR(100),
    product_name VARCHAR(255),
    product_sku BIGINT, 
    product_retail_price DECIMAL(10,2), -- دقة عالية للأسعار
    product_cost DECIMAL(10,2),
    product_weight DECIMAL(10,2),
    recyclable INT,
    low_fat INT
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_acct_num BIGINT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    customer_address VARCHAR(255),
    customer_city VARCHAR(50),
    customer_state_province VARCHAR(50),
    customer_postal_code VARCHAR(20),
    customer_country VARCHAR(50),
    birthdate DATE,
    marital_status CHAR(1),
    yearly_income VARCHAR(50),
    gender CHAR(1),
    total_children INT,
    num_children_at_home INT,
    education VARCHAR(50),
    acct_open_date DATE,
    member_card VARCHAR(50),
    occupation VARCHAR(50),
    homeowner CHAR(1)
);

-- 3. Create Facts Tables
CREATE TABLE Sales_2017 (
    transaction_date DATE FOREIGN KEY REFERENCES Calendar(date),
    stock_date DATE,
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

CREATE TABLE Sales_2018 (
    transaction_date DATE FOREIGN KEY REFERENCES Calendar(date),
    stock_date DATE,
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

CREATE TABLE Returns (
    return_date DATE FOREIGN KEY REFERENCES Calendar(date),
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

-- 4. Load data from CSV files
BULK INSERT Calendar
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Calendar.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Products
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Products.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Region
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Region.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Returns
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Returns.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Stores
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Stores.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
); 

BULK INSERT Sales_2017
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Sales 2017.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Sales_2018
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Sales 2018.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Customers 
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Customers.csv' 
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- Row count validation for all tables in the database
SELECT 'Products' AS TableName, COUNT(*) AS TotalRows FROM Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Sales_2017', COUNT(*) FROM Sales_2017
UNION ALL
SELECT 'Sales_2018', COUNT(*) FROM Sales_2018
UNION ALL
SELECT 'Calendar', COUNT(*) FROM Calendar
UNION ALL
SELECT 'Stores', COUNT(*) FROM Stores
UNION ALL 
SELECT 'Region', COUNT(*) FROM Region
UNION ALL
SELECT 'Returns', COUNT(*) FROM Returns;

-- 5. Answer Business Questions
/* 1) Sales & Profit 
Q1: Annual Performance & Growth -- Evaluate yearly trends and cumulative revenue
*/

WITH YearlyStats AS (
    SELECT 
        YEAR(CAST(c.date AS DATE)) AS Sales_Year,
        SUM(s.quantity * p.product_retail_price) AS Revenue,
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Profit
    FROM (SELECT transaction_date, product_id, quantity FROM Sales_2017 
          UNION ALL 
          SELECT transaction_date, product_id, quantity FROM Sales_2018) s
    JOIN Products p ON s.product_id = p.product_id
    JOIN Calendar c ON s.transaction_date = c.date
    GROUP BY YEAR(CAST(c.date AS DATE))
)
SELECT 
    Sales_Year,
    FORMAT(Revenue, 'C', 'en-US') AS Total_Revenue,
    FORMAT(SUM(Revenue) OVER(ORDER BY Sales_Year), 'C', 'en-US') AS Running_Total_Revenue,
    FORMAT(LAG(Revenue) OVER(ORDER BY Sales_Year), 'C', 'en-US') AS Last_Year_Revenue,
    FORMAT(Profit, 'C', 'en-US') AS Total_Profit
FROM YearlyStats;

/* 
Q2: Top 5 Profitable Brands -- identify which brands contribute most 
*/
SELECT * FROM (
    SELECT 
        p.product_brand,
        FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Brand_Profit,
        -- Window Function: Ranking brands by profit
        DENSE_RANK() OVER(ORDER BY SUM(s.quantity * (p.product_retail_price - p.product_cost)) DESC) AS Profit_Rank
    FROM (SELECT product_id, quantity FROM Sales_2017 
          UNION ALL 
          SELECT product_id, quantity FROM Sales_2018) s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY p.product_brand
) AS RankedBrands
WHERE Profit_Rank <= 5;

/* 
Q3: Store Performance & Efficiency Analysis -- evaluate each store's profitability and space utilization efficiency 
*/
SELECT 
    st.store_name,
    st.store_city,
    st.total_sqft,
    st.grocery_sqft,
    SUM(AllSales.quantity) AS Total_Items_Sold,
    FORMAT(SUM(AllSales.quantity * 1.0) / st.grocery_sqft, 'N2') AS Sales_Per_Grocery_SqFt,
    FORMAT((st.grocery_sqft * 1.0 / st.total_sqft) * 100, 'N0') + '%' AS Display_Area_Ratio
FROM (
    SELECT store_id, quantity FROM Sales_2017
    UNION ALL
    SELECT store_id, quantity FROM Sales_2018
) AS AllSales
JOIN Stores st ON AllSales.store_id = st.store_id
GROUP BY 
    st.store_name, 
    st.store_city, 
    st.total_sqft, 
    st.grocery_sqft
HAVING SUM(AllSales.quantity) > 20000 
ORDER BY Total_Items_Sold DESC;

/* 2) Customer Demographics
Q4: Sales Distribution by Gender -- tailor marketing campaigns based on customer gender
*/
SELECT 
    c.gender,
    SUM(s.quantity) AS Total_Items_Sold,
    FORMAT(SUM(s.quantity * 1.0) / SUM(SUM(s.quantity)) OVER() * 100, 'N2') + '%' AS Sales_Percentage
FROM (SELECT customer_id, quantity FROM Sales_2017 
      UNION ALL 
      SELECT customer_id, quantity FROM Sales_2018) s
JOIN Customers c ON s.customer_id = c.customer_id
GROUP BY c.gender;

/* 
Q5: Impact of Yearly Income on purchase Volume -- identify the target income bracket 
*/
WITH AllSales AS (
    SELECT customer_id, quantity FROM Sales_2017
    UNION ALL
    SELECT customer_id, quantity FROM Sales_2018
)
SELECT 
    c.yearly_income,
    SUM(s.quantity) AS Total_Items_Sold
FROM AllSales s
JOIN Customers c ON s.customer_id = c.customer_id
WHERE c.yearly_income IN ('$150K +', '$130K - $150K', '$10K - $30K', '$30K - $50K') 
GROUP BY c.yearly_income
ORDER BY Total_Items_Sold DESC;

/* 
Q6: Sales by Country -- support geographical expansion decisions
*/
WITH AllSales AS (
    SELECT customer_id, quantity FROM Sales_2017
    UNION ALL
    SELECT customer_id, quantity FROM Sales_2018
)
SELECT 
    c.customer_country,
    SUM(s.quantity) AS Total_Items_Sold
FROM AllSales s
JOIN Customers c ON s.customer_id = c.customer_id
GROUP BY c.customer_country
ORDER BY Total_Items_Sold DESC;

/* Product Performance & Returns
Q7: Top 10 Returned Products -- Identify quality issues and evaluate supplier performance
*/
SELECT * FROM (
    SELECT 
        p.product_name,
        SUM(r.quantity) AS Total_Returned_Quantity,
        RANK() OVER (ORDER BY SUM(r.quantity) DESC) AS Return_Rank
    FROM Returns r
    JOIN Products p ON r.product_id = p.product_id
    WHERE YEAR(CAST(r.return_date AS DATE)) = 1998
    GROUP BY p.product_name
) AS RankedReturns
WHERE Return_Rank <= 10;

/* Q8: Sales of Low Fat vs Regular Products -- Understand customer health trends and preferences
*/
WITH AllSales AS (
    SELECT product_id, quantity FROM Sales_2017
    UNION ALL
    SELECT product_id, quantity FROM Sales_2018
)
SELECT 
    CASE WHEN p.low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS Product_Type,
    SUM(s.quantity) AS Total_Items_Sold
FROM AllSales s
JOIN Products p ON s.product_id = p.product_id
GROUP BY p.low_fat;

-- SQL Views & Data Preparation
/*
Customer Data Preparation for Power BI
- Dropped 'customer_acct_num' as it provides no analytical value for business dashboards.
- Merged 'first_name' and 'last_name' into 'full_name' for better visualization.
- Standardized 'gender', 'marital_status', and 'homeowner' to Upper Case for consistent filtering.
- Applied TRIM() to all text fields to remove unnecessary whitespace.
- Handled NULL/Empty values using ISNULL() and NULLIF() for cleaner data integrity.
- Created 'current_age' using DATEDIFF() to enable demographic age-group analysis.
*/
CREATE VIEW vw_CleanCustomers AS
SELECT 
    customer_id,   
    TRIM(first_name) + ' ' + TRIM(last_name) AS full_name, 
    ISNULL(NULLIF(TRIM(customer_address), ''), 'Unknown') AS customer_address,
    TRIM(customer_city) AS customer_city,
    TRIM(customer_state_province) AS customer_state_province,
    TRIM(customer_postal_code) AS customer_postal_code,
    TRIM(customer_country) AS customer_country,
    CAST(birthdate AS DATE) AS birthdate,
    UPPER(ISNULL(NULLIF(marital_status, ''), 'U')) AS marital_status, 
    yearly_income,
    UPPER(gender) AS gender,
    total_children,
    num_children_at_home,
    TRIM(education) AS education,
    CAST(acct_open_date AS DATE) AS acct_open_date,
    TRIM(member_card) AS member_card,
    TRIM(occupation) AS occupation,
    UPPER(homeowner) AS homeowner,
    
    DATEDIFF(YEAR, CAST(birthdate AS DATE), GETDATE()) AS current_age
FROM Customers;

/* 
Product Data Preparation for Power BI
- Standardized product names and brands using TRIM() to ensure clean grouping in visuals.
- Applied CAST(DECIMAL) to prices and costs for precise financial calculations.
- Transformed 'low_fat' and 'recyclable' flags into descriptive text labels ('Low Fat' vs 'Regular') for user-friendly reporting.
- Calculated 'unit_profit' at the SQL level to optimize Power BI performance.
*/
CREATE VIEW vw_CleanProducts AS
SELECT 
    product_id,
    TRIM(product_brand) AS product_brand,
    TRIM(product_name) AS product_name,
    product_sku,
    CAST(product_retail_price AS DECIMAL(10,2)) AS retail_price,
    CAST(product_cost AS DECIMAL(10,2)) AS product_cost,
    product_weight,
    CASE WHEN recyclable = 1 THEN 'Recyclable' ELSE 'Non-Recyclable' END AS recyclable_status,
    CASE WHEN low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS fat_content,

    CAST((product_retail_price - product_cost) AS DECIMAL(10,2)) AS unit_profit
FROM Products;

/* 
Store & Region Data Preparation (Denormalization for Star Schema)
- Combined all columns from 'Stores' and 'Region' tables to create a comprehensive Dimension table.
- A LEFT JOIN was used to ensure all stores are included in the view even if they lack a matching region_id.
- Dropped 'region_id' from the final view to avoid redundancy after performing the LEFT JOIN.
- Formatted 'first_opened_date' and 'last_remodel_date' as DATE types for time-based store performance analysis.
- Calculated 'display_area_pct' to measure space efficiency across different store types.
*/
CREATE VIEW vw_CleanStores AS
SELECT 
    st.store_id,
    st.store_name,
    st.store_type,
    st.store_street_address,
    st.store_city,
    st.store_state,
    st.store_country,
    st.store_phone,
    r.sales_district,
    r.sales_region,
    CAST(st.first_opened_date AS DATE) AS first_opened_date,
    CAST(st.last_remodel_date AS DATE) AS last_remodel_date,
    st.total_sqft,
    st.grocery_sqft,

    CAST((st.grocery_sqft * 1.0 / st.total_sqft) * 100 AS DECIMAL(5,2)) AS display_area_pct
FROM Stores st
LEFT JOIN Region r ON st.region_id = r.region_id;

/* 
Calendar Dimension Table Preparation
- Standardized 'date' as 'date_key' to serve as the primary link for fact tables.
- Extracted time attributes (Year, Month, Quarter, Day Name) to enable granular time-series analysis.
- Used DATENAME() for readable labels (e.g., 'January', 'Monday') in dashboard slicers.
*/
CREATE VIEW vw_CleanCalendar AS
SELECT 
    CAST(date AS DATE) AS date_key,
    YEAR(CAST(date AS DATE)) AS year,
    MONTH(CAST(date AS DATE)) AS month_num,
    DATENAME(MONTH, CAST(date AS DATE)) AS month_name,
    DATEPART(QUARTER, CAST(date AS DATE)) AS quarter,
    DATENAME(WEEKDAY, CAST(date AS DATE)) AS day_name
FROM Calendar;

/* 
Returns Fact Table Preparation
- Formatted 'return_date' to DATE type to ensure a proper relationship with the Calendar table.
*/
CREATE VIEW vw_CleanReturns AS
SELECT 
    CAST(return_date AS DATE) AS return_date,
    product_id,
    store_id,
    quantity
FROM Returns;

/* 
Unified Sales Fact Table (2017-2018)
- Combined Sales_2017 and Sales_2018 using UNION ALL
- Casted all date fields to DATE type for consistent joining with the Calendar dimension
*/
CREATE VIEW vw_AllSalesFact AS
SELECT 
    CAST(transaction_date AS DATE) AS transaction_date,
    CAST(stock_date AS DATE) AS stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM Sales_2017
UNION ALL
SELECT 
    CAST(transaction_date AS DATE) AS transaction_date,
    CAST(stock_date AS DATE) AS stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM Sales_2018;