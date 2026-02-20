-- ==========================================
-- Project: Klanten- en Productanalyse
-- Database: Schaalmodelauto’s
-- ==========================================

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

SELECT 'Customers' AS table_name,
       13 AS number_of_attributes,
       COUNT(*) AS number_of_rows
FROM Customers
UNION ALL
SELECT 'Products',
       9,
       COUNT(*)
FROM Products
UNION ALL
SELECT 'ProductLines',
       4,
       COUNT(*)
FROM ProductLines
UNION ALL
SELECT 'Orders',
       7,
       COUNT(*)
FROM Orders
UNION ALL
SELECT 'OrderDetails',
       5,
       COUNT(*)
FROM OrderDetails
UNION ALL
SELECT 'Payments',
       4,
       COUNT(*)
FROM Payments
UNION ALL
SELECT 'Employees',
       8,
       COUNT(*)
FROM Employees
UNION ALL
SELECT 'Offices',
       9,
       COUNT(*)
FROM Offices;

-- Deze query berekent voor elk product hoe snel het bijna uitverkocht is 
-- door de som van alle bestellingen te delen door de voorraad, 
-- afgerond op 2 decimalen, en toont de top 10 producten met de hoogste ratio.
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

-- Deze query berekent de totale omzet per product 
-- door de hoeveelheid bestellingen te vermenigvuldigen met de prijs, 
-- groepeert dit per product en toont de top 10 best presterende producten.
SELECT productCode,
       SUM(quantityOrdered * priceEach) AS product_performance
FROM orderdetails
GROUP BY productCode
ORDER BY product_performance DESC
LIMIT 10;

-- Deze query vindt prioriteitsproducten voor herbevoorrading:
-- het combineert de top 10 producten die bijna uitverkocht zijn (LowStock)
-- met de top 10 producten die de meeste omzet opleveren (ProductPerformance)
-- en toont alleen producten die in beide lijsten staan.
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
    SELECT productCode FROM ProductPerformance);
	
-- Bereken voor elke klant hoeveel winst hij/zij oplevert
-- door de verkochte hoeveelheid te vermenigvuldigen met het verschil tussen de prijs in de bestelling en de inkoopprijs
-- en tel dit op voor alle bestellingen van die klant.
SELECT c.customerNumber,
       SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
GROUP BY c.customerNumber
ORDER BY profit DESC;

-- Top 5 VIP-klanten
WITH CustomerProfit AS (
    SELECT o.customerNumber,
           SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    GROUP BY o.customerNumber
)
SELECT c.contactLastName,
       c.contactFirstName,
       c.city,
       c.country,
       cp.profit
FROM CustomerProfit cp
JOIN customers c ON cp.customerNumber = c.customerNumber
ORDER BY cp.profit DESC
LIMIT 5;

-- **Finding the VIP Customers**  
-- Deze query vindt de top 5 klanten die de meeste winst opleveren (VIPs)  
-- Gebruik deze informatie om marketing en communicatie af te stemmen op de meest waardevolle klanten.

-- STAP 1: Bereken de winst per klant met een CTE (tijdelijke tabel)
WITH CustomerProfit AS (
    SELECT 
        o.customerNumber,  -- het nummer van de klant
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  -- totale winst per klant
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  -- koppelt productgegevens aan bestelde producten
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  -- koppelt bestelling aan de klant
    GROUP BY o.customerNumber  -- groepeer resultaten per klant
)

-- STAP 2: Top 5 VIP-klanten ophalen
-- Voeg klantgegevens toe via een JOIN met de customers tabel
SELECT 
    c.contactLastName,   -- achternaam van de klant
    c.contactFirstName,  -- voornaam van de klant
    c.city,              -- stad waar de klant woont
    c.country,           -- land van de klant
    cp.profit            -- winst die de klant oplevert
FROM CustomerProfit cp
JOIN customers c 
    ON cp.customerNumber = c.customerNumber  -- voeg klantinformatie toe
ORDER BY cp.profit DESC  -- sorteert van hoog naar laag, zodat VIP-klanten bovenaan staan
LIMIT 5;  -- laat alleen de top 5 zien

-- **Finding the Least Engaged Customers**  
-- Deze query vindt de top 5 klanten die de minste winst opleveren (minder betrokken)  
-- Gebruik deze informatie om marketingacties te richten op klanten die meer betrokken kunnen worden.

