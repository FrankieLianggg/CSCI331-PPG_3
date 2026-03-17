---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 04 - Subqueries
-- Exercises
-- � Itzik Ben-Gan 
---------------------------------------------------------------------

USE Northwinds2024Student;
GO

-- 1 
SELECT
    O.OrderID    AS orderid,
    O.OrderDate  AS orderdate,
    O.CustomerID AS custid,
    O.EmployeeID AS empid
FROM dbo.Orders AS O
WHERE O.OrderDate = (
    SELECT MAX(OrderDate)
    FROM dbo.Orders
)
ORDER BY O.OrderID DESC;

-- 2 (Optional, Advanced)
SELECT
    O.CustomerID AS custid,
    O.OrderID    AS orderid,
    O.OrderDate  AS orderdate,
    O.EmployeeID AS empid
FROM dbo.Orders AS O
WHERE O.CustomerID IN
(
    SELECT T.CustomerID
    FROM
    (
        SELECT CustomerID, COUNT(*) AS numOrders
        FROM dbo.Orders
        GROUP BY CustomerID
    ) AS T
    WHERE T.numOrders =
    (
        SELECT MAX(X.numOrders)
        FROM
        (
            SELECT CustomerID, COUNT(*) AS numOrders
            FROM dbo.Orders
            GROUP BY CustomerID
        ) AS X
    )
)
ORDER BY custid, orderid;


-- 3
SELECT
    E.EmployeeID AS empid,
    E.EmployeeFirstName AS FirstName,
    E.EmployeeLastName AS lastname
FROM dbo.Employees AS E
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Orders AS O
    WHERE O.EmployeeID = E.EmployeeID
      AND O.OrderDate >= '2016-05-01'
)
ORDER BY empid;



-- 4
USE Northwinds2024Student;
GO

SELECT DISTINCT C.CustomerCountry AS country
FROM dbo.Customers AS C

EXCEPT

SELECT DISTINCT E.EmployeeCountry AS country
FROM dbo.Employees AS E

ORDER BY 1;

-- 5
SELECT
    O.CustomerID AS custid,
    O.OrderID    AS orderid,
    O.OrderDate  AS orderdate,
    O.EmployeeID AS empid
FROM dbo.Orders AS O
JOIN
(
    SELECT CustomerID, MAX(OrderDate) AS MaxOrderDate
    FROM dbo.Orders
    GROUP BY CustomerID
) AS M
  ON M.CustomerID = O.CustomerID
 AND M.MaxOrderDate = O.OrderDate
ORDER BY custid, orderid;

-- 6
SELECT
    C.CustomerId          AS custid,
    C.CustomerCompanyName AS companyname
FROM dbo.Customers AS C
WHERE EXISTS
(
    SELECT 1
    FROM dbo.Orders AS O
    WHERE O.CustomerID = C.CustomerID
      AND O.OrderDate >= '2015-01-01'
      AND O.OrderDate <  '2016-01-01'
)
AND NOT EXISTS
(
    SELECT 1
    FROM dbo.Orders AS O
    WHERE O.CustomerID = C.CustomerID
      AND O.OrderDate >= '2016-01-01'
      AND O.OrderDate <  '2017-01-01'
)
ORDER BY custid;

-- 7 (Optional, Advanced)
SELECT DISTINCT
    C.CustomerId          AS custid,
    C.CustomerCompanyName AS companyname
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
JOIN dbo.OrderDetails AS OD
  ON OD.OrderID = O.OrderID
WHERE OD.ProductID = 12
ORDER BY custid;

-- 8 (Optional, Advanced)
SELECT
    CO.CustomerId    AS custid,
    CO.OrderMonth    AS ordermonth,
    CO.TotalQuantity AS qty,
    (
        SELECT SUM(CO2.TotalQuantity)
        FROM Sales.uvw_CustomerOrder AS CO2
        WHERE CO2.CustomerId = CO.CustomerId
          AND CO2.OrderMonth <= CO.OrderMonth
    ) AS runqty
FROM Sales.uvw_CustomerOrder AS CO
ORDER BY CO.CustomerId, CO.OrderMonth;

-- 9
SELECT
    O.CustomerID AS custid,
    O.OrderDate  AS orderdate,
    O.OrderID    AS orderid,
    DATEDIFF
    (
        day,
        (
            SELECT MAX(O2.OrderDate)
            FROM dbo.Orders AS O2
            WHERE O2.CustomerID = O.CustomerID
              AND (
                    O2.OrderDate < O.OrderDate
                 OR (O2.OrderDate = O.OrderDate AND O2.OrderID < O.OrderID)
                  )
        ),
        O.OrderDate
    ) AS diff
FROM dbo.Orders AS O
ORDER BY O.CustomerID, O.OrderDate, O.OrderID;
