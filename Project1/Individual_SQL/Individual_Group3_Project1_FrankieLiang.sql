---------------------------------------------------------------------
-- SQL Gamification Project Specification
-- Project 1
-- Exercises
-- Frankie Liang
---------------------------------------------------------------------
USE Northwinds2024Student;
GO

-- ==============================================================
-- MYSTERY 1: "THE VANISHING VINTNER"
-- ==============================================================
-- A warehouse manager suspects a sales rep has been moving an
-- unusual volume of beverage products off the books. Your job:
-- follow the order trail and find who handled the most units
-- across the entire order history.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Find all products supplied by each vendor and how many
--       total units have been ordered across all time.
--       High-volume products are the first thread to pull.
-- --------------------------------------------------------------

SELECT
    S.SupplierCompanyName                                               AS SupplierName,
    P.ProductName,
    SUM(OD.Quantity)                                                    AS TotalUnitsOrdered,
    COUNT(DISTINCT O.OrderId)                                           AS OrderCount
FROM Production.Supplier AS S
JOIN Production.Product AS P
    ON S.SupplierId = P.SupplierId
JOIN dbo.OrderDetails AS OD
    ON P.ProductId = OD.ProductId
JOIN dbo.Orders AS O
    ON OD.OrderId = O.OrderId
GROUP BY
    S.SupplierCompanyName,
    P.ProductName
HAVING SUM(OD.Quantity) > 100
ORDER BY TotalUnitsOrdered DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Which employees handled orders for the highest-volume
--       products? Link employees to products through orders.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    P.ProductName,
    S.SupplierCompanyName                                               AS SupplierName,
    COUNT(DISTINCT O.OrderId)                                           AS OrdersHandled,
    SUM(OD.Quantity)                                                    AS TotalUnits
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN Production.Supplier AS S
    ON P.SupplierId = S.SupplierId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName,
    P.ProductName,
    S.SupplierCompanyName
HAVING SUM(OD.Quantity) > 100
ORDER BY TotalUnits DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: For the products flagged in Section 2, identify which
--       customers are receiving those large shipments and
--       whether significant discounts are involved.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    C.CustomerCompanyName                                               AS CustomerName,
    P.ProductName,
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
WHERE COALESCE(OD.DiscountPercentage, 0) > 0
  AND OD.Quantity > 50
ORDER BY OD.Quantity DESC, OD.DiscountPercentage DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Combine all clues: find the employee-customer-product
-- combination with the highest total discounted volume.
-- The top result is the Vanishing Vintner suspect.
-- --------------------------------------------------------------

WITH HighVolumeProducts AS
(
    SELECT
        OD.ProductId,
        SUM(OD.Quantity)                                                AS TotalUnits
    FROM dbo.OrderDetails AS OD
    GROUP BY OD.ProductId
    HAVING SUM(OD.Quantity) > 100
),
DiscountedSales AS
(
    SELECT
        O.OrderId,
        O.OrderDate,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        C.CustomerCompanyName                                           AS CustomerName,
        P.ProductName,
        S.SupplierCompanyName                                           AS SupplierName,
        OD.Quantity,
        COALESCE(OD.DiscountPercentage, 0)                             AS DiscountPercentage,
        (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue,
        HVP.TotalUnits                                                  AS ProductTotalUnits
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
    JOIN HighVolumeProducts AS HVP
        ON OD.ProductId = HVP.ProductId
    WHERE COALESCE(OD.DiscountPercentage, 0) > 0
),
SuspectScore AS
(
    SELECT
        EmployeeName,
        CustomerName,
        ProductName,
        SupplierName,
        COUNT(DISTINCT OrderId)                                         AS OrderCount,
        SUM(Quantity)                                                   AS TotalUnits,
        SUM(NetValue)                                                   AS TotalNetValue,
        CASE WHEN SUM(Quantity) >= 200 THEN 1 ELSE 0 END +
        CASE WHEN COUNT(DISTINCT OrderId) >= 5 THEN 1 ELSE 0 END +
        CASE WHEN SUM(NetValue) >= 1000 THEN 1 ELSE 0 END             AS SuspicionScore
    FROM DiscountedSales
    GROUP BY
        EmployeeName,
        CustomerName,
        ProductName,
        SupplierName
)
SELECT
    EmployeeName,
    CustomerName,
    ProductName,
    SupplierName,
    OrderCount,
    TotalUnits,
    TotalNetValue,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalUnits DESC)  AS SuspicionRank
FROM SuspectScore
WHERE SuspicionScore >= 2
ORDER BY SuspicionRank, TotalNetValue DESC;
GO


-- ==============================================================
-- MYSTERY 2: "THE GHOST CUSTOMER"
-- ==============================================================
-- Revenue totals do not match what customer accounts report.
-- One or more customers are placing orders but never appear
-- in regional sales summaries. Find who is flying under the
-- radar and how much they account for.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: List every customer, their total orders, and total
--       revenue. Customers with high volume but low order
--       counts stand out as suspicious.
-- --------------------------------------------------------------

SELECT
    C.CustomerId,
    C.CustomerCompanyName                                               AS CustomerName,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders,
    SUM(OD.Quantity)                                                    AS TotalUnits,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    C.CustomerId,
    C.CustomerCompanyName
ORDER BY TotalRevenue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Which customers place orders but have unusually few
--       distinct products? A real account buys variety.
--       A ghost account buys only specific items.
-- --------------------------------------------------------------

SELECT
    C.CustomerCompanyName                                               AS CustomerName,
    COUNT(DISTINCT O.OrderId)                                           AS OrderCount,
    COUNT(DISTINCT OD.ProductId)                                        AS UniqueProducts,
    SUM(OD.Quantity)                                                    AS TotalQuantity
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    C.CustomerId,
    C.CustomerCompanyName
