---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 06 - Set Operators
-- Exercises
-- Frankie Liang
---------------------------------------------------------------------


-- 1
-- Explain the difference between the UNION ALL and UNION operators
-- UNION ALL returns all rows from both result sets, including duplicates. Whereas, UNION returns only distinct rows — it implicitly applies a DISTINCT across the combined result, which requires an internal sort or hash operation.

-- In what cases are they equivalent?
-- When the two queries are guaranteed to return no overlapping rows. 

-- When they are equivalent, which one should you use?
-- Use Union all since it doesnt need to check for duplicates that Union does, so it will be more efficient


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

-- No changes needed for Northwinds database. 

-- 3
-- Write a query that returns customer and employee pairs 
-- that had order activity in January 2016 but not in February 2016
-- Tables involved: TSQLV6 database, Orders table

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301';

-- Changes for northwinds database:Sales.Orders → dbo.Orders, custid → CustomerID, empid → EmployeeID, orderdate → OrderDate

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970101' AND OrderDate < '19970201'

EXCEPT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970201' AND OrderDate < '19970301';

-- 4
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- Tables involved: TSQLV6 database, Orders table

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301';

-- Changes for northwinds database:Sales.Orders → dbo.Orders, custid → CustomerID, empid → EmployeeID, orderdate → OrderDate

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970101' AND OrderDate < '19970201'

INTERSECT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970201' AND OrderDate < '19970301';

-- 5
-- Write a query that returns customer and employee pairs 
-- that had order activity in both January 2016 and February 2016
-- but not in 2015
-- Tables involved: TSQLV6 database, Orders table

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20150101' AND orderdate < '20160101';

-- Changes for northwinds database:Sales.Orders → dbo.Orders, custid → CustomerID, empid → EmployeeID, orderdate → OrderDate

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970101' AND OrderDate < '19970201'

INTERSECT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19970201' AND OrderDate < '19970301'

EXCEPT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= '19960101' AND OrderDate < '19970101';

-- 6 (Optional, Advanced)
-- You are given the following query:
SELECT country, region, city
From (
    SELECT 1 AS sortcol, country, region, city
    FROM HR.Employees

    UNION ALL

    SELECT 2 AS sortcol, country, region, city
    FROM Production.Suppliers
)
ORDER BY sortcol, country, region, city;

-- Changes for northwinds database: HR.Employees → dbo.Employees, Production.Suppliers → dbo.Suppliers, country → Country, region → Region, city → City

SELECT Country, Region, City
FROM (
    SELECT 1 AS sortcol, Country, Region, City
    FROM dbo.Employees

    UNION ALL

    SELECT 2, Country, Region, City
    FROM dbo.Suppliers
) AS D
ORDER BY sortcol, Country, Region, City;

-- You are asked to add logic to the query 
-- such that it would guarantee that the rows from Employees
-- would be returned in the output before the rows from Suppliers,
-- and within each segment, the rows should be sorted
-- by country, region, city
-- Tables involved: TSQLV6 database, Employees and Suppliers tables

