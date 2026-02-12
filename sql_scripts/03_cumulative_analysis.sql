/*
=============================================================
Module: Cumulative Analysis
=============================================================
Problem: Analyze business growth and price stability over time.
Techniques: Window Functions (SUM OVER, AVG OVER) for running totals and moving averages.
*/

USE DataWarehouseAnalytics;
GO

-- 1. Running Total of Sales (Cumulative Growth)
-- Insight: Shows the accumulated sales over time to track overall business growth.
SELECT
    OrderMonth,
    TotalSales,
    SUM(TotalSales) OVER (ORDER BY OrderMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalSales
FROM (
    SELECT
        DATETRUNC(month, order_date) AS OrderMonth,
        SUM(sales_amount) AS TotalSales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
) t;

-- 2. Moving Average of Prices (Price Stability)
-- Insight: Smooths out fluctuations to identify the underlying price trend over time.
SELECT
    OrderYear,
    TotalSales,
    AveragePrice,
    AVG(AveragePrice) OVER (ORDER BY OrderYear ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS MovingAveragePrice
FROM (
    SELECT
        DATETRUNC(year, order_date) AS OrderYear,
        SUM(sales_amount) AS TotalSales,
        AVG(price) AS AveragePrice
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(year, order_date)
) t;