## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   -->  données points ebirds
message("Charge : CRS projet")

# Lire le fichier CRS maitre  
projetCRS  = readLines(con = file.path(
  "posts/guide_biodiv_qc/2025_05_24_Guide_biodiv_qc/", 
  "data/param_0/projetCRS.txt"
))