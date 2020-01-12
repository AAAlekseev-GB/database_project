DROP DATABASE IF EXISTS project;
CREATE DATABASE project;
USE project;

-- Создадим таблицу пользователей 
DROP TABLE IF EXISTS users;
CREATE TABLE users (
id SERIAL PRIMARY KEY,
name VARCHAR (255),
phone VARCHAR (255),
email  VARCHAR (255));

-- Данные для этой таблицы находятся в файле users_from_filldb

-- Создаем таблицу с регистрационными данными компаний
-- Она будет аналогом единого государственного реестра юридических лиц (ЕГРЮЛ),
-- содержащим только данные, нужные в рамках этого проекта:
-- Наименование,
-- Дата регистрации,
-- Адрес регистрации,
-- Имя владельца,
-- ИНН и КПП.

DROP TABLE IF EXISTS egrul;
CREATE TABLE egrul (
	name VARCHAR(255),
    inn INT UNSIGNED PRIMARY KEY,
    kpp INT UNSIGNED,
    formal_adress VARCHAR(255),
    created_at DATE,
    owner_id INT UNSIGNED
);

DESC egrul;  
-- Присвоим компаниям правдоподобные значения ИНН и КПП

-- ИНН сосотоит из 10 цифр:
-- Первые четыре цифры ИНН - код налоговой службы по месту регистрации,
-- следующие 5 - порядковый номер записи о регистрации,
-- последняя цифра - контрольная, рассчитывается по специальному алгоритму,
-- в данном примере назначается случайно.

-- КПП состоит из 9 цифр:
-- первые 4 - тот же, что и у ИНН код налоговой,
-- следующие 5 назначаются по специальным справочникам,
-- в этом учебном примере назначаются случайно.

-- Добавим таблицу с кодами налоговых служб

DROP TABLE IF EXISTS tax_services;
CREATE TABLE tax_services(
	city VARCHAR(100),
    code INT(4) UNSIGNED
);
select * from egrul;
-- Настоящие коды привязаны к различным административным единицам,
-- но для учебного проекта я выбрал пять городов,
-- в каждом из которых будет работать только одно отделение.

INSERT INTO tax_services VALUES
	('Moscow', 7701),
    ('Saint Petersburg', 7801),
    ('Ekaterinburg', 6601),
    ('Novosibirsk', 5401),
    ('Vladivostok', 2501);

SELECT * FROM banks;
    
-- Добавим в таблицу egrul поле с указанием города

ALTER TABLE egrul ADD COLUMN city VARCHAR(100);

UPDATE egrul SET city = (SELECT city FROM tax_services ORDER BY RAND() LIMIT 1); 

-- SELECT запрос ниже для проверки корректности нумерации значений
-- они пронумерованы в порядке регистрации отдельно по каждому городу.

SELECT
	egrul.name,
    tax.code AS first_four_signs,
    ROW_NUMBER() OVER w AS second_sign,
    FLOOR(1 + (RAND() * 9)) AS last_sign,
    egrul.city,
    created_at 
    FROM egrul
	JOIN tax_services tax
	ON egrul.city = tax.city
    WINDOW w AS (PARTITION BY egrul.city ORDER BY created_at)
    ORDER BY egrul.city, second_sign;

-- Добавим в таблицу ЕГРЮЛ поля со значениями ИНН

-- Первые 4 цифры - код налоговой
ALTER TABLE egrul ADD COLUMN first_four_signs_of_inn VARCHAR(100);

-- Вторые 5 цифр - порядковый номер записи о регистрации
ALTER TABLE egrul ADD COLUMN second_five_signs_of_inn INT(5) UNSIGNED ZEROFILL DEFAULT 0;

-- Последняя цифра - контрольная, в этом проекте назначена случайно
ALTER TABLE egrul ADD COLUMN last_sign_of_inn INT(1) UNSIGNED; 

-- Вносим в поля для генерации ИНН значения
-- Первые 4 цифры:
UPDATE egrul 
	SET first_four_signs_of_inn = 
		(SELECT code FROM tax_services tax WHERE tax.city = egrul.city);

