* famiinst_results_describe.do
*
* Produces Table 1, a description of race-ethnic-immigration variation in household composition

capture log close

log using "$sipp20pool_logs/faminst_results_describe{panel}.txt", replace

use "${SIPP${panel}keep}/faminst_analysis.dta", clear

* Note that top_age is set in project macros. If you want to change
* the age range, change it there, rather than here. Otherwise 
* the parts of the code designed to describe sample selection
* won't work properly

keep if adj_age < $top_age

keep if pimmigrant == 0

svyset [pweight=WPFINWGT]

drop if missing(comp_changey)

local redummies "nhwhite black hispanic asian otherr"
local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"
local bygroups "Total `redummies'"
local subheadings "weighted_proportion N"

local hhtype "hhtype_1 hhtype_2 hhtype_3 hhtype_4"
local paredummies "plths phs pscol pcolg pedmiss" 
local parcomp "twobio singlebio stepparent noparent"
local incomeassets "hhinc THNETWORTH"
local hhchange "comp_changey hhsplity"

replace THNETWORTH=0 if missing(THNETWORTH)

********************************************************************************
* TABLE SHELL
********************************************************************************
local filename "InstitutionalizedExtension${panel}"
local sheetname "descriptives${panel}"
local tabletitle "Descriptive Statistics for analytical sample"

local gap = 1 // if you want a column separating groups, set to 1. If not, set to 0.

local groups = 6
local subheads = 2 // proportion N
local total_cols = `groups' * (`subheads'+`gap') 
local lastcol : word `total_cols' of `c(ALPHA)'

local first_data_col = 2 // column A is for the row headings. Start column headings with B.

putexcel set "$results/`filename'", sheet(`sheetname') replace

putexcel A1:`lastcol'1 = "`tabletitle'", merge border(bottom)

* Column headings

local ncolstart =  `first_data_col'

/* This part is written to be able to handle any table with major heading and subheading */
forvalues group=1/`groups' {
	local major_heading : word `group' of `bygroups'
	
	display "creating headings for `major_heading'"
	
	local colstart      : word `ncolstart' of `c(ALPHA)'
	local ncolend = `ncolstart' + `subheads'-1
	local colend        : word `ncolend' of `c(ALPHA)'
	putexcel `colstart'2:`colend'2 = ("`major_heading'"), merge border(bottom) 
        *subheadings
	forvalues subhead=1/`subheads'{
		local subheading : word `subhead' of `subheadings'
		local ncolstart = `ncolstart' + (`subhead' - 1) // first subheading goes into the same column as start of majoir heading, next goes one to right. 
		local subcol : word `ncolstart' of `c(ALPHA)'
		putexcel `subcol'3 = "`subheading'"
		
		display "number of column start is `ncolstart'"
	}	
	
	display "number of column start is `ncolstart' and of gap is `gap'"
	
	local ncolstart = `ncolstart' + `gap' +1 // shift to the right the size of the gap and start the next group in the next column to the right	
}
 

* row headings
putexcel A4="Household Extension"
putexcel A5="none (nuclear)"
putexcel A6=" only grandparent"
putexcel A7=" any other relative, no nonrel"
putexcel A8=" only non-relative"
putexcel A9=" relatives and non-relatives"
putexcel A10="Race/Ethnicity"
putexcel A11=" Non-Hispanice White"
putexcel A12=" Black"
putexcel A13=" Non-Black Hispanic US-Born"
*putexcel A14 = " Non--Black Hispanic Immigrant"
putexcel A15=" Asian, US Born"
*putexcel A16=" Asian, Immigrant"
putexcel A17=" Other, including multi-racial"
*putexcel A18="Parent Immigrant"
putexcel A19=" Yes"
putexcel A20="Parental Education"
putexcel A21=" less than High School"
putexcel A22=" diploma or GED"
putexcel A23=" some college"
putexcel A24=" College Grad"
putexcel A25=" unknown"
putexcel A26="Parent"
putexcel A27=" 2 bio"
putexcel A28=" 1 bio, nostep"
putexcel A29=" stepparent"
putexcel A30=" no parent"
putexcel A31 = "mean income (1,000s)"
putexcel A32 = "mean wealth (1,000s)"
putexcel A33="Household Change"
putexcel A34="Household Split"
putexcel A36 = "Total"

********************************************************************************
* TABLE Filling
********************************************************************************

* setting up to abstract, but not close to complete
local nprop_col =  `first_data_col'
local prop_col : word `nprop_col' of `c(ALPHA)'
local nsamp_col = `first_data_col'+1
local samp_col : word `nsamp_col' of `c(ALPHA)'

