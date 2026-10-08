-- =====================================================================
-- PARTIE 3 - ANALYSE SQL
-- =====================================================================

-- EXERCICE 1 - Explorer les produits
SELECT *
FROM produit;

SELECT *
FROM produit
WHERE prix >= 100;


-- EXERCICE 2 - Explorer les clients
SELECT *
FROM client
WHERE ville = 'Paris';

SELECT
    ville,
    COUNT(*) AS nombre_clients
FROM client
GROUP BY ville;


-- EXERCICE 3 - Explorer les commandes
SELECT
    c.id,
    c.date_commande,
    c.statut,
    clt.*
FROM commande c
INNER JOIN client clt
    ON clt.id = c.client_id;


-- EXERCICE 4 - Montant d'une ligne
SELECT
    *,
    quantite * prix_unitaire AS total
FROM ligne_commande;


-- EXERCICE 5 - Montant des commandes
SELECT
    c.id AS commande_id,
    c.date_commande,
    c.statut,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS total
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
GROUP BY c.id
ORDER BY c.id;


-- EXERCICE 6 - Chiffre d'affaires par categorie
SELECT
    p.categorie,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    SUM(lc.quantite) AS quantite_totale
FROM produit p
INNER JOIN ligne_commande lc
    ON lc.produit_id = p.id
INNER JOIN commande c
    ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;


-- EXERCICE 7 - Produits les plus vendus
SELECT
    p.id,
    p.nom,
    p.categorie,
    SUM(lc.quantite) AS quantite_totale
FROM produit p
INNER JOIN ligne_commande lc
    ON lc.produit_id = p.id
INNER JOIN commande c
    ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.id
ORDER BY quantite_totale DESC
LIMIT 10;


-- EXERCICE 8 - Produits generant le plus de chiffre d'affaires
SELECT
    p.nom,
    p.categorie,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires
FROM produit p
INNER JOIN ligne_commande lc
    ON lc.produit_id = p.id
INNER JOIN commande c
    ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.id
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- EXERCICE 9 - Clients
SELECT
    clt.nom,
    clt.prenom,
    COUNT(DISTINCT c.id) AS nb_commandes,
    COALESCE(ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2), 0) AS total_depenses
FROM client clt
LEFT JOIN commande c
    ON c.client_id = clt.id
   AND c.statut <> 'annulée'
LEFT JOIN ligne_commande lc
    ON lc.commande_id = c.id
GROUP BY clt.id
ORDER BY total_depenses DESC;


-- EXERCICE 10 - Panier moyen
-- Panier moyen de la plateforme
SELECT
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND((SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id))::numeric, 2) AS panier_moyen
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- Panier moyen par mois
SELECT
    DATE_TRUNC('month', c.date_commande)::date AS mois,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    ROUND((SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id))::numeric, 2) AS panier_moyen
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY mois
ORDER BY mois;


-- =====================================================================
-- PARTIE 4 - TRANSFORMATION DES DONNEES
-- =====================================================================

-- EXERCICE 11 - Categoriser les commandes
SELECT
    c.id AS commande_id,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS montant,
    CASE
        WHEN SUM(lc.quantite * lc.prix_unitaire) < 500  THEN 'Petit panier'
        WHEN SUM(lc.quantite * lc.prix_unitaire) < 1500 THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS categorie
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
GROUP BY c.id
ORDER BY c.id;


-- EXERCICE 12 - Analyse temporelle
SELECT
    TO_CHAR(c.date_commande, 'YYYY-MM') AS mois,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    RANK() OVER (ORDER BY SUM(lc.quantite * lc.prix_unitaire) DESC) AS rang,
    ROUND(
        (SUM(lc.quantite * lc.prix_unitaire)
         - LAG(SUM(lc.quantite * lc.prix_unitaire)) OVER (ORDER BY TO_CHAR(c.date_commande, 'YYYY-MM'))
        )::numeric,
        2
    ) AS evolution
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY TO_CHAR(c.date_commande, 'YYYY-MM')
ORDER BY mois;


-- =====================================================================
-- PARTIE 5 - QUALITE DES DONNEES
-- =====================================================================

-- EXERCICE 13 - Detecter une incoherence
-- Commandes passees avant la date d'inscription du client
SELECT
    co.id AS commande_id,
    cl.id AS client_id,
    co.date_commande,
    cl.date_inscription,
    co.date_commande - cl.date_inscription AS difference_jours
