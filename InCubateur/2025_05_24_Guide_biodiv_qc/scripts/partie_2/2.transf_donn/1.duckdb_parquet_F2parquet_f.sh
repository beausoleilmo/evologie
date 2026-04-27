## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## # 
## Préparation des données d'occurence de biodiversté GBIF
#
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# Date cération : 2026-02-14
# Auteur: Marc-Olivier Beausoleil

##__________####
## LISEZMOI ####

## Description : 
#  -->  Faire un fichier parquet (et non un dossier) avec les données 
#.      Ce fichier servira pour le reste des analyses 

## Fonctionnement : 
#  --> 

cd "Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data"

duckdb

SET VARIABLE gb_path_pq = "/Volumes/g_magni/gbif_data/0040587-260226173443078.parquet/*";
COPY (
  SELECT
  *,
  ST_Point(decimalLongitude, decimalLatitude) AS geometry
  FROM
  read_parquet(getvariable('gb_path_pq'))
) TO 'gbif_prep_all.parquet' (FORMAT parquet);