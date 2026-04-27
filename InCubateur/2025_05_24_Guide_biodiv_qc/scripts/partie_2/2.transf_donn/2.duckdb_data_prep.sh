## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## # 
## Préparation des données d'occurence de biodiversté GBIF
#
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# Date cération : 2026-02-14
# Auteur: Marc-Olivier Beausoleil

##__________####
## LISEZMOI ####

## Prérequis : 
#  --> les données sont préparés de CSV vers PARQUET  avec 1.duckdb_csv2parquet.sh

## Description : 
#  --> Après le téléchargement des données GBIF (>20Gb), il faut préparer pour 
#      être capable de mettre en mémoire de R.
#  --> Puisque les données n'entre pas en mémoire (un ordinateur avec 16GB RAM)
#      duckDB est une solution pragmatique pour lire ces données 

## Fonctionnement : 
#  --> L'installation de duckDB (https://duckdb.org/install) est requise 
#  --> En utilisant le terminal, on navigue au dossier pour 
#      faire les opérations voulues. 
#  --> Data source : 
#  --> Data cite :  

# Région administratives  ------------
# DESC: 
#   Importation de Shapefile de la région administrative du Québec (polygone)
# DATA SOURCE : 
#    https://www.donneesquebec.ca/recherche/dataset/decoupages-administratifs/resource/b368d470-71d6-40a2-8457-e4419de2f9c0


# Go to correct location 
cd ~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data

# Open duckdb instance 
# duckdb
~/.duckdb/cli/latest/duckdb

# En duckdb : 
# -- Doit placer 'OR' entre paranthèse pour une évaluation correcte 'AND' a précéance sur 'OR'

-- # Syntaxe duckdb (SQLish) à partir de maintenant 

-- # Paramètres duckdb
.timer on 
.maxrows 50

-- # Installation et charge librairies 
INSTALL spatial; LOAD spatial;

-- # Grille H3  
-- # https://duckdb.org/community_extensions/extensions/h3
INSTALL h3 FROM community; LOAD h3;

-- # Définir les 'sentiers' vers les fichiers

-- # Données GBIF (parquet)
-- # Données csv -> parquet 
-- SET VARIABLE gb_path_pq = "~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data/0047252-250827131500795.parquet";

-- # Données parquet -> avec erreur "000000", voir https://github.com/gbif/portal-feedback/issues/6570
-- # Export GBIF's parquet folder to parquet file
-- # Voir le code dans commande_download_gbif.R
-- SET VARIABLE gb_path_pq = "/Volumes/g_magni/gbif_data/0040587-260226173443078.parquet/*";

-- # Données préparées à partir du parquet de GBIF
SET VARIABLE gb_path_pq = "~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_prep_all.parquet";

-- # Noms des espèces (wild species canada, LFVQ et GBIF)
SET VARIABLE sp_nm_path_raw = '~/Github_proj/evologie/output/partie_2/esp_noms_gbif.csv';

-- # Données de région administrative 
SET VARIABLE admin_path = "~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/decoupages_administratifs_1_20000_format_SHP/mrc_s.shp";

SET geometry_always_xy = true;

------------------
-- # Transformation des donnnées spatiales  
CREATE OR REPLACE VIEW admin_qc AS 
  SELECT MRS_NM_MRC, MRS_NM_REG,  
      ST_Transform(geom, 'EPSG:4269', 'EPSG:4326') AS geom
  FROM ST_Read(getvariable('admin_path'));

-- # Regarder les données parquet
-- # describe from read_parquet(getvariable('gb_path_pq')) ; 


---------------------------------------
--- # 8.5 min 

SELECT NOW(); -- # affiche le temps actuel 

COPY (
  -- # Étape 1 : lire parquet et filtrer les données 
  WITH filtered_gb AS (
    SELECT 
      *,
      -- Établir la géométrie  
      ST_Point(decimalLongitude, decimalLatitude) AS geometry,
      -- Grille H3 : Génération des résolutions 6 à 9
      h3_latlng_to_cell(decimalLatitude, decimalLongitude, 6) AS h3_6,
      h3_latlng_to_cell(decimalLatitude, decimalLongitude, 7) AS h3_7,
      h3_latlng_to_cell(decimalLatitude, decimalLongitude, 8) AS h3_8,
      h3_latlng_to_cell(decimalLatitude, decimalLongitude, 9) AS h3_9,
      h3_latlng_to_cell(decimalLatitude, decimalLongitude, 10) AS h3_10
    FROM
      read_parquet(getvariable('gb_path_pq'))
    -- Filtrer les données 
    WHERE 
      species IS NOT NULL 
      AND basisOfRecord IN ('HUMAN_OBSERVATION') 
      AND countryCode IN ('CA')
      AND (stateProvince IN ('Quebec', 'Québec', 'Qc') 
        OR stateProvince IS NULL)
      -- Garde Chromista, Fungi, Plantae, Animalia
      AND taxonRank IN ('SPECIES', 'SUBSPECIES', 'VARIETY') 
      AND kingdom IN ('Chromista', 'Fungi', 'Plantae', 'Animalia') 
      AND (coordinateUncertaintyInMeters <= 200 OR coordinateUncertaintyInMeters IS NULL)
  )
  --,
  -- # Maintenant traité à part dans 3.duckdb_data_type_fr.sh
 -- joined_data AS (
 --   -- Étape 2: Joindre le nom des espèces
 --   SELECT 
 --     gb.*, 
 --     sn.* EXCLUDE (scientificName, species)
 --   FROM 
 --     filtered_gb gb
 --   LEFT JOIN 
 --     read_csv(getvariable('sp_nm_path_raw')) sn 
 --   ON 
 --     gb.scientificName = sn.scientificName
 -- )
  -- # Étape 3: Jointure spatiale (région administratives) et formatter H3 en ID-hexagone
  SELECT 
    jd.* EXCLUDE (geometry, h3_6, h3_7, h3_8, h3_9, h3_10),
    -- Conversion en String IDs
    h3_h3_to_string(h3_6) AS h3_cell_id_6,
    h3_h3_to_string(h3_7) AS h3_cell_id_7,
    h3_h3_to_string(h3_8) AS h3_cell_id_8,
    h3_h3_to_string(h3_9) AS h3_cell_id_9,
    h3_h3_to_string(h3_10) AS h3_cell_id_10,
    qc.* EXCLUDE geom,
    jd.geometry 
  FROM 
    -- joined_data jd
    filtered_gb jd
  JOIN admin_qc qc ON ST_Intersects(jd.geometry, qc.geom)
) TO 'gbif_prep_h3.parquet' (FORMAT parquet);

SELECT NOW();



---------------------------------------
.maxrows 60

describe from read_parquet('gbif_prep_h3.parquet');


-- # quit duckdb
.exit

 cd ~/Projects/data