FROM commande co
INNER JOIN client cl
    ON cl.id = co.client_id
WHERE co.date_commande < cl.date_inscription;

-- Nombre d'anomalies (requete separee pour plus de lisibilite)
SELECT
    COUNT(*) AS nb_anomalies
FROM commande co
INNER JOIN client cl
    ON cl.id = co.client_id
WHERE co.date_commande < cl.date_inscription;


-- EXERCICE 14 - Produits sans vente
SELECT
    p.nom,
    p.categorie,
    p.prix,
    p.stock
FROM produit p
LEFT JOIN ligne_commande lc
    ON lc.produit_id = p.id
WHERE lc.id IS NULL;

/*
Connaitre les produits qui n'ont jamais ete vendus permet de detecter
les produits peu attractifs. L'entreprise peut alors proposer des
promotions pour les ecouler, ou arreter de les reapprovisionner.
*/


-- =====================================================================
-- PARTIE 6 - TABLEAU DE BORD EN SQL
-- =====================================================================

-- EXERCICE 15 - Indicateurs cles

-- A. Exploration
-- Nombre de lignes de chaque table
SELECT 'client' AS nom_table, COUNT(*) AS nombre_lignes FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;

-- Colonnes et types de donnees
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('client', 'produit', 'commande', 'ligne_commande');

-- Valeurs manquantes : COUNT(*) compte toutes les lignes, COUNT(colonne) ignore les NULL
SELECT
    COUNT(*) - COUNT(nom) AS nom_manquant,
    COUNT(*) - COUNT(prenom) AS prenom_manquant,
    COUNT(*) - COUNT(email) AS email_manquant,
    COUNT(*) - COUNT(ville) AS ville_manquante,
    COUNT(*) - COUNT(date_inscription) AS date_inscription_manquante
FROM client;

SELECT
    COUNT(*) - COUNT(nom) AS nom_manquant,
    COUNT(*) - COUNT(categorie) AS categorie_manquante,
    COUNT(*) - COUNT(prix) AS prix_manquant,
    COUNT(*) - COUNT(stock) AS stock_manquant
FROM produit;

SELECT
    COUNT(*) - COUNT(client_id) AS client_id_manquant,
    COUNT(*) - COUNT(date_commande) AS date_commande_manquante,
    COUNT(*) - COUNT(statut) AS statut_manquant
FROM commande;

SELECT
    COUNT(*) - COUNT(commande_id) AS commande_id_manquant,
    COUNT(*) - COUNT(produit_id) AS produit_id_manquant,
    COUNT(*) - COUNT(quantite) AS quantite_manquante,
    COUNT(*) - COUNT(prix_unitaire) AS prix_unitaire_manquant
FROM ligne_commande;


-- B. Analyse commerciale
SELECT
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND((SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id))::numeric, 2) AS panier_moyen,
    COUNT(DISTINCT c.client_id) AS clients_actifs
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- Taux d'annulation
SELECT
    COUNT(*) AS total_commandes,
    SUM(CASE WHEN statut = 'annulée' THEN 1 ELSE 0 END) AS commandes_annulees,
    ROUND(100.0 * SUM(CASE WHEN statut = 'annulée' THEN 1 ELSE 0 END) / COUNT(*), 2) AS taux_annulation_pct
FROM commande;


-- C. Analyse des clients
SELECT
    clt.id AS client_id,
    clt.nom,
    clt.prenom,
    clt.ville,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires
FROM client clt
INNER JOIN commande c
    ON c.client_id = clt.id
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY clt.id
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- D. Synthese mensuelle
-- On supprime la table si elle existe deja, pour pouvoir relancer le fichier
DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT
    EXTRACT(YEAR FROM c.date_commande) AS annee,
    EXTRACT(MONTH FROM c.date_commande) AS mois,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    ROUND((SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id))::numeric, 2) AS panier_moyen
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY
    EXTRACT(YEAR FROM c.date_commande),
    EXTRACT(MONTH FROM c.date_commande);

SELECT *
FROM synthese_mensuelle
ORDER BY annee, mois;

