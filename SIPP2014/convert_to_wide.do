//==============================================================================
//===== Children's Household Instability Project                                                    
//===== Dataset: SIPP2014                                                                             
//===== Purpose: Create a wide database by person (SSUID EPPPNUM) including variables describing parental characteristics, race and sex. 
//===== Logic: This file generates variables indicating the first and last month numbers in which this person is encountered.
//=====        Also, generates a single value for race and sex even though for some people reports vary across months.
//==============================================================================
 
use "$SIPP14keep/allmonths14", clear  

merge m:1 SSUID ERESIDENCEID panelmonth using "$tempdir/residence_members" 
assert _merge == 3
drop _merge

*****************************************************************************
* Section: create a dummy for whether the individual is coresiding with any original
*          sample member to be able to drop observations that aren't
*****************************************************************************

gen with_original=0
replace with_original=1 if PNUM >=101 & PNUM <=120 // original sample member

tab with_original

forvalues n=101/120 {
    replace with_original = strpos(residence_members, " `n' ") if with_original==0 // if you find n in the list of residence members, set with_original equal to 1
}

tab with_original


replace with_original=1 if with_original > 1

tab with_original

********************************************************************************
* Section: create variables describing mother's and father's education and mother's
*           immigration status by merging to person_pdemo 
*           (created in make_auxiliary_datasets)using pdemo_eppnum as key
********************************************************************************

recode EPNPAR1 (. = .), gen(pdemo_epppnum) 
* Ps: there was a change in this panel: variable EPNPAR1 refers not only to mothers 
* but to reference parent number 1. I'm keeping the name mom's 
* so names are uniform across panels but the code will contain men as well
*
* Fixed below using psex, which is now on the person_demo file

* Merging on characterstics of parent 1
merge m:1 SSUID pdemo_epppnum panelmonth using "$tempdir/person_pdemo"

* If there was a valid value of EPNPAR1 then the case should be linked to
* the person_demo file that includes all people
* there is one case (SSUID 876285684196) that doesn't follow the rule in some panel months
*assert missing(pdemo_epppnum) if (_merge == 1)

* drop unmatched people in the parent file
drop if _merge == 2
drop _merge
drop pdemo_epppnum
rename educ par1_educ 
rename page par1_age
rename psex par1_sex
rename ptmoveus par1_tmoveus

recode EPNPAR2 (. = .), gen(pdemo_epppnum)
merge m:1 SSUID pdemo_epppnum panelmonth using "$tempdir/person_pdemo"

* again, a small number of problem cases

* drop unmatched people in the parent file
drop if _merge == 2
drop _merge
drop pdemo_epppnum
rename educ par2_educ
rename page par2_age
rename psex par2_sex
rename ptmoveus par2_tmoveus

gen mom_educ=par1_educ if par1_sex==2
replace mom_educ=par2_educ if par1_sex==1 
gen dad_educ=par1_educ if par1_sex==1
replace dad_educ=par2_educ if par1_sex==2 
gen mom_age=par1_age if par1_sex==2
replace mom_age=par2_age if par1_sex==1
gen dad_age=par1_age if par1_sex==1
replace dad_age=par2_age if par1_sex==2 
gen mom_tmoveus=par1_tmoveus if par1_sex==2
replace mom_tmoveus=par2_tmoveus if par1_sex==1
gen dad_tmoveus=par1_tmoveus if par1_sex==1
replace dad_tmoveus=par2_tmoveus if par1_sex==2 


gen biomom_age=mom_age if EPAR1TYP==1 & par1_sex==2
replace biomom_age=mom_age if EPAR2TYP==1 & par2_sex==2
gen biomom_educ=mom_educ if EPAR1TYP==1 & par1_sex==2
replace biomom_educ=mom_educ if EPAR2TYP==1 & par2_sex==2
gen biodad_age=dad_age if EPAR1TYP==1 & par1_sex==1
replace biodad_age=dad_age if EPAR2TYP==1 & par2_sex==1

label var mom_educ "Mother's (bio, step, adopt) educational level (this month)"
label var mom_age "Mother's (bio, step, adoptive) Age (uncleaned)"
label var biomom_age "Age of coresident biological mother if present (uncleaned)"
label var biomom_educ "Education of coresident biological mother if present"

label var dad_educ "Father's (bio, step, adopt) educational level (this month)"
label var dad_age "Father's (bio, step, adoptive) Age (uncleaned)"
label var biodad_age "Age of coresident biological father if present"

********************************************************************************
* Own Educational Attainment
********************************************************************************

recode EEDUC (31/38 = 1)  (39 = 2)  (40/42 = 3)  (43/46 = 4), gen (educ)
label values educ educ

********************************************************************************
* Section: Make the dataset wide by month (12 months).
********************************************************************************

