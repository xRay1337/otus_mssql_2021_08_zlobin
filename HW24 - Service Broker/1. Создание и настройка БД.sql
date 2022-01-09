-- В этом скрипте создаются и настраиваются БД для использования ServiceBroker'а.
--     * SB_One -- БД, инициирующая общение;
--     * SB_Two -- БД, принимающая и обрабатвающая сообщения.

USE master;

---- На передающей стороне.
-- 01. Создаём БД.
DROP DATABASE IF EXISTS SB_One;
GO

CREATE DATABASE SB_One;
GO

-- 02. Включаем ServiceBroker.
IF (SELECT is_broker_enabled FROM sys.databases WHERE name = 'SB_One') = 0
    ALTER DATABASE SB_One SET ENABLE_BROKER;
GO

-- 03. Настраиваем доверие сервера к БД.
IF (SELECT is_trustworthy_on FROM sys.databases WHERE name = 'SB_One') = 0
    ALTER DATABASE SB_One SET TRUSTWORTHY ON;
GO

-- 04. Магия sa.
ALTER AUTHORIZATION
   ON DATABASE::SB_One TO [sa];
GO

-- 05. Создаём типы сообщений.
USE SB_One;

CREATE MESSAGE TYPE [//DBOne/SB/Request] VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//DBOne/SB/Reply]   VALIDATION = WELL_FORMED_XML;
GO

-- 06. Создаём контракт.
CREATE CONTRACT [//DBOne/SB/Contract]
(
	[//DBOne/SB/Request] SENT BY INITIATOR,
	[//DBOne/SB/Reply]   SENT BY TARGET
);
GO

-- 07. Создаём очередь для приёма сообщений. Нужна будет для "квитанций"
-- о приёме отправленного сообщения.
CREATE QUEUE DBOneSBQueue;

-- 08. Создаём сервис приёма сообщений
CREATE SERVICE [//RBOne/SB/Service] ON QUEUE DBOneSBQueue;
GO


---- На принимающе стороне
USE master;

-- 09. Создаём БД
DROP DATABASE IF EXISTS SB_Two;
GO

CREATE DATABASE SB_Two;
GO

-- 10. Включаем ServiceBroker.
IF (SELECT is_broker_enabled FROM sys.databases WHERE name = 'SB_Two') = 0
    ALTER DATABASE SB_Two SET ENABLE_BROKER;
GO

-- 11. Настраиваем доверие сервера к БД.
IF (SELECT is_trustworthy_on FROM sys.databases WHERE name = 'SB_Two') = 0
    ALTER DATABASE SB_Two SET TRUSTWORTHY ON;
GO

-- 12. Снова магия sa.
ALTER AUTHORIZATION
   ON DATABASE::SB_Two TO [sa];
GO

-- 13. Создаём типы сообщений. Должны совпадать с SB_One.
USE SB_Two;

CREATE MESSAGE TYPE [//DBOne/SB/Request] VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//DBOne/SB/Reply]   VALIDATION = WELL_FORMED_XML;
GO

-- 14. Создаём контракт.  Должен совпадать с SB_One.
CREATE CONTRACT [//DBOne/SB/Contract]
(
	[//DBOne/SB/Request] SENT BY INITIATOR,
	[//DBOne/SB/Reply]   SENT BY TARGET
);
GO

-- 15. Создаём очередь для приёма сообщений.
CREATE QUEUE DBTwoSBQueue;

-- 16. Создаём сервис приёма сообщений. Сервис использует созданные очередь и контракт.
CREATE SERVICE [//RBTwo/SB/Service] ON QUEUE DBTwoSBQueue ([//DBOne/SB/Contract]);
GO

-- 99. Настройка баз завершена.