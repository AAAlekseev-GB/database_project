USE project;

-- Ниже приведены скрипты характерных выборок

-- Клиент запрашивает полные платежные реквизиты для выставления счета контрагенту
-- будем считать, что он авторизуется по ИНН своей организации
SELECT * FROM bank_details WHERE ИНН = '5401000111';

DROP VIEW IF EXISTS bank_details;
CREATE OR REPLACE VIEW bank_details AS
	SELECT 
		egrul.name AS 'Наименование',
		egrul.inn AS 'ИНН',
		egrul.kpp AS 'КПП',
		client_accounts.bank_account AS 'расчетного счет №',
		banks.name AS 'в банке',
		client_accounts.bik AS 'Банковский идентификатор',
		banks.correspondent_account AS 'Корреспондентский счет',
		users.name AS 'Руководитель',
		users.phone  AS 'Телефон', -- Телефон
		users.email AS 'email', -- почта
		egrul.formal_adress AS 'Юридический адрес'
			FROM users
				JOIN egrul 
					ON egrul.owner_id = users.id
				JOIN users_to_client_accounts 
					ON users_to_client_accounts.user_id = users.id
				JOIN client_accounts 
					ON users_to_client_accounts.bank_account_id = client_accounts.id
				JOIN banks 
					ON client_accounts.bik = banks.bik;

-- Клиент запрашивает банковскую выписку за определенный период
SELECT * FROM bank_statement 
	WHERE (получатель = 'Bruen-Wunsch' OR отправитель = 'Bruen-Wunsch') 
    AND (дата BETWEEN '2020-01-05 00:00:00' AND '2020-01-15 23:59:59')
    ORDER BY дата;

DROP VIEW IF EXISTS bank_statement;
CREATE OR REPLACE VIEW bank_statement AS
	SELECT 
		client_payments.id AS '№',
        CONCAT('-', client_payments.amount) AS 'сумма',
        client.name AS 'отправитель',
        counterpart.name AS 'получатель',
        client_payments.created_at AS 'дата'
		FROM client_payments
			JOIN client_accounts 
				ON client_payments.from_counterpart = client_accounts.id
			JOIN counterpart_accounts 
				ON client_payments.to_counterpart = counterpart_accounts.id
			JOIN egrul AS client
				ON client_accounts.inn = client.inn
			JOIN egrul AS counterpart
					ON counterpart_accounts.inn = counterpart.inn
		WHERE status = 8
	UNION
		SELECT 
		incoming_payments.id AS '№',
        CONCAT('+', incoming_payments.amount) AS 'сумма',
        counterpart.name AS 'отправитель',
        client.name AS 'получатель',
        incoming_payments.created_at AS 'дата'
		FROM incoming_payments
			JOIN client_accounts 
				ON incoming_payments.to_counterpart = client_accounts.id
			JOIN counterpart_accounts 
				ON incoming_payments.from_counterpart = counterpart_accounts.id
			JOIN egrul AS client
				ON client_accounts.inn = client.inn
			JOIN egrul AS counterpart
				ON counterpart_accounts.inn = counterpart.inn
		WHERE status = 8;

-- Сотрудник банка решил порекомендовать клиентам тарифы, которые им больше подходят
SELECT * FROM client_tariffs ORDER BY total_payments DESC LIMIT 10;
SELECT * FROM client_tariffs 
	WHERE (total_payments > 10 OR turnover > 500000)
    AND tariff = 'perfect_start'
		ORDER BY total_payments DESC LIMIT 10;

DROP VIEW IF EXISTS client_tariffs;
CREATE OR REPLACE VIEW client_tariffs AS
	SELECT 
		client_accounts.id,
		COUNT(client_payments.id) AS total_payments,
		SUM(client_payments.amount) AS turnover, -- оборот по исходящим платежам
		egrul.name AS 'компания',
		tariff_book.name AS tariff,
        tariff_book.description AS 'описание'
		FROM client_accounts
			JOIN client_payments
				ON client_payments.from_counterpart = client_accounts.id
			JOIN egrul
				ON client_accounts.inn = egrul.inn
			JOIN tariff_book
				ON client_accounts.tariff_id = tariff_book.id
			JOIN users_to_client_accounts
				ON users_to_client_accounts.bank_account_id = client_accounts.id
			JOIN users
				ON users.id = users_to_client_accounts.user_id
			WHERE client_payments.status = 8
				GROUP BY client_accounts.id;
            
-- Клиент запрашивает подтвержение операции в формате платежного поручения
SELECT * FROM payment_order WHERE № = '3';

DROP VIEW IF EXISTS payment_order;
CREATE OR REPLACE VIEW payment_order AS
	SELECT 
		client_payments.id AS '№',
        client_payments.created_at AS 'от',
        users.name AS 'заверено',
        paynent_statuses.status AS 'статус',
        client_payments.updated_at AS 'исполнено банком',
        client_payments.amount AS 'сумма платежа' ,
        client.name AS 'плательщик',
        client_accounts.bank_account AS 'расчетный счет плательщика',
        client_bank.name AS 'банк плательщика',
        counterpart.name AS 'получатель',
        counterpart_accounts.bank_account AS 'расчетный счет получателя',
        counterpart_bank.name AS 'банк получателя',
        client_payments.purpose AS 'назначение платежа'
        FROM client_payments
			JOIN client_accounts 
				ON client_payments.from_counterpart = client_accounts.id
			JOIN counterpart_accounts 
				ON client_payments.to_counterpart = counterpart_accounts.id
			JOIN egrul AS client
				ON client_accounts.inn = client.inn
			JOIN egrul AS counterpart
				ON counterpart_accounts.inn = counterpart.inn
			JOIN banks AS client_bank
				ON client_accounts.bik = client_bank.bik    
			JOIN banks AS counterpart_bank
				ON counterpart_accounts.bik = counterpart_bank.bik
			JOIN paynent_statuses
				ON client_payments.status = paynent_statuses.id    
			JOIN users_to_client_accounts 
				ON users_to_client_accounts.bank_account_id = client_payments.from_counterpart
			JOIN users 
				ON users_to_client_accounts.user_id = users.id;
