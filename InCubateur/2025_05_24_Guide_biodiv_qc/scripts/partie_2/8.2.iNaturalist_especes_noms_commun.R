## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Définition de fonction supplémentaire pour exécuter les scripts
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-28
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Extraire photos d'iNaturalist pour le guide

## ____________####
## Prépare l'environnement --------

# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")

library(dplyr)
library(rinat)
library(httr)
library(jsonlite)

source(file = file.path(
  "~/Github_proj/evologie/posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc/scripts/00_init/functions.R"
))

# Pour chaque région 
source(
  file = file.path(
    incub, "scripts/partie_2/7.selection_especes_region.R"
  )
)


# Lire la liste d'espèces et de photos iNaturalist
sp_rec2 = read.csv2(
  file = file.path(
    incub,
    "output/partie_2/sp_list_fil_iNat.csv"
  )
)

### Téléchargement des images 'Typiques' de iNaturalist ---------------------

# Liste des noms français de noms d'espèces provenant d'iNaturalist
sp_nm_df = NULL
attente_i = 10
nb_requete = 15

for (sp_nm_idx in 1:nrow(sp_rec2)) {
  message(
    sprintf("%03d/%03d (%02d %%)", 
            sp_nm_idx, 
            nrow(sp_rec2) ,  
            round(sp_nm_idx/nrow(sp_rec2)*100, 0)
    )
  )
  
  sp_nm = sp_rec2$nom_sp[sp_nm_idx]
  
  # Attente pour ne pas surcharger le serveur 
  Sys.sleep(time = 0.1)
  
  fr_nm = readTaxonFR(
    taxon = sp_rec2$id[sp_nm_idx], 
    wait = attente_i)
  
  sp_nm_df = rbind(
    sp_nm_df, 
    data.frame(
      species = sp_nm, 
      fr_nm = fr_nm))
  
  # Tous les 'nb_requete' requêtes, attendre 'attente_i' secondes
  # Pour ne pas trop en demander au serveur de iNaturalist 
  if (sp_nm_idx %% nb_requete == 0) {
    message(sprintf(
      fmt = "Done %s. Wait %s s", 
      sp_nm_idx,
      attente_i
    ))
    Sys.sleep(time = attente_i)
  }
}


# Mettre la première lettre en majuscule
# Pattern: Find a lowercase letter ([a-z]) that is preceded by 
# either the start of the string (^) OR a semicolon (;)
sp_nm_df$fr_nm <- gsub(
  pattern = "(^|;)([a-z])", 
  replacement = "\\1\\U\\2", 
  x = sp_nm_df$fr_nm, 
  perl = TRUE)


# Joindre la liste d'espèces et les noms français des espèces 
sp_list_nom_fr = select_sp_tout |> 
  left_join(
    y = sp_rec2,
    by =  join_by(species == nom_sp), 
    relationship = "many-to-many"
  ) |> 
  left_join(
    y = sp_nm_df,
    by =  join_by(species),
    relationship = "many-to-many"
  )

## ____________####
## Exporter données --------
readr::write_excel_csv2(
  x = sp_list_nom_fr, 
  file = file.path(
    incub,
    "output/partie_2/sp_list_fil_iNat_nomFR.csv"
  )
)

# Exporter les noms français d'iNaturalist
readr::write_excel_csv2(
  x = sp_nm_df, 
  file = file.path(
    incub,
    "output/partie_2/sp_nm_df.csv"
  )
)
