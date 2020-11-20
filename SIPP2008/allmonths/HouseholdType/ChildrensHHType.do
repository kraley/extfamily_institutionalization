* This file has one record per coresident other per person per month
* One needs to collapse by SSUID EPPPNUM panelmonth to get to person-months

* Run do_all_months (or at least project_macros) before executing this file

use "$SIPP08keep/HHComp_asis_am", clear

rename EPPPNUM relfrom
rename to_EPPNUM relto

merge m:1 SSUID relfrom relto using "$SIPP08keep/relationship_matrix", keepusing(erelat)

gen t2rel=1 if _merge==3

drop _merge

merge m:1 SSUID relfrom relto panelmonth using "$SIPP08keep/relationship_pairs_bymonth", keepusing(relationship)

keep if _merge==1 | _merge==3

drop _merge

keep if adj_age < 18

putexcel set "$results/compare08.xlsx", sheet(HHmembers) replace

local relationship "BIOCHILD BIOMOM BIODAD STEPCHILD STEPMOM STEPDAD ADOPTCHILD MOM DAD SPOUSE GRANDCHILD GRANDCHILD_P GRANDPARENT GRANDPARENT_P SIBLING PARTNER F_CHILD CHILD F_PARENT PARENT AUNTUNCLE AUNTUNCLE_OR_PARENT GREATGRANDCHILD NEPHEWNIECE CHILD_OR_NEPHEWNIECE SIBLING_OR_COUSIN F_SIB OTHER_REL OTHER_REL_P NOREL DONTKNOW" 

local t2relat "Spouse UnmarriedPartner BioParent Stepparent Step/adoptParent AdoptParent FosterParent BioChild Stepchild BioSib HalfSib StepSib AdoptSib OtherSib Grandparent Grandchild Uncle/aunt Nephew/niece Father/mother-in-law Daughter/son-in-law Brother/sister-in-law Other relative Roommate/housemate Roomer/boarder Other non-relative"

local colhead "B C D E F G H I J K L M N O P Q R S T U V W XX Y Z"

putexcel A1:Z1 = "Counts of cases: Transitively-derived relationship by T2 measure or relationship", merge border(bottom)
putexcel A2 = "Transitively-dervied relationship"
putexcel B3:Z3= "Topical Module 2 measure of relationship"

forvalues r=1/31{
    local row=`r'+3
    local rel : word `r' of `relationship'
    putexcel A`row'="`rel'"
}

forvalues c=1/25{
   local col : word `c' of `colhead'
   local colabel : word `c' of `t2relat'
   putexcel `col'2="`colabel'"
 }
tab relationship erelat, matcell(checkrels)

putexcel C3=matrix(checkrels)

fre erelat if missing(relationship) | relationship==40

* use relationship matrix variable to fill in missing information on relationships derived transitively
* We didn't make this easy by having the relationship codes for relationship be the inverse of
* the codes for erelat. For relationship, the codes indicate the relationship from other's perspective
* (i.e. ego is my child), whereas erelat gives is relationship from ego's perspective (i.e. the other person is my parent)
replace relationship=1 if erelat==10 & (missing(relationship) | relationship==40)		 // bioparent
replace relationship=21 if inlist(erelat,11,13,14) & (missing(relationship) | relationship==40)	 // other parent
replace relationship=17 if inlist(erelat,30,31,33) & (missing(relationship) | relationship==40)	 // sibling
replace relationship=23 if inlist(erelat,20,21) & (missing(relationship) | relationship==40)	 // child
replace relationship=12 if erelat==1 & (missing(relationship) | relationship==40)		 // spouse
replace relationship=37 if inlist(erelat,61,62,65) & (missing(relationship) | relationship==40)	 // non-relative
replace relationship=13 if erelat==40 & (missing(relationship) | relationship==40)		 // grand parent
replace relationship=29 if erelat==42 & (missing(relationship) | relationship==40)	 	 // aunt/uncle
replace relationship=35 if inlist(erelat,42,43,52,55) & (missing(relationship) | relationship==40)  // other relative

fre erelat if missing(relationship) | relationship==40