local i_vars "SSUID PNUM"
local j_vars "panelmonth"
local wide_vars "ERESIDENCEID EPNPAR1 EPNPAR2 EPAR1TYP EPAR2TYP EPNSPOUSE TAGE EMS ERELRP WPFINWGT ERACE ESEX EORIGIN THTOTINC TFTOTINC RHNUMPERWT2 mom_educ biomom_educ dad_educ  mom_age biomom_age dad_age dad_tmoveus mom_tmoveus biodad_age residence_members mx_residence_members educ RGED RENROLL EEDGRADE EEDGREP RFOODR RFOODS RHNUMU18 RHNUMU18WT2 RHNUM65OVER RHNUM65OVRT2 RHPOV RHPOVT2 THINCPOV THINCPOVT2 with_original THNETWORTH"

local extra_vars "overall_max_residence_members"

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

* there was a variable for race in each month
forvalues month = $first_month/$final_month {
    recode ERACE`month' (1=1) (2=2) (3=4) (4=5), generate (race`month')
    replace race`month' = 3 if ((EORIGIN`month' == 1) & (ERACE`month' != 2)) /* non-black Hispanic */
	recode ERACE`month' (1=1)(2=2)(3=4)(4=5), generate(racealt`month')
	replace racealt`month' = 3 if EORIGIN`month'==1 /*All Hispanic */
    label values race`month' race
	label values racealt`month' racealt
}

* use the race value in the first observation.
gen my_race = race$first_month
gen my_racealt = racealt$first_month
forvalues month = $second_month/$final_month {
    replace my_race = race`month' if (missing(my_race))
	replace my_racealt=racealt`month' if (missing(my_racealt))
}
label values my_race race 
label values my_racealt racealt

* Create flag variables (race_diff*) for difference between reported race and my_race throughout the 15 months.
* Use the 15 flag variables to create an indicator variable (any_race_diff) to indicate if there's any different reported race and my_race in any month. 
gen race_diff$first_month = .
forvalues month = $second_month/$final_month {
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

gen my_sex = ESEX$first_month
forvalues month = $second_month/$final_month {
    replace my_sex = ESEX`month' if (missing(my_sex))
}

#delimit ;
label define sex    1 "male"
                    2 "female"
					;

#delimit cr

label values my_sex sex

* Create flag variables (sex_diff*) to indicate whether sex information is the same as reported in the first month.
* Use these flag variables to generate an indicator (any_sex_diff) for any different sex value through out months. 
gen sex_diff$first_month = .
forvalues month = $second_month/$final_month {
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
gen biomom_ed_first=biomom_educ$first_month 
gen momageatbirth=biomom_age$first_month-TAGE$first_month if biomom_age$first_month-TAGE$first_month > 10 & biomom_age$first_month-TAGE$first_month < 50
forvalues month = $second_month/$final_month {
	replace biomom_ed_first=biomom_educ`month' if missing(biomom_ed_first)
	replace momageatbirth=biomom_age`month'-TAGE`month' if missing(momageatbirth) & biomom_age`month'-TAGE`month' > 10 & biomom_age$first_month-TAGE$first_month < 50
}

replace mom_measure=1 if !missing(biomom_ed_first)

*any mom next
gen mom_ed_first=biomom_ed_first
replace mom_ed_first=mom_educ$first_month if missing(mom_ed_first)

forvalues month = $second_month/$final_month {
	replace mom_ed_first=mom_educ`month' if missing(mom_ed_first)
}

*dad next 

replace mom_measure=2 if !missing(mom_ed_first) & missing(biomom_ed_first)

gen dad_ed_first=dad_educ$first_month
forvalues month = $second_month/$final_month {
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

* Merge in file with information on number of persons in sampling unit per month and overall (make_auxiliary_datasets)
merge m:1 SSUID using "$tempdir/ssuid_members_wide"
assert _merge == 3
drop _merge

* Merge in file with information on number of addresses in sampling unit per month and overall (make_auxiliary_datasets)
merge m:1 SSUID using "$tempdir/ssuid_residence_wide"
assert _merge == 3
drop _merge

* Create variables identifying first and last month of appearance for each person(which is often the same as the whole household).
* Note: ERESIDENCE is never missing in the base data, so we can assume here that a missing ERESIDENCE means the person was absent from that month.
gen my_last_month = ${first_month} if (!missing(ERESIDENCEID${first_month}))
forvalues month = $second_month/$final_month {
    replace my_last_month = `month' if (!missing(ERESIDENCEID`month'))
}

gen my_first_month = ${final_month} if (!missing(ERESIDENCEID${final_month}))
forvalues month = $penultimate_month (-1) $first_month {
    replace my_first_month = `month' if (!missing(ERESIDENCEID`month')) & with_original`month'==1
}

drop ERACE* race* ESEX*
drop any_race_diff any_sex_diff sex*

save "$tempdir/person_wide", $replace



