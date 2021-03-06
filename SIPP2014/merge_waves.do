//====================================================================//
//===== Children's Household Instability Project                    
//===== Dataset: SIPP2014                                          
//===== Purpose: This code append all waves of SIPP2014 original data into a long form dataset. 
//=====================================================================//


* First merge the type 1 information

** Import first wave. 
use "$SIPP14keep/wave${first_wave}_extract", clear 

** Append the first wave with waves from the second to last
forvalues wave = $second_wave/$final_wave {
    append using "$SIPP14keep/wave`wave'_extract"
}

** allmonths14.dta is a long-form dataset including all the waves from SIPP2014


save "$SIPP14keep/allmonths14.dta", $replace


* Now make a file with type 2 information

** Import first wave. 
use "$SIPP14keep/wave${first_wave}_type2_extract", clear 

** Append the first wave with waves from the second to last
forvalues wave = $second_wave/$final_wave {
    append using "$SIPP14keep/wave`wave'_type2_extract"
}

** allmonths14.dta is a long-form dataset including all the waves from SIPP2014


save "$SIPP14keep/allmonths14_type2.dta", $replace
