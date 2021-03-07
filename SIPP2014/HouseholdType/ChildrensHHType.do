* This file has one record per coresident other per person per month
* One needs to collapse by SSUID EPPPNUM panelmonth to get to person-months

* Run do_all_months (or at least project_macros) before executing this file

use "$SIPP14keep/HHComp_asis_am", clear

keep if adj_age < 18

tab relationship

/* Create simplified/aggregated indicators for comparison to Pilkauskas & Cross

Note that this code is now correct. 
*/
gen bioparent=1 if relationship==3
gen parent=1 if inlist(relationship,3,5,7)
gen sibling=1 if inlist(relationship,11,12,13,14,15)
gen child=1 if inlist(relationship,4,6,8)
gen spartner=1 if inlist(relationship,1,2)
gen nonrel=1 if inlist(relationship,19,20)
gen grandparent=1 if inlist(relationship,9)
gen auntuncle=1 if inlist(relationship,17)
gen other_rel=1 if inlist(relationship, 16,18) //not parents, siblings, children, spouses, aunt/uncle, or grandparents (comprises in-law and other relationships)
gen unknown=1 if missing(relationship) 
gen nonnuke=1 if nonrel==1 | grandparent==1 | other_rel==1 
gen allelse=1 if inlist(relationship,4,6,8,1,2) // children, spouses - should I include parents relationship here?
gen allrel=1 if !missing(relationship)
gen all=1

gen extended_kin=1 if grandparent==1 | other_rel==1

local rellist "bioparent parent sibling  child spartner nonrel grandparent auntuncle other_rel extended_kin nonnuke allrel all unknown"

*rename from_num PNUM
*rename to_num relto

// convert the file to individuals from coresident others

collapse (count) `rellist' (max) to_age, by (SSUID PNUM panelmonth) fast

rename to_age hhmaxage

recode hhmaxage (14/17=1)(18/49=2)(5/64=3)(65/74=4)(75/90=5), gen(chhmaxage)
if hhmaxage < 14 then chhmaxage==2

merge 1:1 SSUID PNUM panelmonth using "$SIPP14keep/demo_long_interviews_am.dta", ///
keepusing(WPFINWGT my_racealt adj_age my_sex biomom_ed_first par_ed_first ///
mom_measure mom_age mom_tmoveus dad_tmoveus)

keep if _merge==3

drop _merge

gen weight=int(WPFINWGT*10000)

recode nonnuke (0=0)(1/20=1), gen(anynonuke)
recode nonrel (0=0)(1/20=1), gen(anynonrel)
recode grandparent (0=0)(1/20=1), gen(anygp)
recode auntuncle (0=0)(1/20=1), gen(anyauntuncle)
recode other_rel (0=0)(1/20=1), gen(anyother)
recode extended_kin (0=0)(1/20=1), gen(anyextended)
recode unknown (0=0)(1/20=1), gen(anyunknown)

label variable anynonuke "non-nuclear kin or non-relative"
label variable anynonrel "non-relative"
label variable anygp "grandparent"
label variable anyauntuncle "aunt/uncle"
label variable anyother "non-nuclear non-grandparent non-aunt/uncle kin"
label variable anyunknown "unknown relation"
label variable anyextended "any extended kin"


rename all hhsize
rename nonnuke nnsize

label variable hhsize "number of people in the household"
label variable nnsize "number of nonnuclear people in household"

#delimit ;
label define yesno  0 "no"
                    1 "yes";
#delimit cr 

local anyrel "anygp anyauntuncle anyother anynonrel"

label variable my_racealt "Race-Ethnicity"

foreach v in `anyrel'{
	label values `v' yesno
}

gen pimmigrant=((mom_tmoveus>17 & mom_tmoveus!=.) | (dad_tmoveus>17 & dad_tmoveus!=.))


save "$tempdir/relationships14.dta", replace
