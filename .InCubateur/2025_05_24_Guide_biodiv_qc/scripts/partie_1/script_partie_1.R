#' ---
#' title: 'Guide d''identification de biodiversité du Québec - Partie 1 : les cartes'
#' description: Comment les données de biodiversité issues de la science citoyenne permettraient-elles
#'   l'élaboration de dépliants d'identification d'espèces?
#' date: '2026-01-17'
#' author:
#'   name: Marc-Olivier Beausoleil
#' ---


library(renv)
renv::restore() # Permet de restaurer la session avec les mêmes versions
# Lire le script de préparation automatiquement
source(
  file = '.InCubateur/2025_05_24_Guide_biodiv_qc/scripts/00_init/00_initialize.R')

# Fonctionne si vous téléchargez les jeux de données originaux localement. 
# Suivre les indications dans chaque script
# source(file = 'scripts/partie_1/Preparation_admin_region.R')
# source(file = 'scripts/partie_1/Preparation_eco_region.R')
# source(file = 'scripts/partie_1/Preparation_hydrologique.R')
# source(file = 'scripts/partie_1/Preparation_villes.R')

# Charger le géopackage 
regqc = sf::st_read(
  # DSN : data source name
  dsn = "data/partie_1/admin_geo/admin_reg_qc/mrc_s.gpkg", 
  quiet = TRUE
) 

# Sélection de colonnes
regqc |> 
  dplyr::select(
    MRS_NM_MRC, 
    MRS_NM_REG
  ) |> 
  # Extraction de quelques lignes
  head(n = 3)


# Faire une carte interactive.
mapview::mapview(
  x = regqc, 
  zcol = 'MRS_NM_MRC', # Les couleurs représentent les MRCs
  legend = FALSE       # Ne pas ajouter de légende 
) 


cls_eco = st_read(
  dsn = "data/partie_1/ecologie/CLASSI_ECO_QC/classification_eco.gpkg", 
  layer = 'N3_DOM_BIO', 
  quiet = TRUE
)


# Obtenir notre CRS chouchou et l'utiliser comme base pour faire la carte 
projetCRS = st_crs(x = cls_eco)

# Ce CRS est en fait le code EPSG 32198 qui est un système de coordonnées
# projetées 'Conique conforme de Lambert du Québec' NAD83
projetCRS == st_crs(x = 32198)

# Tester si le CRS est équivalent entre des couches 
st_crs(x = cls_eco) == st_crs(x = regqc)

# On transforme le CRS de la région du Québec 
regqc_t = st_transform(x = regqc, 
                       crs = projetCRS)


# Écrire le WKT maitre sur lequel on peut faire référence 
writeLines(
  # Extraire le WKT comme texte seulement 
  text = st_as_text(projetCRS), 
  # Fichier de sortie pour écrire le texte (aussi appeler 'Connection') 
  con = "data/param_0/projetCRS.txt"
) 

# Lire le fichier CRS maitre  
projetCRS_read  = readLines(con = "data/param_0/projetCRS.txt")

# On peut directement utiliser ce CRS de la région du Québec 
regqc_t = st_transform(x = regqc, 
                       crs = projetCRS_read)

# Régions admin du QC
mapview(
  x = regqc_t, 
  zcol = 'MRS_NM_MRC', 
  layer.name = 'MRC du Québec',
  # Change la palette de couleur (voir les palettes ici `sort(hcl.pals())`)
  col.regions = hcl.colors(n = nrow(regqc_t), 
                           palette = "Spectral"),
  legend = FALSE
) +
  # Classification Écologique
  mapview(
    x = regqc_t, 
    zcol = 'NOM_DB', 
    layer.name = 'Domaines biologiques'
  )


# Vérification du CRS de couches spatiales (FALSE si différentes)
st_crs(x = cls_eco) == st_crs(x = regqc)    
# Ici on avait déjà transformé la couche regqc_t.
st_crs(x = cls_eco) == st_crs(x = regqc_t)  


# Pour la simplification des géométries 
# (nombre qui donne un bon résultat suite à des tests)
tolerance = 1e3

# Simplifier une forme pour faire le graphique 
cls_eco_simp = cls_eco |> 
  st_simplify(dTolerance = tolerance)

# Reprojection pour avoir le même CRS 
regqc_simp = regqc |> 
  st_simplify(dTolerance = tolerance) |> 
  st_transform(crs = projetCRS)

