# NIVELL 1 ----------------------------------------------------------------------------
# EXERCICI 2 --- Utilitzant JOIN

# Llistat dels països que estan fent compres.
SELECT DISTINCT country
FROM transaction
INNER JOIN company	
ON transaction.company_id = company.id
;

# Des de quants països es realitzen les compres.
SELECT COUNT(DISTINCT country) AS countries
FROM transaction
INNER JOIN company
ON transaction.company_id = company.id
;

# Identifica la companyia amb la mitjana més gran de vendes.
SELECT company_name
FROM company
JOIN transaction
ON company.id = transaction.company_id
GROUP BY company.id
ORDER BY AVG(amount) DESC
LIMIT 1
;

# EXERCICI 3 --- Utilitzant només subconsultes (sense utilitzar JOIN)
# Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction
WHERE company_id IN
		(SELECT id
		FROM company
        WHERE country = 'Germany')
;

# Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT company.company_name, AVG(amount)
FROM transaction, company
WHERE transaction.company_id = company.id
GROUP BY company_id
HAVING AVG(amount) > (SELECT AVG(amount) FROM transaction) #general average
;

# Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
# No n'hi ha empreses sense transaccions registrades:
SELECT *
FROM transaction
WHERE company_id NOT IN (SELECT id
FROM company)
;

# NIVELL 2 ----------------------------------------------------------------------------
# EXERCICI 1 --- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. Mostra la data de cada transacció juntament amb el total de les vendes.
SELECT company.company_name, DATE(transaction.timestamp) AS date, SUM(transaction.amount) AS total_amount
FROM transaction
JOIN company
ON company.id = transaction.company_id
GROUP BY company_name, DATE(timestamp)
ORDER BY SUM(amount) DESC
LIMIT 5
;

# EXERCICI 2 --- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
SELECT company.country, AVG(amount)
FROM company
JOIN transaction
ON company.id = transaction.company_id
GROUP BY country
ORDER BY AVG(amount) DESC
;

# EXERCICI 3 ---  Llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que "Non Institute"
# Amb JOIN i subconsultes:
SELECT *
FROM transaction
JOIN company
ON company.id = transaction.company_id
WHERE country = (SELECT country
		FROM company
		WHERE company_name = "Non Institute")
;
# Solament subconsultes:
SELECT *
FROM transaction, company
WHERE company.id = transaction.company_id
AND country = (SELECT country
		FROM company
		WHERE company_name = "Non Institute")
;

# Nivell 3 ----------------------------------------------------------------------------
# EXERCICI 1 --- nom, telèfon, país, data i amount de empreses amb transaccions de entre 100 i 200 euros, el 29 d'abril del 2021, 20 de juliol del 2021 o 13 de març del 2022
SELECT company_name, phone, country, DATE(timestamp) AS date, amount
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE amount BETWEEN 100 AND 200
AND DATE(timestamp) IN ('2021-04-29', '2021-07-20', '2022-03-13')
;

# EXERCICI 2 --- quantitat de transaccions que realitzen les empreses on s'especifiqui si tenen més de 4 transaccions o menys.
SELECT company_name,
	CASE
    WHEN  COUNT(*) >= 4 THEN 'Més de 4'
    ELSE 'Menys de 4'	
END AS transaction_count
FROM company
JOIN transaction
ON company.id = transaction.company_id
GROUP BY company_name
;