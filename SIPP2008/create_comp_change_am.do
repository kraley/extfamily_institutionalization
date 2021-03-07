//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

use "$tempdir/person_wide_adjusted_ages_am"

* drop demographic data 
drop my_race* my_sex* EBORNUS* EMS* EPNDAD* EPNMOM* EPNSPOUS* ERRP* ETYPDAD* ETYPMOM* mom* dad* bio*

********************************************************************************
** Section:  Propagate shhadid_members (a list of ids of people in ego's address)
**           forward into prev_hh_members for missing months.  This allows us to
**           know who was in the household with the respondent in the most recent 
**           month at which the respondent was present.

** Logic:   Walk forward through the months, starting with the second.  When the 
**          respondent is missing, SHHADID will be missing. If missing, we copy 
**          shhadid_members for the previous month into prev_hh_members for the 
**          first missing month. For subsequent months of a continuous gap (stretch 
**          of missing interviews) prev_hh_members for the previous month will exist
**        	so we just copy this into prev_hh_members for this month.
********************************************************************************

gen prev_hh_members$firstmonth = ""
forvalues month = $second_month/$finalmonth {
    local prev_month = `month' - 1
    gen prev_hh_members`month' = shhadid_members`prev_month' if (missing(SHHADID`month') & missing(prev_hh_members`prev_month'))
    replace prev_hh_members`month' = prev_hh_members`prev_month' if (missing(SHHADID`month') & (!missing(prev_hh_members`prev_month')))
}

********************************************************************************
** Section:  Propagate shhadid_members backward into future_hh_members for missing months.  
**           This allows us to know who will be in the household with the 
**           respondent in month in which the respondent reappears.
**
** Logic:  Very similar to the logic for prev_hh_members except that we walk 
**         backward from the penultimate month.
********************************************************************************

gen future_hh_members$finalmonth = ""
forvalues month = $penultimate_month (-1) $firstmonth {
    local next_month = `month' + 1
    gen future_hh_members`month' = shhadid_members`next_month' if (missing(SHHADID`month') & missing(future_hh_members`next_month'))
    replace future_hh_members`month' = future_hh_members`next_month' if (missing(SHHADID`month') & (!missing(future_hh_members`next_month')))
}

********************************************************************************
** Section:  Compute flags indicating whether each previous household member is found anywhere during a contiguous
**          gap in which the respondent is missing.  The flags are encoded in found_prev_hh_member_in_gap:
**           if we find a previous household member in the gap we place a 1 in found_prev_hh_member_in_gap at
**          the same position as the previous household member is found in prev_hh_members.
**           For example, if prev_hh_members5 is " 102 104 303 " and we have found 102 and 303 in the gap
**          found_prev_hh_member_in_gap5 will be "1       1    ".  Note the off-by-one positioning
**           due to the fact that we search for " 102 " when we are looking for 102.  See notes on
**           implementation below.
**
**          Note that found_prev_hh_member_in_gap may not be fully populated for months other than
**          the first month of a gap (and the last month before the gap, just because we copy it there).
**          For example, if 102 is found in month 7 and 303 is found in month 4, the flags for months
**           5-7 will show only 102 because that's all we've seen so far.  Month 4 will show both.
**
** Logic:  Walk backward through the months (we stop at the second because the first month can't have any
**         previous members).  Copy the flags discovered so far if this is not the last month of a gap
**        (since we're walking backward, the last month of the gap is the first month we encounter).
**         If this month is part of a gap (the respondent is missing), for each previous household member
**         look to see if that person appears in this month. If so, put a 1 at the appropriate position
**         in found_prev_hh_member_in_gap for this month.  Note that it doesn't hurt to put a 1 there
**         even if one is already present -- the resulting string is identical to what it already was.

**         Some notes on implementation:
**             The notation " " * strlen(x) creates a string of blanks whose length is the same as
**                 the length of x.
**             We loop through overall_max_shhadid_members possible previous household members.  Since the
**                 has to work for all observations, we have to loop through the most members any household
**                 may have.  That's fine because for households with fewer members word(prev_hh_members, n)
**                 is null for n > the number of prev_hh_members who actually exist for this household.
**             Setting my_hh_member = "X" isn't really necessary but it's safer for the future and maybe a
**                 little easier to read.  If we left my_hh_member empty ("") it currently works fine because
**                 we end up searching for "  ", which never occurs in prev_hh_members.  But it's safer not
**                 to depend on the fact that we don't have redundant spaces.
**             We copy found_prev_hh_member_in_gap into the month before the gap begins.  I don't think we
**                 actually make use of this, but it doesn't hurt.
**             The idiom of searching for " " + my_hh_member + " ", for example that would be " 102 " for 
**                 member 102, prevents incorrectly finding 1102 when you're looking for 102.
********************************************************************************

* Setting up label for different ways we can observe or infer comp_change
#delimit ;
label define comp_change_reason   0 "No change"
								  1 "Observed in adjascent months"
								  2 "First appearance (not age 0)"
								  3 "Reappearance"
								  4 "Disappearance"
								  5 "Compare across gap";
								  
label define comp_change          0 "No change"
                                  1 "Composition Change";								  
#delimit cr

gen found_prev_hh_member_in_gap$firstmonth = ""
forvalues month = $finalmonth (-1) $second_month {
    display "Panel Month `month'"
    gen found_prev_hh_member_in_gap`month' = " " * strlen(prev_hh_members`month') if (missing(SHHADID`month'))

    * This copies the flags we've found so far (from the next month to this one) except of course we don't try to copy
    * anything into the final month since there is no succeeding month.
    if (`month' < $finalmonth) {
        local next_month = `month' + 1
        replace found_prev_hh_member_in_gap`month' = found_prev_hh_member_in_gap`next_month' if (missing(SHHADID`next_month'))
    }

    forvalues my_hh_member_num = 1/`=overall_max_shhadid_members' {
        gen my_hh_member = word(prev_hh_members`month', `my_hh_member_num') if (missing(SHHADID`month'))
        replace my_hh_member = "X" if missing(my_hh_member)

        * position is computed only if there is a previous member to search for (my_hh_member != "X"),
        * respondent is missing this month, and previous member is found somewhere in this month (the strpos
        * looks for my_hh_member in ssuid_members).
        tempvar position
        gen `position' = strpos(prev_hh_members`month', " " + my_hh_member + " ") if ((my_hh_member != "X") & (missing(SHHADID`month')) & (strpos(ssuid_members`month', " " + my_hh_member + " ") != 0))

        * Now if position is set we know we found the member and we know at what position in the string.  
        * Remember that we search for " 102 " when we want to find 102, so the position of the 1 in found_prev_hh_member_in_gap
        * is at the poistion of the first space of " 102 " in prev_hh_members.
        replace found_prev_hh_member_in_gap`month' = substr(found_prev_hh_member_in_gap`month', 1, `position' - 1) + "1" + substr(found_prev_hh_member_in_gap`month', `position' + 1, .) if (!missing(`position'))
        drop my_hh_member
    }
}

********************************************************************************
** Section:  Compute flags indicating if each future household member is found 
**           anywhere during a contiguous gap in which the respondent is missing.
**           The flags are encoded in found_future_hh_member_in_gap
**           in the same way as found_prev_hh_member in gap.  See above.
********************************************************************************

gen found_future_hh_member_in_gap$finalmonth = ""
forvalues month = $firstmonth/$penultimate_month {
    display "panel month `month'"
    gen found_future_hh_member_in_gap`month' = " " * strlen(future_hh_members`month') if (missing(SHHADID`month'))

    * Go ahead and copy what we've found so far (except at the first missing month).
    if (`month' > $firstmonth) {
        local prev_month = `month' - 1
        replace found_future_hh_member_in_gap`month' = found_future_hh_member_in_gap`prev_month' if (missing(SHHADID`prev_month'))
    }

    forvalues my_hh_member_num = 1/`=overall_max_shhadid_members' {
        gen my_hh_member = word(future_hh_members`month', `my_hh_member_num') if (missing(SHHADID`month'))
        replace my_hh_member = "X" if missing(my_hh_member)
        tempvar position
        gen `position' = strpos(future_hh_members`month', " " + my_hh_member + " ") if ((my_hh_member != "X") & (missing(SHHADID`month')) & (strpos(ssuid_members`month', " " + my_hh_member + " ") != 0))
        replace found_future_hh_member_in_gap`month' = substr(found_future_hh_member_in_gap`month', 1, `position' - 1) + "1" + substr(found_future_hh_member_in_gap`month', `position' + 1, .) if (!missing(`position'))
        drop my_hh_member
    }
}

