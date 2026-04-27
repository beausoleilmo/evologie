## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Toponomie


## ____________####
## Prépare l'environnement --------

topo_names <- sf::st_read(
  dsn = file.path(
    "~/Downloads/canvec_50K_QC_Toponymy_shp/canvec_50K_QC_Toponymy/bdg_named_feature_0.shp"
  ),
  quiet = TRUE
) |>
  st_transform(crs = st_crs(gb_dat)) |>
  filter(dispscl %in% c(1312, 1313, 1314, 1315, 1316)) |>
  st_crop(REG_bbox |>
    st_transform(crs = st_crs(gb_dat)))


topo_names |>
  st_drop_geometry() |>
  count(dispscl)
