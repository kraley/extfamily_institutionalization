***
*
* Performs data analysis for family institutionalization project

* currently conducting separate analyses for each panel

* Must run setup_project prior to conducting analysis.

cd "${base_code}/analysis"

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
	do faminst_results_describe.do

	* create table of model results
	do faminst_results_models.do
}