# Ou en utilisation le CRS d'une couche directement 
# au lieu de l'objet 'projetCRS'
regqc_simp = regqc |> 
  st_simplify(dTolerance = tolerance) |> 
  st_transform(crs = st_crs(x = cls_eco))

# Faire le graphique de base ggplot 
gg_base = ggplot()


# Couche de domaines bioclimatiques 
gg_cls_eco = geom_sf(
  data = cls_eco,               # Données 
  mapping = aes(fill = NOM_DB), # couleur selon les domaines biologiques
  alpha = 0.9,                  # Transparence à 90% 
  linewidth = 0                 # Pas de ligne, plus beau! 
)                

# Couche des régions administratives du Québec 
gg_reg_qc = geom_sf(
  data = regqc_simp,            # Données 
  fill = NA,                    # Pas de remplissage des polygones
  colour = 'grey100',           # Couleur des lignes
  linewidth = 0.05              # largeur fine pour les lignes
)


# Ajout des couches ggplot dans l'ordre voulu 
gg_qc_db = gg_base +
  # Ajout de la classification écologique
  gg_cls_eco + 
  # Ajout des régions admin, par-dessus pour voir les bordures
  gg_reg_qc


# Afficher la carte 
gg_qc_db +          
  # Change le remplissage pour la palette viridis 
  scale_fill_viridis_d(
    # Ajout d'un titre à la légende 
    guide = guide_legend(title = 'Domaine biologique')
  ) +
  # Thème minimal 
  theme_void()


# Lire les données retravaillées du GRHQ
hq_filt_complete = st_read(
  dsn = 'data/partie_1/hydro/grhq_sud_qc.gpkg', 
  quiet = TRUE
) |> 
  st_transform(crs = projetCRS)


# Lecture du fichier des villes et populations du site d'Ouranos
villes_qc = st_read(
  dsn = 'data/partie_1/villes/villes_qc_ouranos.gpkg',
  quiet = TRUE)

# Afficher le nom des villes au besoin 
# sort(villes_qc$name)

# Vecteur avec le nom des villes 
villes_selection = c('Montréal', 'Québec', 
                     'Gatineau', 'Sherbrooke', 
                     'Saguenay', 'Trois-Rivière', 
                     "Rouyn-Noranda", 
                     'Gaspé', 'Témiscaming', 
                     'Sept-Îles', 'Rimouski')

# Extraction du nom de villes à ajouter sur la carte
villes_qc_lst_flt = villes_qc |> 
  filter(name %in% villes_selection)



# Lire le fichier 
can_bord = st_read(
  dsn = "data/partie_1/admin_geo/admin_reg_can/can_lim.gpkg", 
  quiet = TRUE
)

# Extraire les limites du Québec et de l'Ontario 
qcont_bord = can_bord |> 
  # PRFNOM: Nom de la province ou du territoire, en français.
  filter(PRFNOM %in% c("Québec", "Ontario")) |> 
  # Changer le CRS 
  st_transform(crs = projetCRS) 


# Extraction de l'hydrologie du Québec seulement
hq_filt_qc = hq_filt_complete |>
  # Intersection avec le fichier de l'Ontario et du Québec
  st_intersection(qcont_bord) |> 
  # Garder seulement ce qui se retrouve au Québec
  filter(PRFNOM == "Québec")

# Couche ggplot de l'hydrologie du Québec
gg_hq = geom_sf(
  data = hq_filt_qc, 
  linewidth = 0,
  fill = 'lightblue', # Couleur de l'eau 
  colour = 'lightblue'
)

# Ajout le point des villes 
gg_villes = geom_sf(
  data = villes_qc_lst_flt
)

# Établir le germe aléatoire
set.seed(seed = 12345)


# Faire le graphique de la carte
gg_qc_db = gg_base +
  # Ajout de la classification écologique
  gg_cls_eco + 
  # Ajouter la GRHQ rognée
  gg_hq + 
  # Ajout des régions admin, par-dessus pour voir les bordures
  gg_reg_qc +
  # Ajouter le nom des villes 
  gg_villes + 
  # Ajouter les étiquettes du nom des villes 
  ggrepel::geom_text_repel(
    data = villes_qc_lst_flt, 
    # Définir les étiquettes et les coordonnées spatiales 
    mapping = aes(label = name, 
                  geometry = geometry),
    # Extraction des coordonnées spatiales pour dessiner les étiquettes
    stat = "sf_coordinates", 
    # Taille des étiquettes
    size = 3,
    # Ajout de tampon blanc pour les noms de villes 
    bg.color = "white",
    # Étendue du tampon 
    bg.r = 0.15
  )

