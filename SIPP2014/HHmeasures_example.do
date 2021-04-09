********************************************************************************
*
*
* Example code for creating household measures two ways

* Note that this file is created by running extract_and_format as well as merge_waves
use "$SIPP14keep/allmonths14", clear  

* How many people are living in the household?

* To answer this question we simply count the number of people with the same household id
* In the SIPP 2014, SSUID and ERESIDENCEID can identify households, but we also need to remember
* that households change over time. When we ask "How many people are living in the household?"

* We can calculate the number of people in the household in a particular month by "collapsing"
* the data from a situation where individuals are records to one where households are records.

* create a variable that equals one for every record so that I have something to count
gen all=1

* I'm going to preserve the data. The reasons will become clear.
preserve

collapse (count) hhmembers=all, by(SSUID ERESIDENCEID)

tab hhmembers

* Wait, there's a household with more than 600 members? What is going on? 
* The problem is we haven't taken into account time. 
* The unstated part of the question is "at a particular point in time." Thus we also need 
* information on time. Altogether, SSUID ERESIDENCE SWAVE and MONTHCODE identify 
* households in a particular month.

restore

preserve

collapse (count) hhmembers=all, by(SSUID ERESIDENCEID swave MONTHCODE)

tab hhmembers

* Ah, that's better. The largest household is 20 members. That's a lot, but 
* it's believable.

* The next step is to save the temporary file so that I can merge the household measure back onto 
* a person-level file so that I have the household size on each person's records

save "$tempdir/hhmembers", replace

restore

merge m:1 SSUID ERESIDENCEID swave MONTHCODE using "$tempdir/hhmembers"

* every record in each file should be matched. To make sure...
assert _merge==3

tab hhmembers
* The number of household members is different from the earlier tab because we 
* have shifted from households to people. 

* save the result if you are happy

* This is one way to create household measures. You can create other variables like maximum age
* of any household member or mean age of household member by replacing (count) with (max) or 
* (mean) and all * with age. You can create a count of children by creating a dummy indicator
* for child (gen child=1 if TAGE < 18 ) and count that instead of all.

* Collapse is a little bit clunky because you have to save a temporary file. A streamlined
* approach is to use egen

* Let's start with a fresh copy of the data

use "$SIPP14keep/allmonths14", clear  

egen hhmembers = count(PNUM !=0), by(SSUID ERESIDENCEID swave MONTHCODE)

tab hhmembers
