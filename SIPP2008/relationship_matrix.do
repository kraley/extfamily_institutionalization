//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

* creates relationship_matrix.do and compares transitively-derived measures of 
* relationships to topical module 2 relationships

use "$SIPP2008tm/sippp08putm2.dta", clear

keep ssuid epppnum shhadid erelat* eprlpn* tage

 *******************************************************
 * rename variables to remove leading 0 for single digits
 
 forvalues p=1/9 {
  rename eprlpn0`p' eprlpn`p'
  rename erelat0`p' erelat`p'
 }

****************************************************
* count the number of other people in the household
*

gen countall=0
gen countother=0

 forvalues p=1/30 {
  replace countother=countother+1 if eprlpn`p' > 0 & erelat`p' !=99
  replace countall=countall+1 if eprlpn`p' > 0
 }

rename epppnum relfrom

reshape long erelat eprlpn, i(ssuid relfrom) j(pn)

rename eprlpn relto

drop if relto < 0

rename ssuid SSUID

destring relfrom, replace

drop if relfrom==relto

save "$SIPP08keep/relationship_matrix", $replace

use "$SIPP08keep/relationship_pairs_bymonth"

keep if panelmonth==5

merge 1:1 SSUID relto relfrom using "$SIPP08keep/relationship_matrix"

putexcel set "$results/compare_relationships08.xlsx", sheet(checkrels) modify

tab relationship erelat, matcell(checkrels)

putexcel C3=matrix(checkrels)


