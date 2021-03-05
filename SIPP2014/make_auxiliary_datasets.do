//=================================================================================//
//====== Extended Family Institutionalization Project                          
//====== Dataset: SIPP2014                                             
//====== Purpose: Creates sub-databases: shhadid_members.dta, ssuid_members_wide.dta
//====== ssuid_shhadid_wide.dta, person_pdemo (parents demographics), partner_of_ref_person_long (and wide)
//=================================================================================//

//================================================================================//
//== Section: Make the shhadid member database with a single string variable 
//== containing a list of all EPPPNUMs in a household in a month. 
//================================================================================//
use "$SIPP14keep/allmonths14", clear

* How many residenceids per sampling unit in wave 1 // we observe up to 4

local i_vars "SSUID ERESIDENCEID" // note that SHHADID is all about household that spawn. Not all residences. 
local j_vars "panelmonth"

keep `i_vars' `j_vars' PNUM TAGE RHNUMPER RHNUMPERWT2 
sort `i_vars' `j_vars' PNUM TAGE

by `i_vars' `j_vars':  gen hhmemnum = _n  /* Number the people in household in each month. */

egen maxpnum = max(hhmemnum) /* max n of people in household in any month. */

local maxpn = `=maxpnum' /* to use below in forvalues loop */

*******************************************************************************
** Section: Generate a horizontal list of type 1 people in the household at each month.
*******************************************************************************
* This just gets people who were in a sample household at the time of an interview. Need to add "type 2" people

* Create for_concat* variables equal to string value of pn's EPPPNUM for for_contact_*[pn] and missing otherwise

forvalues pn = 1/`maxpn' {
    gen for_concat_person`pn' = string(PNUM) if (hhmemnum == `pn')
}

drop hhmemnum

* Collapse by address (SSUID ERESIDENCEID) to take the first non-missing value of the 
* variables we built above. Note that there is exactly one non-missing -- 
* only the nth person in the household in this month got a value set for variable #n.

keep `i_vars' `j_vars' for_concat_person* RHNUMPERWT2

