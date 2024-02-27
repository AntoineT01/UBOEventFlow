DROP TABLE IF EXISTS Inscription;
DROP TABLE IF EXISTS Evenement;
DROP TABLE IF EXISTS Membre;
DROP TABLE IF EXISTS Lieu;
DROP DATABASE IF EXISTS `UBOEventFlow_bdd`;

CREATE DATABASE IF NOT EXISTS `UBOEventFlow_bdd` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `UBOEventFlow_bdd`;

-- Création de la table Lieu
CREATE TABLE Lieu
(
    id              INT PRIMARY KEY AUTO_INCREMENT,
    nom             VARCHAR(255) NOT NULL,
    adresse         VARCHAR(255) NOT NULL,
    capaciteAccueil INT          NOT NULL
);

-- Création de la table Membre
CREATE TABLE Membre
(
    id            INT PRIMARY KEY AUTO_INCREMENT,
    nom           VARCHAR(255) NOT NULL,
    prenom        VARCHAR(255) NOT NULL,
    dateNaissance DATE         NOT NULL,
    adresse       VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    motDePasse    VARCHAR(255) NOT NULL,
    UNIQUE (nom, prenom) -- S'assure qu'il n'y a pas deux membres avec le même nom et prénom
);

-- Création de la table Evenement
CREATE TABLE Evenement
(
    id             INT PRIMARY KEY AUTO_INCREMENT,
    nom            VARCHAR(255) NOT NULL,
    dateHeureDebut DATETIME     NOT NULL,
    dateHeureFin   DATETIME     NOT NULL,
    maxParticipant INT          NOT NULL,
    lieuId         INT          NOT NULL,
    FOREIGN KEY (lieuId) REFERENCES Lieu (id)
);

-- Création de la table Inscription
CREATE TABLE Inscription
(
    membreId             INT,
    evenementId          INT,
    dateHeureInscription DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (membreId, evenementId),
    FOREIGN KEY (membreId) REFERENCES Membre (id),
    FOREIGN KEY (evenementId) REFERENCES Evenement (id)

);







-- Création de trigger pour vérifier le chevauchement des événements

DELIMITER //

CREATE TRIGGER BeforeInsertEvent
BEFORE INSERT ON Evenement
FOR EACH ROW
BEGIN
    DECLARE clash_found INT DEFAULT 0;

    -- Vérifiez si un autre événement a lieu dans le même lieu et s'il y a un chevauchement de temps
    SELECT COUNT(*)
    INTO clash_found
    FROM Evenement
    WHERE NEW.lieuId = Evenement.lieuId
      AND NOT (NEW.dateHeureFin <= Evenement.dateHeureDebut OR NEW.dateHeureDebut >= Evenement.dateHeureFin);

    IF clash_found > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un autre événement se déroule déjà dans le même lieu à la même heure.';
    END IF;
END;

//
DELIMITER ;




-- Création de trigger pour vérifier le nombre de participants

DELIMITER //

CREATE TRIGGER BeforeInsertInscription
BEFORE INSERT ON Inscription
FOR EACH ROW
BEGIN
    DECLARE capacite INT;
    DECLARE inscrits INT;
    DECLARE evenement_date DATETIME;

    -- Vérifiez si l'événement est passé
    SELECT dateHeureDebut INTO evenement_date FROM Evenement WHERE id = NEW.evenementId;
    IF evenement_date < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inscription impossible à un événement passé.';
    END IF;

    -- Obtenez la capacité d'accueil du lieu
    SELECT capaciteAccueil
    INTO capacite
    FROM Lieu
    WHERE id = (SELECT lieuId FROM Evenement WHERE id = NEW.evenementId);

    -- Obtenez le nombre actuel d'inscrits à l'événement
    SELECT COUNT(*)
    INTO inscrits
    FROM Inscription
    WHERE evenementId = NEW.evenementId;

    -- Vérifiez si l'événement a atteint la capacité maximale
    IF inscrits >= capacite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L’événement a atteint sa capacité maximale de participants.';
    END IF;
END;

//
DELIMITER ;




-- Création de trigger pour vérifier la modification valide de l'événement
DELIMITER //

CREATE TRIGGER BeforeUpdateEvent
BEFORE UPDATE ON Evenement
FOR EACH ROW
BEGIN
    DECLARE clash_found INT DEFAULT 0;

    -- Vérifiez si la mise à jour entraînerait un chevauchement d'événements
    SELECT COUNT(*) INTO clash_found
    FROM Evenement
    WHERE NEW.lieuId = lieuId
      AND id <> NEW.id -- Assurez-vous de comparer avec le nouvel ID en cas de mise à jour
      AND NOT (NEW.dateHeureFin <= dateHeureDebut OR NEW.dateHeureDebut >= dateHeureFin);

    IF clash_found > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La mise à jour de l’événement entraînerait un chevauchement dans le même lieu.';
    END IF;
END;

//
DELIMITER ;





-- Création de la procédure stockée pour s'incrire à un événement

--utilisation:
-- CALL InscrireMembre(1, 1);

DELIMITER //

CREATE PROCEDURE InscrireMembre(IN membre_id INT, IN evenement_id INT)
BEGIN
  DECLARE capacite INT;
  DECLARE inscrits INT;
  DECLARE evenement_date DATETIME;
  DECLARE chevauchement_found INT DEFAULT 0;

  -- Vérifiez les chevauchements d'événements pour le membre
  SELECT COUNT(*)
  INTO chevauchement_found
  FROM Inscription
  JOIN Evenement ON Inscription.evenementId = Evenement.id
  WHERE Inscription.membreId = membre_id
    AND Evenement.dateHeureDebut < (SELECT dateHeureFin FROM Evenement WHERE id = evenement_id)
    AND Evenement.dateHeureFin > (SELECT dateHeureDebut FROM Evenement WHERE id = evenement_id);

  IF chevauchement_found > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Le membre est déjà inscrit à un événement qui se chevauche avec le nouvel événement.';
  ELSE
    -- Vérifiez si l'événement est passé
    SELECT dateHeureDebut INTO evenement_date FROM Evenement WHERE id = evenement_id;
    IF evenement_date < NOW() THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Inscription impossible à un événement passé.';
    ELSE
      -- Obtenez la capacité d'accueil du lieu
      SELECT capaciteAccueil INTO capacite FROM Lieu WHERE id = (SELECT lieuId FROM Evenement WHERE id = evenement_id);

      -- Obtenez le nombre actuel d'inscrits à l'événement
      SELECT COUNT(*) INTO inscrits FROM Inscription WHERE evenementId = evenement_id;

      -- Vérifiez si l'événement a atteint la capacité maximale
      IF inscrits >= capacite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L’événement a atteint sa capacité maximale de participants.';
      ELSE
        -- Inscription du membre à l'événement
        INSERT INTO Inscription (membreId, evenementId) VALUES (membre_id, evenement_id);
      END IF;
    END IF;
  END IF;
END;

//
DELIMITER ;



-- Création de la procédure stockée pour récuérer l'âge d'un membre


-- utilisation:
-- CALL CalculerAge(1);

DELIMITER //

CREATE PROCEDURE CalculerAge(IN membreId INT)
BEGIN
    SELECT TIMESTAMPDIFF(YEAR, dateNaissance, CURDATE()) AS age
    FROM Membre
    WHERE id = membreId;
END;

//
DELIMITER ;








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


