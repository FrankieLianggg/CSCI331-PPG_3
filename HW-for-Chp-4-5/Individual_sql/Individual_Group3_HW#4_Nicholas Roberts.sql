/* ============================================================
   CSCI 331 – HW (Ch 4 Subqueries + Ch 5 Table Expressions)
   + FY Quarter scalar function + FY Orders/Freight analysis

   NOTE:
   - Test in TSQLV6 first (per instructions),
   - Then modify/run in Northwinds2024Student for final submission.

   File name format:
   Individual_GroupNumber_HW#_MemberName.sql
   ============================================================ */


/* ============================================================
   SECTION A — CHAPTER 4: SUBQUERIES (EXERCISES)
   ============================================================ */

---------------------------------------------------------------
-- EX 1: Orders placed on the last day of activity in Orders
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
-- USE TSQLV6;  -- or TSQLV4 depending on what your server has
-- GO
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = (SELECT MAX(orderdate) FROM Sales.Orders);

-- (Northwinds2024Student version)
-- USE Northwinds2024Student;
-- GO
SELECT OrderID, OrderDate, CustomerID, EmployeeID
FROM dbo.Orders
WHERE OrderDate = (SELECT MAX(OrderDate) FROM dbo.Orders);


---------------------------------------------------------------
-- EX 2 (Optional/Advanced): Orders by the customer(s) with the
-- highest number of orders
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT O.custid, O.orderid, O.orderdate, O.empid
FROM Sales.Orders AS O
WHERE O.custid IN
(
  SELECT X.custid
  FROM
  (
    SELECT custid, COUNT(*) AS cnt
    FROM Sales.Orders
    GROUP BY custid
  ) AS X
  WHERE X.cnt =
  (
    SELECT MAX(Y.cnt)
    FROM
    (
      SELECT custid, COUNT(*) AS cnt
      FROM Sales.Orders
      GROUP BY custid
    ) AS Y
  )
)
ORDER BY O.custid, O.orderid;

-- (Northwinds2024Student version)
SELECT O.CustomerID, O.OrderID, O.OrderDate, O.EmployeeID
FROM dbo.Orders AS O
WHERE O.CustomerID IN
(
  SELECT X.CustomerID
  FROM
  (
    SELECT CustomerID, COUNT(*) AS cnt
    FROM dbo.Orders
    GROUP BY CustomerID
  ) AS X
  WHERE X.cnt =
  (
    SELECT MAX(Y.cnt)
    FROM
    (
      SELECT CustomerID, COUNT(*) AS cnt
      FROM dbo.Orders
      GROUP BY CustomerID
    ) AS Y
  )
)
ORDER BY O.CustomerID, O.OrderID;


---------------------------------------------------------------
-- EX 3: Employees who did NOT place orders on or after 2016-05-01
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees AS E
WHERE E.empid NOT IN
(
  SELECT DISTINCT O.empid
  FROM Sales.Orders AS O
  WHERE O.orderdate >= '20160501'
)
ORDER BY E.empid;

-- (Northwinds2024Student version)
SELECT E.EmployeeID, E.FirstName, E.LastName
FROM dbo.Employees AS E
WHERE E.EmployeeID NOT IN
(
  SELECT DISTINCT O.EmployeeID
  FROM dbo.Orders AS O
  WHERE O.OrderDate >= '20160501'
)
ORDER BY E.EmployeeID;


---------------------------------------------------------------
-- EX 4: Countries where there are customers but NOT employees
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT DISTINCT C.country
FROM Sales.Customers AS C
WHERE NOT EXISTS
(
  SELECT 1
  FROM HR.Employees AS E
  WHERE E.country = C.country
)
ORDER BY C.country;

-- (Northwinds2024Student version)
SELECT DISTINCT C.Country
FROM dbo.Customers AS C
WHERE NOT EXISTS
(
  SELECT 1
  FROM dbo.Employees AS E
  WHERE E.Country = C.Country
)
ORDER BY C.Country;


---------------------------------------------------------------
-- EX 5: For each customer, orders on that customer's last day of activity
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT O.custid, O.orderid, O.orderdate, O.empid
FROM Sales.Orders AS O
WHERE O.orderdate =
(
  SELECT MAX(O2.orderdate)
  FROM Sales.Orders AS O2
  WHERE O2.custid = O.custid
)
ORDER BY O.custid, O.orderid;

