DROP TABLE IF EXISTS ligne_commande;
DROP TABLE IF EXISTS commande;
DROP TABLE IF EXISTS produit;
DROP TABLE IF EXISTS client;

CREATE TABLE IF NOT EXISTS client (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(250) NOT NULL,
    prenom VARCHAR(250) NOT NULL,
    email VARCHAR(250) NOT NULL,
    ville VARCHAR(250) NOT NULL,
    date_inscription DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS produit (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    categorie VARCHAR(100),
    prix FLOAT CHECK (prix > 0) NOT NULL,       
    stock INTEGER CHECK (stock >= 0) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS commande (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    date_commande DATE NOT NULL,
    statut VARCHAR(100),
    CONSTRAINT fk_commande_client
        FOREIGN KEY (client_id)
        REFERENCES client(id),
    CONSTRAINT chk_commandes_statut
        CHECK (
            statut IN (
                'payée',
                'expédiée',
                'livrée',
                'annulée'
            )
        )
);

CREATE TABLE IF NOT EXISTS ligne_commande (
    id SERIAL PRIMARY KEY,
    commande_id INTEGER NOT NULL,
    produit_id INTEGER NOT NULL,
    quantite INTEGER CHECK (quantite > 0) NOT NULL,
    prix_unitaire FLOAT CHECK (prix_unitaire > 0) NOT NULL,
    CONSTRAINT fk_ligne_commande_commande
        FOREIGN KEY (commande_id)
        REFERENCES commande(id),
    CONSTRAINT fk_ligne_commande_produit
        FOREIGN KEY (produit_id)
        REFERENCES produit(id)
);