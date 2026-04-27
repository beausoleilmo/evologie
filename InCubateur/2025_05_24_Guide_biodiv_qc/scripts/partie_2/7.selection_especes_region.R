## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-28
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> Sélection d'espèces par région
#   --> Un nombre d'observation minimales est requis pour être gardé
#   --> Pour les oiseaux :
#         nombre d'observation minimales requis
#         sélection par proportion de chaque famille (avec boucle while)
#   --> Combiner les données

# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")

# Initialise les
source(file = file.path(
  incub, "scripts/partie_2/0.init/0.0.init.R"
))


### duckdb cmd : extraire info sommaire  -------------
# Charge les données
source(
  file = file.path(
    incub, "scripts/partie_2/6.0.load_compte_especes_reg.R"
  )
)


# Nb observations Espèce par région
count_sp <- get_sp_reg_counts(file.raw) |>
  # Correction de classe
  mutate(
    # Reclassification nécessaire pour éviter d'avoir
    # des duplicats dans class et ordre
    class = if_else(
      class == "Diplura",
      true = "Entognatha",
      false = class
    ),
    pa = 1
  )

# Minimum d'observations
# qui doivent être fait pour être inclue
# Cela aide à éviter d'avoir trop d'observations erronées
min_obs <- 10

# Extraire compte observations (avec minimum) pour
# les organismes qui ne sont pas des oiseaux
select_sp_noAves <- count_sp |>
  filter(
    class %in% c(
      # "Insecta", "Arachnida", "Chilopoda", "Diplopoda", "Arthropoda, "Malacostraca", # order == Isopoda
      # "Aves",
      "Mammalia", "Amphibia",
      "Testudines", "Squamata"
    ),
    order != "Cetacea" | is.na(order),
    n >= min_obs
  )

select_sp_noAves |>
  mutate(pa = 1) |>
  group_by(
    MRS_NM_REG,
    # MRS_NM_MRC,
    class
  ) |>
  summarise(sum = sum(pa)) |>
  pivot_wider(names_from = class, values_from = sum)


# Fonction pour augmenter la précision à chaque itération
# Utilisation de w (compteur) comme valeur qui va augmenter la précision
more_prec <- function(x) {
  m1 <- 2 * (1 / x) / 10 # 2* pour aller plus vite (faster decay)
  m2 <- exp(-x)
  m3 <- (x + 1)^-2
  # m4 = -log(x)
  # m5 = -sqrt(x)
  return(list(
    m1 = m1, m2 = m2,
    m3 = m3
  ))
}

reg_prop <- count_sp |>
  distinct(MRS_NM_REG) |>
  mutate(prop = 1)
w <- 1 # Compte pour la boucle while
min_obs_aves <- 100 # Minimum d'observations nécessaire pour gader une espèce
nb_esp_niveau <- 120 # Nombre d'espèce cible à garder
iter_rec <- NULL

# Boucle pour filtrer de plus en plus finement les données
# afin d'avoir un nombre d'oiseaux par région
while (TRUE) {
  # Continuer la sélection pour les oiseaux seulement
  select_sp_Aves <- count_sp |>
    filter(
      class == "Aves",
      n > min_obs_aves
    ) |>
    left_join(
      y = reg_prop,
      by = join_by(MRS_NM_REG)
    ) |>
    # Garder un nombre d'espèce par famille (proportion)
    group_by(MRS_NM_REG, family) |>
    # Garde les données si c'est le top "top_proportion" ou minimum 1
    filter(
      min_rank(desc(n)) <= pmax(1, n() * prop)
    ) |>
    arrange(desc(n))

  # Compte ce qui reste d'espèces après filtration
  aves_count <- select_sp_Aves |>
    group_by(MRS_NM_REG) |>
    summarise(sum = sum(pa))

  # enregistrer le processus de filtration
  if (w == 1) {
    iter_rec <- bind_cols(iter_rec, aves_count)
  } else {
    iter_rec <- bind_cols(iter_rec, aves_count |> select(-MRS_NM_REG))
  }

  # print(aves_count)
  print(more_prec(w)[["m1"]])

  # Extraire région qui n'ont pas atteint le nombre d'espèces espéré
  reg_to_update <- aves_count |>
    # touver les régions qui ont plus de 'nb_esp_niveau'
    mutate(prop_update = sum >= nb_esp_niveau) |>
    filter(prop_update) |>
    pull(MRS_NM_REG)

  # S'il reste rien, quitter la boucle
  if (length(reg_to_update) == 0) {
    break
  }

  # Mettre à jour le tableau de proportion pour
  reg_prop <- reg_prop |>
    mutate(prop = ifelse(
      test = MRS_NM_REG %in% reg_to_update,
      # Diminution de la précision à chaque coup
      # pour filtrer plus précisément
      yes = prop - more_prec(w)[["m1"]],
      no = prop
    ))

  # Augmente le compteur de 1
  w <- w + 1
}

