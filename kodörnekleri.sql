-- Soru 1
-- 1)Çalışanların ad ve soyadlarını getirir
WITH EmployeeNames AS (
    SELECT FirstName, LastName
    FROM HumanResources.Employee AS e
    JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
)
SELECT * FROM EmployeeNames;


-- 2)Liste fiyatı 500 TL'den büyük olan ürünleri listeler
WITH Expensive AS (
    SELECT Name, ListPrice
    FROM Production.Product
    WHERE ListPrice > 500
)
SELECT * FROM Expensive;


-- 3)Çalışanların ID, ad, soyad ve unvan bilgilerini getirir
WITH JobTitles AS (
    SELECT e.BusinessEntityID, p.FirstName, p.LastName, e.JobTitle
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
)
SELECT * FROM JobTitles;


-- 4)1'den 10'a kadar sayı üretir (RECURSIVE CTE örneği)
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM Numbers
    WHERE n < 10
)
SELECT * FROM Numbers;


-- 5)İlk 100 çalışanın ID ve unvanını listeler
WITH FirstEmployees AS (
    SELECT TOP 100 BusinessEntityID, JobTitle
    FROM HumanResources.Employee
)
SELECT * FROM FirstEmployees;

WITH FirstEmployees AS (
    SELECT TOP 100 BusinessEntityID, JobTitle
    FROM HumanResources.Employee
)
SELECT * FROM FirstEmployees;


-- 6)Unvanı "Design Engineer" olan çalışanları listeler
WITH Engineers AS (
    SELECT BusinessEntityID, JobTitle
    FROM HumanResources.Employee
    WHERE JobTitle = 'Design Engineer'
)
SELECT * FROM Engineers;


-- 7) Liste fiyatı 0 olan ürünleri listeler
 WITH ZeroPrice AS (
    SELECT ProductID, Name, ListPrice
    FROM Production.Product
    WHERE ListPrice = 0
)
SELECT * FROM ZeroPrice;


-- 8)Envanterde stoğu olan ürünleri getirir
WITH Inventory AS (
    SELECT ProductID, LocationID, Quantity
    FROM Production.ProductInventory
    WHERE Quantity > 0
)
SELECT * FROM Inventory;


-- 9)1 Ocak 2020'den sonra verilen siparişleri listeler
WITH RecentOrders AS (
    SELECT SalesOrderID, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE OrderDate > '2020-01-01'
)
SELECT * FROM RecentOrders;


-- 10) 100'den fazla sipariş vermiş müşterileri getirir
WITH FrequentCustomers AS (
    SELECT CustomerID, COUNT(*) AS Orders
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(*) > 100
)
SELECT * FROM FrequentCustomers;


-- Soru 2
--Ürün stok adedini kontrol eden 
CREATE PROCEDURE CheckProductStock
    @ProductID INT
AS
BEGIN
    DECLARE @Stock INT;
    SELECT @Stock = Stock FROM Products WHERE ProductID = @ProductID;
    IF @Stock IS NULL
        PRINT 'Ürün bulunamadı.';
    ELSE
        PRINT 'Stok miktarı: ' + CAST(@Stock AS VARCHAR);
END;


--Ürün satıldıktan sonra stok miktarını azaltan 
CREATE PROCEDURE ReduceProductStock
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    DECLARE @CurrentStock INT;
    SELECT @CurrentStock = Stock FROM Products WHERE ProductID = @ProductID;
    IF @CurrentStock IS NULL
        THROW 50001, 'Ürün bulunamadı.', 1;
    ELSE IF @CurrentStock < @Quantity
        THROW 50002, 'Yeterli stok yok.', 1;
    ELSE
    BEGIN
        UPDATE Products
        SET Stock = Stock - @Quantity
        WHERE ProductID = @ProductID;
    END
END;


--Sipariş oluşturulduysa notification bilgisini çıkaran   
CREATE PROCEDURE CreateOrderWithNotification
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Stok kontrol ve azaltma
        EXEC ReduceProductStock @ProductID, @Quantity;
        -- Sipariş oluştur
        INSERT INTO Orders (ProductID, Quantity)
        VALUES (@ProductID, @Quantity);
        -- Bildirim oluştur
        DECLARE @ProductName VARCHAR(100);
        SELECT @ProductName = ProductName FROM Products WHERE ProductID = @ProductID;
        INSERT INTO Notifications (Message)
        VALUES ('Yeni sipariş oluşturuldu: ' + @ProductName + ', Adet: ' + CAST(@Quantity AS VARCHAR));
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
