/*
=============================================================
Module: Change Over Time Analysis
=============================================================
Problem: Analyze how sales performance evolves over time to identify trends and seasonality.
Techniques: Aggregation by Date Dimension (Year, Month).
*/

USE DataWarehouseAnalytics;
GO

-- 1. Analyze Sales Performance Over Time (Yearly)
-- Insight: Helps in understanding the long-term growth or decline of the business.
SELECT
    YEAR(order_date) AS OrderYear,
    SUM(sales_amount) AS TotalSales,
    COUNT(customer_key) AS TotalCustomers,
    SUM(quantity) AS TotalQuantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- 2. Analyze Sales Performance Over Time (Monthly)
-- Insight: Identifies seasonal patterns (e.g., higher sales in specific months).
SELECT
    FORMAT(order_date, 'MMM') AS OrderMonth,
    SUM(sales_amount) AS TotalSales,
    COUNT(customer_key) AS TotalCustomers,
    SUM(quantity) AS TotalQuantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'MMM')
ORDER BY FORMAT(order_date, 'MMM');

-- 3. Detailed Chronological Analysis (Year-Month)
-- Insight: Provides a granular view of performance on a monthly basis across all years.
SELECT
    YEAR(order_date) AS OrdersYear,
    MONTH(order_date) AS OrderMonth,
    SUM(sales_amount) AS TotalSales,
    COUNT(customer_key) AS TotalCustomers,
    SUM(quantity) AS TotalQuantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);