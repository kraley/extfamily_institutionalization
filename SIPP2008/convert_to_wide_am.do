//=================================================================================//
//====== Extended Family Institutionalization Project                          
//====== Dataset: SIPP2008                                               
//====== Purpose: Creates sub-databases: shhadid_members.dta, ssuid_members_wide.dta
//====== ssuid_shhadid_wide.dta, person_pdemo (parents demographics), partner_of_ref_person_long (and wide)
//=================================================================================//

* This code was originally written for the children's households project. 

* Code is specific to 2008 panel.

local panel "08"
 
use "${SIPP`panel'keep}/allmonths", clear  

merge m:1 SSUID SHHADID panelmonth using "$tempdir/shhadid_members_am" 
assert _merge == 3
drop _merge


* Add characteristics of reference person
merge m:1 SSUID SHHADID SWAVE using "$tempdir/ref_person_long_am"

assert _merge == 3
drop _merge

*****************************************************************************
* Section: create a dummy for whether the individual is coresiding with any original
*          sample member to be able to drop observations that aren't
*****************************************************************************

gen with_original=0
replace with_original=1 if EPPPNUM >=101 & EPPPNUM <=120 // original sample member

tab with_original

forvalues n=101/120 {
    replace with_original = strpos(shhadid_members, " `n' ") if with_original==0 // if you find n in the list of residence members, set with_original equal to 1
}

tab with_original

replace with_original=1 if with_original > 1

tab with_original


********************************************************************************
* Section: create variables describing mother's and father's education and mother's
*           immigration status by merging to person_pdemo 
*           (created in make_auxiliary_datasets)using pdemo_eppnum as key
********************************************************************************

recode EPNMOM (9999 = .), gen(pdemo_epppnum)
merge m:1 SSUID pdemo_epppnum panelmonth using "$tempdir/person_pdemo_am"
assert missing(pdemo_epppnum) if (_merge == 1)

gen no_mom=1 if _merge==1
replace no_mom=0 if missing(no_mom)

drop if _merge == 2
drop _merge
drop pdemo_epppnum
rename educ mom_educ
rename page mom_age
rename ptmoveus mom_tmoveus
rename ptbrstate mom_tbrstate
gen biomom_age=mom_age if ETYPMOM==1
gen biomom_educ=mom_educ if ETYPMOM==1

tab mom_age no_mom, m

label var mom_educ "Mother's (bio, step, adopt) educational level (this wave)"
label var mom_age "Mother's (bio, step, adoptive) Age (uncleaned)"
label var biomom_age "Age of coresident biological mother if present (uncleaned)"
label var biomom_educ "Education of coresident biological mother if present"

recode EPNDAD (9999 = .), gen(pdemo_epppnum)
merge m:1 SSUID pdemo_epppnum panelmonth using "$tempdir/person_pdemo_am"
assert missing(pdemo_epppnum) if (_merge == 1)
drop if _merge == 2
drop _merge
drop pdemo_epppnum
rename educ dad_educ
rename page dad_age
rename ptmoveus dad_tmoveus
rename ptbrstate dad_tbrstate

 
gen biodad_age=dad_age if ETYPDAD==1

label var dad_educ "Father's (bio, step, adopt) educational level (this wave)"
label var dad_age "Father's (bio, step, adoptive) Age (uncleaned)"
label var biodad_age "Age of coresident biological father if present"

********************************************************************************
* Own Educational Attainment
********************************************************************************

recode EEDUCATE (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)
label values educ educ

gen dropout=0
replace dropout=1 if RENROLL==3 & educ < 2

********************************************************************************
* Section: Make the dataset wide by wave (15 waves by 4 months).
********************************************************************************

local i_vars "SSUID EPPPNUM"
local j_vars "panelmonth"
local wide_vars "SHHADID EPNMOM EPNDAD ETYPMOM ETYPDAD EPNSPOUS TAGE EMS ERRP WPFINWGT ERACE ESEX EORIGIN EBORNUS THTOTINC TFTOTINC EHHNUMPP mom_educ biomom_educ dad_educ mom_age biomom_age dad_age biodad_age shhadid_members mx_shhadid_members ref_person ref_person_sex ref_person_educ ref_person_tmoveus ref_person_tbrstate mom_tmoveus mom_tbrstate dad_tmoveus dad_tbrstate educ dropout with_original"

local extra_vars "overall_max_shhadid_members"

keep `i_vars' `j_vars' `wide_vars' `extra_vars'
reshape wide `wide_vars', i(`i_vars') j(`j_vars')

***********************************************************************
* Section: Create Race/Ethnicity variables (2 versions) and set my_race 
*           (and my_race_v2) equal to first observation. 
***********************************************************************

#delimit ;
label define race   1 "NH white"
                    2 "black"
                    3 "non-black Hispanic"
                    4 "NH Asian"
                    5 "NH other";

label define racealt  1 "NH white"
					2 "NH black"
					3 "Hispanic"
					4 "NH Asian"
					5 "NH Other";
#delimit cr

* there was a variable for race in each wave that is propogated across all reference months
forvalues month = $firstmonth/$finalmonth {
    recode ERACE`month' (1=1) (2=2) (3=4) (4=5), generate (race`month')
    replace race`month' = 3 if ((EORIGIN`month' == 1) & (ERACE`month' != 2)) /* non-black Hispanic */
    recode ERACE`month' (1=1)(2=2)(3=4)(4=5), generate(racealt`month')
    replace racealt`month' = 3 if EORIGIN`month'==1 /* All Hispanic */
    label values race`month' race
    label values racealt`month' racealt
}

