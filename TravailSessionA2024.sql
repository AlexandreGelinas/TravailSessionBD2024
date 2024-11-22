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

-- Insertion des données ///////////////////////////////////////////////////////////////////////////////

-- Insertion Adherents

INSERT INTO Adherents (ID, Nom, Prenom, Adresse, DateNaissance, Age)
VALUES 
('AL-1995-123', 'Lemoine', 'Alice', '123 Rue de Paris, Paris', '1995-06-15', 28),
('JB-1990-456', 'Benoit', 'Jean', '456 Avenue de Lyon, Lyon', '1990-11-10', 33),
('ML-1985-789', 'Lopez', 'Marie', '789 Boulevard de Lille, Lille', '1985-04-22', 38),
('DC-1998-321', 'Carter', 'David', '321 Allée des Pins, Toulouse', '1998-09-15', 25),
('EG-1992-654', 'Garcia', 'Emma', '654 Place des Érables, Marseille', '1992-03-12', 31),
('PM-1987-987', 'Martin', 'Paul', '987 Chemin des Roses, Nice', '1987-01-05', 36),
('TS-1999-246', 'Simon', 'Thomas', '246 Rue de la Forêt, Bordeaux', '1999-08-07', 24),
('CR-1991-369', 'Roux', 'Camille', '369 Rue des Vignes, Nantes', '1991-12-19', 32),
('BN-1988-159', 'Nicolas', 'Benjamin', '159 Avenue des Champs, Strasbourg', '1988-02-27', 35),
('LE-1996-753', 'Eloise', 'Lucie', '753 Rue des Lilas, Grenoble', '1996-05-30', 27);

-- Insertion Activites

INSERT INTO Activites (Nom, Type, CoutOrganisation, PrixVenteParClient)
VALUES 
('Yoga', 'Sport', 200.00, 15.00),
('Zumba', 'Sport', 250.00, 20.00),
('Peinture', 'Art', 150.00, 25.00),
('Cuisine', 'Loisirs', 300.00, 30.00),
('Théâtre', 'Art', 400.00, 50.00),
('Escalade', 'Sport', 500.00, 40.00),
('Photographie', 'Art', 250.00, 35.00),
('Randonnée', 'Nature', 100.00, 10.00),
('Jardinage', 'Nature', 150.00, 15.00),
('Informatique', 'Technologie', 350.00, 40.00);

-- Insertion Seances

INSERT INTO Seances (idActivite, DateHeure, NombrePlaces)
VALUES 
(1, '2024-01-10 10:00:00', 20),
(2, '2024-01-15 18:00:00', 25),
(3, '2024-02-01 14:00:00', 15),
(4, '2024-02-05 11:00:00', 10),
(5, '2024-02-10 19:00:00', 30),
(6, '2024-03-12 09:00:00', 12),
(7, '2024-03-20 16:00:00', 20),
(8, '2024-04-05 08:00:00', 25),
(9, '2024-04-10 10:30:00', 15),
(10, '2024-05-01 15:00:00', 18);

-- Insertion Participation 

INSERT INTO Participations (idAdherent, idSeance, Note)
VALUES 
('AL-1995-123', 1, 8.5),
('JB-1990-456', 2, 9.0),
('ML-1985-789', 3, 7.5),
('DC-1998-321', 4, 8.0),
('EG-1992-654', 5, 9.5),
('PM-1987-987', 6, NULL),
('TS-1999-246', 7, 8.0),
('CR-1991-369', 8, 7.0),
('BN-1988-159', 9, 6.5),
('LE-1996-753', 10, 8.0);

-- Insertion EvaluationActivites

INSERT INTO Evaluations (idAdherent, idActivite, Note, Commentaire)
VALUES 
('AL-1995-123', 1, 8.0, 'Très relaxant et bien organisé.'),
('JB-1990-456', 2, 9.0, 'Excellente ambiance, très dynamique !'),
('ML-1985-789', 3, 7.5, 'Bonne activité, mais manque un peu de matériel.'),
('DC-1998-321', 4, 8.5, 'Atelier intéressant et formateur.'),
('EG-1992-654', 5, 9.5, 'Magnifique prestation, rien à redire.'),
('PM-1987-987', 6, 8.0, 'Très bien encadré, bonne expérience.'),
('TS-1999-246', 7, 7.5, 'Correct, mais pourrait être amélioré.'),
('CR-1991-369', 8, 7.0, 'Bonne activité de plein air.'),
('BN-1988-159', 9, 6.5, 'Sympathique mais un peu répétitif.'),
('LE-1996-753', 10, 8.0, 'Atelier très enrichissant.');

-- Insertion Administrateur

INSERT INTO Administrateurs (ID, MotDePasse)
VALUES
(101,'Secret1234'),
(102,'Secret5678');
