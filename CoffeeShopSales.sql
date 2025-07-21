SELECT *
FROM Coffee_Shop_Sales;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN transaction_qty INT NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN store_id INT NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN store_location VARCHAR(50) NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN product_id INT NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN product_category VARCHAR(50) NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN product_type VARCHAR(50) NOT NULL;

ALTER TABLE Coffee_Shop_Sales
ALTER COLUMN product_detail VARCHAR(50) NOT NULL;

-- Which product generate the most revenue? --

WITH Category_Revenue AS (
SELECT product_category, ROUND(SUM(transaction_qty * unit_price), 2) AS Total_Revenue
FROM Coffee_Shop_Sales
GROUP BY product_category
),
RevenueWithPercentage AS (
    SELECT 
        product_category,
        ROUND(Total_Revenue, 2) AS Product_Revenue,
        ROUND(100.0 * Total_Revenue / SUM(Total_Revenue) OVER (), 2) AS Revenue_Percentage
    FROM 
        Category_Revenue
)
SELECT 
    product_category,
    product_revenue,
    revenue_percentage
FROM 
    RevenueWithPercentage
ORDER BY Product_Revenue DESC, Revenue_Percentage DESC;

-- What time of day the store performs best? --

 SELECT transaction_time, COUNT(*) AS Total_Revenue,
	CASE	
		WHEN transaction_time BETWEEN '00:00:00'  AND '11:59:59' THEN 'Morning'
		WHEN transaction_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
		WHEN transaction_time BETWEEN '18:00:00' AND '20:59:59' THEN 'Evening'
		ELSE 'Night'
	END AS Time_of_Day
 FROM Coffee_Shop_Sales
 GROUP BY transaction_time
 ORDER BY transaction_time, Total_Revenue;

 ALTER TABLE Coffee_Shop_Sales 
 ADD time_of_day VARCHAR(20);

UPDATE Coffee_Shop_Sales
SET time_of_day = CASE	
		WHEN transaction_time BETWEEN '00:00:00'  AND '11:59:59' THEN 'Morning'
		WHEN transaction_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
		WHEN transaction_time BETWEEN '18:00:00' AND '20:59:59' THEN 'Evening'
		ELSE 'Night'
	END;

WITH TimeOfDayStats AS (
    SELECT 
        time_of_day,
        COUNT(*) AS total_transactions
    FROM 
        Coffee_Shop_Sales
    GROUP BY 
        time_of_day
),
WithPercentages AS (
    SELECT 
        time_of_day,
        total_transactions,
        ROUND(100.0 * total_transactions / SUM(total_transactions) OVER (), 2) AS transaction_percentage
    FROM 
        TimeOfDayStats
)
SELECT 
    time_of_day,
    total_transactions AS total_revenue,
    transaction_percentage
FROM 
    WithPercentages
ORDER BY 
    total_transactions DESC;

-- Calculate Sales trends across products category and time intervals --

WITH ProductTimeRevenue AS (
    SELECT 
        product_category,
        time_of_day,
        SUM(transaction_qty * unit_price) AS total_revenue,
        SUM(transaction_qty) AS total_quantity
    FROM 
        Coffee_Shop_Sales
    GROUP BY 
        product_category, time_of_day
),
RankedTrends AS (
    SELECT 
        product_category,
        time_of_day,
        ROUND(total_revenue, 2) AS total_revenue,
        total_quantity,
        RANK() OVER (PARTITION BY time_of_day ORDER BY total_revenue DESC) AS rank_in_time
    FROM 
        ProductTimeRevenue
)
SELECT 
    product_category,
    time_of_day,
    total_revenue,
    total_quantity,
    rank_in_time
FROM 
    RankedTrends
ORDER BY 
    time_of_day DESC,
    rank_in_time;

-- Calculate High performing, Mid performing and Low performing products --

WITH ProductPerformance AS (
    SELECT 
        product_category,
        SUM(transaction_qty * unit_price) AS total_revenue,
        SUM(transaction_qty) AS total_quantity
    FROM 
        Coffee_Shop_Sales
    GROUP BY 
        product_category
),
RankedPerformance AS (
    SELECT 
        product_category,
        ROUND(total_revenue, 2) AS total_revenue,
        total_quantity,
        RANK() OVER (ORDER BY total_revenue DESC) AS high_revenue_rank,
        RANK() OVER (ORDER BY total_revenue ASC) AS low_revenue_rank
    FROM 
        ProductPerformance
)
SELECT 
    product_category,
    total_revenue,
    total_quantity,
    CASE 
        WHEN high_revenue_rank <= 3 THEN 'High Performing'
        WHEN low_revenue_rank <= 3 THEN 'Low Performing'
        ELSE 'Mid Performing'
    END AS performance_category
FROM 
    RankedPerformance
ORDER BY 
    total_revenue DESC;

-- Calculate Revenue by Month --

SELECT 
    FORMAT(transaction_date, 'yyyy-MM') AS month,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_revenue
FROM 
    Coffee_Shop_Sales
GROUP BY 
    FORMAT(transaction_date, 'yyyy-MM')
ORDER BY 
    total_revenue DESC;

-- Calculate the Total Revenue and Quantity Sold by 30 minutes time intervals --

SELECT 
    CAST(
        DATEADD(MINUTE, DATEDIFF(MINUTE, 0, transaction_time) / 30 * 30, 0)
        AS TIME(0) 
    ) AS interval_start, 
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_revenue,
    COUNT(*) AS total_transactions
FROM 
    Coffee_Shop_Sales
GROUP BY 
    CAST(
        DATEADD(MINUTE, DATEDIFF(MINUTE, 0, transaction_time) / 30 * 30, 0)
        AS TIME(0)
    )
ORDER BY 
    interval_start;

-- Calculate Total Quantity sold by product type or product detail --

WITH Product_Type_Revenue AS (
SELECT product_type, product_detail, ROUND(SUM(transaction_qty), 2) AS Quantity_Sold
FROM Coffee_Shop_Sales
GROUP BY product_type, product_detail
),
RevenueWithPercentage AS (
    SELECT 
        product_type, product_detail,
        ROUND(Quantity_Sold, 2) AS Quantity_Sold,
        ROUND(100.0 * Quantity_Sold / SUM(Quantity_Sold) OVER (), 2) AS Quantity_Percentage
    FROM 
        Product_Type_Revenue
)
SELECT 
    product_type,
	product_detail,
    quantity_sold,
    quantity_percentage
FROM 
    RevenueWithPercentage
ORDER BY Quantity_Sold DESC, Quantity_Percentage DESC;

-- Calculate the Revenue by Store location --

WITH Store_Location_Revenue AS (
SELECT store_location, ROUND(SUM(transaction_qty * unit_price), 2) AS Total_Revenue
FROM Coffee_Shop_Sales
GROUP BY store_location
),
RevenueWithPercentage AS (
    SELECT 
        store_location,
        ROUND(Total_Revenue, 2) AS Location_Revenue,
        ROUND(100.0 * Total_Revenue / SUM(Total_Revenue) OVER (), 2) AS Revenue_Percentage
    FROM 
        Store_Location_Revenue
)
SELECT 
    store_location,
	location_revenue,
    revenue_percentage
FROM 
    RevenueWithPercentage
ORDER BY Location_Revenue DESC, Revenue_Percentage DESC;














