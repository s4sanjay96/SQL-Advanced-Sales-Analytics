/*
=============================================================
Module: Performance Analysis (Year-over-Year, Month-over-Month)
=============================================================
Problem: Analyze the performance of products and customers by comparing current values to previous periods.
Techniques: Window Functions (LAG, AVG OVER, PARTITION BY).
*/

USE DataWarehouseAnalytics;
GO

-- 1. Yearly Product Performance Analysis
-- Insight: Compare each product's current sales to its average sales and previous year's sales.
WITH YearlyProductSales AS (
    SELECT
        YEAR(S.order_date) AS OrderYear,
        P.product_name,
        SUM(S.sales_amount) AS CurrentSales
    FROM gold.fact_sales AS S
    LEFT JOIN gold.dim_products AS P
        ON S.product_key = P.product_key
    WHERE S.order_date IS NOT NULL
    GROUP BY YEAR(S.order_date), P.product_name
)
SELECT
    OrderYear,
    product_name,
    CurrentSales,
    AVG(CurrentSales) OVER (PARTITION BY product_name) AS AvgSales,
    CurrentSales - AVG(CurrentSales) OVER (PARTITION BY product_name) AS DiffFromAvg,
    CASE 
        WHEN CurrentSales - AVG(CurrentSales) OVER (PARTITION BY product_name) > 0 THEN 'Above Average'
        ELSE 'Below Average'
    END AS AvgStatus,
    LAG(CurrentSales) OVER (PARTITION BY product_name ORDER BY OrderYear) AS PreviousYearSales,
    CurrentSales - LAG(CurrentSales) OVER (PARTITION BY product_name ORDER BY OrderYear) AS YoYDifference,
    CASE 
        WHEN CurrentSales - LAG(CurrentSales) OVER (PARTITION BY product_name ORDER BY OrderYear) > 0 THEN 'Growth'
        WHEN CurrentSales - LAG(CurrentSales) OVER (PARTITION BY product_name ORDER BY OrderYear) < 0 THEN 'Decline'
        ELSE 'No Change'
    END AS YoYStatus
FROM YearlyProductSales
ORDER BY product_name, OrderYear;

-- 2. Customer Purchase Pattern Analysis (YoY)
-- Insight: Identify if individual customers are increasing their purchasing quantity over time.
WITH YearlyCustomerPurchase AS (
    SELECT
        YEAR(S.order_date) AS OrderYear,
        COALESCE(C.first_name, '') + ' ' + COALESCE(C.last_name, '') AS CustomerName,
        SUM(S.quantity) AS CurrentQuantity
    FROM gold.fact_sales AS S
    LEFT JOIN gold.dim_customers AS C
        ON S.customer_key = C.customer_key
    WHERE S.order_date IS NOT NULL
    GROUP BY YEAR(S.order_date), COALESCE(C.first_name, '') + ' ' + COALESCE(C.last_name, '')
)
SELECT
    OrderYear,
    CustomerName,
    CurrentQuantity,
    AVG(CurrentQuantity) OVER (PARTITION BY CustomerName) AS AvgQty,
    CurrentQuantity - AVG(CurrentQuantity) OVER (PARTITION BY CustomerName) AS DiffFromAvg,
    LAG(CurrentQuantity) OVER (PARTITION BY CustomerName ORDER BY OrderYear) AS PrevYearQty,
    CurrentQuantity - LAG(CurrentQuantity) OVER (PARTITION BY CustomerName ORDER BY OrderYear) AS YoYDiff
FROM YearlyCustomerPurchase
ORDER BY CustomerName, OrderYear;