--Report 1: Orders by Country
SELECT
    ShipToCountry,
    COUNT(*) AS OrderCount,
    SUM(Freight) AS TotalFreight,
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM Sales.[Order]
GROUP BY ShipToCountry
ORDER BY OrderCount DESC;

--Report 2: Active Customers by Order Volume
SELECT
    c.CustomerId,
    c.CustomerCompanyName,
    COUNT(o.OrderId) AS OrderCount,
    SUM(o.Freight) AS TotalFreight
FROM Sales.Customer AS c
JOIN Sales.[Order] AS o
    ON c.CustomerId = o.CustomerId
GROUP BY
    c.CustomerId,
    c.CustomerCompanyName
ORDER BY OrderCount DESC, TotalFreight DESC;

--Report 3: Freight by Shipper
SELECT
    s.ShipperId,
    s.ShipperCompanyName,
    COUNT(o.OrderId) AS OrdersHandled,
    SUM(o.Freight) AS TotalFreight,
    AVG(o.Freight) AS AvgFreight
FROM Sales.Shipper AS s
JOIN Sales.[Order] AS o
    ON s.ShipperId = o.ShipperId
GROUP BY
    s.ShipperId,
    s.ShipperCompanyName
ORDER BY TotalFreight DESC;

--Report 4: Employee Order Activity
SELECT
    e.EmployeeId,
    e.EmployeeFirstName,
    e.EmployeeLastName,
    COUNT(o.OrderId) AS OrderCount,
    SUM(o.Freight) AS TotalFreight
FROM HumanResources.Employee AS e
JOIN Sales.[Order] AS o
    ON e.EmployeeId = o.EmployeeId
GROUP BY
    e.EmployeeId,
    e.EmployeeFirstName,
    e.EmployeeLastName
ORDER BY OrderCount DESC, TotalFreight DESC;

--Report 5: Discount Analysis by Product
SELECT
    od.ProductId,
    SUM(od.Quantity) AS TotalQty,
    AVG(od.DiscountPercentage) AS AvgDiscountPct,
    SUM(od.UnitPrice * od.Quantity * (1 - od.DiscountPercentage / 100.0)) AS NetSales
FROM Sales.OrderDetail AS od
GROUP BY od.ProductId
ORDER BY AvgDiscountPct DESC, TotalQty DESC;