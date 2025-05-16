DROP DATABASE IF EXISTS airbnb_db;
CREATE DATABASE airbnb_db;
USE airbnb_db;

-- Creamos la tabla hosts
CREATE TABLE hosts (
    host_id BIGINT PRIMARY KEY, -- BIGINT para almacenar números enteros de gran tamaño
    host_name VARCHAR(255) NULL, -- Puede ser NULL si falta
    calculated_host_listings_count INT NOT NULL
);

-- Creamos la tabla neighbourhoods
CREATE TABLE neighbourhoods (
    neighbourhood_id INT AUTO_INCREMENT PRIMARY KEY,
    neighbourhood_group VARCHAR(255) NULL, -- Permitimos NULL si faltase
    neighbourhood VARCHAR(255) NULL -- Permitimos NULL si faltase
);

-- Creamos la tabla listings
CREATE TABLE listings (
    listing_id BIGINT PRIMARY KEY,               
    name VARCHAR(255) NULL,          
    host_id BIGINT NOT NULL, -- No puede faltar (FK)
    neighbourhood_id INT NOT NULL, -- No puede faltar (FK)
    room_type VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL, -- Para almacenar un máximo de 10 números incluyendo los anteriores al punto y los posteriores. El 2 indica el número de dígitos que se almacenarán después del punto decimal
    minimum_nights INT NOT NULL,
    availability_365 INT NOT NULL,
    FOREIGN KEY (host_id) REFERENCES hosts(host_id),
    FOREIGN KEY (neighbourhood_id) REFERENCES neighbourhoods(neighbourhood_id)
);

-- Creamos la tabla reviews
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT NOT NULL, -- FK obligatoria
    number_of_reviews INT NOT NULL, -- Existe siempre, aunque sea 0
    last_review DATE NULL, -- Permitimos NULL para listings sin reviews
    reviews_per_month DECIMAL(4,2) NULL,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id)
);