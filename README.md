# Projet — Analyse des données d'une plateforme e-commerce

Projet de groupe du cours de bases de données relationnelles (EFREI M1). Nous avons modélisé la base d'une plateforme e-commerce sous PostgreSQL, chargé les données fournies, puis répondu en SQL aux questions de l'entreprise : produits les plus vendus, catégories les plus rentables, clients les plus actifs, évolution des ventes et qualité des données.

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `create_schema.sql` | Création des tables, clés et contraintes |
| `seed_ecommerce.sql` | Données de la plateforme (fourni) |
| `analysis.sql` | Toutes les requêtes d'analyse, de la partie 3 à la partie 7 |
| `README.md` | Ce document |

## Prérequis

- PostgreSQL installé, avec l'outil en ligne de commande `psql`.
- Un utilisateur PostgreSQL. Dans les commandes ci-dessous, remplacez `{utilisateur}` par votre nom d'utilisateur.

## Installation

Toutes les commandes se lancent depuis le dossier du projet.

### 1. Créer la base

```bash
createdb -U {utilisateur} ecommerce_db
```

### 2. Créer les tables

```bash
psql -U {utilisateur} -d ecommerce_db -f create_schema.sql
```

Le script supprime d'abord les tables si elles existent, puis les recrée. Il peut donc être relancé autant de fois que nécessaire. Attention : relancer le script efface les données déjà chargées.

### 3. Charger les données

```bash
psql -U {utilisateur} -d ecommerce_db -f seed_ecommerce.sql
```

### 4. Vérifier l'import

Ouvrez une session avec `psql -U {utilisateur} -d ecommerce_db`, puis comptez les lignes de chaque table :

```sql
SELECT 'client' AS nom_table, COUNT(*) AS nombre_lignes FROM client
UNION ALL SELECT 'produit', COUNT(*) FROM produit
UNION ALL SELECT 'commande', COUNT(*) FROM commande
UNION ALL SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;
```

Cette requête figure aussi dans `analysis.sql` (exercice 15 A).

## Exécuter les analyses

Pour lancer toutes les requêtes et enregistrer les résultats dans un fichier :

```bash
psql -U {utilisateur} -d ecommerce_db -f analysis.sql > resultats.txt
```

Pour lancer une seule requête, copiez-la dans un fichier `.sql`, puis exécutez-la depuis `psql` :

```
\i mon_fichier.sql
```

Évitez de coller une longue requête directement dans le terminal : certains terminaux, dont celui de VS Code, mélangent le texte collé et provoquent des erreurs de syntaxe.

## Modélisation

La base contient quatre tables :

- **`client`** : nom, prénom, email, ville et date d'inscription, tous obligatoires.
- **`produit`** : nom, catégorie, prix actuel et stock. Le prix doit être strictement positif et le stock positif ou nul.
- **`commande`** : client, date et statut. Le statut est limité aux quatre valeurs possibles (`payée`, `expédiée`, `livrée`, `annulée`) par une contrainte `CHECK`.
- **`ligne_commande`** : commande, produit, quantité et prix unitaire effectivement payé. La quantité et le prix doivent être strictement positifs.

Les relations sont assurées par des clés étrangères : une commande appartient à un client, et une ligne de commande relie une commande à un produit. Le prix payé est stocké dans `ligne_commande`, et pas seulement dans `produit`, car il peut différer du prix actuel (promotions, changements de prix).

## Règles de calcul

- Le montant d'une ligne est égal à la quantité multipliée par le prix unitaire effectivement payé.
- Les commandes au statut `annulée` sont exclues du chiffre d'affaires, des quantités vendues et du panier moyen.
- Le panier moyen est égal au chiffre d'affaires divisé par le nombre de commandes.

## Principales conclusions

La base contient 100 clients, 65 produits, 500 commandes et 1 547 lignes de commande. Les commandes couvrent toute l'année 2025, du 1er janvier au 29 décembre.

### Activité générale

| Indicateur | Valeur |
|---|---|
| Chiffre d'affaires (hors annulations) | 617 494,76 € |
| Nombre de commandes (hors annulations) | 484 |
| Panier moyen | 1 275,82 € |
| Clients actifs | 90 sur 100 |
| Taux d'annulation | 3,20 % (16 commandes sur 500) |

Le taux d'annulation est faible : plus de la moitié des commandes (279) sont déjà livrées.

Les commandes se répartissent en 103 petits paniers (moins de 500 €), 206 paniers moyens (de 500 € à moins de 1 500 €) et 191 gros paniers (1 500 € ou plus). Les paniers moyens et gros représentent donc près de 80 % des commandes.

### Évolution dans l'année

| Mois | Commandes | Chiffre d'affaires | Panier moyen |
|---|---:|---:|---:|
| Janvier | 29 | 34 765,36 € | 1 198,81 € |
| Février | 44 | 44 673,74 € | 1 015,31 € |
| Mars | 37 | 46 841,99 € | 1 266,00 € |
| Avril | 34 | 35 932,15 € | 1 056,83 € |
| Mai | 54 | 68 841,64 € | 1 274,85 € |
| Juin | 46 | 58 782,33 € | 1 277,88 € |
| Juillet | 38 | 55 406,98 € | 1 458,08 € |
| Août | 50 | 65 441,63 € | 1 308,83 € |
| Septembre | 36 | 40 578,54 € | 1 127,18 € |
| Octobre | 34 | 53 679,61 € | 1 578,81 € |
| Novembre | 40 | 51 895,45 € | 1 297,39 € |
| Décembre | 42 | 60 655,34 € | 1 444,17 € |

