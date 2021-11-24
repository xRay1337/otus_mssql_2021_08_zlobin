
EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0;
RECONFIGURE

GO

CREATE ASSEMBLY [LibSQL]
FROM 'C:\Users\zlovi\source\repos\LibSQL\LibSQL\bin\Release\netstandard2.0\LibSQL.dll'
WITH PERMISSION_SET = SAFE;

GO

CREATE FUNCTION IsMatched(@str NVARCHAR(MAX), @patern NVARCHAR(MAX))
RETURNS INT
AS EXTERNAL NAME [LibSQL].[LibSQL.SqlFunctions].[IsMatched]

GO

CREATE FUNCTION GetRandomNumber(@min INT, @max INT)
RETURNS INT
AS EXTERNAL NAME [LibSQL].[LibSQL.SqlFunctions].[GetRandomNumber]

GO

/* TEST IsMatched
SELECT DISTINCT	[Description]
FROM [WideWorldImporters].[Sales].[InvoiceLines]
WHERE dbo.IsMatched([Description], 'USB [a-mA-M]*') = 1
ORDER BY [Description]

SELECT DISTINCT	[Description]
FROM [WideWorldImporters].[Sales].[InvoiceLines]
WHERE [Description] LIKE 'USB [a-mA-M]%'
ORDER BY [Description]
*/


/* TEST GetRandomNumber
declare @rowCount int = 0
declare @min int = 6
declare @max int = 18

WHILE (@rowCount < 10)
BEGIN
    print dbo.GetRandomNumber(@min, @max)
	set @rowCount += 1
END
*/
