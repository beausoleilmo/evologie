## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##
##
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-28
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> 
#   -->

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
    incub, "scripts/partie_2/6.0.load_compte_especes.R"
  ))

# Regarder les données 
hierarchy_counts |> 
  count(class) |> 
  arrange(-n)

hierarchy_counts |> 
  filter(
    class %in% c(
      "Aves", 
      "Mammalia",
      # "Insecta",
      "Testudines",
      "Squamata"))

select_taxa = hierarchy_counts |> 
  filter(
    class %in% c(
      "Aves", 
      "Mammalia",
      "Amphibia",
      # "Insecta",
      # "Arachnida",
      # "Chilopoda",
      # "Diplopoda",
      # "Arthropoda
      # "Malacostraca", order == Isopoda
      "Testudines",
      "Squamata"), 
    order != "Cetacea" | is.na(order)
)

# Voir le nombre d'espèce par groupe 
select_taxa |> 
  group_by(class) |> 
  summarise(sum = sum(n))
# Le nombre d'organismes pour oiseaux et mammifère est très grand.
# Il faut en prendre moins 

min_obs = 25 # Minimum d'observations qui doivent être fait pour être inclue

count_sp |> 
  filter(
    class == "Mammalia", 
    order != "Cetacea",
    n > min_obs
         ) |> 
  arrange(desc(n))

select_sp_noAves = count_sp |>
  filter(
    class %in% c(
      # "Aves", 
      "Mammalia",
      "Amphibia",
      # "Insecta",
      # "Arachnida",
      # "Chilopoda",
      # "Diplopoda",
      # "Arthropoda
      # "Malacostraca", order == Isopoda
      "Testudines",
      "Squamata"), 
    order != "Cetacea" | is.na(order), 
    n > min_obs
  )
nrow(select_sp_noAves)

select_sp_noAves |> 
  mutate(pa = 1 ) |> 
  group_by(class) |> 
  summarise(sum = sum(pa))

top_proportion = 0.4
# Continuer la sélection pour les oiseaux seulement 
select_sp_Aves = count_sp |> 
  filter(
    class == "Aves", 
    n > min_obs * 100 # x fois plus exigeant pour les oiseaux!
    ) |> 
  group_by(family) |> 
  # Garde les données si c'est le top "top_proportion" ou minimum 1 
  filter(min_rank(desc(n)) <= pmax(1, n() * top_proportion)) |>
  arrange(desc(n))


treemap(
  dtf = select_sp_Aves ,
  index = c(
    "order",
    "family", 
    "species"), # The hierarchy levels
  vSize = "n",                     # Area based on the count
  title = "Hiérarchie imbriquée: Oiseaux",
  palette = "Set3")


treemap(
  dtf = select_sp_noAves,
  index = c(
    "class",
    "order",
    "family"), # The hierarchy levels
  vSize = "n",                     # Area based on the count
  title = "Hiérarchie imbriquée: reste",
  palette = "Set3")

# combiner les espèces choisies
select_sp_tout = select_sp_noAves |> 
  bind_rows(select_sp_Aves) |>
  mutate(
    total = rowSums(across(where(is.numeric)), na.rm = TRUE),
    # treemap ne fonctionne pas s'il y a des NA dans 'order'
    order = ifelse(class == "Squamata", yes = "Couleuvres", no = order),
    order = ifelse(class == "Testudines", yes = "Tortues", no = order), 
    # Espèce renommé en 2025! 
    species = recode(species, "Setophaga petechia" = "Setophaga aestiva")
  )  

select_sp_tout |> 
  group_by(class) |> 
  mutate(
    pa = 1
  ) |> 
  summarise(sum = sum(pa)) |> 
  pivot_wider(names_from = class, values_from = sum)