********************************************************************************
** Section:  Compute composition change.  Outputs for each month are:
**           comp_change, a flag indicating whether or not there is any composition change;
**           comp_change_reason, an indicator of why we believe there is a change;
**           leavers, a string containing the person numbers of those who leave from ego's perspective;
**          arrivers, a string containing the person numbers of those who arrive from ego's perspective;
**           stayers, a string containing the person numbers of those who stay from ego's perspective;

**           In general, changes are marked on the first of the two months that differ.  Thus, when respondent
**           appears at age greater than 0, the change in marked in the month before respondent appears.
**
** Logic:  The major cases are:
**         1) Respondent is present in adjacent months.
**         2) Respondent's first appearance is after month 1, but age is non-zero (non-birth).

**         For each possible case we compute a flag, comp_change_case, indicating whether or not this
**         observation satisfies the conditions to be such a case.  This is for convenience so we don't
**         have to replicate the complicated if condition throughout the code for this case.
**
**         For details about string manipulations and other fancy Stata use, see 
**=         "Some notes in implementation" in earlier comments in this file.
********************************************************************************
// first a quick loop to fill in missing values of max_shhadid_members*

forvalues month=$firstmonth/$finalmonth {
    egen max_shhadid_members`month'= max(mx_shhadid_members`month')
}

