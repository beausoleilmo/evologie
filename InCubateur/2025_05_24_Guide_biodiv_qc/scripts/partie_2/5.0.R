## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> J'ai commencé le script dans R, mais cela prenait beaucoup de temps
#       à exécuter. J'ai donc adapté les parties lente en duckdb, puis les
#       'source' au besoin. Cela est plus rapide (>2500x dans
#       certains cas ou 0.2 s vs 10 min ) et permet
#       d'explorer encore plus les données.
#   -->

## Benchmarking --------

# Transformation des données à différentes résolutions

# duckdb :
# Sommaire par la grille H3 et toutes les régions du Québec
# 6 : 0.20 sec
# 7 : .17 sec
# 8 : 0.16 sec
# 9 : 0.21 sec

# R :
# Sommaire par la grille H3 et toutes les régions du Québec
# 6 :  23 sec
# 7 :  72 sec
# 8 : 195 sec
# 9 : 550 sec (duckdb est plus de 2600X plus rapide!!!)


# Topographic Data of Canada - CanVec Series
# https://open.canada.ca/data/en/dataset/8ba2aa2a-7bb9-4448-b4d7-f164409fe056

# Index of /pub/nrcan_rncan/vector/canvec/shp/Land
# https://ftp.maps.canada.ca/pub/nrcan_rncan/vector/canvec/shp/Land/

# Index of /pub/nrcan_rncan/vector/canvec/shp/Toponymy
# https://ftp.maps.canada.ca/pub/nrcan_rncan/vector/canvec/shp/Toponymy/

## ____________####
## Prépare l'environnement --------

# Liste d'espèces avec Type_FR
# source("Incubateur/2025_05_24_Guide_biodiv_qc/scripts/partie_2/0.1_charge_donnees_sp_nm.R")
# Initialise les
source(file = file.path(
  incub, 
  "scripts/partie_2/0.init/0.0.init.R"
))


# Charger région pour carto
source(
  file.path(
    incub,
    "scripts/partie_2/0.1.charge_donn/0.1_charge_donnees_regions.R")
  )


scripts <- c(
  "4.duckdb_compte_h3.sh",
  "4.duckdb_compte_h3_somme.sh"
)

scrpt_path <- file.path(
  incub,
  "scripts/partie_2/2.transf_donn",
  scripts
)


# Fabrication d'un fichier sommaire de biodiversité avec grille H3
# avec script duckdb
input_path <- file.path(
  incub,
  "data/partie_2/biodiv/gbif_data/",
  "gbif_prep_type_fr_h3.parquet"
)


# Regarder les colonnes rapidement! 
con <- dbConnect(duckdb())
# This returns a dataframe of column info (name, type, etc.)
col_info <- dbGetQuery(
  con, 
  sprintf(
    "DESCRIBE SELECT * FROM '%s'",
    input_path
  )
)
dbDisconnect(con)

cols <- col_info$column_name

h3cells = grep(pattern = "h3_cell_id_", x = cols, value = TRUE)


message("Résolutions H3 à faire")
res_numbers <- sub(".*_", "", h3cells) |> as.numeric()

