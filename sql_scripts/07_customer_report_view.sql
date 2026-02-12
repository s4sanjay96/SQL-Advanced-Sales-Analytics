/*
=============================================================
Module: Customer Report View
=============================================================
Purpose: Create a consolidated view for customer metrics (demographics, segmentation, financial).
Use Case: This view is used for Power BI dashboards or high-level business reporting.
*/

USE DataWarehouseAnalytics;
GO

CREATE VIEW gold.report_customers AS
WITH BaseQuery AS (
    SELECT
        F.order_number,
        F.product_key,
        F.order_date,
        F.sales_amount,
        F.quantity,
        C.customer_key,
        C.customer_number,
        COALESCE(C.first_name, '') + ' ' + COALESCE(C.last_name, '') AS CustomerName,
        DATEDIFF(YEAR, C.birthdate, GETDATE()) AS Age
    FROM gold.fact_sales AS F
    LEFT JOIN gold.dim_customers AS C
        ON C.customer_key = F.customer_key
    WHERE order_date IS NOT NULL
),
CustomerAggregation AS (
    SELECT
        customer_key,
        customer_number,
        CustomerName,
        Age,
        COUNT(DISTINCT order_number) AS TotalOrders,
        SUM(sales_amount) AS TotalSales,
        SUM(quantity) AS TotalQuantity,
        COUNT(DISTINCT product_key) AS TotalProducts,
        MAX(order_date) AS LastOrderDate,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS Lifespan
    FROM BaseQuery
    GROUP BY customer_key, customer_number, CustomerName, Age
)
SELECT
    customer_key,
    customer_number,
    CustomerName,
    Age,
    CASE 
        WHEN Age < 20 THEN 'Under 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and Above'
    END AS AgeGroup,
    CASE 
        WHEN Lifespan >= 12 AND TotalSales > 5000 THEN 'VIP'
        WHEN Lifespan >= 12 AND TotalSales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS CustomerSegment,
    DATEDIFF(MONTH, LastOrderDate, GETDATE()) AS Recency,
    TotalOrders,
    TotalSales,
    TotalQuantity,
    TotalProducts,
    Lifespan,
    -- Computed Columns
    CASE WHEN TotalOrders = 0 THEN 0 ELSE TotalSales / TotalOrders END AS AvgOrderValue,
    CASE WHEN Lifespan = 0 THEN TotalSales ELSE TotalSales / Lifespan END AS AvgMonthlySpend
FROM CustomerAggregation;
GO

-- Verification
SELECT TOP 10 * FROM gold.report_customers ORDER BY TotalSales DESC;