* relatives
forvalues d=1/4{
	local row=`d'+5
	svy: mean hhtype_`d' 
	matrix mr`d' = e(b)
	putexcel `prop_col'`row' = matrix(mr`d'), nformat(#.##)
	count if hhtype_`d'==1
	putexcel `samp_col'`row' = `r(N)'
}

* race-ethnicity
forvalues r=1/5{
	local row=`r'+10
	local var : word `r' of `redummies'
	svy: mean `var' 
	matrix mre`r' = e(b)
	putexcel `prop_col'`row' = matrix(mre`r'), nformat(#.##)
	count if `var' == 1
	putexcel `samp_col'`row' = `r(N)'
}

/* parent immigrant

local row = `row'+2
svy: mean pimmigrant
matrix mpi=e(b)
putexcel `prop_col'`row' = matrix(mpi), nformat(#.##)
count if pimmigrant == 1
putexcel `samp_col'`row' = `r(N)'
*/

* parent education
forvalues pe=1/5{
	local row=`pe'+20
	local var:word `pe' of `paredummies'
	svy: mean `var' 
	matrix mpe`pe' = e(b)
	putexcel `prop_col'`row' = matrix(mpe`pe'), nformat(#.##)
	count if `var'==1
    putexcel `samp_col'`row' = `r(N)'
}

*parent composition	
forvalues p=1/4{
	local row=`p'+26
	local var:word `p' of `parcomp'
	svy: mean `var' 
	matrix mp`p' = e(b)
	putexcel `prop_col'`row' = matrix(mp`p'), nformat(#.##)
	count if `var'==1
        putexcel `samp_col'`row' = `r(N)'
}

*HOUSEHOLD INCOME and Assets (means)
forvalues ia=1/2{
	local row=`ia'+30
	local var:word `ia' of `incomeassets'
	svy: mean `var' 
	matrix mh`ia' = e(b)/1000
	putexcel `prop_col'`row' = matrix(mh`ia'), nformat(#)
	count if !missing(`var')
	putexcel `samp_col'`row' = `r(N)'
}

*comp change
forvalues h=1/2{
	local row=`h'+32
	local var:word `h' of `hhchange'
	svy: mean `var' 
	matrix mh`h' = e(b)
	putexcel `prop_col'`row' = matrix(mh`h'), nformat(#.##)
	count if `var'==1
	putexcel `samp_col'`row' = `r(N)'
}

* total sample size
local row = 36
count if  !missing(comp_changey)
putexcel `samp_col'`row' = `r(N)'

* By Race/Ethnicity

forvalues re=1/5{
	local pcol=(`re')*3+2   
	local propcol: word `pcol' of `c(ALPHA)'
	local addone = `pcol'+1
	local ncol: word `addone' of `c(ALPHA)'
    display "relatives"
	* relatives
	forvalues ht=1/4{
		local row=`ht'+5
		local var : word `ht' of `hhtype'
		svy, subpop(if re==`re'): mean `var' 
		matrix mr`ht'`re' = e(b)
		putexcel `propcol'`row' = matrix(mr`ht'`re'), nformat(#.##)
		count if hhtype_`ht'==1 & re==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	
	svy, subpop(if re==`re'): mean pimmigrant
	matrix mpi`re'=e(b)
	putexcel `propcol'19 = matrix(mpi`re'), nformat(#.##)
	count if pimmigrant == 1 & re==`re'
	putexcel `ncol'19 = `r(N)'
	display "parent education"
	* parent education
	forvalues pe=1/5{
		local row=`pe'+20
		local var:word `pe' of `paredummies'
		svy, subpop(if re==`re'): mean `var' 
		matrix mpe`pe'`re' = e(b)
		putexcel `propcol'`row' = matrix(mpe`pe'`re'), nformat(#.##)
		count if `var'==1 & re==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	display "parent composition"
	*parent composition	
	forvalues p=1/4{
		local row=`p'+26
		local var:word `p' of `parcomp'
		svy, subpop(if re==`re'): mean `var' 
		matrix mp`p'`re' = e(b)
		putexcel `propcol'`row' = matrix(mp`p'`re'), nformat(#.##)
		count if `var'==1 & re==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	*HOUSEHOLD INCOME and Assets (means)
	forvalues ia=1/2{
		local row=`ia'+30
		local var:word `ia' of `incomeassets'
		svy, subpop(if re==`re'): mean `var'
		matrix mh`ia'`re' = e(b)/1000
		display "the mean `var' is `e(b)'"
		putexcel `propcol'`row' = matrix(mh`ia'`re'), nformat(#)
		count if  rei == `re'
		putexcel `ncol'`row' = `r(N)'
	}
	*household change
	forvalues h=1/2{
		local row=`h'+32
		local var:word `h' of `hhchange'
		svy, subpop(if re==`re'): mean `var'  
		matrix mh`h'`re' = e(b)
		putexcel `propcol'`row' = matrix(mh`h'`re'), nformat(#.##)
		count if `var'==1 & re==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	* total sample size
	local row = 36
	count if  rei == `re'
	putexcel `ncol'`row' = `r(N)'
}

/*
// Graphs
combomarginsplot file1 file2 file3 file4 file5, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5) ///
labels(White Black Hispanic Asian Other) xscale(r(0 1)) xtitle(“Race”)
combomarginsplot file1 file2, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5) ///
labels(White Black) xscale(r(0 1)) xtitle(“Race”)
combomarginsplot file1 file3, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5) ///
labels(White Hispanic) xscale(r(0 1)) xtitle(“Race”)
combomarginsplot file1 file4, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5) ///
labels(White Asian) xscale(r(0 1)) xtitle(“Race”)
combomarginsplot file1 file5, ylabel(0(.1).8) ysc(r(0 .8)) scheme(s1color) aspectratio(.5) ///
labels(White Other) xscale(r(0 1)) xtitle(“Race”)

*/

local baseline "i.year adj_age i.par_ed_first i.parentcomp mom_age mom_age2 hhsize b2.chhmaxage hhmaxage"

mlogit hhtype i.re

mlogit hhtype i.re `baseline' 


log close
