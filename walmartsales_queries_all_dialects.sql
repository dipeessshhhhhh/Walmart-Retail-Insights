-- Walmart Sales Queries in Multiple SQL Dialects
-- MySQL Version

USE walmart;

-- 1. Monthly total sales by branch with growth rate
WITH MonthlySales AS (
  SELECT Branch, DATE_FORMAT(STR_TO_DATE(Date, '%m/%d/%Y'), '%Y-%m') AS Month, SUM(Total) AS TotalSales
  FROM walmartsales
  GROUP BY Branch, Month
),
GrowthRates AS (
  SELECT Branch, Month, TotalSales,
         LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month) AS PrevMonthSales
  FROM MonthlySales
)
SELECT Branch, AVG((TotalSales - PrevMonthSales) / PrevMonthSales) * 100 AS AvgGrowth
FROM GrowthRates
WHERE PrevMonthSales IS NOT NULL
GROUP BY Branch
ORDER BY AvgGrowth DESC;

-- 2. Product line with highest gross income per branch
SELECT Branch, `Product line` AS ProductLine, TotalProfit
FROM (
  SELECT Branch, `Product line`,
         SUM(`gross income`) AS TotalProfit,
         RANK() OVER (PARTITION BY Branch ORDER BY SUM(`gross income`) DESC) AS Rank
  FROM walmartsales
  GROUP BY Branch, `Product line`
) Ranked
WHERE Rank = 1;

-- 3. Spending tier classification using PERCENTILE_CONT (MySQL 8+)
WITH CustomerTotals AS (
  SELECT `Customer ID`, SUM(Total) AS TotalSpent
  FROM walmartsales
  GROUP BY `Customer ID`
),
Thresholds AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TotalSpent) AS LowThreshold,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalSpent) AS HighThreshold
  FROM CustomerTotals
)
SELECT ct.`Customer ID`, ct.TotalSpent,
       CASE
         WHEN ct.TotalSpent <= t.LowThreshold THEN 'Low'
         WHEN ct.TotalSpent >= t.HighThreshold THEN 'High'
         ELSE 'Medium'
       END AS SpendingTier
FROM CustomerTotals ct
CROSS JOIN Thresholds t;

-- 4. Outlier total sales by product line
WITH ProductAvg AS (
  SELECT `Product line`, AVG(Total) AS AvgTotal
  FROM walmartsales
  GROUP BY `Product line`
)
SELECT w.*
FROM walmartsales w
JOIN ProductAvg p ON w.`Product line` = p.`Product line`
WHERE w.Total > 1.5 * p.AvgTotal OR w.Total < 0.5 * p.AvgTotal;

-- 5. Payment method counts by city
SELECT City, Payment, COUNT(*) AS Count
FROM walmartsales
GROUP BY City, Payment
ORDER BY City, Count DESC;

-- 6. Monthly sales by gender
SELECT DATE_FORMAT(STR_TO_DATE(Date, '%m/%d/%Y'), '%Y-%m') AS Month, Gender, SUM(Total) AS Sales
FROM walmartsales
GROUP BY Month, Gender
ORDER BY Month;

-- 7. Total sales by customer type and product line
SELECT CustomerType, ProductLine, TotalSales
FROM (
  SELECT `Customer type` AS CustomerType,
         `Product line` AS ProductLine,
         SUM(Total) AS TotalSales,
         RANK() OVER (PARTITION BY `Customer type` ORDER BY SUM(Total) DESC) AS rnk
  FROM walmartsales
  GROUP BY `Customer type`, `product line`
) Ranked
WHERE rnk = 1;

-- 8. Top 5 customers by total spent
SELECT `Customer ID`, SUM(Total) AS TotalSpent
FROM walmartsales
GROUP BY `Customer ID`
ORDER BY TotalSpent DESC
LIMIT 5;

