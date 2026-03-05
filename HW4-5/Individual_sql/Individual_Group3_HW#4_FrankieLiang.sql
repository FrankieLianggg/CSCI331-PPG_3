-- Frankie Liang

/* ============================================================
   CHAPTER 4: SUBQUERIES (EXERCISES)
   ============================================================ */

-- Exercise 1
-- Write a query that returns all orders placed on the last day
-- of activity that can be found in the Orders table.
-- Northwinds2024Student version (Sales schema)
SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order]
WHERE OrderDate = (SELECT MAX(OrderDate) FROM Sales.[Order]);

-- Exercise 2
-- Orders from customer(s) with the highest number of orders
SELECT O.CustomerId, O.OrderId, O.OrderDate, O.EmployeeId
FROM Sales.[Order] AS O
WHERE O.CustomerId IN
(
    SELECT X.CustomerId
    FROM
    (
        SELECT CustomerId, COUNT(*) AS cnt
        FROM Sales.[Order]
        GROUP BY CustomerId
    ) AS X
    WHERE X.cnt =
    (
        SELECT MAX(Y.cnt)
        FROM
        (
            SELECT CustomerId, COUNT(*) AS cnt
            FROM Sales.[Order]
            GROUP BY CustomerId
        ) AS Y
    )
)
ORDER BY O.CustomerId, O.OrderId;

-- Exercise 3
-- Return employees who did not handle orders on or after May 1, 2016
SELECT e.EmployeeId, e.EmployeeFirstName, e.EmployeeLastName
FROM HumanResources.Employee AS e
WHERE e.EmployeeId NOT IN
(
    SELECT DISTINCT o.EmployeeId
    FROM Sales.[Order] AS o
    WHERE o.OrderDate >= '20160501'
)
ORDER BY e.EmployeeId;

-- Exercise 4
-- Return countries that exist in the Customer table
-- but do not appear in the Employee table
SELECT DISTINCT c.CustomerCountry
FROM Sales.Customer AS c
WHERE NOT EXISTS
(
    SELECT 1
    FROM HumanResources.Employee AS e
    WHERE e.EmployeeCountry = c.CustomerCountry
)
ORDER BY c.CustomerCountry;

-- Exercise 5
-- For each customer, find their most recent order date,
-- then return the orders from that date
SELECT o.CustomerId, o.OrderId, o.OrderDate, o.EmployeeId
FROM Sales.[Order] AS o
WHERE o.OrderDate =
(
    SELECT MAX(o2.OrderDate)
    FROM Sales.[Order] AS o2
    WHERE o2.CustomerId = o.CustomerId
)
ORDER BY o.CustomerId, o.OrderId;

-- Exercise 6
-- Find customers who ordered in 2015 but did NOT order in 2016
SELECT c.CustomerId, c.CustomerCompanyName
FROM Sales.Customer AS c
WHERE c.CustomerId IN
(
    SELECT o.CustomerId
    FROM Sales.[Order] AS o
    WHERE YEAR(o.OrderDate) >= '20150101' AND o.OrderDate < '20160101'
)
AND c.CustomerId NOT IN
(
    SELECT o.CustomerId
    FROM Sales.[Order] AS o
    WHERE YEAR(o.OrderDate)  >= '20160101' AND o.OrderDate < '20170101'
)
ORDER BY c.CustomerId;

-- Exercise 7
-- Find customers who ordered product with id = 12
SELECT DISTINCT c.CustomerId, c.CustomerCompanyName
FROM Sales.Customer AS c
WHERE EXISTS
(
    SELECT 1
    FROM Sales.[Order] AS o
    INNER JOIN Sales.OrderDetail AS od
        ON od.OrderId = o.OrderId
    WHERE o.CustomerId = c.CustomerId
      AND od.ProductId = 12
)
ORDER BY c.CustomerId;

-- Exercise 8 (Advanced)
-- Running total quantity per customer and month using subqueries

;WITH CustOrders AS
(
    SELECT
        O.CustomerId,
        DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS OrderMonth,
        SUM(OD.Quantity) AS Qty
    FROM Sales.[Order] AS O
    INNER JOIN Sales.OrderDetail AS OD
        ON OD.OrderId = O.OrderId
    GROUP BY
        O.CustomerId,
        DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1)
)
SELECT
    C1.CustomerId,
    C1.OrderMonth,
    C1.Qty,
    (
        SELECT SUM(C2.Qty)
        FROM CustOrders AS C2
        WHERE C2.CustomerId = C1.CustomerId
          AND C2.OrderMonth <= C1.OrderMonth
    ) AS RunQty
