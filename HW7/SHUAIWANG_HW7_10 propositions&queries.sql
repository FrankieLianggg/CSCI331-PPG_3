/*========================================================
 --1) Proposition: Build a VIP customer watchlist from customers who have actually placed orders
--Idea: Instead of copying all customers, create a shortlist of active customers only. This uses INSERT ... SELECT, one of the core chapter patterns.
========================================================*/
DROP TABLE IF EXISTS dbo.VIPCustomers;
GO

CREATE TABLE dbo.VIPCustomers
(
    CustomerId     INT PRIMARY KEY,
    CompanyName    NVARCHAR(40),
    CustomerCity   NVARCHAR(15),
    CustomerCountry NVARCHAR(15)
);
GO

INSERT INTO dbo.VIPCustomers (CustomerId, CompanyName, CustomerCity, CustomerCountry)
SELECT DISTINCT
    c.CustomerId,
    c.CustomerCompanyName,
    c.CustomerCity,
    c.CustomerCountry
FROM Sales.Customer AS c
JOIN Sales.[Order] AS o
    ON c.CustomerId = o.CustomerId;

SELECT * 
FROM dbo.VIPCustomers
ORDER BY CompanyName;

/*========================================================
2) Proposition: Create a “French orders spotlight” using a stored procedure and capture the results
Idea: This makes INSERT ... EXEC feel like a real reporting task instead of a demo. Your files explicitly include INSERT EXEC.
========================================================*/
DROP TABLE IF EXISTS dbo.FranceOrders;
GO

CREATE TABLE dbo.FranceOrders
(
    OrderId    INT PRIMARY KEY,
    OrderDate  DATE,
    EmployeeId INT,
    CustomerId INT
);
GO

CREATE OR ALTER PROC Sales.GetOrdersByCountry
    @Country NVARCHAR(40)
AS
BEGIN
    SELECT
        OrderId,
        OrderDate,
        EmployeeId,
        CustomerId
    FROM Sales.[Order]
    WHERE ShipToCountry = @Country;
END;
GO

INSERT INTO dbo.FranceOrders (OrderId, OrderDate, EmployeeId, CustomerId)
EXEC Sales.GetOrdersByCountry @Country = N'France';

SELECT *
FROM dbo.FranceOrders
ORDER BY OrderDate;

/*========================================================
3) Proposition: Freeze a 2014 order archive before making cleanup decisions
Idea: A real business snapshot. This uses SELECT INTO, which appears directly in the files.
========================================================*/
DROP TABLE IF EXISTS dbo.OrderArchive2014;
GO

SELECT
    OrderId,
    CustomerId,
    EmployeeId,
    ShipperId,
    OrderDate,
    RequiredDate,
    ShipToDate,
    Freight,
    ShipToName,
    ShipToAddress,
    ShipToCity,
    ShipToRegion,
    ShipToPostalCode,
    ShipToCountry
INTO dbo.OrderArchive2014
FROM Sales.[Order]
WHERE OrderDate >= '20140101'
  AND OrderDate <  '20150101';

SELECT *
FROM dbo.OrderArchive2014
ORDER BY OrderDate, OrderId;

/*========================================================
4) Proposition: Remove stale archived orders and show exactly what was deleted
Idea: This turns a plain DELETE into an audit-friendly cleanup using OUTPUT. Your files emphasize DELETE ... OUTPUT.
========================================================*/
DELETE FROM dbo.OrderArchive2014
OUTPUT
    deleted.OrderId,
    deleted.OrderDate,
    deleted.CustomerId,
    deleted.ShipToCountry
WHERE OrderDate < '20140701';

SELECT *
FROM dbo.OrderArchive2014
ORDER BY OrderDate, OrderId;


/*========================================================
5) Proposition: Eliminate archived orders from customers in Brazil
Idea: This uses DELETE ... FROM ... JOIN, a key chapter concept shown in the files.
========================================================*/
DELETE oa
FROM dbo.OrderArchive2014 AS oa
JOIN Sales.Customer AS c
    ON oa.CustomerId = c.CustomerId
WHERE c.CustomerCountry = N'Brazil';

SELECT *
FROM dbo.OrderArchive2014
ORDER BY OrderId;

/*========================================================
6) Proposition: Give a loyalty discount boost to customers who bought Product 51
Idea: This uses UPDATE plus OUTPUT, which is one of the strongest Chapter 8 ideas.
========================================================*/
DROP TABLE IF EXISTS dbo.OrderDetailSandbox;
GO

CREATE TABLE dbo.OrderDetailSandbox
(
    OrderId    INT,
    ProductId  INT,
    UnitPrice  MONEY,
    Qty        SMALLINT,
    Discount   NUMERIC(4,3),
    CONSTRAINT PK_OrderDetailSandbox PRIMARY KEY (OrderId, ProductId)
);
GO

INSERT INTO dbo.OrderDetailSandbox (OrderId, ProductId, UnitPrice, Qty, Discount)
SELECT
    OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    DiscountPercentage / 100.0
FROM Sales.OrderDetail;
GO

UPDATE dbo.OrderDetailSandbox
SET Discount = Discount + 0.05
OUTPUT
    inserted.OrderId,
    inserted.ProductId,
    deleted.Discount AS OldDiscount,
    inserted.Discount AS NewDiscount
WHERE ProductId = 51;

SELECT *
FROM dbo.OrderDetailSandbox
WHERE ProductId = 51;

/*========================================================
7) Proposition: Synchronize shipping destinations for UK orders with current customer location data
Idea: This is a practical UPDATE ... FROM join example. The chapter files show update-based-on-join patterns.
========================================================*/
DROP TABLE IF EXISTS dbo.OrderShippingSandbox;
GO

