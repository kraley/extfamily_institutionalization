//==============================================================================
//===== Children's Household Instability Project                                                    
//===== Dataset: SIPP2008                                                                               
//===== Purpose: Evaluate how much missing data might bias our analyses
//==============================================================================

* Setup to put output in document

	putdocx begin

* Read in data 
use "$SIPP08keep/hh_change.dta", clear

keep if original==1
drop if SWAVE==15

gen original_child=1 if agewave1 < 18 & original==1

********************************************************************************
* Section: Focusing on original sample members, what proportion of the potential
*          observations are fully observed? Of those intervals that are missing,
*          what proportion are due to a whole household going missing versus a 
*          partial household going missing?
*
* Logic: Create an indicator of whether person is observed both in this wave and
*        in the next, a fully-observed interval. Compare to the number of 
*	     intervals that would have existed if ego had been in all 15 waves 
*        (i.e. _N in wave 1 (105633) times 14 (1478862). 
********************************************************************************

* Get _N in Wave 1
egen originals=count(inwave) if SWAVE==1 
egen okids=count(inwave) if SWAVE==1 & original_child==1
egen originalkids=max(okids)

* calculate the number of possible observations
local inwave1: di %7.0fc = `=originals'
local childinwave1: di %7.0fc = `=originalkids'
local possible_original_obs = `=originals'*14
local possible_origkid_obs = `=originalkids'*14
local dpossible_original_obs: di %9.0fc = `possible_original_obs'

gen interval=1 if inwave==1 & innext==1   // number of fully-obwerved intervals

*calculate the number of fully observed intervals observed of original (wave 1)
*respondents.
egen numorigint=count(interval)
egen nkorigint=count(interval) if original_child==1
egen nkidorigint=max(nkorigint)
local number_original_intervals: di %9.0fc = `=numorigint'
local number_origkid_intervals: di %9.0fc = `=nkidorigint'
local prop_fully_observed=int(100*`=numorigint'/`possible_original_obs')
local prop_fully_obskids=int(100*`=nkidorigint'/`possible_origkid_obs')
local miss_orig =`possible_original_obs'-`=numorigint'
local miss_origkid =`possible_origkid_obs'-`=nkidorigint'

local dmiss_orig: di %7.0fc = `miss_orig'
local dmiss_origkid: di %7.0fc = `miss_origkid'

	putdocx paragraph
	putdocx text ("Many SIPP respondents miss one or more interviews. Wave 1 ")
	putdocx text ("collected data on `inwave1' original sample members ")
	putdocx text ("(`childinwave1' children). The maximum ")
	putdocx text ("possible number of observed intervals for original sample ")
	putdocx text ("members is `dpossible_original_obs' (`inwave1' times 14), ")  
	putdocx text ("but we have data on only `number_original_intervals' (`prop_fully_observed'%). ")
	putdocx text ("Among original children, we have data on a similar proportion ")
	putdocx text ("(`prop_fully_obskids' %) of potential intervals. ")

	putdocx paragraph
	putdocx text ("We can categorize the `dmiss_orig' missing intervals into two ")
	putdocx text ("groups. In one group, the whole household goes missing ")
	putdocx text ("because everyone in a household refused to be interviewed ")
	putdocx text ("or was impossible to locate for one or move waves. ")

*Calculate the number missing because whole household went missing. This would be
*where comp_change is missing or comp_change is not missing but comp_change_reason
*is 5 (compare across a gap).

gen whole_goes_missing=1 if missing(comp_change) 
replace whole_goes_missing=0 if !missing(comp_change) // see one exception next line
replace whole_goes_missing=1 if !missing(comp_change) & comp_change_reason==5

*group observations of original sample members by whether the whole household went missing next wave
egen norigwgm=count(original) if whole_goes_missing==1
egen numorigwgm=max(norigwgm)
egen norigwgm_kid=count(original) if whole_goes_missing & original_child==1
egen numorigwgm_kid=max(norigwgm_kid)
local wgm: di %7.0fc = `=numorigwgm'
local perwgm: di %3.0f =100*`=numorigwgm'/`miss_orig'
local wgm_kid: di %7.0fc = `=numorigwgm_kid'
local perwgm_kid: di %3.0f = 100*`=numorigwgm_kid'/`miss_origkid'

	putdocx text ("This was the case for `wgm' (`perwgm' %) of the missing intervals. ")
	putdocx text ("In the second, smaller group, only some of the people in the household go missing. ")
	putdocx text ("This would happen if some household members moved out and ")
	putdocx text ("could not be interviewed. It also happens by design as children ")
	putdocx text ("less than age 15 are not followed when they no longer live with ")
	putdocx text ("a SIPP member 15 years old or over. For example, if a child were ")
	putdocx text ("originally observed in his mother's household and he went to ")
	putdocx text ("go live with his father he would not be included after he ")
	putdocx text ("moved to his father's household. Despite the difference in treatment, ")
	putdocx text ("the proportion of missing observations that are in the first group ") 
	putdocx text ("is similar for original children (`perwgm_kid' %) as it is for the whole sample. ")
	putdocx text ("`wgm_kid' (`perwgm_kid') % of the missing intervals are missing ")
	putdocx text ("because the whole household went missing. ")

preserve

********************************************************************************
* section: What proportion of original household members have complete data?
*          And is missingness associated with household instability before
*          We infer comp_change?
********************************************************************************

* Start with individuals rather than intervals as the unit of analysis 
* so that we can characterize 

use "$SIPP08keep/comp_change.dta", clear

* original respondents have same value for SHHADID1
gen original=1 if !missing(SHHADID1)
gen original_child=1 if original==1 & adj_age1 < 18

keep if original==1

gen nummissing=0
gen ncompchange=0
gen age=adj_age1

label variable nummissing "Number of waves without an interview"

forvalues a=1/15 {
replace nummissing=nummissing+1 if missing(SHHADID`a')
}

gen nobs=15-nummissing
label variable nobs "Number of observed waves"

recode nummissing (0=0)(1/14=1), gen(anymissing)

* create new comp_change variable with only fully observed data

forvalues w=1/14{
	gen comp_change_before_infer`w'=comp_change`w' if comp_change`w'==0| comp_change_reason`w'==1
}

* Have to insert this paragraph here before reshaping*
sort anymissing
by anymissing: gen norigfull=_N 
egen numorigfull=min(norigfull) // the group with no missing is smaller


egen originals=count(original) // count all cases
local foriginals: di %7.0fc = `=originals' 
local fnumorigfull: di %7.0fc =`=numorigfull'
local per_orig_fully_obs: di %2.0f = 100*`=numorigfull'/`=originals'

	
	putdocx paragraph
	putdocx text ("------------------out of place ----------------------------")
	putdocx paragraph
	putdocx text ("There are substantial amounts of missing data. Of the `foriginals' ")
	putdocx text ("individuals observed in the first wave, only ")
	putdocx text ("`fnumorigfull' (`per_orig_fully_obs'%) are ")
	putdocx text ("observed at every interview until wave 15. ")
	putdocx paragraph
	putdocx text ("------------------out of place ----------------------------")
**************************************************************************

* reshape data to long to be able to calculate rates 	
keep SSUID EPPPNUM comp_change* comp_change_before_infer* comp_change_reason* anymissing original_child

reshape long comp_change comp_change_before_infer comp_change_reason, i(SSUID EPPPNUM) j(SWAVE)

sort anymissing
by anymissing: gen nanymissing=_N

gen comp_change_before_infer_am=comp_change_before_infer if anymissing==1
gen comp_change_before_infer_nm=comp_change_before_infer if anymissing==0
gen cc_before_infer_am_kid=comp_change_before_infer if anymissing==1 & original_child==1
gen cc_before_infer_nm_kid=comp_change_before_infer if anymissing==0 & original_child==1
gen cc_before_infer_kid=comp_change_before_infer if original_child==1
gen cc_kid=comp_change if original_child==1

egen rate_all=mean(comp_change_before_infer)
egen rate_am=mean(comp_change_before_infer_am)
egen rate_nm=mean(comp_change_before_infer_nm) 
egen rate_ai=mean(comp_change)
egen rate_kid=mean(cc_before_infer_kid)
egen rate_am_kid=mean(cc_before_infer_am_kid)
egen rate_nm_kid=mean(cc_before_infer_nm_kid)
egen rate_ai_kid=mean(cc_kid)

label variable rate_all "rate of household instability before inference of missing data"
label variable rate_am "hh instability before inference, any missing data"
label variable rate_nm "hh instability before inference, no missing data"
label variable rate_ai "hh instability before inference, no missing data"
label variable rate_kid "hh instability before inference, age < 18"
label variable rate_am_kid "hh instability before inference, any missing data, age < 18"
label variable rate_nm_kid "hh instability before inference, no missing data, age < 18"

sum rate*

local compchangeall: di %6.3f = `=rate_all'
local cckid: di %6.3f = `=rate_kid'
local compchangeanymissing: di %6.3f = `=rate_am'
local compchangenomissing: di %6.3f = `=rate_nm'
local ccanymisskid: di %6.3f = `=rate_am_kid'
local ccnomisskid: di %6.3f = `=rate_nm_kid'
local ccaikid: di %6.3f = `=rate_ai_kid'
local compchangeafterinfer: di%6.3f = `=rate_ai'

	putdocx paragraph
	putdocx text ("Missing data have the potential to downwardly bias our ") 
	putdocx text ("results if missingness is associated with household ")
	putdocx text ("instability and missing intervals are simply dropped from ")
	putdocx text ("the analysis. ")
	putdocx text ("Supporting this intuition, we find that individuals with at ")
	putdocx text ("least some missing data are more likely to have experienced ")
	putdocx text ("composition changes in fully-observed intervals than ")
	putdocx text ("individuals with complete data. ")
	putdocx text ("The rate of household change for individuals that ")
	putdocx text ("are missing at any wave is `compchangeanymissing' compared to ")
	putdocx text ("`compchangenomissing' for those with complete data. ")
	putdocx text ("Similarly, for children the rate of household composition change ")
	putdocx text ("for children with any missing waves is `ccanymisskid' ")
	putdocx text ("compared to `ccnomisskid' for those with no missing waves.")
	
	putdocx paragraph
	putdocx text ("To reduce the bias due to missing data, we recover some of ")
	putdocx text ("the missing intervals by inferring composition change ")
	putdocx text ("from the available data. For the first type of missing ")
	putdocx text ("data, where an entire household goes missing, we compare each ")
	putdocx text ("person’s household composition at their last appearance before ")
	putdocx text ("the gap in data to their first appearance after the gap. If ")
	putdocx text ("the households are the same, we code no composition change; ")
	putdocx text ("if they are different they are coded as having a composition ")
	putdocx text ("change. In the middle, the composition change variable remains missing.")
	
restore	
	
egen obsafterinfer=count(comp_change)
local recover =`=obsafterinfer'-`=numorigint'
local drecover: di %6.0fc = `recover'
local perrecover: di %3.0f = 100*`recover'/`miss_orig'
	
	putdocx paragraph
	putdocx text ("For the second type of missing data, where only some of the ")
	putdocx text ("people in a household go missing, we infer a composition ")
	putdocx text ("change for everyone in the household. That is, when a person ")
	putdocx text ("transitions to missing and someone who was in that person's ")
	putdocx text ("household appears in the data while they are missing, ")
	putdocx text ("we code both the person who went missing and the person ")
	putdocx text ("who remains in the data as having a composition change. ")
	putdocx text ("Analogously, when a person (ego) reappears in the data after a ")
	putdocx text ("stretch of missing interviews, ")
	putdocx text ("we code a composition change for everyone in the household ")
	putdocx text ("that appeared in the data while ego was missing. ")
	putdocx text ("First appearances in the data after Wave 1 are automatically ")
	putdocx text ("coded as a household change for the person who appeared, ")
	putdocx text ("unless the person is less than one year old. We do not count ")
	putdocx text ("being born as a composition change from the perspective of ")
	putdocx text ("the infant, but it is a household change for everyone else ")
	putdocx text ("the infant lives with. Last appearances in the data are not ")
	putdocx text ("counted as household changes unless the people ego last lived ")
	putdocx text ("with are observed in subsequent interviews. By inferring ")
	putdocx text ("composition change in this way we are able to recover ")
	putdocx text ("`drecover' (`perrecover' %) ")
	putdocx text ("missing intervals and reduce the downward bias in our estimates. ")
	putdocx text ("Using only fully_observed intervals the rate of composition ")
	putdocx text ("change is `compchangeall' compared to `compchangeafterinfer' after inferring. ")
	putdocx text ("For children, the estimated rate of change is `cckid' before ")
	putdocx text ("inferring and `ccaikid' after.")

	putdocx paragraph
	putdocx text ("Despite our efforts to recover missing data, we believe that ")
	putdocx text ("we underestimate household instability. ")
	putdocx text ("Composition change is still coded missing when a whole ")
	putdocx text ("household disappears from the data and never reappears. ")
	putdocx text ("If a household goes missing in Wave 3 and reappears in Wave 7, ")
	putdocx text ("composition change is coded missing for Waves 4-6. ")
	putdocx text ("It seems likely that the missing periods have higher levels ")
	putdocx text ("of instability than the periods we capture. Analysis weights ")
	putdocx text ("correct for some of this bias to the extent that household ")
	putdocx text ("instability is correlated with factors used to generate the ")
	putdocx text ("weights. Additionally, we miss instability that occurs between ")
	putdocx text ("interviews. Using the monthly household rosters collected in Wave 2 ")
	
do ".\SIPP2008\short_transitions.do"	

egen rate_short=mean(compchange_ref)
egen rate_wave=mean(compchange_wave) if ref==1
local compchangeshort: di %6.3f = `=rate_short'
local rateratio : di %4.2f = 4*`=rate_short'/(`=rate_wave')
	
	putdocx text ("for household changes between Wave 1 and Wave 2, we determined that ")
	putdocx text ("the rate of household change including household changes ")
	putdocx text ("that occur between waves is `rateratio' times the rate estimated ")
	putdocx text ("by comparing household composition in the interview months. ")
	putdocx text ("Thus, we believe that these are slightly conservative estimates, but ")
	putdocx text ("probably do not underestimate by much.")

		putdocx save "$results/missingreport.docx", $replace
	
/*	
	
*******************************************************************************
* Section: Do we observe children < 15 transitioning alone or without adults?
*******************************************************************************	

	// New paragraph
	putdocx paragraph	
	putdocx text ("Do we observe children < 15 transitioning alone or without adults? "), bold

	putdocx paragraph
	putdocx text ("By design, when children leave a sample household without an adult, ")
	putdocx text ("they are not followed. Assuming the household continues to be ") 
	putdocx text ("observed, these children will be coded as having a composition ")
	putdocx text ("change. In a population-representative sample, children ")
	putdocx text ("exiting without adults should be matched (and represented) by ")
	putdocx text ("children entering sample households unaccompanied by adults. These ")
	putdocx text ("children would also be coded as having a composition change. ")
	putdocx text ("Thus we double count these transitions and this might be a source ")
	putdocx text ("of over-estimation of children’s household instability. ")
	putdocx text ("So, our goal is to determine what proportion of comp_changes ")
	putdocx text ("involve children disappearing alone/with no adults. ")

********************************************************************	
* Create a file with an observation for ever person observed in the 
* data the next wave to be merged onto this wave.
********************************************************************
use "$tempdir/person_wide_adjusted_ages", clear

keep SSUID EPPPNUM SHHADID* ERRP* adj_age* shhadid_members*

reshape long SHHADID adj_age shhadid_members, i(SSUID EPPPNUM) j(SWAVE)

keep if !missing(SHHADID)

drop SHHADID

replace SWAVE=SWAVE-1

keep if SWAVE > 0

rename EPPPNUM relto
rename adj_age to_age

save "$tempdir/everyoneobservednextwave", $replace

********************************************************************
* Read in file with one observation for each person in ego's (relto) 
* household

* Add to_age to pairs data 
use "$tempdir/relationship_pairs_bywave", clear
rename relto EPPPNUM
merge m:1 SSUID EPPPNUM SWAVE using "$tempdir/demo_long_all", keepusing(adj_age)

keep if _merge==3

drop _merge

* renameing to "other_age" instead of "to_age" to avoid conflict with to_age (next wave)
rename adj_age other_age
rename EPPPNUM relto

gen other_oldenough=1 if other_age > 15

********************************************************************
* count number of household members in this wave 
egen hhmem=count(SHHADID), by(SSUID relfrom SWAVE)
egen oldhhmem=count(other_oldenough), by(SSUID relfrom SWAVE)

********************************************************************
*look for everyone in my household this wave in the next wave

merge m:1 SSUID relto SWAVE using "$tempdir/everyoneobservednextwave"

* drop observations that are just in next wave
drop if _merge==2

gen toinnext=1 if _merge==3

gen toinnext_oldenough=1 if _merge==3 & other_age > 15

********************************************************************
* Collapse to one record per person with indicators for number 

collapse (first) hhmem oldhhmem (count) hhmem_innext=toinnext num_old_innext=toinnext_oldenough, by(SSUID relfrom SWAVE)

gen all_other_observed=1 if hhmem_innext==hhmem

label variable all_other_observed "Every other person in ego's household is observed in next wave"

gen no_other_observed=1 if hhmem_innext==0

label variable no_other_observed "No other person in ego's household is observed in next wave"

gen all_other_old_observed=1 if oldhhmem==num_old_innext

label variable all_other_old_observed "Every other person age 15+ in ego's household is observed in next wave"

gen no_other_old_observed=1 if num_old_innext==0

label variable no_other_old_observed "No other person age 15+ in ego's household is observed in next wave"

rename relfrom EPPPNUM

********************************************************************
* Merge onto hh_change to see how often comp_change happens when all_other_observed=1 (disappear alone)

merge 1:1 SSUID EPPPNUM SWAVE using "$tempdir/hh_change.dta"

keep if _merge==3

gen gone_missing_alone=0 if !missing(comp_change)
replace gone_missing_alone=1 if innext==0 & all_other_observed==1

gen gone_missing_withoutadult=0 if !missing(comp_change)
replace gone_missing_withoutadult=1 if innext==0 & all_other_old_observed==1

save "$tempdir/nextwave.dta", $replace

tab comp_change gone_missing_alone, m

keep if adj_age < 15

tab comp_change gone_missing_alone, m

tab comp_change gone_missing_withoutadult, m

* ssc install putdocxcrosstab
putdocxcrosstab comp_change gone_missing_withoutadult

egen num_compchange=sum(comp_change)
local compchanges=num_compchange

egen num_gone_missing_withoutadult=sum(gone_missing_withoutadult)
local gonemissingbydesign=num_gone_missing_withoutadult
local percentbydesign=int(100*`gonemissingbydesign'/`compchanges')
local impact=`percentbydesign'/2 

	putdocx paragraph
	putdocx text ("Of the `compchanges' intervals where a person < 15 ")
	putdocx text ("is coded as having a composition change, only `gonemissingbydesign' ")
	putdocx text (" (`percentbydesign' percent) of the composition changes involve ")
	putdocx text ("a child leaving without an adult. ")	
	

* Calculate number and proportion of observations fully_observed or inferred
* We have more observations of comp_change than we have full intervals because
* we use information on other household members to code ego as experiencing
* a composition change even if ego is missing.

gen nmcomp= !missing(comp_change)   // not missing comp_change

sort original nmcomp 
by original nmcomp: gen norignmc=_n // original ==1 and nmcomp ==1 will be the largest group
egen numorignmc=max(norignmc)
local number_original_nmc = `=numorignmc'
local prop_nmc = int(100*`number_original_nmc'/`possible_original_obs')

	putdocx text ("The number of observed or inferred comp_change intervals for ")
	putdocx text ("original sample members is ")
	putdocx text ("`number_original_nmc' (`prop_nmc'%). So inferring composition change ")
local prop_diff = `prop_nmc' - `prop_fully_observed'
	putdocx text ("reduced missing data by `prop_diff' percentage points." )



