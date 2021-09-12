/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT	[StockItemID],
		[StockItemName]
FROM [WideWorldImporters].[Warehouse].[StockItems]
WHERE [StockItemName] LIKE '%urgent%' OR [StockItemName] LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT	[S].[SupplierID],
		[S].[SupplierName]
FROM [WideWorldImporters].[Purchasing].[PurchaseOrders] AS [PO]
FULL JOIN [WideWorldImporters].[Purchasing].[Suppliers] AS [S] ON [PO].[SupplierID] = [S].[SupplierID]
WHERE [PurchaseOrderID] IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT	[O].[OrderID],
		CONVERT(NVARCHAR(10), [O].[OrderDate], 104) AS [OrderDate],
		DATENAME(MONTH, [O].[OrderDate]) AS [Month Name],
		DATENAME(QUARTER, [O].[OrderDate]) AS [Quarter],
		CASE WHEN MONTH([O].[OrderDate]) < 5 THEN 1
			WHEN MONTH([O].[OrderDate]) < 9 THEN 2
		ELSE 3 END AS [Third of the year],
		[C].[CustomerName]
FROM [WideWorldImporters].[Sales].[Orders] AS [O]
JOIN [WideWorldImporters].[Sales].[OrderLines] AS [OL] ON [O].[OrderID] = [OL].[OrderID]
	AND ([UnitPrice] > 100 OR [Quantity] > 20)
	AND [O].[PickingCompletedWhen] IS NOT NULL
JOIN [WideWorldImporters].[Sales].[Customers] AS [C] ON [O].[CustomerID] = [C].[CustomerID]
ORDER BY [Quarter], [Third of the year], [OrderDate] OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT	[DM].[DeliveryMethodName],
		[PO].[ExpectedDeliveryDate],
		[S].[SupplierName],
		[P].[FullName] AS [ContactPerson]
FROM [WideWorldImporters].[Purchasing].[PurchaseOrders] AS [PO]
JOIN [WideWorldImporters].[Application].[DeliveryMethods] AS [DM] ON [PO].[DeliveryMethodID] = [DM].[DeliveryMethodID]
	AND ([ExpectedDeliveryDate] BETWEEN '20130101' AND '20130131' AND [DeliveryMethodName] = 'Air Freight'
		OR [DeliveryMethodName] = 'Refrigerated Air Freight' AND [IsOrderFinalized] = 1)
JOIN [WideWorldImporters].[Purchasing].[Suppliers] AS [S] ON [PO].[SupplierID] = [S].[SupplierID]
JOIN [WideWorldImporters].[Application].[People] AS [P] ON [PO].[ContactPersonID] = [P].[PersonID]

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP (10) 
		[OrderDate],
		[CP].[FullName] AS [Customer],
		[SP].[FullName] AS [Seller]
FROM [WideWorldImporters].[Sales].[Orders] AS [O]
JOIN [WideWorldImporters].[Application].[People] AS [CP] ON [O].[ContactPersonID] = [CP].[PersonID]
JOIN [WideWorldImporters].[Application].[People] AS [SP] ON [O].[SalespersonPersonID] = [SP].[PersonID]
ORDER BY [OrderDate] DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT 	[O].[ContactPersonID],
		[P].[FullName],
		[P].[PhoneNumber]
FROM [WideWorldImporters].[Sales].[Orders]			AS [O]
JOIN [WideWorldImporters].[Application].[People]	AS [P] ON [O].[ContactPersonID] = [P].[PersonID]
JOIN [WideWorldImporters].[Sales].[OrderLines]		AS [OL] ON [O].[OrderID] = [OL].[OrderID]
JOIN [WideWorldImporters].[Warehouse].[StockItems]	AS [SI] ON [OL].[StockItemID] = [SI].[StockItemID]
	AND [StockItemName] = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT	YEAR([InvoiceDate]) AS [Год продажи],
		MONTH([InvoiceDate]) AS [Месяц продажи],
		AVG([UnitPrice]) AS [Средняя цена за месяц по всем товарам],
		SUM([Quantity] * [UnitPrice]) AS [Общая сумма продаж за месяц]
FROM [WideWorldImporters].[Sales].[Invoices] AS [I]
JOIN [WideWorldImporters].[Sales].[OrderLines] AS [OL] ON [I].[OrderID] = [OL].[OrderID]
GROUP BY YEAR([InvoiceDate]), MONTH([InvoiceDate])
ORDER BY [Год продажи], [Месяц продажи]

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT	YEAR([InvoiceDate]) AS [Год продажи],
		MONTH([InvoiceDate]) AS [Месяц продажи],
		SUM([Quantity] * [UnitPrice]) AS [Общая сумма продаж]
FROM [WideWorldImporters].[Sales].[Invoices] AS [I]
JOIN [WideWorldImporters].[Sales].[OrderLines] AS [OL] ON [I].[OrderID] = [OL].[OrderID]
GROUP BY YEAR([InvoiceDate]), MONTH([InvoiceDate])
HAVING SUM([Quantity] * [UnitPrice]) > 10000
ORDER BY [Год продажи], [Месяц продажи]

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT	YEAR([I].[InvoiceDate]) AS [Год продажи],
		MONTH([InvoiceDate]) AS [Месяц продажи],
		[SI].[StockItemName] AS [Наименование товара],
		SUM([OL].[Quantity] * [OL].[UnitPrice]) AS [Сумма продаж],
		MIN([I].[InvoiceDate]) AS [Дата первой продажи],
		SUM([OL].[Quantity]) AS [Количество проданного]
FROM [WideWorldImporters].[Sales].[Invoices] AS [I]
JOIN [WideWorldImporters].[Sales].[OrderLines] AS [OL] ON [I].[OrderID] = [OL].[OrderID]
JOIN [WideWorldImporters].[Warehouse].[StockItems] AS [SI] ON [OL].[StockItemID] = [SI].[StockItemID]
GROUP BY [SI].[StockItemName], YEAR([InvoiceDate]), MONTH([InvoiceDate])
ORDER BY [Год продажи], [Месяц продажи], [Наименование товара]

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
