## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Prépare les MRC du Québec 
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Préparation de la couche spatiale des MRC du Québec pour exportation en GeoPackage au lieu d'un shapefile 
#   --> Téléchargement du découpage administratif sur Données Québec.
#     --> voir Découpages administratifs https://www.donneesquebec.ca/recherche/dataset/decoupages-administratifs/resource/b368d470-71d6-40a2-8457-e4419de2f9c0
#     --> Le fichier qui nous intéresse est `mrc_s.shp` : ce sont les polygones des MRC du Québec. 
#     --> L'original est un Shapefile. Mais je trouve cela plus élégant de mettre cela en gegopackage (`.gpkg`). 

## ____________####
## Prépare l'environnement --------

# Charge selon la position du chemin d'accès 
if (!grepl(pattern = '2025_05_24_Guide_biodiv_qc', x = getwd())) {
  source(file = '.InCubateur/2025_05_24_Guide_biodiv_qc/scripts/00_initialize.R')
} else {
  source(file = 'scripts/00_initialize.R')
}

# Créer un dossier pour exporter nos données 
dir.create(path = 'data', 
           showWarnings = FALSE)


## ____________####
## Charge les données --------
# Ici c'est le Shapefile 
regqc = sf::st_read(
  dsn = "data/adim_reg_qc/mrc_s.shp"
) 


## ____________####
## Exporter les données --------

# Exporter le fichier SHP 
sf::st_write(obj = regqc,
             dsn = "data/adim_reg_qc/mrc_s.gpkg"
) 