* Create simplified/aggregated indicators for comparison to Pilkauskas & Cross

gen bioparent=1 if relationship==1
gen parent=1 if inlist(relationship,1,4,7,19,21)
gen sibling=1 if inlist(relationship, 17)
gen child=1 if inlist(relationship,2,3,5,6,8,9,10,11,22,23)
gen spartner=1 if inlist(relationship,12,18)
gen nonrel=1 if inlist(relationship,20,22,34,37,38,40)
gen grandparent=1 if inlist(relationship,13,14,27)
gen auntuncle=1 if inlist(relationship,29,30)
gen other_rel=1 if inlist(relationship, 15,16,24,25,26,28,31,33,32,35,36) //not parents, siblings, children, spouses, aunt/uncle, or grandparents
gen unknown=1 if relationship==40 | missing(relationship)
gen nonnuke=1 if nonrel==1 | grandparent==1 | other_rel==1 | unknown==1 
gen allelse=1 if inlist(relationship,2,3,5,6,8,9,10,11,23,12,18) // children, spouses
gen allrel=1 if !missing(relationship)
gen all=1

gen t2gp=1 if erelat==40
gen t2au=1 if erelat==42
gen t2or=1 if inlist(erelat,43,55)
gen t2nr=1 if inlist(erelat,61,62,63,65)
gen t2allrel=1 if !missing(erelat)

gen extended_kin=1 if grandparent==1 | other_rel==1

local rellist "bioparent parent sibling  child spartner nonrel grandparent auntuncle other_rel extended_kin unknown nonnuke allrel all t2gp t2au t2or t2nr t2allrel"

rename relfrom EPPPNUM

// convert the file to individuals from coresident others

collapse (count) `rellist', by (SSUID EPPPNUM panelmonth) fast

merge 1:1 SSUID EPPPNUM panelmonth using "$SIPP08keep/demo_long_interviews_am.dta", keepusing(WPFINWGT my_racealt adj_age my_sex biomom_ed_first par_ed_first ref_person_educ mom_measure mom_age mom_tmoveus dad_tmoveus)

keep if _merge==3

drop _merge

gen weight=int(WPFINWGT*10000)

* Transitively-derived (augmented by T2)
recode nonnuke (0=0)(1/20=1), gen(anynonuke)
recode nonrel (0=0)(1/20=1), gen(anynonrel)
recode grandparent (0=0)(1/20=1), gen(anygp)
recode auntuncle (0=0)(1/20=1), gen(anyauntuncle)
recode other_rel (0=0)(1/20=1), gen(anyother)
recode extended_kin (0=0)(1/20=1), gen(anyextended)
recode unknown (0=0)(1/20=1), gen(anyunknown)

* Topical Module 2 measures
recode t2gp (0=0)(1/90=1), gen(anyt2gp)
recode t2au (0=0)(1/90=1), gen(anyt2au)
recode t2or (0=0)(1/90=1), gen(anyt2or)
recode t2nr (0=0)(1/90=1), gen(anyt2nr)

label variable anynonuke "non-nuclear kin or non-relative"
label variable anynonrel "non-relative"
label variable anygp "grandparent"
label variable anyauntuncle "aunt/uncle"
label variable anyother "non-nuclear non-grandparent non-aunt/uncle kin"
label variable anyunknown "unknown relation"
label variable anyextended "any extended kin"
label variable anyt2gp "any grandparent based on TM2 relationship"
label variable anyt2au "any aunt/uncle based on TM2 relationship"
label variable anyt2or "any other relative based on TM2 relationship"
label variable anyt2nr "any non-relative based on TM2 relationship"

rename all hhsize

#delimit ;
label define yesno  0 "no"
                    1 "yes";
#delimit cr 

local anyrel "anygp anyauntuncle anyother anynonrel"

label variable my_racealt "Race-Ethnicity"

foreach v in `anyrel'{
	label values `v' yesno
}

local t2rel "anyt2gp anyt2au anyt2or anyt2nr"

foreach v in `t2rel'{
	label values `v' yesno
}

save "$tempdir/relationships.dta", replace
