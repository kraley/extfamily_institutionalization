//=================================================================================//
//====== Extended Family Institutionalization Project                          
//====== Dataset: SIPP2008                                               
//====== Purpose: Creates sub-databases: shhadid_members.dta, ssuid_members_wide.dta
//====== ssuid_shhadid_wide.dta, person_pdemo (parents demographics), partner_of_ref_person_long (and wide)
//=================================================================================//

* This code was originally written for the children's households project. 

* Code is specific to 2008 panel.
local panel "08"

*** We also need a dataset of reference persons.
use "${SIPP`panel'keep}/allmonths"
keep SSUID EPPPNUM SHHADID ERRP ESEX EEDUCATE TMOVEUS TBRSTATE SWAVE

keep if ((ERRP == 1) | (ERRP == 2))

drop ERRP

* can the household reference person vary within address within wave? Seems like the answer should be no
duplicates report SSUID SHHADID SWAVE // yes, but we will fix that below

*gen check=1 if SSUID=="077925488584" | SSUID=="644344944613"

*keep if check==1

recode EEDUCATE (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)

rename EPPPNUM ref_person
rename ESEX ref_person_sex
rename educ ref_person_educ
rename TMOVEUS ref_person_tmoveus
rename TBRSTATE ref_person_tbrstate

label values ref_person_educ educ

drop EEDUCATE

bysort SSUID SHHADID SWAVE: keep if _n==1 // keep one observation per address per wave

save "$tempdir/ref_person_long_am", $replace

