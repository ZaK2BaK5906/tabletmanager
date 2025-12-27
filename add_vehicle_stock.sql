-- Ajouter colonne stock à la table vehicles
ALTER TABLE vehicles
ADD COLUMN stock INT DEFAULT 5;

-- Mettre stock à 50 pour les véhicules gratuits
UPDATE vehicles SET stock = 50 WHERE model IN ('club', 'panto', 'issi2');
