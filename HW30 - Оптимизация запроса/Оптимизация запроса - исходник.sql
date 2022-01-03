set statistics io, time on

Select	ord.CustomerID,
		det.StockItemID,
		SUM(det.UnitPrice),
		SUM(det.Quantity),
		COUNT(ord.OrderID)
FROM Sales.Orders						AS ord
JOIN Sales.OrderLines					AS det		 ON det.OrderID = ord.OrderID
JOIN Sales.Invoices						AS Inv		 ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions			AS Trans	 ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions	AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND (Select SupplierId
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


/*Ѕыло
3 619
“аблица "StockItemTransactions". „исло просмотров 1, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 66, lob физических чтений 1, lob упреждающих чтений 130.
“аблица "StockItemTransactions". —читано сегментов 1, пропущено 0.
“аблица "OrderLines". „исло просмотров 4, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 518, lob физических чтений 5, lob упреждающих чтений 795.
“аблица "OrderLines". —читано сегментов 2, пропущено 0.
“аблица "Worktable". „исло просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
“аблица "CustomerTransactions". „исло просмотров 5, логических чтений 261, физических чтений 4, упреждающих чтений 253, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
“аблица "Orders". „исло просмотров 2, логических чтений 883, физических чтений 4, упреждающих чтений 849, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
“аблица "Invoices". „исло просмотров 1, логических чтений 76422, физических чтений 2, упреждающих чтений 11606, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
“аблица "StockItems". „исло просмотров 1, логических чтений 2, физических чтений 1, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

¬рем€ ÷ѕ = 937 мс
*/