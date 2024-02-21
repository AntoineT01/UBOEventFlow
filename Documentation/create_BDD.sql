-------------------------------------------------------------------------
---           Création de la base de données et des tables            ---
-------------------------------------------------------------------------

-- Création de la base de données
CREATE
DATABASE IF NOT EXISTS `UBOEventFlow_bdd` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

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
    FOREIGN KEY (lieuId) REFERENCES Lieu (id),
);

-- Création de la table Commentaire
CREATE TABLE Commentaire
(
    id               INT PRIMARY KEY AUTO_INCREMENT,
    texteCommentaire TEXT NOT NULL,
    date             DATE NOT NULL,
    evenementId      INT  NOT NULL,
    membreId         INT  NOT NULL,
    FOREIGN KEY (evenementId) REFERENCES Evenement (id),
    FOREIGN KEY (membreId) REFERENCES Membre (id)
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

-------------------------------------------------------------------------
---           Création des procédures stockées et des triggers        ---
-------------------------------------------------------------------------

-- Création de trigger pour vérifier le chevauchement des événements

DELIMITER
//

CREATE TRIGGER BeforeInsertEvent
    BEFORE INSERT
    ON Evenement
    FOR EACH ROW
BEGIN
    DECLARE clash_found INT DEFAULT 0;

  -- Vérifiez si un autre événement a lieu dans le même lieu et s'il y a un chevauchement de temps
    SELECT COUNT(*)
    INTO clash_found
    FROM Evenement
    WHERE NEW.lieuId = lieuId
      AND NOT (NEW.dateHeureFin <= dateHeureDebut OR NEW.dateHeureDebut >= dateHeureFin);

    IF clash_found > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Un autre événement se déroule déjà dans le même lieu à la même heure.';
END IF;
END;

DELIMITER ;



-- Création de trigger pour vérifier le nombre de participants

DELIMITER
//

CREATE TRIGGER BeforeInsertInscription
    BEFORE INSERT
    ON Inscription
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
IF
inscrits >= capacite THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'L’événement a atteint sa capacité maximale de participants.';
END IF;
END;

DELIMITER ;

-- Création de trigger pour vérifier la modification valide de l'événement
DELIMITER //

CREATE TRIGGER BeforeUpdateEvent
    BEFORE UPDATE ON Evenement
    FOR EACH ROW
BEGIN
    DECLARE clash_found INT DEFAULT 0;

    SELECT COUNT(*) INTO clash_found
    FROM Evenement
    WHERE NEW.lieuId = lieuId
      AND id <> OLD.id
      AND NOT (NEW.dateHeureFin <= dateHeureDebut OR NEW.dateHeureDebut >= dateHeureFin);

    IF clash_found > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La mise à jour de l’événement entraînerait un chevauchement dans le même lieu.';
END IF;
END;

DELIMITER ;




-- Création de la procédure stockée pour s'incrire à un événement

--utilisation:
-- CALL InscrireMembre(1, 1);
DELIMITER
//

CREATE PROCEDURE InscrireMembre(IN membre_id INT, IN evenement_id INT)
BEGIN
  DECLARE
capacite INT;
  DECLARE
inscrits INT;
  DECLARE
evenement_date DATETIME;
  DECLARE
chevauchement_found INT DEFAULT 0;

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
    SELECT dateHeureDebut
    INTO evenement_date
    FROM Evenement
    WHERE id = evenement_id;
    IF evenement_date < NOW() THEN
          SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Inscription impossible à un événement passé.';
    ELSE
              -- Obtenez la capacité d'accueil du lieu
        SELECT capaciteAccueil
        INTO capacite
        FROM Lieu
        WHERE id = (SELECT lieuId FROM Evenement WHERE id = evenement_id);

        -- Obtenez le nombre actuel d'inscrits à l'événement
        SELECT COUNT(*)
        INTO inscrits
        FROM Inscription
        WHERE evenementId = evenement_id;

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

DELIMITER ;











