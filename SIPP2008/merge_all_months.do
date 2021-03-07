//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP 
//===== Purpose: Merges all extracts together into one file
//===== 

local panel "08"

** Import first wave. 
use "${SIPP`panel'keep}/wave${first_wave}_extract", clear 

** Append the first wave with waves from the second to last, also keep only observations from the reference month. 
forvalues wave = $second_wave/$final_wave {
    append using "${SIPP`panel'keep}/wave`wave'_extract"
}

gen panelmonth=(SWAVE-1)*4+SREFMON

* First, create an id variable per person
	sort SSUID EPPPNUM SREFMON
	egen id = concat (SSUID EPPPNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id

// Create a macro with the total number of respondents in the dataset.
	egen all = nvals(idnum)
	global allindividuals`panel' = all
	di "${allindividuals`panel'}"
	
	global allmonths`panel' = _N
	di "${allmonths`panel'}"

** allmonths.dta is a long-form datasets include all the waves from SIPP2008, all months
save "${SIPP`panel'keep}/allmonths", $replace