-- Для заполнения поля second_five_signs_of_inn была написана процедура
-- скрипт ее создания в файле generate_five_signs_of_inn_script
SELECT city FROM tax_services;
CALL second_five_signs_of_inn('Moscow');
CALL second_five_signs_of_inn('Saint Petersburg');
CALL second_five_signs_of_inn('Ekaterinburg');
CALL second_five_signs_of_inn('Novosibirsk');
CALL second_five_signs_of_inn('Vladivostok');

-- Назачим последний символ ИНН
UPDATE egrul SET last_sign_of_inn = FLOOR(1 + (RAND() * 9));

-- Проверяем корректность полученных значений
SELECT 
	name, 
	city,
    created_at,
    first_four_signs_of_inn, 
    second_five_signs_of_inn, 
    last_sign_of_inn FROM egrul ORDER BY created_at;

-- Обновляем поле ИНН более правдоподобными значениями
DESC egrul;
ALTER TABLE egrul MODIFY COLUMN inn VARCHAR(10);
  
UPDATE egrul SET inn = CONCAT(
	first_four_signs_of_inn, 
    second_five_signs_of_inn, 
    last_sign_of_inn);
    
SELECT 
	first_four_signs_of_inn, 
	second_five_signs_of_inn, 
    last_sign_of_inn,
    inn
		FROM egrul ORDER BY created_at;

-- Присвоим значения КПП
-- КПП состоит из 9 цифр:
-- первые 4 - те же, что и у ИНН,
-- следующие 5 назначаются по специальным справочникам,
-- в этом проекте назначаются случайно.

ALTER TABLE egrul ADD COLUMN last_signs_of_kpp INT(5) UNSIGNED ZEROFILL;
UPDATE egrul SET last_signs_of_kpp = FLOOR(1 + (RAND() * 99999));
ALTER TABLE egrul MODIFY COLUMN kpp VARCHAR(9);
UPDATE egrul SET kpp = CONCAT(first_four_signs_of_inn, last_signs_of_kpp);

SELECT name, inn, kpp, city, created_at FROM egrul LIMIT 10;

-- Добавим в поле formal_adress названия городов

UPDATE egrul SET formal_adress = (CONCAT(city,', ', formal_adress));

-- Удалим из реестра ЕГРЮЛ лишние столбцы 

DESC egrul;

ALTER TABLE egrul DROP COLUMN city;
ALTER TABLE egrul DROP COLUMN first_four_signs_of_inn;
ALTER TABLE egrul DROP COLUMN last_sign_of_inn;
ALTER TABLE egrul DROP COLUMN second_five_signs_of_inn;
ALTER TABLE egrul DROP COLUMN last_signs_of_kpp;

SELECT * FROM egrul LIMIT 10;

-- Создадим таблицы, нужные для работы банков

-- Таблица с реквизитами самих банков

DROP TABLE IF EXISTS banks;
CREATE TABLE banks (
	name VARCHAR(255), 
	inn VARCHAR(11),
	bik VARCHAR(10),
    division VARCHAR(6),
	correspondent_account VARCHAR(27), 
	bank_account_number VARCHAR(27)
);

INSERT INTO banks VALUES
	('First National Bank',
    '7701147911',
    '044000001',
    '7701',
    '301.02.810.2.2013.6974413', 
    '407.02.810.2.2013.6974413'),
    
    ('Second Independent Bank',
    '7701147352',
    '044000035',
    '7721',
    '301.02.810.2.1999.6946277', 
    '407.02.810.2.1999.7456211'),
    
    ('Small Local Bank',
    '5401143810',
    '044005221',
    '5401',
    '301.02.810.2.2013.6974413', 
    '407.02.810.2.2013.6522917'),
    
    ('Average Commercial Bank',
    '5401147911',
    '044005887',
    '5441',
    '301.02.810.2.1555.6943221', 
    '407.02.810.2.1885.5582134')
    ; 

SELECT * FROM banks;

-- Таблица валют
DROP TABLE IF EXISTS currency;
CREATE TABLE currency (
name VARCHAR(255),
tag INT UNSIGNED NOT NULL PRIMARY KEY);

