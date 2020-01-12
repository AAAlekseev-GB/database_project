 -- Ниже скрипт исполнения одного платежного поручения
 -- Он принимает входным параметром номер платежного поручения
 -- Исполняет его и в зависимости от результата транзакции
 -- назначает ему статус и корректирует остатки на счетах

USE project;

DROP PROCEDURE IF EXISTS execute_payment;

DELIMITER //
CREATE PROCEDURE execute_payment (IN payment_id INT)
BEGIN
	DECLARE from_counterpart_id, to_counterpart_id INT;
	DECLARE total DECIMAL;
    
	SET from_counterpart_id = 
		(SELECT from_counterpart 
			FROM payments WHERE id = payment_id);
	SET to_counterpart_id = 
		(SELECT to_counterpart 
			FROM payments WHERE id = payment_id);
	SET total =  
		(SELECT amount 
			FROM payments WHERE id = payment_id);    
	
	START TRANSACTION;
		UPDATE bank_accounts 
			SET account_balance = account_balance - total WHERE id = from_counterpart_id; 
		UPDATE bank_accounts 
			SET account_balance = account_balance + total WHERE id = to_counterpart_id;
		IF 
			(SELECT account_balance  
				FROM bank_accounts 
					WHERE id = from_counterpart_id) 
			>= 0 
		THEN COMMIT;
			UPDATE payments
				SET payments.status = 8 WHERE id = payment_id;
		ELSE ROLLBACK;
			UPDATE payments
				SET payments.status = 5 WHERE id = payment_id;
		END IF;
	END //

DELIMITER ;    

SELECT * FROM payments WHERE id = 1;

-- Ниже проверка корректности работы функции

UPDATE payments SET status = NULL WHERE id = 1;
UPDATE bank_accounts SET account_balance = 70000 
	WHERE id = 87137;
UPDATE bank_accounts SET account_balance = 100000 WHERE id = 1062; 

-- Две команды ниже устанавливают размер платежа

-- для успешного платежа
UPDATE payments SET amount = 10000 WHERE id = 1;
-- для платежа, на который не хватит денег
UPDATE payments SET amount = 100000 WHERE id = 1;

CALL execute_payment(1);

SELECT * FROM payments WHERE id = 1;

-- В запросе ниже 
-- id, status, amoumnt - № платежного поручения, его статус и сумма платежа
-- from_counterpart, sender_balance - id и баланс плательщика
-- to_counterpartner, recipient_balance - id и баланс получателя

SELECT
	payments.id,
    payments.status,
    payments.amount,
	payments.from_counterpart,
    sender.account_balance AS sender_balance,
    payments.to_counterpart,
    recipient.account_balance AS recipient_balance
		FROM payments
		JOIN bank_accounts AS sender
		ON sender.id = payments.from_counterpart 
		JOIN bank_accounts AS recipient
		ON recipient.id = payments.to_counterpart 
			WHERE payments.id = 1;

-- Команды для обновления остатков на счетах до начальных величин
UPDATE payments SET status = NULL WHERE id = 1;
UPDATE bank_accounts SET account_balance = 70000 
	WHERE bank_accounts.id = 
    (SELECT from_counterpart FROM payments WHERE payments.id = 1);
UPDATE bank_accounts SET account_balance = 80000 
	WHERE bank_accounts.id = 
    (SELECT to_counterpart FROM payments WHERE payments.id = 1);
UPDATE payments SET amount = 7557 WHERE id = 1;