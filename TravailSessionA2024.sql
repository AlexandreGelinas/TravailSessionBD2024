-- Alexandre Gélinas et David Paré
-- Travail de session - dù pour le 11 Décembre 2024

-- Création des tables ////////////////////////////////////////////////////////////////

-- Table Adherents
CREATE TABLE Adherents (
    ID VARCHAR(20) PRIMARY KEY,
    Nom VARCHAR(100) NOT NULL,
    Prenom VARCHAR(100) NOT NULL,
    Adresse TEXT NOT NULL,
    DateNaissance DATE NOT NULL,
    Age INT NOT NULL, 
    CONSTRAINT Verif_Age CHECK (Age >= 18)
);
-- Table Activites
CREATE TABLE Activites (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nom VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NOT NULL,
    CoutOrganisation DECIMAL(10, 2) NOT NULL,
    PrixVenteParClient DECIMAL(10, 2) NOT NULL
);

-- Table Seances
CREATE TABLE Seances (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    idActivite INT NOT NULL,
    DateHeure DATETIME NOT NULL,
    NombrePlaces INT NOT NULL,
    FOREIGN KEY (idActivite) REFERENCES Activites(ID)
);

-- Table Participations
CREATE TABLE Participations (
    idAdherent VARCHAR(20) NOT NULL,
    idSeance INT NOT NULL,
    Note DECIMAL(3, 2),
    PRIMARY KEY (idAdherent, idSeance),
    FOREIGN KEY (idAdherent) REFERENCES Adherents(ID),
    FOREIGN KEY (idSeance) REFERENCES Seances(ID)
);

-- Table Administrateurs
CREATE TABLE Administrateurs (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    MotDePasse VARCHAR(255) NOT NULL
);

-- Table d'évaluation

CREATE TABLE EvaluationsActivites (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    idAdherent VARCHAR(20) NOT NULL,
    idActivite INT NOT NULL,
    Note DECIMAL(3, 2) NOT NULL CHECK (Note >= 0 AND Note <= 10),
    Commentaire TEXT,
    FOREIGN KEY (idAdherent) REFERENCES Adherents(ID),
    FOREIGN KEY (idActivite) REFERENCES Activites(ID)
);

-- Création des triggers /////////////////////////////////////////////////////////////

-- Triggers pour calculer l'âge avant insertion
CREATE TRIGGER BeforeInsertAdherent
BEFORE INSERT ON Adherents
FOR EACH ROW
SET NEW.Age = YEAR(CURDATE()) - YEAR(NEW.DateNaissance);

-- Trigger pour construire le numéro d'identification de l'adhérent (AG-1995-150)

DELIMITER //

CREATE TRIGGER Generer_ID_Adherent
BEFORE INSERT ON Adherents
FOR EACH ROW
BEGIN
    DECLARE initiales VARCHAR(3);
    DECLARE anneeNaissance CHAR(4);
    DECLARE randomNum CHAR(3);

    -- Première partie(AG)
    SET initiales = CONCAT(LEFT(NEW.Prenom, 1), LEFT(NEW.Nom, 1));

    -- Deuxième partie(1995)
    SET anneeNaissance = YEAR(NEW.DateNaissance);

    -- Troisième partie(150)
    SET randomNum = LPAD(FLOOR(1 + (RAND() * 999)), 3, '0');

    -- Produit final
    SET NEW.ID = CONCAT(initiales, '-', anneeNaissance, '-', randomNum);
END;
//

DELIMITER ;

-- Trigger pour gérer le nombre de place dispo dans chaque séance

DELIMITER //

CREATE TRIGGER MiseAJour_Places_ApresInsertion
AFTER INSERT ON Participations
FOR EACH ROW
BEGIN
    UPDATE Seances
    SET NombrePlaces = NombrePlaces - 1
    WHERE ID = NEW.idSeance;
END;
//

DELIMITER ;

-- Trigger qui permet d'insérer des participants dans une séance si le nb max n'est pas atteint.
-- Sinon, message d'erreur pour dire qu'il n'y a plus de places.

DELIMITER //

CREATE TRIGGER Verifier_Places_Disponibles
BEFORE INSERT ON Participations
FOR EACH ROW
BEGIN
    DECLARE placesRestantes INT;

    -- Places restantes
    SELECT NombrePlaces
    INTO placesRestantes
    FROM Seances
    WHERE ID = NEW.idSeance;

    -- Vérifier si des places sont disponibles
    IF placesRestantes <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Il ne reste plus de places disponibles pour cette séance.';
    END IF;
END;
//

DELIMITER ;
