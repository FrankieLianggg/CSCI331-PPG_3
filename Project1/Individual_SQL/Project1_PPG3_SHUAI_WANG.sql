USE Northwinds2024Student;
GO

--Question 1: Provide a table containing OrderID, OrderTime (specifically for July 2014), and Quantity.

SELECT 
    O.OrderId   AS OrderID,
    O.OrderDate AS OrderTime,
    OD.Quantity
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
WHERE O.OrderDate >= '20140701'
  AND O.OrderDate <  '20140801';


--Quesation2: Make table shows ude mutiply table:
--which employee handled the order
--which customer placed it
--which product was ordered
--which supplier provides that product

SELECT
    T1.EmployeeId,
    T1.EmployeeName,
    T1.StartDate,
    T2.CustomerId,
    T2.CustomerName,
    T3.SupplierName,
    T3.ProductName
FROM
(
    SELECT
        E.EmployeeId,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName,
        E.HireDate AS StartDate
    FROM dbo.Employees AS E
) AS T1
JOIN dbo.Orders AS O
    ON T1.EmployeeId = O.EmployeeId
JOIN
(
    SELECT
        C.CustomerId,
        C.CustomerCompanyName AS CustomerName
    FROM dbo.Customers AS C
) AS T2
    ON O.CustomerId = T2.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN
(
    SELECT
        S.SupplierId,
        S.SupplierCompanyName AS SupplierName,
        P.ProductId,
        P.ProductName
    FROM Production.Supplier AS S
    JOIN Production.Product AS P
        ON S.SupplierId = P.SupplierId
) AS T3
    ON P.ProductId = T3.ProductId;

USE Northwinds2024Student;
GO

USE Northwinds2024Student;
GO

--Quesation3: Make a table is to show sales-related product information in one result by combining discount, product, supplier, and profit details.

