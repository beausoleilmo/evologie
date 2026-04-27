# Go to the place you want to work with 
cd ~/Desktop/
# Start duckdb 
duckdb

--- when you exit, the tables you create will be available there
.open test_db.ddb

.timer on
INSTALL httpfs;
LOAD httpfs;
LOAD spatial;
CREATE VIEW atlas AS SELECT * FROM read_parquet('https://object-arbutus.cloud.computecanada.ca/bq-io/atlas/parquet/atlas_public_2025-03-17.parquet');
from atlas limit 5;
DESCRIBE from atlas;
SHOW TABLE atlas;

SELECT group_fr, COUNT(*) AS compte_groupe 
FROM atlas 
WHERE dataset_name = 'iNaturalist Research-grade Observations' 
GROUP BY group_fr  
ORDER BY compte_groupe DESC;

CREATE TABLE c_inat AS SELECT group_fr, COUNT(*) AS compte_groupe 
FROM atlas 
WHERE dataset_name = 'iNaturalist Research-grade Observations' 
GROUP BY group_fr  
ORDER BY compte_groupe DESC;

select *
from c_inat
where compte_groupe > 5e3;


SELECT distinct dataset_name
from atlas;

SELECT distinct observed_rank
from atlas;
SELECT distinct license
from atlas;

SELECT license, COUNT(*) FROM atlas WHERE license ILIKE '%cc0%' group by license;

# FAIRE UN FILTRE ET COMPTER 
SELECT COUNT(*) FROM atlas WHERE license ILIKE '%cc0%' AND dataset_name = 'Herbier du Québec (QUE) - Collection de plantes vasculaires';
# SELECT valid_scientific_name, longitude, latitude, license, dataset_name FROM atlas WHERE license ILIKE '%cc0%' AND dataset_name = 'Herbier du Québec (QUE) - Collection de plantes vasculaires';

--- save to current directory 
COPY c_inat TO 'output.csv' (HEADER, DELIMITER ',');


# observed_rank = 'species' AND
COPY (SELECT dataset_name, license, COUNT(*) FROM atlas WHERE license ILIKE '%cc0%' group by license, dataset_name) TO 'query_output.csv' (HEADER, DELIMITER ',');
COPY (SELECT valid_scientific_name, longitude, latitude, license, dataset_name FROM atlas WHERE license ILIKE '%cc0%' AND dataset_name = 'Herbier du Québec (QUE) - Collection de plantes vasculaires') TO 'query_output_herbqc.csv' (HEADER, DELIMITER ',');


#### 
# Read data in 
# https://duckdb.org/docs/stable/data/overview.html
# Go to the place you want to work with 
cd ~/Desktop/
# Start duckdb 
duckdb

--- when you exit, the tables you create will be available there
.open gbif_db.ddb

.mode duckbox
.timer on
.maxrows 1234
INSTALL httpfs;
INSTALL spatial;
LOAD httpfs;
LOAD spatial;
CREATE VIEW gbifdb AS SELECT * FROM read_parquet("s3://gbif-open-data-us-east-1/occurrence/2025-06-01/occurrence.parquet/*");
# DROP VIEW gbifdb;
from gbifdb limit 5;
DESCRIBE from gbifdb;
SHOW TABLE gbifdb;

SELECT count(*) AS iNat_obs_CA
FROM gbifdb 
WHERE countrycode = 'CA' AND publishingorgkey = '28eb1a3f-1c15-4a95-931a-4af90ecb574d';
# 100% ▕████████████████████████████████████████████████████████████▏ 
# ┌────────────────┐
# │  iNat_obs_CA   │
# │     int64      │
# ├────────────────┤
# │    9228525     │
# │ (9.23 million) │
# └────────────────┘

