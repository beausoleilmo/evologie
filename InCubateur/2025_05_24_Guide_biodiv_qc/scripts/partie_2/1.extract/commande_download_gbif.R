## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> https://data-blog.gbif.org/post/apache-arrow-and-parquet/


## ____________####
## Prépare l'environnement --------

library(rgbif)
library(jsonlite)

# usethis::edit_r_environ()
# Mettre vos identifiant, voir https://docs.ropensci.org/rgbif/articles/gbif_credentials.html
# GBIF_USER="username"
# GBIF_PWD="safe_fake_password_123"
# GBIF_EMAIL="username@gbif.org"

# Mettre le fichier en mémoire avec la modification 
readRenviron("~/.Renviron")

# Script simplification des régions administratives du Québec 
source(file.path(
  incub, 
  "scripts/partie_2/1.extract/0.1_gbif_polygon_filter_occurences.R"
))

# Polygon doit être en ordre 'sens-des-aiguilles-montre' ou CW 
# pol_lim_qc = "POLYGON ((-79.18661 45.737, -74.17295 44.31865, -70.35774 44.65409, -68.86137 46.63709, -66.34416 47.35701, -64.336 47.45411, -62.5469 46.18651, -60.70562 46.36289, -55.83659 52.00987, -58.17867 53.37907, -63.63169 53.63143, -65.16292 53.0203, -66.31831 54.06506, -63.23293 54.00381, -62.17406 55.19059, -62.17351 58.8368, -63.60196 60.7996, -65.65498 60.91404, -67.4021 59.34233, -68.36592 61.4554, -72.96321 63.06364, -79.32995 62.70702, -79.87082 58.54605, -77.77697 56.47879, -80.92362 54.72415, -79.81893 52.32097, -80.43478 47.07494, -79.18661 45.737))"
pol_lim_qc = pol_wkt

# Visualisation du polyogne 
# mapview(st_as_sfc(pol_lim_qc, crs = 4326))

# 3. Send the download request to GBIF
download_key <- occ_download(
  # body = request_body, 
  pred("OCCURRENCE_STATUS", "present"),
  pred_in("BASIS_OF_RECORD", c("MACHINE_OBSERVATION", "HUMAN_OBSERVATION")),
  pred_within(
    pol_lim_qc
  ),
# Use the format "SIMPLE_PARQUET" for the parquet file format
  format = "SIMPLE_PARQUET"
)

# 4. Check status (optional)
occ_download_wait(download_key)

download_path <- occ_download_get(
  key = download_key[1], 
  path = '/Volumes/g_magni/gbif_data/',  
  overwrite = TRUE
  )
# "/Volumes/g_magni/gbif_data/0040587-260226173443078.zip"
# "/Volumes/g_magni/gbif_data/occurrence.parquet"

dwnlGBIF = tools::file_path_sans_ext(basename(
  download_path[1]
))
new_name = sprintf("/Volumes/g_magni/gbif_data/%s.parquet",
                   dwnlGBIF
                   )
file.rename(
  from = "/Volumes/g_magni/gbif_data/occurrence.parquet", 
  to = new_name
)

# Vérification si fichier de taille 0 
# devant être retiré 
zero_size = file.info(list.files(new_name, full.names = T)) |> 
  dplyr::filter(size == 0)

if (nrow(zero_size)>0) {
  path_file = row.names(zero_size)
  
  archive_folder = file.path(
    dirname(dirname(path_file)), 
    sprintf("%s_archive",
            dwnlGBIF
    )
  )

  dir.create(
    path =   archive_folder
  )
  
  file.rename(from = path_file,  to = file.path(archive_folder, basename(path_file)))
  
}


# request_prep <- occ_download_prep(
#   pred("OCCURRENCE_STATUS", "present"),
#   pred_in("BASIS_OF_RECORD", c("MACHINE_OBSERVATION", "HUMAN_OBSERVATION")),
#   pred_within(
#     pol_lim_qc
#     ),
#   format = "SIMPLE_PARQUET"
# )