WITH SalesInfo AS
(
    SELECT
        OD.DiscountPercentage AS Discount,
        P.ProductName,
        (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS Profit,
        DATENAME(MONTH, O.OrderDate) AS OrderMonth
    FROM dbo.Orders AS O
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    JOIN Production.Product AS P
        ON OD.ProductId = P.ProductId
)

(
    SELECT Discount, ProductName, Profit, OrderMonth
    FROM SalesInfo
    WHERE Discount > 0

    INTERSECT

    SELECT Discount, ProductName, Profit, OrderMonth
    FROM SalesInfo
    WHERE Profit > 100
)

UNION

SELECT Discount, ProductName, Profit, OrderMonth
FROM SalesInfo
WHERE OrderMonth = 'July';


USE Northwinds2024Student;
GO

-- Question 4:
-- Create a view summarizing products and their sales activity,
-- showing only products with high total sales.

DROP VIEW IF EXISTS dbo.vw_ProductOrderSummary;
GO

CREATE VIEW dbo.vw_ProductOrderSummary
WITH SCHEMABINDING
AS
SELECT
    P.ProductId,
    P.ProductName,
    COUNT_BIG(*) AS OrderLineCount,
    SUM(OD.Quantity) AS TotalQuantity
FROM Production.Product AS P
JOIN dbo.OrderDetails AS OD
    ON P.ProductId = OD.ProductId
GROUP BY
    P.ProductId,
    P.ProductName
HAVING SUM(OD.Quantity) > 100;
GO

-- Question 5:
-- Rank employees by the number of July 2014 orders they handled.

DROP VIEW IF EXISTS dbo.vw_ProductOrderSummary;
GO

CREATE VIEW dbo.vw_ProductOrderSummary
AS
SELECT
    P.ProductId,
    P.ProductName,
    COUNT_BIG(*) AS OrderLineCount,
    SUM(OD.Quantity) AS TotalQuantity
FROM Production.Product AS P
JOIN dbo.OrderDetails AS OD
    ON P.ProductId = OD.ProductId
GROUP BY
    P.ProductId,
    P.ProductName
HAVING SUM(OD.Quantity) > 100;
GO

-- Question 6:
-- Show customers whose total July quantity is unusually high.

SELECT
    C.CustomerId,
    C.CustomerCompanyName AS CustomerName,
    SUM(OD.Quantity) AS TotalJulyQuantity,
    COUNT(DISTINCT O.OrderId) AS NumberOfOrders
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
WHERE O.OrderDate >= '20140701'
  AND O.OrderDate <  '20140801'
GROUP BY
    C.CustomerId,
    C.CustomerCompanyName
HAVING SUM(OD.Quantity) >= 100
ORDER BY TotalJulyQuantity DESC, CustomerName;
GO

-- Question 7:
-- Show July order lines with significant discounts.

SELECT
    O.OrderId,
    O.OrderDate,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName,
    C.CustomerCompanyName AS CustomerName,
    P.ProductName,
    OD.Quantity,
    OD.UnitPrice,
    OD.DiscountPercentage,
    (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN dbo.Employees AS E
    ON O.EmployeeId = E.EmployeeId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
WHERE O.OrderDate >= '20140701'
  AND O.OrderDate <  '20140801'
  AND COALESCE(OD.DiscountPercentage, 0) >= 10
ORDER BY OD.DiscountPercentage DESC, NetValue DESC;
GO

-- Question 8:
-- Find products that are both high-volume and profitable.

WITH ProductProfit AS
(
    SELECT
        P.ProductId,
        P.ProductName,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalProfit
    FROM Production.Product AS P
    JOIN dbo.OrderDetails AS OD
        ON P.ProductId = OD.ProductId
    JOIN dbo.Orders AS O
        ON OD.OrderId = O.OrderId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY
        P.ProductId,
        P.ProductName
)
SELECT
    V.ProductId,
    V.ProductName,
    V.OrderLineCount,
    V.TotalQuantity,
    PP.TotalProfit
FROM dbo.vw_ProductOrderSummary AS V
JOIN ProductProfit AS PP
    ON V.ProductId = PP.ProductId
WHERE PP.TotalProfit > 500
ORDER BY PP.TotalProfit DESC, V.TotalQuantity DESC;
GO

-- Question 9:
-- Use earlier clues to build a suspect list of suspicious July order lines.

WITH BusyEmployees AS
(
    SELECT
        O.EmployeeId,
        COUNT(DISTINCT O.OrderId) AS JulyOrderCount
    FROM dbo.Orders AS O
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY O.EmployeeId
),
HeavyCustomers AS
(
    SELECT
        O.CustomerId,
        SUM(OD.Quantity) AS TotalJulyQuantity
    FROM dbo.Orders AS O
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY O.CustomerId
    HAVING SUM(OD.Quantity) >= 100
),
ProfitableProducts AS
(
    SELECT
        OD.ProductId,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalProfit
    FROM dbo.OrderDetails AS OD
    JOIN dbo.Orders AS O
        ON OD.OrderId = O.OrderId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY OD.ProductId
    HAVING SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) > 500
)
SELECT
    O.OrderId,
    O.OrderDate,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName,
    C.CustomerCompanyName AS CustomerName,
    P.ProductName,
    S.SupplierCompanyName AS SupplierName,
    OD.Quantity,
    OD.DiscountPercentage,
    (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN dbo.Employees AS E
    ON O.EmployeeId = E.EmployeeId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN Production.Supplier AS S
    ON P.SupplierId = S.SupplierId
JOIN dbo.vw_ProductOrderSummary AS V
    ON OD.ProductId = V.ProductId
JOIN BusyEmployees AS BE
    ON O.EmployeeId = BE.EmployeeId
JOIN HeavyCustomers AS HC
    ON O.CustomerId = HC.CustomerId
JOIN ProfitableProducts AS PP
    ON OD.ProductId = PP.ProductId
WHERE O.OrderDate >= '20140701'
  AND O.OrderDate <  '20140801'
  AND COALESCE(OD.DiscountPercentage, 0) > 0
ORDER BY NetValue DESC, OD.Quantity DESC;
GO


-- Question 10:
-- Final SQLNOIR reveal: identify the prime suspects using a combined suspicion score.
--Mystery prompt:
--This is the final reveal. Combine the earlier clues into one final suspect score. A line becomes more suspicious when it has several indicators at once:

--handled by a busy employee
--placed by a heavy customer
--involves a high-volume product
--has a discount
--generates strong profit

WITH BusyEmployees AS
(
    SELECT
        O.EmployeeId,
        COUNT(DISTINCT O.OrderId) AS JulyOrderCount
    FROM dbo.Orders AS O
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY O.EmployeeId
),
HeavyCustomers AS
(
    SELECT
        O.CustomerId,
        SUM(OD.Quantity) AS TotalJulyQuantity
    FROM dbo.Orders AS O
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY O.CustomerId
),
ProductProfit AS
(
    SELECT
        OD.ProductId,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalProfit
    FROM dbo.OrderDetails AS OD
    JOIN dbo.Orders AS O
        ON OD.OrderId = O.OrderId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
    GROUP BY OD.ProductId
),
FinalClues AS
(
    SELECT
        O.OrderId,
        O.OrderDate,
        E.EmployeeId,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName AS EmployeeName,
        C.CustomerId,
        C.CustomerCompanyName AS CustomerName,
        P.ProductId,
        P.ProductName,
        S.SupplierCompanyName AS SupplierName,
        OD.Quantity,
        COALESCE(OD.DiscountPercentage, 0) AS DiscountPercentage,
        (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue,
        BE.JulyOrderCount,
        HC.TotalJulyQuantity,
        V.TotalQuantity AS ProductTotalQuantity,
        PP.TotalProfit,
        CASE WHEN BE.JulyOrderCount >= 5 THEN 1 ELSE 0 END +
        CASE WHEN HC.TotalJulyQuantity >= 100 THEN 1 ELSE 0 END +
        CASE WHEN V.TotalQuantity >= 100 THEN 1 ELSE 0 END +
        CASE WHEN COALESCE(OD.DiscountPercentage, 0) >= 10 THEN 1 ELSE 0 END +
        CASE WHEN PP.TotalProfit >= 500 THEN 1 ELSE 0 END AS SuspicionScore
    FROM dbo.Orders AS O
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    JOIN dbo.Employees AS E
        ON O.EmployeeId = E.EmployeeId
    JOIN dbo.Customers AS C
        ON O.CustomerId = C.CustomerId
    JOIN Production.Product AS P
        ON OD.ProductId = P.ProductId
    JOIN Production.Supplier AS S
        ON P.SupplierId = S.SupplierId
    JOIN BusyEmployees AS BE
        ON O.EmployeeId = BE.EmployeeId
    JOIN HeavyCustomers AS HC
        ON O.CustomerId = HC.CustomerId
    JOIN dbo.vw_ProductOrderSummary AS V
        ON OD.ProductId = V.ProductId
    JOIN ProductProfit AS PP
        ON OD.ProductId = PP.ProductId
    WHERE O.OrderDate >= '20140701'
      AND O.OrderDate <  '20140801'
)
SELECT
    OrderId,
    OrderDate,
    EmployeeName,
    CustomerName,
    ProductName,
    SupplierName,
    Quantity,
    DiscountPercentage,
    NetValue,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, NetValue DESC) AS SuspicionRank
FROM FinalClues
WHERE SuspicionScore >= 3
ORDER BY SuspicionRank, NetValue DESC, OrderId;
GO