-- STAP 1: Bereken de winst per klant met een CTE (tijdelijke tabel)
WITH CustomerProfit AS (
    SELECT 
        o.customerNumber,  -- het nummer van de klant
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  -- totale winst per klant
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  -- koppelt productgegevens aan bestelde producten
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  -- koppelt bestelling aan de klant
    GROUP BY o.customerNumber  -- groepeer resultaten per klant
)

-- STAP 2: Top 5 minst betrokken klanten ophalen
-- Voeg klantgegevens toe via een JOIN met de customers tabel
SELECT 
    c.contactLastName,   -- achternaam van de klant
    c.contactFirstName,  -- voornaam van de klant
    c.city,              -- stad waar de klant woont
    c.country,           -- land van de klant
    cp.profit            -- winst die de klant oplevert
FROM CustomerProfit cp
JOIN customers c 
    ON cp.customerNumber = c.customerNumber  -- voeg klantinformatie toe
ORDER BY cp.profit ASC  -- sorteert van laag naar hoog, zodat de minst winstgevende klanten bovenaan staan
LIMIT 5;  

-- laat alleen de top 5 zien

-- **Customer Lifetime Value (LTV) berekenen**  
-- Deze query berekent de gemiddelde winst per klant.  
-- Dit helpt bepalen hoeveel geld we veilig kunnen uitgeven aan het aantrekken van nieuwe klanten.

-- STAP 1: Maak een CTE (tijdelijke tabel) met de winst per klant
WITH CustomerProfit AS (
    SELECT 
        o.customerNumber,  -- het nummer van de klant
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit  -- totale winst per klant
    FROM products p
    JOIN orderdetails od 
        ON p.productCode = od.productCode  -- koppelt productgegevens aan bestelde producten
    JOIN orders o 
        ON o.orderNumber = od.orderNumber  -- koppelt bestelling aan de klant
    GROUP BY o.customerNumber  -- groepeer resultaten per klant
)

-- STAP 2: Bereken de gemiddelde winst per klant (Customer Lifetime Value)
SELECT 
    ROUND(AVG(profit), 2) AS average_customer_profit  -- gemiddelde winst afgerond op 2 decimalen
FROM CustomerProfit;

/*
**Verhaal van het Customers and Products Analysis Project**

**Vraag 1: Welke producten moeten we meer of minder inkopen?**
We hebben gekeken welke producten het vaakst worden verkocht en de meeste winst opleveren.  
Deze producten moeten we altijd op voorraad hebben.

Resultaten uit de query (prioriteit voor restocking):

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

---

**Vraag 2: Hoe richten we marketing op klanten?**

**Belangrijkste klanten (VIP, leveren veel winst):**

contactLastName | contactFirstName | city      | country | profit
----------------|-----------------|----------|--------|----------
Freyre          | Diego           | Madrid   | Spain  | 326,519.66
Nelson          | Susan           | San Rafael | USA   | 236,769.39
Young           | Jeff            | NYC      | USA    | 72,370.09
Ferguson        | Peter           | Melbourne| Australia | 70,311.07
Labrune         | Janine          | Nantes   | France | 60,875.30

**Minder actieve klanten (leveren weinig winst):**

contactLastName | contactFirstName | city       | country | profit
----------------|-----------------|-----------|--------|----------
Young           | Mary            | Glendale  | USA    | 2,610.87
Taylor          | Leslie          | Brickhaven| USA    | 6,586.02
Ricotti         | Franco          | Milan     | Italy  | 9,532.93
Schmitt         | Carine          | Nantes    | France | 10,063.80
Smith           | Thomas          | London    | UK     | 10,868.04

**Wat dit betekent:**  
- VIP-klanten leveren veel winst en verdienen speciale aanbiedingen of beloningen om ze tevreden te houden.  
- Minder actieve klanten leveren minder winst, maar we kunnen proberen ze meer aankopen te laten doen door gerichte acties of kortingen.

---

**Vraag 3: Hoeveel kunnen we uitgeven aan nieuwe klanten?**

De gemiddelde winst per klant (Customer Lifetime Value, LTV) is:

average_customer_profit
-----------------------
39,039.59

**Wat dit betekent:**  
- Een gemiddelde klant levert ongeveer $39.039 winst op.  
- Bijvoorbeeld: als we 10 nieuwe klanten krijgen, levert dat ongeveer $390.395 winst op.  
- Hiermee kunnen we bepalen hoeveel geld we veilig kunnen uitgeven aan marketing om nieuwe klanten te werven.
*/