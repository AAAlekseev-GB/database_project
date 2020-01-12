USE project;

-- Функция ниже присваивает клиентам правдоподобные номера расчетных счетов 
-- используя данные таблиц bank и currency а также дату обращения клиента в банк 
DROP FUNCTION IF EXISTS create_bank_account;

DELIMITER //

CREATE FUNCTION create_bank_account(inn VARCHAR(255))
RETURNS VARCHAR(255)
READS SQL DATA
NOT DETERMINISTIC

BEGIN
-- Номер расчетного счета имеет следующий формат
-- 111.22.333.4.5555.666666, где
    DECLARE 
		first_signs, -- где 111 - номер балансового счета первого порядка, для юр. лиц - 407
		second_signs, -- 22 - номер балансового счета второго порядка, для ООО и ЗАО - 02
        third_signs, -- код валюты, получим его из таблицы currency 
		fourth_sign, -- 4 - контрольная цифра, т.к. алгоритм мне не известен, назначим её случайно
		fifth_signs, -- 5555 - код подразделения банка - поле division из таблицы banks
        sixth_signs, -- 666666 - внутренний номер клиента в банке
        bank_account VARCHAR(255);
    
    DECLARE i, j, num INT;
    
    SET first_signs = '407';
    SET second_signs = '02';
    SET third_signs = 
		(SELECT tag FROM currency 
			WHERE name = (SELECT currency FROM bank_accounts
				WHERE bank_accounts.inn = inn));
	SET fourth_sign = FLOOR(1 + (RAND() * 9));
    SET fifth_signs = (SELECT division FROM banks 
			WHERE banks.bik = (SELECT bik FROM bank_accounts
				WHERE bank_accounts.inn = inn));

-- Так как ни один из номеров расчетного счета пока не назначен
-- значение внутреннего номера клиента в банке рассчитаем так:
-- посчитаем колличество клиентов банка (i),
-- которые решили зарегистрироваться раньше текущего клиента

	SET i = 
	(SELECT COUNT(*) FROM bank_accounts
		WHERE created_at < 
			(SELECT created_at FROM bank_accounts 
				WHERE bank_accounts.inn = inn)
		AND bik = 
			(SELECT bik FROM bank_accounts 
				WHERE bank_accounts.inn = inn));

-- Посчитаем клинтов которые решили зарегистрироваться в тот же день
-- и в том же банке, что и текущий клиент и уже получили номер
-- это значение (j) будет отвечать за нумерацию внутри дня 
	
    SET j =  
    (SELECT COUNT(*) FROM bank_accounts
		WHERE (created_at = 
			(SELECT created_at FROM bank_accounts 
				WHERE bank_accounts.inn = inn)
		AND bik = 
			(SELECT bik FROM bank_accounts 
				WHERE bank_accounts.inn = inn))
		AND bank_accounts.bank_account IS NOT NULL);

-- Сумма этих значений и будет номером клиента
 
        SET num = i + j;
		SET sixth_signs = num; 
	
-- Дополняем значение номера счета клиента до 6 разрядов
	CASE LENGTH(sixth_signs)
        WHEN 1 THEN
        SET sixth_signs = CONCAT('00000', num);
		WHEN 2 THEN
        SET sixth_signs = CONCAT('0000', num);
		WHEN 3 THEN
        SET sixth_signs = CONCAT('000', num);
        WHEN 4 THEN
        SET sixth_signs = CONCAT('00', num);
        WHEN 5 THEN
        SET sixth_signs = CONCAT('0', num);
        WHEN 6 THEN
        SET sixth_signs = num;
    END CASE; 
    
        SET bank_account = CONCAT(
			first_signs, '.', 
			second_signs, '.',
			third_signs,'.',
			fourth_sign,'.', 
			fifth_signs,'.', 
			sixth_signs);
	
    RETURN bank_account;
END //

DELIMITER ;

-- Проверяем, корректно ли работает функция
SELECT create_bank_account(2501000416);