- **Mois les plus forts :** mai (68 841,64 €, avec le plus grand nombre de commandes) et août (65 441,63 €).
- **Mois les plus faibles :** janvier (34 765,36 €) et avril (35 932,15 €).
- **Tendance générale :** le second semestre rapporte environ 13 % de plus que le premier (327 657,55 € contre 289 837,21 €), alors que le nombre de commandes est presque le même (240 contre 244). La hausse vient donc surtout de paniers plus élevés. Octobre en est le meilleur exemple : peu de commandes (34), mais le panier moyen le plus haut de l'année (1 578,81 €).

### Produits et catégories

| Catégorie | Chiffre d'affaires | Part du CA | Quantité vendue |
|---|---:|---:|---:|
| Sport | 162 149,83 € | 26,3 % | 780 |
| Informatique | 138 024,98 € | 22,4 % | 1 051 |
| Mode | 124 202,00 € | 20,1 % | 753 |
| Maison | 111 359,19 € | 18,0 % | 727 |
| Audio | 81 758,76 € | 13,2 % | 490 |

- **Sport** est la catégorie qui rapporte le plus. **Informatique** est celle qui vend le plus d'unités, mais à un prix moyen plus bas, ce qui la place en deuxième position en chiffre d'affaires.
- **Produits les plus vendus en quantité :** Montre sport 1 (101 unités), puis Casque 1 et Écran 2 (94 unités chacun).
- **Produits qui rapportent le plus :** Sac à dos 1 (24 925,47 €), Gourde 1 (23 589,49 €) et Écouteurs 1 (21 678,00 €). Les produits les plus vendus ne sont donc pas forcément ceux qui rapportent le plus.
- **Clients qui rapportent le plus :** Alice Dubois (Nice, 11 commandes, 17 169,00 €), Sarah Bernard (Paris, 15 432,22 €) et Nathan Bernard (Lyon, 15 324,36 €).
- **Produits jamais vendus :** 5 produits, un par catégorie : Chemise 1, Corde à sauter 1, Platine vinyle 1, Imprimante 1 et Grille-pain 1. Ils immobilisent 325 unités en stock. Ce sont les cinq derniers produits ajoutés au catalogue (identifiants 61 à 65) : il peut s'agir de nouveautés, ou de produits à mettre en avant ou à retirer.

### Qualité des données

- **Commandes antérieures à l'inscription :** 30 commandes, réparties sur 12 clients, sont datées avant la date d'inscription du client, de 2 à 194 jours avant. C'est impossible dans la réalité : soit la date d'inscription est fausse, soit la date de commande l'est. Ces anomalies sont à corriger à la source.
- **Valeurs manquantes :** aucune. Toutes les colonnes sont renseignées, y compris la catégorie des produits, qui n'est pas obligatoire dans le schéma.
- **Clients sans commande :** 10 clients inscrits n'ont jamais passé de commande. Ce n'est pas une erreur, mais une information utile pour les relancer.

### Analyses libres (partie 7)

Nous avons choisi trois questions qui n'étaient pas traitées dans les exercices précédents. Les requêtes complètes sont à la fin de `analysis.sql`.

#### 1. Les clients commandent-ils plusieurs fois ?

Nous avons utilisé les tables `client`, `commande` et `ligne_commande` pour séparer les clients qui n'ont jamais acheté, ceux qui ont fait un seul achat et ceux qui ont commandé plusieurs fois.

88 clients réguliers ont passé 482 commandes et représentent 99,74 % du chiffre d'affaires. Deux clients n'ont fait qu'un seul achat et dix n'ont jamais commandé.

Le chiffre d'affaires repose donc presque entièrement sur les clients réguliers. L'entreprise pourrait chercher à fidéliser les deux clients qui n'ont commandé qu'une fois, et proposer une offre de bienvenue aux clients inscrits qui n'ont jamais acheté.

#### 2. Les produits sont-ils souvent vendus moins cher que leur prix actuel ?

Nous avons comparé le prix payé dans `ligne_commande` avec le prix actuel enregistré dans `produit`, sans compter les commandes annulées.

775 lignes de commande ont un prix inférieur au prix actuel. Elles représentent 1 991 unités vendues et 304 891,00 € de chiffre d'affaires, avec un écart moyen de -11,68 %. Les 725 autres lignes ont le même prix que le prix actuel.

Ce résultat donne une idée du poids des promotions dans les ventes. Il faut toutefois l'interpréter avec prudence : le prix actuel du produit a pu changer depuis la commande.

#### 3. Quelles catégories sont achetées ensemble ?

Nous avons recherché les catégories présentes dans une même commande. Une paire de catégories n'est comptée qu'une fois par commande.

Les trois associations les plus fréquentes sont :

- Informatique et Mode : 136 commandes ;
- Informatique et Sport : 135 commandes ;
- Informatique et Maison : 131 commandes.

La catégorie Informatique apparaît dans les trois premières associations. L'entreprise pourrait s'en servir pour proposer des produits complémentaires ou créer des offres groupées autour de l'informatique.
