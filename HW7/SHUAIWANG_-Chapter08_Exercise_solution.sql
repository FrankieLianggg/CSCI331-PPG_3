USE Northwinds2024Student;
GO

/*========================================================
  1
  Create dbo.Customers
========================================================*/
DROP TABLE IF EXISTS dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
    custid      INT          NOT NULL PRIMARY KEY,
    companyname NVARCHAR(40) NOT NULL,
    country     NVARCHAR(15) NOT NULL,
    region      NVARCHAR(15) NULL,
    city        NVARCHAR(15) NOT NULL
);
GO

SELECT*
FROM dbo.Customers

/*========================================================
  1-1
  Insert one row into dbo.Customers
========================================================*/
INSERT INTO dbo.Customers (custid, companyname, country, region, city)
VALUES (100, N'Coho Winery', N'USA', N'WA', N'Redmond');
GO

SELECT*
FROM dbo.Customers
/*========================================================
  1-2
  Insert all customers who placed orders
========================================================*/
INSERT INTO dbo.Customers (custid, companyname, country, region, city)
SELECT DISTINCT
    C.CustomerId,
    C.CustomerCompanyName,
    C.CustomerCountry,
    C.CustomerRegion,
    C.CustomerCity
FROM Sales.Customer AS C
JOIN Sales.[Order] AS O
    ON C.CustomerId = O.CustomerId

SELECT*
FROM dbo.Customers

/*========================================================
  1-3
  SELECT INTO dbo.H7_Orders for orders in years 2020-2022
========================================================*/

DROP TABLE IF EXISTS dbo.Orders;
GO

SELECT *
INTO dbo.Orders
FROM Sales.[Order]
WHERE OrderDate >= '20140101'
  AND OrderDate <  '20170101';
GO

SELECT *
FROM dbo.Orders;


/*========================================================
  2
  Delete orders before August 2020
  Return deleted orderid and orderdate
========================================================*/
DELETE FROM dbo.Orders
OUTPUT deleted.OrderId, deleted.OrderDate
WHERE OrderDate < '20140801';
GO

SELECT *
FROM dbo.Orders;

/*========================================================
  3
  Delete from dbo.H7_Orders orders placed by customers from Brazil
========================================================*/

DELETE O
FROM dbo.Orders AS O
JOIN dbo.Customers AS C
    ON O.CustomerId = C.custid
WHERE C.country = N'Brazil';
GO

SELECT *
FROM dbo.Orders;

/*========================================================
  4
  Update NULL region values to '<None>'
  Show custid, old region, new region
========================================================*/
UPDATE dbo.Customers
SET region = N'<None>'
OUTPUT
    deleted.custid,
    deleted.region AS oldregion,
    inserted.region AS newregion
WHERE region IS NULL;
GO

SELECT*
FROM dbo.Customers

/*========================================================
  5
  Update UK orders in dbo.H7_Orders
  Set shipcountry, shipregion, shipcity from dbo.Customers
========================================================*/
UPDATE O
SET
    O.ShipToCountry = C.country,
    O.ShipToRegion  = C.region,
    O.ShipToCity    = C.city
FROM dbo.Orders AS O
JOIN dbo.Customers AS C
    ON O.CustomerId = C.custid
WHERE C.country = N'UK';
GO


USE Northwinds2024Student;
GO

/*========================================================
  6
  Recreate dbo.H7_Orders and dbo.OrderDetails and populate them
========================================================*/


DROP TABLE IF EXISTS dbo.OrderDetails;
DROP TABLE IF EXISTS dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
    OrderId          INT           NOT NULL,
    CustomerId       INT           NULL,
    EmployeeId       INT           NOT NULL,
    ShipperId        INT           NOT NULL,
    OrderDate        DATE          NOT NULL,
    RequiredDate     DATE          NOT NULL,
    ShipToDate       DATE          NULL,
    Freight          MONEY         NOT NULL
        CONSTRAINT DFT_Orders_Freight DEFAULT (0),
    ShipToName       NVARCHAR(40)  NOT NULL,
    ShipToAddress    NVARCHAR(60)  NOT NULL,
    ShipToCity       NVARCHAR(15)  NOT NULL,
    ShipToRegion     NVARCHAR(15)  NULL,
    ShipToPostalCode NVARCHAR(10)  NULL,
    ShipToCountry    NVARCHAR(15)  NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderId)
);
GO

CREATE TABLE dbo.OrderDetails
(
    OrderId   INT           NOT NULL,
    ProductId INT           NOT NULL,
    UnitPrice MONEY         NOT NULL
        CONSTRAINT DFT_OrderDetails_UnitPrice DEFAULT (0),
    Quantity  SMALLINT      NOT NULL
        CONSTRAINT DFT_OrderDetails_Quantity DEFAULT (1),
    Discount  NUMERIC(4,3)  NOT NULL
        CONSTRAINT DFT_OrderDetails_Discount DEFAULT (0),
    CONSTRAINT PK_OrderDetails PRIMARY KEY (OrderId, ProductId),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId)
        REFERENCES dbo.Orders(OrderId),
    CONSTRAINT CHK_OrderDetails_Discount CHECK (Discount BETWEEN 0 AND 1),
    CONSTRAINT CHK_OrderDetails_Quantity CHECK (Quantity > 0),
    CONSTRAINT CHK_OrderDetails_UnitPrice CHECK (UnitPrice >= 0)
);
GO

INSERT INTO dbo.Orders
(
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
)
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
FROM Sales.[Order];
GO

INSERT INTO dbo.OrderDetails
(
    OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    Discount
)
SELECT
    OrderId,
    ProductId,
    UnitPrice,
    Quantity,
    DiscountPercentage
FROM Sales.OrderDetail;
GO

/*========================================================
  DELETE both tables successfully
========================================================*/
DELETE FROM dbo.OrderDetails;
DELETE FROM dbo.Orders;
GO

/*========================================================
  Cleanup
========================================================*/
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders, dbo.Customers;
GO