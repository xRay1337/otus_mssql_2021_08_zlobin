/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29  | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
SET STATISTICS TIME, IO ON

SELECT InvoiceID AS [Id продажи],
		CustomerName AS [Название клиента],
		InvoiceDate AS [Дата продажи],
		(Quantity * UnitPrice) AS [Сумма продажи],
		(	
			SELECT SUM(Quantity * UnitPrice)
			FROM Sales.Invoices AS InvoicesSub
			JOIN Sales.OrderLines ON InvoicesSub.OrderID = OrderLines.OrderID
			WHERE InvoiceDate >= '20150101'
				AND	EOMONTH(InvoicesSub.InvoiceDate) <= EOMONTH(Invoices.InvoiceDate)
		) AS [Нарастающий итог по месяцу]

FROM Sales.Invoices
JOIN Sales.OrderLines ON Invoices.OrderID = OrderLines.OrderID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
WHERE InvoiceDate >= '20150101' --AND InvoiceDate <= '20150331'
ORDER BY [Дата продажи]

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/


SELECT InvoiceID AS [Id продажи],
		CustomerName AS [Название клиента],
		InvoiceDate AS [Дата продажи],
		(Quantity * UnitPrice) AS [Сумма продажи],
		SUM(Quantity * UnitPrice) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate) RANGE UNBOUNDED PRECEDING) AS [Нарастающий итог по месяцу]
FROM Sales.Invoices
JOIN Sales.OrderLines ON Invoices.OrderID = OrderLines.OrderID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
WHERE InvoiceDate >= '20150101' --AND InvoiceDate <= '20150331'
ORDER BY [Дата продажи]

--Стоимость: запрос1 / запрос2 = 95% / 5%

--Первый запрос:
--(затронуто строк: 16934)
--Таблица "OrderLines". Число просмотров 156, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 326, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 78, пропущено 0.
--Таблица "Worktable". Число просмотров 77, логических чтений 149375, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Workfile". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 2, логических чтений 22800, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Customers". Число просмотров 1, логических чтений 40, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

--Второй запрос:
--(затронуто строк: 16934)
--Таблица "OrderLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 163, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 1, логических чтений 11400, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Customers". Число просмотров 1, логических чтений 40, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

--Итог: очень много логических чтений в первом случае

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;WITH CteGroupBy AS
(
	SELECT 	MONTH(InvoiceDate)	AS [Месяц],
			StockItemName		AS [Товар],
			SUM(Quantity)		AS [Кол-во продаж]
	FROM Sales.Invoices
	JOIN Sales.OrderLines ON Invoices.OrderID = OrderLines.OrderID
	JOIN Warehouse.StockItems ON OrderLines.StockItemID = StockItems.StockItemID
	WHERE InvoiceDate BETWEEN '20160101' AND '20161231'
	GROUP BY MONTH(InvoiceDate), StockItemName
), CteRowNumber AS
(
	SELECT	[Месяц],
			[Товар],
			[Кол-во продаж],
			ROW_NUMBER() OVER(PARTITION BY [Месяц] ORDER BY [Кол-во продаж] DESC) AS [RowNumber]
	FROM CteGroupBy
)
SELECT	[Месяц],
		[Товар],
		[Кол-во продаж]
FROM CteRowNumber
WHERE RowNumber IN (1, 2)
ORDER BY [Месяц], [Кол-во продаж] DESC

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT	StockItemID
		,StockItemName
		,Brand
		,UnitPrice
		,ROW_NUMBER() OVER(PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName) AS [Номер записи по первой букве]
		,SUM(QuantityPerOuter) OVER() AS [Общее кол-во товаров]
		,SUM(QuantityPerOuter) OVER(PARTITION BY LEFT(StockItemName, 1)) AS [Общее кол-во товара по первой букве]
		,LEAD(StockItemID) OVER(ORDER BY StockItemName) AS [След. id товара]
		,LAG(StockItemID) OVER(ORDER BY StockItemName) AS [Пред. id товара]
		,LAG(StockItemName, 2, 'No items') OVER(ORDER BY StockItemName) AS [Названия товара 2 строки назад]
		,NTILE(30) OVER(ORDER BY TypicalWeightPerUnit) AS [Группа по весу]
FROM Warehouse.StockItems
ORDER BY StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP 1 WITH TIES
		SalespersonPersonID AS [ID сотрудника]
		,SUBSTRING(FullName, CHARINDEX(' ', FullName) + 1, 50) AS [Фамилия сотрудника]
		,Invoices.CustomerID AS [ID клиента]
		,CustomerName AS [Название клиента]
		,InvoiceDate AS [Дата продажи]
		,(Quantity * UnitPrice) AS [Сумма сделка]
FROM Sales.Invoices
JOIN Sales.OrderLines ON Invoices.OrderID = OrderLines.OrderID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
JOIN Application.People ON Invoices.SalespersonPersonID = People.PersonID
ORDER BY ROW_NUMBER() OVER (PARTITION BY SalespersonPersonID ORDER BY Invoices.LastEditedWhen DESC)

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT TOP 1 WITH TIES
		Invoices.CustomerID		AS [ID клиента]
		,CustomerName			AS [Название клиента]
		,OrderLines.StockItemID AS [ID товара]
		,UnitPrice				AS [Цена]
		,InvoiceDate			AS [Дата покупки]
FROM Sales.Invoices
JOIN Sales.OrderLines ON Invoices.OrderID = OrderLines.OrderID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
ORDER BY ROW_NUMBER() OVER (PARTITION BY Invoices.CustomerID ORDER BY UnitPrice DESC)

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 