
USE Retail_GP
GO

SELECT current_age FROM vw_CleanCustomers

SELECT MAX(current_age) AS AMXAGE FROM vw_CleanCustomers
SELECT MIN(current_age) AS MINAGE FROM vw_CleanCustomers

ALTER VIEW vw_CleanCustomers 
AS

SELECT 
    customer_id,

    LTRIM(RTRIM(first_name)) + ' ' + LTRIM(RTRIM(last_name)) AS full_name,

    ISNULL(NULLIF(LTRIM(RTRIM(customer_address)), ''), 'Unknown') AS customer_address,

    LTRIM(RTRIM(customer_city)) AS customer_city,

    LTRIM(RTRIM(customer_state_province)) AS customer_state_province,

    LTRIM(RTRIM(customer_postal_code)) AS customer_postal_code,

    LTRIM(RTRIM(customer_country)) AS customer_country,

    CAST(birthdate AS DATE) AS birthdate,

    UPPER(ISNULL(NULLIF(marital_status, ''), 'U')) AS marital_status,

    yearly_income,

    UPPER(gender) AS gender,

    total_children,

    num_children_at_home,

    LTRIM(RTRIM(education)) AS education,

    CAST(acct_open_date AS DATE) AS acct_open_date,

    LTRIM(RTRIM(member_card)) AS member_card,

    LTRIM(RTRIM(occupation)) AS occupation,

    UPPER(homeowner) AS homeowner,

    DATEDIFF(YEAR, birthdate, GETDATE()) AS current_age,

    CASE
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 40 AND 55 THEN 'Middle Age'
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 56 AND 70 THEN 'Senior Adult'
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 71 AND 90 THEN 'Old'
        ELSE 'Very Old'
    END AS age_group

FROM dbo.Customers


SELECT 
    product_id,
    retail_price,
    product_cost,
    unit_profit,

    (retail_price - product_cost) AS calculated_profit

FROM vw_CleanProducts

ALTER VIEW [dbo].[vw_AllSalesFact] 
AS

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

FROM Sales_2018


ALTER VIEW vw_CleanCustomers AS
SELECT 
    customer_id,

    LTRIM(RTRIM(first_name)) + ' ' + LTRIM(RTRIM(last_name)) AS full_name,

    ISNULL(NULLIF(LTRIM(RTRIM(customer_address)), ''), 'Unknown') AS customer_address,

    LTRIM(RTRIM(customer_city)) AS customer_city,
    LTRIM(RTRIM(customer_state_province)) AS customer_state_province,
    LTRIM(RTRIM(customer_postal_code)) AS customer_postal_code,
    LTRIM(RTRIM(customer_country)) AS customer_country,

    CAST(birthdate AS DATE) AS birthdate,

    UPPER(ISNULL(NULLIF(marital_status, ''), 'U')) AS marital_status,

    yearly_income,
    UPPER(gender) AS gender,

    total_children,
    num_children_at_home,

    LTRIM(RTRIM(education)) AS education,

    CAST(acct_open_date AS DATE) AS acct_open_date,

    LTRIM(RTRIM(member_card)) AS member_card,
    LTRIM(RTRIM(occupation)) AS occupation,

    UPPER(homeowner) AS homeowner,

    DATEDIFF(YEAR, birthdate, GETDATE()) AS current_age,

    -- ?? ??????: Age Group
    CASE 
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 40 AND 55 THEN 'Middle Age'
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 56 AND 70 THEN 'Senior Adult'
        WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 71 AND 90 THEN 'Old'
        ELSE 'Very Old'
    END AS age_group,

    -- ?? Income Midpoint (??? ????)
    CASE 
        WHEN yearly_income = '$10K - $30K' THEN 20000
        WHEN yearly_income = '$30K - $50K' THEN 40000
        WHEN yearly_income = '$50K - $70K' THEN 60000
        WHEN yearly_income = '$70K - $90K' THEN 80000
        WHEN yearly_income = '$90K - $110K' THEN 100000
        WHEN yearly_income = '$110K - $130K' THEN 120000
        WHEN yearly_income = '$130K - $150K' THEN 140000
        WHEN yearly_income = '$150K +' THEN 180000
        ELSE NULL
    END AS income_midpoint

