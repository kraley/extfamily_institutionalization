//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

local panel "08"
****************************************************************************
* create database with all pairs of coresident individuals in each wave
****************************************************************************
use "${SIPP`panel'keep}/allmonths"

keep SSUID SHHADID EPPPNUM ERRP panelmonth

sort SSUID SHHADID panelmonth

by SSUID SHHADID  panelmonth:  gen HHmembers = _N  /* Number the people in the household in each wave. */

* merge in age of other person in the household to save as "to_age"
merge 1:1 SSUID EPPPNUM panelmonth using "${SIPP`panel'keep}/demo_long_interviews_am.dta", keepusing(adj_age my_sex)

assert _merge==3

drop _merge

rename EPPPNUM relto
rename ERRP ERRPto
rename adj_age to_age
rename my_sex to_sex

save "$tempdir/to", $replace

use "${SIPP`panel'keep}/allmonths", clear

keep SSUID SHHADID EPPPNUM panelmonth ERRP

rename EPPPNUM relfrom
rename ERRP ERRPfrom

joinby SSUID SHHADID panelmonth using "$tempdir/to"  

* drop pairs of ego to self
drop if relto==relfrom

merge m:1 SSUID relfrom relto panelmonth using "${SIPP`panel'keep}/relationship_pairs_bymonth"

replace relationship = .a if (_merge == 1) & (missing(relationship))
replace relationship = .m if (_merge == 3) & (missing(relationship))

drop if relationship == . // PS: 22 contradictins - dropping them 
assert (relationship != .)
drop _merge

tab relationship, m

rename relfrom EPPPNUM
rename relto to_EPPNUM

merge m:1 SSUID EPPPNUM panelmonth using "${SIPP`panel'keep}/demo_long_interviews_am.dta"

drop if _merge==2

drop _merge

tab relationship, m 

do "$sipp2008_code/simple_rel_label"

save "${SIPP`panel'keep}/HHComp_asis_am.dta", $replace
