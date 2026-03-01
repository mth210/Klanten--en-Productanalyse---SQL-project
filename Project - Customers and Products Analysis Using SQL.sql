-- ==========================================
-- Project: Klanten- en Productanalyse
-- Database: Schaalmodelauto’s
-- ==========================================
/*
Resultaten uit de queries:

-- Vraag 1: Welke producten moeten we meer of minder inkopen?--

productName                  | productLine
-----------------------------|-------------
1968 Ford Mustang            | Classic Cars
1911 Ford Town Car           | Vintage Cars
1928 Mercedes-Benz SSK       | Vintage Cars
1960 BSA Gold Star DBD34     | Motorcycles
1997 BMW F650 ST             | Motorcycles
1928 Ford Phaeton Deluxe     | Vintage Cars
2002 Yamaha YZR M1           | Motorcycles
The Mayflower                | Ships
F/A 18 Hornet 1/72           | Planes
Pont Yacht                   | Ships

--Vraag 2: Hoe richten we marketing op klanten?--

**Belangrijkste klanten (VIP, leveren veel winst op):**

contactLastName | contactFirstName | city      | country | profit
----------------|-----------------|----------|--------|----------
Freyre          | Diego           | Madrid   | Spain  | 326,519.66
Nelson          | Susan           | San Rafael | USA   | 236,769.39
Young           | Jeff            | NYC      | USA    | 72,370.09
Ferguson        | Peter           | Melbourne| Australia | 70,311.07
Labrune         | Janine          | Nantes   | France | 60,875.30

**Minder actieve klanten (leveren weinig winst op):**

contactLastName | contactFirstName | city       | country | profit
----------------|-----------------|-----------|--------|----------
Young           | Mary            | Glendale  | USA    | 2,610.87
Taylor          | Leslie          | Brickhaven| USA    | 6,586.02
Ricotti         | Franco          | Milan     | Italy  | 9,532.93
Schmitt         | Carine          | Nantes    | France | 10,063.80
Smith           | Thomas          | London    | UK     | 10,868.04

--Wat dit betekent: 
- VIP-klanten leveren veel winst en verdienen speciale aanbiedingen of beloningen om ze tevreden te houden.  
- Minder actieve klanten leveren minder winst, maar we kunnen proberen ze meer aankopen te laten doen door gerichte acties of kortingen.

--Vraag 3: Hoeveel kunnen we uitgeven aan nieuwe klanten?--

De gemiddelde winst per klant (Customer Lifetime Value, LTV) is:

average_customer_profit
-----------------------
39,039.59

--Wat dit betekent:-- 
- Een gemiddelde klant levert ongeveer $39.039 winst op.  
- Bijvoorbeeld: als we 10 nieuwe klanten krijgen, levert dat ongeveer $390.395 winst op.  
- Hiermee kunnen we bepalen hoeveel geld we veilig kunnen uitgeven aan marketing om nieuwe klanten te werven.

-- Beschrijving van de tabellen en hun relaties:
-- 
-- Customers: bevat gegevens van klanten, zoals naam, adres en contactinformatie.
-- Employees: bevat informatie over medewerkers, zoals naam, functie en kantoor.
-- Offices: informatie over verkoopkantoren, zoals locatie en telefoonnummer.
-- Orders: verkooporders van klanten, gekoppeld aan Customers en Employees.
-- OrderDetails: details van elke verkooporder, gekoppeld aan Orders en Products.
-- Payments: betalingsgegevens van klanten, gekoppeld aan Customers.
-- Products: lijst van schaalmodelauto’s, gekoppeld aan ProductLines.
-- ProductLines: categorieën van productlijnen (bijv. voertuigen, treinen, vliegtuigen).

-- ==========================================
-- Query: tabeloverzicht met aantal kolommen en rijen
-- ==========================================
*/

-- SQL Queries

-- ==========================================
-- Overzicht: aantal rijen per tabel
-- ==========================================

