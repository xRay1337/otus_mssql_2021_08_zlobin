/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
	SELECT CustomerID
		  ,CustomerName
		  ,CreditLimit
		  ,PhoneNumber
	INTO Sales.CustomersDemoDml
	FROM Sales.Customers

	ALTER TABLE Sales.CustomersDemoDml
	ADD CONSTRAINT PK_CustomerID PRIMARY KEY CLUSTERED (CustomerID);

	SELECT * FROM Sales.CustomersDemoDml ORDER BY CustomerID DESC
*/

/*
1. Добавить в базу 5 записей используя insert в таблицу Customers или Suppliers.
*/

INSERT INTO Sales.CustomersDemoDml(CustomerID, CustomerName, CreditLimit, PhoneNumber)
VALUES	(1062, 'Zlobin1', 9999.00, '(913) 737-3455'),
		(1063, 'Zlobin2', 9999.00, '(913) 737-3456'),
		(1064, 'Zlobin3', 9999.00, '(913) 737-3457'),
		(1065, 'Zlobin4', 9999.00, '(913) 737-3458'),
		(1066, 'Zlobin5', 9999.00, '(913) 737-3459')

/*
2. Удалить 1 запись из Customers, которая была добавлена.
*/

DELETE
--SELECT *
FROM Sales.CustomersDemoDml
WHERE CustomerID = 1066
/*
3. Изменить одну запись, из добавленных через UPDATE.
*/

UPDATE Sales.CustomersDemoDml
SET PhoneNumber = '(913) 737-3459'
--SELECT * FROM Sales.CustomersDemoDml
WHERE CustomerID = 1065

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть.
*/

MERGE Sales.CustomersDemoDml AS TargetTable
USING
(
	SELECT *
	FROM (VALUES	(1062, 'Zlobin1', 9999.00, '(913) 737-3455'),	--без изменений
					(1063, 'Zlobin2', 9500.00, '(913) 737-3456'),	--лимит снижен
					(1064, 'Zlobin3', 9999.99, '(913) 737-3457'),	--лимит увеличен
					(1065, 'Zlobin4', 9999.00, '(913) 737-3458'),	--другой номер
					(1066, 'Zlobin5', 9999.00, '(913) 737-3459')	--отсутствует
	) AS Customers(CustomerID, CustomerName, CreditLimit, PhoneNumber)
) AS SourceTable
ON TargetTable.CustomerID = SourceTable.CustomerID
WHEN MATCHED AND (TargetTable.CustomerName <> SourceTable.CustomerName
					OR TargetTable.CreditLimit <> SourceTable.CreditLimit
					OR TargetTable.PhoneNumber <> SourceTable.PhoneNumber)
THEN UPDATE SET	TargetTable.CustomerName = SourceTable.CustomerName,
				TargetTable.CreditLimit = SourceTable.CreditLimit,
				TargetTable.PhoneNumber = SourceTable.PhoneNumber
WHEN NOT MATCHED
THEN INSERT(CustomerID, CustomerName, CreditLimit, PhoneNumber)
		VALUES(SourceTable.CustomerID, SourceTable.CustomerName, SourceTable.CreditLimit, SourceTable.PhoneNumber)
OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузит через bulk insert.
*/

-- Разрешить изменение дополнительных параметров. 
EXEC sp_configure 'show advanced options', 1;
GO  
-- Обновить текущее настроенное значение для дополнительных параметров. 
RECONFIGURE;
GO  
-- Включить функцию xp_cmdshell.
EXEC sp_configure 'xp_cmdshell', 1;
GO  
-- Обновить текущее значение для этой функции.  
RECONFIGURE;
GO  

SELECT @@SERVERNAME


EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[CustomersDemoDml]" out "D:\OTUS\MS SQL Developer\otus-mssql-2021-08-zlobin\HW10 - DML\Customers.txt" -T -w -t" , " -S DESKTOP-RIJ408G'


SELECT TOP(0) *
INTO Sales.CustomersDemoDmlCopy
FROM Sales.CustomersDemoDml


BULK INSERT Sales.CustomersDemoDmlCopy
FROM "D:\OTUS\MS SQL Developer\otus-mssql-2021-08-zlobin\HW10 - DML\Customers.txt"
WITH 
(
	BATCHSIZE = 1000,			--Указывает число строк в одном пакете
	DATAFILETYPE = 'widechar',	--Символьный файл с Unicode
	FIELDTERMINATOR = ' , ',	--разделитель столбцов
	ROWTERMINATOR = '\n',		--разделитель строк
	KEEPNULLS,					--пустым ячейкам присваиваться значения NULL
	TABLOCK						--указывает необходимость запроса блокировки уровня таблицы на время выполнения импорта
);


SELECT COUNT(*) FROM Sales.CustomersDemoDmlCopy

SELECT * FROM Sales.CustomersDemoDmlCopy




