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

# init
suppressMessages(
  {
    library(dplyr)    # Manipulation données 
    library(tidyr)    # Manipulation données 
    library(sf)       # Simple feature
    library(h3jsr)    # Grille H3
    library(mapview)  # Cartes 
    library(ggplot2)  # Graphiques 
    library(tictoc)   # Minuteur 
    library(lwgeom)   # Préparation de polygon pour filtre GBIF 
    library(duckdb)   # Lire fichiers données qui n'entrent pas en mémoire 
    library(treemap)  # Compte des espèces
    library(plotly)   # Diagrammes interactifs
    library(rgbif)    # Permet d'intéragir avec GBIF 
    library(jsonlite) # 
  }
)

# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")
message(sprintf("Accès projet: %s", incub))

source(file.path(incub, "scripts/partie_2/0.init/0.0.charge_crs.R"))
