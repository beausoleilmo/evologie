## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Prépare les domaines bioclimatiques du Québec 
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-10-25
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Préparation de la couche spatiale des des domaines climatiques du Québec pour exportation en GeoPackage au lieu d'un geodatabase 
#   --> Téléchargement des écorégions sur Données Québec.
#     --> voir Classification écologique du territoire québécois https://www.donneesquebec.ca/recherche/dataset/systeme-hierarchique-de-classification-ecologique-du-territoire/resource/b336d842-9f1d-4d0e-88c1-d771d8ade785

## ____________####
## Prépare l'environnement --------

# Charge selon la position du chemin d'accès 
if (!grepl(pattern = '2025_05_24_Guide_biodiv_qc', x = getwd())) {
  source(file = '.InCubateur/2025_05_24_Guide_biodiv_qc/scripts/00_init/00_initialize.R')
} else {
  source(file = 'scripts/00_init/00_initialize.R')
}

# Créer un dossier pour exporter nos données 
dir.create(path = 'data', 
           showWarnings = FALSE)

## ____________####
## Charge les données --------

# Chemin accès vers le fichier (ici GDB ou geoDataBase)
CLASSI_ECO_QC_GDB = "zdata/partie_1/CLASSI_ECO_QC.gdb"

# Extraire les couches pour voir ce qui est spatial (voir la colonne 'geometry_type')
cls_eco_couches = sf::st_layers(dsn = CLASSI_ECO_QC_GDB)

# Préparation du jeu de données pour interne : utiliser le jeu de données en GPKG 

# Extraction du domaine biologique du Québec (N3 ou niveau 3)
cls_eco = sf::st_read(
  dsn = CLASSI_ECO_QC_GDB, 
  layer = 'N3_DOM_BIO', 
  quiet = TRUE
) 

# Simplification des géométrie (va faire un plus petit fichier et plus rapide)
cls_eco_out = cls_eco |> 
  sf::st_simplify(dTolerance = 50)

## ____________####
## Exporter les données --------

# Exporter en fichier geopackage
sf::st_write(
  obj = cls_eco_out, 
  dsn = "data/partie_1/ecologie/CLASSI_ECO_QC/classification_eco.gpkg", 
  layer = 'N3_DOM_BIO', 
  delete_dsn = TRUE
)