HAVING COUNT(DISTINCT OD.ProductId) <= 3
   AND COUNT(DISTINCT O.OrderId) >= 5
ORDER BY OrderCount DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Check which employees are processing orders for the
--       narrowest customer base. A rep with only 1-2 customers
--       generating large revenue needs scrutiny.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    COUNT(DISTINCT O.CustomerId)                                        AS UniqueCustomers,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY UniqueCustomers ASC, TotalRevenue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Find the customer generating disproportionate revenue through
-- a very narrow product set, handled by a single employee.
-- --------------------------------------------------------------

WITH CustomerProfile AS
(
    SELECT
        C.CustomerId,
        C.CustomerCompanyName                                           AS CustomerName,
        COUNT(DISTINCT O.OrderId)                                       AS OrderCount,
        COUNT(DISTINCT OD.ProductId)                                    AS UniqueProducts,
        SUM(OD.Quantity)                                                AS TotalUnits,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
    FROM dbo.Customers AS C
    JOIN dbo.Orders AS O
        ON C.CustomerId = O.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        C.CustomerId,
        C.CustomerCompanyName
),
EmployeeCustomerLink AS
(
    SELECT
        O.CustomerId,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS HandlingEmployee,
        COUNT(DISTINCT O.OrderId)                                       AS OrdersHandled
    FROM dbo.Orders AS O
    JOIN dbo.Employees AS E
        ON O.EmployeeId = E.EmployeeId
    GROUP BY
        O.CustomerId,
        E.EmployeeFirstName,
        E.EmployeeLastName
),
TopEmployee AS
(
    SELECT
        CustomerId,
        HandlingEmployee,
        OrdersHandled,
        DENSE_RANK() OVER (ORDER BY OrdersHandled DESC)                 AS EmployeeRank
    FROM EmployeeCustomerLink
)
SELECT
    CP.CustomerName,
    CP.OrderCount,
    CP.UniqueProducts,
    CP.TotalUnits,
    CP.TotalRevenue,
    TE.HandlingEmployee,
    CASE WHEN CP.UniqueProducts <= 3 THEN 1 ELSE 0 END +
    CASE WHEN CP.TotalRevenue >= 10000 THEN 1 ELSE 0 END +
    CASE WHEN CP.OrderCount >= 10 THEN 1 ELSE 0 END                    AS SuspicionScore,
    DENSE_RANK() OVER (ORDER BY CP.TotalRevenue DESC)                  AS RevenueRank
FROM CustomerProfile AS CP
JOIN TopEmployee AS TE
    ON CP.CustomerId = TE.CustomerId
WHERE TE.EmployeeRank <= 3
ORDER BY SuspicionScore DESC, CP.TotalRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 3: "THE DISCOUNT CONSPIRACY"
-- ==============================================================
-- Accounting flagged a pattern: certain order lines receive
-- discounts just below the approval threshold (10%). Someone
-- is systematically applying 5-9% discounts to large orders
-- to avoid triggering a review. Find the pattern and the rep.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Profile discount usage across all employees.
--       Who gives the most discounts, and what is the
--       average discount they apply?
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders,
    COUNT(DISTINCT CASE WHEN COALESCE(OD.DiscountPercentage, 0) > 0
                        THEN O.OrderId END)                             AS DiscountedOrders,
    SUM(CASE WHEN COALESCE(OD.DiscountPercentage, 0) > 0
             THEN 1 ELSE 0 END)                                         AS DiscountedLines,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY DiscountedLines DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Focus on the suspicious 5-9% band — just under the
--       10% approval threshold. Who is concentrated there?
-- --------------------------------------------------------------

