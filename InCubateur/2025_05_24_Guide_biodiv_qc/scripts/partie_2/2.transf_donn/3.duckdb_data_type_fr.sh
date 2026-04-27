cd ~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data

~/.duckdb/cli/latest/duckdb

-- Paramètres duckdb
.timer on 

INSTALL h3; INSTALL spatial;
LOAD h3; LOAD spatial;


-- Données GBIF (parquet)
SET VARIABLE gb_path = '~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data/gbif_prep_h3.parquet';

SET VARIABLE spnm_path = '~/Github_proj/evologie/output/partie_2/esp_noms_gbif.csv';

-- 20 sec 
COPY (
  
  SELECT 
  gb.*,
  -- Handle the Type_FR logic using COALESCE and CASE
  COALESCE(
    CASE 
    WHEN class = 'Aves' THEN 'Oiseaux'
    WHEN class = 'Holothuroidea' THEN 'Holothuries'
    WHEN class = 'Echinoidea' THEN 'Oursins'
    WHEN class IN ('Jungermanniopsida', 'Polytrichopsida', 
                   'Marchantiopsida', 'Bryopsida',  
                   'Sphagnopsida', 
                   'Anthocerotopsida') THEN 'Plantes non-vasculaires'
    WHEN class IN ('Asteroidea', 
                   'Crinoidea', 'Ophiuroidea') THEN 'Astéries'
    WHEN class IN ('Demospongiae', 
                   'Calcarea') THEN 'Éponges'
    WHEN "order" = 'Spongillida' THEN 'Éponges'
    WHEN class IN ('Magnoliopsida', 'Lycopodiopsida', 'Liliopsida', 
                   'Polypodiopsida') THEN 'Plantes vasculaires'
    WHEN "order" = 'Lepidoptera' THEN 'Papillons'
    WHEN class IN ('Chlorophyceae', 'Dinophyceae', 'Phaeophyceae', 
                    'Phaeophyceae', 'Cryptophyceae', 'Dictyochophyceae', 
                     'Prymnesiophyceae', 'Katablepharidophyceae', 
                     'Prasinophyceae', 
                     'Chrysophyceae', 'Florideophyceae', 'Xanthophyceae', 
                     'Raphidophyceae', 'Mamiellophyceae', 
                     'Nephroselmidophyceae', 'Ulvophyceae',
                     'Charophyceae', 'Conjugatophyceae', 
                     'Compsopogonophyceae', 'Stylonematophyceae', 
                     'Zygnematophyceae', 'Bangiophyceae') THEN 'Algues'
    WHEN "order" IN ('Cypriniformes', 'Perciformes', 'Siluriformes', 'Esociformes', 'Salmoniformes', 
                     'Gasterosteiformes', 'Amiiformes', 'Osteoglossiformes', 'Anguilliformes', 
                     'Cyprinodontiformes', 'Gadiformes', 'Scorpaeniformes', 
                     'Aulopiformes', 'Stomiiformes', 'Pleuronectiformes', 'Myxiniformes') THEN 'Poissons'
    WHEN class IN ('Anthozoa', 'Hydrozoa',
                   'Scyphozoa','Staurozoa') THEN 'Coraux'
    WHEN class = 'Collembola' THEN 'Collemboles'
    WHEN class = 'Bacillariophyceae' THEN 'Diatomé'
    WHEN class = 'Mammalia' THEN 'Mammifères'
    WHEN "order" = 'Hymenoptera' THEN 'Abeilles'
    WHEN "order" = 'Trichoptera' THEN 'Trichoptères'
    WHEN "order" = 'Diptera' THEN 'Certaines mouches'
    WHEN kingdom = 'Fungi' THEN 'Macrochampignons'
    WHEN "order" = 'Coleoptera' THEN 'Coléoptères'
    WHEN class = 'Squamata' THEN 'Reptiles'
    WHEN class IN ('Gastropoda', 'Polyplacophora'
                    'Scaphopoda') THEN 'Escargots et limaces terrestres et d''eau douce'
    WHEN "order" = 'Neuroptera' THEN 'Neuroptères'
    WHEN "order" IN ('Anura', 'Caudata') THEN 'Amphibiens'
    WHEN "order" = 'Odonata' THEN 'Libellules et demoiselles'
    WHEN "order" = 'Orthoptera' THEN 'Sauterelles et semblables'
    WHEN class = 'Testudines' THEN 'Reptiles'
    WHEN "order" = 'Megaloptera' THEN 'Neuroptera'
    WHEN "order" = 'Isopoda' THEN 'Isopode'
    WHEN "order" IN ('Pinales', 'Lycopodiales') THEN 'Plantes vasculaires'
    WHEN "order" = 'Hemiptera' THEN 'Punaises'
    WHEN class = 'Arachnida' THEN 'Araignées'
    WHEN class = 'Pycnogonida' THEN 'Araignées'
    WHEN class = 'Malacostraca' THEN 'Crustacés'
    WHEN class = 'Polychaeta' THEN 'Lombrics'
    WHEN class = 'Diplura' THEN 'Collemboles'
    WHEN "order" = 'Mantodea' THEN 'Sauterelles et semblables'
    WHEN "order" = 'Arhynchobdellida' THEN 'Sangsues'
    WHEN "order" = 'Psocodea' THEN 'Puces'
    WHEN "order" = 'Dermaptera' THEN 'Sauterelles et semblables'
    WHEN "order" = 'Decapoda' THEN 'Décapodes'
    WHEN "order" = 'Entomobryomorpha' THEN 'Collemboles'
    WHEN "order" = 'Ephemeroptera' THEN 'Éphémères'
    WHEN "order" IN ('Diplostraca', 'Calanoida') THEN 'Décapodes'
    WHEN "order" = 'Mecoptera' THEN 'Mécoptères'
    WHEN class = 'Bivalvia' THEN 'Bivalves'
    WHEN class IN ('Diplopoda', 'Chilopoda', 'Pauropoda') THEN 'Myriapodes'
    WHEN class IN ('Ascidiacea',
'Maxillopoda',
'Gymnolaemata',
'Tentaculata',
'Sipunculidea',
'Nuda',
'Copepoda',
'Rhynchonellata',
'Polyplacophora',
'Caudofoveata',
'Scaphopoda',
'Stenolaemata') THEN 'Autres'
    WHEN class IN ('Hoplonemertea',
'Pilidiophora',
'Trematoda') THEN 'Sangsues'
    WHEN class IN ('Oligotrichea',
'Gymnostomatea',
'Prostomatea',
'Oligohymenophorea',
'Sagittoidea',
'Chromadorea',
'Eurotatoria',
'Peronosporea',
'Hypotrichea',
'Ostracoda') THEN 'Micro-organisme divers'
    WHEN "order" = 'Zygentoma' THEN 'Myriapodes'
    WHEN "order" = 'Plumatellida' THEN 'Bryophytes'
    ELSE NULL 
    END,
    spnm.Type_FR -- This mimics the coalesce(Type_FR_2, Type_FR)
  ) AS Type_FR
  FROM read_parquet(getvariable('gb_path')) AS gb
  LEFT JOIN read_csv_auto(getvariable('spnm_path')) AS spnm 
  ON gb.scientificName = spnm.scientificName
) TO 'gbif_prep_type_fr_h3.parquet' (FORMAT parquet);

-- quit duckdb
.exit