FROM CustOrders AS C1
ORDER BY C1.CustomerId, C1.OrderMonth;

-- Exercise 9 (Conceptual)
-- IN vs EXISTS
/*
IN:
- Compares a value to a list returned by a subquery (or literal list).
- Can behave unexpectedly with NULLs (especially NOT IN) unless NULLs are filtered out.

EXISTS:
- Tests whether the subquery returns at least one row (TRUE/FALSE).
- Safer for "not found" checks (NOT EXISTS) because it is not affected by NULLs
  the same way NOT IN can be.
*/

-- Exercise 10 (Advanced)
-- Days since customer's previous order

SELECT
    O1.CustomerId,
    O1.OrderDate,
    O1.OrderId,
    DATEDIFF
    (
        DAY,
        (
            SELECT MAX(O2.OrderDate)
            FROM Sales.[Order] AS O2
            WHERE O2.CustomerId = O1.CustomerId
              AND
              (
                  O2.OrderDate < O1.OrderDate
                  OR (O2.OrderDate = O1.OrderDate AND O2.OrderId < O1.OrderId)
              )
        ),
        O1.OrderDate
    ) AS diff
FROM Sales.[Order] AS O1
ORDER BY O1.CustomerId, O1.OrderDate, O1.OrderId;

/* ============================================================
    CHAPTER 5: TABLE EXPRESSIONS (EXERCISES)
   ============================================================ */

-- Exercise 1
-- The following query attempts to filter orders placed on the
-- last day of the year. Explain why it produces an error and fix it.

/*
Problem:
SELECT-list aliases (like endofyear) are not in scope inside WHERE.
SQL logical processing order: FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
So WHERE cannot reference the alias "endofyear" defined in SELECT.

Also note: the original query used <> instead of =. If the goal is orders
placed on the LAST day of the year, the correct operator is =.

Fix 1: Repeat the expression directly in WHERE ():
*/
SELECT
    OrderId,
    OrderDate,
    CustomerId,
    EmployeeId,
    DATEFROMPARTS(YEAR(OrderDate), 12, 31) AS endofyear
FROM Sales.[Order]
WHERE OrderDate = DATEFROMPARTS(YEAR(OrderDate), 12, 31);

-- Fix 2: Wrap in a derived table and filter in the outer query ():
SELECT *
FROM
(
    SELECT
        OrderId,
        OrderDate,
        CustomerId,
        EmployeeId,
        DATEFROMPARTS(YEAR(OrderDate), 12, 31) AS endofyear
    FROM Sales.[Order]
) AS D
WHERE D.OrderDate = D.endofyear;


-- Exercise 2-1
-- Write a query that returns the maximum order date
-- for each employee.
SELECT
    EmployeeId,
    MAX(OrderDate) AS maxorderdate
FROM Sales.[Order]
GROUP BY EmployeeId
ORDER BY EmployeeId;


-- Exercise 2-2
-- Encapsulate exercise 2-1 in a derived table.
-- Join with Sales.[Order] to return orders that occurred
-- on each employee's maximum order date.
SELECT
    O.EmployeeId,
    O.OrderDate,
    O.OrderId,
    O.CustomerId
FROM Sales.[Order] AS O
INNER JOIN
(
    SELECT
        EmployeeId,
        MAX(OrderDate) AS maxorderdate
    FROM Sales.[Order]
    GROUP BY EmployeeId
) AS D
    ON O.EmployeeId = D.EmployeeId
   AND O.OrderDate  = D.maxorderdate
ORDER BY O.EmployeeId, O.OrderId;


-- Exercise 3-1
-- Write a query that calculates a row number for each order
-- based on orderdate and orderid ordering.
SELECT
    OrderId,
    OrderDate,
    CustomerId,
    EmployeeId,
    ROW_NUMBER() OVER(ORDER BY OrderDate, OrderId) AS rownum
FROM Sales.[Order]
ORDER BY rownum;


