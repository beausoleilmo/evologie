require(dplyr)
require(DBI)
require(duckdb)
## Compte d'observation PAR espèces

# OBSERVATIONS 
# compte le nombre d'observation par d'espèce par région 

# Fichier des points GBIF ! 
file.raw = file.path(
  incub,
  "data/partie_2/biodiv/gbif_data/",
  "gbif_prep_type_fr_h3.parquet"
)

#' Query Species Observation Counts from Parquet
#' @param file_path Path to the .parquet file
#' @return A data frame with the aggregated results
get_sp_reg_counts <- function(file_path) {
  
  # Connection DuckDB
  con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  
  # Quand quitte la fonction "on.exit" fermme duckdb 
  on.exit(dbDisconnect(con, shutdown = TRUE))
  
# Requête 
  query <- sprintf("
    SELECT 
      kingdom, phylum, class, \"order\", family, 
      -- MRS_NM_MRC, 
      MRS_NM_REG,
      species, count(species) as n 
    FROM 
      '%s'
    GROUP BY ALL
    ORDER BY 
      kingdom, phylum, class, \"order\", family, species, 
      -- MRS_NM_MRC, 
      MRS_NM_REG, 
      n DESC;
  ", file_path)
  
  # Exécute requête 
  result <- dbGetQuery(con, query)
  return(result)
}