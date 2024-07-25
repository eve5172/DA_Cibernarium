# NIVELL 1 -------------------------------------------------------
# EXERCICI 1 --- Crear taula credit_card, relacionar-la amb les altres taules.

USE transactions;

# Crear tabla
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR (100) PRIMARY KEY,
    iban VARCHAR (50),
    pan VARCHAR (50),
    pin VARCHAR (50),
    cvv VARCHAR (50),
    expiring_date VARCHAR (10)
    );

# Agregar FK a la tabla transaction para relacionarlas
ALTER TABLE transaction
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id)
;

# EXERCICI 2 --- Error en el número de compte de l'usuari amb ID CcU-2938, hauria de ser: R323456312213576817699999
UPDATE credit_card
SET iban = 'R323456312213576817699999'
WHERE id = 'CcU-2938'
;
SELECT id, iban
FROM credit_card
WHERE id = 'CcU-2938'
;

# EXERCICI 3 --- Ingressar nou registre a la taula transaction
# Desabilitar FK constraints
SET FOREIGN_KEY_CHECKS = 0;

# Ingressar les dades del nou usuari
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', '111.11', '0')
;

# Habilitar FK constraints
SET FOREIGN_KEY_CHECKS = 1;

# Verificar dades en la taula
SELECT *
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD'
;

# S'agrega el registre creat a la taula transaction a les altres taules perquè les dades siguin coherents en totes les taules
INSERT INTO credit_card (id)
VALUES ('CcU-9999');

INSERT INTO company (id)
VALUES ('b-9999');

INSERT INTO user (id)
VALUES ('9999');

# EXERCICI 4 --- Eliminar la columna 'pan' de la taula credit_card
ALTER TABLE credit_card
DROP COLUMN pan
;
SELECT *
FROM credit_card
;

# NIVELL 2 --------------------------------------------------------------------------------
# EXERCICI 1 --- Elimina de la taula transaction el registre amb ID 02C6201E-D90A-1859-B4EE-88D2986D3B02
DELETE FROM transaction
WHERE id = '02C6201E-D90A-1859-B4EE-88D2986D3B02'
;

# EXERCICI 2 --- Crear VistaMarketing amb: nom de la companyia, telèfon, país, mitjana de compra de cada companyia. Presentar ordenant de major a menor la mitjana de compres.
CREATE VIEW VistaMarketing AS
SELECT company.company_name AS Companyia,
		company.phone AS Telefon,
        company.country AS Pais,
        ROUND(AVG(transaction.amount), 2) AS 'Mitjana compres'
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE transaction.declined = 0
GROUP BY 1, 2, 3
;
SELECT *
FROM VistaMarketing
ORDER BY 'Mitjana compres' DESC
;

# EXERCICI 3 --- Filtra VistaMarketing per a mostrar companyies amb país 'Germany'
SELECT *
FROM VistaMarketing
WHERE country = 'Germany'
;

# NIVELL 3 ---------------------------------------------------------------------------------
# EXERCICI 1 --- Fer comandos per a obtenir el diagrama
# 1. Se cambia el tipo del campo cvv, de VARCHAR a INT
ALTER TABLE credit_card
MODIFY COLUMN cvv INT(3)
;

# 2. Se crea una columna: actual_date
ALTER TABLE credit_card
ADD COLUMN actual_date DATE
AS (STR_TO_DATE(expiring_date, '%m/%d/%y')) STORED
;

# 3. Se elimina el campo website
ALTER TABLE company
DROP COLUMN website
;

# 4. Se crea la tabla data_user sin la línea de foreign key
CREATE INDEX idx_user_id ON transaction(user_id);
 
CREATE TABLE IF NOT EXISTS user (
        id INT PRIMARY KEY,
        name VARCHAR(100),
        surname VARCHAR(100),
        phone VARCHAR(150),
        email VARCHAR(150),
        birth_date VARCHAR(100),
        country VARCHAR(150),
        city VARCHAR(150),
        postal_code VARCHAR(100),
        address VARCHAR(255)
    );

# Se agrega la FK a la tabla transaction
SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE transaction
ADD FOREIGN KEY (user_id) REFERENCES user(id)
;
SET FOREIGN_KEY_CHECKS = 1;

# Se cargan los datos de la tabla user desde el archivo datos_introducir_user(1)

# Se cambia el nombre de la columna email a personal_email.
ALTER TABLE user
RENAME COLUMN email TO personal_email
;

# Se cambió el nombre de la tabla de user a data_user
RENAME TABLE user TO data_user
;

# EXERCICI 2 --- Crear vista anomenada 'InformeTecnico'
CREATE VIEW InformeTecnico AS
SELECT transaction.id AS 'ID de la transacció',
		user.name AS Nom,
        user.surname AS Cognom,
        credit_card.iban AS IBAN,
        company.company_name AS Companyia
FROM transaction
JOIN user
ON transaction.user_id = user.id
JOIN credit_card
ON transaction.credit_card_id = credit_card.id
JOIN company
ON transaction.company_id = company.id
;
SELECT *
FROM InformeTecnico
ORDER BY 'ID de la transacció' DESC
;