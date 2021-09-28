* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global base_code "C:/Users/Carolina Aragao/Documents/GitHub/extfamily_institutionalization"

global boxdir "C:/Users/Carolina Aragao/Box"
global projdir "$boxdir/SIPP"

* 2008 Macros

* This is the location of the SIPP original data
global SIPP2008core "$projdir/data/SIPP2008/FullFile"
global SIPP2008tm "$projdir/data/SIPP2008/FullFile"

* This is the location of the do files.  
global sipp2008_code "$base_code/SIPP2008"

* This is where logfiles produced by processing 2008 will go
global sipp2008_logs "$boxdir/sipp files/logs2008"

* This is where data will put data files tht are used in the analysis
global SIPP08keep "$boxdir/sipp files/WorkingFiles2008"

* 2014 Macros
* This is the location of the SIPP original data
global SIPP2014 "$boxdir/UT/sipp2014"

* This is the location of the do files.
global sipp2014_code "$base_code/SIPP2014"

*This is the location of the SIPP Extracts and analysis files
global SIPP14keep "$boxdir/sipp files/WorkingFiles2014"

* This is where logfiles produced by processing 2014 panel will go
global sipp2014_logs "$boxdir/sipp files/logs2014"

* Pooled data from multiple panels
global SIPPpoolkeep "$boxdir/sipp files/pooled"

* This is where logfiles produced by pooled data files will go
global sipp20pool_logs "$boxdir/sipp files/logs"

*temporary data files
global tempdir "C:/Users/Carolina Aragao/Documents/temp 2014"

* results
global results "$boxdir/sipp files/results"


global replace "replace"