SELECT 'Customers' AS table_name, 13 AS number_of_attributes, COUNT(*) AS number_of_rows FROM Customers
UNION ALL
SELECT 'Products', 9, COUNT(*) FROM Products
UNION ALL
SELECT 'ProductLines', 4, COUNT(*) FROM ProductLines
UNION ALL
SELECT 'Orders', 7, COUNT(*) FROM Orders
UNION ALL
SELECT 'OrderDetails', 5, COUNT(*) FROM OrderDetails
UNION ALL
SELECT 'Payments', 4, COUNT(*) FROM Payments
UNION ALL
SELECT 'Employees', 8, COUNT(*) FROM Employees
UNION ALL
SELECT 'Offices', 9, COUNT(*) FROM Offices;


-- ==========================================
-- Producten die bijna uitverkocht zijn
-- ==========================================

SELECT p.productCode,
       ROUND(
         (SELECT SUM(o.quantityOrdered)
          FROM orderdetails o
          WHERE o.productCode = p.productCode
         ) / p.quantityInStock, 2
       ) AS low_stock_ratio
FROM products p
ORDER BY low_stock_ratio DESC
LIMIT 10;


-- ==========================================
-- Producten met hoogste omzet
-- ==========================================

SELECT productCode,
       SUM(quantityOrdered * priceEach) AS product_performance
FROM orderdetails
GROUP BY productCode
ORDER BY product_performance DESC
LIMIT 10;


-- ==========================================
-- Prioriteitsproducten (staan in beide top 10 lijsten)
-- ==========================================

WITH LowStock AS (
    SELECT p.productCode,
           ROUND(
             (SELECT SUM(o.quantityOrdered)
              FROM orderdetails o
              WHERE o.productCode = p.productCode
             ) / p.quantityInStock, 2
           ) AS low_stock_ratio
    FROM products p
    ORDER BY low_stock_ratio DESC
    LIMIT 10
),
ProductPerformance AS (
    SELECT productCode,
           SUM(quantityOrdered * priceEach) AS product_performance
    FROM orderdetails
    GROUP BY productCode
    ORDER BY product_performance DESC
    LIMIT 10
)

SELECT *
FROM products
WHERE productCode IN (
    SELECT productCode FROM LowStock
    INTERSECT
    SELECT productCode FROM ProductPerformance
);


-- ==========================================
-- VRAAG 2: Hoe richten we marketing op klanten?
-- ==========================================

/*
Ik bereken eerst hoeveel winst elke klant oplevert.
Winst = verkochte hoeveelheid × (verkoopprijs - inkoopprijs)
*/

WITH CustomerProfit AS (
    SELECT 
        o.customerNumber, 
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  
    GROUP BY o.customerNumber 
)

-- ==========================================
-- Top 5 VIP-klanten (meeste winst)
-- ==========================================

SELECT 
    c.contactLastName,
    c.contactFirstName,
    c.city,
    c.country,
    cp.profit
FROM CustomerProfit cp
JOIN customers c 
    ON cp.customerNumber = c.customerNumber  
ORDER BY cp.profit DESC
LIMIT 5;


-- ==========================================
-- Top 5 minst winstgevende klanten
-- ==========================================

WITH CustomerProfit AS (
    SELECT 
        o.customerNumber,  
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  
    GROUP BY o.customerNumber  
)

SELECT 
    c.contactLastName,
    c.contactFirstName,
    c.city,
    c.country,
    cp.profit
FROM CustomerProfit cp
JOIN customers c 
    ON cp.customerNumber = c.customerNumber  
ORDER BY cp.profit ASC
LIMIT 5;


-- ==========================================
-- VRAAG 3: Hoeveel kunnen we uitgeven aan nieuwe klanten?
-- ==========================================

/*
Hier bereken ik de gemiddelde winst per klant.
Dit noemen we ook Customer Lifetime Value (LTV).
*/

WITH CustomerProfit AS (
    SELECT 
        o.customerNumber, 
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  
    GROUP BY o.customerNumber  
)

SELECT 
    ROUND(AVG(profit), 2) AS average_customer_profit  
FROM CustomerProfit;