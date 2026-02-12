/*
=============================================================
Module: Part-to-Whole Analysis (Pareto Principle)
=============================================================
Problem: Identify which categories, products, or customers contribute the most to total revenue.
Techniques: Window Functions (SUM OVER), Casting, Cumulative Distribution.
*/

USE DataWarehouseAnalytics;
GO

-- 1. Sales Contribution by Category
-- Insight: Identify which product categories drive the majority of sales.
WITH CategoryContribution AS (
    SELECT
        P.category,
        SUM(S.sales_amount) AS TotalSales
    FROM gold.fact_sales AS S
    LEFT JOIN gold.dim_products AS P
        ON S.product_key = P.product_key
    GROUP BY P.category
)
SELECT
    category,
    TotalSales,
    SUM(TotalSales) OVER () AS OverallSales,
    CONCAT(ROUND((CAST(TotalSales AS FLOAT) / SUM(TotalSales) OVER ()) * 100, 2), '%') AS SalesPercentage
FROM CategoryContribution
ORDER BY TotalSales DESC;

-- 2. Pareto Analysis: Top 80% Revenue Products
-- Insight: Determine which products constitute the top 80% of revenue (Vital Few vs. Trivial Many).
WITH ProductSales AS (
    SELECT
        P.product_name,
        SUM(S.sales_amount) AS TotalSales
    FROM gold.fact_sales AS S
    LEFT JOIN gold.dim_products AS P
        ON S.product_key = P.product_key
    WHERE S.order_date IS NOT NULL
    GROUP BY P.product_name
),
ProductContribution AS (
    SELECT
        product_name,
        TotalSales,
        SUM(TotalSales) OVER () AS OverallSales,
        CAST(TotalSales AS FLOAT) / SUM(TotalSales) OVER () AS RevenueShare,
        SUM(TotalSales) OVER (ORDER BY TotalSales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
        / SUM(TotalSales) OVER () AS CumulativeShare
    FROM ProductSales
)
SELECT
    product_name,
    TotalSales,
    ROUND(RevenueShare * 100, 2) AS SharePct,
    ROUND(CumulativeShare * 100, 2) AS CumulativePct,
    CASE 
        WHEN CumulativeShare <= 0.80 THEN 'Top 80% (Key Products)'
        ELSE 'Bottom 20% (Long Tail)'
    END AS ParetoSegment
FROM ProductContribution
ORDER BY TotalSales DESC;