INSERT INTO currency VALUES 
	('RUB', '810'),
	('USD', '840'),
    ('EUR', '978');

SELECT * FROM currency;

-- Тарифный справочник
DROP TABLE IF EXISTS tariff_book;
CREATE TABLE tariff_book (
	id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255),
	description TEXT);

INSERT INTO tariff_book VALUES
	('1', 'perfect_start', 
    'Тариф для недавно открывшихся предприятий, оплата только если по счету были операции, 1% от всех исходящих платежей'),
    ('2','high_results',
    'Тариф c абонентской платой 2500 рублей/месяц и фиксированной платой за каждое платежное поручение - 100 рублей'),
    ('3', 'great_opportunities',
    'Тариф с абонентской платой 5000 рублей и беcплатным безлимитным оформлением платежных поручний');
    
SELECT * FROM tariff_book;

-- Таблица статусов платежных поручений
DROP TABLE IF EXISTS paynent_statuses;
CREATE TABLE paynent_statuses (
	id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	status VARCHAR(255));

INSERT INTO paynent_statuses VALUES
	('1', 'created'),
    ('2', 'confirmed by user, sent on execution'),
    ('3', 'recieved by bank, executing'),
    ('4', 'sent to additional check by bank employee'),
	('5', 'rejected, not enough money'),
    ('6', 'rejected by user'),
	('7', 'rejected, suspicious payment, please contact bank employee'),
    ('8', 'executed');
    
SELECT * FROM paynent_statuses;

-- Таблица очередности исполнения платежных поручений
DROP TABLE IF EXISTS paynent_queue_statuses;
CREATE TABLE paynent_queue_statuses (
	id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	queue VARCHAR(255));

-- Очередность исполнения платежей по получателю
-- здесь id совпадает с приоритетом на исполнение
INSERT INTO paynent_queue_statuses VALUES
	('1', 'court decisions'), -- взыскания по решению суда
    ('2', 'government services'), -- оплаты в государственные учреждения
    ('3', 'bank comissions'), -- комиссии банка за обслуживание счета
    ('4', 'express payments'), -- платежи, отправленные с пометкой "срочно"
    ('5', 'regular payments'); -- обычные платежи

SELECT * FROM paynent_queue_statuses;

-- Таблица с номерами расчетных счетов
DROP TABLE IF EXISTS bank_accounts;
CREATE TABLE bank_accounts (
	bank_account VARCHAR(26),
	account_balance DECIMAL,
	inn VARCHAR(255),
	bik VARCHAR(255),
	currency VARCHAR(5),
	created_at DATE); 

ALTER TABLE bank_accounts MODIFY COLUMN bank_account VARCHAR(255) DEFAULT 'n/a';

-- Заполним таблицу счетов данными
INSERT INTO bank_accounts (inn) 
	SELECT inn FROM egrul;
 
UPDATE bank_accounts 
	SET bik = (SELECT bik FROM banks WHERE name = 'Average Commercial Bank')
	LIMIT 200;

UPDATE bank_accounts
	SET bank_accounts.bik = (SELECT bik FROM banks 
    WHERE name IN ('First National Bank', 'Second Independent Bank', 'Small Local Bank')
    ORDER BY RAND() LIMIT 1)
    WHERE bank_accounts.bik IS NULL;

-- Проверяем корректность распределяния клиентов по банкам
-- Клиентами нашего банка будут 200 организаций,
-- Остальные 300 организаций нужны для создания межбанковских платежей,
-- Они станут клиентами трех других банков;

SELECT COUNT(*), bik FROM bank_accounts GROUP BY bik;

-- в данном примере будем считать,
-- что клиенты открыли счета для своих компаний
-- в тот же день, что и зарегистрировали компании

UPDATE bank_accounts 
	SET created_at = (SELECT created_at FROM egrul WHERE egrul.inn = bank_accounts.inn);

-- все счета у нас будут в рублях
UPDATE bank_accounts SET currency = 'RUB';
	
SELECT * FROM bank_accounts;
    
