#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 6 ]; then
echo "Usage: $0 <input_path> <h3_column_name> <output_path>"
exit 1
fi

INPUT_FILE=$1
H3_COL=$2
OUTPUT_FILE=$3
KINGDOM_SEL=$4
REGION_SEL_LIST=$5
TYPE_FCT_LIST=$6

# Filtrer les données et agrégation selon le filtre 
# Compte NB observations dans une grille H3 avec résolution choisie
# en gardant information biologique SEULEMENT pour des groupes d'organismes 
# choisis 
duckdb -c "
-- Load spatial extension if needed
INSTALL spatial; LOAD spatial;

COPY (
    SELECT 
        Type_FR, 
        kingdom, 
        ${H3_COL}, 
        MRS_NM_MRC, 
        MRS_NM_REG, 
        SUM(n) AS n,
        LN(SUM(n)) AS log_n, 
        geom
    FROM read_parquet('${INPUT_FILE}')
    WHERE 
        kingdom = '${KINGDOM_SEL}' 
        AND Type_FR IN (${TYPE_FCT_LIST})
        AND MRS_NM_REG IN (${REGION_SEL_LIST})
    GROUP BY 
        Type_FR, 
        ${H3_COL}, 
        kingdom, 
        MRS_NM_MRC, MRS_NM_REG, geom
    ORDER BY n DESC
) TO '${OUTPUT_FILE}' (FORMAT parquet);
"

