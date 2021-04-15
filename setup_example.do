* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global base_code "$homedir/github/extfamily_institutionalization"

* 2008 Macros

* This is the location of the SIPP original data
global SIPP2008core "/data/sipp/2008_Core/StataData"
global SIPP2008tm "/data/sipp/2008_TM/StataData"

* This is the location of the do files.  
global sipp2008_code "$base_code/SIPP2008"

* This is where logfiles produced by stata will go
global sipp2008_logs "$homedir/projects/extfamily_institutionalization/logs"

* This is where data will put data files that are used in the analysis
global SIPP08keep "$homedir/projects/extfamily_institutionalization/data/keep/2008"

* 2014 Macros
* This is the location of the SIPP original data
global SIPP2014 "/data/sipp/2014"

* This is the location of the do files.
global sipp2014_code "$base_code/SIPP2014"

*This is the location of the SIPP Extracts and analysis files
global SIPP14keep "$homedir/projects/extfamily_institutionalization/data/keep/2014"

* This is where logfiles produced by stata will go
global sipp2014_logs "$homedir/projects/extfamily_institutionalization/logs/2014"

*temporary data files
global tempdir "$homedir/projects/extfamily_institutionalization/data/temp"

*results


global replace "replace"

