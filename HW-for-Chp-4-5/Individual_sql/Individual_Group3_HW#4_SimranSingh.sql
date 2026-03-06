-- Simran Singh
-- CSCI 331
-- Chapter 4 Exercises:

/*
1) Write a query that returns all orders placed on the last day of
-- activity that can be found in the Orders table
-- Tables involved: TSQLV4 database, Orders table
-- Tavles involved in Northwinds2024: sales.order */

-- Selecting specific columns we wnat to display for this query
SELECT CustomerId,OrderId,OrderDate, EmployeeId
-- getting the data from sales.order table
FROM sales.[Order]
-- so we are flitering the rows so we only keep orders from the latest order date
-- The subquery finds the maximum (latest) orderdate in the table
WHERE OrderDate = (SELECT MAX(OrderDate) FROM sales.[Order] )

/* 2) Orders from customer(s) with the highest number of orders*/

-- Selecting the columns we want to display
SELECT CustomerId,OrderId,OrderDate, EmployeeId
-- Use Orders table and give it alias "o" for refrense 
FROM Sales.[Order] AS o 
-- Filter orders where the customer id appears in the subquery result
WHERE o.CustomerId IN
(
    -- Find the customer(s) who placed the most orders
    SELECT TOP (1) WITH TIES CustomerId
    -- TOP(1): returns top customer 
    -- WITH TIES: if the multiple customers have the same higest number, include them 

    -- Look at all orders
    FROM sales.[Order]

    -- Group rows by customer
    GROUP BY CustomerId

    -- Sort customers by number of orders (highest first)
    ORDER BY COUNT(*) DESC
)

-- Sort the final output by customer and order id
ORDER BY o.CustomerId, o.orderid;

-- Exercise 3
-- Return employees who did not handle orders on or after May 1, 2016
SELECT e.EmployeeId, e.EmployeeFirstName, e.EmployeeLastName
FROM HumanResources.Employee AS e
-- employees who did not appear in orders after the May 1, 2016
WHERE e.EmployeeId NOT IN 
(
    -- this is subquery for excluding for employees who did not apear 
    SELECT o.EmployeeId 
    FROM Sales.[Order] as o
    WHERE o.OrderDate >= '2016-05-01'
)
-- Sort by employee id
ORDER BY e.EmployeeId


-- Exercise 4
-- Return countries that exist in the Customer table
-- but do not appear in the Employee table

-- Select distinct (unique) customer countries
SELECT DISTINCT c.CustomerCountry
-- Read from Customer table
FROM Sales.Customer AS c
-- Keep countries that are NOT in the employee country list
WHERE c.CustomerCountry NOT IN
(
    -- Subquery returns all countries that employees are from
    SELECT e.EmployeeCountry
    FROM HumanResources.Employee AS e
)
-- Sort alphabetically
ORDER BY c.CustomerCountry;


-- Exercise 5
-- For each customer, find their most recent order date
-- Then return the orders from that date

-- Show customer id, order id, order date, and employee id
SELECT o.CustomerId, o.OrderId, o.OrderDate, o.EmployeeId

-- Get data from the Orders table
FROM Sales.[Order] AS o

-- Keep rows where the order date equals the latest order date for that customer
WHERE o.OrderDate =
(
    -- This subquery finds the latest order date for that specific customer
    SELECT MAX(o2.OrderDate)
    FROM Sales.[Order] AS o2

    -- Make sure we compare orders from the same customer
    WHERE o2.CustomerId = o.CustomerId
)

-- Sort by customer and order id
ORDER BY o.CustomerId, o.OrderDate;


-- Exercise 6
-- This query finds customers who ordered in 2015 but did NOT order in 2016

-- Show customer id and company name
SELECT c.CustomerId, c.CustomerCompanyName

-- Get data from the Customer table
FROM Sales.Customer AS c

-- Keep customers who appear in orders from 2015
WHERE c.CustomerId IN
(
    -- Subquery finds customers who placed orders in 2015
    SELECT o.CustomerId
    FROM Sales.[Order] AS o
    WHERE YEAR(o.OrderDate) = 2015
)

