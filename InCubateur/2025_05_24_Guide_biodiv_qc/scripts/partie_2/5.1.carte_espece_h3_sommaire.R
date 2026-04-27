## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
# --> À différentes résolutions H3, Compte 
# --> Exécution automatique des scripts dudckdb pour compter (exportés en Parquet)

## ____________####
## Prépare l'environnement --------

# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")

source(
  file = file.path(
    incub, 
    "scripts/partie_2/5.0.R")
  )

## Prépare scripts bash ----------------------------------------------------
# 2 scripts bash (.sh) sont appelés dans R. Il faut les rendre exécutable
Sys.chmod(scrpt_path, mode = "0755")

## Sommaire biodiv Grille H3 -----------------------------------------------

# Faire tourner pour toutes les résolutions de grilles
for (res_idx in res_numbers) {
  # Change la colonne de résolution
  h3_col <- sprintf("h3_cell_id_%s", res_idx)
  
  message(sprintf("Exécute : %s", h3_col))
  # Chemin d'accès de sortie
  output_path <- file.path(
    incub,
    "data/partie_2/biodiv/gbif_data",
    sprintf(
      "gbif_prep_type_fr_h3_compte_res%s.parquet",
      res_idx
    )
  )
  
  # Exécution du script
  tictoc::tic()
  system2( # system2 pour passer les arguments séparéments
    command = grep(
      pattern = "4.duckdb_compte_h3.sh",
      scrpt_path,
      value = TRUE
    ),
    # Passer les paramètres
    args = c(
      # shQote pour moins gérer des caractères déchappement
      shQuote(input_path),
      shQuote(h3_col),
      shQuote(output_path)
    )
  )
  tictoc::toc()
}
