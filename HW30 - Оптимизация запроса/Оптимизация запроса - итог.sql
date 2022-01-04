/*Итоги:
	Сократилось количество чтений таблицы Invoices в 7 раз(это пожалуй главная заслуга), а время работы процессора в 9 раз
	За счёт выноса 1го подзапроса во временную таблицу имеем прирост производительности(с CTE заметно хуже)
	Вместо 2го подзапроса сделал джоин с Warehouse.StockItems
	Удалил ненужные джоины(JOIN CustomerTransactions и JOIN StockItemTransactions) и сортировку(ORDER BY ord.CustomerID, det.StockItemID)
	Условие "DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0" заменено "Inv.InvoiceDate = ord.OrderDate" - исключено лишнее вычисление
	COUNT(ord.OrderID) заменён на COUNT(*) - думаю в этом есть небольшой прирост, т.к. не требуется проверка на NULL
	Заметно повысилась удобочитаемость
*/

SET STATISTICS IO, TIME ON

DROP TABLE IF EXISTS #CustomersId


SELECT CustomerID
INTO #CustomersId
FROM Sales.Orders		AS O
JOIN Sales.OrderLines	AS OL ON O.OrderID = OL.OrderID
GROUP BY CustomerID
HAVING SUM(OL.UnitPrice * OL.Quantity) > 250000


SELECT	O.CustomerID,
		OL.StockItemID,
		SUM(OL.UnitPrice)	AS UnitPrice,
		SUM(OL.Quantity)	AS Quantity,
		COUNT(*)			AS OrdersCount
FROM #CustomersId						AS CI
JOIN Sales.Orders						AS O	ON CI.CustomerID = O.CustomerID
JOIN Sales.OrderLines					AS OL	ON O.OrderID = OL.OrderID
JOIN Sales.Invoices						AS I	ON O.OrderID = I.OrderID
JOIN Warehouse.StockItems				AS SI	ON OL.StockItemID = SI.StockItemID
WHERE O.OrderDate = I.InvoiceDate
	AND O.CustomerID <> I.BillToCustomerID
	AND SI.SupplierId = 12
GROUP BY O.CustomerID, OL.StockItemID

--3 619

/*Было

Таблица "Orders".					Число просмотров 2, логических чтений 883, физических чтений 4.
Таблица "OrderLines".				Число просмотров 4, логических чтений 0, физических чтений 0.
Таблица "Invoices".					Число просмотров 1, логических чтений 76422, физических чтений 2.
Таблица "StockItems".				Число просмотров 1, логических чтений 2, физических чтений 1.
Таблица "CustomerTransactions".		Число просмотров 5, логических чтений 261, физических чтений 4.
Таблица "StockItemTransactions".	Число просмотров 1, логических чтений 0, физических чтений 0.

Время ЦП = 937 мс, затраченное время = 4502 мс.

*/

/*Стало

Таблица "Orders".								Число просмотров 1, логических чтений 191, физических чтений 0.
Таблица "OrderLines".							Число просмотров 2, логических чтений 0, физических чтений 0.

Таблица "#CustomerIdWithTotalSalesOverValue".	Число просмотров 5, логических чтений 1, физических чтений 0.
Таблица "Orders".								Число просмотров 5, логических чтений 725, физических чтений 0.
Таблица "OrderLines".							Число просмотров 8, логических чтений 0, физических чтений 0.
Таблица "Invoices".								Число просмотров 5, логических чтений 11994, физических чтений 0.
Таблица "StockItems".							Число просмотров 1, логических чтений 2, физических чтений 0.

Время ЦП = 109 мс, затраченное время = 278 мс.

*/