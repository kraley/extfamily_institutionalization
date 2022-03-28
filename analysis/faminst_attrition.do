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

use "${SIPP${panel}keep}/faminst_beforeattrition.dta", clear

	sort SSUID PNUM
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id

local panel  "${panel}"

display "`panel'"

svyset [pweight=WPFINWGT]

    egen allobs = nvals(idnum)
	sum allobs
	global allchildren`panel' = allobs
	di "${allchildren`panel'}"
	drop allobs
		
	global allchildyears`panel' = _N
	di "${allchildyears`panel'}"

keep if pimmigrant == 0

    egen allnatobs = nvals(idnum)
	global allnatchildren`panel' = allnatobs
	di "${allnatchildren`panel'}"
	drop allnatobs
	
save $tempdir/manyperhh.dta, replace
	
* Select only one child per household

	keep SSUID PNUM
	duplicates drop

	set seed 2222
	bys SSUID: sample 1, count 

merge 1:m SSUID PNUM using $tempdir/manyperhh.dta

keep if _merge==3
*drop _merge

gen haveid = !missing(idnum)

tab haveid _merge

    egen onenatobs = nvals(idnum)
	sum onenatobs, detail
	global onenatchildren`panel' = onenatobs
	di "${onenatchildren`panel'}"
	drop onenatobs

	
putdocx begin
	putdocx paragraph
	putdocx text ("Our analysis focuses on ")
	putdocx text ("${allchildren`panel'} children less than $top_age years old. ")
	putdocx text ("We restrict the sample to the ${allnatchildren`panel'} children ")
	putdocx text ("whose mothers who migrated to the United States as children or ")
	putdocx text ("were born in the United States. We then select one child per ")
	putdocx text ("household to reduce the clustering in our data and so that our ")
	putdocx text ("sample represents children's households, rather than children. ")
	putdocx text ("After selecting one child per household, our sample is  ")
	putdocx text ("${onenatchildren`panel'}. ")
	putdocx text ("The SIPP has some sample attrition and we lose ")
	
gen mccy=1 if missing(comp_changey)

preserve
	drop if mccy==1
	* to create sample macros

	drop if missing(hhinc)
	
    egen analysiskid = nvals(idnum)
	global analysiskid`panel' = analysiskid 

macro list
	
	di "${analysiskid`panel'}"
sum analysiskid 

	global attritedkid`panel' = ${onenatchildren`panel'} - ${analysiskid`panel'}

	drop analysiskid
	
	
	global analysischildyears`panel' = _N
	di "${analysischildyears`panel'}"
	
* end sample macros

save ${SIPP`panel'keep}/faminst_analysis.dta, replace

	putdocx text ("${attritedkid`panel'} children ")
    putdocx text ("who were not observed two consecutive years. In all, ")
	putdocx text ("our analyses derive from ${analysischildyears`panel'} ")
    putdocx text ("child years.")
	
	putdocx paragraph
	putdocx text ("To investigate how sample attrition biases our sample, we ")
	putdocx text ("compare the characteristics of our sample of child years before and after ")
	putdocx text ("restricting to cases observed in consecutive years. ")
	putdocx text ("This analysis can be found in InstitutionalizedExtensionAttritionAnalysis.xlsx. ")
	
	putdocx save "$results/attrition_report_`panel'.docx", replace

	
local subheadings "weighted_proportion N"

local hhtype "grandparent otherrel nonkin complex"
local reidummies "nhwhite black hispanic_nat hispanic_im asian_nat asian_im otherr"
local paredummies "plths phs pscol pcolg pedmiss" 
local parcomp "twobio singlebio stepparent noparent"
local hhchange "comp_changey hhsplity"


