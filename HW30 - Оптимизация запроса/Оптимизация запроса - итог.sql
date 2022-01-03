/*Итоги:
	Удалось сократить колличество чтений таблицы Invoices в 7 раз(это пожалуй главная заслуга), в время работы процессора в 3 раза
	За счёт выноса подзапросов во временную таблицу с последующей индексацией имеем прирост производительности
	Закомментированы ненужные джоины и сортировка
	Условие "DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0" заменено "Inv.InvoiceDate = ord.OrderDate" - исключено лишнее вычисление
	COUNT(ord.OrderID) заменён на COUNT(*) - думаю в этом есть небольшой прирост
	Повысилась удобочитаемость, результаты темповых таблиц можно переиспользовать в будущем
*/

SET STATISTICS IO, TIME ON

DROP TABLE IF EXISTS #totalSales
DROP TABLE IF EXISTS #StockItemsIdBySupplierId


SELECT	CustomerID,
		SUM(Total.UnitPrice * Total.Quantity) AS Total
INTO #TotalSales
FROM Sales.OrderLines	AS Total
JOIN Sales.Orders		AS OrdTotal ON OrdTotal.OrderID = Total.OrderID
GROUP BY CustomerID
HAVING SUM(Total.UnitPrice * Total.Quantity) > 250000

CREATE CLUSTERED INDEX IDX_CustomerID ON #TotalSales(CustomerID) --вынес расчёт в темповую таблицу, т.к. в табличной в переменной нужно сразу индекс указывать, что замедляет вставку, поэтому заполняю кучу, а потом соритрую


SELECT DISTINCT StockItemID
INTO #StockItemsIdBySupplierId
FROM Warehouse.StockItems
WHERE SupplierId = 12

CREATE CLUSTERED INDEX IDX_StockItemID ON #StockItemsIdBySupplierId(StockItemID) --вынес расчёт в темповую таблицу, т.к. в табличной переменной нужно сразу индекс указывать, что замедляет вставку, поэтому заполняю кучу, а потом соритрую


SELECT	ord.CustomerID,
		det.StockItemID,
		SUM(det.UnitPrice),
		SUM(det.Quantity),
		COUNT(*) --ord.OrderID NOT NULL, поэтому можно считать *, а не проверять каждый раз поле на NULL
FROM #TotalSales						AS ordTotal
JOIN Sales.Orders						AS ord		 ON ordTotal.CustomerID = ord.CustomerID
JOIN Sales.OrderLines					AS det		 ON det.OrderID = ord.OrderID
JOIN #StockItemsIdBySupplierId			AS It		 ON It.StockItemID = det.StockItemID
JOIN Sales.Invoices						AS Inv		 ON Inv.OrderID = ord.OrderID
/*Неиспользуемые джоины, если нужны, то раскомментировать
JOIN Sales.CustomerTransactions			AS Trans	 ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions	AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
*/
WHERE Inv.InvoiceDate = ord.OrderDate --Вместо DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0. Лишнее вычисление, типы данных совпадают
	AND Inv.BillToCustomerID <> ord.CustomerID
GROUP BY ord.CustomerID, det.StockItemID
--ORDER BY ord.CustomerID, det.StockItemID --Не ясно, нужна ли сортировка, если нужна, то раскомментировать

--3 619

/*Было

Таблица "StockItemTransactions".	Число просмотров 1, логических чтений 0, физических чтений 0.
Таблица "OrderLines".				Число просмотров 4, логических чтений 0, физических чтений 0.
Таблица "CustomerTransactions".		Число просмотров 5, логических чтений 261, физических чтений 4.
Таблица "Orders".					Число просмотров 2, логических чтений 883, физических чтений 4.
Таблица "Invoices".					Число просмотров 1, логических чтений 76422, физических чтений 2.
Таблица "StockItems".				Число просмотров 1, логических чтений 2, физических чтений 1.

Время ЦП = 937 мс, затраченное время = 4502 мс.

*/

/*Стало

Таблица "OrderLines".					Число просмотров 2, логических чтений 0, физических чтений 0.
Таблица "Orders".						Число просмотров 1, логических чтений 191, физических чтений 1.

Таблица "StockItems".					Число просмотров 1, логических чтений 2, физических чтений 1.

Таблица "#StockItemsIdBySupplierId".	Число просмотров 1, логических чтений 2, физических чтений 0.
Таблица "OrderLines".					Число просмотров 8, логических чтений 0, физических чтений 0.
Таблица "Orders".						Число просмотров 5, логических чтений 725, физических чтений 3.
Таблица "#totalSales".					Число просмотров 5, логических чтений 7, физических чтений 0.
Таблица "Invoices".						Число просмотров 5, логических чтений 11580, физических чтений 3.

Время ЦП = 344 мс, затраченное время = 3216 мс.

*/