WITH DiscountBands AS
(
    SELECT
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        OD.DiscountPercentage,
        CASE
            WHEN COALESCE(OD.DiscountPercentage, 0) = 0               THEN '0% - None'
            WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 1 AND 4   THEN '1-4%'
            WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 5 AND 9   THEN '5-9% SUSPICIOUS'
            WHEN COALESCE(OD.DiscountPercentage, 0) = 10              THEN '10% - At Threshold'
            WHEN COALESCE(OD.DiscountPercentage, 0) > 10              THEN 'Over 10%'
        END                                                             AS DiscountBand,
        (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue
    FROM dbo.Employees AS E
    JOIN dbo.Orders AS O
        ON E.EmployeeId = O.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
)
SELECT
    EmployeeName,
    DiscountBand,
    COUNT(*)                                                            AS LineCount,
    SUM(NetValue)                                                       AS TotalNetValue
FROM DiscountBands
GROUP BY
    EmployeeName,
    DiscountBand
ORDER BY EmployeeName, DiscountBand;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Calculate the revenue lost to discounts per employee.
--       Full-price revenue minus actual revenue = the "leak."
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    SUM(OD.Quantity * OD.UnitPrice)                                     AS FullPriceRevenue,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS ActualRevenue,
    SUM(OD.Quantity * OD.UnitPrice * (COALESCE(OD.DiscountPercentage, 0) / 100.0))     AS RevenueLost,
    SUM(CASE WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 5 AND 9
             THEN OD.Quantity * OD.UnitPrice * (COALESCE(OD.DiscountPercentage, 0) / 100.0)
             ELSE 0 END)                                                AS SuspiciousBandLoss
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY SuspiciousBandLoss DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Score each employee on: volume of suspicious-band discounts,
-- revenue leaked, and number of discounted lines.
-- --------------------------------------------------------------

WITH DiscountSummary AS
(
    SELECT
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        COUNT(DISTINCT O.OrderId)                                       AS TotalOrders,
        SUM(CASE WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 5 AND 9
                 THEN 1 ELSE 0 END)                                     AS SuspiciousLines,
        SUM(OD.Quantity * OD.UnitPrice * (COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenueLost,
        SUM(CASE WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 5 AND 9
                 THEN OD.Quantity * OD.UnitPrice * (COALESCE(OD.DiscountPercentage, 0) / 100.0)
                 ELSE 0 END)                                            AS SuspiciousBandLoss
    FROM dbo.Employees AS E
    JOIN dbo.Orders AS O
        ON E.EmployeeId = O.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        E.EmployeeFirstName,
        E.EmployeeLastName
),
ScoredEmployees AS
(
    SELECT
        EmployeeName,
        TotalOrders,
        SuspiciousLines,
        TotalRevenueLost,
        SuspiciousBandLoss,
        CASE WHEN SuspiciousLines >= 5 THEN 1 ELSE 0 END +
        CASE WHEN SuspiciousBandLoss >= 500 THEN 1 ELSE 0 END +
        CASE WHEN TotalRevenueLost >= 1000 THEN 1 ELSE 0 END           AS SuspicionScore
    FROM DiscountSummary
)
SELECT
    EmployeeName,
    TotalOrders,
    SuspiciousLines,
    TotalRevenueLost,
    SuspiciousBandLoss,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, SuspiciousBandLoss DESC) AS SuspicionRank
FROM ScoredEmployees
ORDER BY SuspicionRank, SuspiciousBandLoss DESC;
GO


-- ==============================================================
-- MYSTERY 4: "THE SUPPLIER'S SECRET"
-- ==============================================================
-- The purchasing department keeps reordering from one supplier
-- despite their products consistently running out of stock.
-- Someone may be protecting that relationship. Identify which
-- supplier has the worst stock health but the most orders.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Which suppliers have products with the lowest stock
--       relative to the number of units that have been ordered?
-- --------------------------------------------------------------

SELECT
    S.SupplierCompanyName                                               AS SupplierName,
    COUNT(DISTINCT P.ProductId)                                         AS ProductCount,
    SUM(P.UnitsInStock)                                                 AS TotalStock,
    SUM(P.UnitsOnOrder)                                                 AS TotalOnOrder,
    SUM(CASE WHEN P.UnitsInStock < P.ReorderLevel THEN 1 ELSE 0 END)   AS ProductsBelowReorder
FROM Production.Supplier AS S
JOIN Production.Product AS P
    ON S.SupplierId = P.SupplierId
GROUP BY
    S.SupplierId,
    S.SupplierCompanyName
ORDER BY ProductsBelowReorder DESC, TotalStock ASC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Despite poor stock levels, how much revenue has each
--       supplier's products generated? A protected supplier
--       will be high revenue despite low reliability.
-- --------------------------------------------------------------

SELECT
    S.SupplierCompanyName                                               AS SupplierName,
    P.ProductName,
    SUM(OD.Quantity)                                                    AS UnitsSold,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS Revenue,
    P.UnitsInStock,
    P.ReorderLevel,
    CASE WHEN P.UnitsInStock < P.ReorderLevel THEN 'BELOW REORDER'
         ELSE 'OK' END                                                  AS StockStatus
FROM Production.Supplier AS S
JOIN Production.Product AS P
    ON S.SupplierId = P.SupplierId
JOIN dbo.OrderDetails AS OD
    ON P.ProductId = OD.ProductId
GROUP BY
    S.SupplierCompanyName,
    P.ProductName,
    P.UnitsInStock,
    P.ReorderLevel
ORDER BY Revenue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Which employees are processing the most orders for
--       the supplier with the worst stock health?
--       A pattern here suggests a protected relationship.
-- --------------------------------------------------------------

WITH PoorStockSuppliers AS
(
    SELECT
        S.SupplierId,
        S.SupplierCompanyName                                           AS SupplierName,
        SUM(CASE WHEN P.UnitsInStock < P.ReorderLevel THEN 1 ELSE 0 END) AS BelowReorderCount
    FROM Production.Supplier AS S
    JOIN Production.Product AS P
        ON S.SupplierId = P.SupplierId
    GROUP BY
        S.SupplierId,
        S.SupplierCompanyName
    HAVING SUM(CASE WHEN P.UnitsInStock < P.ReorderLevel THEN 1 ELSE 0 END) >= 1
)
SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    PSS.SupplierName,
    PSS.BelowReorderCount,
    COUNT(DISTINCT O.OrderId)                                           AS OrdersForSupplier,
    SUM(OD.Quantity)                                                    AS UnitsOrdered
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN PoorStockSuppliers AS PSS
    ON P.SupplierId = PSS.SupplierId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName,
    PSS.SupplierName,
    PSS.BelowReorderCount
ORDER BY OrdersForSupplier DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Identify the "protected supplier": high revenue, poor stock,
-- and a specific employee driving most of their orders.
-- --------------------------------------------------------------

WITH SupplierHealth AS
(
    SELECT
        S.SupplierId,
        S.SupplierCompanyName                                           AS SupplierName,
        SUM(CASE WHEN P.UnitsInStock < P.ReorderLevel THEN 1 ELSE 0 END) AS BelowReorderCount,
        COUNT(DISTINCT P.ProductId)                                     AS ProductCount
    FROM Production.Supplier AS S
    JOIN Production.Product AS P
        ON S.SupplierId = P.SupplierId
    GROUP BY
        S.SupplierId,
        S.SupplierCompanyName
),
SupplierRevenue AS
(
    SELECT
        P.SupplierId,
        COUNT(DISTINCT OD.OrderId)                                      AS TotalOrders,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
    FROM Production.Product AS P
    JOIN dbo.OrderDetails AS OD
        ON P.ProductId = OD.ProductId
    GROUP BY P.SupplierId
),
ScoredSuppliers AS
(
    SELECT
        SH.SupplierName,
        SH.BelowReorderCount,
        SH.ProductCount,
        SR.TotalOrders,
        SR.TotalRevenue,
        CASE WHEN SH.BelowReorderCount >= 2 THEN 1 ELSE 0 END +
        CASE WHEN SR.TotalRevenue >= 5000 THEN 1 ELSE 0 END +
        CASE WHEN SR.TotalOrders >= 20 THEN 1 ELSE 0 END               AS SuspicionScore
    FROM SupplierHealth AS SH
    JOIN SupplierRevenue AS SR
        ON SH.SupplierId = SR.SupplierId
)
SELECT
    SupplierName,
    BelowReorderCount,
    ProductCount,
    TotalOrders,
    TotalRevenue,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalRevenue DESC) AS SuspicionRank
FROM ScoredSuppliers
ORDER BY SuspicionRank, TotalRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 5: "THE MIDNIGHT SHIPMENTS"
-- ==============================================================
-- Orders are going to customers whose company names do not
-- match the ship name on the order. Someone is re-routing
-- deliveries. Find the orders where the ship name diverges
-- from the customer name and trace them to an employee.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Find orders where the ShipName does not match the
--       CustomerCompanyName. These are diverted shipments.
-- --------------------------------------------------------------

SELECT
    O.OrderId,
    O.OrderDate,
    C.CustomerCompanyName                                               AS CustomerName,
    O.ShipName,
    O.ShipCity,
    O.ShipCountry
FROM dbo.Orders AS O
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
WHERE O.ShipName <> C.CustomerCompanyName
ORDER BY O.OrderDate DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Which employees processed the most diverted orders?
--       Link the diverted orders back to their handlers.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    COUNT(DISTINCT O.OrderId)                                           AS DivertedOrders,
    COUNT(DISTINCT O.ShipCountry)                                       AS UniqueShipCountries,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS DivertedRevenue
FROM dbo.Orders AS O
JOIN dbo.Employees AS E
    ON O.EmployeeId = E.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
WHERE O.ShipName <> C.CustomerCompanyName
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY DivertedOrders DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Among diverted shipments, which products are being
--       redirected most? Cross with discounts — a diversion
--       paired with a discount is doubly suspicious.
-- --------------------------------------------------------------

SELECT
    P.ProductName,
    S.SupplierCompanyName                                               AS SupplierName,
    COUNT(DISTINCT O.OrderId)                                           AS DivertedOrderCount,
    SUM(OD.Quantity)                                                    AS TotalDivertedUnits,
    SUM(CASE WHEN COALESCE(OD.DiscountPercentage, 0) > 0 THEN 1 ELSE 0 END) AS DiscountedLines
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN Production.Supplier AS S
    ON P.SupplierId = S.SupplierId
WHERE O.ShipName <> C.CustomerCompanyName
GROUP BY
    P.ProductName,
    S.SupplierCompanyName
ORDER BY TotalDivertedUnits DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- The employee with the most diverted orders, highest diverted
-- revenue, and most discounted diverted lines is the suspect.
-- --------------------------------------------------------------

WITH DivertedOrders AS
(
    SELECT
        O.OrderId,
        O.OrderDate,
        O.ShipName,
        O.ShipCity,
        O.ShipCountry,
        C.CustomerCompanyName                                           AS CustomerName,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        P.ProductName,
        S.SupplierCompanyName                                           AS SupplierName,
        OD.Quantity,
        COALESCE(OD.DiscountPercentage, 0)                             AS DiscountPercentage,
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
    WHERE O.ShipName <> C.CustomerCompanyName
),
EmployeeSummary AS
(
    SELECT
        EmployeeName,
        COUNT(DISTINCT OrderId)                                         AS DivertedOrders,
        SUM(Quantity)                                                   AS TotalUnits,
        SUM(NetValue)                                                   AS TotalRevenue,
        SUM(CASE WHEN DiscountPercentage > 0 THEN 1 ELSE 0 END)       AS DiscountedLines,
        CASE WHEN COUNT(DISTINCT OrderId) >= 5 THEN 1 ELSE 0 END +
        CASE WHEN SUM(NetValue) >= 2000 THEN 1 ELSE 0 END +
        CASE WHEN SUM(CASE WHEN DiscountPercentage > 0 THEN 1 ELSE 0 END) >= 3 THEN 1 ELSE 0 END AS SuspicionScore
    FROM DivertedOrders
    GROUP BY EmployeeName
)
SELECT
    EmployeeName,
    DivertedOrders,
    TotalUnits,
    TotalRevenue,
    DiscountedLines,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalRevenue DESC) AS SuspicionRank
