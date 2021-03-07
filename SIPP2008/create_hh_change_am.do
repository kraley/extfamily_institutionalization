//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 


local panel "08"

use "${SIPP`panel'keep}/comp_change_am.dta", clear

#delimit ; 
label define addr_change          0 "No move"
                                  1 "Move";	 
#delimit cr

********************************************************************************
* Function Propagate shhadid_members forard into prev_SHHADID for missing months.
********************************************************************************

gen prev_SHHADID$firstmonth = .
forvalues month = $second_month/$finalmonth {
    local prev_month = `month' - 1
    gen prev_SHHADID`month' = SHHADID`prev_month' if (missing(SHHADID`month') & missing(prev_SHHADID`prev_month'))
    replace prev_SHHADID`month' = prev_SHHADID`prev_month' if (missing(SHHADID`month') & (!missing(prev_SHHADID`prev_month')))
}

********************************************************************************
** Function:  Propagate shhadid_members backward into future_hh_members for missing months.  
********************************************************************************

gen future_SHHADID$finalmonth = .
forvalues month = $penultimate_month (-1) $firstmonth {
    local next_month = `month' + 1
    gen future_SHHADID`month' = SHHADID`next_month' if (missing(SHHADID`month') & missing(future_SHHADID`next_month'))
    replace future_SHHADID`month' = future_SHHADID`next_month' if (missing(SHHADID`month') & (!missing(future_SHHADID`next_month')))
}

********************************************************************************
** Function: walk backward through the months and for each month in which ego is missing  compare prev_SHHAIDD to see if we find anyone
********************************************************************************

gen found_prev_SHHADID$firstmonth = .
forvalues month = $finalmonth (-1) $second_month {
	gen found_prev_SHHADID`month'= 0 if (missing(SHHADID`month'))
	gen found_prev_SHHADID_in_gap`month'=0 if (missing(SHHADID`month'))
	replace found_prev_SHHADID`month' = 1 if ((missing(SHHADID`month')) & (strpos(ssuid_shhadid`month', " " + string(prev_SHHADID`month') + " ") != 0))
	replace found_prev_SHHADID_in_gap`month' = 1 if ((missing(SHHADID`month')) & (strpos(ssuid_shhadid`month', " " + string(prev_SHHADID`month') + " ") !=0))
	if (`month' < $finalmonth) {
		local next_month = `month' + 1
		replace found_prev_SHHADID_in_gap`month' = 1 if ((missing(SHHADID`month')) & (found_prev_SHHADID_in_gap`next_month' == 1))
	}
}

********************************************************************************
** Function: walk forward through the months 
********************************************************************************

gen found_future_SHHADID$finalmonth = .
forvalues month = $firstmonth/$penultimate_month {
	gen found_future_SHHADID`month'= 0 if (missing(SHHADID`month'))
	gen found_future_SHHADID_in_gap`month'=0 if (missing(SHHADID`month'))
	replace found_future_SHHADID`month' = 1 if ((missing(SHHADID`month')) & (strpos(ssuid_shhadid`month', " " + string(prev_SHHADID`month') + " ") != 0))
	replace found_future_SHHADID_in_gap`month' = 1 if ((missing(SHHADID`month')) & (strpos(ssuid_shhadid`month', " " + string(prev_SHHADID`month') + " ") !=0))
	if (`month' > $finalmonth) {
		local prev_month = `month' - 1
		replace found_future_SHHADID_in_gap`month' = 1 if ((missing(SHHADID`month')) & (found_future_SHHADID_in_gap`prev_month' == 1))
	}
}

*******************************************************************************
** Function: Compute address change.
*******************************************************************************

forvalues month = $firstmonth/$penultimate_month {
    local next_month = `month' + 1

    * Start by assuming this month is not interesting.
    gen addr_change`month' = .

    * If we have data in both months, just compare HH members.
    replace addr_change`month' = (SHHADID`month' != SHHADID`next_month') if ((!missing(SHHADID`month')) & (!missing(SHHADID`next_month')))

    * If we are moving from a month in which ego is missing to one in which ego is present
    * there is an address change if we have seen the future SHHADID in the gap during which ego was missing
    * UNLESS this is ego's birth.
    * We also need to populate age and weight from the next month since ego has no data in this month.
    replace addr_change`month' = 1 if ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (found_future_SHHADID_in_gap`month' == 1))
    replace adj_age`month' = adj_age`next_month' if ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (found_future_SHHADID_in_gap`month' == 1))
    replace WPFINWGT`month' = WPFINWGT`next_month' if ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (found_future_SHHADID_in_gap`month' == 1))
    * Undo those changes if this is birth.
    replace addr_change`month' = . if ((`next_month' == my_first_month) & (adj_age`next_month' == 0))
    replace adj_age`month' = . if ((`next_month' == my_first_month) & (adj_age`next_month' == 0))
    replace WPFINWGT`month' = . if ((`next_month' == my_first_month) & (adj_age`next_month' == 0))

    * If we are moving from a month in which ego is present to one in which ego is missing
    * there is an address change if we have seen the current SHHADID in the gap 
    * during which ego is missing as we look forward.
    replace addr_change`month' = 1 if ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (found_prev_SHHADID_in_gap`next_month' == 1))

    * If we are moving from a month in which ego is present to one in which ego is missing
    * and we do not see the current SHHADID in the gap looking forward,
    * we compare the current SHHADID to the future SHHADID as if we move into the
    * future household in the first missing month, unless there is no future SHHADID
    * (ego's last appearance).
    replace addr_change`month' = (SHHADID`month' != future_SHHADID`next_month') if ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (!missing(future_SHHADID`next_month')) & (found_prev_SHHADID_in_gap`next_month' != 1))


    * Tab "original" addr_change and comp_change variables.
    tab addr_change`month' comp_change`month', m

    * We once forced them up to have the same denominator by setting to zero if missing and the other variable is not missing.
	* but this is not appropriate. Sometimes we can know if there was an address change even if we don't know household composition
	* Keeping this here to document.
*    replace addr_change`month' = 0 if (missing(addr_change`month') & (!missing(comp_change`month')))
*    replace comp_change`month' = 0 if (missing(comp_change`month') & (!missing(addr_change`month')))

