/* Monthly ETL script - runs every month (via a Python script) loading a new
   month's CSV into the star schema created by Database_setup.sql.
   A 'staging_table' holds the monthly raw data and is fully dropped and recreated on each run,
   which is why the cleaning steps below execute every time. */

-- Dropped 'Crime ID' column as it is not needed for this analysis.
ALTER TABLE staging_table
DROP COLUMN "Crime ID";

-- Dropped 'Reported by' column as it is a duplicate of the 'Falls Within' column, verified 0 mismatches before dropping.
ALTER TABLE staging_table
DROP COLUMN "Reported by";

-- Converted 'Month' column from text ('YYYY-MM') to date type, by completing the text and specifying the date format.
ALTER TABLE staging_table
ALTER COLUMN "Month" TYPE DATE
USING to_date("Month" || '-01', 'YYYY-MM-DD');

-- Replaced null outcomes with 'No outcome recorded'.
UPDATE staging_table
SET "Last outcome category" = 'No outcome recorded'
WHERE "Last outcome category" IS NULL;

-- Populated each dimension table with distinct, non-null values.
-- Duplicate values are skipped using ON CONFLICT DO NOTHING.
INSERT INTO dim_date (date)
SELECT
    DISTINCT "Month"
FROM staging_table
WHERE
    "Month" IS NOT NULL
ON CONFLICT (date) DO NOTHING;

INSERT INTO dim_crime_type (crime_type_name)
SELECT
    DISTINCT "Crime type"
FROM staging_table
WHERE
    "Crime type" IS NOT NULL
ON CONFLICT (crime_type_name) DO NOTHING;

INSERT INTO dim_outcome (outcome_category)
SELECT
    DISTINCT "Last outcome category"
FROM staging_table
WHERE
    "Last outcome category" IS NOT NULL
ON CONFLICT (outcome_category) DO NOTHING;

INSERT INTO dim_police_force (force_name)
SELECT
    DISTINCT "Falls within"
FROM staging_table
WHERE
    "Falls within" IS NOT NULL
ON CONFLICT (force_name) DO NOTHING;

INSERT INTO dim_location (lsoa_code, lsoa_name, street_name, longitude, latitude)
SELECT
    DISTINCT "LSOA code",
             "LSOA name",
             "Location",
             "Longitude",
             "Latitude"
FROM staging_table
WHERE
    "LSOA code" IS NOT NULL
ON CONFLICT (lsoa_code, lsoa_name, street_name, longitude, latitude) DO NOTHING;

/* Populated the fact table, using left joins to ensure no records are lost.
   Standard left joins were used instead of null-safe IS NOT DISTINCT FROM,
   since the latter damages query performance by forcing a slow nested loop.
   Standard joins remain safe because every joined dimension column has a NOT NULL constraint. */
INSERT INTO fact_crimes (date_id, force_id, location_id, crime_type_id, outcome_id)
SELECT
    d.date_id,
    f.force_id,
    l.location_id,
    c.crime_type_id,
    o.outcome_id
FROM staging_table r
LEFT JOIN dim_date d
    ON r."Month" = d.date
LEFT JOIN dim_police_force f
    ON r."Falls within" = f.force_name
LEFT JOIN dim_location l
    ON r."LSOA code" = l.lsoa_code
    AND r."LSOA name" = l.lsoa_name
    AND r."Location" = l.street_name
    AND r."Longitude" = l.longitude
    AND r."Latitude" = l.latitude
LEFT JOIN dim_crime_type c
    ON r."Crime type" = c.crime_type_name
LEFT JOIN dim_outcome o
    ON r."Last outcome category" = o.outcome_category;

-- Indexed the fact table for enhanced query performance.
-- One index per foreign key so PostgreSQL can use any combination of filters.
CREATE INDEX idx_fact_crimes_date_id ON fact_crimes(date_id);
CREATE INDEX idx_fact_crimes_force_id ON fact_crimes(force_id);
CREATE INDEX idx_fact_crimes_location_id ON fact_crimes(location_id);
CREATE INDEX idx_fact_crimes_crime_type_id ON fact_crimes(crime_type_id);
CREATE INDEX idx_fact_crimes_outcome_id ON fact_crimes(outcome_id);