FROM EmployeeSummary
ORDER BY SuspicionRank, TotalRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 6: "THE LOYAL CUSTOMER'S BETRAYAL"
-- ==============================================================
-- A once-active customer has gone completely silent. Meanwhile
-- a new customer appeared ordering the exact same products.
-- Was the account migrated off the books? Find which long-term
-- customer stopped ordering and what happened to their volume.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Show each customer's first order date, last order date,
--       and total lifetime orders. Find those who stopped early.
-- --------------------------------------------------------------

SELECT
    C.CustomerCompanyName                                               AS CustomerName,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders,
    MIN(O.OrderDate)                                                    AS FirstOrder,
    MAX(O.OrderDate)                                                    AS LastOrder,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS LifetimeRevenue
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    C.CustomerId,
    C.CustomerCompanyName
ORDER BY LastOrder ASC, TotalOrders DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: For customers with high lifetime revenue but an early
--       last order, find what products they were buying before
--       they went silent.
-- --------------------------------------------------------------

WITH EarlyExiters AS
(
    SELECT
        C.CustomerId,
        C.CustomerCompanyName                                           AS CustomerName,
        MAX(O.OrderDate)                                                AS LastOrderDate,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS LifetimeRevenue
    FROM dbo.Customers AS C
    JOIN dbo.Orders AS O
        ON C.CustomerId = O.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        C.CustomerId,
        C.CustomerCompanyName
    HAVING SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) >= 5000
)
SELECT
    EE.CustomerName,
    EE.LastOrderDate,
    EE.LifetimeRevenue,
    P.ProductName,
    S.SupplierCompanyName                                               AS SupplierName,
    SUM(OD.Quantity)                                                    AS TotalUnits
