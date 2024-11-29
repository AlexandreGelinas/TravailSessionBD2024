-- Alexandre Gélinas et David Paré
-- Travail de session - dù pour le 11 Décembre 2024

-- Création des tables ////////////////////////////////////////////////////////////////

-- Table Adherents
CREATE TABLE Adherents (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nom VARCHAR(100) NOT NULL,
    Prenom VARCHAR(100) NOT NULL,
    Adresse TEXT NOT NULL,
    DateNaissance DATE NOT NULL,
    Age INT NOT NULL, 
    CONSTRAINT Verif_Age CHECK (Age >= 18),
    MotDePasse VARCHAR(255) NOT NULL,
    CodeAdherent VARCHAR(255) -- Crée par un trigger
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
    idAdherent INT NOT NULL,
    idSeance INT NOT NULL,
    Note DECIMAL(3, 2),
    PRIMARY KEY (idAdherent, idSeance),
    FOREIGN KEY (idAdherent) REFERENCES Adherents(ID),
    FOREIGN KEY (idSeance) REFERENCES Seances(ID)
);

-- Table Administrateurs
CREATE TABLE Administrateurs (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Prenom VARCHAR(100) NOT NULL,
    Nom VARCHAR(100) NOT NULL,
    MotDePasse VARCHAR(255) NOT NULL
);

-- Table d'évaluation

