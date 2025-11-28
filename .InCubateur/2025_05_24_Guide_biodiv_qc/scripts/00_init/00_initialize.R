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

# Création de dossier de sortie
part_fold = sprintf(c("partie_%d"), 1:3)
mapply(FUN = dir.create, 
       path = sprintf("output/%s", part_fold),
       showWarnings = FALSE, 
       recursive = TRUE)

#### ____________####
# Progiciels R ------------------------------------------------------------

# install.packages(c("dplyr", "ggplot2", "sf", "terra",
#                    "mapview", "tictoc",
#                    "duckdb", "duckdbsf", "rgbif", "rinat", 
#                    "jpeg",
#                    "fs", "generics",
#                    "leafem", "maps",
#                    "sass", "servr",
#                    "svglite", "tinytex", "promises"
#                    ))

# Manipulation de données
library(dplyr) # -> manipulation et préparation de données
library(ggplot2) # -> graphiques pour visualisation de données

# Cartographie et géomatique
library(sf) # -> manipulation spatiale et cartographie
library(terra) # -> manipulation spatiale et cartographie (dont les raster)
library(mapview) # -> cartes interactives pour visualisations rapides

# Utilitaire
library(tictoc) # -> minuteur pour mesurer le temps de long processus.

# Bases de données
library(duckdb) # Interface pour les base de données
library(duckdbfs) # Système de fichier de haute performance pour les base de données

library(rgbif) # Lire les données GBIF 
library(rinat) # Lire les données iNaturalist

# Exporter les citations des progiciels R en fichier texte
knitr::write_bib(.packages(),
                 "my_citations.bib")

#### ____________####
# Charge les fonctions ----------------------------------------------------
source(file = 'scripts/00_init/functions.R')

# Définition de CRS pour projet ----------------------------------------------------
input_name = "NAD83 / Quebec Lambert"
crs_32198 = readLines(con = "data/param_0/projetCRS.txt")

# Prépare le CRS pour toutes les couches
projetCRS = structure(
  list(
    input = input_name,
    wkt = crs_32198
  ),
  class = "crs"
)

# Emprise Québec ----------------------------------------------------
# Prépare l'emprise spatiale du Québec
bbox_qc = structure(
  c(
    xmin = -830291.429999985,
    ymin = 117964.150000002,
    xmax = 783722.440000005,
    ymax = 721304.835203388
  ),
  class = "bbox",
  crs = structure(
    list(
      input = input_name,
      wkt = crs_32198
    ),
    class = "crs"
  )
)