FROM EarlyExiters AS EE
JOIN dbo.Orders AS O
    ON EE.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN Production.Supplier AS S
    ON P.SupplierId = S.SupplierId
GROUP BY
    EE.CustomerName,
    EE.LastOrderDate,
    EE.LifetimeRevenue,
    P.ProductName,
    S.SupplierCompanyName
ORDER BY EE.LifetimeRevenue DESC, TotalUnits DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Are those same products now being ordered in higher
--       volume by a different customer after the exit date?
--       This would confirm a migrated account.
-- --------------------------------------------------------------

WITH EarlyExiters AS
(
    SELECT
        C.CustomerId,
        C.CustomerCompanyName                                           AS CustomerName,
        MAX(O.OrderDate)                                                AS LastOrderDate
    FROM dbo.Customers AS C
    JOIN dbo.Orders AS O
        ON C.CustomerId = O.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        C.CustomerId,
        C.CustomerCompanyName
    HAVING SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) >= 5000
),
ExiterProducts AS
(
    SELECT DISTINCT
        OD.ProductId
    FROM EarlyExiters AS EE
    JOIN dbo.Orders AS O
        ON EE.CustomerId = O.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
)
SELECT
    C.CustomerCompanyName                                               AS NewCustomerName,
    P.ProductName,
    COUNT(DISTINCT O.OrderId)                                           AS OrderCount,
    SUM(OD.Quantity)                                                    AS TotalUnits,
    MIN(O.OrderDate)                                                    AS FirstOrderForProduct
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
JOIN ExiterProducts AS EP
    ON OD.ProductId = EP.ProductId
WHERE C.CustomerId NOT IN
(
    SELECT CustomerId FROM EarlyExiters
)
GROUP BY
    C.CustomerCompanyName,
    P.ProductName
ORDER BY TotalUnits DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- The lost loyalist is the high-revenue customer who stopped
-- ordering earliest. Score by revenue and recency of exit.
-- --------------------------------------------------------------

WITH CustomerStats AS
(
    SELECT
        C.CustomerId,
        C.CustomerCompanyName                                           AS CustomerName,
        COUNT(DISTINCT O.OrderId)                                       AS TotalOrders,
        MIN(O.OrderDate)                                                AS FirstOrder,
        MAX(O.OrderDate)                                                AS LastOrder,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS LifetimeRevenue,
        COUNT(DISTINCT OD.ProductId)                                    AS UniqueProducts
    FROM dbo.Customers AS C
    JOIN dbo.Orders AS O
        ON C.CustomerId = O.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        C.CustomerId,
        C.CustomerCompanyName
),
ScoredCustomers AS
(
    SELECT
        CustomerName,
        TotalOrders,
        FirstOrder,
        LastOrder,
        LifetimeRevenue,
        UniqueProducts,
        CASE WHEN LifetimeRevenue >= 10000 THEN 1 ELSE 0 END +
        CASE WHEN TotalOrders >= 10 THEN 1 ELSE 0 END +
        CASE WHEN UniqueProducts >= 5 THEN 1 ELSE 0 END                AS LoyaltyScore,
        DENSE_RANK() OVER (ORDER BY LastOrder ASC)                     AS ExitRank
    FROM CustomerStats
    WHERE TotalOrders >= 5
)
SELECT
    CustomerName,
    TotalOrders,
    FirstOrder,
    LastOrder,
    LifetimeRevenue,
    UniqueProducts,
    LoyaltyScore,
    ExitRank,
    DENSE_RANK() OVER (ORDER BY LoyaltyScore DESC, LifetimeRevenue DESC) AS SuspicionRank
FROM ScoredCustomers
WHERE LoyaltyScore >= 2
ORDER BY ExitRank, LifetimeRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 7: "THE PHANTOM EMPLOYEE"
-- ==============================================================
-- An employee appears in order records but their hire date
-- is unusually recent compared to the orders attributed to
-- them, or they handle orders with no associated customers.
-- Find who does not fit the normal employee profile.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: List all employees with their hire date, how many
--       orders they handled, and the date of their first order.
--       An employee processing orders before their hire date
--       is a red flag.
-- --------------------------------------------------------------

SELECT
    E.EmployeeId,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    E.HireDate,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders,
    MIN(O.OrderDate)                                                    AS FirstOrderDate,
    MAX(O.OrderDate)                                                    AS LastOrderDate
FROM dbo.Employees AS E
LEFT JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
GROUP BY
    E.EmployeeId,
    E.EmployeeFirstName,
    E.EmployeeLastName,
    E.HireDate
ORDER BY E.HireDate DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Flag any employee whose first recorded order date
--       is before their hire date. Use HAVING to isolate them.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    E.HireDate,
    MIN(O.OrderDate)                                                    AS FirstOrderDate,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName,
    E.HireDate
