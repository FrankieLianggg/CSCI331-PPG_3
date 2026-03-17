---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 05 - Table Expressions
-- Exercises
-- � Itzik Ben-Gan 
---------------------------------------------------------------------


-- 1
-- The following query attempts to filter orders placed on the last day of the year.
USE Northwinds2024Student;
GO

SELECT 
    O.OrderID    AS orderid,
    O.OrderDate  AS orderdate,
    O.CustomerID AS custid,
    O.EmployeeID AS empid,
    DATEFROMPARTS(YEAR(O.OrderDate), 12, 31) AS endofyear
FROM dbo.Orders AS O
WHERE O.OrderDate <> DATEFROMPARTS(YEAR(O.OrderDate), 12, 31);

-- When you try to run this query you get the following error.
/*
Msg 207, Level 16, State 1, Line 233
Invalid column name 'endofyear'.
*/
-- Explain what the problem is and suggest a valid solution.


--Problem: endofyear is a column alias created in the SELECT list: DATEFROMPARTS(YEAR(O.OrderDate), 12, 31) AS endofyear

--But the WHERE clause is evaluated before the SELECT list (logical query processing order). So when SQL Server parses/evaluates:

--WHERE O.OrderDate <> endofyear;

--it cannot see the alias yet, and it looks for a real column named endofyear in the tables—doesn’t find one—so you get:

--Invalid column name 'endofyear'.



-- 2-1
SELECT
    O.EmployeeID AS empid,
    MAX(O.OrderDate) AS maxorderdate
FROM dbo.Orders AS O
GROUP BY O.EmployeeID
ORDER BY empid;


-- 2-2

SELECT
    O.EmployeeID AS empid,
    O.OrderDate  AS orderdate,
    O.OrderID    AS orderid,
    O.CustomerID AS custid
FROM dbo.Orders AS O
JOIN (
    SELECT
        EmployeeID,
        MAX(OrderDate) AS maxorderdate
    FROM dbo.Orders
    GROUP BY EmployeeID
) AS D
  ON D.EmployeeID   = O.EmployeeID
 AND D.maxorderdate = O.OrderDate
ORDER BY empid DESC, orderid;

-- 3-1

SELECT
    O.OrderID   AS orderid,
    O.OrderDate AS orderdate,
    O.CustomerID AS custid,
    O.EmployeeID AS empid,
    ROW_NUMBER() OVER (ORDER BY O.OrderDate, O.OrderID) AS rownum
FROM dbo.Orders AS O
ORDER BY O.OrderDate, O.OrderID;

-- 3-2

WITH OrderRows AS
(
    SELECT
        O.OrderID    AS orderid,
        O.OrderDate  AS orderdate,
        O.CustomerID AS custid,
        O.EmployeeID AS empid,
        ROW_NUMBER() OVER (ORDER BY O.OrderDate, O.OrderID) AS rownum
    FROM dbo.Orders AS O
)
SELECT
    orderid, orderdate, custid, empid, rownum
FROM OrderRows
WHERE rownum BETWEEN 11 AND 20
ORDER BY rownum;

-- 4 (Optional, Advanced)

WITH ManagementChain AS
(
    -- anchor: start at Patricia Doyle (empid 9)
    SELECT
        E.EmployeeID AS empid,
        E.EmployeeManagerID AS mgrid,
        E.EmployeeFirstName AS firstname,
        E.EmployeeLastName AS lastname
    FROM dbo.Employees AS E
    WHERE E.EmployeeID = 9

    UNION ALL

    -- recursive: follow the manager (mgrid) upward
    SELECT
        E.EmployeeID AS empid,
        E.EmployeeManagerID AS mgrid,
        E.EmployeeFirstName AS firstname,
        E.EmployeeLastName AS lastname
    FROM dbo.Employees AS E
    JOIN ManagementChain AS MC
      ON E.EmployeeID = MC.mgrid
)
SELECT
    empid, mgrid, firstname, lastname
FROM ManagementChain
ORDER BY empid DESC;   -- matches your sample output order

-- 5-1

DROP VIEW IF EXISTS Sales.VEmpOrders;
GO

CREATE VIEW Sales.VEmpOrders
AS
SELECT
    O.Employeeid AS empid, 
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.Quantity) AS qty 
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY
    O.Employeeid,
    YEAR(O.orderdate);
GO

-- test
SELECT *
FROM Sales.VEmpOrders
ORDER BY empid, orderyear;

-- 5-2 (Optional, Advanced)
SELECT
    empid,
    orderyear,
    qty,
    SUM(qty) OVER (
        PARTITION BY empid
        ORDER BY orderyear
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS runqty
FROM Sales.VEmpOrders
ORDER BY empid, orderyear;

-- 6-1
DROP FUNCTION IF EXISTS Production.TopProducts;
GO

CREATE FUNCTION Production.TopProducts
(
    @supid INT,
    @n     INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@n)
        P.productid,
        P.productname,
        P.unitprice
    FROM Production.Product AS P
    WHERE P.supplierid = @supid
    ORDER BY
        P.unitprice DESC,
        P.productid ASC     -- tie-breaker for stable results
);
GO

-- test
SELECT *
FROM Production.TopProducts(5, 2);
GO



-- 6-2
SELECT
    S.SupplierId          AS supplierid,
    S.SupplierCompanyName AS companyname,
    TP.productid,
    TP.productname,
    TP.unitprice
FROM Production.Supplier AS S
CROSS APPLY Production.TopProducts(S.SupplierId, 2) AS TP
ORDER BY S.SupplierId, TP.unitprice DESC, TP.productid;
-- When you�re done, run the following code for cleanup:
DROP VIEW IF EXISTS dbo.VEmpOrders;
DROP FUNCTION IF EXISTS Production.TopProducts;