select_sp_Aves

# Treemaps ----------------------------------------------------------------

reg_lst <- unique(select_sp_Aves$MRS_NM_REG)

reg_sel <- reg_lst[5]

treemap(
  dtf = select_sp_Aves |>
    filter(MRS_NM_REG %in% reg_sel),
  index = c(
    "order",
    "family",
    "species"
  ),
  vSize = "n",
  title = sprintf("Hiérarchie imbriquée: Oiseaux. Reg : %s", reg_sel),
  palette = "Set3"
)


treemap(
  dtf = select_sp_noAves |>
    filter(MRS_NM_REG %in% reg_sel),
  index = c(
    "class",
    "order",
    "family"
  ),
  vSize = "n",
  title = sprintf("Hiérarchie imbriquée: rest Reg : %s", reg_sel),
  palette = "Set3"
)


# Compte final d'espèce ---------------------------------------------------
# Voir le nombre d'espèce par groupe
count_sp |>
  filter(
    class %in% c("Aves", "Mammalia", "Amphibia", "Testudines", "Squamata"),
    order != "Cetacea" | is.na(order)
  ) |>
  group_by(
    MRS_NM_REG,
    # MRS_NM_MRC,
    class
  ) |>
  summarise(sum = sum(pa)) |>
  pivot_wider(
    names_from = class,
    values_from = sum, 
    names_sort = TRUE)
# Certaines régions n'ont pas de tortues!

# combiner les espèces choisies
select_sp_tout <- select_sp_noAves |>
  bind_rows(select_sp_Aves) |>
  mutate(
    total = rowSums(across(where(is.numeric)), na.rm = TRUE),
    # treemap ne fonctionne pas s'il y a des NA dans 'order'
    order = ifelse(class == "Squamata", yes = "Couleuvres", no = order),
    order = ifelse(class == "Testudines", yes = "Tortues", no = order), 
  # Espèce renommé en 2025! 
    species = recode(species, "Setophaga petechia" = "Setophaga aestiva")
  )  


# Tableau large du nombre d'espèces dans chaque Classes par région
select_sp_tout |>
  group_by(
    MRS_NM_REG,
    # MRS_NM_MRC,
    class
  ) |>
  summarise(sum = sum(pa)) |>
  pivot_wider(
    names_from = class,
    values_from = sum, names_sort = TRUE
  ) 

reg_lst <- unique(select_sp_Aves$MRS_NM_REG)

# for (reg_sel in reg_lst) {
#   for (class_sel in list("Aves", c("Mammalia", "Amphibia", "Testudines", "Squamata"))
#   ) {
#     if (all(class_sel %in% "Aves")) {
#       class_name <- "oiseaux"
#       idx <- c(
#         # "class",
#         "order",
#         "family",
#         "species"
#       )
#     } else {
#       class_name <- "reste"
#       idx <- c(
#         "class",
#         "order",
#         "family",
#         "species"
#       )
#     }
#     png(
#       filename = sprintf(
#         "InCubateur/2025_05_24_Guide_biodiv_qc/output/partie_2/plot_%s_%s.png",
#         class_name,
#         reg_sel
#       ),
#       width = 10, height = 8, units = "in", res = 300
#     )
#     treemap(
#       dtf = select_sp_tout |>
#         filter(
#           MRS_NM_REG %in% reg_sel,
#           class %in% class_sel
#         ),
#       index = idx,
#       vSize = "n",
#       title = sprintf("Hiérarchie imbriquée: %s Reg : %s", class_name, reg_sel),
#       palette = "Set3"
#     )
#     dev.off()
#   }
# }