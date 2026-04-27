## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-29
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   -->
#   -->


source(
  file = file.path(incub, "scripts/partie_2/5.0.R")
)

# Liste d'espèces avec Type_FR
# source("Incubateur/2025_05_24_Guide_biodiv_qc/scripts/partie_2/0.1_charge_donnees_sp_nm.R")

# Charger région pour carto
source(
  file = file.path(
    incub, "scripts/partie_2/0.1.charge_donn/0.1_charge_donnees_regions.R"))
# Points eBird
source(
  file = file.path(
    incub, "scripts/partie_2/0.1.charge_donn/0.1_charge_donnees_ebirdHS.R"))

# données hydrologiques du Québec
hpol = st_read(
  dsn = file.path(
    "~/Github_proj/evologie",
    "posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc/",
    "data/partie_1/hydro/grhq_sud_qc.gpkg"
  )
)


# Choisir une résolution entre 6 et 9
res_h3 <- 7
# Voir 5.1
TYPE_FCT_LIST <- c("Oiseaux")
REGION_SEL_LIST = unique(regqc$MRS_NM_REG)


tictoc::tic() # res 9 = 1 sec
gb_compte <- st_read(
  dsn = file.path(
    incub,
    "data/partie_2/biodiv/gbif_data",
    sprintf("gbif_prep_type_fr_h3_compte_somme_res%s.parquet", res_h3)
  )
) |>
  # Colonne avec les type_FR en ordre
  mutate(
    tax_gr = factor(Type_FR, TYPE_FCT_LIST)
  )

tictoc::toc()


# Nombre de type
nb_type <- length(unique(gb_compte$Type_FR))


# Filtre région au besoin
reg_sel_spatial <- regqc |>
  dplyr::filter(MRS_NM_REG %in% REGION_SEL_LIST) |>
  st_simplify(dTolerance = 1e2)

# Filtre les points eBirds pour la région sélectionnée
ebird_hp_sf_reg <- ebird_hp_sf |>
  st_filter(reg_sel_spatial)

## ____________####
## Gg_map --------

reg_idx = 17
reg_sel = REGION_SEL_LIST[reg_idx]
reg_sel_map = reg_sel_spatial |> 
  filter(MRS_NM_REG == reg_sel)

reg_bbox = reg_sel_map |> 
  st_buffer(dist = 1e4) |> 
  st_transform(crs = 4326) |> 
  st_bbox()

pt_lab = reg_sel_map |>
  st_union() |> 
  st_centroid()



# Afficher une carte pour une région seulement
gb_compte |>
  ggplot() +
  # Ajout des limites régionales (chaque MRC)
  geom_sf(
    data = reg_sel_spatial,
    fill = rep(
      viridis::inferno(
        n = length(
          reg_sel_spatial |>
            pull(MRS_NM_MRC)
        ),
        alpha = .2
      ),
      nb_type
    ),
    # Pas de ligne 
    linewidth = 0,
    inherit.aes = FALSE
  ) +
  geom_sf(
    data = reg_sel_map,
    # Pas de ligne 
    linewidth = 2,
    inherit.aes = FALSE
  ) +
  geom_sf(
    data = hpol,
    fill = "lightblue",
    # Pas de ligne 
    linewidth = 0,
    inherit.aes = FALSE
  ) +
  # Séparation des données par groupe
  facet_wrap(. ~ tax_gr, ncol = 2) +
  # Ajout des hexagones
  geom_sf(
    mapping = aes(fill = log_n),
    colour = NA
  ) +
  # Points eBirds
  # geom_sf(
  #   data = ebird_hp_sf_reg,
  #   mapping = aes(colour = numSpeciesAllTime),
  #   size = 2
  # ) +
  # Ajout des étiquettes
  # geom_sf_label(
  #   data = reg_sel_spatial,
  #   aes(label = MRS_NM_MRC),
  #   fun.geometry = sf::st_centroid, # Forces the label to the center of the polygon
  #   size = 2,
  #   color = "grey0",
  #   alpha = 0.8
  # ) +
  # Ajoute contour par dessus les hexagones
  geom_sf(
    data = reg_sel_spatial,
    fill = NA,
    colour = scales::alpha(
      "grey0",
      alpha = 1
    ),
    linewidth = 0.3,
    inherit.aes = FALSE
  ) +
  # Ajout d'étiquette sur carte 
  geom_sf_label(
    data = pt_lab,
    aes(label = REGION_SEL_LIST[reg_idx]),
    inherit.aes = FALSE
  ) +
  # Couleur des hexagones
  scale_fill_viridis_c() +
  scale_colour_viridis_c(option = "inferno", alpha = .6) +
  # Thème avec rien pour la carto
  theme_void() +
  # Ajout de quelques trucs pour la légende et l'apparence des titres de cartes
  theme(
    legend.position = "bottom",
    # Change background color of the strip
    strip.background = element_rect(fill = "white", color = "white", linewidth = 0.5, linetype = "solid"),
    # Align text to the left within the strip box
    strip.text = element_text(hjust = 0, color = "black", face = "plain", size = 10)
  ) +
  labs(
    title = sprintf(
      "Région : %s \nRésolution H3 : %s",
      reg_sel, # "toutes", # region_sel,
      res_h3
    )
  ) + 
  coord_sf(
    xlim = c(reg_bbox["xmin"], reg_bbox["xmax"]),
    ylim = c(reg_bbox["ymin"], reg_bbox["ymax"]),
    expand = TRUE # Zoom avec espace autour
  )

## ____________####
## Carte interactive --------

gb_h3pol_oi <- gb_compte |>
  filter(Type_FR == "Oiseaux")

# Polygones biodiversité
mapview::mapview(gb_h3pol_oi, zcol = "log_n", label = "n") +
  # Ajout des régions
  mapview::mapview(regqc,
                   zcol = "MRS_NM_MRC",
                   col.regions = viridis::cividis(n = nrow(reg_sel_spatial)),
                   legend = FALSE
  ) +
  # Points eBird
  mapview::mapview(ebird_hp_sf,
                   zcol = "numSpeciesAllTime",
                   label = "labs",
                   legend = FALSE, col.regions = viridis::inferno(n = nrow(ebird_hp_sf_reg))
  )
