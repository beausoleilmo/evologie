## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
##  
## 
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
# date création: 2026-03-14
# auteur: Marc-Olivier Beausoleil

## ____________####
## Lisez-moi --------
#   --> 


## ____________####
## Prépare l'environnement --------

cd ~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data

~/.duckdb/cli/latest/duckdb

-- Données GBIF (parquet)
SET VARIABLE gb_path = '~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data/gbif_prep_h3.parquet';
SET VARIABLE MRCSelect = 'Lanaudière';

-- select day, month, year, *
-- from "~/Github_proj/evologie/Incubateur/2025_05_24_Guide_biodiv_qc/data/partie_2/biodiv/gbif_data/0047252-250827131500795.parquet"
-- where 
-- occurrenceID in ('URN:catalog:CLO:EBIRD:OBS3264023705') ;

select *, count(MRS_NM_REG) as reg
from read_parquet(getvariable('gb_path'))
group by all;

describe SELECT * FROM read_parquet(getvariable('gb_path'));

select *
from read_parquet(getvariable('gb_path'))
limit 10;


COPY (
select *
from read_parquet(getvariable('gb_path'))
where 
MRS_NM_REG IN ('Montréal')
) TO 'gbif_mtl.parquet' (FORMAT parquet);

COPY (
select *
from read_parquet(getvariable('gb_path'))
where 
MRS_NM_REG IN ('Lanaudière')
) TO 'gbif_lanaud.parquet' (FORMAT parquet);




-- COPY (
-- select *
-- from read_parquet(getvariable('gb_path'))
-- where 
-- MRS_NM_REG IN (getvariable('MRCSelect'))
-- ) TO '../data/partie_2/biodiv/gbif_data/gbif_lanaudiere.parquet' (FORMAT parquet);





-- Extraire les Type_FR qui sont NULL
COPY (
select distinct scientificName, Type_EN, Type_FR, kingdom, "order", class, nom_fr
from read_parquet(getvariable('gb_path'))
where 
Type_FR is NULL
) TO '../data/partie_2/biodiv/gbif_data/gbif_type_null.parquet' 
(FORMAT parquet);

select distinct  species from '../data/partie_2/biodiv/gbif_data/gbif_mtl.parquet' where Type_FR is NULL ORDER BY species ;
select distinct  species from '../data/partie_2/biodiv/gbif_data/gbif_lanaudiere.parquet' where Type_FR is NULL ORDER BY species ;

select distinct  species
from read_parquet(getvariable('gb_path'))
where Type_FR is NULL ORDER BY species ;

select distinct  species, Type_FR
from read_parquet(getvariable('gb_path'))
where species in ('Abies balsamea') ORDER BY species ;
