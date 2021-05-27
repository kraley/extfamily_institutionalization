********************************************************************************
* Extended Family Institutionalization Project
*
* by Kelly Raley, Carolina Aragao, and Inbar Weiss
********************************************************************************
* 
* This file runs regression analyses and stores results in stata
*
* This version of the file requres stata 17
* If you don't have stata 17, use faminst_results_models.do instead

* This file is going to be executed three times, once each for the SIPP 08 and 14 panels and 
* then again for a data file that combines the two panels
 
use "${SIPP${panel}keep}/faminst_analysis.dta", clear

* $top_age is set in the setup file. This makes it easy for us to make changes
* to this sample restriction. For example, to limit to school-aged children 
* or whatever

keep if adj_age < $top_age

svyset [pweight=WPFINWGT]

drop if missing(comp_changey)

local redummies "nhwhite black hispanic asian otherr"
local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"
local bygroups "Total `reidummies'"
local subheadings "weighted_proportion N"

local hhtype "hhtype_1 hhtype_2 hhtype_3 hhtype_4"
local paredummies "plths phs pscol pcolg pedmiss" 
local parcomp "twobio singlebio stepparent noparent"
local hhchange "comp_changey hhsplity"

* Regression analysis

// setting up multi-variate models

gen adjage_sq = adj_age*adj_age

local baseline "i.year adj_age adjage_sq i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage log_hhinc" 
collect clear

collect style autolevels result _r_b _r_se _r_p // sets the levels of result that will be automatically included
*collect style showbase off // does not show row with baseline category for factor variable

collect: svy: logit hhsplity i.re `baseline' b0.hhtype

collect style cell result[_r_b _r_se _r_p], nformat(%3.2f)

forvalues r=1/5{
	local re : word `r' of `redummies'
	collect: svy, subpop(if re==`r'):logit hhsplity `baseline' b0.hhtype 
}

collect label levels cmdset 1 "Total" 2 "White" 3 "Black" 4 "Hispanic" 5 "Asian" 6 "Other"
log using "${sipp20${panel}_logs}/tests", text replace

collect style column, dups(center) // show repeating headers only once, center
collect layout (colname) (cmdset#result)

putexcel set "$results/InstExtReg${`panel'}", sheet(Models"$panel") replace
putexcel A1 = collect

forvalues r=1/5{
	local re : word `r' of `redummies'
	margins hhtype, subpop(if re==`r') saving(file`r', replace)
}

/*

// Tests - Models with interactions

local baseline "i.year adj_age i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage hhmaxage"
svy: logit hhsplity `baseline' b0.hhtype##re
outreg2 using "$results/Interaction${panel}.xls", append ctitle(Model with interactions)


* Test 1 
contrast hhtype##re, effects
/* Support that some extended ararngemenst are associated with less instability
for Black ans Hispanic hildren when compared o NH White. Asians are not different. 
*/

* Test 2: grandparent relationships are stronger than other relationships? 
contrast {hhtype 0 1 -1 0 0}, effects // gp vs other relatives, no non-relatives s
contrast {hhtype 0 1 0 -1 0}, effects // gp vs only non-relatives 
contrast {hhtype 0 1 0 0 -1}, effects // gp vs relative & non-relatives 
/* supports that gp relationships are stronger than other extented arrangements
*/

* Test 3: boundary between grandparents and non-kin is especially strong among Asian and Hispanic children's 
contrast {hhtype 0 1 -1 0 0}#g.re, effects
contrast {hhtype 0 1 0 -1 0}#g.re, effects
contrast {hhtype 0 1 0 0 -1}#g.re, effects
/* overall does not provide support that gp arrangenets vs other types ard particularly different
among Hispanic and Asians - yet some support that gp vs complex is different than means for Hispanics
Asians and also Black children
*/

* Test 4: any extension less associated with instability for Black children than for White children, particularly other kin
contrast {re 1 -1 -0 0 0}@i1.hhtype, effects
contrast {re 1 -1 -0 0 0}@i2.hhtype, effects
contrast {re 1 -1 -0 0 0}@i3.hhtype, effects
contrast {re 1 -1 -0 0 0}@i4.hhtype, effects
/* partial support, differences not significant for gp arrangements  
*/


* Graph
margins hhtype##re 
marginsplot, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5)

log close
