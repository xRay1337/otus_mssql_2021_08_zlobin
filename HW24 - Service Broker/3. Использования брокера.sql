-- Скрипт с примерами использования брокера. Предполагается, что БД находится
-- в "пустом" состоянии после выполнения 1 и 2 скрипта.

-- В БД инициаторе
USE SB_One;

-- Заполняем таблицу с сообщениями
INSERT INTO dbo.source (message_text)
VALUES
    (N'Far out in the uncharted backwaters of the unfashionable end of the western spiral arm of the Galaxy lies a small unregarded yellow sun.')
   ,(N'So long, and thanks for all the fish!..')
   ,(N'These creatures you call mice, you see, they are not quite as they appear. They are merely the protrusion into our dimension of vast hyperintelligent pandimensional beings. The whole business with the cheese and the squeaking is just a front.')
   ,(N'Mostly harmless')
   ,(N'The Ultimate Question of Life, the Universe, and Everything')
   ;

-- Имитируем одно ранее отправленное сообщение
UPDATE dbo.source SET sent_at = SYSDATETIMEOFFSET() WHERE id = 1;

SELECT * FROM dbo.source;

-- Выполняем запуск отправки сообщений:
EXEC dbo.SendMessage @message_id = 1;  -- сообщение не отправлено, было отправлено ранее;
EXEC dbo.SendMessage @message_id = 2;  -- сообщение не отправлено, не существует;
EXEC dbo.SendMessage @message_id = 3;  -- сообщение отправлено.

SELECT * FROM dbo.source;

-- На стороне приёмника
USE SB_Two;
-- Получаем сообщение и отправляем квитанцию.
EXEC dbo.RecieveMessage;

-- На стороне инициатора
USE SB_One;
-- Получаем квитанцию и закрываем диалог.
EXEC dbo.ValidateReplyTicket

---- Выборки из очередей для целей отладки
USE SB_One;
SELECT cast(message_body as xml), * FROM DBOneSBQueue;

USE SB_Two;
SELECT cast(message_body as xml), * FROM DBTwoSBQueue;