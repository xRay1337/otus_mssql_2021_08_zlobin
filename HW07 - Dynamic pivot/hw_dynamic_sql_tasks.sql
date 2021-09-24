/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @script AS NVARCHAR(MAX)
DECLARE @columns AS NVARCHAR(MAX)
 
SELECT @columns = ISNULL(@columns + ', ', '') + QUOTENAME(REPLACE(REPLACE(CustomerName, 'Tailspin Toys (', ''), ')', ''))
FROM Sales.Customers
WHERE CustomerID BETWEEN 2 AND 6

SET @script = N'
;WITH CTE AS
(
	SELECT	CONVERT(varchar(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, InvoiceDate), 0), 104) AS StartOfMonth,
			REPLACE(REPLACE(CustomerName, ''Tailspin Toys ('', ''''), '')'', '''') AS CustomerName,
			1 AS Invoice
	FROM Sales.Invoices
	JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE Invoices.CustomerID BETWEEN 2 AND 6
)
SELECT StartOfMonth, ' + @columns + '
FROM CTE
PIVOT (COUNT(Invoice) FOR CustomerName IN (' + @columns + ')) AS [Pivot]
ORDER BY CAST(StartOfMonth AS DATE)
'

EXEC sp_executesql @script
