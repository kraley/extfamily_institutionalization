//========================================================================================================================//
//=================== Children's Household Instability Project                    ========================================//
//=================== Dataset: SIPP2014                                         ========================================//
//=================== Purpose: This file fixes up age so the months are consistent ========================================//
//=========================================================================================================================//
use "$tempdir/person_wide"

gen num_ages = 0
forvalues month = $first_month/$final_month {
    replace num_ages = num_ages + 1 if (!missing(TAGE`month'))
}

******************************************************************************
*Section: create expected age variables based on age at first observation and 
*          aging the person one year every 3 observations or based on last observation
*          and decrementing one year every 3 observations 
******************************************************************************

*** We make a simple projection of expected age from the first reported age
* and from the last reported age.  
gen expected_age_fwd = TAGE$first_month
gen expected_age_fwd$first_month = expected_age_fwd

* a counter; after 3 observations at current age, increase by 1
gen num_curr_age = 0
replace num_curr_age = 1 if (!missing(expected_age_fwd))

forvalues month = $second_month/$final_month {
    * Increment counter of age runs if we have established an age.
    * Set the counter to 1 if we are just now establishing an age.
    replace num_curr_age = num_curr_age + 1 if (!missing(expected_age_fwd))
    replace num_curr_age = 1 if ((!missing(TAGE`month')) & (missing(expected_age_fwd)))
    replace expected_age_fwd = TAGE`month' if ((!missing(TAGE`month')) & (missing(expected_age_fwd)))

    * Increment the age if we've already used it three times. Reset counter.
    replace expected_age_fwd = expected_age_fwd + 1 if (num_curr_age > 3)
    replace num_curr_age = 1 if (num_curr_age > 3)

    gen expected_age_fwd`month' = expected_age_fwd
}
drop num_curr_age expected_age_fwd

* backward projection.
gen expected_age_bkwd = TAGE$final_month
gen expected_age_bkwd$final_month = expected_age_bkwd

gen num_curr_age = 0
replace num_curr_age = 1 if (!missing(expected_age_bkwd))

forvalues month = $penultimate_month (-1) $first_month {
    * Increment counter of age runs if we have established an age.
    * Set the counter to 1 if we are just now establishing an age.
    replace num_curr_age = num_curr_age + 1 if (!missing(expected_age_bkwd))
    replace num_curr_age = 1 if ((!missing(TAGE`month')) & (missing(expected_age_bkwd)))
    replace expected_age_bkwd = TAGE`month' if ((!missing(TAGE`month')) & (missing(expected_age_bkwd)))

    * Decrement the age if we've already used it three times.
    replace expected_age_bkwd = expected_age_bkwd - 1 if (num_curr_age > 3)
    replace num_curr_age = 1 if (num_curr_age > 3)
	
	replace expected_age_bkwd=0 if expected_age_bkwd < 0

    gen expected_age_bkwd`month' = expected_age_bkwd
}
drop num_curr_age expected_age_bkwd

sum expected_age_bkwd*

********************************************************************************
* Section: Check backwards and forwards projections against what is coded
********************************************************************************

*** Count the number of times age matches each projection (within one, in the correct direction).
gen num_fwd_matches = 0
gen num_bkwd_matches = 0
forvalues month = $first_month/$final_month {
    gen fwd_match`month' = ((!missing(TAGE`month')) & (TAGE`month' >= expected_age_fwd`month') & (TAGE`month' <= expected_age_fwd`month' + 1))
    replace num_fwd_matches = num_fwd_matches + 1 if (fwd_match`month' == 1)
    gen bkwd_match`month' = ((!missing(TAGE`month')) & (TAGE`month' <= expected_age_bkwd`month') & (TAGE`month' >= expected_age_bkwd`month' - 1))
    replace num_bkwd_matches = num_bkwd_matches + 1 if (bkwd_match`month' == 1)
}

*check against number of observed months to create problem flag 
gen num_fwd_problem=num_ages-num_fwd_matches
gen num_bkwd_problem=num_ages-num_bkwd_matches

gen anyproblem=0
replace anyproblem=1 if num_fwd_problem > 0 | num_bkwd_problem > 0

tab anyproblem

********************************************************************************
* Section: adjust age to projection if backwards and forwards projection are within 1
********************************************************************************

gen check=0
gen fill=0

gen adj_age$first_month = TAGE$first_month
forvalues month = $second_month/$final_month {

* fix age when it is out of line with backwards and forwards projections
    gen adj_age`month' = TAGE`month'
    replace adj_age`month' = expected_age_fwd`month' if ((!missing(TAGE`month')) & (fwd_match`month' == 0) & (bkwd_match`month' == 0) & (abs(expected_age_fwd`month' - expected_age_bkwd`month') <= 1))
	replace check=1 if ((!missing(TAGE`month')) & (fwd_match`month' == 0) & (bkwd_match`month' == 0) & (abs(expected_age_fwd`month' - expected_age_bkwd`month') <= 1))
	
