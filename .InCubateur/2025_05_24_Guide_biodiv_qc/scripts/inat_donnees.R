## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Préparation des données de biodiversité (GBIF)
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2025-09-11
# auteur: Marc-Olivier Beausoleil

#### ____________####
#### Lisez-moi --------
#   --> 


# Charger les progiciels --------------------------------------------------
library(duckdb) # Pour se connecter avec un pilote duckDB (C'est la même chose que d'aller dans le terminal et exécuter 'duckdb')
library(DBI) # Database (DB) interface (I). 
library(dplyr) # Manipulation de données 
library(dbplyr) # Manipulation de bases de données 
library(tidyr) # pour gather
library(purrr) # pour map
library(stringr) # pour str_c
library(terra) # pour les images matricielles
library(viridisLite) # Palette de couleur viridis 


# Démarrer duckDB ---------------------------------------------------------
# Se connecter à une session duckDB 
con <- dbConnect(duckdb())

# Exploration données iNaturalist -----------------------------------------
# Lire les données fitrés 
# inat_dat = read.csv(file = '.InCubateur/2025_05_24_Guide_biodiv_qc/data/gbif_data/inat_research_grade_obs.csv')
inat_csv = 'data/partie_2/biodiv/gbif_data/inat_research_grade_obs.csv'

cmd = sprintf("CREATE VIEW ginat AS SELECT * FROM read_csv('%s')", inat_csv)
DBI::dbExecute(conn = con, 
               statement = cmd)
# dbReadTable(con, "ginat")
inat_dat = tbl(con, "ginat")
# dbDisconnect(con)

# gbif_csv = duckdb_read_csv(conn = con,
#                            name = "test",
#                            files = '.InCubateur/2025_05_24_Guide_biodiv_qc/data/gbif_data/inat_test.csv',
#                            delim = ",",
#                            header = TRUE)


# strsplit(x = unique(inat_dat$issue), split = ';') |> 
#   unlist() |>  unique() |> dput()
# c("COORDINATE_ROUNDED", "CONTINENT_DERIVED_FROM_COORDINATES", 
#   "TAXON_ID_NOT_FOUND", "COUNTRY_COORDINATE_MISMATCH", "TAXON_MATCH_HIGHERRANK", 
#   "TAXON_MATCH_FUZZY", "COORDINATE_UNCERTAINTY_METERS_INVALID", 
#   "MULTIMEDIA_URI_INVALID", "MULTIMEDIA_DATE_INVALID", "COUNTRY_DERIVED_FROM_COORDINATES"
# )

# inat_dat |> 
#   filter(grepl(pattern = 'TAXON_ID_NOT_FOUND', x = issue))

# Des fois, les informations dans GBIF ont des 'problèmes' nommées 'issue'. 
# Nous pouvons regarder le nombre de 'issue' 
inat_dat |>  
  count(issue) |> 
  arrange(-n)
# En fait, il y a des problèmes partout...
# Pour nous c'est vraiment pas un problème 

# Les données ont été filtrés pour garder les taxonRankce qui sont de l'espèce et plus précis
inat_dat |> 
  count(taxonRank)

# Nous pouvons compter différentes informations
# Voir les règnes dans les données 
inat_dat |> 
  count(kingdom) |>
  collect() |> 
  arrange(n)

# Préparation du jeu de données iNaturalist
inat_dat_tax = inat_dat |> 
  filter((kingdom %in% c('Animalia'))) |> 
  count(kingdom, phylum, class, order, species) |> 
  arrange(kingdom, phylum, class, order, -n) |>  
  collect()

# Biodiversité en lumière -------------------------------------------------
# Faire la lumière sur la biodiversité : 
# une carte de biodiversité avec GBIF 

# Pour faire une carte, on arrondi les coordonnées 
df <- inat_dat |> 
  # Arrondir les coordonnées 2: si à l'échelle du Québec, sinon, 
  # 3: à l'échelle d'une MRC. plus haut est trop long à calculer 
  # 4: Error: [raster,matrix(xyz)] x cell sizes are not regular
  mutate(latitude = round(decimalLatitude, 2),
         longitude = round(decimalLongitude, 2)) |> 
  count(longitude, latitude) |> 
  collect() |> 
  mutate(n = log(n))


r <- rast(df, crs="epsg:4326") |> 
  # Rogner pour le sud du Québec 
  crop(y = ext(-79.76288, -57.10750, 44.99136,  50.5 )) |> 
  # reprojection pour le Québec 
  project(y = 'epsg:32198')


# Afficher la 'densité' d'observation au Québec 
# Voir pour le Québec (pour round = 2 decimal)
plot(r, 
     col = viridis(1e3), 
     legend=FALSE, maxcell=6e6, 
     colNA="black", axes=FALSE)

# Zoom dans le sud du Québec (pour round = 2 decimal)
plot(r, 
     xlim = c(-700000, 0),
     ylim = c(111024, 392779.9),
     col = viridis(1e3), 
     legend=FALSE, maxcell=6e6, 
     colNA="black", axes=FALSE)
# Voir pour Montréal (pour round = 3 decimal)
plot(r, 
     xlim = c(-430000, -3.8e5),
     ylim = c(170000, 205000),
     col = viridis(1e3), 
     legend=FALSE, maxcell=6e6, 
     colNA="grey30", axes=T)
