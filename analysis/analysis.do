***
*
* Performs data analysis for family institutionalization project

* currently conducting separate analyses for each panel

* Must run setup_project prior to conducting analysis.

local panels "08 14"

forvalues p=1/2 {
	local panel: word `p' of `panels'

	* Create measures of children's Household Type
	do ChildrensHHType.do

	* Prepare other variables for analysis
	do faminst_prepdata.do

	* create table of descriptive results
	do faminst_results_describe.do

	* create table of model results
	do faminst_results_models.do
}
