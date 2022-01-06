--GO
--USE [master]
--GO
--DROP DATABASE IF EXISTS [Organization]
--GO
--CREATE DATABASE [Organization]
--GO
USE [Organization]
--GO
--CREATE SCHEMA [CRM]
--GO
--CREATE SCHEMA [PersonalInfo]
--GO
--CREATE SCHEMA [OrgStructure]
--GO
--CREATE SCHEMA [Dimensions]
GO

CREATE TABLE [Dimensions].[Regions]
(
	[RegionId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[RegionName]		NVARCHAR(100) NOT NULL,
	[RegionTimezone]	VARCHAR(6),

	CONSTRAINT [CheckRegionTimezone]	CHECK (LEN([RegionTimezone]) IN (5, 6)),
	CONSTRAINT [UniqueRegionName]		UNIQUE ([RegionName])
)

CREATE TABLE [OrgStructure].[Positions]
(
	[PositionId]	INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[PositionName]	NVARCHAR(100) NOT NULL,

	CONSTRAINT [UniquePositionName] UNIQUE ([PositionName])
)

GO

/* Обычная [PersonalInfo].[Clients]
CREATE TABLE [PersonalInfo].[Clients]
(
	[ClientId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[ClientName]		NVARCHAR(100) NOT NULL,
	[ClientBirthday]	DATE,
	[ClientSex]			CHAR(1),
	[ClientMobilNumber]	VARCHAR(11) NOT NULL,
	[ClientEmail]		NVARCHAR(100),
	[ClientRegionId]	INT,
	CONSTRAINT [FkClientRegionId]	FOREIGN KEY ([ClientRegionId]) REFERENCES [Dimensions].[Regions]([RegionId]),
	CONSTRAINT [CheckSex]			CHECK ([ClientSex] IN ('M', 'W')),
	CONSTRAINT [CheckMobilNumber]	CHECK ([ClientMobilNumber] LIKE '[8][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT [CheckEmail]			CHECK ([ClientEmail] LIKE '%_@__%.__%')
)
*/

CREATE TABLE [PersonalInfo].[Clients]
(
	[ValidFrom]			DATETIME2 GENERATED ALWAYS AS ROW START DEFAULT SYSDATETIME(),
	[ValidTo]			DATETIME2 GENERATED ALWAYS AS ROW END	DEFAULT '9999-12-31 23:59:59.9999999',
	[ClientId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[LastName]			NVARCHAR(100) NOT NULL,
	[FirstName]			NVARCHAR(100) NOT NULL,
	[MiddleName]		NVARCHAR(100),
	[Birthday]			DATE,
	[Sex]				CHAR(1),
	[MobilNumber]		VARCHAR(11) NOT NULL,
	[AddMobilNumber]	VARCHAR(11),
	[Email]				NVARCHAR(100),
	[RegionId]			INT,

	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo]),
	CONSTRAINT [FkClientRegionId]		FOREIGN KEY ([RegionId]) REFERENCES [Dimensions].[Regions]([RegionId]),
	CONSTRAINT [CheckSex]				CHECK ([Sex] IN ('M', 'W')),
	CONSTRAINT [CheckMobilNumber]		CHECK ([MobilNumber] LIKE '[8][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT [CheckAddMobilNumber]	CHECK ([MobilNumber] LIKE '[8][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT [CheckEmail]				CHECK ([Email] LIKE '%_@__%.__%')
 )
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [PersonalInfo].[ClientsHistory]));
CREATE INDEX [IdxRegionId] ON [PersonalInfo].[Clients]([RegionId])

/* Обычная [PersonalInfo].[Employees]
CREATE TABLE [PersonalInfo].[Employees]
(
	[EmployeeId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[EmployeeLogin]			VARCHAR(50) NOT NULL,
	[EmployeeName]			NVARCHAR(100) NOT NULL,
	[EmployeePositionId]	INT,
	[DateOfEmployment]		DATE NOT NULL,
	[DateOfDismissal]		DATE,
	CONSTRAINT [FkEmployeePositionId]	FOREIGN KEY ([EmployeePositionId]) REFERENCES [OrgStructure].[Positions]([PositionId]),
	CONSTRAINT [CheckDateOfDismissal]	CHECK([DateOfDismissal] > [DateOfEmployment]),
)
CREATE INDEX [IdxEmployeePositionId] ON [PersonalInfo].[Employees]([EmployeePositionId])
*/

CREATE TABLE [PersonalInfo].[Employees]
(
	[ValidFrom]			DATETIME2 GENERATED ALWAYS AS ROW START DEFAULT SYSDATETIME(),
	[ValidTo]			DATETIME2 GENERATED ALWAYS AS ROW END	DEFAULT '9999-12-31 23:59:59.9999999',
	[EmployeeId]		INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[Login]				NVARCHAR(100) NOT NULL,
	[LastName]			NVARCHAR(100) NOT NULL,
	[FirstName]			NVARCHAR(100) NOT NULL,
	[MiddleName]		NVARCHAR(100),
	[Birthday]			DATE,
	[Sex]				CHAR(1),
	[PositionId]		INT,
	[DateOfEmployment]	DATE NOT NULL,
	[DateOfDismissal]	DATE,

	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
	CONSTRAINT [FkEmployeePositionId]	FOREIGN KEY ([PositionId]) REFERENCES [OrgStructure].[Positions]([PositionId]),
	CONSTRAINT [CheckDateOfDismissal]	CHECK([DateOfDismissal] > [DateOfEmployment]),
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [PersonalInfo].[EmployeesHistory]));
CREATE INDEX [IdxEmployeePositionId] ON [PersonalInfo].[Employees]([PositionId])

