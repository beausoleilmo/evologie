# Prépare le chemin d'accès
incub <- file.path("Incubateur/2025_05_24_Guide_biodiv_qc")


sp_list_fil_nom_fr = read.csv2(
  file = file.path(
    incub,
    "output/partie_2/sp_list_fil_iNat_nomFR.csv"
  )
)

# Voir les données AVONET au lien https://figshare.com/s/b990722d72a26b5bfead (voir aussi l'article qui explique le jeu de données)
amniotes_traits = read.csv(
  file = file.path(
    incub, 
    "data/partie_3/traits/amniote/Amniote_Database_Aug_2015.csv"
  ),
  na.strings = -999)

amphi_traits = read.csv(
  file = file.path(
    incub, 
    "data/partie_3/traits/amphiBIO/AmphiBIO_v1/AmphiBIO_v1.csv"
  )) |> 
  mutate(source ="AmphiBIO") |> 
  dplyr::select(Species, Body_mass_g,  Body_size_mm)

# Tolérance pour décrire un dimorphisme 
percent_diff_tol = 0.10
amniotes_traits_dimor = amniotes_traits |> 
  mutate(
    dimorphisme_g = (male_body_mass_g-female_body_mass_g), 
    sp_names = sprintf('%s %s', genus, species)) |> 
  group_by(sp_names) |> 
  mutate(
    # Calcul pourcentage 
    dimo_prop = abs(dimorphisme_g)/pmax(male_body_mass_g, female_body_mass_g, na.rm=TRUE),
    sign_mass = sign(dimorphisme_g), 
    Body_mass_g = rowMeans(pick(male_body_mass_g,
                    female_body_mass_g), na.rm = TRUE),
    Body_size_mm = adult_svl_cm*10,
    percent_diff = ifelse(
      test = sign_mass == -1, # Si la masse est négative, les femelles sont plus lourde
      yes = (1-abs(dimo_prop)), 
      no =  ifelse(sign_mass == 0, 
                   yes = 0, 
                   no = (1+abs(dimo_prop)))) * 100,
    dimo_sex_g = ifelse(test = sign_mass == -1 & dimo_prop >= percent_diff_tol, 
                        yes = 'f > m', 
                        no = 'f < m'),
    dimo_sex_g = ifelse(test = dimo_prop < (percent_diff_tol), 
                        yes = 'f = m', 
                        no = dimo_sex_g),
    source = "Amniotes"
    ) |> 
  dplyr::select(
    Species = sp_names,
    # common_name,
    # dimo_prop,
    # sign_mass, 
    # male_body_mass_g, 
    # female_body_mass_g, 
    Body_mass_g,
    Body_size_mm,
    # dimorphisme_g, 
    # percent_diff,  
    dimo_sex_g
  )

# Combiner les données 
traits_comb = bind_rows(
  amniotes_traits_dimor, 
  amphi_traits)

# Ajout des traits avec noms des espèces 
sp_list_fil_nom_fr_traits = sp_list_fil_nom_fr |> 
  left_join(
    y = traits_comb,
    by = join_by(
      species == Species
    )
  ) 
