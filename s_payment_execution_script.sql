USE project;

-- Создадим курсор для последовательного исполнения всех платежных поручений

DROP PROCEDURE IF EXISTS execute_all_payments;

DELIMITER //

CREATE PROCEDURE execute_all_payments()
BEGIN 
	DECLARE payment_id INT;
	
    DECLARE is_end INT DEFAULT 0;
	
    DECLARE payment_cursor CURSOR 
		FOR SELECT 
			id FROM payments WHERE status != 8 ORDER BY created_at;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;

	OPEN payment_cursor;
    
    cycle : LOOP
    FETCH payment_cursor 
    INTO payment_id;        
	IF is_end THEN LEAVE cycle;
	END IF;
    CALL execute_payment(payment_id);
    END LOOP cycle;

	CLOSE payment_cursor;

END //

DELIMITER ;

-- Проверяем корректность работы процедуры execute_all_payments

CALL execute_all_payments();

SELECT payments.status, paynent_statuses.status, COUNT(*) 
	FROM payments
    JOIN paynent_statuses
    ON payments.status = paynent_statuses.id
    GROUP BY payments.status;