HAVING MIN(O.OrderDate) < E.HireDate
ORDER BY TotalOrders DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: For flagged employees, pull the specific orders
--       that were placed before their hire date along with
--       which customers and products were involved.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    E.HireDate,
    O.OrderId,
    O.OrderDate,
    C.CustomerCompanyName                                               AS CustomerName,
    P.ProductName,
    OD.Quantity,
    (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
JOIN Production.Product AS P
    ON OD.ProductId = P.ProductId
WHERE O.OrderDate < E.HireDate
ORDER BY EmployeeName, O.OrderDate;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Score employees: orders before hire date, total phantom
-- order value, and number of affected customers.
-- --------------------------------------------------------------

WITH EmployeeOrderProfile AS
(
    SELECT
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        E.HireDate,
        COUNT(DISTINCT O.OrderId)                                       AS TotalOrders,
        COUNT(DISTINCT CASE WHEN O.OrderDate < E.HireDate
                            THEN O.OrderId END)                         AS PhantomOrders,
        SUM(CASE WHEN O.OrderDate < E.HireDate
                 THEN OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)
                 ELSE 0 END)                                            AS PhantomRevenue,
        COUNT(DISTINCT CASE WHEN O.OrderDate < E.HireDate
                            THEN O.CustomerId END)                      AS PhantomCustomers
    FROM dbo.Employees AS E
    JOIN dbo.Orders AS O
        ON E.EmployeeId = O.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        E.EmployeeFirstName,
        E.EmployeeLastName,
        E.HireDate
)
SELECT
    EmployeeName,
    HireDate,
    TotalOrders,
    PhantomOrders,
    PhantomRevenue,
    PhantomCustomers,
    CASE WHEN PhantomOrders >= 1 THEN 1 ELSE 0 END +
    CASE WHEN PhantomRevenue >= 500 THEN 1 ELSE 0 END +
    CASE WHEN PhantomCustomers >= 2 THEN 1 ELSE 0 END                  AS SuspicionScore,
    DENSE_RANK() OVER (ORDER BY PhantomOrders DESC, PhantomRevenue DESC) AS SuspicionRank
FROM EmployeeOrderProfile
WHERE PhantomOrders >= 1
ORDER BY SuspicionRank;
GO


-- ==============================================================
-- MYSTERY 8: "THE CHRISTMAS RUSH COVER-UP"
-- ==============================================================
-- Q4 always looks exceptional. But someone is booking orders
-- in September and delaying shipment into October-December to
-- inflate Q4 numbers for bonus calculations. Find orders where
-- the order month is September but the shipment is Q4.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Compare order counts and revenue by month across the
--       dataset. Does September always spike before Q4?
-- --------------------------------------------------------------

SELECT
    DATENAME(MONTH, O.OrderDate)                                        AS OrderMonth,
    COUNT(DISTINCT O.OrderId)                                           AS OrderCount,
    SUM(OD.Quantity)                                                    AS TotalUnits,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue
FROM dbo.Orders AS O
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    DATENAME(MONTH, O.OrderDate)
ORDER BY TotalRevenue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Find orders placed in September that were shipped in
--       October, November, or December (front-loaded).
-- --------------------------------------------------------------

SELECT
    O.OrderId,
    O.OrderDate,
    O.ShippedDate,
    DATENAME(MONTH, O.OrderDate)                                        AS OrderMonth,
    DATENAME(MONTH, O.ShippedDate)                                      AS ShipMonth,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    C.CustomerCompanyName                                               AS CustomerName,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS OrderValue
FROM dbo.Orders AS O
JOIN dbo.Employees AS E
    ON O.EmployeeId = E.EmployeeId
JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
WHERE DATENAME(MONTH, O.OrderDate)  = 'September'
  AND DATENAME(MONTH, O.ShippedDate) IN ('October', 'November', 'December')
GROUP BY
    O.OrderId,
    O.OrderDate,
    O.ShippedDate,
    E.EmployeeFirstName,
    E.EmployeeLastName,
    C.CustomerCompanyName
ORDER BY OrderValue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Which employees have the most September-to-Q4
--       front-loaded orders? Count them and total the value.
-- --------------------------------------------------------------

SELECT
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    COUNT(DISTINCT O.OrderId)                                           AS FrontLoadedOrders,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS FrontLoadedRevenue,
    COUNT(DISTINCT O.CustomerId)                                        AS CustomersInvolved
FROM dbo.Employees AS E
JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
WHERE DATENAME(MONTH, O.OrderDate)  = 'September'
  AND DATENAME(MONTH, O.ShippedDate) IN ('October', 'November', 'December')
GROUP BY
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY FrontLoadedOrders DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Score employees by front-load volume, revenue, and whether
-- the pattern repeats across multiple years.
-- --------------------------------------------------------------