SELECT basisofrecord, COUNT(basisofrecord) FROM gbifdb group by basisofrecord;
# 100% ▕████████████████████████████████████████████████████████████▏ 
# ┌─────────────────────┬──────────────────────┐
# │    basisofrecord    │ count(basisofrecord) │
# │       varchar       │        int64         │
# ├─────────────────────┼──────────────────────┤
# │ MATERIAL_SAMPLE     │             71544479 │
# │ OBSERVATION         │             16764336 │
# │ FOSSIL_SPECIMEN     │              9754499 │
# │ MATERIAL_CITATION   │              8305482 │
# │ HUMAN_OBSERVATION   │           2753954846 │
# │ MACHINE_OBSERVATION │             25108555 │
# │ PRESERVED_SPECIMEN  │            263734877 │
# │ OCCURRENCE          │             20480442 │
# │ LIVING_SPECIMEN     │              3385481 │
# └─────────────────────┴──────────────────────┘
# Run Time (s): real 310.606 user 70.687111 sys 16.065501
# Second time : 
# Run Time (s): real 3.822 user 18.783915 sys 0.101791


SELECT kingdom, COUNT(kingdom) FROM gbifdb group by kingdom;
# 100% ▕████████████████████████████████████████████████████████████▏ 
# ┌────────────────┬────────────────┐
# │    kingdom     │ count(kingdom) │
# │    varchar     │     int64      │
# ├────────────────┼────────────────┤
# │ Bacteria       │       25198707 │
# │ Fungi          │       45870703 │
# │ Plantae        │      542486126 │
# │ incertae sedis │        9193909 │
# │ Archaea        │         422798 │
# │ Viruses        │         916082 │
# │ Protozoa       │        1688692 │
# │ Animalia       │     2528920710 │
# │ Chromista      │       18335270 │
# └────────────────┴────────────────┘
# Run Time (s): real 286.079 user 69.037853 sys 16.954443

# Get observation from iNaturalist that are relatively recent within the bbox of Québec. 
CREATE VIEW gbifca AS 
SELECT *
FROM gbifdb 
WHERE countrycode = 'CA' AND 
publishingorgkey = '28eb1a3f-1c15-4a95-931a-4af90ecb574d' AND 
license IN ('CC_BY_4_0', 'CC0_1_0') AND
basisofrecord = 'HUMAN_OBSERVATION' AND
kingdom = 'Animalia' AND
year >= 2020 limit 5;

# decimallongitude >= -79.76288 AND 
# decimallongitude <= -57.10750 AND 
# decimallatitude >= 44.99136 AND 
# decimallatitude >= 62.58054
# limit 5;

from gbifqc;
# Run Time (s): real 311.485 user 74.042262 sys 56.061376

COPY gbifqc TO '~/Desktop/gbif_CA_inat_lic_open_BY_animalia_2020plus_bboxQC.parquet' (FORMAT parquet);

# Copy query to a parquet file (will take a long time to run at first )
# Run Time (s): real 3999.779 user 118.840015 sys 123.335757
COPY (SELECT *
FROM gbifdb 
WHERE countrycode = 'CA' AND 
publishingorgkey = '28eb1a3f-1c15-4a95-931a-4af90ecb574d' AND 
license IN ('CC_BY_4_0', 'CC0_1_0') AND
basisofrecord = 'HUMAN_OBSERVATION' AND
kingdom = 'Animalia' AND
year >= 2020) TO '~/Desktop/gbif_CA_inat_lic_open_BY_animalia_2020plus_bboxQC.parquet' (FORMAT parquet);

# 4323.542 secondes!!!
COPY (SELECT *
FROM gbifdb 
WHERE countrycode = 'CA' AND 
publishingorgkey = '28eb1a3f-1c15-4a95-931a-4af90ecb574d' AND 
license IN ('CC_BY_4_0', 'CC0_1_0') AND
basisofrecord = 'HUMAN_OBSERVATION' AND
kingdom = 'Animalia' AND
year >= 2020) TO '~/Desktop/gbif_CA_inat_lic_open_BY_animalia_2020plus_bboxQC.csv' (HEADER, DELIMITER ',');


SELECT license, COUNT(license) FROM gbifdb group by license;


SELECT COUNT(dataset_name) AS compte_groupe 
FROM gbifdb 
WHERE dataset_name = 'iNaturalist Research-grade Observations' 
ORDER BY compte_groupe DESC;