CREATE TABLE dbo.OrderShippingSandbox
(
    OrderId         INT PRIMARY KEY,
    CustomerId      INT,
    EmployeeId      INT,
    OrderDate       DATE,
    RequiredDate    DATE,
    ShipToDate      DATE NULL,
    ShipperId       INT,
    Freight         MONEY,
    ShipToName      NVARCHAR(40),
    ShipToAddress   NVARCHAR(60),
    ShipToCity      NVARCHAR(15),
    ShipToRegion    NVARCHAR(15) NULL,
    ShipToPostalCode NVARCHAR(10) NULL,
    ShipToCountry   NVARCHAR(15)
);
GO

INSERT INTO dbo.OrderShippingSandbox
(
    OrderId, CustomerId, EmployeeId, OrderDate, RequiredDate, ShipToDate,
    ShipperId, Freight, ShipToName, ShipToAddress, ShipToCity,
    ShipToRegion, ShipToPostalCode, ShipToCountry
)
SELECT
    OrderId, CustomerId, EmployeeId, OrderDate, RequiredDate, ShipToDate,
    ShipperId, Freight, ShipToName, ShipToAddress, ShipToCity,
    ShipToRegion, ShipToPostalCode, ShipToCountry
FROM Sales.[Order];
GO

UPDATE os
SET
    ShipToCity       = c.CustomerCity,
    ShipToRegion     = c.CustomerRegion,
    ShipToPostalCode = c.CustomerPostalCode,
    ShipToCountry    = c.CustomerCountry
FROM dbo.OrderShippingSandbox AS os
JOIN Sales.Customer AS c
    ON os.CustomerId = c.CustomerId
WHERE c.CustomerCountry = N'UK';

SELECT TOP (20) *
FROM dbo.OrderShippingSandbox
WHERE ShipToCountry = N'UK'
ORDER BY OrderDate DESC;

/*========================================================
8) Proposition: Raise freight by $15 for the 25 most recent archived orders
Idea: This uses TOP inside a CTE for targeted updates, matching the chapter’s TOP/OFFSET-FETCH modification theme.
========================================================*/
WITH RecentOrders AS
(
    SELECT TOP (25) *
    FROM dbo.OrderShippingSandbox
    ORDER BY OrderDate DESC, OrderId DESC
)
UPDATE RecentOrders
SET Freight = Freight + 15.00;

SELECT TOP (25)
    OrderId,
    OrderDate,
    Freight
FROM dbo.OrderShippingSandbox
ORDER BY OrderDate DESC, OrderId DESC;

/*========================================================
9) Proposition: Purge a “page” of low-priority orders using OFFSET-FETCH logic
Idea: This is a more interesting batch-delete pattern than deleting everything old. It mirrors the chapter’s OFFSET-FETCH modification examples.
========================================================*/
WITH BatchToDelete AS
(
    SELECT *
    FROM dbo.OrderShippingSandbox
    ORDER BY OrderDate, OrderId
    OFFSET 10 ROWS FETCH NEXT 15 ROWS ONLY
)
DELETE FROM BatchToDelete;

SELECT COUNT(*) AS RemainingRows
FROM dbo.OrderShippingSandbox;

/*========================================================
10) Proposition: Merge a customer stage table into a master contact list and show what changed
Idea: This is a strong final proposition because MERGE is one of the signature Chapter 8 topics in the files.
========================================================*/
DROP TABLE IF EXISTS dbo.CustomerMaster, dbo.CustomerStage;
GO

CREATE TABLE dbo.CustomerMaster
(
    CustomerId   INT PRIMARY KEY,
    CompanyName  NVARCHAR(40),
    Phone        NVARCHAR(24),
    City         NVARCHAR(15)
);

CREATE TABLE dbo.CustomerStage
(
    CustomerId   INT PRIMARY KEY,
    CompanyName  NVARCHAR(40),
    Phone        NVARCHAR(24),
    City         NVARCHAR(15)
);
GO

INSERT INTO dbo.CustomerMaster (CustomerId, CompanyName, Phone, City)
SELECT TOP (8)
    CustomerId,
    CustomerCompanyName,
    CustomerPhoneNumber,
    CustomerCity
FROM Sales.Customer
ORDER BY CustomerId;

INSERT INTO dbo.CustomerStage (CustomerId, CompanyName, Phone, City)
VALUES
    (1, N'Updated Company 1', N'(111) 111-1111', N'New York'),
    (2, N'Updated Company 2', N'(222) 222-2222', N'London'),
    (9, N'Brand New Customer 9', N'(999) 999-9999', N'Paris'),
    (10, N'Brand New Customer 10', N'(101) 101-1010', N'Berlin');
GO

MERGE dbo.CustomerMaster AS tgt
USING dbo.CustomerStage AS src
    ON tgt.CustomerId = src.CustomerId
WHEN MATCHED THEN
    UPDATE SET
        tgt.CompanyName = src.CompanyName,
        tgt.Phone       = src.Phone,
        tgt.City        = src.City
WHEN NOT MATCHED THEN
    INSERT (CustomerId, CompanyName, Phone, City)
    VALUES (src.CustomerId, src.CompanyName, src.Phone, src.City)
OUTPUT
    $action AS MergeAction,
    inserted.CustomerId,
    deleted.CompanyName AS OldCompanyName,
    inserted.CompanyName AS NewCompanyName;

SELECT *
FROM dbo.CustomerMaster
ORDER BY CustomerId;