*    tab addr_change`month' comp_change`month', m
}

gen original=1 if !missing(SHHADID1)
gen agemonth1=adj_age1 if original==1

keep SSUID EPPPNUM SHHADID* adj_age* comp_change* addr_change* comp_change_reason* original agemonth1

reshape long SHHADID adj_age comp_change addr_change comp_change_reason, i(SSUID EPPPNUM) j(panelmonth)

merge 1:1 SSUID EPPPNUM panelmonth using "${SIPP`panel'keep}/demo_long_all_am.dta"

drop if panelmonth > $finalmonth

assert _merge==3

drop _merge

gen hh_change=comp_change
replace hh_change=1 if addr_change==1

gen inmonth = !missing(ERRP)

gen insample=0
* Keep if in this month and next
replace insample=1 if inmonth==1 & innext==1
* also keep if hh_change is not missing. This would be (for example) if not in current month, 
* but in next one and people you live with in next month appear while ego is missing.
* hh_change also ==1 if in current month and not in next, but some of the people 
* you are living with now appear in "next" month while ego is missing.
* hh_change can =0 if not in next month but in a subsequent one and everyone ego 
* is with in this month is in the household in the next appearence
replace insample=2 if insample==0 & !missing(comp_change)
replace insample=3 if insample==0 & !missing(hh_change)

	label var comp_change_reason "Codes for whether comp_change is observed in adjascent months or inferred"
    label values comp_change_reason comp_change_reason
	
	label var comp_change "Indicator for whether a composition change is observed or inferred"
	label values comp_change comp_change
	
	label var addr_change "Indicator for whether individual moved"
	label values addr_change addr_change

save "${SIPP`panel'keep}/hh_change_am.dta", $replace
