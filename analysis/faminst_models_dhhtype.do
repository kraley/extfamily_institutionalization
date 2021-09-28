
use "${SIPP${panel}keep}/faminst_analysis.dta", clear

keep if adj_age < $top_age

* Select only one child per household
tempfile holding
save `holding'

keep SSUID PNUM
duplicates drop

set seed 2222
bys SSUID: sample 1, count 

merge 1:m SSUID PNUM using `holding', assert(match using) keep(match) nogenerate 

svyset [pweight=WPFINWGT]

drop if missing(comp_changey)

local redummies "nhwhite black hispanic asian otherr"
*local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"
local bygroups "Total `redummies'"
local subheadings "weighted_proportion N"

local hhtype "hhtype_1 hhtype_2 hhtype_3 hhtype_4"
local dhhtype "dhhtype_1 dhhtype_2 dhhtype_3 dhhtype_4 dhhtype_5"
local paredummies "plths phs pscol pcolg pedmiss" 
local parcomp "twobio singlebio stepparent noparent"
local hhchange "comp_changey hhsplity"

* Regression analysis

// setting up multi-variate models

gen adjage_sq = adj_age*adj_age

local baseline "i.year adj_age adjage_sq i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage log_hhinc" 

svy: logit hhsplity i.re `baseline' 
outreg2 using "$results/InstExtReg${panel}_dhhtype.xlsx", append ctitle(Model 2) 

// in contrast to the descriptive bivariate analysis above, these models 
*  have mutually-exclusive household type cateogires

svy: logit hhsplity i.re `baseline' b0.dhhtype
outreg2 using "$results/InstExtReg${panel}_dhhtype.xlsx", append ctitle(Model 3)

forvalues r=1/5{
	local re : word `r' of `redummies'
	svy, subpop(if re==`r'):logit hhsplity `baseline' b0.dhhtype 
	outreg2 using "$results/InstExtReg${panel}_dhhtype.xlsx", append ctitle(re=`re')
	margins dhhtype, subpop(if re==`r') saving(file`r', replace)
	marginsplot, recast(bar) plotopts(barw(.8)) xtitle(HH Type - `r') legend( order(0 "Nuclear" 1 "Granparents" 2 "Aunt/Uncle" 3 "OtherRelatives" 4 "Non-relatives" 5 "Relatives & non-Relatives"))
}

/*
* Models controling for wealth 

local baselineII "i.year adj_age adjage_sq i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage log_hhinc log_wealth"
forvalues r=1/5{
	local re : word `r' of `redummies'
	svy, subpop(if re==`r'):logit hhsplity `baselineII' b0.hhtype 
	outreg2 using "$results/InstExtReg${panel}.xlsx", append ctitle(re=`re')
	margins hhtype, subpop(if re==`r') saving(file`r', replace)
	marginsplot, recast(bar) plotopts(barw(.8)) xtitle(HH Typ - `r') legend( order(0 "Nuclear" 1 "Granparents" 2 "Relatives" 3 "Non-relatives" 4 "Relatives & non-Relatives"))
}
*/							

log using "${sipp20${panel}_logs}/tests_detailed", text replace

// Tests - Models with interactions

local baseline "i.year adj_age i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage hhmaxage"
svy: logit hhsplity `baseline' b0.dhhtype##re
outreg2 using "$results/Interaction${panel}.xlsx", append ctitle(Model with interactions)


* Test 1 
// https://stats.idre.ucla.edu/stata/faq/everything-you-always-wanted-to-know-about-contrasts-but-were-afraid-to-ask/
contrast dhhtype##re, effects
/* Support that some extended arrangemenst (grandparents, aunt/uncle, other relative, non-relative
are associated with less instability for Black ans Hispanic hildren when compared o NH White. Asians are not different.
*/

* Test 2: grandparent relationships are stronger than other relationships? 
contrast {dhhtype 0 1 -1 0 0 0}, effects // gp vs aunt/uncle, 
contrast {dhhtype 0 1 0 -1 0 0}, effects // gp vs other relatives, no non-relatives s
contrast {dhhtype 0 1 0 0 -1 0}, effects // gp vs only non-relatives 
contrast {dhhtype 0 1 0 0 0 -1}, effects // gp vs relative & non-relatives 
/* supports that GP relationships are STRONGER than other extented arrangements including AUNT/UNCLE
*/

* Test 3: boundary between grandparents and other kin is especially strong among Asian and Hispanic children’s 
*1) Testing White children vs Hispanic Children
contrast {dhhtype 0 1 -1 0 0 0}#{re 1 0 -1 0 0}, effects 
contrast {dhhtype 0 1 0 -1 0 0}#{re 1 0 -1 0 0}, effects 
contrast {dhhtype 0 1 0 0 -1 0}#{re 1 0 -1 0 0}, effects 
contrast {dhhtype 0 1 0 0 0 -1}#{re 1 0 -1 0 0}, effects 

*2) Testing White children vs Asian Children
contrast {dhhtype 0 1 -1 0 0 0}#{re 1 0 0 -1 0}, effects 
contrast {dhhtype 0 1 0 -1 0 0}#{re 1 0 0 -1 0}, effects 
contrast {dhhtype 0 1 0 0 -1 0}#{re 1 0 0 -1 0}, effects 
contrast {dhhtype 0 1 0 0 0 -1}#{re 1 0 0 -1 0}, effects 


/* overall does not provide support that gp arrangenets vs other types ard particularly different
for Hispanic and Asians when constrasting agaist White children
*/

* Test 4: any extension less associated with instability for Black children than for White children, particularly other kin
contrast {re 1 -1 0 0 0}@i1.dhhtype, effects
contrast {re 1 -1 0 0 0}@i2.dhhtype, effects
contrast {re 1 -1 0 0 0}@i3.dhhtype, effects
contrast {re 1 -1 0 0 0}@i4.dhhtype, effects
contrast {re 1 -1 0 0 0}@i5.dhhtype, effects
/* partial support, differences not significant for gp arrangements  
*/


* Graph
margins dhhtype##re 
marginsplot, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5)

log close
