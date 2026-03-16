---------------------------------------------------------------------
-- Chapter 6 - Set Operators
-- Student: Simran Singh
---------------------------------------------------------------------


-- Question 1
-- Difference between UNION and UNION ALL

-- UNION combines results from two queries and removes duplicate rows.
-- UNION ALL also combines results but it keeps all rows even if they repeat.

-- They would give the same result if both queries return completely different rows
-- and there are no duplicates between them.

-- If both give same result then UNION ALL is usually better
-- because SQL does not need to check duplicates which may take extra time.



-- Question 2
-- Create a virtual table with numbers from 1 to 10

SELECT n
FROM (VALUES
(1),(2),(3),(4),(5),
(6),(7),(8),(9),(10)
) AS Numbers(n);

-- This just creates numbers manually.
-- There are other ways to do it but this one is simple.



-- Question 3
-- Customer and employee pairs that made orders in January 2016
-- but not in February 2016

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-01-01'
AND orderdate < '2016-02-01'

EXCEPT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-02-01'
AND orderdate < '2016-03-01';

-- EXCEPT basically removes rows that appear in the second query.
-- So this leaves only January pairs that are not in February.



-- Question 4
-- Pairs that had orders in BOTH January and February

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-01-01'
AND orderdate < '2016-02-01'

INTERSECT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-02-01'
AND orderdate < '2016-03-01';

-- INTERSECT returns only rows that appear in both queries.
-- So these customers worked with the same employee in both months.



-- Question 5
-- Pairs that had activity in Jan and Feb 2016
-- but not any activity in 2015

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-01-01'
AND orderdate < '2016-02-01'

INTERSECT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2016-02-01'
AND orderdate < '2016-03-01'

EXCEPT

SELECT CustomerId, EmployeeId
FROM Sales.[Order]
WHERE orderdate >= '2015-01-01'
AND orderdate < '2016-01-01';

-- First we find pairs active in both months.
-- Then EXCEPT removes anyone who already had orders in 2015.
-- I think this works but there may be other ways to write it too.



-- Question 6
-- Show employees first and suppliers second
-- Then sort them by country, region and city

SELECT EmployeeCountry AS country,
       EmployeeRegion AS region,
       EmployeeCity AS city
FROM (
    
    -- Employees part
    SELECT 1 AS grp,
           EmployeeCountry,
           EmployeeRegion,
           EmployeeCity
    FROM HumanResources.Employee

    UNION ALL

    -- Suppliers part
    SELECT 2 AS grp,
           SupplierCountry,
           SupplierRegion,
           SupplierCity
    FROM Production.Supplier

) AS combined

ORDER BY grp, country, region, city;