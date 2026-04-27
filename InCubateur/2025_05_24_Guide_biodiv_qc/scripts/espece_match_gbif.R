## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## #
## Préparation des données d'occurence de biodiversté GBIF
#
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# Date cération : 2026-02-14
# Auteur: Marc-Olivier Beausoleil

## __________####
## LISEZMOI ####

## Objectif :
#  --> Obtenir une liste d'espèces avec les noms commun selon la taxonomie GBIF
#      Permet de joindre les données GBIF avec les données d'autres sources
#  --> Les noms communs '2024_10_wild_sp_common_names_Especes_sauvages_noms_communs.xlsx'
#      de https://www.wildspecies.ca ne contiennent pas tous les noms.
#      Il faut complété avec
#      'Wild_Species_2020_Data_Especes_sauvages_2020_Donnees.xlsx' et
#      la 'LFVQ_17_07_2025.csv' Liste de la faune vertébrée du Québec (LFVQ)

library(dplyr)
library(tidyr)
library(readxl)
library(rgbif)
library(taxize) # https://www.r-bloggers.com/2011/11/use-case-combining-taxize-and-rgbif/

# GBIF :Système mondial d'information sur la biodiversité
# Match la liste d'espèces du Canada avec la liste du 'backbone' taxonomique de GBIF (SMIB)
# L'outil de GBIF 'Species-lookup' https://www.gbif.org/tools/species-lookup
# ne permet pas plus de 6000 espèces et recommande d'utiliser l'API pour faire une
# requête avec beaucoup d'espèces.

# Charge liste d'espèces
# https://www.wildspecies.ca/common-names
esp_sc <- readxl::read_xlsx(
  path = "Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/more/2024_10_wild_sp_common_names_Especes_sauvages_noms_communs.xlsx",
  sheet = "Common names - Noms communs"
)

# Liste de la faune vertébrée du Québec (LFVQ) en CSV
lfvq <- read.csv("Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/more/LFVQ_17_07_2025.csv")

# Obtenir la liste la plus complète (même si pas tous les noms français)
wsc_lst <- readxl::read_xlsx(
  path = "Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/more/Wild_Species_2020_Data_Especes_sauvages_2020_Donnees.xlsx",
  sheet = "Ranks - Rangs"
) |>
  # tidyr::separate(
  #   `TAXONOMIC GROUP - GROUPE TAXONOMIQUE`,
  #   into = c("Type_EN", "Type_FR"),
  #   sep = " - "
  # ) |>
  # Some species names were duplicated
  distinct(`SCIENTIFIC NAME - NOM SCIENTIFIQUE`, .keep_all = TRUE) |>
  filter(!(`SCIENTIFIC NAME - NOM SCIENTIFIQUE` %in% esp_sc$`SCIENTIFIC NAME - NOM SCIENTIFIQUE`)) |>
  dplyr::select(`CODE - CODE`:`SCIENTIFIC NAME - NOM SCIENTIFIQUE`) |>
  left_join(
    y = lfvq |> dplyr::select(Nom_scientifique,
      `NOM COMMUN EN FRANÇAIS` = Nom_francais
    ),
    by = join_by(`SCIENTIFIC NAME - NOM SCIENTIFIQUE` == Nom_scientifique)
  )


# Extraire nom des espèces
# Ajout de 'order' et 'family' pour éviter les faux positifs
df_sp <- esp_sc |>
  bind_rows(wsc_lst) |>
  dplyr::select(
    # Noms scientifiques à chercher
    name = `SCIENTIFIC NAME - NOM SCIENTIFIQUE`,
    # Raffiner la recherche taxonomique avec ordre et famille
    # Probablement pour éviter les faux positifs
    order = `ORDER - ORDRE`,
    family = `FAMILY - FAMILLE`
  ) |>
  dplyr::mutate(
    # Index de 1 au total du nombre de noms d'espèces
    id = row_number()
  )

# rgbif: Match names from the data frame
# Cette fonction tente de trouver les noms fournis
# dans la banque de données de
# 190 sec (pour 50528)
tictoc::tic()
df_matches <- rgbif::name_backbone_checklist(
  df_sp,
  verbose = TRUE
)
tictoc::toc()


# Exploration des noms
df_matches_simple <- df_matches |>
  filter(
    # Retirer les noms alternatifs
    !is_alternative,
    # rank == "SPECIES"
  ) |>
  mutate(
    # Vérification que les noms canoniques sont les mêmes que les noms verbatim
    check = canonicalName == verbatim_name
  )

# Vérification des noms différents de la taxonomie de GBIF
df_matches_simple |>
  select(
    canonicalName, verbatim_name, check
  ) |>
  filter(!check)

df_matches_simple |>
  count(rank)

# Vérification si TOUS les IDs originaux sont dedans le tableau final
# Si oui, == integer(0)
setdiff((df_sp$id), (df_matches_simple$verbatim_index))

# combiner avec données GBIF
#
esp_sc_gbif <- esp_sc |>
  # Ajout de noms manquants
  bind_rows(wsc_lst) |>
  # Ajout des noms GBIF
  left_join(
    df_matches_simple,
    by = join_by(`SCIENTIFIC NAME - NOM SCIENTIFIQUE` == verbatim_name)
  ) |>
  # séparation colonnes de wild species
  tidyr::separate(
    `TAXONOMIC GROUP - GROUPE TAXONOMIQUE`,
    into = c("Type_EN", "Type_FR"),
    sep = " - "
  ) |>
  # Extraire ce qui se trouve entre ""
  mutate(
    desc_fr = stringr::str_extract(`FR JUSTIFICATION FR`, "(?<=\").*(?=\")")
  ) |>
  # Sélection de colonnes
  dplyr::select(
    Type_EN,
    Type_FR,
    nom_sci = `SCIENTIFIC NAME - NOM SCIENTIFIQUE`,
    nom_en = `ENGLISH COMMON NAME`,
    nom_fr = `NOM COMMUN EN FRANÇAIS`,
    species,
    scientificName,
    desc_fr
  )

names(esp_sc_gbif)
head(esp_sc_gbif)



# Exportation
write.csv(
  x = esp_sc_gbif,
  row.names = FALSE,
  file = "output/partie_2/esp_noms_gbif.csv"
)
