## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## # 
## Biodiversty occurence GBIF processing
#
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# Date created : 2026-02-14
# Author: Marc-Olivier Beausoleil

##README####
#  --> Description : 
#  --> After downloading the data from GBIF, process it to run in R.
#  --> Data source : 
#  --> Data cite :  

# Go to correct location 
cd ~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data

# Open duckdb instance 
duckdb

-- Syntaxe duckdb (SQLish) à partir de maintenant 

-- Paramètres duckdb
.timer on 
.maxrows 50

-- Installation et charge librairies 
INSTALL spatial; 
LOAD spatial;

-- Grid 
-- https://duckdb.org/community_extensions/extensions/h3
INSTALL h3 FROM community;
LOAD h3;

-- Définir le sentier vers les données GBIF brutes
SET VARIABLE gb_path_raw = '/Volumes/g_magni/gbif_data/0047252-250827131500795.csv';
SET VARIABLE sp_nm_path_raw = '~/Github_proj/evologie/output/partie_2/esp_noms_gbif.csv';
-- Définir le sentier vers les données de région administrative 
SET VARIABLE admin_path = "~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/decoupages_administratifs_1_20000_format_SHP/mrc_s.shp";


-- Montre toutes les colonnes
-- SELECT UNNEST(Columns)  FROM sniff_csv(getvariable('gb_path_raw'));




-- Région administratives  ------------
  -- DESC: 
  --   Importation de Shapefile de la région administrative du Québec (polygone)
-- DATA SOURCE : 
  --    https://www.donneesquebec.ca/recherche/dataset/decoupages-administratifs/resource/b368d470-71d6-40a2-8457-e4419de2f9c0

------------------
  -- Transformation for good measure 
CREATE OR REPLACE VIEW admin_qc AS 
SELECT MRS_NM_MRC, MRS_NM_REG,  
ST_Transform(geom, 'EPSG:4269', 'EPSG:4326') AS geom
FROM ST_Read(getvariable('admin_path'));
  
  -------------------------------------
  -- GBIF data   ------------
  -- DESC: 
  --   Load gbif table and spatial (points) data 
-- Note : 
  --   VARCHAR : 'catalogNumber' was not interpreted correctly. needed to set VARCHAR. 
--   SPATIAL : Get geometry point for the occurence data ST_Point()...
--   CRS : spatial data is in 4326 
--   WHERE : remove missing species data 
CREATE OR REPLACE VIEW gb_data AS 
SELECT * ,
-- Add the H3 cell ID column at resolution X
h3_h3_to_string(h3_latlng_to_cell(decimalLatitude, decimalLongitude, 8)) AS h3_cell_id_8,
-- Make spatial 
ST_Point(decimalLongitude, decimalLatitude) AS geometry 
FROM read_csv(getvariable('gb_path_raw'), 
              sep = '\t',
              types={'catalogNumber': 'VARCHAR'}) 
WHERE 
species IS NOT NULL  
AND basisOfRecord IN ('HUMAN_OBSERVATION')
AND countryCode IN ('CA')
AND stateProvince IN ('Quebec', 'Québec', 'Qc') 
-- Garde Chromista, Protozoa, Fungi, Plantae, Animalia
AND kingdom NOT IN ('incertae sedis', 'Protozoa', 'Bacteria', 'Viruses');

select h3_cell_id_8 from gb_data limit 6;

select kingdom, 
count(kingdom) as n 
from gb_data 
group by ALL order by n ; 


CREATE OR REPLACE VIEW gb_data AS 
SELECT * ,
-- Make spatial 
ST_Point(decimalLongitude, decimalLatitude) AS geometry 
FROM read_csv(getvariable('gb_path_raw'), 
              sep = '\t',
              types={'catalogNumber': 'VARCHAR'});


CREATE OR REPLACE VIEW gout AS 
from gb_data 
where 
species IS NOT NULL  
AND basisOfRecord IN ('HUMAN_OBSERVATION')
AND countryCode IN ('CA')
AND stateProvince IN ('Quebec', 'Québec', 'Qc') 
AND kingdom NOT IN ('incertae sedis', 'Protozoa', 'Bacteria', 'Viruses')
AND coordinateUncertaintyInMeters <= 200 OR coordinateUncertaintyInMeters IS NULL
AND recordedBy ILIKE 'Marc-Olivier Beausoleil';