-- Теперь у нас есть все необходимые данные для назначения каждому клиенту номера расчетного счета
-- Скрипт функции, генерирующей правдоподобный номер счета в файле create_bank_account_script
-- Создадим курсор, чтобы присвоить номер расчетного счета каждой организации
-- Процедура будет последовательно извелекать значения ИНН из таблицы bank_accounts
-- и присваивать номера счетов функцией create_bank_account возвращая их в ту же таблицу

DROP PROCEDURE IF EXISTS assign_bank_account;

DELIMITER //

CREATE PROCEDURE assign_bank_account()
BEGIN 
	DECLARE current_inn VARCHAR(255);
    DECLARE is_end INT DEFAULT 0;
	
    DECLARE cursor_for_bank_accounts CURSOR 
		FOR SELECT inn FROM bank_accounts ORDER BY bik, created_at;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;

	OPEN cursor_for_bank_accounts;
    
    cycle : LOOP
    FETCH cursor_for_bank_accounts INTO current_inn;
	IF is_end THEN LEAVE cycle;
	END IF;
    UPDATE bank_accounts 
		SET bank_account = create_bank_account(current_inn) WHERE bank_accounts.inn = current_inn;
	END LOOP cycle;

	CLOSE cursor_for_bank_accounts;

END //

DELIMITER ;    

-- Присваиваем компаниям номера счетов
CALL assign_bank_account;

-- Проверяем корректность назначенных номеров
SELECT bank_account, bik, created_at, 
	ROW_NUMBER() OVER(PARTITION BY bik ORDER BY created_at) 
		AS number_over_window
    FROM bank_accounts;
-- Номера отличаются внутри дня, но корректно назначились по дням и банкам
-- т.к. дата регистрации указана без уточнения времени

-- Присвоим записям значения id
DESC bank_accounts;
SELECT COUNT(*), bik FROM bank_accounts GROUP BY bik ORDER BY bik LIMIT 10;
-- Колличество клиентов в каждом из банков < 1000,
-- у нас < 10 разных банков, но последняя цифра банковского идентификатора одинакова у двух банков
-- чтобы однозначно определить расчетный счет каждого контрагента нам будет достаточно 5 символов

ALTER TABLE bank_accounts MODIFY COLUMN id INT(5) UNSIGNED ZEROFILL DEFAULT 0 FIRST;

SELECT LENGTH(bank_account) FROM bank_accounts;

-- Для клиентов нашего банка внутренний номер будет совпадать с последними пятью цифрами расчетного счета
SELECT LENGTH(bank_account) FROM bank_accounts;
UPDATE bank_accounts SET id = 
	SUBSTRING(bank_account, 22, 24)
		WHERE bik = '044005887';
SELECT COUNT(id) FROM bank_accounts WHERE bik = 044005887 LIMIT 201;

-- Внутренний номер клиентов других банков будет складываться 
-- из последних двух цифр БИК и последних трех расчетного счета
UPDATE bank_accounts SET id =
	CONCAT(SUBSTRING(bik, 8, 9), SUBSTRING(bank_account, 22, 24))
		WHERE bik != 044005887;

-- Проверим получившиеся значения id на уникальность
SELECT COUNT(*), id FROM bank_accounts GROUP BY id ORDER BY id LIMIT 501;
SELECT * FROM bank_accounts LIMIT 10;
DESC payments; 

-- Пусть при регистрации каждая компания внесла на расчетный счет какую-то сумму
-- в диапозоне 50 - 250 тыс. рублей
UPDATE bank_accounts SET account_balance = FLOOR(RAND()*(20)+5)*10000;

SELECT * FROM bank_accounts LIMIT 10;

-- создадим таблицу платежных поручений
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
	id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_counterpart INT(5) UNSIGNED, -- отправитель
    to_counterpart INT(5) UNSIGNED, -- получатель
    payment_queue INT UNSIGNED, -- очередность по отправителю
    amount DECIMAL UNSIGNED, -- сумма
    created_at DATETIME, 
    status INT UNSIGNED,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    purpose VARCHAR(255)); -- назначение
         
DESC payments;

