//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP
//===== Purpose: describe sample attrition 
//===== creates an excel spreadsheet in results folder called
*       "InstitutionalizedExtensionAttritionAnalysis.xlsx"
*       that has sample characterstics before and after selection
*       on attrition. 

*       Also creates a word document describing sample before and after
*       attrition for, if you like, insertion into paper. 

putdocx begin
	putdocx paragraph
	putdocx text ("The 20`panel' of the SIPP includes ${allindividuals`panel'} ")
	putdocx text ("individuals of all ages. Our analysis focuses on the ")
	putdocx text ("${allchildren`panel'} children less than $top_age years old. ")
	putdocx text ("The SIPP has some sample attrition and we lose ")
	
use "${SIPP`panel'keep}/faminst_analysis.dta", clear
svyset [pweight=WPFINWGT]
keep if adj_age < $top_age

gen mccy=1 if missing(comp_changey)

preserve
	drop if mccy==1
	* sample macros

    egen analysiskid = nvals(idnum)
	global analysiskid`panel' = analysiskid 
	global attritedkid`panel' = ${decemberkid`panel'} - ${analysiskid`panel'}
	di "${analysiskid`panel'}"
	drop analysiskid
		
	global analysischildyears`panel' = _N
	di "${analysischildyears`panel'}"

* end sample macros
restore

	putdocx text ("${attritedkid`panel'} children ")
    putdocx text ("who were not observed two consecutive years. In all, ")
	putdocx text ("our analyses derive from ${analysischildyears`panel'} ")
    putdocx text ("child years.")
	
	putdocx paragraph
	putdocx text ("To investigate how sample attrition biases our sample, we ")
	putdocx text ("compare the characteristics of our sample of child years before and after ")
	putdocx text ("restricting to cases observed in consecutive years. ")
	putdocx text ("This analysis can be found in InstitutionalizedExtensionAttritionAnalysis.xlsx. ")
	
	putdocx save "$results/attritionreport.docx", $replace
	
local subheadings "weighted_proportion N"

local hhtype "grandparent otherrel nonkin complex"
local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"
local paredummies "plths phs pscol pcolg pedmiss" 
local parcomp "twobio singlebio stepparent noparent"
local hhchange "comp_changey hhsplity"

********************************************************************************
* TABLE SHELL
********************************************************************************
local filename "InstitutionalizedExtensionAttritionAnalysis"
local sheetname "descriptives`panel'"
local tabletitle "Descriptive Statistics for analytical sample"

local gap = 1 // if you want a column separating groups, set to 1. If not, set to 0.

local bygroups "Total_sample Analysis_sample"
local subheadings "weighted_proportion N"

local groups = 2
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

* first loop for total sample, second for analytical sample
forvalues g=1/`groups'{
	local pcol=(`g'-1)*(`subheads'+ `gap')+`first_data_col'
	local prop_col: word `pcol' of `c(ALPHA)'
	local addone = `pcol'+1
	local samp_col: word `addone' of `c(ALPHA)'
	* relatives
	forvalues d=1/4{
		local row=`d'+4
		svy: mean hhtype_`d' 
		matrix mr`d'`g' = e(b)
		putexcel `prop_col'`row' = matrix(mr`d'`g'), nformat(#.##)
		count if hhtype_`d'==1
		putexcel `samp_col'`row' = `r(N)'
	}

	* race-ethnicity
	forvalues r=1/7{
		local row=`r'+9
		local var : word `r' of `reidummies'
		svy: mean `var' 
		matrix mre`r'`g' = e(b)
		putexcel `prop_col'`row' = matrix(mre`r'`g'), nformat(#.##)
		count if `var' == 1
		putexcel `samp_col'`row' = `r(N)'
	}
	
	* parent immigrant
		
	local row = `row'+2
	svy: mean pimmigrant
	matrix mpi`g'=e(b)
	putexcel `prop_col'`row' = matrix(mpi`g'), nformat(#.##)
	count if pimmigrant == 1
	putexcel `samp_col'`row' = `r(N)'
	
	* parent education
	forvalues pe=1/5{
		local row=`pe'+19
		local var:word `pe' of `paredummies'
		svy: mean `var' 
		matrix mpe`pe'`g' = e(b)
		putexcel `prop_col'`row' = matrix(mpe`pe'`g'), nformat(#.##)
		count if `var'==1
		putexcel `samp_col'`row' = `r(N)'
	}
	
	*parent composition	
	forvalues p=1/4{
		local row=`p'+25
		local var:word `p' of `parcomp'
		svy: mean `var' 
		matrix mp`p'`g' = e(b)
		putexcel `prop_col'`row' = matrix(mp`p'`g'), nformat(#.##)
		count if `var'==1
		putexcel `samp_col'`row' = `r(N)'
	}
	
	*comp change
	forvalues h=1/2{
		local row=`h'+29
		local var:word `h' of `hhchange'
		svy: mean `var' 
		matrix mh`h'`g' = e(b)
		putexcel `prop_col'`row' = matrix(mh`h'`g'), nformat(#.##)
		count if `var'==1
		putexcel `samp_col'`row' = `r(N)'
	}
	drop if missing(comp_changey)
}