CREATE OR REPLACE VIEW gout AS 
from gb_data 
where 
species IS NOT NULL  
AND coordinateUncertaintyInMeters <= 200;

select coordinateUncertaintyInMeters, 
count(coordinateUncertaintyInMeters) as n 
from gout 
where 
coordinateUncertaintyInMeters IS NULL
group by ALL order by n ; 


---------------------------------------------------------------
  --- Compte nombre de données NULL dans chaque code des institutions
CREATE OR REPLACE VIEW ginst AS 
SELECT
institutionCode, 
collectionCode, 
kingdom,
-- species,
countryCode, 
stateProvince, 
basisOfRecord, 
datasetKey, 
-- geometry,
coordinateUncertaintyInMeters,
-- publishingOrgKey,
COUNT(*) FILTER (WHERE coordinateUncertaintyInMeters IS NULL) AS null_nb
FROM
gb_data 
WHERE 
species IS NOT NULL  
AND basisOfRecord IN ('HUMAN_OBSERVATION')
AND countryCode IN ('CA')
-- GROUP IF COUNT 
group by 
ALL
HAVING 
null_nb > 0
order by 
null_nb desc ;

------------------
  -- exportation données
select species, geometry from ginst limit 10 ;
copy ginst to 'count_null_coordinates.csv' (format csv);

CREATE OR REPLACE VIEW gck AS 
select 
* 
  exclude (
    countryCode, 
    basisOfRecord,
    --collectionCode
  ) 
from ginst limit 10 ;

from gck;

select species, count(species) as n from gout group by ALL order by n ; 
select species, basisOfRecord, countryCode,  stateProvince, coordinateUncertaintyInMeters from gout; 

copy gout to 'mb.parquet' (format parquet);

----------------------------------------
  -- Table de nom des espèces ------------
  CREATE OR REPLACE VIEW spnm AS 
SELECT * exclude (species)
FROM read_csv(getvariable('sp_nm_path_raw'));




------------------------------------------
  -- Jointure des tableaux 

CREATE OR REPLACE VIEW gbnm AS 
SELECT
t1.*,
t2.* EXCLUDE (scientificName)
FROM
gb_data AS t1
LEFT JOIN
spnm AS t2
ON
t1.scientificName = t2.scientificName;


---------------------------------------------
  -- exploration des données 

-- check if data is imported 
from admin_qc limit 10;

-- check data
from spnm limit 4;
select species, * from gbnm limit 10;   

-- Summary statistics 
SUMMARIZE gbnm;

-- Check the type of data in each column 
DESCRIBE gbnm;
SUMMARIZE gbnm;
from gbnm limit 10;

--institutionCode
-- CLO: Cornell Lab of Ornithology (CLO) 

-- datasetKey, 
-- kingdom,
-- phylum,
-- class,
-- "order",
-- family,
-- genus,
-- species,
-- infraspecificEpithet,
-- taxonRank,
-- scientificName,
-- verbatimScientificName,
-- verbatimScientificNameAuthorship,
-- countryCode,
-- locality,
-- stateProvince,
-- occurrenceStatus,
-- individualCount,
-- publishingOrgKey,
-- coordinateUncertaintyInMeters,
-- coordinatePrecision,
-- eventDate,
-- day,
-- month,
-- year,
-- basisOfRecord,
-- institutionCode,
-- collectionCode,
-- identifiedBy,
-- dateIdentified,
-- license,
-- rightsHolder,
-- recordedBy,
-- lastInterpreted,
-- issue,


-- Sommaire de quelques données de type caractères (VARCHAR)
SELECT 
category, 
value, 
count(*) AS n
FROM gbnm
UNPIVOT (
  value FOR category IN (taxonRank, occurrenceStatus, 
                         license, basisOfRecord, 
                         countrycode, stateprovince,
                         --collectioncode, 
                         institutionCode,
                         kingdom)
)
GROUP BY ALL
ORDER BY category, n DESC;