/*
Cette table resume l'activite mois par mois en trois indicateurs. Elle permet
de voir d'un coup d'oeil si les ventes progressent ou reculent, et de reperer
les mois forts et les mois faibles.

Ce que la table permet d'observer :
- les mois les plus forts sont mai, aout et decembre, les plus faibles
  janvier, avril et septembre ;
- le second semestre (327 657,55 EUR) depasse le premier (289 837,21 EUR)
  d'environ 13 % ;
- le chiffre d'affaires depend du nombre de commandes et du panier moyen :
  le nombre de commandes est presque le meme sur les deux semestres
  (244 puis 240), donc la hausse vient surtout de paniers plus eleves.
  Octobre le montre bien : peu de commandes (34), mais le panier moyen
  le plus haut de l'annee (1 578,81 EUR).
*/


-- =====================================================================
-- PARTIE 7 - ANALYSE LIBRE
-- =====================================================================

-- ANALYSE 1 - Clients reguliers
-- Comparer le chiffre d'affaires des clients reguliers et occasionnels.
WITH montant_commandes AS (
    SELECT
        c.id AS commande_id,
        c.client_id,
        SUM(lc.quantite * lc.prix_unitaire)::numeric AS montant
    FROM commande c
    INNER JOIN ligne_commande lc
        ON lc.commande_id = c.id
    WHERE c.statut <> 'annulée'
    GROUP BY c.id, c.client_id
),
resume_clients AS (
    SELECT
        cl.id AS client_id,
        COUNT(mc.commande_id) AS nombre_commandes,
        COALESCE(SUM(mc.montant), 0)::numeric AS chiffre_affaires
    FROM client cl
    LEFT JOIN montant_commandes mc
        ON mc.client_id = cl.id
    GROUP BY cl.id
),
segments AS (
    SELECT
        CASE
            WHEN nombre_commandes = 0 THEN 'Aucun achat'
            WHEN nombre_commandes = 1 THEN 'Un seul achat'
            ELSE 'Client régulier'
        END AS type_client,
        nombre_commandes,
        chiffre_affaires
    FROM resume_clients
)
SELECT
    type_client,
    COUNT(*) AS nombre_clients,
    SUM(nombre_commandes) AS nombre_commandes,
    ROUND(SUM(chiffre_affaires), 2) AS chiffre_affaires,
    ROUND(
        100.0 * SUM(chiffre_affaires)
        / NULLIF(SUM(SUM(chiffre_affaires)) OVER (), 0),
        2
    ) AS part_ca_pct
FROM segments
GROUP BY type_client
ORDER BY chiffre_affaires DESC;


-- ANALYSE 2 - Prix paye et prix actuel
-- Comparer le prix paye par le client avec le prix actuel du produit.
SELECT
    CASE
        WHEN lc.prix_unitaire < p.prix THEN 'Prix inférieur au prix actuel'
        WHEN lc.prix_unitaire = p.prix THEN 'Même prix que le prix actuel'
        ELSE 'Prix supérieur au prix actuel'
    END AS comparaison_prix,
    COUNT(*) AS nombre_lignes,
    SUM(lc.quantite) AS unites_vendues,
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    ROUND(AVG(100.0 * (lc.prix_unitaire - p.prix) / p.prix)::numeric, 2) AS ecart_moyen_pct
FROM ligne_commande lc
INNER JOIN commande c
    ON c.id = lc.commande_id
INNER JOIN produit p
    ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY comparaison_prix
ORDER BY comparaison_prix;


-- ANALYSE 3 - Categories achetees ensemble
-- Trouver les categories les plus souvent achetees dans la meme commande.
WITH categories_par_commande AS (
    SELECT DISTINCT
        c.id AS commande_id,
        p.categorie
    FROM commande c
    INNER JOIN ligne_commande lc
        ON lc.commande_id = c.id
    INNER JOIN produit p
        ON p.id = lc.produit_id
    WHERE c.statut <> 'annulée'
),
paires AS (
    SELECT
        a.categorie AS categorie_1,
        b.categorie AS categorie_2,
        COUNT(*) AS nombre_commandes
    FROM categories_par_commande a
    INNER JOIN categories_par_commande b
        ON b.commande_id = a.commande_id
       AND b.categorie > a.categorie
    GROUP BY a.categorie, b.categorie
),
total_commandes AS (
    SELECT COUNT(*)::numeric AS total
    FROM commande
    WHERE statut <> 'annulée'
)
SELECT
    p.categorie_1,
    p.categorie_2,
    p.nombre_commandes,
    ROUND(100.0 * p.nombre_commandes / t.total, 2) AS pourcentage_commandes
FROM paires p
CROSS JOIN total_commandes t
ORDER BY p.nombre_commandes DESC
LIMIT 10;
