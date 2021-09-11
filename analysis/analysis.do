***
*
* Performs data analysis for family institutionalization project

* currently conducting separate analyses for each panel

* Must run setup_project prior to conducting analysis.

cd "${base_code}/analysis"

* This section is going to prepare the files and analyze the data for each 
* panel separately

local panels "08 14"

local loops "5 4"

forvalues p=1/2 {
	global panel: word `p' of `panels'
	global nloops: word `p' of `loops'
	
	macro list

	display "starting with the `panel' panel"

	* Prepare other variables for analysis
	do faminst_prepdata.do
	* create table of descriptive results
*	do faminst_results_describe.do

	* create table of model results
*	do faminst_results_models.do
}

* This section pools the data files for the two panels and analyzes them together

use "$SIPP08keep/faminst_analysis.dta", clear

gen panel=1

append using "$SIPP14keep/faminst_analysis.dta"

replace panel=2 if missing(panel)

replace year=year+4 if panel==2

save "$SIPPpoolkeep/faminst_analysis.dta", replace

global panel "pool"

do faminst_attrition.do
do faminst_results_describe.do
do faminst_describe_detailed.do
do faminst_results_models.do
do faminst_models_dhhtype.do
