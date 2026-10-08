 -- PARTIE 3

 -- EXERCICE 1
SELECT * FROM produit;
SELECT * FROM produit WHERE prix >= 100;

-- EXERCICE 2
SELECT * FROM client WHERE ville = 'Paris';
SELECT ville, COUNT(*) AS nombre_clients FROM client GROUP BY ville;

-- EXERCICE 3
SELECT c.id, c.date_commande, c.statut, clt.* 
FROM commande c 
INNER JOIN client clt 
ON c.client_id = clt.id;

-- EXERCICE 4
SELECT *, quantite * prix_unitaire AS total FROM ligne_commande;

-- EXERCICE 5
SELECT c.id AS commande_id,
       c.date_commande,
       c.statut,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS total
FROM commande c
INNER JOIN ligne_commande lc
    ON lc.commande_id = c.id
GROUP BY c.id
ORDER BY c.id;

-- EXERCICE 6
SELECT p.categorie, 
    ROUND(SUM(lc.quantite * lc.prix_unitaire)::numeric, 2) AS chiffre_affaires,
    SUM(lc.quantite) AS quantite_totale
FROM produit p
INNER JOIN ligne_commande lc
    ON p.id = lc.produit_id
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;

