---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 06 - Set Operators
-- Exercises
-- � Itzik Ben-Gan 
---------------------------------------------------------------------

-- 1
-- Explain the difference between the UNION ALL and UNION operators
-- In what cases are they equivalent?
-- When they are equivalent, which one should you use?

---- 1
-- UNION ALL returns all rows from both queries, including duplicates.
-- UNION returns only distinct rows, so duplicate rows are removed.
-- They are equivalent when the two input queries are guaranteed not to
-- produce duplicate rows across the combined result.
-- When they are equivalent, UNION ALL is usually better because it avoids
-- the extra work of duplicate elimination and is therefore more efficient.

-- 2
-- Write a query that generates a virtual auxiliary table of 10 numbers
-- in the range 1 through 10
-- Tables involved: no table

SELECT 1 AS n
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10;
GO

-- 3
-- Write a query that returns customer and employee pairs 
-- that had order activity in January 2016 but not in February 2016
-- Tables involved: Northwinds2024Student database, Orders table

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '20160101'
  AND orderdate <  '20160201'

EXCEPT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '20160201'
  AND orderdate <  '20160301';
GO

-- 4
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- Tables involved: Northwinds2024Student database, Orders table

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160101'
  AND OrderDate <  '20160201'

INTERSECT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20160201'
  AND OrderDate <  '20160301';
GO

-- 5
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- but not in 2015
-- Tables involved: Northwinds2024Student database, Orders table

(
    SELECT CustomerId, EmployeeId
    FROM Sales.[Order]
    WHERE OrderDate >= '20160101'
      AND OrderDate <  '20160201'

    INTERSECT

    SELECT CustomerId, EmployeeId
    FROM Sales.[Order]
    WHERE OrderDate >= '20160201'
      AND OrderDate <  '20160301'
)

EXCEPT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE OrderDate >= '20150101'
  AND OrderDate <  '20160101';
GO

-- 6 (Optional, Advanced)
-- You are given the following query:

--SELECT country, region, city
--FROM HR.Employees

--UNION ALL

--SELECT country, region, city
--FROM Production.Suppliers;


-- You are asked to add logic to the query 
-- such that it would guarantee that the rows from Employees
-- would be returned in the output before the rows from Suppliers,
-- and within each segment, the rows should be sorted
-- by country, region, city
-- Tables involved: Northwinds2024Student database, Employees and Suppliers tables

SELECT country, region, city
FROM
(
    SELECT
        1 AS sortcol,
        EmployeeCountry AS country,
        EmployeeRegion  AS region,
        EmployeeCity    AS city
    FROM HumanResources.Employee

    UNION ALL

    SELECT
        2 AS sortcol,
        SupplierCountry AS country,
        SupplierRegion  AS region,
        SupplierCity    AS city
    FROM Production.Supplier
) AS D
ORDER BY
    sortcol,
    country,
    region,
    city;