# Carte avec thématique 
gg_qc_db + 
  # Change le remplissage pour la palette viridis 
  scale_fill_viridis_d(
    guide = guide_legend(
      title = 'Domaine biologique',
      title.position = "top",
      # Légende en bas
      position = 'bottom',
      # Nombre de rangées pour les étiquettes de la légende 
      nrow = 4,
      # Orientation horizontale
      direction = 'horizontal'
    )
  ) +
  # Thème au minium 
  theme_void() +
  # Changer l'espacement entre les étiquettes de la légende 
  theme(legend.key.spacing.y = unit(x = 0.015, units = "cm"))


# Trouver les limites du Québec en WSG84
bbox_qc_wsg84 = cls_eco_simp |> 
  st_transform(crs = 4326) |> # Ici on transforme de 32198 vers 4326
  st_bbox()


# Boite limite 'bounding box' en epsg:4326 (mètres)
bbox_qc_wsg84

# Extraire la boite limite 'bounding box' en epsg:32198 (mètres)
(bbox_qc = st_bbox(obj = cls_eco_simp))


# Trouver le centre entre xmin et xmax (ou l'étendue longitude du Québec en WSG84)
centre = mean(bbox_qc_wsg84[c('xmin','xmax')])
round(centre, 1) # environ -68.5


# Faire un point fictif au Québec
pts = st_point(x = c(centre, 50.5)) |> 
  # Mettre le CRS 
  st_sfc(crs = 4326) |> 
  # Transformer en epsg:32198
  st_transform(crs = projetCRS) |> 
  # Extraire les coordonnées seulement 
  st_coordinates()


# Remplacer la valeur de la borne supérieure 
bbox_qc[4] <- pts[2]


# Péparation des domaines bioclimatiques pour le Québec méridional
cls_eco_meridional = cls_eco |> 
  st_transform(crs = projetCRS) |> 
  # boite gabarit pour rogner
  st_crop(y = bbox_qc) |> 
  mutate(
    # Calcul de l'aire de chaque polygone des domaines bioclimatiques
    aire_cls_eco = st_area(geom), 
    # Proportion d'aire pour chaque polygone
    # Note : une polygone (NOM_DB == 'Toundra forestière') est 
    # très petit et peut être enlevé sans affecter la visualisation 
    prop = round(aire_cls_eco/sum(aire_cls_eco), 4)*100
    ) |> 
  # Enlever NOM_DB == 'Toundra forestière'
  filter(NOM_DB != "Toundra forestière")

# Péparation/Rogner des régions administratives pour le Québec méridional
regqc_meridional = regqc |> 
  st_transform(crs = projetCRS) |> 
  # boite gabarit pour rogner
  st_crop(y = bbox_qc)


# Domaines biologiques rognés
gg_cls_eco_merid = geom_sf(
  data = cls_eco_meridional,  
  mapping = aes(fill = NOM_DB), # couleur en fonction des domaines biologiques
  alpha = .9,                   # Transparence à 90% 
  linewidth = 0                 # Pas de ligne, plus beau
)

# Régions agministratives rognées 
gg_regqc_merid = geom_sf(
  data = regqc_meridional,  
  fill = NA,                    # Pas de remplissage
  colour = 'grey100',           # Couleur des lignes
  linewidth = 0.05              # Fine ligne
  
)

# Établir le germe aléatoire
set.seed(12345)

