--------------------------------
-- 1. DATA EXPLORATION
--------------------------------

/*
Identifier les tables présentes dans la base de données pour en
comprendre la structure.
*/

SELECT name FROM sqlite_master WHERE type = 'table';

PRAGMA table_info('riders');
PRAGMA table_info('trips');
PRAGMA table_info('drivers');
PRAGMA table_info('locations');
PRAGMA table_info('payments');
PRAGMA table_info('reviews');
PRAGMA table_info('users');
PRAGMA table_info('cancellations');

SELECT * FROM riders LIMIT 10;
SELECT * FROM cancellations LIMIT 10;
SELECT * FROM trips LIMIT 10;
SELECT * FROM drivers LIMIT 10;
SELECT * FROM users LIMIT 10;
SELECT * FROM locations LIMIT 10;
SELECT * FROM payments LIMIT 10;
SELECT * FROM reviews LIMIT 10;

--------------------------------
-- 2. KEY BUSINESS METRICS
--------------------------------

/*
Analyser les principaux indicateurs de performance de
l'activité d'Uber à partir de la table de faits (trips).

Les analyses portent notamment sur :
- le volume de courses
- la répartition des statuts
- les revenus générés
- les performances opérationnelles
*/


-- KPI 1 : volume de courses
SELECT COUNT(*) AS "Nombre total de courses"
FROM trips;


-- KPI 2 : distribution des courses par statut (completed, cancelled, in_progress)
SELECT status, COUNT(*) AS "Nombre de courses"
FROM trips
GROUP BY status;


-- KPI 3 : chiffre d'affaires total
SELECT SUM(total_fare) AS "Chiffre d'affaires total"
FROM trips;


-- KPI 4 : panier moyen par course
SELECT ROUND(AVG(total_fare), 2) AS "Panier moyen par course"
FROM trips;


-- KPI 5 : distance moyenne par course
SELECT ROUND(AVG(distance_km), 2) AS "Distance moyenne par course"
FROM trips;


-- KPI 6 : durée moyenne par course
SELECT ROUND(AVG(duration_mins), 2) AS "Durée moyenne par course"
FROM trips;


SELECT requested_at
FROM trips;

/*
Analyser l'évolution du volume de courses au fil du temps pour identifier
les tendances saisonnières et les périodes de forte activité.
*/

SELECT
    strftime('%Y-%m', requested_at) AS 'Mois',
    COUNT(*) AS "Nombre de courses"
FROM trips
GROUP BY strftime('%Y-%m', requested_at)
ORDER BY strftime('%Y-%m', requested_at) ;

/*
Analyser les villes les plus fréquentées par les utilisateurs
pour identifier les zones à fort potentiel de croissance et d'expansion.
*/

SELECT
    locations.city AS 'Ville',
    COUNT(*) AS "Nombre de courses"
FROM trips
JOIN locations ON trips.pickup_location_id = locations.location_id
GROUP BY locations.city
ORDER BY "Nombre de courses" DESC;


-- Qui sont les 10 chauffeurs ayant rapporté le plus de CA ?

SELECT
    users.name AS "Chauffeurs",
    COUNT(*) AS "Nombre de courses",
    ROUND(SUM(trips.total_fare), 2) AS "Chiffre d'affaires total généré"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
GROUP BY users.name
ORDER BY "Chiffre d'affaires total généré" DESC
LIMIT 10;


-- Quel est le taux d'annulation des course ?

SELECT
    100.0 * COUNT(cancellations.trip_id)  / COUNT(trips.trip_id) AS "Taux d'annulation"
FROM trips
LEFT JOIN cancellations ON trips.trip_id = cancellations.trip_id;

-- Quelles sont les raisons d'annulation ?
SELECT
    COUNT(cancel_id) AS "Nombre d'annulations",
    reason AS "Raison de l'annulation",
    cancelled_by AS "Annulé par"
FROM cancellations
GROUP BY reason, cancelled_by
ORDER BY "Nombre d'annulations" DESC;
