# Analyse de courses VTC (SQL)

Projet d'analyse exploratoire réalisé en SQL à partir d'une base de données simulant l'activité d'une plateforme de VTC.


## Objectifs du projet

J'ai choisi d'orienter ce projet sur une analyse ayant pour objectif de répondre aux besoins d'équipes métier.
L'objectif est donc d'identifier des leviers d'optimisation par zone géographique, par utilisateur (chauffeur ou client), ou par
type de trajet par exemple.

Les équipes métier peuvent donc orienter leurs actions vers les insights découverts grâce à l'analyse.

## STACK

- SQL
- SQLite
- SQLTools (VS Code)
- Git
- GitHub


## Analyses réalisées

Le fichier `queries.sql` regroupe plusieurs analyses métier :

- KPI globaux
- Analyse du chiffre d'affaires
- Analyse des annulations
- Analyse des performances des chauffeurs
- Analyse des créneaux horaires
- Analyse des trajets (distance et durée)
- Analyse des zones géographiques
- Calcul de différents indicateurs de performance


## Optimisation

Le fichier `indexes.sql` contient les index utilisés afin d'améliorer les performances des requêtes les plus coûteuses.


##  Utilisation

1. Cloner le dépôt :

```bash
git clone https://github.com/AlexandreLoumi/uber_analysis.git
```

2. Ouvrir `data/rideshare.db` avec SQLite ou SQLTools.

3. Exécuter les requêtes présentes dans `queries.sql`.


## Source des données

Les données utilisées dans ce projet proviennent du jeu de données **Uber SQL Database** disponible sur Kaggle :

https://www.kaggle.com/datasets/rockyt07/uber-sql-database