USE WideWorldImporters

GO

/*
1. Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION [Sales].[GetCustomerIdWithHighestPurchaseAmount]()
RETURNS int
AS
BEGIN
	RETURN
	(
		SELECT [CustomerID]
		FROM
		(
			SELECT TOP 1
					[CustomerID]
					,SUM([Quantity] * [UnitPrice]) AS [SalesAmount]
			FROM [Sales].[Orders] AS [O]
			JOIN [Sales].[OrderLines] AS [OL] ON [O].[OrderID] = [OL].[OrderID]
			GROUP BY [CustomerID]
			ORDER BY [SalesAmount] DESC
		) AS [Subquery]
	)
END

--SELECT [Sales].[GetCustomerIdWithHighestPurchaseAmount]() --149

GO

/*
2. Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупок по этому клиенту.
Использовать таблицы : Sales.Customers Sales.Invoices Sales.InvoiceLines
*/

CREATE PROCEDURE [Sales].[GetCustomerSalesAmount] @customerId int
WITH EXECUTE AS CALLER  
AS
SET NOCOUNT ON									--быз вывода количества строк
SET TRANSACTION ISOLATION LEVEL READ COMMITTED	--оставлю по умолчанию, т.к. хочу читать чистые данные 1 раз
	
SELECT SUM([Quantity] * [UnitPrice]) AS [SalesAmount]
FROM [Sales].[Invoices] AS [I]
JOIN [Sales].[OrderLines] AS [OL] ON [I].[OrderID] = [OL].[OrderID]
WHERE [CustomerID] = @customerId
GROUP BY [CustomerID]

--EXEC [Sales].[GetCustomerSalesAmount] @customerId = 149

GO

/*
3. Создать одинаковую функцию и хранимую процедуру, сравнить производительность.
*/


CREATE FUNCTION [Sales].[GetCustomerSalesAmountById](@customerId int)
RETURNS int
AS
BEGIN
	RETURN
	(
		SELECT SUM([Quantity] * [UnitPrice]) AS [SalesAmount]
		FROM [Sales].[Invoices] AS [I]
		JOIN [Sales].[OrderLines] AS [OL] ON [I].[OrderID] = [OL].[OrderID]
		WHERE [CustomerID] = @customerId
		GROUP BY [CustomerID]
	)
END

GO

--/*

SET STATISTICS IO, TIME ON

------------------------------------------------------------

--Процедура получения всех трат клиента по его id:
EXEC [Sales].[GetCustomerSalesAmount] @customerId = 149

--Результат первого запуска процедуры:
	--логических чтений 752
	--затраченное время = 490 мс.
--Результат 5го запуска процедуры:
	--логических чтений 396
	--затраченное время = 4 мс.
--Стоимость: 0,465603
------------------------------------------------------------

--Функция получения всех трат клиента по его id:
SELECT [Sales].[GetCustomerSalesAmountById](149)

--Результат первого запуска функции:
	--Время ЦП = 15 мс, затраченное время = 12 мс.
--Результат 5го запуска функции:
	--Время ЦП = 0 мс, затраченное время = 9 мс.
--Стоимость: 0,0000013

--Видим, что функция быстрее на 5 порядков.
--Почему так, пока что без вариантов, ожидал что процедура, на втором запуске будет выполняться быстрее.

--*/

GO

/*
4. Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
*/

CREATE FUNCTION [Sales].[GetCustomerTopPurchasedItemsById](@customerId int, @itemsCount int)
RETURNS TABLE
AS
RETURN
(
	SELECT TOP (@itemsCount)
			[SI].[StockItemName]
			,SUM([OL].[Quantity]) AS [PurchasedItemsCount]
	FROM [Warehouse].[StockItems]	AS [SI]
	JOIN [Sales].[OrderLines]		AS [OL] ON [SI].[StockItemID] = [OL].[StockItemID]
	JOIN [Sales].[Orders]			AS [SO] ON [OL].[OrderID] = [SO].[OrderID]
	WHERE [SO].[CustomerID] = @customerId
	GROUP BY [SO].[CustomerID], [SI].[StockItemName]
	ORDER BY [PurchasedItemsCount] DESC
)

GO   

DECLARE @itemsCount int = 3 --Выбираем TOP-3 товара по количеству покупок для каждого клиента

SELECT	[CustomerID]
		,[CustomerName]
		,[PurchasedItems].*
FROM [WideWorldImporters].[Sales].[Customers]
CROSS APPLY [Sales].[GetCustomerTopPurchasedItemsById]([CustomerID], @itemsCount) AS [PurchasedItems]
ORDER BY [CustomerID], [PurchasedItems].[PurchasedItemsCount] DESC