-- Remove customers who also placed orders in 2016
AND c.CustomerId NOT IN
(
    -- Subquery finds customers who placed orders in 2016
    SELECT o.CustomerId
    FROM Sales.[Order] AS o
    WHERE YEAR(o.OrderDate) = 2016
)

-- Sort by customer id
ORDER BY c.CustomerId;


-- Exercise 7
-- This query finds customers who ordered product with id = 12

-- Select unique customers
SELECT DISTINCT c.CustomerId, c.CustomerCompanyName

-- Get data from the Customer table
FROM Sales.Customer AS c

-- Keep customers who appear in the orders containing product 12
WHERE c.CustomerId IN
(
    -- Subquery finds customers who made orders
    SELECT o.CustomerId
    FROM Sales.[Order] AS o

    -- Only include orders that contain product 12
    WHERE o.orderid IN
    (
        -- This subquery finds order ids where product 12 was ordered
        SELECT od.orderid
        FROM Sales.OrderDetail AS od
        WHERE od.productid = 12
    )
)

-- Sort results by customer id
ORDER BY c.CustomerId;



-- Chapter 5 Exercises:
-- =========================================================
-- Exercise 1
-- The following query attempts to filter orders placed
-- on the last day of the year.
-- Explain why the query produces an error and fix it.
-- =========================================================



SELECT
    orderid,                         -- show order id
    orderdate,                       -- show order date
    CustomerId,                          -- show customer id
    EmployeeId,                           -- show employee id
    DATEFROMPARTS(YEAR(orderdate),12,31) AS endofyear -- create last day of that year
FROM Sales.[Order]                   -- read data from orders table
WHERE orderdate <> DATEFROMPARTS(YEAR(orderdate),12,31);
-- we repeat the formula because SQL cannot use SELECT aliases in WHERE


-- =========================================================
-- Exercise 2-1
-- Write a query that returns the maximum order date
-- for each employee.
-- =========================================================

SELECT
    EmployeeId,                           -- employee who made the order
    MAX(orderdate) AS maxorderdate   -- latest order date for that employee
FROM Sales.[Order]                   -- get data from orders table
GROUP BY EmployeeId;                      -- group rows by employee

-- =========================================================
-- Exercise 2-2
-- Encapsulate the query from exercise 2-1 in a derived table.
-- Join it with Sales.Order to return the orders that happened
-- on the maximum order date for each employee.
-- =========================================================

SELECT
    O.EmployeeId,                   -- employee id
    O.orderdate,               -- order date
    O.orderid,                 -- order id
    O.CustomerId                   -- customer id
FROM Sales.[Order] AS O        -- main orders table
JOIN
(
    SELECT
        EmployeeId,                          -- employee id
        MAX(Orderdate) AS maxorderdate  -- latest order date
    FROM Sales.[Order]                  -- orders table
    GROUP BY EmployeeId                      -- group by employee
) AS D                                  -- derived table result
ON O.EmployeeId = D.EmployeeId                    -- match employee ids
AND O.OrderDate = D.maxOrderDate        -- keep rows with max order date
ORDER BY O.EmployeeId, O.orderid;            -- sort results


-- =========================================================
-- Exercise 3-1
-- Write a query that calculates a row number for each order
-- based on orderdate and orderid ordering.
-- =========================================================

SELECT
    orderid,                                    -- order id
    orderdate,                                  -- order date
    CustomerId,                                     -- customer id
    EmployeeId,                                      -- employee id
    ROW_NUMBER() OVER(ORDER BY orderdate,orderid) AS rownum
    -- assign row numbers based on order date then order id
FROM Sales.[Order];                              -- orders table


-- =========================================================
-- Exercise 3-2
-- Write a query that returns rows with row numbers 11–20
-- using a CTE to encapsulate the query from exercise 3-1.
-- =========================================================