FROM dbo.Customers;
Select yearly_income from vw_CleanCustomers



ALTER VIEW vw_CleanProducts AS
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


-- POWER BI MEASURES vs DATABASE TOTALS

-- 1) m_sales
SELECT 
    COUNT(*) AS [Total Sales], 
    SUM(s.quantity) AS [Total Quantity],
    FORMAT(SUM(s.quantity * p.retail_price), 'C', 'en-US') AS [Total Revenue],
    FORMAT(SUM(s.quantity * (p.retail_price - p.product_cost)), 'C', 'en-US') AS [Total Profit],
    FORMAT(SUM(s.quantity * (p.retail_price - p.product_cost)) / SUM(s.quantity * p.retail_price), 'P') AS [Profit Margin %],
    FORMAT(CAST((SELECT SUM(quantity) FROM vw_CleanReturns) AS FLOAT) / SUM(s.quantity), 'P') AS [Return Rate],
    FORMAT(SUM(s.quantity * p.retail_price) / COUNT(*), 'C', 'en-US') AS [Avg Order Value]
FROM vw_AllSalesFact s
JOIN vw_CleanProducts p ON s.product_id = p.product_id;

-- YOY Revenue Change & MOM Revenue Change
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(transaction_date) AS SaleYear,
        MONTH(transaction_date) AS SaleMonth,
        SUM(s.quantity * p.retail_price) AS Revenue
    FROM vw_AllSalesFact s
    JOIN vw_CleanProducts p ON s.product_id = p.product_id
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
),
GrowthAnalysis AS (
    SELECT *,
        LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth) AS PrevMonthRevenue,
        LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth) AS PrevYearRevenue
    FROM MonthlyRevenue
)
SELECT 
    SaleYear,
    SaleMonth,
    FORMAT(Revenue, 'C', 'en-US') AS Monthly_Revenue,
    FORMAT((Revenue - PrevMonthRevenue) / NULLIF(PrevMonthRevenue, 0), 'P') AS [MoM Revenue Change],
    FORMAT((Revenue - PrevYearRevenue) / NULLIF(PrevYearRevenue, 0), 'P') AS [YoY Revenue Change]
FROM GrowthAnalysis
ORDER BY SaleYear DESC, SaleMonth DESC;