# Faire le graphique 
gg_qc_db = gg_base +
  # Domaines biologiques rognés
  gg_cls_eco_merid + 
  # Ajouter la GRHQ rognée
  gg_hq + 
  # Ajout des régions admin, par-dessus pour voir les bordures
  # Régions agministratives rognées 
  gg_regqc_merid + 
  # Ajouter le nom des villes 
  gg_villes + 
  # Ajouter le texte du nom des villes 
  ggrepel::geom_text_repel(
    data = villes_qc_lst_flt, 
    mapping = aes(label = name, 
                  geometry = geometry),
    stat = "sf_coordinates", 
    size = 3,
    # Ajout de fond blanc pour les noms de villes 
    bg.color = "white",
    bg.r = 0.15
  ) +   
  # Change le remplissage pour la palette viridis 
  scale_fill_viridis_d(
    guide = guide_legend(
      title = 'Domaine biologique',
      title.position = "top",
      # Légende en bas
      position = 'bottom',
      # Nombre de rangées pour les étiquettes de la légende 
      nrow = 2,
      # Orientation horizontale
      direction = 'horizontal'
    )
  ) +
  # Thème au minium 
  theme_void() +
  # Changement d'autres paramètres du thème
  theme(
  # Changer l'espacement entre les étiquettes de la légende 
    legend.key.spacing.y = unit(x = 0.015, units = "cm"), 
    # Taille du texte
    legend.text = element_text(size = 7),
    # Taille du titre
    legend.title = element_text(size = 8)
  )

# Afficher la carte
gg_qc_db


# Exportation en PNG
ggsave(
  # Changer l'extension '.png' pour '.pdf' ou '.svg' au besoin. 
  filename = "output/partie_1/carte_domEco_Qc.png", 
  plot = gg_qc_db, 
  width = 6, 
  height = 6, 
  dpi = 300
)


# Mettre les données des points chauds de eBird en mémoire
pts_chauds_ebird = "data/partie_1/biodiv/eBird_hotspots_CA_QC_2025-10-13.csv"

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
ebird_hp_prep = ebird_hp |>  
  # Mettre tableau en format spatial 
  st_as_sf(coords = c('lng', 'lat')) |> 
  # Choisir le CRS 
  st_set_crs(value = 4326) |>  
  # Formatter la colonne de date 
  mutate(
    date_obs_recent = as.POSIXct(
      latestObsDt,
      format="%Y-%m-%d %H:%M",
      tz = Sys.timezone()
    )
  ) |> 
  # Projection du jeu de données selon le CRS du projet 
  st_transform(crs = projetCRS) 


ebird_hp_sf = ebird_hp_prep |> 
  # Nouvelle colonne d'étiquette 
  dplyr::mutate(
    labs = sprintf(
      # Joindre le nom d'un point eBird et le nombre d'espèces.
      fmt = "%s — %s espèces", 
      locName, numSpeciesAllTime)
  )


ebird_hp_sf |> 
  # Application du filtrer 
  filter(numSpeciesAllTime >= 150,           # Nombre d'espèces
         date_obs_recent >= '2020-01-01') |> # Date 
  nrow()


# 20 sites avec vieilles dates de visites (pas de liste eBird depuis ce temps!)
sites_perdus = ebird_hp_sf |> 
  # Étiquette avec l'année d'observation
  dplyr::mutate(yr_last = substr(latestObsDt, 0,4), 
                labs = sprintf(fmt = "%s — %s", yr_last, labs)) |> 
  # Montre les 20 premiers avec les dates les plus petites
  slice_min(order_by = date_obs_recent, 
            n = 20)

# Faire une carte 
mapview(x = sites_perdus, 
        zcol = "yr_last", 
        layer.name = 'Nb Esp.',
        label = "labs")

# Préparation des données simplifier (moins de colonnes)
ebird_hp_sf_simple = ebird_hp_sf |> 
  # Sélection de colonnes pour l'affichage de détail dans la carte 
  dplyr::select(locId, latestObsDt, numSpeciesAllTime, labs) 

# Regarder les points chauds d'observations eBird 
mapview(
  x = ebird_hp_sf_simple, 
  # Ajout de la couleur en fonction du nombre d'espèces vues
  zcol = 'numSpeciesAllTime',  
  label = "labs",
  layer.name = 'Nb Esp.')


ebird_hp_chaud = ebird_hp_sf |> 
  dplyr::filter(numSpeciesAllTime >= 250) |> 
  # Sélection de colonnes pour l'affichage de détail dans la carte 
  dplyr::select(locId, latestObsDt, numSpeciesAllTime, labs)

# Faire la carte 
mapview(
  x = ebird_hp_chaud, 
  zcol = "numSpeciesAllTime", 
  label = "labs",
  labelOptions = leaflet::labelOptions(noHide = FALSE,
                                       opacity = .85, 
                                       textOnly = FALSE),
  layer.name = 'Nb Esp.<br> filtre(>=250)')


