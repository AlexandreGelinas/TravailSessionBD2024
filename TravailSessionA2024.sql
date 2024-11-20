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

-- Création des triggers /////////////////////////////////////////////////////////////

-- Triggers pour calculer l'âge avant insertion
CREATE TRIGGER BeforeInsertAdherent
BEFORE INSERT ON Adherents
FOR EACH ROW
SET NEW.Age = YEAR(CURDATE()) - YEAR(NEW.DateNaissance);

-- Triggers pour recalculer l'âge avant mise à jour
CREATE TRIGGER BeforeUpdateAdherent
BEFORE UPDATE ON Adherents
FOR EACH ROW
SET NEW.Age = YEAR(CURDATE()) - YEAR(NEW.DateNaissance);