-- 9. Total sales by day of week
SELECT DAYNAME(STR_TO_DATE(Date, '%m/%d/%Y')) AS DayOfWeek, SUM(Total) AS TotalSales
FROM walmartsales
GROUP BY DayOfWeek
ORDER BY TotalSales DESC;

----------------------------------------------------------------------------------------------------
-- PostgreSQL Version

-- 1. Monthly total sales by branch with growth rate
WITH MonthlySales AS (
  SELECT Branch, TO_CHAR(TO_DATE(Date, 'MM/DD/YYYY'), 'YYYY-MM') AS Month, SUM(Total) AS TotalSales
  FROM walmartsales
  GROUP BY Branch, Month
),
GrowthRates AS (
  SELECT Branch, Month, TotalSales,
         LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month) AS PrevMonthSales
  FROM MonthlySales
)
SELECT Branch, AVG((TotalSales - PrevMonthSales) / PrevMonthSales) * 100 AS AvgGrowth
FROM GrowthRates
WHERE PrevMonthSales IS NOT NULL
GROUP BY Branch
ORDER BY AvgGrowth DESC;

-- 2. Product line with highest gross income per branch
SELECT Branch, "Product line" AS ProductLine, TotalProfit
FROM (
  SELECT Branch, "Product line",
         SUM("gross income") AS TotalProfit,
         RANK() OVER (PARTITION BY Branch ORDER BY SUM("gross income") DESC) AS Rank
  FROM walmartsales
  GROUP BY Branch, "Product line"
) Ranked
WHERE Rank = 1;

-- 3. Spending tier classification using PERCENTILE_CONT
WITH CustomerTotals AS (
  SELECT "Customer ID", SUM(Total) AS TotalSpent
  FROM walmartsales
  GROUP BY "Customer ID"
),
Thresholds AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TotalSpent) AS LowThreshold,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalSpent) AS HighThreshold
  FROM CustomerTotals
)
SELECT ct."Customer ID", ct.TotalSpent,
       CASE
         WHEN ct.TotalSpent <= t.LowThreshold THEN 'Low'
         WHEN ct.TotalSpent >= t.HighThreshold THEN 'High'
         ELSE 'Medium'
       END AS SpendingTier
FROM CustomerTotals ct, Thresholds t;

-- 4. Outlier total sales by product line
WITH ProductAvg AS (
  SELECT "Product line", AVG(Total) AS AvgTotal
  FROM walmartsales
  GROUP BY "Product line"
)
SELECT w.*
FROM walmartsales w
JOIN ProductAvg p ON w."Product line" = p."Product line"
WHERE w.Total > 1.5 * p.AvgTotal OR w.Total < 0.5 * p.AvgTotal;

-- 5. Payment method counts by city
SELECT City, Payment, COUNT(*) AS Count
FROM walmartsales
GROUP BY City, Payment
ORDER BY City, Count DESC;

-- 6. Monthly sales by gender
SELECT TO_CHAR(TO_DATE(Date, 'MM/DD/YYYY'), 'YYYY-MM') AS Month, Gender, SUM(Total) AS Sales
FROM walmartsales
GROUP BY Month, Gender
ORDER BY Month;

-- 7. Total sales by customer type and product line
SELECT CustomerType, ProductLine, TotalSales
FROM (
  SELECT "Customer type" AS CustomerType,
         "Product line" AS ProductLine,
         SUM(Total) AS TotalSales,
         RANK() OVER (PARTITION BY "Customer type" ORDER BY SUM(Total) DESC) AS rnk
  FROM walmartsales
  GROUP BY "Customer type", "Product line"
) Ranked
WHERE rnk = 1;

-- 8. Top 5 customers by total spent
SELECT "Customer ID", SUM(Total) AS TotalSpent
FROM walmartsales
GROUP BY "Customer ID"
ORDER BY TotalSpent DESC
LIMIT 5;

-- 9. Total sales by day of week
SELECT TO_CHAR(TO_DATE(Date, 'MM/DD/YYYY'), 'Day') AS DayOfWeek, SUM(Total) AS TotalSales
FROM walmartsales
GROUP BY DayOfWeek
ORDER BY TotalSales DESC;

