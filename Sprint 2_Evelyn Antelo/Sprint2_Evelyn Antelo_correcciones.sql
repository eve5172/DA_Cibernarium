# NIVELL 1 -------------------------------------------------------------------------------
# EXERCICI 2 --- Utilizant JOIN

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
SELECT company_name, ROUND(AVG(amount), 2) AS top_avg_amount
FROM transaction
JOIN company
ON transaction.company_id = company.id
GROUP BY company_id
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
SELECT DISTINCT company_name
FROM company
WHERE id IN (SELECT company_id
			FROM transaction
            WHERE amount > (SELECT AVG(amount)
							FROM transaction))
;

# Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT company_name
FROM company
WHERE id NOT IN (SELECT company_id
				FROM transaction)
;

# NIVELL 2 -------------------------------------------------------------------------------
# EXERCICI 1 --- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. Mostra la data de cada transacció juntament amb el total de les vendes. -- Como se trata de ventas (transacciones aprobadas), se agrega la condición declined = 0.
SELECT date(timestamp) AS date, SUM(amount) AS total_amount
FROM transaction
WHERE declined = 0
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
;

# EXERCICI 2 --- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
SELECT company.country AS country, ROUND(AVG(transaction.amount),2) AS avg_sales
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE transaction.declined = 0
GROUP BY 1
ORDER BY 2 DESC
;

# EXERCICI 3 --- Llista de totes les transacciones realitzades per empreses que estan situades en el mateix país que "Non Institute"

# Amb JOIN i subconsultes:
SELECT *
FROM transaction
JOIN company
ON transaction.company_id = company.id
WHERE country = (SELECT country
				FROM company
                WHERE company_name = 'Non Institute')
;

# Solament subconsultes:
SELECT *
FROM transaction
WHERE company_id IN (SELECT id
					FROM company
                    WHERE country = (SELECT country
									FROM company
                                    WHERE company_name = 'Non Institute'))
;

# NIVELL 3 --------------------------------------------------------------------------------
# EXERCICI 1 --- Nom, telèfon, país, data i amount de empreses amb transaccions de entre 100 i 200 euros, el 29 d'abril del 2021, 20 de juliol del 2021 o 13 de març del 2022. Ordena els resultats de major a menor quantitat
SELECT company_name, phone, country, DATE(timestamp) AS date, amount
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE amount BETWEEN 100 AND 200
	AND DATE(timestamp) IN ('2021-04-29', '2021-07-20', '2022-03-13')
ORDER BY amount DESC
;

# EXERCICI 2 --- Quantitat de transaccions que realitzen les empreses on s'especifiqui si tenen més de 4 transacciones o menys
SELECT company_name,
	CASE
		WHEN COUNT(transaction.id) >= 4 THEN 'Més de 4'
		ELSE 'Menys de 4'
	END AS transaction_count
FROM company
JOIN transaction
ON company.id = transaction.company_id
GROUP BY 1
;