WITH FrontLoadedLines AS
(
    SELECT
        O.OrderId,
        O.OrderDate,
        O.ShippedDate,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        C.CustomerCompanyName                                           AS CustomerName,
        P.ProductName,
        S.SupplierCompanyName                                           AS SupplierName,
        OD.Quantity,
        COALESCE(OD.DiscountPercentage, 0)                             AS DiscountPercentage,
        (OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS NetValue
    FROM dbo.Orders AS O
    JOIN dbo.Employees AS E
        ON O.EmployeeId = E.EmployeeId
    JOIN dbo.Customers AS C
        ON O.CustomerId = C.CustomerId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    JOIN Production.Product AS P
        ON OD.ProductId = P.ProductId
    JOIN Production.Supplier AS S
        ON P.SupplierId = S.SupplierId
    WHERE DATENAME(MONTH, O.OrderDate)  = 'September'
      AND DATENAME(MONTH, O.ShippedDate) IN ('October', 'November', 'December')
),
EmployeeSummary AS
(
    SELECT
        EmployeeName,
        COUNT(DISTINCT OrderId)                                         AS FrontLoadedOrders,
        SUM(Quantity)                                                   AS TotalUnits,
        SUM(NetValue)                                                   AS TotalRevenue,
        SUM(CASE WHEN DiscountPercentage > 0 THEN 1 ELSE 0 END)       AS DiscountedLines,
        CASE WHEN COUNT(DISTINCT OrderId) >= 3 THEN 1 ELSE 0 END +
        CASE WHEN SUM(NetValue) >= 1000 THEN 1 ELSE 0 END +
        CASE WHEN SUM(CASE WHEN DiscountPercentage > 0 THEN 1 ELSE 0 END) >= 2 THEN 1 ELSE 0 END AS SuspicionScore
    FROM FrontLoadedLines
    GROUP BY EmployeeName
)
SELECT
    EmployeeName,
    FrontLoadedOrders,
    TotalUnits,
    TotalRevenue,
    DiscountedLines,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalRevenue DESC) AS SuspicionRank
FROM EmployeeSummary
ORDER BY SuspicionRank, TotalRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 9: "THE TERRITORY WAR"
-- ==============================================================
-- Two employees are attributed orders for the same customers.
-- One appears to be overwriting the other's work by reassigning
-- order credit. Find customers served by more than one
-- employee and which rep dominates each shared account.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Find customers who have been served by more than
--       one employee. A customer with 2+ handling reps
--       is the disputed territory.
-- --------------------------------------------------------------

SELECT
    C.CustomerCompanyName                                               AS CustomerName,
    COUNT(DISTINCT O.EmployeeId)                                        AS NumberOfReps,
    COUNT(DISTINCT O.OrderId)                                           AS TotalOrders
FROM dbo.Customers AS C
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
GROUP BY
    C.CustomerId,
    C.CustomerCompanyName
HAVING COUNT(DISTINCT O.EmployeeId) > 1
ORDER BY NumberOfReps DESC, TotalOrders DESC;
GO

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: For each shared customer, show how many orders and
--       how much revenue each employee claims.
--       An extreme imbalance = one rep is crowding out the other.
-- --------------------------------------------------------------

WITH SharedCustomers AS
(
    SELECT O.CustomerId
    FROM dbo.Orders AS O
    GROUP BY O.CustomerId
    HAVING COUNT(DISTINCT O.EmployeeId) > 1
)
SELECT
    C.CustomerCompanyName                                               AS CustomerName,
    E.EmployeeFirstName + ' ' + E.EmployeeLastName                     AS EmployeeName,
    COUNT(DISTINCT O.OrderId)                                           AS OrdersForCustomer,
    SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS Revenue
FROM SharedCustomers AS SC
JOIN dbo.Customers AS C
    ON SC.CustomerId = C.CustomerId
JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
JOIN dbo.Employees AS E
    ON O.EmployeeId = E.EmployeeId
JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
GROUP BY
    C.CustomerCompanyName,
    E.EmployeeFirstName,
    E.EmployeeLastName
ORDER BY CustomerName, Revenue DESC;
GO

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Which employee appears as the dominant rep across the
--       most shared customers? That is the usurper.
-- --------------------------------------------------------------

WITH SharedCustomers AS
(
    SELECT O.CustomerId
    FROM dbo.Orders AS O
    GROUP BY O.CustomerId
    HAVING COUNT(DISTINCT O.EmployeeId) > 1
),
CustomerRepRevenue AS
(
    SELECT
        SC.CustomerId,
        O.EmployeeId,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS Revenue
    FROM SharedCustomers AS SC
    JOIN dbo.Orders AS O
        ON SC.CustomerId = O.CustomerId
    JOIN dbo.Employees AS E
        ON O.EmployeeId = E.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        SC.CustomerId,
        O.EmployeeId,
        E.EmployeeFirstName,
        E.EmployeeLastName
),
DominantRep AS
(
    SELECT
        CustomerId,
        EmployeeName,
        Revenue,
        DENSE_RANK() OVER (ORDER BY Revenue DESC)                      AS RevenueRank
    FROM CustomerRepRevenue
)
SELECT
    EmployeeName,
    COUNT(DISTINCT CustomerId)                                          AS CustomersWon,
    SUM(Revenue)                                                        AS TotalRevenueFromShared
FROM DominantRep
WHERE RevenueRank = 1
GROUP BY EmployeeName
ORDER BY CustomersWon DESC, TotalRevenueFromShared DESC;
GO

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- The usurper is the employee dominating the most shared
-- accounts by revenue with the widest margin of victory.
-- --------------------------------------------------------------

WITH SharedCustomers AS
(
    SELECT O.CustomerId
    FROM dbo.Orders AS O
    GROUP BY O.CustomerId
    HAVING COUNT(DISTINCT O.EmployeeId) > 1
),
CustomerRepRevenue AS
(
    SELECT
        SC.CustomerId,
        C.CustomerCompanyName                                           AS CustomerName,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        COUNT(DISTINCT O.OrderId)                                       AS OrderCount,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS Revenue
    FROM SharedCustomers AS SC
    JOIN dbo.Customers AS C
        ON SC.CustomerId = C.CustomerId
    JOIN dbo.Orders AS O
        ON C.CustomerId = O.CustomerId
    JOIN dbo.Employees AS E
        ON O.EmployeeId = E.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY
        SC.CustomerId,
        C.CustomerCompanyName,
        E.EmployeeFirstName,
        E.EmployeeLastName
),
ScoredReps AS
(
    SELECT
        EmployeeName,
        COUNT(DISTINCT CustomerId)                                      AS SharedCustomers,
        SUM(OrderCount)                                                 AS TotalOrders,
        SUM(Revenue)                                                    AS TotalRevenue,
        CASE WHEN COUNT(DISTINCT CustomerId) >= 3 THEN 1 ELSE 0 END +
        CASE WHEN SUM(Revenue) >= 5000 THEN 1 ELSE 0 END +
        CASE WHEN SUM(OrderCount) >= 10 THEN 1 ELSE 0 END              AS SuspicionScore
    FROM CustomerRepRevenue
    GROUP BY EmployeeName
)
SELECT
    EmployeeName,
    SharedCustomers,
    TotalOrders,
    TotalRevenue,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalRevenue DESC) AS SuspicionRank
