require(dplyr)
require(DBI)
require(duckdb)
## Compte d'observation PAR espèces

# OBSERVATIONS 
# count_nb_obs_sp (voir commande duckdb plus bas) :
# On voit le biais d'observation de certains groupes d'organismes (oiseaux)
# Une visualisation en LOG serait meilleure

# Fichier des points GBIF ! 
file.raw = file.path(
  incub,
  "data/partie_2/biodiv/gbif_data/",
  "gbif_prep_type_fr_h3.parquet"
)

# Met emphase sur le NOMBRE *D'OBSERVATION* UNIQUE POUR CHAQUR ESPÈCES
count_nb_obs_sp = sprintf(
  "SELECT 
     kingdom, phylum, class, \"order\", family, 
     species, count(species) as n 
   FROM 
     '%s'
    GROUP BY ALL
    ORDER BY 
      kingdom, phylum, class, \"order\", family, species, n desc",
  file.raw
)

### Exécution de la commande 
# Connecte à duckdb
con <- DBI::dbConnect(duckdb())
# Lire les informations
count_sp <- DBI::dbGetQuery(
  conn = con, 
  statement = count_nb_obs_sp
)
# Fermer duckdb
dbDisconnect(con)

## Compte hiérarchique du nombre d'espèces unique (sommaire
# du NB d'espèce observées dans chaque famille). 
hierarchy_counts <- count_sp |>
  # Correction de classe 
  mutate(
    # Reclassification nécessaire pour éviter d'avoir 
    # des duplicats dans class et ordre
    class = if_else(
      class == "Diplura", 
      true = "Entognatha", 
      false = class)
  ) |> 
  select(-c(n, species)) |> 
  group_by_all() |> 
  count() |>
  mutate(
    pa = 1
  ) |> 
  ungroup()


