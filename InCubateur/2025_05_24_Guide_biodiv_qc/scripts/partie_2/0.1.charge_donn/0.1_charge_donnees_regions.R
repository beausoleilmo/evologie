## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Charge les données des régions du Québec avec le bon CRS 
suppressMessages(
  {
require(sf)
  }
)

# CRS du projet 
source(file.path(incub, "scripts/partie_2/0.init/0.0.charge_crs.R"))

message("Charge : 'regqc' (MRC du Québec)")
# Charger les Régions du Québec
regqc <- sf::st_read(
  dsn = file.path(
    incub, 
    "data/partie_2/decoupages_administratifs_1_20000_format_SHP/mrc_s.shp"
  ),
  # dsn = "posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc/data/partie_1/admin_geo/admin_reg_qc/mrc_s.gpkg",
  quiet = TRUE
) |> 
  sf::st_transform(
    crs = projetCRS
    )
