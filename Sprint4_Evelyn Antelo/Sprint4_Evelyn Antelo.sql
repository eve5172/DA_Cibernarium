# NIVELL 1 -----------------------------------------------------------
# Dissenya una base de dades amb un esquema d'estrella que contingui almenys 4 taules
CREATE DATABASE transactionsnew;

CREATE TABLE credit_cards (
id VARCHAR(50) PRIMARY KEY,
user_id INT,
iban VARCHAR(50),
pan VARCHAR(50),
pin INT,
cvv INT,
track1 VARCHAR(100),
track2 VARCHAR(100),
expiring_date VARCHAR(8)
);

CREATE TABLE companies (
id VARCHAR(50) PRIMARY KEY,
company_name VARCHAR(100),
phone VARCHAR(15),
email VARCHAR(100),
country VARCHAR(100),
website VARCHAR(100)
);

CREATE TABLE users (
id INT PRIMARY KEY,
name VARCHAR(50),
surname VARCHAR(50),
phone VARCHAR(15),
email VARCHAR(100),
birth_date VARCHAR(12),
country VARCHAR(100),
city VARCHAR(50),
postal_code VARCHAR(10),
address VARCHAR(100)
);

CREATE TABLE transactions (
id VARCHAR(50) PRIMARY KEY,
card_id VARCHAR(50),
company_id VARCHAR(50),
timestamp TIMESTAMP,
amount DECIMAL(10,2),
declined TINYINT(1),
product_ids VARCHAR(100),
user_id INT,
lat FLOAT,
longitude FLOAT,
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
FOREIGN KEY (company_id) REFERENCES companies(id),
FOREIGN KEY (user_id) REFERENCES users(id)
);

# Para cargar los datos desde los archivos CSV con código SQL se colocan los archivos en la carpeta que MySQL habilita como fuente para cargar archivos (intenté modificar los permisos pero sin éxito).
# El siguiente código muestra la ubicación de la carpeta:
SHOW VARIABLES LIKE "secure_file_priv";

# Se cargan los datos en cada tabla, confirmando a continuación que se hayan cargado correctamente
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
;

SELECT * FROM credit_cards;

LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
;

SELECT * FROM companies;

LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\users_ca.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
;

LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\users_uk.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
;

LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\users_usa.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
;	

SELECT * FROM users;

LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
IGNORE 1 ROWS
;

SELECT * FROM transactions;

# EXERCICI 1 --- Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.
# Si se intenta hacer esta consulta solo con subqueries, devuelve el listado de los usuarios con más de 30 transacciones pero no la cantidad de transacciones, por lo tanto se hace una JOIN además de la subconsulta, ya que es un dato útil.
SELECT users.id, CONCAT(users.name, ' ', users.surname) AS Name, auxt.Transactions
FROM users
JOIN (SELECT user_id, COUNT(id) AS Transactions
		FROM transactions
		GROUP BY user_id
		HAVING COUNT(id) > 30) auxt
ON users.id = auxt.user_id
;


# EXERCICI 2 --- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT companies.company_name AS Company, credit_cards.iban AS IBAN, ROUND(AVG(transactions.amount), 2) AS 'Avg. amount'
FROM transactions
JOIN credit_cards
ON transactions.card_id = credit_cards.id
JOIN companies
ON transactions.company_id = companies.id
WHERE company_name = 'Donec Ltd'
GROUP BY IBAN
;

# NIVELL 2
# Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades
CREATE TABLE card_status
AS
# Se crea una CTE en la que se dividen por card_id y se ordenan por fecha las filas. El campo latest3 enumera las transacciones en orden descendiente comenzando desde 1 en cada card_id diferente.
WITH auxtransactions AS (
	SELECT
		card_id,
        timestamp,
        declined,
        DENSE_RANK() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS latest3
	FROM transactions
)
# En la SELECT que usa la CTE auxtransactions se filtran las últimas tres transacciones en el WHERE y con CASE se asigna la etiqueta 'blocked' a las transacciones que tienen tres instancias en que declined sea True (es decir, en que la suma de los valores de declined es 3).
SELECT
	card_id,
    CASE
		WHEN SUM(declined) = 3 THEN 'blocked'
        ELSE 'active'
	END AS status
FROM auxtransactions
WHERE latest3 <= 3
GROUP BY card_id
;

# Se agrega la foreign key para vincular la tabla a transactions
ALTER TABLE card_status
ADD FOREIGN KEY (card_id) REFERENCES credit_cards(id)
;

# Comprobación de la tabla
SELECT *
FROM card_status
;

# EXERCICI 1 --- Quantes targetes estan actives?
SELECT COUNT(status) AS active_cards
FROM card_status
WHERE status = 'active'
;

# Nivell 3 ------------------------------------------------------------------------------
# Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, tenint en compte que des de transaction tens product_ids.

# Se crea una tabla puente llamada bridge_products con los campos transaction_id (vinculado con el campo id de la tabla transactions) y product_id (vinculado con el campo id de la tabla products)
CREATE TABLE bridge_products (transaction_id VARCHAR(50), product_id INT)
AS
# Se genera una CTE en la que se dividen los números de productos que están separados por coma en el campo product_ids. Se utiliza la función SUBSTRING_INDEX para extraer cada valor antes de la coma y los resultados se almacenan en campos llamados p1, p2, p3, p4.
WITH aux
AS (
SELECT id,
	SUBSTRING_INDEX(transactions.product_ids, ', ', 1) AS p1,
	SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ', ', 2), ', ', -1) AS p2,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ', ', 3), ', ', -1) AS p3,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ', ', 4), ', ', -1) AS p4
FROM transactions)
# En la siguiente subquery se colocan los valores de los campos p1, p2, p3 y p4 de la tabla aux en un solo campo llamado product_id utilizando la función UNION, y no UNION ALL, para no incluir los valores repetidos (que se generaron en el paso anterior, pues SUBSTRING_INDEX devuelve el último valor si no encuentra uno nuevo)
SELECT id AS transaction_id, product_id
FROM (SELECT id, p1 AS product_id
	FROM aux
	UNION 
	SELECT id, p2
	FROM aux
	UNION
	SELECT id, p3
	FROM aux
	UNION
	SELECT id, p4
	FROM aux
) AS aux2
# Se ordena por id para mayor claridad al visualizar la tabla
ORDER BY 1
;

# Se crea la tabla products
CREATE TABLE products (
id INT PRIMARY KEY,
product_name VARCHAR(100),
price VARCHAR(20),
colour VARCHAR(20),
weight DECIMAL(8,2),
warehouse_id VARCHAR(15)
);

# Se agregan las foreign keys para vincular las tablas transactions y products a través de la tabla puente
SET FOREIGN_KEY_CHECKS = 0
;
ALTER TABLE bridge_products
ADD FOREIGN KEY (transaction_id) REFERENCES transactions(id),
ADD FOREIGN KEY (product_id) REFERENCES products(id)
;
SET FOREIGN_KEY_CHECKS = 1
;

# Se introducen los datos en la tabla products
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
;

# Se comprueba la tabla products
SELECT * FROM products;

# Se comprueba la tabla bridge_products
SELECT * FROM bridge_products;

# Exercici 1 --- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
SELECT product_id, product_name, COUNT(product_id)
FROM products
JOIN bridge_products ON products.id = bridge_products.product_id
JOIN transactions ON transactions.id = bridge_products.transaction_id
WHERE declined = 0
GROUP BY 1
;
