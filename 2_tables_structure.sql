USE project;

-- Оптимизирум базу, для чего расставим индексы и ключи 
-- и изменим где нужно тип данных

SHOW TABLES;

DESC users;
SELECT * FROM users LIMIT 1;

ALTER TABLE users MODIFY COLUMN id INT UNSIGNED NOT NULL;
ALTER TABLE users MODIFY COLUMN name VARCHAR(255) NOT NULL;
ALTER TABLE users MODIFY COLUMN phone VARCHAR(255) NOT NULL;
ALTER TABLE users MODIFY COLUMN email VARCHAR(255) NOT NULL;

DESC egrul;
SELECT * FROM egrul LIMIT 1;

SELECT MAX(LENGTH(name)) FROM egrul LIMIT 1;
ALTER TABLE egrul MODIFY COLUMN name VARCHAR(50) NOT NULL;
SELECT LENGTH(inn) FROM egrul LIMIT 1;
ALTER TABLE egrul MODIFY COLUMN inn BIGINT(10) UNSIGNED NOT NULL;
SELECT LENGTH(kpp) FROM egrul LIMIT 1;
ALTER TABLE egrul MODIFY COLUMN kpp INT(9) UNSIGNED NOT NULL;
ALTER TABLE egrul
	ADD CONSTRAINT egrul_owner_id_fk
		FOREIGN KEY (owner_id) REFERENCES users(id);


DESC banks;
SELECT * FROM banks LIMIT 4;

-- Добавим в таблицу egrul записи о банках
INSERT INTO egrul VALUES
('First National Bank', '7701147911', '770134986', 'Moscow, 6438 Jeffery Street Suite 235', '2019-12-15', '64'),
('Second Independent Bank', '7701147352', '770134986', 'Moscow, 6438 Henry Street 239', '2019-12-01', '65'),
('Small Local Bank', '5401143810', '540131376', 'Novosibirsk, 3681 Vern Ways', '2019-12-02', '63'),
('Small Local Bank', '5401147911', '540131376', 'Novosibirsk, 3681 Vern Ways', '2019-12-02', '63');

ALTER TABLE banks MODIFY COLUMN name VARCHAR(100) NOT NULL;
ALTER TABLE banks MODIFY COLUMN inn BIGINT(10) UNSIGNED NOT NULL;
SELECT LENGTH(bik) FROM banks LIMIT 1;
ALTER TABLE banks MODIFY COLUMN bik INT(9) UNSIGNED NOT NULL;
ALTER TABLE banks MODIFY COLUMN division INT(4) UNSIGNED NOT NULL;
SELECT LENGTH(correspondent_account) FROM banks LIMIT 1;
ALTER TABLE banks MODIFY COLUMN correspondent_account VARCHAR(25) NOT NULL;
ALTER TABLE banks MODIFY COLUMN bank_account_number VARCHAR(25) NOT NULL;
CREATE INDEX banks_bik_idx ON banks(bik);

ALTER TABLE banks
	ADD CONSTRAINT banks_inn_fk
		FOREIGN KEY (inn) REFERENCES egrul(inn);

DESC tariff_book;
SELECT * FROM tariff_book LIMIT 1;

DESC client_accounts;
SELECT * FROM client_accounts LIMIT 1;

ALTER TABLE client_accounts MODIFY COLUMN id INT(5) UNSIGNED ZEROFILL NOT NULL PRIMARY KEY;
SELECT LENGTH(bank_account) FROM client_accounts LIMIT 1;
ALTER TABLE client_accounts MODIFY COLUMN bank_account VARCHAR(25) NOT NULL;
ALTER TABLE client_accounts MODIFY COLUMN account_balance DECIMAL(10,2) NOT NULL;
ALTER TABLE client_accounts MODIFY COLUMN inn BIGINT(10) UNSIGNED NOT NULL;
ALTER TABLE client_accounts MODIFY COLUMN bik INT(9) UNSIGNED NOT NULL;
ALTER TABLE client_accounts MODIFY COLUMN created_at DATE NOT NULL;

CREATE INDEX client_accounts_inn_idx ON client_accounts(inn);

ALTER TABLE client_accounts
	ADD CONSTRAINT client_accounts_inn_fk
		FOREIGN KEY (inn) REFERENCES egrul(inn);

DESC currency;
SELECT * FROM currency;
ALTER TABLE currency MODIFY COLUMN tag INT(3) UNSIGNED NOT NULL;

UPDATE client_accounts SET currency = '810';
ALTER TABLE client_accounts MODIFY COLUMN currency INT(3) UNSIGNED NOT NULL;
ALTER TABLE client_accounts
	ADD CONSTRAINT client_accounts_currency_fk
		FOREIGN KEY (currency) REFERENCES currency(tag);


ALTER TABLE client_accounts
	ADD CONSTRAINT client_accounts_bik_fk
		FOREIGN KEY (bik) REFERENCES banks(bik);

-- Добавим столбец для указания тарифа, по которому обслуживается счет
ALTER TABLE client_accounts
	ADD COLUMN tariff_id INT(2) UNSIGNED NOT NULL;
		
UPDATE client_accounts 
	SET tariff_id = (SELECT id FROM tariff_book ORDER BY RAND() LIMIT 1);

DESC tariff_book;
SELECT * FROM tariff_book;

ALTER TABLE tariff_book MODIFY COLUMN id INT(2) UNSIGNED NOT NULL;
ALTER TABLE tariff_book MODIFY COLUMN name VARCHAR(20) NOT NULL;
ALTER TABLE tariff_book MODIFY COLUMN description TEXT NOT NULL;

