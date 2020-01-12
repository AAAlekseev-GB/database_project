USE project;

-- Процедура ниже генерирует корректные значения для поля second_five_signs_of_inn.
-- Процедура принимает в качестве параметра название города,
-- проверяет колличество записей в реестре
-- заполняет поле second_five_signs_of_inn номерами в порядке даты регистрации
-- от ранних записей к поздним

DROP PROCEDURE IF EXISTS second_five_signs_of_inn;

DELIMITER //

CREATE PROCEDURE second_five_signs_of_inn (
IN city_name VARCHAR(255))

BEGIN
	DECLARE i, n INT;
    
    SET i = 1;
    SET n = (SELECT COUNT(*) FROM egrul
		WHERE city = city_name);
	
    WHILE i <= n DO
    
    UPDATE egrul SET second_five_signs_of_inn = i 
		WHERE (city = city_name AND second_five_signs_of_inn = 0)
		ORDER BY created_at LIMIT 1;
    
	SET i = i + 1;	
    
    END WHILE;
END //

DELIMITER ;
