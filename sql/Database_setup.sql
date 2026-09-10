/* Database setup - used once to create the star schema (fact and dimension tables),
   which is populated monthly using Monthly_ETL_script.sql (run via a Python script).
   Dimension tables are created first because fact table foreign keys reference dimension table primary keys. */

-- Created 5 dimension tables - date, crime_type, outcome, police_force and location.
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    date date UNIQUE NOT NULL
);

CREATE TABLE dim_crime_type (
    crime_type_id SERIAL PRIMARY KEY,
    crime_type_name varchar(100) UNIQUE NOT NULL
);

CREATE TABLE dim_outcome (
    outcome_id SERIAL PRIMARY KEY,
    outcome_category varchar(200) UNIQUE NOT NULL
);

CREATE TABLE dim_police_force (
    force_id SERIAL PRIMARY KEY,
    force_name varchar(200) UNIQUE NOT NULL
);

CREATE TABLE dim_location (
    location_id SERIAL PRIMARY KEY,
    lsoa_code varchar(100) NOT NULL,
    lsoa_name varchar(200) NOT NULL,
    street_name varchar(200) NOT NULL,
    longitude float NOT NULL,
    latitude float NOT NULL,
    UNIQUE (lsoa_code, lsoa_name, street_name, longitude, latitude)
);

-- Created a fact table with relationships to every dimension table.
CREATE TABLE fact_crimes (
    crime_id SERIAL PRIMARY KEY,
    date_id INT REFERENCES dim_date(date_id),
    force_id INT REFERENCES dim_police_force(force_id),
    location_id INT REFERENCES dim_location(location_id),
    crime_type_id INT REFERENCES dim_crime_type(crime_type_id),
    outcome_id INT REFERENCES dim_outcome(outcome_id)
);
