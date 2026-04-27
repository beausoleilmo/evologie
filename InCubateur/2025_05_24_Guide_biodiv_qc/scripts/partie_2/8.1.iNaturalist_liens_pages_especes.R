## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Définition de fonction supplémentaire pour exécuter les scripts
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-27
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Extraire photos d'iNaturalist pour le guide

## ____________####
## Prépare l'environnement --------

library(dplyr)
library(httr)
library(jsonlite)
library(purrr)
library(rinat)

# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")

source(
  file = file.path(
    "~/Github_proj/evologie/posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc",
    "scripts/00_init/functions.R"
  )
)

# Pour le Québec au complet 
source(
  file = file.path(
    incub, "scripts/partie_2/7.selection_especes.R"
  )
)

# Pour chaque région 
source(
  file = file.path(
    incub, "scripts/partie_2/7.selection_especes_region.R"
  )
)



# Liste d'espèces
sp_list = # Espèces unique 
  select_sp_tout |> 
  distinct(species)


### Extraire données d'espèces (ID) iNaturalist ----------------------------------
sp_rec = NULL
max_it = nrow(sp_list)
attendre_i = 10
nb_requete = 25
tail(sp_rec)
# Fails at about 266, restart manual 
for (sp_idx in 1:max_it) {
  message(sprintf("%s/%03d (%02d %%)", 
                  formatC(sp_idx, width = 3, flag = " "),
                  max_it , 
                  round(sp_idx/max_it*100, 0)))
  # Tous les 'nb_requete' requêtes, attendre 'attendre_i' secondes
  # Pour ne pas trop en demander au serveur de iNaturalist 
  if (sp_idx %% nb_requete == 0) {
    message(sprintf(
      fmt = "Done %s. Wait %s s.", 
      sp_idx, 
      attendre_i
    ))
    Sys.sleep(time = attendre_i)
  }
  nom_sp = sp_list[sp_idx,"species"]
  sptmp = getTaxonInfo(taxon = nom_sp, wait = attendre_i)
  
  sp_rec = rbind(sp_rec, data.frame(nom_sp, as.data.frame(sptmp)))
}


# Ajoute l'ID d'espèce 
# Pas le même que ID D'OBSERVATION!
sp_list_fil = select_sp_tout |> 
  left_join(
    y = sp_rec, 
    by = join_by(species == nom_sp), 
    relationship = "many-to-many")

## ____________####
## Exporter données --------
readr::write_excel_csv2(
  x = sp_rec, 
  file = file.path(
    incub,
    "output/partie_2/sp_list_fil_iNat.csv"
  )
)
