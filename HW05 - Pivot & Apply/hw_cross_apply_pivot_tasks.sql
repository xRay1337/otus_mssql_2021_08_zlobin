/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;WITH CTE AS
(
	SELECT	CONVERT(varchar(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, InvoiceDate), 0), 104) AS StartOfMonth,
			REPLACE(REPLACE(CustomerName, 'Tailspin Toys (', ''), ')', '') AS CustomerName,
			1 AS Invoice
	FROM Sales.Invoices
	JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE Invoices.CustomerID BETWEEN 2 AND 6
)
SELECT StartOfMonth, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
FROM CTE
PIVOT (COUNT(Invoice) FOR CustomerName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])) AS [Pivot]
ORDER BY CAST(StartOfMonth AS DATE)

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

;WITH CTE AS
(
	SELECT	CustomerName,
			DeliveryAddressLine1,
			DeliveryAddressLine2,
			PostalAddressLine1,
			PostalAddressLine2
	FROM Sales.Customers
	WHERE CustomerName LIKE '%Tailspin Toys%'
)
SELECT	CustomerName,
		AddressLine
FROM CTE
UNPIVOT
(
	AddressLine FOR PostalDeliveryAddressLine IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)
) AS UP
ORDER BY CustomerName, AddressLine

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT	[CountryID],
		[CountryName],
		[IsoAlpha3Code] AS [Code]
FROM [Application].[Countries]
UNION ALL
SELECT	[CountryID],
		[CountryName],
		CAST([IsoNumericCode] AS varchar)
FROM [Application].[Countries]
ORDER BY [CountryID], [Code] DESC

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT	CustomerID,
		CustomerName,
		CA.*
FROM Sales.Customers
CROSS APPLY
(
	SELECT TOP (2)
			StockItemID,
			UnitPrice,
			OrderDate
	FROM Sales.Orders
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
	WHERE Orders.CustomerID = Customers.CustomerID
	ORDER BY UnitPrice DESC
) AS CA
