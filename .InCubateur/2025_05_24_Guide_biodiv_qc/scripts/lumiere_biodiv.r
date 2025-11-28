## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Préparation des données de biodiversité (GBIF)
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-09-14
# auteur: Marc-Olivier Beausoleil

#### ____________####
#### Lisez-moi --------
#   --> Faire la lumière sur la biodiversité 

# Charger les progiciels --------------------------------------------------
library(duckdb) # Pour se connecter avec un pilote duckDB (C'est la même chose que d'aller dans le terminal et exécuter 'duckdb')
library(DBI) # Database (DB) interface (I). 
library(dplyr) # Manipulation de données 
library(dbplyr) # Manipulation de bases de données 
library(tidyr) # pour gather
library(purrr) # pour map
library(stringr) # pour str_c
library(terra) # pour les images matricielles
library(viridisLite) # Palette de couleur viridis 

# Obtenir les données de GBIF ------------------------------------------------------------

# Se connecter à une session duckDB 
con <- dbConnect(duckdb())

# Read the CSV into a DuckDB table named "gbif_data"
csv = "/Volumes/g_magni/gbif_data/0047252-250827131500795.csv"
path_gbif_csv_fr = "/Volumes/g_magni/gbif_data/0001413-250914085247600.csv" # exemple avec les données GBIF de la France (~100GB)! 

gbif = duckdb::tbl_file(con, csv)

# Compte le nombre de lignes 
gbif_fr = duckdb::tbl_file(con, path_gbif_csv_fr)
# gbif_fr |> count() |> collect()  # 198,055,071

# Données de France (100GB)
tictoc::tic() # 25 sec sur NVMe
df <- gbif_fr |> 
  mutate(latitude = round(decimalLatitude, 2),
         longitude = round(decimalLongitude, 2)) |> 
  count(longitude, latitude) |> 
  collect() |> 
  mutate(n = log(n))
tictoc::toc()

# Faire un raster avec les données GBIF (arrondir les coordonnées)
tictoc::tic() # 25 sec sur NVMe, 65 sec sur disque dure 
df <- gbif |> 
  mutate(latitude = round(decimalLatitude, 2),
         longitude = round(decimalLongitude, 2)) |> 
  count(longitude, latitude) |> 
  collect() |> 
  mutate(n = log(n))
tictoc::toc()

# dir.create(path = 'output/biodiv', showWarnings = FALSE, recursive = TRUE)
r <- rast(df, crs="epsg:4326")
# Afficher la 'densité' d'observation au Québec 
plot(r, 
     col = viridis(1e3), 
     legend=FALSE, maxcell=6e6, colNA="black", axes=FALSE)

# Exporter l'image matricielle 
# writeRaster(x = r, 
#             filename = "output/biodiv/gbif_qc.tif", 
# overwrite = TRUE)