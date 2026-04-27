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

# Règne à sélectionner
KINGDOM_SEL <- "Animalia"
# Type d'organisme
TYPE_FCT_LIST <- c("Oiseaux")
# Sélection de régions (toutes)
REGION_SEL_LIST <- regqc |>
  st_drop_geometry() |>
  distinct(MRS_NM_REG) |>
  pull(MRS_NM_REG)


for (res_idx in numbers) {
  input_path <- file.path(
    incub,
    "data/partie_2/biodiv/gbif_data",
    sprintf(
      "gbif_prep_type_fr_h3_compte_res%s.parquet",
      res_idx
    )
  )
  
  # Change la colonne de résolution
  h3_col <- sprintf("h3_cell_id_%s", res_idx)
  
  # Chemin d'accès de sortie
  output_path <- file.path(
    incub,
    "data/partie_2/biodiv/gbif_data",
    sprintf(
      "gbif_prep_type_fr_h3_compte_somme_res%s.parquet",
      res_idx
    )
  )
  
  # Exécution du script
  tictoc::tic()
  system2(
    command = grep(
      pattern = "4.duckdb_compte_h3_somme.sh",
      scrpt_path,
      value = TRUE
    ),
    args = c(
      shQuote(input_path),
      shQuote(h3_col),
      shQuote(output_path),
      shQuote(KINGDOM_SEL),
      shQuote(
        paste0(sprintf("\'%s\'", REGION_SEL_LIST), collapse = ", ")
      ),
      shQuote(
        paste0(sprintf("\'%s\'", TYPE_FCT_LIST), collapse = ", ")
      )
    )
  )
  tictoc::toc()
}
