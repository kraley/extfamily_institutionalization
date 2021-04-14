* famiinst_prepdata.do
*
*  Merge together files desccribing household composition in December of each year
*  to predict a composition change over the subsequent year.

*******************************************************
* bring in comp_change and create annual measure of composition change
********************************************************
*

local panel "14"

// a wide file
use "${SIPP`panel'keep}/comp_change_am.dta", clear

gen comp_change0=.
gen leavers0=" "

forvalues y=1/4 {
	gen obsyear`y'=0 // dummy indicator for whether there were  observations in this year
	forvalues m=0/11 {
		local pm=((`y'-1)*12)+`m'
		replace obsyear`y'=obsyear`y'+1 if !missing(comp_change`pm')
	}
}

forvalues y=1/4 {
	gen comp_changey`y'= 0 if obsyear`y' > 0
	gen hhsplity`y'=0 if obsyear`y' > 0
	forvalues m=0/11 {
		local pm=((`y'-1)*12)+`m'
		replace comp_changey`y'=1 if comp_change`pm'==1
		replace hhsplity`y'=1 if leavers`pm' != " " & !missing(leavers`pm')
	}
	tab comp_changey`y' hhsplity`y', m
}

keep SSUID PNUM comp_changey? hhsplity? obsyear?

reshape long comp_changey hhsplity obsyear, i(SSUID PNUM) j(year)

tab comp_changey hhsplity, m

replace year=year-1 // lag the dv

save "$tempdir/compchangey`panel'", replace

*******************************************************
* bring in comp_change and create annual measure of household income
********************************************************

use "${SIPP`panel'keep}/demo_wide_am.dta"

forvalues y=1/4 {
	gen obsyear`y'=0 // dummy indicator for whether there were  observations in this year
	forvalues m=1/12 {
		local pm=((`y'-1)*12)+`m'
		replace obsyear`y'=obsyear`y'+1 if !missing(THTOTINC`pm')
	}
}

forvalues y=1/4 {
	gen hhinc`y'= 0 if obsyear`y' > 0
	forvalues m=1/12 {
		local pm=((`y'-1)*12)+`m'
		replace hhinc`y'=hhinc`y'+THTOTINC`pm' if !missing(THTOTINC`pm')
	}
}

keep SSUID PNUM hhinc? obsyear?

reshape long hhinc obsyear, i(SSUID PNUM) j(year)

sum hhinc

save "$tempdir/hhinc`panel'", replace

**********************************************************
* Read in main data
**********************************************************

use  "${SIPP`panel'keep}/relationships.dta", replace

keep if inlist(panelmonth, 12, 24, 36, 48)

gen year=1 if panelmonth==12
replace year=2 if panelmonth==24
replace year=3 if panelmonth==36
replace year=4 if panelmonth==48 

merge 1:1 SSUID PNUM year using "$tempdir/compchangey`panel'"

keep if _merge == 3

drop _merge

merge 1:1 SSUID PNUM year using "$tempdir/hhinc`panel'"

keep if _merge == 3

drop _merge

gen hhinc_sq = hhinc*hhinc
gen log_hhinc = ln(hhinc) if hhinc > 0
replace log_hhinc=0 if hhinc <=0

gen log_wealth = ln(THNETWORTH) if THNETWORTH > 0
replace log_wealth = 0 if THNETWORTH <=0

keep if adj_age < $top_age

gen parentcomp=1 if bioparent==2
replace parentcomp=2 if bioparent==1 & parent==1
replace parentcomp=3 if parent > bioparent
replace parentcomp=4 if parent==0

label define parentcomp 1 "two bio parent" 2 "single bioparent" 3 "stepparent" 4 "noparent"

* mean-center mom_age
mean mom_age
replace mom_age=mom_age-37 
replace mom_age=0 if missing(mom_age)

gen mom_age2=mom_age*mom_age

* dummy indicators for demographics
gen black= my_racealt==2
gen nhwhite= my_racealt==1
gen hispanic= my_racealt==3
gen asian= my_racealt==4
gen otherr=my_racealt==5

gen plths=par_ed_first==1
gen phs=par_ed_first==2
gen pscol=par_ed_first==3
gen pcolg=par_ed_first==4
gen pedmiss= missing(par_ed_first)

gen twobio=parentcomp==1
gen singlebio=parentcomp==2
gen stepparent=parentcomp==3
gen noparent=parentcomp==4

gen asian_nat=1 if asian==1 & pimmigrant==0 
replace asian_nat=0 if missing(asian_nat)

gen asian_im=1 if asian==1 & pimmigrant==1
replace asian_im=0 if missing(asian_im)

gen hispanic_nat=1 if hispanic==1 & pimmigrant==0
replace hispanic_nat=0 if missing(hispanic_nat)

gen hispanic_im=1 if hispanic==1 & pimmigrant==1
replace hispanic_im=0 if missing(hispanic_im)

local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"

gen rei=.

forvalues rei=1/7{
	local rei_name : word `rei' of `reidummies'
	replace rei=`rei' if `rei_name'==1
}

gen nongprel= (anyauntuncle==1 | anyother==1)

gen hhexttype=0 if anygp==0 & nongprel==0 & anynonrel==0
replace hhexttype=1 if anygp==1 & nongprel==0 & anynonrel==0
replace hhexttype=2 if anygp==0 & nongprel==1 & anynonrel==0
replace hhexttype=3 if anygp==1 & nongprel==1 & anynonrel==0
replace hhexttype=4 if anygp==0 & nongprel==0 & anynonrel==1
replace hhexttype=5 if anygp==1 & nongprel==0 & anynonrel==1
replace hhexttype=6 if anygp==0 & nongprel==1 & anynonrel==1
replace hhexttype=7 if anygp==1 & nongprel==1 & anynonrel==1

gen nuclear= (hhexttype==0)
gen anyext= (anygp+anyauntuncle+anyother+anynonrel > 0)

* a condensed version of the household type variable to enable evaluation
* of hypothesized contrasts

recode hhexttype (0=0)(1=1)(2/3=2)(4=3)(5/7=4), gen(hhtype)

label define hhtype 0 "nuclear" 1 "only grandparent" 2 "other relatives, no non-relatives" 3 "only nonrelatives" 4 "relative and non-relatives"
label var hhtype hhtype
label val hhtype hhtype

forvalues t=1/4{
	gen hhtype_`t' = (hhtype==`t')
}


save "${SIPP`panel'keep}/faminst_analysis.dta", replace


 