-- (Northwinds2024Student version)
SELECT O.CustomerID, O.OrderID, O.OrderDate, O.EmployeeID
FROM dbo.Orders AS O
WHERE O.OrderDate =
(
  SELECT MAX(O2.OrderDate)
  FROM dbo.Orders AS O2
  WHERE O2.CustomerID = O.CustomerID
)
ORDER BY O.CustomerID, O.OrderID;


---------------------------------------------------------------
-- EX 6: Customers who placed orders in 2015 but NOT in 2016
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE EXISTS
(
  SELECT 1
  FROM Sales.Orders AS O
  WHERE O.custid = C.custid
    AND O.orderdate >= '20150101' AND O.orderdate < '20160101'
)
AND NOT EXISTS
(
  SELECT 1
  FROM Sales.Orders AS O
  WHERE O.custid = C.custid
    AND O.orderdate >= '20160101' AND O.orderdate < '20170101'
)
ORDER BY C.custid;

-- (Northwinds2024Student version)
SELECT C.CustomerID, C.CompanyName
FROM dbo.Customers AS C
WHERE EXISTS
(
  SELECT 1
  FROM dbo.Orders AS O
  WHERE O.CustomerID = C.CustomerID
    AND O.OrderDate >= '20150101' AND O.OrderDate < '20160101'
)
AND NOT EXISTS
(
  SELECT 1
  FROM dbo.Orders AS O
  WHERE O.CustomerID = C.CustomerID
    AND O.OrderDate >= '20160101' AND O.OrderDate < '20170101'
)
ORDER BY C.CustomerID;


---------------------------------------------------------------
-- EX 7 (Optional/Advanced): Customers who ordered product 12
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE EXISTS
(
  SELECT 1
  FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  WHERE O.custid = C.custid
    AND OD.productid = 12
)
ORDER BY C.custid;

-- (Northwinds2024Student version)
-- Northwind usually uses dbo.[Order Details] with a space:
SELECT C.CustomerID, C.CompanyName
FROM dbo.Customers AS C
WHERE EXISTS
(
  SELECT 1
  FROM dbo.Orders AS O
  INNER JOIN dbo.[Order Details] AS OD
    ON OD.OrderID = O.OrderID
  WHERE O.CustomerID = C.CustomerID
    AND OD.ProductID = 12
)
ORDER BY C.CustomerID;


---------------------------------------------------------------
-- EX 8 (Optional/Advanced): Running total qty per customer+month using subqueries
-- (TSQLV6/TSQLV4 version using Sales.CustOrders view if it exists)
---------------------------------------------------------------
-- If Sales.CustOrders exists:
-- Columns usually: custid, ordermonth, qty
SELECT C1.custid, C1.ordermonth, C1.qty,
  (SELECT SUM(C2.qty)
   FROM Sales.CustOrders AS C2
   WHERE C2.custid = C1.custid
     AND C2.ordermonth <= C1.ordermonth) AS runqty
FROM Sales.CustOrders AS C1
ORDER BY C1.custid, C1.ordermonth;

-- (Northwinds2024Student version) — build “CustOrders” as a derived table:
;WITH CustOrders AS
(
  SELECT
    O.CustomerID,
    DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS OrderMonth,
    SUM(OD.Quantity) AS Qty
  FROM dbo.Orders AS O
  INNER JOIN dbo.[Order Details] AS OD
    ON OD.OrderID = O.OrderID
  GROUP BY
    O.CustomerID,
    DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1)
)
SELECT
  C1.CustomerID,
  C1.OrderMonth,
  C1.Qty,
  (SELECT SUM(C2.Qty)
   FROM CustOrders AS C2
   WHERE C2.CustomerID = C1.CustomerID
     AND C2.OrderMonth <= C1.OrderMonth) AS RunQty
FROM CustOrders AS C1
ORDER BY C1.CustomerID, C1.OrderMonth;


---------------------------------------------------------------
-- EX 9: IN vs EXISTS (put as comment answer)
---------------------------------------------------------------
/*
IN:
- Compares a value to a LIST returned by a subquery (or literal list).
- Can behave unexpectedly with NULLs (especially NOT IN) unless you filter NULLs out.

EXISTS:
- Tests whether the subquery returns at least one row (TRUE/FALSE).
- Usually safer for “not found” checks (NOT EXISTS) because it isn’t tripped up by NULLs the same way NOT IN can be.
*/


