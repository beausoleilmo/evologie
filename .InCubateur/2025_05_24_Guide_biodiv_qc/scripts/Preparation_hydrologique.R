## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Prépare l'hydrologie au Québec 
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-08-31
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Préparation des couches hydrologique pour le Sud du québec 
#   --> Téléchargement de la Géobase du réseau hydrographique du Québec (GRHQ) dans un dossier 'grhq' 
#     --> Source : https://www.donneesquebec.ca/recherche/fr/dataset/grhq 
#     --> Pour le sud du Québec, les zones 00, 01, 02, 03, 04, 05, 06, 07_1, 07_2, 08, 14 semblent suffisantes
#     --> Au total, c'est plus de 13GB de données! Après manipualtion, c'est seulement 3.5MB! 
#     --> Les zones sont observables ici : https://vgo-telechargement.portailcartographique.gouv.qc.ca/mobile.aspx?gpw=6781ef64-4bbd-4cb1-86c8-b138cf32270b



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

# Liste tous les dossiers téléchargés 
dossiers_grhq = list.dirs(path = "data/grhq", 
                          full.names = TRUE, 
                          recursive = TRUE)

# Sélectionner seulement les dossiers qui contiennent '.gdb' 
gdb_grhq = grep(pattern = '.gdb', 
                x = dossiers_grhq, 
                value = TRUE)

# Charger tous les fichiers '.gdb' et joindre tous les fichiers
hq = lapply(X = gdb_grhq, 
            FUN = function(x) st_read(x, layer = "RH_S") |> 
              # Correction d'une colonne avec type de donnée ambigue
              dplyr::mutate(CODE_PRECI_PLANI = as.character(CODE_PRECI_PLANI))) |> 
  # concatener les fichiers un à la suite des autres 
  bind_rows()



## ____________####
## Manipulation des données --------

# Pour simplifier et avoir moins de polygones à représenter sur la carte 
# Extraction des polygones qui ont une superficie de plus de 1 000 000 m^2. 
# (vérifier avec hq[1,'SHAPE_Area'] et st_area(hq[1,]))
hq_sel = hq |> 
  filter(SHAPE_Area > 1e6) |> 
  st_zm() 

# Simplification des données spatiales pour des calculs plus efficace 
hq_filt_complete = hq_sel |> 
  st_simplify(dTolerance = 100) |> 
  st_transform(crs = masterCRS) |> 
  st_crop(y = bbox_qc)

# Taille de notre table d'attributs
dim(hq_filt_complete)


## ____________####
## Exporter les données --------

# Exportation des données pour un accès plus rapide
st_write(obj = hq_filt_complete, 
         dsn = 'data/grhq_sud_qc.gpkg', 
         delete_dsn = TRUE)
