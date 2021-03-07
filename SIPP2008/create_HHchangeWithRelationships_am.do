//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

local panel "08"

* hh_change has one record per person per wave
use "${SIPP`panel'keep}/hh_change_am.dta"

keep SSUID EPPPNUM panelmonth comp_change hh_change addr_change 

* changer_rels.dta has one record for every person arriving or leaving ego's 
* household between this month and the next. There may be records for both 
* arrivers and leavers. An "arriver" might be someone that ego moves in with
* or someone who moves in with ego. Analogously, a leaver could be someone ego
* leaves ego's household or someone who ego leaves behind when she leaves.   

* changer_rels includes no records for individuals who experienced no composition change in the month
* we get these records from hh_change.dta. Thus any variable we pull in with "changer_rels" is missing for everyone
* who did not experience a composition change. For example, adult_arrive is missing for everyone with comp_change==0
merge 1:m SSUID EPPPNUM panelmonth using "$tempdir/changer_rels_am", keepusing(relationship ///
parent sibling grandparent nonrel other_rel foster allelse adult_arrive adult_leave ///
adult30_arrive adult30_leave parent_arrive parent_leave otheradult30_arrive ///
otheradult30_leave otheradult_arrive otheradult_leave change_type ///
yadult_arrive yadult_leave otheryadult_arrive otheryadult_leave adultsib_arrive ///
adultsib_leave otheradult2_arrive otheradult2_leave infant_arrive) 

* be sure that all cases with a comp_change were found in changer_rels
assert _merge==3 if comp_change==1

drop _merge

tab  relationship change_type, m

gen someoneleft=0 if !missing(comp_change)
gen someonearrived=0 if !missing(comp_change)

replace someonearrived=1 if change_type==1
replace someoneleft=1 if change_type==2

gen parent_change=1 if comp_change==1 & parent==1
gen sib_change=1 if comp_change==1 & sibling==1
gen other_change=1 if comp_change==1 & parent!=1 & sibling !=1
gen nonparent_change=1 if comp_change==1 & parent!=1
gen gp_change=1 if comp_change==1 & grandparent==1
gen nonrel_change=1 if comp_change==1 & nonrel==1
gen otherrel_change=1 if comp_change==1 & other_rel==1
gen foster_change=1 if comp_change==1 & foster==1 		// tiny
gen allelse_change=1 if comp_change==1 & allelse==1

collapse (max) comp_change parent_change sib_change other_change nonparent_change gp_change ///
nonrel_change otherrel_change foster_change allelse_change adult_arrive ///
adult_leave adult30_arrive adult30_leave someonearrived someoneleft ///
parent_arrive parent_leave otheradult30_arrive otheradult30_leave ///
otheradult_arrive otheradult_leave yadult_arrive yadult_leave otheryadult_arrive ///
otheryadult_leave adultsib_arrive adultsib_leave otheradult2_arrive otheradult2_leave infant_arrive, by(SSUID EPPPNUM panelmonth)

merge 1:1 SSUID EPPPNUM panelmonth using "${SIPP`panel'keep}/hh_change_am.dta"

drop _merge

* remove observations that are missing because of lack of interview and
* unable to infer comp_change. insample is generated at the end of create_hh_change.do
keep if insample !=0

local reltyp "parent sib other nonparent gp nonrel otherrel foster allelse"

* set relationship-specific composition change variables to 0 if comp_change is not missing and specific relationship type wasn't observed among the changers.
foreach r in `reltyp'{
	replace `r'_change=0 if missing(`r'_change) & !missing(comp_change)
}

assert parent_change==. if comp_change==.
assert parent_change==0 if comp_change==0
assert other_change==. if comp_change==.
assert other_change==0 if comp_change==0

replace adult_arrive=0 if missing(adult_arrive) & !missing(comp_change)
replace adult_leave=0 if missing(adult_leave) & !missing(comp_change)

replace yadult_arrive=0 if missing(yadult_arrive) & !missing(comp_change)
replace yadult_leave=0 if missing(yadult_leave) & !missing(comp_change)

replace adult30_arrive=0 if missing(adult30_arrive) & !missing(comp_change)
replace adult30_leave=0 if missing(adult30_leave) & !missing(comp_change)

replace parent_arrive=0 if missing(parent_arrive) & !missing(comp_change)
replace parent_leave=0 if missing(parent_leave) & !missing(comp_change)

