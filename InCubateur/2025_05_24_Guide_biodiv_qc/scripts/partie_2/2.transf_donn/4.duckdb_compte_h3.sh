#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 3 ]; then
echo "Usage: $0 <input_path> <h3_column_name> <output_path>"
exit 1
fi

INPUT_FILE=$1
H3_COL=$2
OUTPUT_FILE=$3

# Compte NB *observations* (pas d'espèce) dans une 
# grille H3 avec résolution choisie
# en gardant information biologique 
# choisi le plus précis (family)

duckdb -c "
-- Load spatial extension if needed
INSTALL h3; INSTALL spatial;
LOAD h3; LOAD spatial;


COPY (
    SELECT 
        Type_FR, 
        kingdom, 
        class, 
        \"order\", 
        family,
        ${H3_COL}, 
        MRS_NM_MRC, 
        MRS_NM_REG, 
        COUNT(*) AS n,
        LN(COUNT(*)) AS log_n,
        ST_GeomFromText(h3_cell_to_boundary_wkt(${H3_COL})) AS geom
    FROM read_parquet('${INPUT_FILE}')
    GROUP BY 
      -- Groupe d'organisme --------------------------
      Type_FR, kingdom, class, \"order\", family,
      -- Grille H3 --------------------------
      ${H3_COL}, 
      -- Région --------------------------
      MRS_NM_MRC, MRS_NM_REG
    ORDER BY n DESC
) TO '${OUTPUT_FILE}' (FORMAT parquet);
"