* fix age when it is missing. Take forward projection first. If no forward projection, then take backward projection. 
	replace fill=1 if missing(adj_age`month') & !missing(expected_age_fwd`month')
	replace adj_age`month'= expected_age_fwd`month' if missing(adj_age`month') & !missing(expected_age_fwd`month')
	replace fill=2 if missing(adj_age`month') & !missing(expected_age_bkwd`month')
	replace adj_age`month'=expected_age_bkwd`month' if missing(adj_age`month') & !missing(expected_age_bkwd`month')

}


********************************************************************************
* Section: Check backwards and forwards projections against adjusted age
********************************************************************************
gen num_adjfwd_matches = 0
gen num_adjbkwd_matches = 0
forvalues month = $first_month/$final_month {
    gen adjfwd_match`month' = ((!missing(adj_age`month')) & (adj_age`month' >= expected_age_fwd`month') & (adj_age`month' <= expected_age_fwd`month' + 1))
    replace num_adjfwd_matches = num_adjfwd_matches + 1 if (adjfwd_match`month' == 1)
    gen adjbkwd_match`month' = ((!missing(adj_age`month')) & (adj_age`month' <= expected_age_bkwd`month') & (adj_age`month' >= expected_age_bkwd`month' - 1))
    replace num_adjbkwd_matches = num_adjbkwd_matches + 1 if (adjbkwd_match`month' == 1)
}

gen num_adjfwd_problem=num_ages-num_adjfwd_matches
gen num_adjbkwd_problem=num_ages-num_adjbkwd_matches

gen any_adj_problem=0
replace any_adj_problem=1 if num_adjfwd_problem > 0 | num_adjbkwd_problem > 0

*******************************************************************************
* Section: create flags for data that remain problematic. 
*******************************************************************************

gen monotonic = 1 /* dpes age always increase? */
gen ageproblem=0 /* are there deviations in age from one observation to the next greater than 5 */
gen childageproblem=0
gen curr_age = adj_age$first_month
forvalues month = $second_month/$final_month {
    replace monotonic = 0 if ((!missing(adj_age`month')) & (!missing(curr_age)) & (adj_age`month' < curr_age))
	replace ageproblem=1 if ((!missing(adj_age`month')) & (!missing(curr_age)) & (abs(adj_age`month'-curr_age) > 5))
	replace childageproblem=1 if ((!missing(adj_age`month')) & (!missing(curr_age)) & (abs(adj_age`month'-curr_age) > 5)) & (curr_age < 18)
    replace curr_age = adj_age`month' if (!missing(adj_age`month'))
}

tab ageproblem anyproblem
tab childageproblem

tab ageproblem any_adj_problem

drop curr_age
drop expected_age_bkwd* expected_age_fwd*
drop adjbkwd* adjfwd*
drop bkwd* fwd*
drop monotonic
drop num_adjbkwd_matches num_adjfwd_matches 
drop anyproblem
drop any_adj_problem


* Create dummies for whether in this interview to be able to create an indicator for whether in interview next month
forvalues w=$first_month/$final_month {
  gen in`w'=0
  replace in`w'=1 if !missing(ERELRP`w')
  }
  
forvalues w=$first_month/$penultimate_month {
  local x=`w'+1
  gen innext`w'=0
  replace innext`w'=1 if in`x'==1
 }

save "$tempdir/person_wide_adjusted_ages", $replace

keep SSUID PNUM EMS* ERELRP* WPFINWGT* EORIGIN* EPAR1TYP* EPAR2TYP* my_race ///
my_racealt my_sex mom_educ* dad_educ* adj_age* mom_age* ///
biomom_age* biomom_educ* dad_age* biodad_age* innext*  ///
biomom_ed_first mom_ed_first dad_ed_first par_ed_first mom_measure ///
check fill TAGE* THTOTINC* TFTOTINC* educ* RGED* RENROLL* EEDGRADE* EEDGREP* RFOODR* RFOODS* ///
RHNUMU18* RHNUMU18WT2* RHNUM65OVER* RHNUM65OVRT2* RHPOV* RHPOVT2* THINCPOV* THINCPOVT2* RHNUMPERWT2* ERESIDENCEID* THNETWORTH*


save "$SIPP14keep/demo_wide_am.dta", $replace

reshape long adj_age EMS ERELRP WPFINWGT EORIGIN EPAR1TYP EPAR2TYP mom_educ dad_educ mom_age biomom_age biomom_educ dad_age biodad_age innext  TAGE THTOTINC TFTOTINC educ RGED RENROLL EEDGRADE EEDGREP RFOODR RFOODS RHNUMPERWT2 RHNUMU18 RHNUMU18WT2 RHNUM65OVER RHNUM65OVRT2 RHPOV RHPOVT2 THINCPOV THINCPOVT2 ERESIDENCEID THNETWORTH, i(SSUID PNUM) j(panelmonth)

label variable adj_age "Adjusted Age"
label variable innext "Is this person interviewed in next month?"

tab adj_age check

tab adj_age fill

save "$SIPP14keep/demo_long_all_am", $replace

drop if missing(TAGE)

save "$SIPP14keep/demo_long_interviews_am", $replace