replace otheradult30_arrive=0 if missing(otheradult30_arrive) & !missing(comp_change)
replace otheradult30_leave=0 if missing(otheradult30_leave) & !missing(comp_change)

replace otheradult_arrive=0 if missing(otheradult_arrive) & !missing(comp_change)
replace otheradult_leave=0 if missing(otheradult_leave) & !missing(comp_change)

replace otheryadult_arrive=0 if missing(otheryadult_arrive) & !missing(comp_change)
replace otheryadult_leave=0 if missing(otheryadult_leave) & !missing(comp_change)

replace adultsib_arrive=0 if missing(adultsib_arrive) & !missing(comp_change)
replace adultsib_leave=0 if missing(adultsib_leave) & !missing(comp_change)

replace otheradult2_arrive=0 if missing(otheradult2_arrive) & !missing(comp_change)
replace otheradult2_leave=0 if missing(otheradult2_leave) & !missing(comp_change)

replace infant_arrive=0 if missing(infant_arrive) & !missing(comp_change)

label variable comp_change "Household composition changed bewteen this month and the next"
label variable parent_change "Started or stopped living with a (bio/step/adoptive) parent (or parent's partner)"
label variable sib_change "Started or stopped living with a (full/half/step) sibling entered or left household"
label variable other_change "Started or stopped living with non-parent, non-sibling"
label variable nonparent_change "Started or stopped living with non-parent"
label variable gp_change "Started or stopped living with a grandparent"
label variable foster_change "Started or stopped living with a foster sibling/parent"
label variable allelse_change "Started or stopped living with a spouse or child"
label variable adult_arrive "Started living with an adult (18+)"
label variable adult_leave "Stopped living with an adult (18-29)"
label variable yadult_arrive "Started living with an adult (18-29)"
label variable yadult_leave "Stopped living with an adult (18+)"
label variable adult30_arrive "Started living with an adult (30+)"
label variable adult30_leave "Stopped living with an adult (30+)"
label variable someonearrived "Started living with someone"
label variable someoneleft "Stopped living with someone"
label variable parent_arrive "Started living with a (step/bio/adoptive) parent (or parent's partner)"
label variable parent_leave "Stopped living with a (step/bio/adoptive) parent (or parent's partner)"
label variable otheradult30_arrive "Started living with an adult over age 30"
label variable otheradult30_leave "Stopped living with an adult over age 30"
label variable otheradult_arrive "Started living with a non-parent adult"
label variable otheradult_leave "Stopped living with a non-parent adult"
label variable otheradult2_arrive "Started living with a non-parent non-sibling adult"
label variable otheradult2_leave "Stopped living with a non-parent non-sibling adult"
label variable otheryadult_arrive "Started living with a non-parent young adult (18-29)"
label variable otheryadult_leave "Stopped living with a non-parent youn adult (18-29)"
label variable adj_age "Cleaned age variable"
label variable original "Was in the sample at Month 1"
label variable agemonth1 "Age in month 1"
label variable my_race "Race-Ethnicity of individual reported at Month 1"
label variable my_sex "Sex of person as reported at Month 1"
label variable mom_measure "Measure of mother's characteristics reflects biological, other mother, or father"
label variable biomom_ed_first "Education level of biological mother as reported at first observation together"
label variable mom_ed_first "Education level of (any) mother as reported at first observation together"
label variable dad_ed_first "Education level of (any) father as reported at first observation together"
label variable par_ed_first "Education level of parent (priority order: biomom, other mom, dad)"
label variable hh_change "Is there a change in household composition or address between this month and the next?"
label variable inmonth "Is this person observed in this month?"
label variable insample "Is this observation included in lifetable analysis?"
label variable infant_arrive "Infant arriving"

label define yesno   0 "No" 1 "Yes"
label define insample 0 "Not in sample" 1 "In this month and the next" 2 "Inferred Composition Change" 3 "Only Address Change"
label define momeasure 0 "Never lived with parent" 1 "Biological Mother" 2 "Other Mother" 3 "Father"

local changevars "comp_change parent_change sib_change other_change nonparent_change gp_change foster_change allelse_change adult_arrive adult_leave someonearrived someoneleft parent_arrive parent_leave otheradult30_arrive otheradult30_leave otheradult_arrive otheradult_leave otheradult2_arrive otheradult2_leave infant_arrive innext hh_change inmonth"

foreach v in `changevars' {
	label values `v' yesno
}

label values insample insample
label values mom_measure momeasure

save "${SIPP`panel'keep}/HHchangeWithRelationships_am.dta", $replace


