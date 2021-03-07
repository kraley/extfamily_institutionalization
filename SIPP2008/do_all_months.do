//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

* make sure temporary directory is clean

cd "$tempdir"

local datafiles: dir "$tempdir" files "*.dta"

foreach datafile of local datafiles {
        rm `datafile'
}

cd "$base_code"

***************************************************************************
** Section: Creates macros for wave, age, month, relationships
***************************************************************************
do "$base_code/SIPP2008/project_macros" /* this do-file contains macros of wave, age, month, relationships */

***************************************************************************
** Section: Check to make sure the required directories exist.
***************************************************************************
if ("$sipp2008_code" == "") {
    display as error "sipp2008_code macro not set."
    display as error "This macro tells us where to find the project code."
    exit
}

if ("$sipp2008_logs" == "") {
    display as error "sipp2008_logs macro not set."
    display as error "This macro tells us where to put the log files."
    exit
}

confirmdir "$sipp2008_logs"
if `r(confirmdir)' {
    display as error "The sipp2008_logs macro specifies a directory that does not exist:  $sipp2008_logs"
    exit
}

confirmdir "$sipp2008_code"
if `r(confirmdir)' {
    display as error "The sipp2008_code macro specifies a directory that does not exist:  $sipp2008_code"
    exit
}

********************************************************************************
* Execute scripts to process data.
********************************************************************************
** ATTENTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
** NOTE: Please do not change the directories here. If $sipp2008_code does not point to the correct
** directory, change it in your setup file. 
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" extract_and_format

** Combines all the waves into a long file where every person-wave is a record. 
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" merge_all_months  

** Makes sub-datasets for analyses.
** Includes file for maternal and parental characteristics like education and immigration status
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" make_auxiliary_datasets_am 

** Generates a wide dataset by person (includes static demographic variables). 
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" convert_to_wide_am 

** Makes sure ages are consistent in all the waves. Caveat: cleaning incomplete.
* Also produces demo_wide and demo_long data files
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" normalize_ages_am 

** Computes biderectional base relationships (mom, dad, child, spouse) 
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" compute_base_relationships_am 

** Identifies additional relationships transitively
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" compute_secondary_relationships_am 

** Creates a variable to measure change in household composition.
** Also creates lists of people who arrive/leave or stay in ego's household
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_comp_change_am 

** Creates addr_change and hh_change. Converts data file to long. Core file: hh_change.dta
*do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_hh_change_am 

** Links ego's household arrivers and stayers (in comp_change) 
** to relationships data created by compute_secondary_relationships. 
do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_changer_rels_am 

** Merges relationship of changers to ego back to comp_change
do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_HHchangeWithRelationships_am

** Creates a pairwise data file with one record per coresident individuals in each wave.
** Useful for identifying household composition of children, but to produce results that describe
** households of children, need to collapse by SSUID SHHADID and SWAVE and then select if adj_age < 18
do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_HHComp_asis_am

do "$base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" relationship_matrix.do

