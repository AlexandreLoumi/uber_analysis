--------------------------------
-- 1. EXPLORATION DES DONNÉES
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
-- 2. MÉTRIQUES BUSINESS CLÉS
--------------------------------

/*
Analyser les principaux indicateurs de performance de
l'activité d'Uber.
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


--------------------------------
-- 3. ANALYSE DE LA DEMANDE ET DU MARCHÉ
--------------------------------

/*
Évolution du volume de courses au fil du temps pour identifier
les tendances saisonnières et les périodes de forte activité.
*/

SELECT
    strftime('%Y-%m', requested_at) AS 'Mois',
    COUNT(*) AS "Nombre de courses"
FROM trips
GROUP BY strftime('%Y-%m', requested_at)
ORDER BY strftime('%Y-%m', requested_at) ;

/*
Analyse des villes les plus fréquentées par les utilisateurs
pour identifier les zones à fort potentiel de croissance et d'expansion.
*/

SELECT
    locations.city AS 'Ville',
    COUNT(*) AS "Nombre de courses"
FROM trips
JOIN locations ON trips.pickup_location_id = locations.location_id
GROUP BY locations.city
ORDER BY "Nombre de courses" DESC;

-- !!!!!!!!!!!!!!!!! ANALYSER LA QUALITÉ DU MARCHÉ (annulations par ville, notes des chauffeurs par ville...)

--------------------------------
-- 4. ANALYSE DES ANNULATIONS ET DE LA QUALITÉ DE SERVICE
--------------------------------

-- Quel est le taux d'annulation des course ?

SELECT
    100.0 * COUNT(cancellations.trip_id)  / COUNT(trips.trip_id) AS "Taux d'annulation"
FROM trips
LEFT JOIN cancellations ON trips.trip_id = cancellations.trip_id;


-- Quelles sont les raisons d'annulation principales ?

SELECT
    COUNT(cancel_id) AS "Nombre d'annulations",
    reason AS "Raison de l'annulation",
    cancelled_by AS "Annulé par"
FROM cancellations
GROUP BY reason, cancelled_by
ORDER BY "Nombre d'annulations" DESC;


-- Combien de chiffre d'affaires perd Uber à cause des annulations ?

SELECT
    cancellations.reason AS "Raison d'annulation",
    SUM(trips.total_fare) AS "CA potentiel perdu",
    COUNT(*) AS "Nombre d'annulations",
    ROUND(AVG(trips.total_fare), 2) AS "Montant moyen des courses annulées" 
FROM cancellations
JOIN trips ON cancellations.trip_id = trips.trip_id
GROUP BY cancellations.reason
ORDER BY "CA potentiel perdu" DESC;


--------------------------------
-- 5. ANALYSE OPÉRATIONNELLE
--------------------------------

/*
Quelles sont les courses les plus rentables ?
Par rentable, on entend les courses qui rapportent le plus de CA
par minutes et par km parcourus.
Je compare les catégories de trajets selon leur durée et leur distance
afin d'identifier celles qui génèrent le plus de CA et offrent
la meilleure rentabilité en temps et en distance.
*/

WITH courses_quartile AS (
    SELECT
        NTILE(4) OVER (ORDER BY duration_mins) AS quartile_duree,
        duration_mins,
        distance_km,
        total_fare
    FROM trips
)
SELECT

    CASE
        WHEN quartile_duree = 1 THEN "Trajet court"
        WHEN quartile_duree = 2 THEN "Trajet moyen"
        WHEN quartile_duree = 3 THEN "Trajet long"
        ELSE "Trajet très long"
    END AS "Catégorie durée",

    ROUND(SUM(total_fare) / SUM(duration_mins), 2) AS "CA par minute",
    ROUND(SUM(total_fare) / SUM(distance_km), 2) AS "CA par km",
    COUNT(*) AS "Nombre de courses",
    SUM(total_fare) AS "CA total",
    AVG(total_fare) AS "CA moyen"
FROM courses_quartile
GROUP BY quartile_duree;



/*
Quels sont les créneaux Jour / Heure les plus demandés ?
L'analyse croise le jour de la semaine et l'heure de la journée
afin d'identifier les créneaux générant le plus de demandes.
*/

WITH jour_semaine AS (
    SELECT
        strftime('%w', requested_at) AS 'Jour',
        strftime('%H', requested_at) AS 'Heure de la journée',
        trip_id
    FROM trips
)
SELECT
    CASE
        WHEN Jour = '0' THEN 'Dimanche'
        WHEN Jour = '1' THEN 'Lundi'
        WHEN Jour = '2' THEN 'Mardi'
        WHEN Jour = '3' THEN 'Mercredi'
        WHEN Jour = '4' THEN 'Jeudi'
        WHEN Jour = '5' THEN 'Vendredi'
        WHEN Jour = '6' THEN 'Samedi'
    END AS 'Jour de la semaine',
    COUNT(trip_id) AS 'Nombre de courses',
    "Heure de la journée"
FROM jour_semaine
GROUP BY "Jour de la semaine", "Heure de la journée"
ORDER BY "Nombre de courses" DESC
LIMIT 10;


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


-- Quels chauffeurs génèrent le PLUS de CA par unité de temps ?

SELECT
    users.name AS "Chauffeurs",
    ROUND((SUM(trips.total_fare) / SUM(trips.duration_mins)) * 60, 2) AS "CA par heure",
    COUNT(*) AS "Nombre de courses",
    SUM(trips.total_fare) AS "CA total"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
GROUP BY users.name
ORDER BY "CA par heure" DESC
LIMIT 10;

-- Quels chauffeurs génèrent le MOINS de CA par unité de temps ?

SELECT
    users.name AS "Chauffeurs",
    ROUND((SUM(trips.total_fare) / SUM(trips.duration_mins)) * 60, 2) AS "CA par heure",
    COUNT(*) AS "Nombre de courses",
    SUM(trips.total_fare) AS "CA total"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
GROUP BY users.name
ORDER BY "CA par heure" ASC
LIMIT 10;

-- Quels chauffeurs contribuent le plus aux annulations

WITH trips_cte AS (
    SELECT
        driver_id,
        COUNT(*) AS total_courses
    FROM trips
    GROUP BY driver_id
)
SELECT
    users.name AS "Chauffeurs",
    total_courses,
    COUNT(cancellations.cancel_id) AS "Nombre d'annulations",
    ROUND(100.0 * COUNT(cancellations.cancel_id) / total_courses, 2) AS "Taux d'annulation"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
JOIN trips_cte ON drivers.driver_id = trips_cte.driver_id
JOIN cancellations ON trips.trip_id = cancellations.trip_id
GROUP BY drivers.driver_id, users.name, total_courses
ORDER BY "Taux d'annulation" DESC
LIMIT 10;

