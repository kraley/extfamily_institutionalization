
local panel "08"

use "${SIPP`panel'keep}/faminst_analysis.dta", clear

keep if adj_age < 15

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

********************************************************************************
* TABLE SHELL
********************************************************************************
local filename "InstitutionalizedExtension"
local sheetname "descriptives`panel'"
local tabletitle "Descriptive Statistics for analytical sample"

local gap = 1 // if you want a column separating groups, set to 1. If not, set to 0.

local groups = 8
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
putexcel A5=" only grandparent"
putexcel A6=" any other relative, no nonrel"
putexcel A7=" only non-relative"
putexcel A8=" relatives and non-relatives"
putexcel A9="Race/Ethnicity"
putexcel A10=" Non-Hispanice White"
putexcel A11=" Black"
putexcel A12=" Non-Black Hispanic US-Born"
putexcel A13 = " Non--Black Hispanic Immigrant"
putexcel A14=" Asian, US Born"
putexcel A15=" Asian, Immigrant"
putexcel A16=" Other, including multi-racial"
putexcel A17="Parent Immigrant"
putexcel A18=" Yes"
putexcel A19="Parental Education"
putexcel A20=" less than High School"
putexcel A21=" diploma or GED"
putexcel A22=" some college"
putexcel A23=" College Grad"
putexcel A24=" unknown"
putexcel A25="Parent"
putexcel A26=" 2 bio"
putexcel A27=" 1 bio, nostep"
putexcel A28=" stepparent"
putexcel A29=" no parent"
putexcel A30="Household Change"
putexcel A31="Household Split"

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
	local row=`d'+4
	svy: mean hhtype_`d' 
	matrix mr`d' = e(b)
	putexcel `prop_col'`row' = matrix(mr`d'), nformat(#.##)
	count if hhtype_`d'==1
	putexcel `samp_col'`row' = `r(N)'
}

* race-ethnicity
forvalues r=1/7{
	local row=`r'+9
	local var : word `r' of `reidummies'
	svy: mean `var' 
	matrix mre`r' = e(b)
	putexcel `prop_col'`row' = matrix(mre`r'), nformat(#.##)
	count if `var' == 1
	putexcel `samp_col'`row' = `r(N)'
}

* parent immigrant

local row = `row'+1
svy: mean pimmigrant
*matrix mpi=e(b)
*putexcel `prop_col'`row' = matrix(mpi), nformat(#.##)
*count if pimmigrant == 1
*putexcel `samp_col'`row' = `r(N)'

* parent education
forvalues pe=1/5{
	local row=`pe'+19
	local var:word `pe' of `paredummies'
	svy: mean `var' 
	matrix mpe`pe' = e(b)
	putexcel `prop_col'`row' = matrix(mpe`pe'), nformat(#.##)
	count if `var'==1
    putexcel `samp_col'`row' = `r(N)'
}

*parent composition	
forvalues p=1/4{
	local row=`p'+25
	local var:word `p' of `parcomp'
	svy: mean `var' 
	matrix mp`p' = e(b)
	putexcel `prop_col'`row' = matrix(mp`p'), nformat(#.##)
	count if `var'==1
    putexcel `samp_col'`row' = `r(N)'
}

*comp change
forvalues h=1/2{
	local row=`h'+29
	local var:word `h' of `hhchange'
	svy: mean `var' 
	matrix mh`h' = e(b)
	putexcel `prop_col'`row' = matrix(mh`h'), nformat(#.##)
	count if `var'==1
    putexcel `samp_col'`row' = `r(N)'
}

* By Race/Ethnicity

forvalues re=1/7{
	local pcol=(`re')*3+2   
	local propcol: word `pcol' of `c(ALPHA)'
	local addone = `pcol'+1
	local ncol: word `addone' of `c(ALPHA)'
    display "relatives"
	* relatives
	forvalues ht=1/4{
		local row=`ht'+4
		local var : word `ht' of `hhtype'
		svy, subpop(if rei==`re'): mean `var' 
		matrix mr`ht'`re' = e(b)
		putexcel `propcol'`row' = matrix(mr`ht'`re'), nformat(#.##)
		count if hhtype_`ht'==1 & rei==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	
	svy, subpop(if rei==`re'): mean pimmigrant
	matrix mpi`re'=e(b)
	putexcel `propcol'18 = matrix(mpi`re'), nformat(#.##)
	count if pimmigrant == 1 & rei==`re'
	putexcel `ncol'18 = `r(N)'
	display "parent education"
	* parent education
	forvalues pe=1/5{
		local row=`pe'+19
		local var:word `pe' of `paredummies'
		svy, subpop(if rei==`re'): mean `var' 
		matrix mpe`pe'`re' = e(b)
		putexcel `propcol'`row' = matrix(mpe`pe'`re'), nformat(#.##)
		count if `var'==1 & rei==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	display "parent composition"
	*parent composition	
	forvalues p=1/4{
		local row=`p'+25
		local var:word `p' of `parcomp'
		svy, subpop(if rei==`re'): mean `var' 
		matrix mp`p'`re' = e(b)
		putexcel `propcol'`row' = matrix(mp`p'`re'), nformat(#.##)
		count if `var'==1 & rei==`re'
		putexcel `ncol'`row' = `r(N)'
	}
	*household change
	forvalues h=1/2{
		local row=`h'+29
		local var:word `h' of `hhchange'
		svy, subpop(if rei==`re'): mean `var'  
		matrix mh`h'`re' = e(b)
		putexcel `propcol'`row' = matrix(mh`h'`re'), nformat(#.##)
		count if `var'==1 & rei==`re'
		putexcel `ncol'`row' = `r(N)'
	}
}

