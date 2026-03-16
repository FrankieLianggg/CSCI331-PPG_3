USE Northwinds2024Student3;
GO

/*
Name: Nicholas Roberts
Group: 3
Homework: HW6
Topic: Set Operators

Problem Proposition:
This assignment uses SQL set operators to compare business records
in the Northwinds database in order to identify overlap, difference,
and full combinations across order activity and location data.
*/


/************************************************************
1. UNION ALL vs UNION explanation
************************************************************/
/*
UNION ALL returns all rows from both queries, including duplicates.

UNION returns only distinct rows, removing duplicates.

They are equivalent when no duplicate rows can exist between the two result sets.

When they are equivalent, UNION ALL is usually preferred because it avoids
the extra work of removing duplicates and is more efficient.
*/


/************************************************************
2. Auxiliary table of numbers 1 through 10
************************************************************/
SELECT 1 AS n
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10
ORDER BY n;
GO


/************************************************************
3. Check available order date range
   Run this first if you want to confirm which months exist
************************************************************/
SELECT MIN(OrderDate) AS MinOrderDate,
       MAX(OrderDate) AS MaxOrderDate
FROM dbo.Orders;
GO

SELECT YEAR(OrderDate) AS OrderYear,
       MONTH(OrderDate) AS OrderMonth,
       COUNT(*) AS NumOrders
FROM dbo.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;
GO


/************************************************************
4. Customer-employee pairs with activity in Month 1
   but not in Month 2
************************************************************/
DECLARE @Month1Start DATE = '1997-01-01';
DECLARE @Month2Start DATE = '1997-02-01';
DECLARE @Month3Start DATE = '1997-03-01';

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month1Start
  AND OrderDate <  @Month2Start

EXCEPT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month2Start
  AND OrderDate <  @Month3Start

ORDER BY CustomerID, EmployeeID;
GO


/************************************************************
5. Customer-employee pairs with activity in both months
************************************************************/
DECLARE @Month1Start2 DATE = '1997-01-01';
DECLARE @Month2Start2 DATE = '1997-02-01';
DECLARE @Month3Start2 DATE = '1997-03-01';

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month1Start2
  AND OrderDate <  @Month2Start2

INTERSECT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month2Start2
  AND OrderDate <  @Month3Start2

ORDER BY CustomerID, EmployeeID;
GO


/************************************************************
6. Customer-employee pairs active in both months,
   but not active in the prior year
************************************************************/
DECLARE @Month1Start3 DATE = '1997-01-01';
DECLARE @Month2Start3 DATE = '1997-02-01';
DECLARE @Month3Start3 DATE = '1997-03-01';
DECLARE @PriorYearStart DATE = '1996-01-01';
DECLARE @PriorYearEnd   DATE = '1996-12-31';

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month1Start3
  AND OrderDate <  @Month2Start3

INTERSECT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @Month2Start3
  AND OrderDate <  @Month3Start3

EXCEPT

SELECT CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate >= @PriorYearStart
  AND OrderDate < DATEADD(DAY, 1, @PriorYearEnd)

ORDER BY CustomerID, EmployeeID;
GO


/************************************************************
7. Employees first, suppliers second, ordered within each group
************************************************************/
SELECT Country, Region, City
FROM
(
    SELECT 1 AS sortcol,
           Country,
           Region,
           City
    FROM dbo.Employees

    UNION ALL

    SELECT 2 AS sortcol,
           Country,
           Region,
           City
    FROM dbo.Suppliers
) AS D
ORDER BY sortcol, Country, Region, City;
GO


/************************************************************
8. Example: employee and supplier locations with UNION ALL
   Keeps duplicates
************************************************************/
SELECT Country, Region, City
FROM dbo.Employees

UNION ALL

SELECT Country, Region, City
FROM dbo.Suppliers
ORDER BY Country, Region, City;
GO


/************************************************************
9. Example: employee and supplier locations with UNION
   Removes duplicates
************************************************************/
SELECT Country, Region, City
FROM dbo.Employees

UNION

SELECT Country, Region, City
FROM dbo.Suppliers
ORDER BY Country, Region, City;
GO


/************************************************************
10. Example: shared locations between employees and suppliers
************************************************************/
SELECT Country, Region, City
FROM dbo.Employees

INTERSECT

SELECT Country, Region, City
FROM dbo.Suppliers
ORDER BY Country, Region, City;
GO


/************************************************************
11. Example: employee locations not used by suppliers
************************************************************/
SELECT Country, Region, City
FROM dbo.Employees

EXCEPT

SELECT Country, Region, City
FROM dbo.Suppliers
ORDER BY Country, Region, City;
GO