----------------------------------------------------------------------------------------------------
-- SQL Server Version

USE walmart;
GO

-- 1. Monthly total sales by branch with growth rate
WITH MonthlySales AS (
  SELECT Branch, FORMAT(CONVERT(date, Date, 101), 'yyyy-MM') AS Month, SUM(Total) AS TotalSales
  FROM walmartsales
  GROUP BY Branch, FORMAT(CONVERT(date, Date, 101), 'yyyy-MM')
),
GrowthRates AS (
  SELECT Branch, Month, TotalSales,
         LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month) AS PrevMonthSales
  FROM MonthlySales
)
SELECT Branch, AVG(CAST((TotalSales - PrevMonthSales) AS FLOAT) / PrevMonthSales) * 100 AS AvgGrowth
FROM GrowthRates
WHERE PrevMonthSales IS NOT NULL
GROUP BY Branch
ORDER BY AvgGrowth DESC;
GO

-- 2. Product line with highest gross income per branch
SELECT Branch, [Product line] AS ProductLine, TotalProfit
FROM (
  SELECT Branch, [Product line],
         SUM([gross income]) AS TotalProfit,
         RANK() OVER (PARTITION BY Branch ORDER BY SUM([gross income]) DESC) AS Rank
  FROM walmartsales
  GROUP BY Branch, [Product line]
) Ranked
WHERE Rank = 1;
GO

-- 3. Spending tier classification (approximate percentiles not straightforward in SQL Server, simplified version)
WITH CustomerTotals AS (
  SELECT [Customer ID], SUM(Total) AS TotalSpent
  FROM walmartsales
  GROUP BY [Customer ID]
),
Thresholds AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TotalSpent) OVER () AS LowThreshold,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalSpent) OVER () AS HighThreshold
  FROM CustomerTotals
)
SELECT ct.[Customer ID], ct.TotalSpent,
       CASE
         WHEN ct.TotalSpent <= (SELECT TOP 1 LowThreshold FROM Thresholds) THEN 'Low'
         WHEN ct.TotalSpent >= (SELECT TOP 1 HighThreshold FROM Thresholds) THEN 'High'
         ELSE 'Medium'
       END AS SpendingTier
FROM CustomerTotals ct;
GO

-- 4. Outlier total sales by product line
WITH ProductAvg AS (
  SELECT [Product line], AVG(Total) AS AvgTotal
  FROM walmartsales
  GROUP BY [Product line]
)
SELECT w.*
FROM walmartsales w
JOIN ProductAvg p ON w.[Product line] = p.[Product line]
WHERE w.Total > 1.5 * p.AvgTotal OR w.Total < 0.5 * p.AvgTotal;
GO

-- 5. Payment method counts by city
SELECT City, Payment, COUNT(*) AS Count
FROM walmartsales
GROUP BY City, Payment
ORDER BY City, Count DESC;
GO

-- 6. Monthly sales by gender
SELECT FORMAT(CONVERT(date, Date, 101), 'yyyy-MM') AS Month, Gender, SUM(Total) AS Sales
FROM walmartsales
GROUP BY FORMAT(CONVERT(date, Date, 101), 'yyyy-MM'), Gender
ORDER BY Month;
GO

-- 7. Total sales by customer type and product line
SELECT CustomerType, ProductLine, TotalSales
FROM (
  SELECT [Customer type] AS CustomerType,
         [Product line] AS ProductLine,
         SUM(Total) AS TotalSales,
         RANK() OVER (PARTITION BY [Customer type] ORDER BY SUM(Total) DESC) AS rnk
  FROM walmartsales
  GROUP BY [Customer type], [Product line]
) Ranked
WHERE rnk = 1;
GO