-- Exercise 3-2
-- Write a query that returns rows with row numbers 11 through 20
-- using a CTE to encapsulate the query from exercise 3-1.
WITH OrdersWithNums AS
(
    SELECT
        OrderId,
        OrderDate,
        CustomerId,
        EmployeeId,
        ROW_NUMBER() OVER(ORDER BY OrderDate, OrderId) AS rownum
    FROM Sales.[Order]
)
SELECT
    OrderId,
    OrderDate,
    CustomerId,
    EmployeeId,
    rownum
FROM OrdersWithNums
WHERE rownum BETWEEN 11 AND 20
ORDER BY rownum;


-- Exercise 4
-- Write a recursive CTE that returns the management chain
-- leading to Patricia Doyle (employee id 9).
WITH EmpChain AS
(
    SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName, 0 AS lvl
    FROM HumanResources.Employee
    WHERE EmployeeId = 9

    UNION ALL

    SELECT E.EmployeeId, E.EmployeeManagerId, E.EmployeeFirstName, E.EmployeeLastName, C.lvl + 1
    FROM HumanResources.Employee AS E
    INNER JOIN EmpChain AS C
        ON E.EmployeeId = C.EmployeeManagerId
)
SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName
FROM EmpChain
ORDER BY lvl;

-- Exercise 5-1
-- Create a view that returns the total quantity for each
-- employee and year using Sales.[Order] and Sales.OrderDetail.
GO
CREATE OR ALTER VIEW Sales.VEmpOrders
AS
SELECT
    O.EmployeeId,
    YEAR(O.OrderDate) AS orderyear,
    SUM(OD.Quantity)  AS qty
FROM Sales.[Order] AS O
INNER JOIN Sales.OrderDetail AS OD
    ON OD.OrderId = O.OrderId
GROUP BY
    O.EmployeeId,
    YEAR(O.OrderDate);
GO



-- Exercise 5-2
-- Write a query against Sales.VEmpOrders that returns
-- the running quantity for each employee and year.
SELECT
    EmployeeId,
    orderyear,
    qty,
    SUM(qty) OVER
    (
        PARTITION BY EmployeeId
        ORDER BY orderyear
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS runqty
FROM Sales.VEmpOrders
ORDER BY EmployeeId, orderyear;



-- Exercise 6-1
-- Create an inline table-valued function that accepts a
-- supplier id and a count N, and returns the N most expensive
-- products supplied by that supplier.
GO
CREATE OR ALTER FUNCTION Production.TopProducts
(
    @supid INT,
    @n     INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@n)
        ProductId,
        ProductName,
        UnitPrice
    FROM Production.Product
    WHERE SupplierId = @supid
    ORDER BY UnitPrice DESC, ProductId ASC
);
GO

-- Exercise 6-2
-- Use CROSS APPLY to return the two most expensive products
-- per supplier using the function above.
SELECT
    S.SupplierId,
    S.SupplierCompanyName,
    P.ProductId,
    P.ProductName,
    P.UnitPrice
FROM Production.Supplier AS S
CROSS APPLY Production.TopProducts(S.SupplierId, 2) AS P
ORDER BY S.SupplierId, P.UnitPrice DESC;

/* ============================================================
   EXTRA: FY QUARTER SCALAR FUNCTION + ANALYSIS
   Federal FY: starts Oct 1 (Q1: Oct-Dec, Q2: Jan-Mar,
   Q3: Apr-Jun, Q4: Jul-Sep)
   ============================================================ */

-- Scalar function: returns label like "FY2026 Q1"
GO
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

-- Analyze total orders and total freight per FY quarter

SELECT
    dbo.fn_FYQuarter(O.OrderDate) AS FYQuarter,
    COUNT(*)                      AS TotalOrders,
    SUM(O.Freight)                AS TotalFreight
FROM Sales.[Order] AS O
GROUP BY dbo.fn_FYQuarter(O.OrderDate)
ORDER BY dbo.fn_FYQuarter(O.OrderDate) DESC;

-- Calling dbo.fn_FYQuarter() in both GROUP BY and ORDER BY means it runs once per row for grouping and again for ordering. A small improvement would be to wrap in a derived table.

/* ============================================================
   CLEANUP -- Suggested by claude to avoid confusion with future exercises that may reuse these names
   ============================================================ */

DROP VIEW IF EXISTS Sales.VEmpOrders;
GO

DROP FUNCTION IF EXISTS Production.TopProducts;
GO

DROP FUNCTION IF EXISTS dbo.fn_FYQuarter;
GO

