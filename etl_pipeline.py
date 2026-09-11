"""

Monthly ETL script - loads a new month's crime data CSV into the star schema.
Database_setup.sql needs to run once in the 'crime_data' database before this script.

Before running:
  - Install packages: pandas, sqlalchemy, psycopg2-binary
  - Replace 'your_file_path', 'yourpassword', and 'yourport' below with your own values.
  - Run this script from the repository root.

"""

import pandas as pd
from sqlalchemy import create_engine, text

file_path = r"your_file_path"
raw_crime_data = pd.read_csv(file_path)

engine = create_engine('postgresql+psycopg2://postgres:yourpassword@localhost:yourport/crime_data')

raw_crime_data.to_sql(
    name='staging_table',
    con=engine,
    if_exists='replace',
    index=False
)

sql_file_path = r"sql/Monthly_ETL_script.sql"

with open(sql_file_path) as file:
    sql_file = text(file.read())

with engine.begin() as connection:
    connection.execute(sql_file)