ebird_hp_sf_chaud_bio = ebird_hp_sf |> 
  # Sélection de colonnes pour l'affichage de détail dans la carte 
  dplyr::select(locId, latestObsDt, numSpeciesAllTime, labs) |> 
  # Regarder seulement les sites qui ont plus de 150 espèces 
  filter(numSpeciesAllTime >= 150)

mapview(
  x = ebird_hp_sf_chaud_bio, 
  zcol = 'numSpeciesAllTime', 
  label = "labs",
  layer.name = 'Nb Esp.<br> filtre(>=150)')


# Joindre les informations de MRC pour chaque point d'observation eBird
eb_qc = ebird_hp_sf |>  
  st_join(y = regqc_t)


# Exportation des données en géopackage 
st_write(
  obj = eb_qc, 
  dsn = "output/partie_1/site_pub_ebird_MRC.gpkg", 
  delete_dsn = TRUE,
  quiet = TRUE
)


# Donne le top n des sites en fonction du nombre d'espèces vues
eb_qc_topn = eb_qc |>  
  # Groupe par MRC pour faire le sommaire (filtration) 
  group_by(MRS_NM_MRC) |> 
  # Extraire 20 points avec le plus d'espèces d'oiseaux par MRC 
  slice_max(n = 20, 
            order_by = numSpeciesAllTime)


mapview(regqc_t, 
        legend = FALSE, 
        zcol = 'MRS_NM_MRC') + 
  mapview(eb_qc_topn,
          legend = FALSE, 
          cex = 'numSpeciesAllTime',
          zcol = 'MRS_NM_MRC', 
          label = 'locName') 


# Extraire l'emprise spatiale autour de Montréal et Laval 
emprise_region_villes = regqc_t |> 
  filter(MRS_NM_MRC %in% c("Montréal", 'Laval')) |> 
  st_bbox()



# Rogner l'information hydrologique pour cette région 
hq_lvl_mtl = hq_filt_qc |> st_crop(y = emprise_region_villes)
reg_mtl = regqc_t |> st_crop(y = emprise_region_villes)

# Prendre les 20 points les plus élevés en nombre d'espèces pour Montréal et Laval 
eb_qc_topn_lvl_mtl = eb_qc_topn |> 
  filter(MRS_NM_MRC %in% c("Montréal", 'Laval')) 


# Chemin d'accès aux fichiers de réseaux cyclables
res_cycl = "data/partie_1/infrastructure/res_cyclable"
lien_res_cycl_mtl = file.path(res_cycl, 'reseau_cyclable.geojson')
lien_res_cycl_lvl = file.path(res_cycl, 'pistes-cyclables-et-pietonnieres.geojson')

res_cyclable_mtl = st_read(dsn = lien_res_cycl_mtl, quiet = TRUE)
res_cyclable_lvl = st_read(dsn = lien_res_cycl_lvl, quiet = TRUE)


set.seed(123456)
gg_carte_points_inret_ebird = ggplot() + 
  # Polygones des MRCs 
  geom_sf(data = reg_mtl) + 
  # Polygones d'eau
  geom_sf(data = hq_lvl_mtl, fill = 'lightblue') + 
  # Lignes du Réseau cyclable
  geom_sf(data = res_cyclable_mtl, colour = "#A1D998", alpha = .5) + 
  geom_sf(data = res_cyclable_lvl, colour = "#A1D998", alpha = .5) + 
  # Top Points eBirds
  geom_sf(data = eb_qc_topn_lvl_mtl, 
          aes(size = numSpeciesAllTime, 
              shape = MRS_NM_MRC,
              colour = numSpeciesAllTime)) +
  # Texte nom de villes 
  ggrepel::geom_text_repel(data = eb_qc_topn_lvl_mtl, 
                           mapping = aes(label = labs, 
                                         geometry = geometry),
                           stat = "sf_coordinates", 
                           size = 2.25,
                           # Ajout de fond blanc pour les noms de villes 
                           bg.color = "white",
                           bg.r = 0.15) +
  # Couleur des points
  scale_colour_viridis_c() +
  # Thème minimal 
  theme_void() +
  # Ajout de titre aux légendes
  labs(colour = "Nb espèces", 
       size = "Nb espèces",
       shape = "MRC")


gg_carte_points_inret_ebird