-- Так как данные для платежей будут генерироваться вручную, предварительно создадим пустые записи
-- из расчета 1 платеж на каждого клиента в день
-- 1 х 200 х 30 = 6000, 
-- учтем что часть платежей уйдет клиентам другого банка некоторые не будут проведены из-за отсутствия денег
-- создадим с запасом 10000 записей

-- Для генерации пустых строк была создана процедура create_empty_set
-- скрипт ее создания находится в файле create_empty_set_script
CALL create_empty_set('payments', 'purpose' , 10000);
-- эта команда отрабатывает корректно только через консольный клиент
-- Создаем платежные поручения:
-- Отправители платежей
UPDATE payments 
	SET from_counterpart = 
		(SELECT id FROM bank_accounts  ORDER BY RAND() LIMIT 1);

-- Получатели платежей
UPDATE payments 
	SET to_counterpart = 
		(SELECT id FROM bank_accounts ORDER BY RAND() LIMIT 1);

-- Проверяем и корректируем данные
SELECT COUNT(id) FROM payments WHERE from_counterpart = to_counterpart; 

UPDATE payments 
	SET to_counterpart = 
		(SELECT id FROM bank_accounts ORDER BY RAND() LIMIT 1)
	WHERE from_counterpart = to_counterpart;

-- Даты для платежных поручений ограничим одним месяцем, 
-- чтобы получить достаточное колличество платежей для каждого дня и компании
-- Скрипт импорта дат находится в файле payment_dates_from_filldb
-- Проверим и скорректируем данные, чтобы даты платежей были позже дат открытия счетов
SELECT COUNT(*) FROM correct_dates;
SELECT MIN(date), MAX(date) FROM correct_dates LIMIT 1;
UPDATE correct_dates SET date = TIMESTAMPADD(DAY, 24, date);
UPDATE correct_dates SET date = TIMESTAMPADD(DAY, 1, date) 
	WHERE date < '2020-01-01 00:00:00';

UPDATE payments SET created_at = 
	(SELECT date FROM correct_dates ORDER BY RAND() LIMIT 1);

-- Назначения платежей сгенерируем спомощью filldb.info
-- Скрипт импорта в файле payment_purposes_from_filldb
ALTER TABLE payments MODIFY COLUMN purpose TEXT;
UPDATE payments SET purpose =
	(SELECT correct_purposes.purpose FROM correct_purposes ORDER BY RAND() LIMIT 1);

-- установим очередность для платежей и их начальные статусы
SELECT * FROM paynent_queue_statuses;
UPDATE payments 
	SET payment_queue  = (SELECT id FROM paynent_queue_statuses WHERE id != 3 ORDER BY RAND() LIMIT 1);

SELECT * FROM paynent_statuses;
UPDATE payments 
	SET status = 1;
 
-- Суммы платежей
UPDATE payments 
	SET amount = FLOOR(1000 + (RAND() * 49000));

-- Проверяем, достаточно ли денег на счетах клиентов для совершения первых оплат 
SELECT 
	payments.id, payments.status,
	bank_accounts.account_balance, 
    payments.amount,
    bank_accounts.account_balance - payments.amount AS overspending
		FROM payments
		JOIN bank_accounts
			ON payments.from_counterpart = bank_accounts.id
		WHERE bank_accounts.account_balance < payments.amount
			AND payments.status != 8
        ORDER BY overspending LIMIT 2000;
 
SELECT COUNT(*) FROM
		(SELECT payments.id
			FROM payments
			JOIN bank_accounts
			ON payments.from_counterpart = bank_accounts.id
				WHERE bank_accounts.account_balance < payments.amount
					AND payments.status != 8) AS t;

-- Меняем суммы в платежах, на которые не хватает денег
UPDATE payments
	JOIN bank_accounts
    ON bank_accounts.id = payments.from_counterpart
	SET amount = FLOOR(1000 + (RAND() * 49000)) 
		WHERE payments.amount > bank_accounts.account_balance
			AND payments.status != 8;

CALL execute_all_payments();
-- Эта команда корректно работает только из консольного клиента

-- Проверим получившуюся выборку