* use the race value in the first observation.
gen my_race = race$firstmonth
gen my_racealt = racealt$firstmonth
forvalues month = $second_month/$finalmonth {
    replace my_race = race`month' if (missing(my_race))
	replace my_racealt=racealt`month' if (missing(my_racealt))
}
label values my_race race 
label values my_racealt racealt

* Create flag variables (race_diff*) for difference between reported race and my_race throughout the 15 waves times 4 months.
* Use the 15 flag variables to create an indicator variable (any_race_diff) to indicate if there's any different reported race and my_race in any wave. 
gen race_diff$firstmonth = .
forvalues month = $second_month/$finalmonth {
    gen race_diff`month' = .
    replace race_diff`month' = 1 if ((!missing(my_race)) & (!missing(race`month')) & (race`month' != my_race))
    replace race_diff`month' = 0 if ((!missing(my_race)) & (!missing(race`month')) & (race`month' == my_race))
    tab race_diff`month'
    tab my_race race`month' if (race_diff`month' == 1)
}
egen any_race_diff = rowmax(race_diff*)
tab any_race_diff

********************************************************************************
* Section: Create sex variable. Set value of my_sex to the value at first observation. 
********************************************************************************

gen my_sex = ESEX$firstmonth
forvalues month = $second_month/$finalmonth {
    replace my_sex = ESEX`month' if (missing(my_sex))
}

#delimit ;
label define sex    1 "male"
                    2 "female"
					;

#delimit cr

label values my_sex sex

* Create flag variables (sex_diff*) to indicate whether sex information is the same as reported in the first wave.
* Use these flag variables to generate an indicator (any_sex_diff) for any different sex value through out waves. 
gen sex_diff$firstmonth = .
forvalues month = $second_month/$finalmonth {
    gen sex_diff`month' = .
    replace sex_diff`month' = 1 if ((!missing(my_sex)) & (!missing(ESEX`month')) & (ESEX`month' != my_sex))
    replace sex_diff`month' = 0 if ((!missing(my_sex)) & (!missing(ESEX`month')) & (ESEX`month' == my_sex))
    tab sex_diff`month'
    tab my_sex ESEX`month' if (sex_diff`month' == 1)
}
egen any_sex_diff = rowmax(sex_diff*)
tab any_sex_diff

********************************************************************************
* Section: Create biological mother education and age variables. 
*          Set value of my_sex to the value at first observation.
*          If no biological mother, then use other mother or father 
********************************************************************************

gen mom_measure=0

* bio mom first
gen biomom_ed_first=biomom_educ$firstmonth 
gen momageatbirth=biomom_age$firstmonth-TAGE$firstmonth if biomom_age$firstmonth-TAGE$firstmonth > 10 & biomom_age$firstmonth-TAGE$firstmonth < 50
forvalues month = $second_month/$finalmonth {
	replace biomom_ed_first=biomom_educ`month' if missing(biomom_ed_first)
	replace momageatbirth=biomom_age`month'-TAGE`month' if missing(momageatbirth) & biomom_age`month'-TAGE`month' > 10 & biomom_age$firstmonth-TAGE$firstmonth < 50
}

replace mom_measure=1 if !missing(biomom_ed_first)

*any mom next
gen mom_ed_first=biomom_ed_first
replace mom_ed_first=mom_educ$firstmonth if missing(mom_ed_first)

forvalues month = $second_month/$finalmonth {
	replace mom_ed_first=mom_educ`month' if missing(mom_ed_first)
}

*dad next 

replace mom_measure=2 if !missing(mom_ed_first) & missing(biomom_ed_first)

gen dad_ed_first=dad_educ$firstmonth
forvalues month = $second_month/$finalmonth {
	replace dad_ed_first=dad_educ`month' if missing(dad_ed_first)
}

replace mom_measure=3 if !missing(dad_ed_first) & missing(biomom_ed_first) & missing(mom_ed_first)

gen par_ed_first=biomom_ed_first
replace par_ed_first=mom_ed_first if missing(par_ed_first)
replace par_ed_first=dad_ed_first if missing(par_ed_first)

tab mom_measure
tab par_ed_first

********************************************************************************
* Section: Add variables for other members of sampling unit and other members who 
*          ever share an address
********************************************************************************

* Merge in file with information on number of persons in sampling unit per wave and overall (make_auxiliary_datasets)
merge m:1 SSUID using "$tempdir/ssuid_members_wide_am"
assert _merge == 3
drop _merge

* Merge in file with information on number of addresses in sampling unit per wave and overall (make_auxiliary_datasets)
merge m:1 SSUID using "$tempdir/ssuid_shhadid_wide_am"
assert _merge == 3
drop _merge

* Create variables identifying first and last wave of appearance for each person(which is often the same as the whole household).
* Note: SHHADID is never missing in the base data, so we can assume here that a missing SHHADID means the person was absent from that wave.
gen my_last_month = $firstmonth if (!missing(SHHADID${firstmonth}))
forvalues month = $second_month/$finalmonth {
    replace my_last_month = `month' if (!missing(SHHADID`month'))
}

gen my_first_month = $finalmonth if (!missing(SHHADID${finalmonth}))
forvalues month = $penultimate_month (-1) $firstmonth {
    replace my_first_month = `month' if (!missing(SHHADID`month')) & with_original`month'==1
}

drop ERACE* race* ESEX*
drop any_race_diff any_sex_diff sex*

save "$tempdir/person_wide_am", $replace




