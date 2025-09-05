## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Initialisation du projet 
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

#### ____________####
#### Lisez-moi --------
#   --> Préparation de l'environnement de travail 
#   --> Charger les progiciels R  
#   --> Charge les fonctions   

#### ____________####
# Chemin d'accès du projet ------

# Préparation de l'environnement ------------------------------------------
# Prendre le chemin d'accès actuel 
# Mettre le chemin d'accès dans le dossier du projet 
if (!grepl(pattern = '2025_05_24_Guide_biodiv_qc', x = getwd())) {
  setwd('.InCubateur/2025_05_24_Guide_biodiv_qc')
}

#### ____________####
# Progiciels R ------------------------------------------------------------
# Manipulation de données 
library(dplyr)   # -> manipulation et préparation de données
library(ggplot2) # -> graphiques pour visualisation de données

# Cartographie et géomatique 
library(sf)      # -> manipulation spatiale et cartographie 
library(terra) # -> manipulation spatiale et cartographie (dont les raster)
library(mapview) # -> cartes interactives pour visualisations rapides 

# Utilitaire 
library(tictoc)  # -> minuteur pour mesurer le temps de long processus.

# Bases de données 
library(duckdb)   # Interface pour les base de données 
library(duckdbfs) # Système de fichier de haute performance pour les base de données 


#### ____________####
# Charge les fonctions ----------------------------------------------------
source(file = 'scripts/functions.R')

# Prépare le CRS pour toutes les couches 
masterCRS = structure(
  list(
    input = "NAD83 / Quebec Lambert", 
    wkt = "PROJCRS[\"NAD83 / Quebec Lambert\",\n    BASEGEOGCRS[\"NAD83\",\n        DATUM[\"North American Datum 1983\",\n            ELLIPSOID[\"GRS 1980\",6378137,298.257222101,\n                LENGTHUNIT[\"metre\",1]]],\n        PRIMEM[\"Greenwich\",0,\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        ID[\"EPSG\",4269]],\n    CONVERSION[\"Quebec Lambert Projection\",\n        METHOD[\"Lambert Conic Conformal (2SP)\",\n            ID[\"EPSG\",9802]],\n        PARAMETER[\"Latitude of false origin\",44,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8821]],\n        PARAMETER[\"Longitude of false origin\",-68.5,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8822]],\n        PARAMETER[\"Latitude of 1st standard parallel\",60,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8823]],\n        PARAMETER[\"Latitude of 2nd standard parallel\",46,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8824]],\n        PARAMETER[\"Easting at false origin\",0,\n            LENGTHUNIT[\"metre\",1],\n            ID[\"EPSG\",8826]],\n        PARAMETER[\"Northing at false origin\",0,\n            LENGTHUNIT[\"metre\",1],\n            ID[\"EPSG\",8827]]],\n    CS[Cartesian,2],\n        AXIS[\"easting (X)\",east,\n            ORDER[1],\n            LENGTHUNIT[\"metre\",1]],\n        AXIS[\"northing (Y)\",north,\n            ORDER[2],\n            LENGTHUNIT[\"metre\",1]],\n    USAGE[\n        SCOPE[\"Topographic mapping (medium and small scale).\"],\n        AREA[\"Canada - Quebec.\"],\n        BBOX[44.99,-79.85,62.62,-57.1]],\n    ID[\"EPSG\",32198]]"
  ), 
  class = "crs"
)

# Prépare l'emprise spatiale du Québec 
bbox_qc = structure(c(xmin = -830291.429999985, 
                      ymin = 117964.150000002, 
                      xmax = 783722.440000005, 
                      ymax = 721304.835203388), 
                    class = "bbox", 
                    crs = structure(
                      list(
                        input = "NAD83 / Quebec Lambert", 
                        wkt = "PROJCRS[\"NAD83 / Quebec Lambert\",\n    BASEGEOGCRS[\"NAD83\",\n        DATUM[\"North American Datum 1983\",\n            ELLIPSOID[\"GRS 1980\",6378137,298.257222101,\n                LENGTHUNIT[\"metre\",1]]],\n        PRIMEM[\"Greenwich\",0,\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        ID[\"EPSG\",4269]],\n    CONVERSION[\"Quebec Lambert Projection\",\n        METHOD[\"Lambert Conic Conformal (2SP)\",\n            ID[\"EPSG\",9802]],\n        PARAMETER[\"Latitude of false origin\",44,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8821]],\n        PARAMETER[\"Longitude of false origin\",-68.5,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8822]],\n        PARAMETER[\"Latitude of 1st standard parallel\",60,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8823]],\n        PARAMETER[\"Latitude of 2nd standard parallel\",46,\n            ANGLEUNIT[\"degree\",0.0174532925199433],\n            ID[\"EPSG\",8824]],\n        PARAMETER[\"Easting at false origin\",0,\n            LENGTHUNIT[\"metre\",1],\n            ID[\"EPSG\",8826]],\n        PARAMETER[\"Northing at false origin\",0,\n            LENGTHUNIT[\"metre\",1],\n            ID[\"EPSG\",8827]]],\n    CS[Cartesian,2],\n        AXIS[\"easting (X)\",east,\n            ORDER[1],\n            LENGTHUNIT[\"metre\",1]],\n        AXIS[\"northing (Y)\",north,\n            ORDER[2],\n            LENGTHUNIT[\"metre\",1]],\n    USAGE[\n        SCOPE[\"Topographic mapping (medium and small scale).\"],\n        AREA[\"Canada - Quebec.\"],\n        BBOX[44.99,-79.85,62.62,-57.1]],\n    ID[\"EPSG\",32198]]"), 
                      class = "crs")
)