forvalues month = $firstmonth/$penultimate_month {
    local next_month = `month' + 1

    display "Computing comp change for panel model `month'"

    *** Start by assuming this month is not interesting.
    gen comp_change`month' = .
    gen comp_change_reason`month' = 0

    gen leavers`month' = " "
    gen arrivers`month' = " "
    gen stayers`month' = " "


    ********************************************************************************
    ** Section:  Compute composition change when respondent is present in adjacent months.
    ********************************************************************************

    *** If we have data in both months, just compare HH members (strings shhadid_members this month compared to shhadid_members next month).
    replace comp_change`month' = (shhadid_members`month' != shhadid_members`next_month') if ((!missing(SHHADID`month')) & (!missing(SHHADID`next_month')))
    replace comp_change_reason`month' = 1 if ((shhadid_members`month' != shhadid_members`next_month') & (!missing(SHHADID`month')) & (!missing(SHHADID`next_month')))
    gen comp_change_case = ((shhadid_members`month' != shhadid_members`next_month') & (!missing(SHHADID`month')) & (!missing(SHHADID`next_month')))

    display "Computing comp change for months with adjacent data"
    * Since we have adjacent data, you're a leaver if you're in this HH but not the next and a stayer otherwise.
    forvalues my_hh_member_num = 1/`=max_shhadid_members`month'' {
        gen my_hh_member = word(shhadid_members`month', `my_hh_member_num') if (comp_change_case == 1)
        * This is a bit lazy but prevents having to check for missing my_hh_member in all the places below, so overall it's easier to read.
        replace my_hh_member = "XXXX" if missing(my_hh_member)

        replace leavers`month' = leavers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_hh_member != "XXXX") & (strpos(shhadid_members`next_month', " " + my_hh_member + " ") == 0))
        replace stayers`month' = stayers`month' + my_hh_member + " " if ((comp_change_case == 1) & (strpos(shhadid_members`next_month', " " + my_hh_member + " ") != 0))

        drop my_hh_member
    }

    * Since we have adjacent data, you're an arriver if you're in the next HH but not this one.  We already took care of stayers.
    forvalues my_hh_member_num = 1/`=max_shhadid_members`next_month'' {
        gen my_hh_member = word(shhadid_members`next_month', `my_hh_member_num') if (comp_change_case == 1)
        replace my_hh_member = "XXXX" if missing(my_hh_member)

        replace arrivers`month' = arrivers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_hh_member != "XXXX") & (strpos(shhadid_members`month', " " + my_hh_member + " ") == 0))

        drop my_hh_member
    }

    drop comp_change_case

    *******************************************************************************
    ** Section:  Compute composition change for respondent's first appearance when not a birth.
    **           The change is marked in this month if the appearance is in the following month,
    **           consistent with our choice of marking a change of state in the first month of the two that differ.
    **
    **           Note that we propagate age and weight back from the month in which respondent appears to the
    **           month at which we mark the change.  This is necessary because there is no age and weight data
    **           in the month where respondent is missing.  It's not ideal, but it's adequate.
    *******************************************************************************

    *** If next month is ego's first and it's not a birth (age > 0), it's a change.
    * We also need to populate age and weight from the next month since ego has no data in this month.
    replace comp_change`month' = 1 if ((`next_month' == my_first_month) & (adj_age`next_month' > 0))
    replace comp_change_reason`month' = 2 if ((`next_month' == my_first_month) & (adj_age`next_month' > 0))
    gen comp_change_case = ((`next_month' == my_first_month) & (adj_age`next_month' > 0))
    replace adj_age`month' = adj_age`next_month' if (comp_change_case == 1)
    replace WPFINWGT`month' = WPFINWGT`next_month' if (comp_change_case == 1)

    display "Computing comp change for non-infant ego's first month."
    * We look at the "gap" from first month to this month to see if anyone from the future HH shows up and set changes accordingly.
    * For anyone we see in the "gap" they arrive from our perspective.  Others we don't know so we assume ego and other were already together.
    forvalues my_hh_member_num = 1/`=max_shhadid_members`next_month'' {
        gen my_hh_member = word(shhadid_members`next_month', `my_hh_member_num') if (comp_change_case == 1)
        * This is a bit lazy but prevents having to check for missing my_hh_member in all the places below, so overall it's easier to read.
        replace my_hh_member = "XXXX" if missing(my_hh_member)
        gen my_pos = strpos(future_hh_members`month', " " + my_hh_member + " ") if (comp_change_case == 1)
        replace arrivers`month' = arrivers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_pos != 0) & (substr(found_future_hh_member_in_gap`month', my_pos, 1) == "1"))
        drop my_pos

        drop my_hh_member
    }

    drop comp_change_case

    display "Computing comp change for ego moving from missing to present."
	*******************************************************************************
    ** Section: Dealing with reappearances. If we are moving from a month in which 
	** ego is missing to one in which ego is present there is a composition change 
	** if we have seen any member of the future household in gap during which ego was missing.
    * Again, we also need to populate age and weight from the next month since ego has no data in this month.
	*******************************************************************************
	
    replace comp_change`month' = 1 if ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (`next_month' > my_first_month) & (indexnot(found_future_hh_member_in_gap`month', " ") != 0))
    replace comp_change_reason`month' = 3 if ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (`next_month' > my_first_month) & (indexnot(found_future_hh_member_in_gap`month', " ") != 0))
    gen comp_change_case = ((missing(SHHADID`month')) & (!missing(SHHADID`next_month')) & (`next_month' > my_first_month) & (indexnot(found_future_hh_member_in_gap`month', " ") != 0))
    replace adj_age`month' = adj_age`next_month' if (comp_change_case == 1)
    replace WPFINWGT`month' = WPFINWGT`next_month' if (comp_change_case == 1)

    * For anyone we see in the "gap" they arrive from our perspective.  Others we don't know so we assume ego and other were already together.
    forvalues my_hh_member_num = 1/`=max_shhadid_members`next_month'' {
        gen my_hh_member = word(shhadid_members`next_month', `my_hh_member_num') if (comp_change_case == 1)
        * This is a bit lazy but prevents having to check for missing my_hh_member in all the places below, so overall it's easier to read.
        replace my_hh_member = "XXXX" if missing(my_hh_member)
        gen my_pos = strpos(future_hh_members`month', " " + my_hh_member + " ") if (comp_change_case == 1)
        replace arrivers`month' = arrivers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_pos != 0) & (substr(found_future_hh_member_in_gap`month', my_pos, 1) == "1"))
        drop my_pos

        drop my_hh_member 
    } 
    drop comp_change_case


    display "Computing comp change for ego moving from present to missing."
	******************************************************************************
    ** Section: If we are moving from a month in which ego is present to one in which ego is missing
    * there is a composition change if we have seen any member of the current household in gap 
    * during which ego is missing as we look forward.
	*******************************************************************************
    
	replace comp_change`month' = 1 if ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") != 0))
    replace comp_change_reason`month' = 4 if ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") != 0))
    gen comp_change_case = ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") != 0))

    * For anyone we see in the "gap" they depart from our perspective.  Others we don't know so we assume we stay together.
    forvalues my_hh_member_num = 1/`=max_shhadid_members`month'' {
        gen my_hh_member = word(shhadid_members`month', `my_hh_member_num') if (comp_change_case == 1)
        * This is a bit lazy but prevents having to check for missing my_hh_member in all the places below, so overall it's easier to read.
        replace my_hh_member = "XXXX" if missing(my_hh_member)
        gen my_pos = strpos(prev_hh_members`next_month', " " + my_hh_member + " ") if (comp_change_case == 1)
        replace leavers`month' = leavers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_pos != 0) & (substr(found_prev_hh_member_in_gap`next_month', my_pos, 1) == "1"))
        drop my_pos

        drop my_hh_member
    }

    drop comp_change_case



    display "Computing comp change for ego missing in a gap in which all past and future HH members are also missing."
	******************************************************************************
    *** Section If we are moving from a month in which ego is present to one in which ego is missing
    * and we do not see any member of the current household  or any member of the future
    * household in the gap looking forward, we compare the current household to the 
	* future household as if we move into the future household in the first missing month. 
	* If there there is no future HH (ego's last appearance) we don't code a household change.
	******************************************************************************
    replace comp_change`month' = (shhadid_members`month' != future_hh_members`next_month') if ((!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(future_hh_members`next_month', " ") != 0) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") == 0) & (indexnot(found_future_hh_member_in_gap`next_month', " ") == 0))
    replace comp_change_reason`month' = 5 if ((shhadid_members`month' != future_hh_members`next_month') & (!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(future_hh_members`next_month', " ") != 0) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") == 0) & (indexnot(found_future_hh_member_in_gap`next_month', " ") == 0))

    gen comp_change_case = ((shhadid_members`month' != future_hh_members`next_month') & (!missing(SHHADID`month')) & (missing(SHHADID`next_month')) & (indexnot(future_hh_members`next_month', " ") != 0) & (indexnot(found_prev_hh_member_in_gap`next_month', " ") == 0) & (indexnot(found_future_hh_member_in_gap`next_month', " ") == 0))

    forvalues my_hh_member_num = 1/`=max_shhadid_members`month'' {
        gen my_hh_member = word(shhadid_members`month', `my_hh_member_num') if (comp_change_case == 1)
        * This is a bit lazy but prevents having to check for missing my_hh_member in all the places below, so overall it's easier to read.
        replace my_hh_member = "XXXX" if missing(my_hh_member)

        replace leavers`month' = leavers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_hh_member != "XXXX") & (strpos(future_hh_members`next_month', " " + my_hh_member + " ") == 0))
        replace stayers`month' = stayers`month' + my_hh_member + " " if ((comp_change_case == 1) & (strpos(future_hh_members`next_month', " " + my_hh_member + " ") != 0))

        drop my_hh_member
    }

    forvalues my_hh_member_num = 1/`=overall_max_shhadid_members' {
        gen my_hh_member = word(future_hh_members`next_month', `my_hh_member_num') if (comp_change_case == 1)
        replace my_hh_member = "XXXX" if missing(my_hh_member)

        replace arrivers`month' = arrivers`month' + my_hh_member + " " if ((comp_change_case == 1) & (my_hh_member != "XXXX") & (strpos(shhadid_members`month', " " + my_hh_member + " ") == 0))

        drop my_hh_member
    }


    * We set comp_change to zero if ego was present this month and this is not ego's last month.
    replace comp_change`month' = 0 if (missing(comp_change`month') & (!missing(SHHADID`month') & (`month' != my_last_month)))
	
	replace comp_change_reason`month'=. if missing(comp_change`month')

	label var comp_change_reason`month' "Codes for whether comp_change is observed in adjascent months or inferred"
    label values comp_change_reason`month' comp_change_reason
	
	label var comp_change`month' "Indicator for whether a composition change is observed or inferred"
	label values comp_change`month' comp_change
	
	drop comp_change_case
}

drop _*

save "$SIPP08keep/comp_change_am.dta", $replace
