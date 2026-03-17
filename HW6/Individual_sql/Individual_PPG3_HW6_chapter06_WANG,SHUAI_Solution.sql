---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 06 - Set Operators
-- Itzik Ben-Gan
---------------------------------------------------------------------

SET NOCOUNT ON;
USE Northwinds2024Student;
GO

---------------------------------------------------------------------
-- The UNION Operator
---------------------------------------------------------------------

-- The UNION ALL Multiset Operator
SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee

UNION ALL

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

-- The UNION Distinct Set Operator
SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee

UNION

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

---------------------------------------------------------------------
-- The INTERSECT Operator
---------------------------------------------------------------------

-- The INTERSECT Distinct Set Operator
SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee

INTERSECT

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

-- The INTERSECT ALL Multiset Operator (Optional, Advanced)
SELECT 
    ROW_NUMBER() OVER
    (
        PARTITION BY EmployeeCountry, EmployeeRegion, EmployeeCity
        ORDER BY (SELECT 0)
    ) AS rownum,
    EmployeeCountry AS country,
    EmployeeRegion  AS region,
    EmployeeCity    AS city
FROM HumanResources.Employee

INTERSECT

SELECT 
    ROW_NUMBER() OVER
    (
        PARTITION BY CustomerCountry, CustomerRegion, CustomerCity
        ORDER BY (SELECT 0)
    ) AS rownum,
    CustomerCountry AS country,
    CustomerRegion  AS region,
    CustomerCity    AS city
FROM Sales.Customer;
GO

WITH INTERSECT_ALL AS
(
    SELECT 
        ROW_NUMBER() OVER
        (
            PARTITION BY EmployeeCountry, EmployeeRegion, EmployeeCity
            ORDER BY (SELECT 0)
        ) AS rownum,
        EmployeeCountry AS country,
        EmployeeRegion  AS region,
        EmployeeCity    AS city
    FROM HumanResources.Employee

    INTERSECT

    SELECT 
        ROW_NUMBER() OVER
        (
            PARTITION BY CustomerCountry, CustomerRegion, CustomerCity
            ORDER BY (SELECT 0)
        ) AS rownum,
        CustomerCountry AS country,
        CustomerRegion  AS region,
        CustomerCity    AS city
    FROM Sales.Customer
)
SELECT country, region, city
FROM INTERSECT_ALL;
GO

---------------------------------------------------------------------
-- The EXCEPT Operator
---------------------------------------------------------------------

-- The EXCEPT Distinct Set Operator

-- Employees EXCEPT Customers
SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee

EXCEPT

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

-- Customers EXCEPT Employees
SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer

EXCEPT

SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee;
GO

-- The EXCEPT ALL Multiset Operator (Optional, Advanced)
WITH EXCEPT_ALL AS
(
    SELECT 
        ROW_NUMBER() OVER
        (
            PARTITION BY EmployeeCountry, EmployeeRegion, EmployeeCity
            ORDER BY (SELECT 0)
        ) AS rownum,
        EmployeeCountry AS country,
        EmployeeRegion  AS region,
        EmployeeCity    AS city
    FROM HumanResources.Employee

    EXCEPT

    SELECT 
        ROW_NUMBER() OVER
        (
            PARTITION BY CustomerCountry, CustomerRegion, CustomerCity
            ORDER BY (SELECT 0)
        ) AS rownum,
        CustomerCountry AS country,
        CustomerRegion  AS region,
        CustomerCity    AS city
    FROM Sales.Customer
)
SELECT country, region, city
FROM EXCEPT_ALL;
GO

---------------------------------------------------------------------
-- Precedence
---------------------------------------------------------------------

-- INTERSECT precedes EXCEPT
SELECT SupplierCountry AS country,
       SupplierRegion  AS region,
       SupplierCity    AS city
FROM Production.Supplier

EXCEPT

SELECT EmployeeCountry AS country,
       EmployeeRegion  AS region,
       EmployeeCity    AS city
FROM HumanResources.Employee

INTERSECT

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

-- Using Parenthesis
(
    SELECT SupplierCountry AS country,
           SupplierRegion  AS region,
           SupplierCity    AS city
    FROM Production.Supplier

    EXCEPT

    SELECT EmployeeCountry AS country,
           EmployeeRegion  AS region,
           EmployeeCity    AS city
    FROM HumanResources.Employee
)

INTERSECT

SELECT CustomerCountry AS country,
       CustomerRegion  AS region,
       CustomerCity    AS city
FROM Sales.Customer;
GO

---------------------------------------------------------------------
-- Circumventing Unsupported Logical Phases
-- (Optional, Advanced)
---------------------------------------------------------------------

-- Number of distinct locations
-- that are either employee or customer locations in each country
SELECT country, COUNT(*) AS numlocations
FROM
(
    SELECT EmployeeCountry AS country,
           EmployeeRegion  AS region,
           EmployeeCity    AS city
    FROM HumanResources.Employee

    UNION

    SELECT CustomerCountry AS country,
           CustomerRegion  AS region,
           CustomerCity    AS city
    FROM Sales.Customer
) AS U
GROUP BY country;
GO

-- Two most recent orders for employees 3 and 5
-- Two most recent orders for employees 3 and 5
SELECT country, COUNT(*) AS numlocations
FROM
(
    SELECT EmployeeCountry AS country,
           EmployeeRegion  AS region,
           EmployeeCity    AS city
    FROM HumanResources.Employee

    UNION

    SELECT CustomerCountry AS country,
           CustomerRegion  AS region,
           CustomerCity    AS city
    FROM Sales.Customer
) AS U
GROUP BY country;
GO

-- Two most recent orders for employees 3 and 5
SELECT EmployeeId, OrderId, OrderDate
FROM
(
    SELECT TOP (2) EmployeeId, OrderId, OrderDate
    FROM Sales.[Order]
    WHERE EmployeeId = 3
    ORDER BY OrderDate DESC, OrderId DESC
) AS D1

UNION ALL

SELECT EmployeeId, OrderId, OrderDate
FROM
(
    SELECT TOP (2) EmployeeId, OrderId, OrderDate
    FROM Sales.[Order]
    WHERE EmployeeId = 5
    ORDER BY OrderDate DESC, OrderId DESC
) AS D2;
GO