CREATE TABLE Evaluations (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    idAdherent INT NOT NULL,
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

CREATE DEFINER = `1372735`@`%` TRIGGER Generer_ID_Adherent
BEFORE INSERT
ON Adherents
FOR EACH ROW
BEGIN
    DECLARE initiales VARCHAR(3);
    DECLARE anneeNaissance CHAR(4);
    DECLARE randomNum CHAR(3);

    -- Vérification des données obligatoires (GESTION D'ERREURS)
    IF NEW.Prenom IS NULL OR NEW.Nom IS NULL THEN
        SIGNAL SQLSTATE '45001'
        SET MESSAGE_TEXT = 'Le prénom ou le nom ne peut pas être NULL.';
    END IF;

    IF NEW.DateNaissance IS NULL THEN
        SIGNAL SQLSTATE '45002'
        SET MESSAGE_TEXT = 'La date de naissance ne peut pas être NULL.';
    END IF;

    -- Vérification que la date de naissance est dans le passé
    IF NEW.DateNaissance >= CURDATE() THEN
        SIGNAL SQLSTATE '45003'
        SET MESSAGE_TEXT = 'La date de naissance doit être une date passée.';
    END IF;

    -- Première partie (initiales AG)
    SET initiales = CONCAT(LEFT(NEW.Prenom, 1), LEFT(NEW.Nom, 1));

    -- Deuxième partie (année de naissance 1995)
    SET anneeNaissance = YEAR(NEW.DateNaissance);

    -- Troisième partie (nombre aléatoire 150)
    SET randomNum = LPAD(FLOOR(1 + (RAND() * 999)), 3, '0');

    -- Produit final
    SET NEW.CodeAdherent = CONCAT(initiales, '-', anneeNaissance, '-', randomNum);
END;


-- Trigger pour gérer le nombre de place dispo dans chaque séance (GESTION D'ERREURS)

DELIMITER //

CREATE TRIGGER MiseAJour_Places_ApresInsertion
AFTER INSERT ON Participations
FOR EACH ROW
BEGIN
    DECLARE nbPlacesRestantes INT;

    -- Vérification que la séance existe
    SELECT NombrePlaces INTO nbPlacesRestantes
    FROM Seances
    WHERE ID = NEW.idSeance;

    IF nbPlacesRestantes IS NULL THEN
        SIGNAL SQLSTATE '22001' -- Erreur de données 
        SET MESSAGE_TEXT = 'Erreur : La séance associée à cette participation existe pas.';
    END IF;

    -- Vérification de places dispo
    IF nbPlacesRestantes <= 0 THEN
        SIGNAL SQLSTATE '22002' -- Erreur de données 
        SET MESSAGE_TEXT = 'Erreur : Il n\'y a plus de places disponibles pour cette séance.';
    END IF;

    -- Vérification de l'intégrité des données : ID de séance valide
    IF NEW.idSeance <= 0 THEN
        SIGNAL SQLSTATE '22003' -- Erreur de données
        SET MESSAGE_TEXT = 'Erreur : ID de la séance est invalide.';
    END IF;

    -- Mise à jour du nombre de places restantes
    UPDATE Seances
    SET NombrePlaces = NombrePlaces - 1
    WHERE ID = NEW.idSeance;
END;
//

DELIMITER ;


-- Trigger qui permet d'insérer des participants dans une séance si le nb max n'est pas atteint.
-- Sinon, message d'erreur pour dire qu'il n'y a plus de places. ( Gestion d'erreur)

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

INSERT INTO Adherents (Nom, Prenom, Adresse, DateNaissance, Age, MotDePasse, CodeAdherent) -- Le codeAdherent va etre modifier avec le trigger donc entrer n'importe quoi
VALUES
('Lemoine', 'Alice', '123 Rue de Paris, Paris', '1995-06-15', 28, 'Pomme123', 'AL'),
('Benoit', 'Jean', '456 Avenue de Lyon, Lyon', '1990-11-10', 33, 'Orange123', 'BE'),
('Lopez', 'Marie', '789 Boulevard de Lille, Lille', '1985-04-22', 38, 'Courge123', 'LO'),
('Carter', 'David', '321 Allée des Pins, Toulouse', '1998-09-15', 25, 'Aubergine123', 'CA'),
('Garcia', 'Emma', '654 Place des Érables, Marseille', '1992-03-12', 31, 'Citrouille123', 'GA'),
('Martin', 'Paul', '987 Chemin des Roses, Nice', '1987-01-05', 36, 'Raisin123', 'MA'),
('Simon', 'Thomas', '246 Rue de la Forêt, Bordeaux', '1999-08-07', 24, 'Concombre123', 'SI'),
('Roux', 'Camille', '369 Rue des Vignes, Nantes', '1991-12-19', 32, 'Zuccini123', 'R'),
('Nicolas', 'Benjamin', '159 Avenue des Champs, Strasbourg', '1988-02-27', 35, 'Poivron123', 'NI'),
('Eloise', 'Lucie', '753 Rue des Lilas, Grenoble', '1996-05-30', 27, 'Tomate123', 'EL');


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
(1, 1, 8.5),
(2, 2, 9.0),
(3, 3, 7.5),
(4, 4, 8.0),
(5, 5, 9.5),
(6, 6, NULL),
(7, 7, 8.0),
(8, 8, 7.0),
(9, 9, 6.5),
(10, 10, 8.0);

-- Insertion EvaluationActivites

INSERT INTO Evaluations (idAdherent, idActivite, Note, Commentaire)
VALUES 
(1, 1, 8.0, 'Très relaxant et bien organisé.'),
(2, 2, 9.0, 'Excellente ambiance, très dynamique !'),
(3, 3, 7.5, 'Bonne activité, mais manque un peu de matériel.'),
(4, 4, 8.5, 'Atelier intéressant et formateur.'),
(5, 5, 9.5, 'Magnifique prestation, rien à redire.'),
(6, 6, 8.0, 'Très bien encadré, bonne expérience.'),
(7, 7, 7.5, 'Correct, mais pourrait être amélioré.'),
(8, 8, 7.0, 'Bonne activité de plein air.'),
(9, 9, 6.5, 'Sympathique mais un peu répétitif.'),
(10, 10, 8.0, 'Atelier très enrichissant.');

-- Insertion Administrateur

INSERT INTO Administrateurs (ID, MotDePasse)
VALUES
(101,'Alexandre','Gélinas','Secret1234'),
(102,'David','Paré','Secret5678');

-- Création des vues ///////////////////////////////////////////////////////////////////////////////////

-- Trouver le participant ayant le nombre de séances le plus élevé

CREATE VIEW Participant_Max_Seances AS
SELECT P.idAdherent, CONCAT(A.Prenom, ' ', A.Nom) AS NomComplet, COUNT(P.idSeance) AS NombreSeances
FROM Participations P
JOIN Adherents A ON P.idAdherent = A.ID
GROUP BY P.idAdherent
ORDER BY NombreSeances DESC
LIMIT 1;

SELECT *
FROM participant_max_seances;

-- Trouver le prix moyen par activité pour chaque participant

CREATE VIEW Prix_Moyen_Par_Activite AS
SELECT 
    P.idAdherent,
    CONCAT(A.Prenom, ' ', A.Nom) AS NomComplet,
    S.idActivite,
    AVG(AC.PrixVenteParClient) AS PrixMoyen
FROM Participations P
JOIN Seances S ON P.idSeance = S.ID
JOIN Activites AC ON S.idActivite = AC.ID
JOIN Adherents A ON P.idAdherent = A.ID
GROUP BY P.idAdherent, S.idActivite;

SELECT *
FROM Prix_Moyen_Par_Activite;

-- Afficher les notes d'appréciation pour chaque activité

CREATE VIEW Notes_Par_Activite AS
SELECT 
    E.idActivite,
    AC.Nom AS Activite,
    E.idAdherent,
    CONCAT(A.Prenom, ' ', A.Nom) AS NomComplet,
    E.Note,
    E.Commentaire
FROM Evaluations E
JOIN Activites AC ON E.idActivite = AC.ID
JOIN Adherents A ON E.idAdherent = A.ID;

SELECT *
FROM Notes_Par_Activite;

-- Afficher la moyenne des notes d'appréciation pour toutes les activités

CREATE VIEW Moyenne_Notes_Activites AS
SELECT 
    AC.ID AS idActivite,
    AC.Nom AS Activite,
    AVG(E.Note) AS MoyenneNote
FROM Evaluations E
JOIN Activites AC ON E.idActivite = AC.ID
GROUP BY AC.ID, AC.Nom;

SELECT *
FROM Moyenne_Notes_Activites;


-- Afficher le nombre de participants pour chaque activité

CREATE VIEW Nombre_Participants_Par_Activite AS
SELECT 
    S.idActivite,
    AC.Nom AS Activite,
    COUNT(P.idAdherent) AS NombreParticipants
FROM Seances S
JOIN Participations P ON S.ID = P.idSeance
JOIN Activites AC ON S.idActivite = AC.ID
GROUP BY S.idActivite, AC.Nom;

SELECT *
FROM Nombre_Participants_Par_Activite;


-- Afficher le nombre de participant moyen pour chaque mois (À retravailler)

CREATE VIEW Moyenne_Participants_Par_Mois AS
SELECT
    YEAR(ParticipationParSeance.DateHeure) AS Annee,
    MONTH(ParticipationParSeance.DateHeure) AS Mois,
    AVG(ParticipationParSeance.NombreParticipants) AS MoyenneParticipants
FROM (
    SELECT
        S.ID AS idSeance,
        S.DateHeure,
        COUNT(P.idAdherent) AS NombreParticipants
    FROM Seances S
    LEFT JOIN Participations P ON S.ID = P.idSeance
    GROUP BY S.ID, S.DateHeure
) AS ParticipationParSeance
GROUP BY YEAR(ParticipationParSeance.DateHeure), MONTH(ParticipationParSeance.DateHeure);

SELECT *
FROM Moyenne_Participants_Par_Mois;


-- Procédures stockées /////////////////////////////////////////////////////////////////////////////////

-- Cette procédure ajoute un participant à une séance,
-- vérifie s’il reste des places et met à jour le nombre de places disponibles si l’ajout est réussi.

DELIMITER //

CREATE PROCEDURE AjouterParticipant(
    IN p_idAdherent INT,
    IN p_idSeance INT
)
BEGIN
    DECLARE placesRestantes INT;

    -- Vérifier le nombre de places restantes
    SELECT NombrePlaces
    INTO placesRestantes
    FROM Seances
    WHERE ID = p_idSeance;

    IF placesRestantes > 0 THEN
        -- Ajouter le participant
        INSERT INTO Participations (idAdherent, idSeance) 
        VALUES (p_idAdherent, p_idSeance);

        -- Réduire le nombre de places disponibles
        UPDATE Seances
        SET NombrePlaces = NombrePlaces - 1
        WHERE ID = p_idSeance;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Pas de places disponibles pour cette séance.';
    END IF;
END;
//

DELIMITER ;

CALL AjouterParticipant(1, 101);

-- Cette procédure calcule les revenus générés par une activité en fonction des séances associées.

DELIMITER //

CREATE PROCEDURE CalculerRevenusActivite(
    IN p_idActivite INT,
    OUT revenusTotaux DECIMAL(10, 2)
)
BEGIN
    SELECT SUM(S.NombrePlaces * A.PrixVenteParClient) AS Revenus
    INTO revenusTotaux
    FROM Seances S
    JOIN Activites A ON S.idActivite = A.ID
    WHERE A.ID = p_idActivite;
END;
//

DELIMITER ;

CALL CalculerRevenusActivite(10, @revenus);
SELECT @revenus AS RevenusTotaux;


-- Cette procédure permet à un adhérent d’ajouter une évaluation pour une activité qu’il a déjà suivie.

DELIMITER //

CREATE PROCEDURE AjouterEvaluation(
    IN p_idAdherent VARCHAR(20),
    IN p_idActivite INT,
    IN p_note DECIMAL(3, 2),
    IN p_commentaire TEXT
)
BEGIN
    DECLARE participationExist INT;

    -- Vérifier si l'adhérent a participé à au moins une séance de l'activité
    SELECT COUNT(*)
    INTO participationExist
    FROM Participations P
    INNER JOIN Seances S ON P.idSeance = S.ID
    WHERE P.idAdherent = p_idAdherent AND S.idActivite = p_idActivite;

    IF participationExist > 0 THEN
        -- Ajouter l'évaluation
        INSERT INTO Evaluations (idAdherent, idActivite, Note, Commentaire) 
        VALUES (p_idAdherent, p_idActivite, p_note, p_commentaire);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : L’adhérent ne peut évaluer une activité à laquelle il n’a pas participé.';
    END IF;
END;
//

DELIMITER ;

CALL AjouterEvaluation(1, 5, 4.5, 'Très bonne activité, bien encadrée!');


-- Cette procédure retourne toutes les séances d’une activité où des places sont encore disponibles.

DELIMITER //

CREATE PROCEDURE ListerSeancesDisponibles(
    IN p_idActivite INT
)
BEGIN
    SELECT S.ID AS idSeance, S.DateHeure, S.NombrePlaces
    FROM Seances S
    WHERE S.idActivite = p_idActivite AND S.NombrePlaces > 0
    ORDER BY S.DateHeure;
END;
//

DELIMITER ;

CALL ListerSeancesDisponibles(3);


-- Cette procédure supprime un adhérent, ainsi que toutes ses participations et évaluations. (GESTION D'ERREURS 2 différentes)

DELIMITER //

CREATE PROCEDURE SupprimerAdherent(
    IN p_idAdherent VARCHAR(20)
)
BEGIN
    DECLARE adherentExiste INT;
    DECLARE participationsExiste INT;
    DECLARE evaluationsExiste INT;

    -- Adhérent existe? 
    SELECT COUNT(*) INTO adherentExiste
    FROM Adherents
    WHERE ID = p_idAdherent;

    IF adherentExiste = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erreur : adhérent spécifié existe pas.';
    END IF;

    -- Vérifier si l'adhérent a encore des participations
    SELECT COUNT(*) INTO participationsExiste
    FROM Participations
    WHERE idAdherent = p_idAdherent;

    IF participationsExiste > 0 THEN
        SIGNAL SQLSTATE '2627' 
        SET MESSAGE_TEXT = 'Erreur : Impossible de supprimer adhérent car des participations existent encore.';
    END IF;

    -- Vérifier si l'adhérent a encore des évaluations
    SELECT COUNT(*) INTO evaluationsExiste
    FROM Evaluations
    WHERE idAdherent = p_idAdherent;

    IF evaluationsExiste > 0 THEN
        SIGNAL SQLSTATE '2627' 
        SET MESSAGE_TEXT = 'Erreur : Impossible de supprimer adhérent car des évaluations existent encore.';
    END IF;

    -- Supprimer les participations de l'adhérent
    DELETE FROM Participations
    WHERE idAdherent = p_idAdherent;

    -- Supprimer les évaluations de l'adhérent
    DELETE FROM Evaluations
    WHERE idAdherent = p_idAdherent;

    -- Supprimer l'adhérent
    DELETE FROM Adherents
    WHERE ID = p_idAdherent;
END;
//

DELIMITER ;


CALL SupprimerAdherent(1);


-- Fonction stockées ///////////////////////////////////////////////////////////////////////////////////

-- Cette fonction retourne le total de participants ayant assisté à une activité donnée.

DELIMITER //

CREATE FUNCTION NombreParticipantsActivite(p_idActivite INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE totalParticipants INT;

    SELECT COUNT(DISTINCT P.idAdherent) INTO totalParticipants
    FROM Participations P
    JOIN Seances S ON P.idSeance = S.ID
    WHERE S.idActivite = p_idActivite;

    RETURN totalParticipants;
END;
//

DELIMITER ;

SELECT NombreParticipantsActivite(1);

-- Cette fonction retourne la moyenne des notes données pour une activité spécifique.

DELIMITER //

CREATE FUNCTION MoyenneNotesActivite(p_idActivite INT)
RETURNS DECIMAL(3, 2)
DETERMINISTIC
BEGIN
    DECLARE moyenneNotes DECIMAL(3, 2);

    SELECT AVG(Note) INTO moyenneNotes
    FROM Evaluations
    WHERE idActivite = p_idActivite;

    RETURN IFNULL(moyenneNotes, 'Aucune évaluation');
END;
//

DELIMITER ;

SELECT MoyenneNotesActivite(2);

-- Cette fonction retourne un booléen (1 ou 0) (oui ou non) si un adhérent a participé à une activité.

DELIMITER //

CREATE FUNCTION AParticipeActivite(p_idAdherent INT, p_idActivite INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE participationExist INT;

    SELECT COUNT(*)
    INTO participationExist
    FROM Participations P
    INNER JOIN Seances S ON P.idSeance = S.ID
    WHERE P.idAdherent = p_idAdherent AND S.idActivite = p_idActivite;

    RETURN (participationExist > 0);
END;
//

DELIMITER ;

SELECT AParticipeActivite(1,3);

-- Cette fonction retourne le revenu total généré par une activité en additionnant les prix payés par les participants.

DELIMITER //

CREATE FUNCTION RevenuTotalActivite(p_idActivite INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE revenuTotal DECIMAL(10, 2);

    SELECT SUM(A.PrixVenteParClient * COUNT(DISTINCT P.idAdherent)) INTO revenuTotal
    FROM Seances S
    JOIN Activites A ON S.idActivite = A.ID
    LEFT JOIN Participations P ON S.ID = P.idSeance
    WHERE S.idActivite = p_idActivite;

    RETURN IFNULL(revenuTotal, 0.00);
END;
//

DELIMITER ;

SELECT  RevenuTotalActivite(4);

-- Cette fonction retourne la moyenne des participants par séance pour une activité donnée.

DELIMITER //

CREATE FUNCTION MoyenneParticipantsParSeance(p_idActivite INT)
RETURNS DECIMAL(5, 2)
DETERMINISTIC
BEGIN
    DECLARE moyenneParticipants DECIMAL(5, 2);

    SELECT AVG(NombreParticipants) INTO moyenneParticipants
    FROM (
        SELECT S.ID AS idSeance, COUNT(P.idAdherent) AS NombreParticipants
        FROM Seances S
        LEFT JOIN Participations P ON S.ID = P.idSeance
        WHERE S.idActivite = p_idActivite
        GROUP BY S.ID
    ) AS ParticipantsParSeance;

    RETURN IFNULL(moyenneParticipants, 0.00);
END;
//

DELIMITER ;

SELECT MoyenneParticipantsParSeance(5);


-- Gestion des erreurs /////////////////////////////////////////////////////////////////////////////////

-- Trois codes d'erreur differents identifié à coté des descriptions de fonctions/parametres/declencheurs ou vues. ( Gestion d'erreur)

