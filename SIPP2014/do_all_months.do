//==============================================================================//
//===== Extended Family Institutionalization Project
//===== Dataset: SIPP2014
//===== Purpose: Executes do files to create core datafiles:
//===== 

//=========================================================================//
//== Purpose: Preparation for running the program.
//== 
//== Note: This program requires the mdesc and confirmdir packages. If you do not have this, type ssc install mdesc/confirmdir before running.
//=========================================================================//
* make sure temporary directory is clean

cd "$tempdir"

local datafiles: dir "$tempdir" files "*.dta"

foreach datafile of local datafiles {
        rm `datafile'
}

cd "$base_code"

***************************************************************************
** Section: The following code attempts to make sure these packages are installed before allowing execution.
***************************************************************************
capture findfile mdesc.ado
if ("`r(fn)'" == "") {
    display as error "It appears the mdesc package is not installed."
    display as error "Try 'ssc install mdesc' to acquire it."
    exit
}

capture findfile confirmdir.ado
if ("`r(fn)'" == "") {
    display as error "It appears the confirmdir package is not installed."
    display as error "Try 'ssc install confirmdir' to acquire it."
    exit
}

***************************************************************************
** Section: Creates macros for wave, age, month, relationships
***************************************************************************
do "$sipp2014_code/project_macros" /* this do-file contains macros of wave, age, month, relationships */

***************************************************************************
** Section: Check to make sure the required directories exist.
***************************************************************************

if ("$sipp2014_code" == "") {
    display as error "sipp2014_code macro not set."
    display as error "This macro tells us where to find the project code."
    exit
}

if ("$sipp2014_logs" == "") {
    display as error "sipp2014_logs macro not set."
    display as error "This macro tells us where to put the log files."
    exit
}

confirmdir "$sipp2014_logs"
if `r(confirmdir)' {
    display as error "The sipp2014_logs macro specifies a directory that does not exist:  $sipp2014_logs"
    exit
}

confirmdir "$sipp2014_code"
if `r(confirmdir)' {
    display as error "The sipp2014_code macro specifies a directory that does not exist:  $sipp2014_code"
    exit
}

********************************************************************************
* Execute scripts to process data.
********************************************************************************
** Extracts data from NBER download and formats it for our scripts
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" extract_and_format

** Combines all the waves into a long file where every person-wave is a record. 
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" merge_waves  

** Makes sub-datasets for analyses.
** Includes file for maternal and parental characteristics like education and immigration status
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" make_auxiliary_datasets 

** Generates a wide dataset by person (includes static demographic variables). 
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" convert_to_wide 

** Makes sure ages are consistent in all the waves. Caveat: cleaning incomplete.
* Also produces demo_wide and demo_long data files
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" normalize_ages 

** Creates matched demographic info file for all coresident pairs of type 1 people 
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" allpairs

** Computes biderectional base relationships (mom, dad, child, spouse) 
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" compute_relationships 

** Creates a variable to measure change in household composition.
** Also creates lists of people who arrive/leave or stay in ego's household
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" create_comp_change 

** Creates addr_change and hh_change. Converts data file to long. Core file: hh_change.dta
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" create_hh_change 

** Links ego's household arrivers and stayers (in comp_change) 
** to relationships data created by compute_relationships. 
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" create_changer_rels 

** Merges relationship of changers to ego back to comp_change
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" create_HHchangeWithRelationships 

** Creates a pairwise data file with one record per coresident individuals in each wave.
** Useful for identifying household composition of children, but to produce results that describe
** households of children, need to collapse by SSUID SHHADID and panelmonth and then select if adj_age < 18
do "$base_code/do_and_log" "$sipp2014_code" "$sipp2014_logs" create_HHComp_asis

/*
******************************
* Clean up temporary directory
******************************
cd "$tempdir"

local datafiles: dir "$tempdir" files "*.dta"

foreach datafile of local datafiles {
        rm `datafile'
}

cd "$base_code"
