USE project;

DROP PROCEDURE IF EXISTS create_empty_set;

DELIMITER //
CREATE PROCEDURE create_empty_set (
    IN tbl_name VARCHAR(255),
    IN clmn_name VARCHAR(255),
    IN dimension INT)

BEGIN
	DECLARE i INT DEFAULT 0;
    DECLARE insert_statement VARCHAR(255);
	
    SET @insert_string = CONCAT('INSERT INTO ',tbl_name,' SET ', clmn_name, ' = NULL;');
    PREPARE insert_statement FROM @insert_string;
    
    IF ( dimension > 0) THEN
	WHILE i < dimension DO
	EXECUTE insert_statement;
	SET i = i + 1;	
	END WHILE;
	END IF;
    DEALLOCATE PREPARE insert_statement;
END //
DELIMITER ;

CALL create_empty_set('samples', 'description', 5);

SELECT * FROM samples; 

SELECT CONCAT('INSERT INTO ',tbl_name,' SET', clmn_name, ' = NULL;');