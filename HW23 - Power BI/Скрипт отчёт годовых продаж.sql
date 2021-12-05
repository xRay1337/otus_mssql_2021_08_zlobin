/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
SELECT	[StockItemName] AS [Товар]
		,YEAR([OrderDate]) AS [Год продажи]
		,SUM([OL].[UnitPrice] * [PickedQuantity]) AS [Выручка]
FROM [WideWorldImporters].[Sales].[OrderLines] AS [OL]
JOIN [WideWorldImporters].[Warehouse].[StockItems] AS [SI] ON [OL].[StockItemID] = [SI].[StockItemID]
JOIN [WideWorldImporters].[Sales].[Orders] AS [O] ON [OL].[OrderID] = [O].[OrderID]
GROUP BY [StockItemName], YEAR([OrderDate])