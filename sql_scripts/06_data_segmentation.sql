/*
=============================================================
Module: Data Segmentation
=============================================================
Problem: Group data into meaningful segments for targeted analysis.
Techniques: CASE Statements, CTEs, Date Diff functions.
*/

USE DataWarehouseAnalytics;
GO

-- 1. Product Cost Segmentation
-- Insight: Count products in specific cost ranges to understand inventory price distribution.
WITH ProductSegmentation AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Low Cost (<100)'
            WHEN cost BETWEEN 100 AND 500 THEN 'Mid Cost (100-500)'
            WHEN cost BETWEEN 500 AND 1000 THEN 'High Cost (500-1000)'
            ELSE 'Premium (>1000)'
        END AS CostRange
    FROM gold.dim_products
)
SELECT
    CostRange,
    COUNT(product_key) AS ProductCount
FROM ProductSegmentation
GROUP BY CostRange
ORDER BY ProductCount DESC;

-- 2. Customer Segmentation (RFM-Style)
-- Insight: Segment customers into VIP, Regular, or New based on spending and tenure.
WITH CustomerSpending AS (
    SELECT
        C.customer_key,
        SUM(S.sales_amount) AS TotalSpend,
        DATEDIFF(MONTH, MIN(S.order_date), MAX(S.order_date)) AS LifespanMonths
    FROM gold.fact_sales AS S
    LEFT JOIN gold.dim_customers AS C
        ON C.customer_key = S.customer_key
    GROUP BY C.customer_key
)
SELECT
    CustomerSegment,
    COUNT(customer_key) AS CustomerCount
FROM (
    SELECT
        customer_key,
        CASE 
            WHEN LifespanMonths >= 12 AND TotalSpend > 5000 THEN 'VIP'
            WHEN LifespanMonths >= 12 AND TotalSpend <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS CustomerSegment
    FROM CustomerSpending
) t
GROUP BY CustomerSegment
ORDER BY CustomerCount DESC;