CREATE TABLE [OrgStructure].[Departments]
(
	[DepartmentId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[DepartmentName]		NVARCHAR(50) NOT NULL,
	[DepartmentManagerId]	INT,

	CONSTRAINT [FkDepartmentManagerId]	FOREIGN KEY ([DepartmentManagerId]) REFERENCES [PersonalInfo].[Employees]([EmployeeId]),
	CONSTRAINT [UniqueDepartmentName]	UNIQUE ([DepartmentName])
)
CREATE INDEX [IdxDepartmentManagerId] ON [OrgStructure].[Departments]([DepartmentManagerId])

CREATE TABLE [OrgStructure].[Groups]
(
	[GroupId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[GroupName]			NVARCHAR(50) NOT NULL,
	[GroupDepartmentId]	INT,
	[GroupManagerId]	INT,

	CONSTRAINT [FkGroupDepartmentId]	FOREIGN KEY ([GroupDepartmentId])	REFERENCES [OrgStructure].[Departments]([DepartmentId]),
	CONSTRAINT [FkGroupManagerId]		FOREIGN KEY ([GroupManagerId])		REFERENCES [PersonalInfo].[Employees]([EmployeeId]),
	CONSTRAINT [UniqueGroupName]		UNIQUE ([GroupName])
)
CREATE INDEX [IdxGroupDepartmentId] ON [OrgStructure].[Groups]([GroupDepartmentId])
CREATE INDEX [IdxGroupManagerId]	ON [OrgStructure].[Groups]([GroupManagerId])

CREATE TABLE [CRM].[Role]
(
	[RoleId]	INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[RoleName]	NVARCHAR(50) NOT NULL,

	CONSTRAINT [UniqueRoleName] UNIQUE ([RoleName])
)

GO

CREATE TABLE [CRM].[Operators]
(
	[OperatorId]			INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[OperatorEmployeeId]	INT,
	[OperatorRoleId]		INT,
	[OperatorGroupId]		INT,

	CONSTRAINT [FkOperatorEmployeeId]	FOREIGN KEY ([OperatorEmployeeId])	REFERENCES [PersonalInfo].[Employees]([EmployeeId]),
	CONSTRAINT [FkOperatorRoleId]		FOREIGN KEY ([OperatorRoleId])		REFERENCES [CRM].[Role]([RoleId]),
	CONSTRAINT [FkOperatorGroupId]		FOREIGN KEY ([OperatorGroupId])		REFERENCES [OrgStructure].[Groups]([GroupId])
)
CREATE INDEX [IdxOperatorEmployeeId] ON [CRM].[Operators]([OperatorEmployeeId])

CREATE TABLE [CRM].[ContactResults]
(
	[ContactResultId]	INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[ContactResultName]	NVARCHAR(50) NOT NULL,

	CONSTRAINT [UniqueContactResultName] UNIQUE ([ContactResultName])
)

GO

CREATE TABLE [CRM].[Contacts]
(
	[ContactId]		INT PRIMARY KEY CLUSTERED IDENTITY(1, 1),
	[ContactDT]		DATETIME2 DEFAULT(SYSDATETIME()),
	[OperatorId]	INT,
	[ClientId]		INT,
	[ResultId]		INT,
	[NextActionDT]	DATETIME2,

	CONSTRAINT [FkContactOperatorId]	FOREIGN KEY ([OperatorId])	REFERENCES [CRM].[Operators]([OperatorId]),
	CONSTRAINT [FkContactClientId]		FOREIGN KEY ([ClientId])	REFERENCES [PersonalInfo].[Clients]([ClientId]),
	CONSTRAINT [FkContactResultId]		FOREIGN KEY ([ResultId])	REFERENCES [CRM].[ContactResults]([ContactResultId]),
	CONSTRAINT [CheckNextActionDT]		CHECK ([NextActionDT] > [ContactDT])
)
CREATE INDEX [IdxContactOperatorId] ON [CRM].[Contacts]([OperatorId])
CREATE INDEX [IdxContactClientId]	ON [CRM].[Contacts]([ClientId])

/*

GO
DROP TABLE IF EXISTS [CRM].[Contacts]
GO
DROP TABLE IF EXISTS [CRM].[Operators]
DROP TABLE IF EXISTS [OrgStructure].[Groups]
DROP TABLE IF EXISTS [PersonalInfo].[Clients]

ALTER TABLE [PersonalInfo].[Clients] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE IF EXISTS [PersonalInfo].[Clients]
DROP TABLE IF EXISTS [PersonalInfo].[ClientsHistory]
GO
DROP TABLE IF EXISTS [PersonalInfo].[Employees]

ALTER TABLE [PersonalInfo].[Employees] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE IF EXISTS [PersonalInfo].[Employees]
DROP TABLE IF EXISTS [PersonalInfo].[EmployeesHistory]

GO
DROP TABLE IF EXISTS [Dimensions].[Regions]
DROP TABLE IF EXISTS [OrgStructure].[Positions]
DROP TABLE IF EXISTS [OrgStructure].[Departments]
DROP TABLE IF EXISTS [CRM].[Role]
DROP TABLE IF EXISTS [CRM].[ContactResults]

*/
