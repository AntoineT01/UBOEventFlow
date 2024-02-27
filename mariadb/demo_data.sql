-- Insertion de données fictives dans la table Lieu
INSERT INTO Lieu (nom, adresse, capaciteAccueil) VALUES
('Salle Polyvalente', '123 rue de Brest, 29200 Brest', 100),
('Amphithéâtre K', '1 Avenue de la Plage, 29200 Brest', 200);

-- Insertion de données fictives dans la table Membre
INSERT INTO Membre (nom, prenom, dateNaissance, adresse, email, motDePasse) VALUES
('Dupont', 'Jean', '1980-04-12', '456 avenue de la République, 29200 Brest', 'jean.dupont@email.com', 'motdepasse123'),
('Martin', 'Alice', '1992-07-23', '789 rue de Siam, 29200 Brest', 'alice.martin@email.com', 'motdepasse456');

-- Insertion de données fictives dans la table Evenement
INSERT INTO Evenement (nom, dateHeureDebut, dateHeureFin, maxParticipant, lieuId) VALUES
('Conférence sur le climat', '2024-03-15 09:00:00', '2024-03-15 12:00:00', 80, 1),
('Atelier de programmation', '2024-04-20 14:00:00', '2024-04-20 17:00:00', 50, 2);

-- Insertion de données fictives dans la table Inscription
INSERT INTO Inscription (membreId, evenementId) VALUES
(1, 1),
(2, 2);



-- Insertion supplémentaire dans la table Lieu
INSERT INTO Lieu (nom, adresse, capaciteAccueil) VALUES
('Auditorium Maxime', '10 rue des Navigateurs, 29200 Brest', 150),
('Espace Événementiel Horizon', '22 avenue du Ponant, 29200 Brest', 250),
('La Grande Halle', '5 boulevard des Explorateurs, 29200 Brest', 300);

-- Insertion supplémentaire dans la table Membre
INSERT INTO Membre (nom, prenom, dateNaissance, adresse, email, motDePasse) VALUES
('Lebrun', 'Marie', '1990-05-16', '33 rue du Commerce, 29200 Brest', 'marie.lebrun@email.com', 'motdepasse789'),
('Riviere', 'Lucas', '1985-09-30', '27 avenue de la Liberté, 29200 Brest', 'lucas.riviere@email.com', 'password123'),
('Petit', 'Sophie', '1995-11-08', '9 rue de la Victoire, 29200 Brest', 'sophie.petit@email.com', 'passe123');

-- Insertion supplémentaire dans la table Evenement
INSERT INTO Evenement (nom, dateHeureDebut, dateHeureFin, maxParticipant, lieuId) VALUES
('Séminaire sur l\'innovation', '2024-05-25 10:00:00', '2024-05-25 16:00:00', 100, 3),
('Festival du Numérique', '2024-06-10 09:00:00', '2024-06-12 18:00:00', 200, 4),
('Rencontre des Jeunes Entrepreneurs', '2024-07-05 09:00:00', '2024-07-05 18:00:00', 150, 5);

-- Insertion supplémentaire dans la table Inscription
INSERT INTO Inscription (membreId, evenementId) VALUES
(3, 3),
(4, 4),
(5, 5),
(1, 3), -- Membre déjà existant s'inscrit à un nouvel événement
(2, 4); -- Membre déjà existant s'inscrit à un nouvel événement