-- After word, after completion, I ran my code through claude to see what I could optimize or improve. These are the suggestions I got:
/*
Looking at your SQL, it's already very strong. Here are the meaningful improvements worth making:

---

**1. FY Quarter ORDER BY — use a numeric sort key (most important)**

Your current `ORDER BY dbo.fn_FYQuarter(O.OrderDate) DESC` sorts alphabetically. It happens to work with `FYyyyy Qq` format, but it's fragile and calls the scalar function a second time per row. A more robust and explicit approach:

```sql
SELECT
    dbo.fn_FYQuarter(O.OrderDate) AS FYQuarter,
    COUNT(*)                      AS TotalOrders,
    SUM(O.Freight)                AS TotalFreight
FROM Sales.[Order] AS O
GROUP BY dbo.fn_FYQuarter(O.OrderDate),
         -- include sort key in GROUP BY so we can ORDER BY it cleanly
         CASE WHEN MONTH(O.OrderDate) >= 10 THEN YEAR(O.OrderDate) + 1 ELSE YEAR(O.OrderDate) END * 10
         + CASE WHEN MONTH(O.OrderDate) BETWEEN 10 AND 12 THEN 1
                WHEN MONTH(O.OrderDate) BETWEEN  1 AND  3 THEN 2
                WHEN MONTH(O.OrderDate) BETWEEN  4 AND  6 THEN 3
                ELSE 4 END
ORDER BY
         CASE WHEN MONTH(O.OrderDate) >= 10 THEN YEAR(O.OrderDate) + 1 ELSE YEAR(O.OrderDate) END * 10
         + CASE WHEN MONTH(O.OrderDate) BETWEEN 10 AND 12 THEN 1
                WHEN MONTH(O.OrderDate) BETWEEN  1 AND  3 THEN 2
                WHEN MONTH(O.OrderDate) BETWEEN  4 AND  6 THEN 3
                ELSE 4 END DESC;
```

Or more cleanly, push it into a derived table so the sort key is computed once:

```sql
SELECT FYQuarter, TotalOrders, TotalFreight
FROM (
    SELECT
        dbo.fn_FYQuarter(O.OrderDate)        AS FYQuarter,
        COUNT(*)                              AS TotalOrders,
        SUM(O.Freight)                        AS TotalFreight,
        CASE WHEN MONTH(O.OrderDate) >= 10
             THEN YEAR(O.OrderDate) + 1
             ELSE YEAR(O.OrderDate) END * 10
        + CASE WHEN MONTH(O.OrderDate) BETWEEN 10 AND 12 THEN 1
               WHEN MONTH(O.OrderDate) BETWEEN  1 AND  3 THEN 2
               WHEN MONTH(O.OrderDate) BETWEEN  4 AND  6 THEN 3
               ELSE 4 END                    AS SortKey
    FROM Sales.[Order] AS O
    GROUP BY dbo.fn_FYQuarter(O.OrderDate),
             CASE WHEN MONTH(O.OrderDate) >= 10 THEN YEAR(O.OrderDate)+1 ELSE YEAR(O.OrderDate) END * 10
             + CASE WHEN MONTH(O.OrderDate) BETWEEN 10 AND 12 THEN 1
                    WHEN MONTH(O.OrderDate) BETWEEN  1 AND  3 THEN 2
                    WHEN MONTH(O.OrderDate) BETWEEN  4 AND  6 THEN 3
                    ELSE 4 END
) AS X
ORDER BY SortKey DESC;
```

---

**2. Exercise 3 — NULL safety on `NOT IN`**

```sql
WHERE e.EmployeeId NOT IN (SELECT DISTINCT o.EmployeeId ...)
```

If any `EmployeeId` in the subquery is `NULL`, `NOT IN` returns no rows at all. Add a filter:

```sql
WHERE o.EmployeeId IS NOT NULL
```

---

**3. Exercise 10 — `DATEDIFF` returns NULL for the first order**

When there's no previous order, the subquery returns `NULL`, and `DATEDIFF(DAY, NULL, ...)` returns `NULL`. That's technically correct, but worth an explicit label for clarity:

```sql
ISNULL(DATEDIFF(DAY, (...subquery...), O1.OrderDate), 0) AS DaysSincePrev
-- or use NULL intentionally and just alias it clearly:
... AS DaysSincePreviousOrder  -- NULL means first order
```

Those are the real improvements. Everything else — your logic, structure, dual-approach style, and comments — is genuinely well done.
*/