---------------------------------------------------------------
-- EX 10 (Optional/Advanced): Days since customer’s previous order
-- Use orderdate as primary sort, orderid as tiebreaker.
-- (TSQLV6/TSQLV4 version)
---------------------------------------------------------------
SELECT
  O1.custid,
  O1.orderdate,
  O1.orderid,
  DATEDIFF
  (
    DAY,
    (
      SELECT MAX(O2.orderdate)
      FROM Sales.Orders AS O2
      WHERE O2.custid = O1.custid
        AND
        (
          O2.orderdate < O1.orderdate
          OR (O2.orderdate = O1.orderdate AND O2.orderid < O1.orderid)
        )
    ),
    O1.orderdate
  ) AS diff
FROM Sales.Orders AS O1
ORDER BY O1.custid, O1.orderdate, O1.orderid;

-- (Northwinds2024Student version)
SELECT
  O1.CustomerID,
  O1.OrderDate,
  O1.OrderID,
  DATEDIFF
  (
    DAY,
    (
      SELECT MAX(O2.OrderDate)
      FROM dbo.Orders AS O2
      WHERE O2.CustomerID = O1.CustomerID
        AND
        (
          O2.OrderDate < O1.OrderDate
          OR (O2.OrderDate = O1.OrderDate AND O2.OrderID < O1.OrderID)
        )
    ),
    O1.OrderDate
  ) AS diff
FROM dbo.Orders AS O1
ORDER BY O1.CustomerID, O1.OrderDate, O1.OrderID;



/* ============================================================
   SECTION B — CHAPTER 5: TABLE EXPRESSIONS (EXERCISES)
   ============================================================ */

---------------------------------------------------------------
-- EX 1: Why alias “endofyear” fails in WHERE + valid solution
---------------------------------------------------------------
/*
Problem:
- SELECT-list aliases (like endofyear) are not in scope inside WHERE.
- SQL logical processing: FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
So WHERE can’t “see” endofyear yet.

Valid fixes:
1) Repeat the expression in WHERE
2) Wrap the SELECT in a derived table/CTE and filter in the outer query
Also: If the goal is “orders placed on last day of year”, you want "=" not "<>".
*/

-- Fix #1 (TSQLV6/TSQLV4)
SELECT orderid, orderdate, custid, empid,
  DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate = DATEFROMPARTS(YEAR(orderdate), 12, 31);

-- Fix #2 (TSQLV6/TSQLV4, derived table)
SELECT *
FROM
(
  SELECT orderid, orderdate, custid, empid,
    DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
  FROM Sales.Orders
) AS D
WHERE D.orderdate = D.endofyear;


---------------------------------------------------------------
-- EX 2-1: Max orderdate for each employee
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
SELECT empid, MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid
ORDER BY empid;

-- (Northwinds2024Student)
SELECT EmployeeID, MAX(OrderDate) AS MaxOrderDate
FROM dbo.Orders
GROUP BY EmployeeID
ORDER BY EmployeeID;


---------------------------------------------------------------
-- EX 2-2: Orders that are on each employee’s maximum order date
-- using a derived table
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
INNER JOIN
(
  SELECT empid, MAX(orderdate) AS maxorderdate
  FROM Sales.Orders
  GROUP BY empid
) AS D
  ON D.empid = O.empid
 AND D.maxorderdate = O.orderdate
ORDER BY O.empid, O.orderid;

-- (Northwinds2024Student)
SELECT O.EmployeeID, O.OrderDate, O.OrderID, O.CustomerID
FROM dbo.Orders AS O
INNER JOIN
(
  SELECT EmployeeID, MAX(OrderDate) AS MaxOrderDate
  FROM dbo.Orders
  GROUP BY EmployeeID
) AS D
  ON D.EmployeeID = O.EmployeeID
 AND D.MaxOrderDate = O.OrderDate
ORDER BY O.EmployeeID, O.OrderID;


---------------------------------------------------------------
-- EX 3-1: Row number for each order by (orderdate, orderid)
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
SELECT orderid, orderdate, custid, empid,
  ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders
ORDER BY rownum;

