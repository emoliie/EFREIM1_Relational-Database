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

### Activité générale

*À compléter avec les résultats des exercices 10, 12 et 15 : chiffre d'affaires total, nombre de commandes, panier moyen, taux d'annulation, mois les plus forts et les plus faibles.*

### Produits et catégories

*À compléter avec les résultats des exercices 6, 7, 8 et 14 : catégories et produits qui génèrent le plus de chiffre d'affaires, produits jamais vendus.*

### Qualité des données

*À compléter avec les résultats de l'exercice 13 : nombre de commandes datées avant l'inscription du client.*

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
