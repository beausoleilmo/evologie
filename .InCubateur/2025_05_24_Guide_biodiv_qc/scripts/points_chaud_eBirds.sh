# Aller au dossier de téléchargement 
cd ~/Github_proj/evologie/.InCubateur/2025_05_24_Guide_biodiv_qc/data/partie_1/biodiv 

# Prendre la date actuelle 
DATE_VAR=$(date -I)

# Télécharger la liste des codes de région eBirds
curl -L -o eBird_region_codes_${DATE_VAR}.xlsx \ 
      "https://support.ebird.org/helpdesk/attachments/48293281603"

# Télécharger la liste des points chauds d'observation eBird du Québec 
curl --header 'X-eBirdApiToken: md76vruc29t5' \
     --location -g 'https://api.ebird.org/v2/ref/hotspot/CA-QC?fmt=csv' > \
     eBird_hotspots_CA_QC_${DATE_VAR}.csv
