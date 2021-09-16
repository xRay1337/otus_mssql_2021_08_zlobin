/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog

* https://dataedo.com/samples/html/WideWorldImporters/doc/WideWorldImporters_5/tables/Sales_Invoices_3824.html
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE [WideWorldImporters]

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT	[PersonID],
		[FullName]
FROM [Application].[People]
WHERE [IsSalesperson] = 1
	AND [PersonID] NOT IN (	SELECT [SalespersonPersonID]
							FROM [Sales].[Invoices]
							WHERE [InvoiceDate] = '20150704')

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--2.1 Подзапрос:
SELECT	[StockItemID],
		[StockItemName],
		[UnitPrice]
FROM [Warehouse].[StockItems]
WHERE [UnitPrice] = (SELECT MIN([UnitPrice]) FROM [Warehouse].[StockItems])

--2.2 CTE:
;WITH [CteMinUnitPrice] AS
(
	SELECT MIN([UnitPrice]) AS [MinPrice]
	FROM [WideWorldImporters].[Warehouse].[StockItems]
)
SELECT	[StockItemID],
		[StockItemName],
		[UnitPrice]
FROM [Warehouse].[StockItems]
WHERE [UnitPrice] = (SELECT [MinPrice] FROM [CteMinUnitPrice])

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--3.1 Подзапрос:
SELECT	[PersonID],
		[FullName]
FROM [Application].[People]
WHERE [PersonID] IN (	SELECT TOP (5) [CustomerID]
						FROM [Sales].[CustomerTransactions]
						ORDER BY [TransactionAmount] DESC)

--3.2 CTE:
;WITH [CteTopTran] AS
(
	SELECT TOP (5) [CustomerID]
	FROM [Sales].[CustomerTransactions]
	ORDER BY [TransactionAmount] DESC
)
SELECT	[PersonID],
		[FullName]
FROM [Application].[People]
WHERE [PersonID] IN (SELECT [CustomerID] FROM [CteTopTran])
/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
--4.1 Подзапрос:
SELECT DISTINCT
		[Cities].[CityID],
		[Cities].[CityName],
		[People].[FullName] AS [PackedByPerson]
FROM [Sales].[Invoices]
JOIN [Application].[People]		ON [Invoices].[PackedByPersonID] = [People].[PersonID]	--Упаковщики
JOIN [Sales].[Customers]		ON [Invoices].[CustomerID] = [Customers].[CustomerID]	--Клиенты
JOIN [Application].[Cities]		ON [Customers].[DeliveryCityID] = [Cities].[CityID]		--Город клента
JOIN [Sales].[OrderLines]		ON [Invoices].[OrderID] = [OrderLines].[OrderID]		--Детали заказа
WHERE [OrderLines].[StockItemID] IN (SELECT TOP (3) [StockItemID]
									FROM [Warehouse].[StockItems]
									ORDER BY [UnitPrice] DESC)
ORDER BY [CityName], [PackedByPerson]

--4.2 CTE:
;WITH [CteTopUnitPrice] AS
(
	SELECT TOP (3) [StockItemID]
	FROM [Warehouse].[StockItems]
	ORDER BY [UnitPrice] DESC
)
SELECT DISTINCT
		[Cities].[CityID],
		[Cities].[CityName],
		[People].[FullName] AS [PackedByPerson]
FROM [Sales].[Invoices]
JOIN [Application].[People]		ON [Invoices].[PackedByPersonID] = [People].[PersonID]	--Упаковщики
JOIN [Sales].[Customers]		ON [Invoices].[CustomerID] = [Customers].[CustomerID]	--Клиенты
JOIN [Application].[Cities]		ON [Customers].[DeliveryCityID] = [Cities].[CityID]		--Город клента
JOIN [Sales].[OrderLines]		ON [Invoices].[OrderID] = [OrderLines].[OrderID]		--Детали заказа
WHERE [OrderLines].[StockItemID] IN (SELECT [StockItemID] FROM [CteTopUnitPrice])
ORDER BY [CityName], [PackedByPerson]

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

--Было:
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

--Запрос для вывода клиентов с покупками от 27000. В конце стоимость купленных и выбранных товаров.
--Стало:
;WITH CteSalesTotals AS --Сумма покупок от 27К
(
	SELECT	InvoiceId,
			SUM(Quantity * UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity * UnitPrice) > 27000
), CtePickingCompletedWhen AS
(
	SELECT OrderId
	FROM Sales.Orders
	WHERE Orders.PickingCompletedWhen IS NOT NULL
)
SELECT	Invoices.InvoiceID,												--ID продажи
		Invoices.InvoiceDate,											--Дата продажи
		People.FullName AS SalesPersonName,								--Имя продавца
		SalesTotals.TotalSumm AS TotalSummByInvoice,					--Сумма всех покупок
		(SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT OrderId
									FROM CtePickingCompletedWhen
									WHERE CtePickingCompletedWhen.OrderId = Invoices.OrderId)
		) AS TotalSummForPickedItems									--Стоимость выбранных товаров с датой завершения комплектации заказа
FROM Sales.Invoices
JOIN [Application].People ON People.PersonID = Invoices.SalespersonPersonID			--Соединения для имени продавца
JOIN CteSalesTotals AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID	--Сумма покупок от 27К
ORDER BY TotalSumm DESC

