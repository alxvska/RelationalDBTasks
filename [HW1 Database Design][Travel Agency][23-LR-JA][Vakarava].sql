--  Rerunnable 

DROP TABLE IF EXISTS Guide_Excursion;
DROP TABLE IF EXISTS Logistics;
DROP TABLE IF EXISTS Excursion;
DROP TABLE IF EXISTS Hotel;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Tour;
DROP TABLE IF EXISTS Guide;
DROP TABLE IF EXISTS Agent;
DROP TABLE IF EXISTS Client;

-- Tables creation

CREATE TABLE Client (
    client_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    id_number VARCHAR(50) UNIQUE
);

CREATE TABLE Agent (
    agent_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    office VARCHAR(100)
);

CREATE TABLE Guide (
    guide_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    language VARCHAR(50) NOT NULL,
    experience_years INT CHECK (experience_years >= 0) DEFAULT 0
);

CREATE TABLE Tour (
    tour_id UUID PRIMARY KEY,
    destination VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL CHECK (base_price >= 0),
    CONSTRAINT check_dates CHECK (end_date >= start_date)
);

CREATE TABLE Booking (
    booking_id UUID PRIMARY KEY,
    client_id UUID NOT NULL,
    tour_id UUID NOT NULL,
    agent_id UUID,
    booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) NOT NULL,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'Pending',
    number_of_travelers INT NOT NULL CHECK (number_of_travelers >= 1)
);

CREATE TABLE Payment (
    payment_id UUID PRIMARY KEY,
    booking_id UUID UNIQUE NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    method VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0)
);

CREATE TABLE Hotel (
    hotel_id UUID PRIMARY KEY,
    tour_id UUID NOT NULL,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(150),
    room_type VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT check_hotel_dates CHECK (end_date >= start_date)
);

CREATE TABLE Excursion (
    excursion_id UUID PRIMARY KEY,
    tour_id UUID NOT NULL,
    location VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT check_excursion_dates CHECK (end_date >= start_date)
);

CREATE TABLE Logistics (
    logistics_id UUID PRIMARY KEY,
    tour_id UUID NOT NULL,
    mean_of_transport VARCHAR(50) NOT NULL,
    reservation_number VARCHAR(50) UNIQUE,
    departure VARCHAR(150) NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    arrival VARCHAR(150) NOT NULL,
    arrival_time TIMESTAMP WITH TIME ZONE NOT NULL
);

-- M:N 

CREATE TABLE Guide_Excursion (
    guide_excursion_id UUID PRIMARY KEY,
    guide_id UUID NOT NULL,
    excursion_id UUID NOT NULL,
    UNIQUE (guide_id, excursion_id)
);

--  (FK)

ALTER TABLE Booking
ADD CONSTRAINT fk_booking_client
    FOREIGN KEY (client_id)
    REFERENCES Client (client_id),
ADD CONSTRAINT fk_booking_tour
    FOREIGN KEY (tour_id)
    REFERENCES Tour (tour_id),
ADD CONSTRAINT fk_booking_agent
    FOREIGN KEY (agent_id)
    REFERENCES Agent (agent_id);

ALTER TABLE Payment
ADD CONSTRAINT fk_payment_booking
    FOREIGN KEY (booking_id)
    REFERENCES Booking (booking_id);

ALTER TABLE Hotel
ADD CONSTRAINT fk_hotel_tour
    FOREIGN KEY (tour_id)
    REFERENCES Tour (tour_id);

ALTER TABLE Excursion
ADD CONSTRAINT fk_excursion_tour
    FOREIGN KEY (tour_id)
    REFERENCES Tour (tour_id);

ALTER TABLE Logistics
ADD CONSTRAINT fk_logistics_tour
    FOREIGN KEY (tour_id)
    REFERENCES Tour (tour_id);

-- FK for M:N

ALTER TABLE Guide_Excursion
ADD CONSTRAINT fk_ge_guide
    FOREIGN KEY (guide_id)
    REFERENCES Guide (guide_id),
ADD CONSTRAINT fk_ge_excursion
    FOREIGN KEY (excursion_id)
    REFERENCES Excursion (excursion_id);