-- 8. Top 5 customers by total spent
SELECT TOP 5 [Customer ID], SUM(Total) AS TotalSpent
FROM walmartsales
GROUP BY [Customer ID]
ORDER BY TotalSpent DESC;
GO

-- 9. Total sales by day of week
SELECT DATENAME(weekday, CONVERT(date, Date, 101)) AS DayOfWeek, SUM(Total) AS TotalSales
FROM walmartsales
GROUP BY DATENAME(weekday, CONVERT(date, Date, 101))
ORDER BY TotalSales DESC;
GO

----------------------------------------------------------------------------------------------------
-- SQLite Version

-- Note: SQLite does not support window functions before 3.25 and lacks some features like PERCENTILE_CONT.
-- Date format assumed to be MM/DD/YYYY.

-- 1. Monthly total sales by branch with growth rate (no LAG function available)
-- Simplified version without growth rate

SELECT Branch, strftime('%Y-%m', substr(Date, 7,4) || '-' || substr(Date, 1,2) || '-' || substr(Date, 4,2)) AS Month, SUM(Total) AS TotalSales
FROM walmartsales
GROUP BY Branch, Month
ORDER BY Branch, Month;

-- 2. Product line with highest gross income per branch
SELECT Branch, `Product line` AS ProductLine, MAX(TotalProfit) AS MaxProfit
FROM (
  SELECT Branch, `Product line`, SUM(`gross income`) AS TotalProfit
  FROM walmartsales
  GROUP BY Branch, `Product line`
)
GROUP BY Branch;

-- 3. Spending tier classification - Not supported due to lack of PERCENTILE_CONT, needs external processing

-- 4. Outlier total sales by product line
WITH ProductAvg AS (
  SELECT `Product line`, AVG(Total) AS AvgTotal
  FROM walmartsales
  GROUP BY `Product line`
)
SELECT w.*
FROM walmartsales w
JOIN ProductAvg p ON w.`Product line` = p.`Product line`
WHERE w.Total > 1.5 * p.AvgTotal OR w.Total < 0.5 * p.AvgTotal;

-- 5. Payment method counts by city
SELECT City, Payment, COUNT(*) AS Count
FROM walmartsales
GROUP BY City, Payment
ORDER BY City, Count DESC;

-- 6. Monthly sales by gender
SELECT strftime('%Y-%m', substr(Date, 7,4) || '-' || substr(Date, 1,2) || '-' || substr(Date, 4,2)) AS Month, Gender, SUM(Total) AS Sales
FROM walmartsales
GROUP BY Month, Gender
ORDER BY Month;

-- 7. Total sales by customer type and product line
SELECT CustomerType, ProductLine, TotalSales
FROM (
  SELECT `Customer type` AS CustomerType,
         `Product line` AS ProductLine,
         SUM(Total) AS TotalSales
  FROM walmartsales
  GROUP BY `Customer type`, `Product line`
)
ORDER BY TotalSales DESC;

-- 8. Top 5 customers by total spent
SELECT `Customer ID`, SUM(Total) AS TotalSpent
FROM walmartsales
GROUP BY `Customer ID`
ORDER BY TotalSpent DESC
LIMIT 5;

-- 9. Total sales by day of week
SELECT strftime('%w', substr(Date, 7,4) || '-' || substr(Date, 1,2) || '-' || substr(Date, 4,2)) AS DayNumber, 
       CASE strftime('%w', substr(Date, 7,4) || '-' || substr(Date, 1,2) || '-' || substr(Date, 4,2))
         WHEN '0' THEN 'Sunday'
         WHEN '1' THEN 'Monday'
         WHEN '2' THEN 'Tuesday'
         WHEN '3' THEN 'Wednesday'
         WHEN '4' THEN 'Thursday'
         WHEN '5' THEN 'Friday'
         WHEN '6' THEN 'Saturday'
       END AS DayOfWeek,
       SUM(Total) AS TotalSales
FROM walmartsales
GROUP BY DayNumber
ORDER BY TotalSales DESC;