-- (Northwinds2024Student)
SELECT OrderID, OrderDate, CustomerID, EmployeeID,
  ROW_NUMBER() OVER(ORDER BY OrderDate, OrderID) AS RowNum
FROM dbo.Orders
ORDER BY RowNum;


---------------------------------------------------------------
-- EX 3-2: Rows 11 through 20 using a CTE
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
;WITH C AS
(
  SELECT orderid, orderdate, custid, empid,
    ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
  FROM Sales.Orders
)
SELECT orderid, orderdate, custid, empid, rownum
FROM C
WHERE rownum BETWEEN 11 AND 20
ORDER BY rownum;

-- (Northwinds2024Student)
;WITH C AS
(
  SELECT OrderID, OrderDate, CustomerID, EmployeeID,
    ROW_NUMBER() OVER(ORDER BY OrderDate, OrderID) AS RowNum
  FROM dbo.Orders
)
SELECT OrderID, OrderDate, CustomerID, EmployeeID, RowNum
FROM C
WHERE RowNum BETWEEN 11 AND 20
ORDER BY RowNum;


---------------------------------------------------------------
-- EX 4 (Optional/Advanced): Recursive CTE management chain to employee 9
-- (TSQLV6/TSQLV4: HR.Employees has mgrid)
---------------------------------------------------------------
;WITH Chain AS
(
  SELECT empid, mgrid, firstname, lastname, 0 AS lvl
  FROM HR.Employees
  WHERE empid = 9

  UNION ALL

  SELECT E.empid, E.mgrid, E.firstname, E.lastname, C.lvl + 1
  FROM Chain AS C
  INNER JOIN HR.Employees AS E
    ON E.empid = C.mgrid
)
SELECT empid, mgrid, firstname, lastname
FROM Chain
ORDER BY lvl;

-- (Northwinds2024Student: Employees typically has ReportsTo as manager)
;WITH Chain AS
(
  SELECT EmployeeID, ReportsTo, FirstName, LastName, 0 AS lvl
  FROM dbo.Employees
  WHERE EmployeeID = 9

  UNION ALL

  SELECT E.EmployeeID, E.ReportsTo, E.FirstName, E.LastName, C.lvl + 1
  FROM Chain AS C
  INNER JOIN dbo.Employees AS E
    ON E.EmployeeID = C.ReportsTo
)
SELECT EmployeeID, ReportsTo, FirstName, LastName
FROM Chain
ORDER BY lvl;


---------------------------------------------------------------
-- EX 5-1: Create view total qty per employee and year
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
DROP VIEW IF EXISTS Sales.VEmpOrders;
GO
CREATE VIEW Sales.VEmpOrders
AS
SELECT
  O.empid,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
INNER JOIN Sales.OrderDetails AS OD
  ON OD.orderid = O.orderid
GROUP BY
  O.empid,
  YEAR(O.orderdate);
GO

-- (Northwinds2024Student)
DROP VIEW IF EXISTS dbo.VEmpOrders;
GO
CREATE VIEW dbo.VEmpOrders
AS
SELECT
  O.EmployeeID,
  YEAR(O.OrderDate) AS OrderYear,
  SUM(OD.Quantity) AS Qty
FROM dbo.Orders AS O
INNER JOIN dbo.[Order Details] AS OD
  ON OD.OrderID = O.OrderID
GROUP BY
  O.EmployeeID,
  YEAR(O.OrderDate);
GO