SELECT payments.status, paynent_statuses.status, COUNT(*) 
	FROM payments
    JOIN paynent_statuses
    ON payments.status = paynent_statuses.id
    GROUP BY payments.status;

UPDATE correct_dates SET date = TIMESTAMPADD(DAY, 24, date);

SELECT 'платежи', MAX(amount) as MAX, MIN(amount)as MIN, AVG(amount) as AVG FROM payments
UNION
SELECT 'остатки на счетах', MAX(account_balance), MIN(account_balance), AVG(account_balance) from bank_accounts;

-- >89% платежей исполнилась. Корректируем еще не исполненные платежи
SELECT COUNT(*) FROM payments
	JOIN bank_accounts
    ON bank_accounts.id = payments.from_counterpart
		WHERE bank_accounts.account_balance > (SELECT AVG(amount) as AVG FROM payments)
			AND payments.status != 8;

-- Меняем отправителей в неисполненных платежах, на тех у кого больше денег
UPDATE payments
	JOIN bank_accounts
    ON bank_accounts.id = payments.from_counterpart
	SET from_counterpart = 
		(SELECT id FROM bank_accounts 
			WHERE bik = 044005887
			AND bank_accounts.account_balance > 10000 ORDER BY RAND() LIMIT 1)
				WHERE payments.amount > bank_accounts.account_balance
					AND payments.status != 8;

-- Уменьшаем суммы еще не исполненных платежей
UPDATE payments
	JOIN bank_accounts
    ON bank_accounts.id = payments.from_counterpart
	SET amount = FLOOR(1000 + (RAND() * 4000)) 
		WHERE payments.amount > bank_accounts.account_balance
			AND payments.status != 8;

-- Проверяем и корректируем данные
SELECT COUNT(id) FROM payments WHERE from_counterpart = to_counterpart; 
UPDATE payments 
	SET to_counterpart = 
		(SELECT id FROM bank_accounts ORDER BY RAND() LIMIT 1)
	WHERE from_counterpart = to_counterpart;

-- Исполняем то, что еще не исполнилось
CALL execute_all_payments();

-- Проверим получившуюся выборку

-- Соотношение исполненных платежей к неисполненным
SELECT payments.status, paynent_statuses.status, COUNT(*) 
	FROM payments
    JOIN paynent_statuses
    ON payments.status = paynent_statuses.id
    GROUP BY payments.status;

-- Распределение исходящих платежей по банкам
SELECT banks.name, COUNT(*)
    FROM payments
    JOIN bank_accounts
    ON (bank_accounts.id = payments.from_counterpart)
    JOIN banks
    ON bank_accounts.bik = banks.bik
    GROUP BY banks.name;

-- Активность клиентов нашего банка
SELECT  from_counterpart AS 'id', COUNT(payments.id) AS 'активность'
		FROM payments
        JOIN bank_accounts
		ON bank_accounts.id = payments.from_counterpart
        WHERE bank_accounts.bik = '044005887'
        GROUP BY from_counterpart ORDER by COUNT(payments.id) DESC;

SELECT * FROM payments WHERE from_counterpart = 149 ORDER BY created_at;

-- В итоговой выборке неисполненных платежей <0,5%
-- Платежей приходящихся на наш банк 4228, что меньше планируемого,
-- но достаточно для того чтобы банковские выписки клиентов нашего банка получились достаточно полными

-- Скорректируем поле created_at, чтобы оно указывало время исполнения платежа 
ALTER TABLE payments MODIFY COLUMN updated_at DATETIME DEFAULT NULL;
UPDATE payments SET updated_at = TIMESTAMPADD(HOUR, 1, created_at);

-- В рамках проекта мы работаем только с одним банком а не со всей банковской системой
-- Скорректируем базу данных чтобы в ней остались записи с участием наших клиентов
DROP TABLE IF EXISTS client_accounts;
CREATE TABLE client_accounts 
	AS SELECT * FROM bank_accounts WHERE bik = '044005887';

DESC client_accounts;
SELECT * FROM client_accounts ORDER BY id;
SELECT COUNT(*) FROM client_accounts ORDER BY id;