FROM ScoredReps
ORDER BY SuspicionRank, TotalRevenue DESC;
GO


-- ==============================================================
-- MYSTERY 10: "THE FINAL RECKONING"
-- ==============================================================
-- One employee is at the center of all nine prior cases.
-- They appear in: discount abuse, ghost customers, supplier
-- protection, diverted shipments, front-loading, and territory
-- usurpation. Combine all clues into one final suspicion score
-- and name the criminal mastermind.
-- ==============================================================

-- --------------------------------------------------------------
-- SECTION 1
-- Clue: Discount abuse — employees with the most lines in
--       the suspicious 5-9% discount band.
-- --------------------------------------------------------------

WITH DiscountAbuse AS
(
    SELECT
        O.EmployeeId,
        COUNT(DISTINCT CASE WHEN COALESCE(OD.DiscountPercentage, 0) BETWEEN 5 AND 9
                            THEN O.OrderId END)                         AS SuspiciousDiscountOrders
    FROM dbo.Orders AS O
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    GROUP BY O.EmployeeId
),

-- --------------------------------------------------------------
-- SECTION 2
-- Clue: Diverted shipments — orders where ShipName does not
--       match CustomerCompanyName.
-- --------------------------------------------------------------

DivertedShipments AS
(
    SELECT
        O.EmployeeId,
        COUNT(DISTINCT O.OrderId)                                       AS DivertedOrders
    FROM dbo.Orders AS O
    JOIN dbo.Customers AS C
        ON O.CustomerId = C.CustomerId
    WHERE O.ShipName <> C.CustomerCompanyName
    GROUP BY O.EmployeeId
),

-- --------------------------------------------------------------
-- SECTION 3
-- Clue: Front-loading — September orders shipped in Q4.
-- --------------------------------------------------------------

FrontLoading AS
(
    SELECT
        O.EmployeeId,
        COUNT(DISTINCT O.OrderId)                                       AS FrontLoadedOrders
    FROM dbo.Orders AS O
    WHERE DATENAME(MONTH, O.OrderDate)   = 'September'
      AND DATENAME(MONTH, O.ShippedDate) IN ('October', 'November', 'December')
    GROUP BY O.EmployeeId
),

-- --------------------------------------------------------------
-- SECTION 4: THE VERDICT
-- Combine all three crime dimensions into one score per
-- employee. The highest scorer is the mastermind.
-- --------------------------------------------------------------

FinalClues AS
(
    SELECT
        E.EmployeeId,
        E.EmployeeFirstName + ' ' + E.EmployeeLastName                 AS EmployeeName,
        E.HireDate,
        COUNT(DISTINCT O.OrderId)                                       AS TotalOrders,
        SUM(OD.Quantity * OD.UnitPrice * (1 - COALESCE(OD.DiscountPercentage, 0) / 100.0)) AS TotalRevenue,
        COALESCE(DA.SuspiciousDiscountOrders, 0)                       AS SuspiciousDiscountOrders,
        COALESCE(DS.DivertedOrders, 0)                                  AS DivertedOrders,
        COALESCE(FL.FrontLoadedOrders, 0)                              AS FrontLoadedOrders,
        CASE WHEN COALESCE(DA.SuspiciousDiscountOrders, 0) >= 3 THEN 1 ELSE 0 END +
        CASE WHEN COALESCE(DS.DivertedOrders, 0) >= 2 THEN 1 ELSE 0 END +
        CASE WHEN COALESCE(FL.FrontLoadedOrders, 0) >= 1 THEN 1 ELSE 0 END +
        CASE WHEN COUNT(DISTINCT O.OrderId) >= 50 THEN 1 ELSE 0 END   AS SuspicionScore
    FROM dbo.Employees AS E
    JOIN dbo.Orders AS O
        ON E.EmployeeId = O.EmployeeId
    JOIN dbo.OrderDetails AS OD
        ON O.OrderId = OD.OrderId
    LEFT JOIN DiscountAbuse AS DA
        ON E.EmployeeId = DA.EmployeeId
    LEFT JOIN DivertedShipments AS DS
        ON E.EmployeeId = DS.EmployeeId
    LEFT JOIN FrontLoading AS FL
        ON E.EmployeeId = FL.EmployeeId
    GROUP BY
        E.EmployeeId,
        E.EmployeeFirstName,
        E.EmployeeLastName,
        E.HireDate,
        DA.SuspiciousDiscountOrders,
        DS.DivertedOrders,
        FL.FrontLoadedOrders
)
SELECT
    EmployeeName,
    HireDate,
    TotalOrders,
    TotalRevenue,
    SuspiciousDiscountOrders,
    DivertedOrders,
    FrontLoadedOrders,
    SuspicionScore,
    DENSE_RANK() OVER (ORDER BY SuspicionScore DESC, TotalRevenue DESC) AS SuspicionRank
FROM FinalClues
ORDER BY SuspicionRank, TotalRevenue DESC;
GO
