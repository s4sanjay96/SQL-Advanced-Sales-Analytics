/*
=============================================================
Module: Product Report View
=============================================================
Purpose: Create a consolidated view for product metrics (performance, profit, inventory).
Use Case: This view identifies high-performing products and those needing attention.
*/

USE DataWarehouseAnalytics;
GO

CREATE VIEW gold.report_products AS
WITH ProductsBaseQuery AS (
    SELECT
        F.order_number,
        F.order_date,
        F.sales_amount,
        F.quantity,
        F.customer_key,
        P.product_key,
        P.product_name,
        P.category,
        P.subcategory,
        P.cost
    FROM gold.fact_sales AS F
    LEFT JOIN gold.dim_products AS P
        ON F.product_key = P.product_key
    WHERE F.order_date IS NOT NULL
),
ProductAggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS Lifespan,
        MAX(order_date) AS LastSaleDate,
        COUNT(DISTINCT customer_key) AS TotalCustomers,
        COUNT(DISTINCT order_number) AS TotalOrders,
        SUM(sales_amount) AS TotalSales,
        SUM(quantity) AS TotalQuantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS AvgSellingPrice
    FROM ProductsBaseQuery
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, LastSaleDate, GETDATE()) AS RecencyInMonths,
    CASE 
        WHEN TotalSales > 50000 THEN 'High-Performer'
        WHEN TotalSales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS ProductSegment,
    Lifespan,
    TotalOrders,
    TotalSales,
    TotalQuantity,
    TotalCustomers,
    AvgSellingPrice,
    -- Computed Columns
    CASE WHEN TotalOrders = 0 THEN 0 ELSE TotalSales / TotalOrders END AS AvgOrderRevenue,
    CASE WHEN Lifespan = 0 THEN TotalSales ELSE TotalSales / Lifespan END AS AvgMonthlyRevenue
FROM ProductAggregations;
GO

-- Verification
SELECT TOP 10 * FROM gold.report_products ORDER BY TotalSales DESC;