WITH OrdersWithNums AS
(
    SELECT
        orderid,                                  -- order id
        orderdate,                                -- order date
        CustomerId,                                   -- customer id
        EmployeeId,                                    -- employee id
        ROW_NUMBER() OVER(ORDER BY orderdate,orderid) AS rownum
        -- create row numbers
    FROM Sales.[Order]                            -- orders table
)

SELECT
    orderid,                -- order id
    orderdate,              -- order date
    CustomerId,                 -- customer id
    EmployeeId,                  -- employee id
    rownum                  -- row number
FROM OrdersWithNums         -- use the CTE
WHERE rownum BETWEEN 11 AND 20 -- only keep rows 11 through 20
ORDER BY rownum;

-- =========================================================
-- Exercise 4
-- Write a recursive CTE that returns the management chain
-- leading to Patricia Doyle (employee id 9).
-- =========================================================

WITH EmpChain AS
(
    SELECT
        EmployeeId,                    -- employee id
        EmployeeManagerId,                    -- manager id
        EmployeeFirstName,                -- first name
        EmployeeLastName                  -- last name
    FROM HumanResources.Employee
    WHERE EmployeeId = 9               -- start from Patricia

    UNION ALL

    SELECT
        E.EmployeeId,                  -- manager id
        E.EmployeeManagerId,                  -- manager's manager
        E.EmployeeFirstName,
        E.EmployeeLastName
    FROM HumanResources.Employee E
    JOIN EmpChain C
        ON E.EmployeeId = C.EmployeeManagerId      -- find manager of previous employee
)

SELECT
    EmployeeId,
    EmployeeManagerId,
    EmployeeFirstName,
    EmployeeLastName
FROM EmpChain;


-- =========================================================
-- Exercise 5-1
-- Create a view that returns the total quantity
-- for each employee and year using Sales.Order
-- and Sales.OrderDetail tables.
-- =========================================================
GO
CREATE OR ALTER VIEW Sales.VEmpOrders
AS

SELECT
    O.EmployeeId,                          -- employee who handled the order
    YEAR(O.orderdate) AS orderyear,   -- extract year from order date
    SUM(OD.Quantity) AS qty                -- total quantity sold
FROM Sales.[Order] O                  -- orders table
JOIN Sales.OrderDetail OD             -- order details table
ON OD.orderid = O.orderid             -- connect order detail to order
GROUP BY
    O.EmployeeId,
    YEAR(O.orderdate);
GO

-- =========================================================
-- Exercise 5-2
-- Write a query against Sales.VEmpOrders that returns
-- the running quantity for each employee and year.
-- =========================================================
GO

SELECT
    EmployeeId,
    orderyear,
    qty,

    SUM(qty) OVER(
        PARTITION BY EmployeeId
        ORDER BY Orderyear
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS runqty

FROM Sales.VEmpOrders
ORDER BY EmployeeId, orderyear;

-- =========================================================
-- Exercise 6-1
-- Create an inline function that accepts a supplier id
-- and a number of products and returns the N most expensive
-- products supplied by that supplier.
-- =========================================================

GO

CREATE OR ALTER FUNCTION Production.TopProducts
(
    @supid INT,
    @n INT
)

RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@n)
        Productid,
        productname,
        unitprice
    FROM Production.Product
    WHERE supplierid = @supid
    ORDER BY unitprice DESC
);
GO

-- =========================================================
-- Exercise 6-1
-- Create an inline function that accepts a supplier id
-- and a number of products and returns the N most expensive
-- products supplied by that supplier.
-- =========================================================


GO

CREATE OR ALTER FUNCTION Production.TopProducts
(
    @supid INT,
    @n INT
)

RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@n)
        productid,
        productname,
        unitprice
    FROM Production.Product
    WHERE supplierid = @supid
    ORDER BY unitprice DESC
);
GO


-- =========================================================
-- Cleanup after finishing the exercises
-- =========================================================

DROP VIEW IF EXISTS Sales.VEmpOrders;
GO

DROP FUNCTION IF EXISTS Production.TopProducts;
GO