---------------------------------------------------------------
-- EX 5-2 (Optional/Advanced): Running qty per employee and year
---------------------------------------------------------------
-- (TSQLV6/TSQLV4)
SELECT empid, orderyear, qty,
  SUM(qty) OVER(PARTITION BY empid ORDER BY orderyear
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runqty
FROM Sales.VEmpOrders
ORDER BY empid, orderyear;

-- (Northwinds2024Student)
SELECT EmployeeID, OrderYear, Qty,
  SUM(Qty) OVER(PARTITION BY EmployeeID ORDER BY OrderYear
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunQty
FROM dbo.VEmpOrders
ORDER BY EmployeeID, OrderYear;


---------------------------------------------------------------
-- EX 6-1: Inline table-valued function TopProducts(@supid, @n)
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
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
    productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supid
  ORDER BY unitprice DESC, productid ASC
);
GO

-- (Northwinds2024Student)
DROP FUNCTION IF EXISTS dbo.TopProducts;
GO
CREATE FUNCTION dbo.TopProducts
(
  @supid INT,
  @n     INT
)
RETURNS TABLE
AS
RETURN
(
  SELECT TOP (@n)
    ProductID, ProductName, UnitPrice
  FROM dbo.Products
  WHERE SupplierID = @supid
  ORDER BY UnitPrice DESC, ProductID ASC
);
GO


---------------------------------------------------------------
-- EX 6-2: CROSS APPLY – two most expensive products per supplier
-- (TSQLV6/TSQLV4)
---------------------------------------------------------------
SELECT
  S.supplierid, S.companyname,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
CROSS APPLY Production.TopProducts(S.supplierid, 2) AS P
ORDER BY S.supplierid, P.unitprice DESC;

-- (Northwinds2024Student)
SELECT
  S.SupplierID, S.CompanyName,
  P.ProductID, P.ProductName, P.UnitPrice
FROM dbo.Suppliers AS S
CROSS APPLY dbo.TopProducts(S.SupplierID, 2) AS P
ORDER BY S.SupplierID, P.UnitPrice DESC;



/* ============================================================
   SECTION C — EXTRA: FY QUARTER SCALAR FUNCTION + ANALYSIS QUERY
   Federal FY:
   - starts Oct 1, YYYY
   - ends Sep 30, YYYY+1
   Q1: Oct–Dec, Q2: Jan–Mar, Q3: Apr–Jun, Q4: Jul–Sep
   ============================================================ */

---------------------------------------------------------------
-- 1) Scalar function: returns label like "FY2026 Q1"
-- Create this in BOTH databases as needed.
---------------------------------------------------------------

-- (TSQLV6/TSQLV4)
DROP FUNCTION IF EXISTS dbo.fn_FYQuarter;
GO
CREATE FUNCTION dbo.fn_FYQuarter (@d DATE)
RETURNS VARCHAR(12)
AS
BEGIN
  DECLARE @fy INT =
    CASE WHEN MONTH(@d) >= 10 THEN YEAR(@d) + 1 ELSE YEAR(@d) END;

  DECLARE @q INT =
    CASE
      WHEN MONTH(@d) BETWEEN 10 AND 12 THEN 1
      WHEN MONTH(@d) BETWEEN  1 AND  3 THEN 2
      WHEN MONTH(@d) BETWEEN  4 AND  6 THEN 3
      ELSE 4
    END;

  RETURN CONCAT('FY', @fy, ' Q', @q);
END;
GO

-- (Northwinds2024Student)
-- If you already created it above in this same DB context, skip re-creating.


---------------------------------------------------------------
-- 2) Analyze total orders + total freight per FY quarter
-- Show FY quarters from newest to oldest
---------------------------------------------------------------

-- IMPORTANT:
-- Your prompt says: Sales.[Order]
-- Many installs instead use Sales.Orders
-- So: change Sales.[Order] to Sales.Orders if needed.

-- (TSQLV6/TSQLV4)
SELECT
  dbo.fn_FYQuarter(O.orderdate) AS FYQuarter,
  COUNT(*) AS TotalOrders,
  SUM(O.freight) AS TotalFreight
FROM Sales.[Order] AS O   -- change to Sales.Orders if that’s your actual table name
GROUP BY dbo.fn_FYQuarter(O.orderdate)
ORDER BY dbo.fn_FYQuarter(O.orderdate) DESC;

-- (Northwinds2024Student)
SELECT
  dbo.fn_FYQuarter(O.OrderDate) AS FYQuarter,
  COUNT(*) AS TotalOrders,
  SUM(O.Freight) AS TotalFreight
FROM dbo.Orders AS O
GROUP BY dbo.fn_FYQuarter(O.OrderDate)
ORDER BY dbo.fn_FYQuarter(O.OrderDate) DESC;



/* ============================================================
   OPTIONAL CLEANUP (only if your instructor wants it)
   ============================================================ */
-- DROP VIEW IF EXISTS Sales.VEmpOrders;
-- DROP VIEW IF EXISTS dbo.VEmpOrders;
-- DROP FUNCTION IF EXISTS Production.TopProducts;
-- DROP FUNCTION IF EXISTS dbo.TopProducts;
-- DROP FUNCTION IF EXISTS dbo.fn_FYQuarter;