-- 2) m_customer
SELECT 
    COUNT(customer_id) AS [Total Customer],
    SUM(CASE WHEN marital_status = 'M' THEN 1 ELSE 0 END) AS [Married Customers],
    CAST(SUM(CASE WHEN homeowner = 'Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(10,4)) AS [Homeowners %],
    AVG(income_midpoint) AS [Avg Yearly_Income],
    -- Average Customer Value
    (SELECT SUM(s.quantity * p.retail_price) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(customer_id) AS [Avg Customer Value]
FROM vw_CleanCustomers;

-- 3) m_products
SELECT 
    COUNT(product_id) AS [Total Product],
    COUNT(DISTINCT product_brand) AS [Total Brand],
    -- Recyclable vs Non
    SUM(CASE WHEN recyclable_status = 'Recyclable' THEN 1 ELSE 0 END) AS [Recyclable Products],
    SUM(CASE WHEN recyclable_status = 'Non-Recyclable' THEN 1 ELSE 0 END) AS [Non-Recyclable Products],
    -- Averages
    AVG(retail_price) AS [Avg Product Value],
    AVG(product_cost) AS [Avg Product Cost],
    AVG(unit_profit) AS [Avg Unit Profit]
FROM vw_CleanProducts;

-- 4) m_store
SELECT 
    COUNT(store_id) AS [Total Store],
    COUNT(DISTINCT store_type) AS [Total Store Types],
    COUNT(DISTINCT store_city) AS [Total Cities],
    -- Averages
    AVG(total_sqft) AS [Avg Store Size],
    AVG(grocery_sqft) AS [Avg Grocery], 
    -- Revenue Per Store 
    (SELECT SUM(s.quantity * p.retail_price) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(store_id) AS [Average Store Revenue],
    -- Profit Per Store 
    (SELECT SUM(s.quantity * (p.retail_price - p.product_cost)) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(store_id) AS [Average Store Profit]
FROM vw_CleanStores;


/* CUSTOMER VIEW ENHANCEMENT
Added Features:
-- 1) RFM Segmentation: To group customers based on buying behavior (Recency, Frequency, Monetary)
-- 2) Age Grouping: To analyze customer demographics (Middle Age, Senior, etc.)
-- 3) Income Midpoint: Converted text income ranges to numeric values for Power BI aggregations
*/
ALTER VIEW vw_CleanCustomers AS
WITH AllSales AS (
    -- to calculate RFM
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2017
    UNION ALL
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2018
),
RFM_Base AS (
    SELECT 
        s.customer_id,
        DATEDIFF(DAY, MAX(s.transaction_date), (SELECT MAX(transaction_date) FROM AllSales)) AS Recency,
        COUNT(DISTINCT s.transaction_date) AS Frequency,
        SUM(s.quantity * p.product_retail_price) AS Monetary
    FROM AllSales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY s.customer_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM_Base
),
RFM_Final AS (
    SELECT 
        customer_id,
        Recency,
        Frequency,
        Monetary,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
        CASE 
            WHEN (R_Score + F_Score + M_Score) >= 12 THEN 'VIP / Champions'
            WHEN (R_Score + F_Score + M_Score) BETWEEN 9 AND 11 THEN 'Loyal Customers'
            WHEN (R_Score + F_Score + M_Score) BETWEEN 6 AND 8 THEN 'Potential Loyalists / Promising'
            ELSE 'About to Sleep / Lost'
        END AS Customer_Segment
    FROM RFM_Scores
)
SELECT 
    c.customer_id,   
    TRIM(c.first_name) + ' ' + TRIM(c.last_name) AS full_name, 
    ISNULL(NULLIF(TRIM(c.customer_address), ''), 'Unknown') AS customer_address,
    TRIM(c.customer_city) AS customer_city,
    TRIM(c.customer_state_province) AS customer_state_province,
    TRIM(CAST(c.customer_postal_code AS VARCHAR(20))) AS customer_postal_code,
    TRIM(c.customer_country) AS customer_country,
    CAST(c.birthdate AS DATE) AS birthdate,
    -- Current Age
    DATEDIFF(YEAR, CAST(c.birthdate AS DATE), GETDATE()) AS current_age,
    -- Age Groups
    CASE 
        WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 40 AND 55 THEN 'Middle Age'
        WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 56 AND 70 THEN 'Senior Adult'
        WHEN DATEDIFF(YEAR, c.birthdate, GETDATE()) BETWEEN 71 AND 90 THEN 'Old'
        ELSE 'Very Old'
    END AS age_group,

    UPPER(ISNULL(NULLIF(c.marital_status, ''), 'U')) AS marital_status, 
    c.yearly_income,
    
    -- Income Midpoint
    CASE 
        WHEN c.yearly_income = '$10K - $30K' THEN 20000
        WHEN c.yearly_income = '$30K - $50K' THEN 40000
        WHEN c.yearly_income = '$50K - $70K' THEN 60000
        WHEN c.yearly_income = '$70K - $90K' THEN 80000
        WHEN c.yearly_income = '$90K - $110K' THEN 100000
        WHEN c.yearly_income = '$110K - $130K' THEN 120000
        WHEN c.yearly_income = '$130K - $150K' THEN 140000
        WHEN c.yearly_income = '$150K +' THEN 180000
        ELSE NULL
    END AS income_midpoint,
    
    UPPER(c.gender) AS gender,
    c.total_children,
    c.num_children_at_home,
    TRIM(c.education) AS education,
    CAST(c.acct_open_date AS DATE) AS acct_open_date,
    TRIM(c.member_card) AS member_card,
    TRIM(c.occupation) AS occupation,
    UPPER(c.homeowner) AS homeowner,
    -- RFM columns
    ISNULL(r.Recency, 0) AS Recency,
    ISNULL(r.Frequency, 0) AS Frequency,
    ISNULL(r.Monetary, 0) AS Monetary,
    ISNULL(r.RFM_Cell, '111') AS RFM_Cell,
    ISNULL(r.Customer_Segment, 'About to Sleep / Lost') AS Customer_Segment
FROM Customers c
LEFT JOIN RFM_Final r ON c.customer_id = r.customer_id;


/* CUSTOMER VIEW ENHANCEMENT
Added Features:
-- 1) RFM Segmentation: To group customers based on buying behavior (Recency, Frequency, Monetary)
-- 2) Age Grouping: To analyze customer demographics (Middle Age, Senior, etc.)
-- 3) Income Midpoint: Converted text income ranges to numeric values for Power BI aggregations
*/
ALTER VIEW vw_CleanCustomers AS
WITH AllSales AS (
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2017
    UNION ALL
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2018
),
RFM_Base AS (
    SELECT 
        s.customer_id,
        DATEDIFF(DAY, MAX(s.transaction_date), (SELECT MAX(transaction_date) FROM AllSales)) AS Recency,
        COUNT(DISTINCT s.transaction_date) AS Frequency,
        SUM(s.quantity * p.product_retail_price) AS Monetary
    FROM AllSales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY s.customer_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM_Base
),
RFM_Final AS (
    SELECT 
        customer_id,
        Recency,
        Frequency,
        Monetary,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'VIP'
            WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal'
            WHEN R_Score >= 4 AND F_Score < 3 THEN 'New'
            WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
            ELSE 'Lost'
        END AS Customer_Segment
    FROM RFM_Scores
)
SELECT 
    c.customer_id,   

    TRIM(c.first_name) + ' ' + TRIM(c.last_name) AS full_name, 

    ISNULL(NULLIF(TRIM(c.customer_address), ''), 'Unknown') AS customer_address,

    TRIM(c.customer_city) AS customer_city,
    TRIM(c.customer_state_province) AS customer_state_province,

    TRIM(CAST(c.customer_postal_code AS VARCHAR(20))) AS customer_postal_code,

    TRIM(c.customer_country) AS customer_country,

    CAST(c.birthdate AS DATE) AS birthdate,

    DATEDIFF(YEAR, CAST(c.birthdate AS DATE), (SELECT MAX(transaction_date) FROM AllSales)) AS current_age,

    -- Age Group
    CASE 
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) < 35 THEN 'Young Adult'
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) BETWEEN 35 AND 50 THEN 'Middle Age'
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) BETWEEN 51 AND 65 THEN 'Senior Adult'
        ELSE 'Old'
    END AS age_group,

    UPPER(ISNULL(NULLIF(c.marital_status, ''), 'U')) AS marital_status, 

    c.yearly_income,

    -- Income Midpoint
    CASE 
        WHEN c.yearly_income = '$10K - $30K' THEN 20000
        WHEN c.yearly_income = '$30K - $50K' THEN 40000
        WHEN c.yearly_income = '$50K - $70K' THEN 60000
        WHEN c.yearly_income = '$70K - $90K' THEN 80000
        WHEN c.yearly_income = '$90K - $110K' THEN 100000
        WHEN c.yearly_income = '$110K - $130K' THEN 120000
        WHEN c.yearly_income = '$130K - $150K' THEN 140000
        WHEN c.yearly_income = '$150K +' THEN 180000
        ELSE NULL
    END AS income_midpoint,
    
    UPPER(c.gender) AS gender,
    c.total_children,
    c.num_children_at_home,
    TRIM(c.education) AS education,
    CAST(c.acct_open_date AS DATE) AS acct_open_date,
    TRIM(c.member_card) AS member_card,
    TRIM(c.occupation) AS occupation,
    UPPER(c.homeowner) AS homeowner,

    -- RFM columns
    ISNULL(r.Recency, 0) AS Recency,
    ISNULL(r.Frequency, 0) AS Frequency,
    ISNULL(r.Monetary, 0) AS Monetary,
    ISNULL(r.RFM_Cell, '111') AS RFM_Cell,
    ISNULL(r.Customer_Segment, 'Lost / Hibernating') AS Customer_Segment

FROM Customers c
LEFT JOIN RFM_Final r 
    ON c.customer_id = r.customer_id;