ALTER TABLE client_accounts
	ADD CONSTRAINT client_accounts_tariff_id_fk
		FOREIGN KEY (tariff_id) REFERENCES tariff_book(id);


-- Доработаем таблицу счетов контрагентов также, как это было сделано для клиентов банка	
ALTER TABLE counterpart_accounts MODIFY COLUMN id INT(5) UNSIGNED ZEROFILL NOT NULL PRIMARY KEY;
ALTER TABLE counterpart_accounts MODIFY COLUMN bank_account VARCHAR(25) NOT NULL;
ALTER TABLE counterpart_accounts MODIFY COLUMN account_balance DECIMAL(10,2) NOT NULL;
ALTER TABLE counterpart_accounts MODIFY COLUMN inn BIGINT(10) UNSIGNED NOT NULL;
ALTER TABLE counterpart_accounts MODIFY COLUMN bik INT(9) UNSIGNED NOT NULL;
ALTER TABLE counterpart_accounts MODIFY COLUMN created_at DATE NOT NULL;

CREATE INDEX counterpart_accounts_inn_idx ON counterpart_accounts(inn);

ALTER TABLE counterpart_accounts
	ADD CONSTRAINT counterpart_accounts_inn_fk
		FOREIGN KEY (inn) REFERENCES egrul(inn);

UPDATE counterpart_accounts SET currency = '810';
ALTER TABLE counterpart_accounts MODIFY COLUMN currency INT(3) UNSIGNED NOT NULL;
ALTER TABLE counterpart_accounts
	ADD CONSTRAINT counterpart_accounts_currency_fk
		FOREIGN KEY (currency) REFERENCES currency(tag);

ALTER TABLE counterpart_accounts
	ADD CONSTRAINT counterpart_accounts_bik_fk
		FOREIGN KEY (bik) REFERENCES banks(bik);
	
DESC client_payments;
SELECT * FROM incoming_payments;

DESC client_payments;
SELECT * FROM client_payments LIMIT 1;

ALTER TABLE client_payments MODIFY COLUMN id INT(10) UNSIGNED NOT NULL PRIMARY KEY;
ALTER TABLE client_payments MODIFY COLUMN from_counterpart INT(5) UNSIGNED ZEROFILL NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN to_counterpart INT(5) UNSIGNED ZEROFILL NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN payment_queue int(10) UNSIGNED NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN amount DECIMAL(10,2) UNSIGNED NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN status INT(10) UNSIGNED NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN purpose TEXT NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN created_at DATETIME NOT NULL;
ALTER TABLE client_payments MODIFY COLUMN updated_at DATETIME NOT NULL;

ALTER TABLE client_payments
	ADD CONSTRAINT client_payments_from_counterpart_fk
		FOREIGN KEY (from_counterpart) REFERENCES client_accounts(id);

ALTER TABLE client_payments
	ADD CONSTRAINT client_payments_to_counterpart_fk
		FOREIGN KEY (to_counterpart) REFERENCES counterpart_accounts(id);

DESC paynent_queue_statuses;	

ALTER TABLE client_payments
	ADD CONSTRAINT client_payments_payment_queue_fk
		FOREIGN KEY (payment_queue) REFERENCES paynent_queue_statuses(id);

DESC paynent_statuses;

ALTER TABLE client_payments
	ADD CONSTRAINT client_payments_status_fk
		FOREIGN KEY (status) REFERENCES paynent_statuses(id);

DESC incoming_payments;
SELECT * FROM incoming_payments LIMIT 1;

-- Доработаем таблицу входящих платежей также, как это было сделано для входящих
ALTER TABLE incoming_payments MODIFY COLUMN id INT(10) UNSIGNED NOT NULL PRIMARY KEY;
ALTER TABLE incoming_payments MODIFY COLUMN from_counterpart INT(5) UNSIGNED ZEROFILL NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN to_counterpart INT(5) UNSIGNED ZEROFILL NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN payment_queue int(10) UNSIGNED NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN amount DECIMAL(10,2) UNSIGNED NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN status INT(10) UNSIGNED NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN purpose TEXT NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN created_at DATETIME NOT NULL;
ALTER TABLE incoming_payments MODIFY COLUMN updated_at DATETIME NOT NULL;

ALTER TABLE incoming_payments
	ADD CONSTRAINT incoming_payments_from_counterpart_fk
		FOREIGN KEY (from_counterpart) REFERENCES counterpart_accounts(id);

ALTER TABLE incoming_payments
	ADD CONSTRAINT incoming_payments_to_counterpart_fk
		FOREIGN KEY (to_counterpart) REFERENCES client_accounts(id);

ALTER TABLE incoming_payments
	ADD CONSTRAINT incoming_payments_payment_queue_fk
		FOREIGN KEY (payment_queue) REFERENCES paynent_queue_statuses(id);

ALTER TABLE incoming_payments
	ADD CONSTRAINT incoming_payments_status_fk
		FOREIGN KEY (status) REFERENCES paynent_statuses(id);

DESC users_to_client_accounts;
SELECT * FROM users_to_client_accounts;

ALTER TABLE users_to_client_accounts
	ADD PRIMARY KEY (user_id, bank_account_id);

ALTER TABLE users_to_client_accounts
	ADD CONSTRAINT users_to_client_accounts_bank_account_id_fk
		FOREIGN KEY (bank_account_id) REFERENCES client_accounts(id);

ALTER TABLE users_to_client_accounts
	ADD CONSTRAINT users_to_client_accounts_user_id_fk
		FOREIGN KEY (user_id) REFERENCES users(id);
