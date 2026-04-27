## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> 


## ____________####
## Prépare l'environnement --------


# Capture les arguments
args <- commandArgs()


# Sélection de colonnes à charger
cols <- args[1]

# Nom du fichier et couche
layer <- args[2]

# Construction de la requête SQL
sql_quer <- sprintf("SELECT %s from %s", cols, layer) #  where class IN ('Aves')

print(sql_quer)

# Importation données GBIF
tictoc::tic()
# Joliette : 9 sec
# Montréal : 25 sec
gb_dat <- sf::st_read(
  dsn = file.path(
    "Incubateur/2025_05_24_Guide_biodiv_qc/",
    "data/partie_2/biodiv/gbif_data/",
    sprintf("%s.parquet", layer)
  ),
  # Requête SQL
  query = sql_quer
)
tictoc::toc()

# Graphique des points
# gb_dat |>
#   st_geometry() |>
#   plot(pch = '.', asp = 1)

# Obtenir la région du jeu de données GBIF préparé avec duckdb
reg_gb <- gb_dat |>
  st_drop_geometry() |>
  distinct(MRS_NM_REG) |>
  pull()
