
EXEC sp_configure 'clr strict security', 0;
RECONFIGURE
FROM 'C:\Users\zlovi\source\repos\LibSQL\LibSQL\bin\Release\netstandard2.0\LibSQL.dll'
WITH PERMISSION_SET = SAFE;

GO

CREATE FUNCTION IsMatched(@str NVARCHAR(MAX), @patern NVARCHAR(MAX))
RETURNS INT
AS EXTERNAL NAME [LibSQL].[LibSQL.SqlFunctions].[IsMatched]