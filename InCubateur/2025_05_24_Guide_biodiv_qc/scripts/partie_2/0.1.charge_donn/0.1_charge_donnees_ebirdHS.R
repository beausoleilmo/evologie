## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   -->  données points ebirds

suppressMessages(
  {
    require(sf)
    require(dplyr)
  }
)

source("Incubateur/2025_05_24_Guide_biodiv_qc/scripts/partie_2/0.init/0.0.charge_crs.R")

message("Charge : 'ebird_hp_sf' (points d'observations eBird)")

pts_chauds_ebird = file.path(
  "posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc/", 
"data/partie_1/biodiv/eBird_hotspots_CA_QC_2025-10-13.csv"
)

# Mettre le fichier en mémoire 
ebird_hp = read.csv(file = pts_chauds_ebird, 
                    header = FALSE)

# Ajouter un nom aux colonnes 
names(ebird_hp) <- c("locId", 
                     "countryCode", 
                     "subnational1Code", 
                     "subnational2Code", 
                     "lat", "lng",        # Données spatiales!
                     "locName",           # Nom des sites
                     "latestObsDt",       # Date de la dernière observation
                     "numSpeciesAllTime") # Nombre d'espèces

# Préparer les données spatiales pour une cartographie 
ebird_hp_sf = ebird_hp |>  
  # Mettre tableau en format spatial 
  sf::st_as_sf(coords = c('lng', 'lat')) |> 
  # Choisir le CRS 
  sf::st_set_crs(value = 4326) |>  
  # Formatter la colonne de date 
  dplyr::mutate(
    date_obs_recent = as.POSIXct(
      latestObsDt,
      format="%Y-%m-%d %H:%M",
      tz = Sys.timezone()
    )
  ) |> 
  # Projection du jeu de données selon le CRS du projet 
  sf::st_transform(crs = projetCRS)  |> 
  # Nouvelle colonne d'étiquette 
  dplyr::mutate(
    labs = sprintf(
      # Joindre le nom d'un point eBird et le nombre d'espèces.
      fmt = "%s — %s sp.", 
      locName, 
      numSpeciesAllTime)
  )

# Ménage d'objets non nécessaire 
rm(ebird_hp, pts_chauds_ebird)

