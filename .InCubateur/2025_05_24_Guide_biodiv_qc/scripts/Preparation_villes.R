## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Prépare les villes du Québec 
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Préparation de la couche spatiale des villes du Québec pour exportation en GeoPackage au lieu d'un GeoJSON 
#   --> Téléchargement du tableau des villes et des informations sur le site d'Ouranos .
#     --> voir le site de portraits climatiques d'Ouranos https://portraits.ouranos.ca/fr/

## ____________####
## Prépare l'environnement --------

# Charge selon la position du chemin d'accès 
if (!grepl(pattern = '2025_05_24_Guide_biodiv_qc', x = getwd())) {
  source(file = '.InCubateur/2025_05_24_Guide_biodiv_qc/scripts/00_initialize.R')
} else {
  source(file = 'scripts/00_initialize.R')
}

# Créer un dossier pour exporter nos données 
dir.create(path = 'output', 
           showWarnings = FALSE)

## ____________####
## Charge les données --------

# Va chercher les villes et populations importantes sur le site d'Ouranos
lien_villes = 'https://pavics.ouranos.ca/pc-geoserver/pc/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=pc:places&outputFormat=application%2Fjson&format_options=CHARSET:UTF-8&pc_ver=3.0.3'

# Lire le GeoJSON à partir du lien
villes_qc = st_read(
  dsn = lien_villes
)

## ____________####
## Exporter les données --------

st_write(obj = villes_qc, 
         dsn = 'output/villes_qc_ouranos.gpkg', 
         # Donner un nom à la colonne de géométrie 
         layer_options="GEOMETRY_NAME=geometry",
         delete_dsn = TRUE)
