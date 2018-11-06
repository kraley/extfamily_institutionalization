*******************************************************
* Table 2 analysis
*******************************************************
use "$SIPP08keep/hh_change.dta", clear

* limit to cases that have fully-observed intervals or we were able to infer hh_change

drop if insample==0

keep if adj_age < $adult_age 

* this doesn't really matter since comp_change is missing if SWAVE==15
drop if SWAVE==15

do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" HHchange_table  

do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" Compchange_table  

do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" addrchange_table  

tab par_ed_first
tab my_race
tab my_racealt