-- Сейчас связь руководителей предприятий с номерами счетов в банке настроена так:
-- Таблица счтов клиентов связана с таблицей гос. реестра (egrul) по полю ИНН
-- А реестр ЕГРЮЛ связан с таблицей учетных данных пользователей users, что некорректно
-- потому, что работа с учетными данными пользователя не должна зависеть от доступности
-- открытого сервиса не являющегося частью банка   
-- Создадим таблицу связей между рассчетными счетами и пользователями

DESC users;
DESC client_accounts;
DESC egrul;

SELECT
    client_accounts.id AS bank_account_id,
    client_accounts.inn AS inn_from_accounts_table,
    egrul.inn AS inn_from_egrul,
    users.id AS id_from_users
		FROM users 
			JOIN egrul
			ON egrul.owner_id = users.id
			JOIN client_accounts
            ON client_accounts.inn = egrul.inn;

DROP TABLE IF EXISTS users_to_client_accounts;
CREATE TABLE users_to_client_accounts
	AS SELECT * FROM 
		(SELECT * FROM (SELECT
			users.id AS user_id,
			client_accounts.id AS bank_account_id
				FROM users 
					JOIN egrul
					ON egrul.owner_id = users.id
					JOIN client_accounts
					ON client_accounts.inn = egrul.inn
		) AS Q) AS T;

DESC users_to_client_accounts;
SELECT * FROM users_to_client_accounts;
		
-- Добавим таблицу контрагентов
-- туда побадут банковские реквизиты клиентов других банков
-- которые хотя бы раз платили в наш банк

DROP TABLE IF EXISTS counterpart_accounts;
CREATE TABLE counterpart_accounts 
	AS SELECT * FROM bank_accounts WHERE bik != '044005887';

-- Проверим данные
DESC counterpart_accounts;
SELECT * FROM counterpart_accounts ORDER BY id;
SELECT COUNT(*) FROM counterpart_accounts ORDER BY id;

 DROP TABLE IF EXISTS client_payments;
CREATE TABLE client_payments 
	AS 
	(SELECT * FROM payments 
		WHERE from_counterpart IN
        (SELECT id FROM client_accounts)
	UNION ALL
	SELECT * FROM payments 
		WHERE to_counterpart IN
        (SELECT id FROM client_accounts));

-- Проверим получившуюся выборку	
SELECT 'отправители' AS 'наименование', COUNT(*) FROM client_payments 
	WHERE from_counterpart IN 
		(SELECT id FROM client_accounts)
UNION
SELECT 'получатели', COUNT(*) FROM client_payments 
	WHERE to_counterpart IN 
		(SELECT id FROM client_accounts)
UNION
	SELECT 'внутрибанковские платежи', -COUNT(*) FROM client_payments
	JOIN client_accounts as t1
    ON t1.id = client_payments.to_counterpart
    JOIN client_accounts as t2
    ON t2.id = client_payments.from_counterpart
UNION        
	SELECT 'всего записей', COUNT(*) FROM client_payments;	
-- Значения корректны

-- Платежи, поступающие от клиентов других банков, должны храниться в отдельной таблице
DROP TABLE IF EXISTS incoming_payments;
CREATE TABLE incoming_payments 
	AS 
	(SELECT * FROM client_payments 
		WHERE to_counterpart IN
        (SELECT id FROM client_accounts));

SELECT COUNT(*) FROM incoming_payments;

-- Удалим из таблицы исходящих платежей записи о платежах из других банков 
DELETE FROM client_payments 
		WHERE to_counterpart IN
        (SELECT id FROM client_accounts);

-- Удалим из таблицы входящих платежей записи о платежах внутри нашего банка, 
-- т.к. они есть в исходящих
DELETE FROM incoming_payments 
		WHERE from_counterpart IN
        (SELECT id FROM client_accounts);

-- Проверим данные
SELECT COUNT(*) FROM client_payments
	UNION
SELECT COUNT(*) FROM incoming_payments;
-- Тестовые данные корректны, удалим лишние таблицы

SHOW TABLES;
DROP TABLES company_names, correct_dates, correct_purposes;