collapse (firstnm) for_concat_person* RHNUMPERWT2, by (`i_vars' `j_vars')

* Concatenate all for_concat* variables into a single string where each person number is separated by a blank.
egen t1residence_members = concat(for_concat_person*), punct(" ")

* clean up
drop for_concat_person* 

save "$tempdir/t1residence_members", $replace

*******************************************************************************
** Section: Generate a horizontal list of type 2 people in the household at each month.
* and then merge onto list of t1 residence members
*******************************************************************************

* person-numbers for type 2 people are listed in variables ET2_LNOX, but not consecutively
* Can concatenate and strip out missing values 

use "$SIPP14keep/allmonths14_type2.dta", clear

* replace missing data with blanks

gen anyt2=.
forvalues lno=1/10 {
    replace anyt2=1 if !missing(ET2_LNO`lno')
    tostring ET2_LNO`lno', replace
    replace ET2_LNO`lno'=" " if ET2_LNO`lno'=="."
}

egen t2residence_members=concat(ET2_LNO*), punct(" ")

keep `i_vars' `j_vars' t2residence_members anyt2

* take only observations with type 2 people

collapse (firstnm) anyt2 t2residence_members, by (`i_vars' `j_vars')

drop anyt2

merge 1:1 SSUID ERESIDENCEID panelmonth using "$tempdir/t1residence_members"

drop _merge

egen residence_members=concat(t1residence_members t2residence_members), punct(" ")

* Strip out extra spaces.
replace residence_members = strtrim(residence_members)

* Add a space at the beginning and end of the string to make sure every person appears surrounded by spaces.
replace residence_members = " " + residence_members + " "

********************************************************************
** Section: Compute number of household members by month and overall.
********************************************************************
sort panelmonth
gen n_residence_members = wordcount(residence_members)

* verify through comparison to census variable
assert n_residence_members==RHNUMPERWT2

* create max variables for later loops
by panelmonth:  egen mx_residence_members = max(n_residence_members)
egen overall_max_residence_members = max(n_residence_members)

drop n_residence_members

compress 

macro drop i_vars j_vars 

save "$tempdir/residence_members", $replace

//================================================================================//
//== Purpose: Make the ssuid member database
//== The logic is similar for the shhadid database, but here we are going to collapse
//== by sample unit (SSUID) instead of address (SSUID ERESIDENCEID) to create variables
//== describing number of sample unit members across all months
//================================================================================//

use "$SIPP14keep/allmonths14"

local i_vars "SSUID"
local j_vars "panelmonth"

keep `i_vars' `j_vars' PNUM
sort `i_vars' `j_vars' PNUM

by `i_vars' `j_vars':  gen hhmemnum = _n  /* Number the people in the sampling unit in each wave. */

egen maxpnum = max(hhmemnum) /* max n of people in sampling unit in any month. */
local maxpn = `=maxpnum' /* to use below in forvalues loop */

*******************************************************************
** Section: Generate a horizontal list of people in the SSUID (original sampling unit).
********************************************************************

* Create for_concat* variable equal to string value of pn's EPPPNUM for for_contact_*[pn] and missing otherwise
forvalues pn = 1/`maxpn' {
    gen for_concat_person`pn' = string(PNUM) if (hhmemnum == `pn')
}

drop hhmemnum

keep `i_vars' `j_vars' for_concat_person*

* Collapse to take the first non-missing of the variables we built above.  
* There is exactly one non-missing -- only the nth person in the household in this month got a value set for variable #n.
collapse (firstnm) for_concat_person*, by (`i_vars' `j_vars')

*Concatenate all person-numbers into a single string.
egen t1ssuid_members = concat(for_concat_person*), punct(" ")

drop for_concat_person*

save "$tempdir/t1ssuid_members_wide", $replace

*******************************************************************************
** Section: Generate a horizontal list of type 2 people in the SSUID
*******************************************************************************

* person-numbers for type 2 people are listed in variables ET2_LNOX, but not consecutively
* Can concatenate and strip out missing values 

use "$SIPP14keep/allmonths14_type2.dta", clear

* replace missing data with blanks

gen anyt2=.
forvalues lno=1/10 {
    replace anyt2=1 if !missing(ET2_LNO`lno')
    tostring ET2_LNO`lno', replace
    replace ET2_LNO`lno'=" " if ET2_LNO`lno'=="."
}

egen t2ssuid_members=concat(ET2_LNO*), punct(" ")

keep `i_vars' `j_vars' t2ssuid_members anyt2

* take only observations with type 2 people

collapse (firstnm) anyt2 t2ssuid_members, by (`i_vars' `j_vars')

drop anyt2

merge 1:1 SSUID panelmonth using "$tempdir/t1ssuid_members_wide"

drop _merge

egen ssuid_members= concat(t1ssuid_members t2ssuid_members), punct(" ")

drop t1ssuid_members
drop t2ssuid_members


* Strip out extra space to save space.
replace ssuid_members = strtrim(ssuid_members)

* Add a space at the beginning and end of the string so we are sure every person appears surrounded by spaces.
replace ssuid_members = " " + ssuid_members + " "

* Compute max number of members by month and overall.
sort panelmonth
gen n_ssuid_members = wordcount(ssuid_members)
by panelmonth:  egen max_ssuid_members = max(n_ssuid_members)
egen overall_max_ssuid_members = max(n_ssuid_members)
drop n_ssuid_members

compress 

reshape wide ssuid_members max_ssuid_members, i(`i_vars') j(`j_vars')

macro drop i_vars j_vars

save "$tempdir/ssuid_members_wide", $replace

//================================================================================//
//== Purpose: Make the ssuid ERESIDENCEID database with information on the number of addresses (ERESIDENCEID)
//== in the sampling unit (SSUID) in each month and overall.
//================================================================================//

use "$SIPP14keep/allmonths14"

local i_vars "SSUID"
local j_vars "panelmonth"

keep `i_vars' `j_vars' ERESIDENCEID
sort `i_vars' `j_vars' ERESIDENCEID

duplicates drop

by `i_vars' `j_vars':  gen anum = _n /* Number the addresses in the household for each month. */

* maximum number of addresses in any household in any month.
egen maxanum = max(anum)
local maxan = `=maxanum'

*******************************************************************
** Section: Generate a horizontal list of addresses in the SSUID (original sampling unit).
********************************************************************

* Create for_concat* variable equal to string value of address's ERESIDENCEID for for_contact_*[an] and missing otherwise

forvalues an = 1/`maxan' {
    gen for_concat_address`an' = ERESIDENCEID if (anum == `an')
}

drop anum

keep `i_vars' `j_vars' for_concat_address* 

* Collapse to take the first non-missing of the variables we built above.  
* There is exactly one non-missing -- only the nth address in the household in this month got a value set for variable #n.
collapse (firstnm) for_concat_address*, by (`i_vars' `j_vars')


*Concatenate all "addresses" into a single string.
egen ssuid_residence = concat(for_concat_address*), punct(" ")

drop for_concat_address*

* Save space by stripping out extra spaces.
replace ssuid_residence = strtrim(ssuid_residence)

* Add a space at the beginning and end of the string so we are sure every person appears surrounded by spaces.
replace ssuid_residence = " " + ssuid_residence + " "

* Compute max number of addresses by month and overall.

sort panelmonth
gen n_ssuid_residence = wordcount(ssuid_residence)
by panelmonth:  egen max_ssuid_residence = max(n_ssuid_residence)
egen overall_max_ssuid_residence = max(n_ssuid_residence)
drop n_ssuid_residence

compress

reshape wide ssuid_residence max_ssuid_residence, i(`i_vars') j(`j_vars')

macro drop i_vars j_vars

save "$tempdir/ssuid_residence_wide", $replace

//================================================================================//
//== Purpose: Create a dataset with education, immigration status (year of immigration), and age for merging.
//== Logic: Rename EPPPNUM to later merge onto person number of mother (EPNMOM) 
//==        and father (EPNDAD) to get parents' educ and immigration status in the analysis dataset.
//================================================================================//

 
use "$SIPP14keep/allmonths14"

local i_vars "SSUID PNUM"
local j_vars "panelmonth" 


keep `i_vars' `j_vars' swave EEDUC TAGE ESEX TYRENTRY

sort `i_vars' `j_vars' swave EEDUC TAGE ESEX TYRENTRY


** Label recoded education.
#delimit ;
label define educ   1 "lths"
                    2 "hs"
                    3 "ltcol"
                    4 "coll";
#delimit cr

recode EEDUC (31/38 = 1)  (39 = 2)  (40/42 = 3)  (43/46 = 4), gen (educ)
label values educ educ

drop EEDUC

*Years in the US
*The year the wave was taken:
g year=swave+2013
drop swave

*year of birth
g birthyear=year-TAGE

*year of migration
g yrmigration=TYRENTRY
replace yrmigration=2013 if TYRENTRY==2014 & year==2014
replace yrmigration=2010.5 if TYRENTRY==2011 & year==2014
replace yrmigration=2008.5 if TYRENTRY==2009 & year==2014
replace yrmigration=2006.5 if TYRENTRY==2007 & year==2014
replace yrmigration=2003.5 if TYRENTRY==2004 & year==2014
replace yrmigration=1996.5 if TYRENTRY==1997 & year==2014
replace yrmigration=1994.5 if TYRENTRY==1995 & year==2014
replace yrmigration=1992.5 if TYRENTRY==1993 & year==2014
replace yrmigration=1990.5 if TYRENTRY==1991 & year==2014
replace yrmigration=1988.5 if TYRENTRY==1989 & year==2014
replace yrmigration=1986.5 if TYRENTRY==1987 & year==2014
replace yrmigration=1984.5 if TYRENTRY==1985 & year==2014
replace yrmigration=1982 if TYRENTRY==1983 & year==2014
replace yrmigration=1979 if TYRENTRY==1980 & year==2014
replace yrmigration=1975.5 if TYRENTRY==1977 & year==2014
replace yrmigration=1971.5 if TYRENTRY==1973 & year==2014
replace yrmigration=1965.5 if TYRENTRY==1961 & year==2014
replace yrmigration=1960 if TYRENTRY==1961 & year==2014
replace yrmigration=1961 if TYRENTRY==1962 & year==2015
replace yrmigration=1966 if TYRENTRY==1969 & year==2015
replace yrmigration=1971.5 if TYRENTRY==1973 & year==2015
replace yrmigration=1975.5 if TYRENTRY==1977 & year==2015
replace yrmigration=1979 if TYRENTRY==1980 & year==2015
replace yrmigration=1982 if TYRENTRY==1983 & year==2015
replace yrmigration=1984.5 if TYRENTRY==1985 & year==2015
replace yrmigration=1986.5 if TYRENTRY==1987 & year==2015
replace yrmigration=1988.5 if TYRENTRY==1989 & year==2015
replace yrmigration=1990.5 if TYRENTRY==1991 & year==2015
replace yrmigration=1992.5 if TYRENTRY==1993 & year==2015
replace yrmigration=1994.5 if TYRENTRY==1995 & year==2015
replace yrmigration=1996.5 if TYRENTRY==1997 & year==2015
replace yrmigration=2003.5 if TYRENTRY==2004 & year==2015
replace yrmigration=2006.5 if TYRENTRY==2007 & year==2015
replace yrmigration=2008.5 if TYRENTRY==2009 & year==2015
replace yrmigration=2011 if TYRENTRY==2012 & year==2015
replace yrmigration=2014 if TYRENTRY==2015 & year==2015
replace yrmigration=1961 if TYRENTRY==1962 & year==2016
replace yrmigration=1966 if TYRENTRY==1969 & year==2016
replace yrmigration=1971.5 if TYRENTRY==1973 & year==2016
replace yrmigration=1975.5 if TYRENTRY==1977 & year==2016
replace yrmigration=1979 if TYRENTRY==1980 & year==2016
replace yrmigration=1982 if TYRENTRY==1983 & year==2016
replace yrmigration=1984.5 if TYRENTRY==1985 & year==2016
replace yrmigration=1986.5 if TYRENTRY==1987 & year==2016
replace yrmigration=1988.5 if TYRENTRY==1989 & year==2016
replace yrmigration=1990.5 if TYRENTRY==1991 & year==2016
replace yrmigration=1992.5 if TYRENTRY==1993 & year==2016
replace yrmigration=1994.5 if TYRENTRY==1995 & year==2016
replace yrmigration=1996.5 if TYRENTRY==1997 & year==2016
replace yrmigration=2002.5 if TYRENTRY==2003 & year==2016
replace yrmigration=2006.5 if TYRENTRY==2007 & year==2016
replace yrmigration=2008.5 if TYRENTRY==2009 & year==2016
replace yrmigration=2011.5 if TYRENTRY==2012 & year==2016
replace yrmigration=2014.5 if TYRENTRY==2016 & year==2016
replace yrmigration=1961 if TYRENTRY==1962 & year==2017
replace yrmigration=1966 if TYRENTRY==1969 & year==2017
replace yrmigration=1971.5 if TYRENTRY==1973 & year==2017
replace yrmigration=1976 if TYRENTRY==1978 & year==2017
replace yrmigration=1979.5 if TYRENTRY==1980 & year==2017
replace yrmigration=1982 if TYRENTRY==1983 & year==2017
replace yrmigration=1985 if TYRENTRY==1986 & year==2017
replace yrmigration=1987.5 if TYRENTRY==1988 & year==2017
replace yrmigration=1989.5 if TYRENTRY==1990 & year==2017
replace yrmigration=1991.5 if TYRENTRY==1992 & year==2017
replace yrmigration=1993.5 if TYRENTRY==1994 & year==2017
replace yrmigration=1995.5 if TYRENTRY==1996 & year==2017
replace yrmigration=1997.5 if TYRENTRY==1998 & year==2017
replace yrmigration=2002.5 if TYRENTRY==2003 & year==2017
replace yrmigration=2004.5 if TYRENTRY==2005 & year==2017
replace yrmigration=2006.5 if TYRENTRY==2007 & year==2017
replace yrmigration=2008.5 if TYRENTRY==2009 & year==2017
replace yrmigration=2010.5 if TYRENTRY==2011 & year==2017
replace yrmigration=2012.5 if TYRENTRY==2013 & year==2017
replace yrmigration=2015.5 if TYRENTRY==2017 & year==2017

*age at immigration- missing values are native born
g age_migration=yrmigration-birthyear


* demo_epppnum will be key to merge with epnmom and epndad to get parent education onto
* ego's record
rename PNUM pdemo_epppnum
rename TAGE page /* page for "parent age" */
rename ESEX psex // parent sex because the parent pointers are now gender neutral
rename age_migration ptmoveus /* pmoveus for "parent's age at immigration" */

save "$tempdir/person_pdemo", $replace

* create a dataset of household reference persons.
do "$base_code/SIPP2014/make_aux_refperson"