-- Compte le nombre de règne
SELECT kingdom, count(kingdom) AS n 
FROM gbnm 
GROUP BY ALL;

-- check the data
select species * from gbnm limit 10;



-- Count number of rows from original dataset 
-- SELECT count(*) FROM gbnm;

-- count number of items for one species 
-- SELECT count(*) 
-- FROM gbnm
-- WHERE species IN ('Myotis lucifugus');

-- check for NULL species names 
SELECT species, class, genus, count(*) 
FROM gbnm
WHERE species IS NULL
group by species, class, genus;



---------------------------------------------------
  -- Spatial intersection And filtering ------------
  -- Note : 
  --   The geometry column in both datasets is NOT the same 
--   intersection took 3 min


------------------------
  --small example to test 
CREATE OR REPLACE view test AS 
SELECT * 
  FROM gbnm limit 1e2; 


-- note : un RTREE se fait SEULEMENT sur des 'TABLE' et NON des 'VIEW' 
-- CREATE INDEX idx_table1_geom ON gbnm USING RTREE (geometry);
-- CREATE INDEX idx_table2_geom ON admin_qc USING RTREE (geom);



----------------------------------------
  CREATE OR REPLACE VIEW sp_clip_qc AS
SELECT 
p.* EXCLUDE geometry,
b.*  EXCLUDE geom,
ST_Intersects(p.geometry, b.geom) as geometry
FROM 
gbnm as p, 
admin_qc as b
WHERE 
ST_Intersects(p.geometry, b.geom);


-------------------
  CREATE OR REPLACE VIEW sp_clip_qc AS
SELECT *
  FROM gbnm as p
JOIN admin_qc as b
ON ST_Intersects(p.geometry, b.geom);


------------------------------------
  -- make test
CREATE OR REPLACE VIEW spatest AS
SELECT *
  FROM test as p -- gbnm
JOIN admin_qc as b
ON ST_Intersects(p.geometry, b.geom);

COPY spatest TO 'testdata.parquet' (FORMAT parquet);
COPY test TO 'testtest.parquet' (FORMAT parquet);


-- check data 
select species, geometry from sp_clip_qc limit 10;


-- for character data (VARCHAR)
SELECT 
category, 
value, 
count(*) AS n
FROM sp_clip_qc
UNPIVOT (
  value FOR category IN (taxonRank, occurrenceStatus, 
                         license, basisOfRecord, 
                         countrycode, stateprovince,
                         collectioncode)
)
GROUP BY ALL
ORDER BY category, n DESC;

-- for numerical data (BIGINT)
SELECT 
category, 
value, 
count(*) AS n
FROM sp_clip_qc
UNPIVOT (
  value FOR category IN (year)
)
GROUP BY ALL
ORDER BY category, n DESC;


-- count the species 
select species, count(species) as n 
from sp_clip_qc 
group by species 
order by n desc;

-- nb rows original data
select count(*) from gbnm;
-- nb rows clipped data
select count(*) from sp_clip_qc;


-- Export to gpkg file. Takes 60 sec. File size : 340 MB. for ONLY the data in QC
-- COPY sp_clip_qc TO 'gbif_prep.gpkg' (FORMAT GDAL, DRIVER 'GPKG', SRS 'EPSG:4326');

-- Export to parquet file.  Takes 32 sec. File size : 3.13GB. for ONLY the data in QC 
-- COPY gbnm TO 'gbif_prep.parquet' (FORMAT parquet);

SELECT NOW();
Explain COPY sp_clip_qc TO 'gbif_prep_h3.parquet' (FORMAT parquet);
SELECT NOW();

-- quit duckdb
.exit

cd ~/Projects/data

# Copy the data to Windows!
PATHTOWINDODO="/mnt/c/Projects/PRJ_24001/output/Biodiversity/GBIF/gbif_sdm"
PATHBUBUNTU="gbif/gbif_data_espece_terrain_0005901_260208012135463.gpkg"
cp $PATHBUBUNTU $PATHTOWINDODO
