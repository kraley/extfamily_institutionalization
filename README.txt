Extended Family Institutionalization

This README file has instructions on how to run the accompanying code to: 
Part 1. Setup to be able to run the code
Part 2. Download and prepare original data
Part 3. Produce variables for analysis and produce analyses

Part 1. Setup to be able to run the code in stata (version 16)

	To run the data creation files, edit setup_example.do to create your personal setup file. 
	The personalized setup do file defines several macros required by the project code.
	The values of the macros are personalized, but the names of the macros must be the same for all users.
	See an example setup file, e.g. setup_XXXX.do, to learn which macros must be defined. To run the code
	you will need to create your own personalized setup file named setup_<username>.do, where <username> is replaced
	by your username on this computer running the code.

Part 2. Download and prepare original data

	The full files were obtained from NBER (http://www.nber.org/data/survey-of-income-and-program-participation-sipp-data.html). 
	
	The 2008 Panel has 16 Waves. This project uses Waves 1 through 15. You'll need data (.zip or .z), stata code (.do), and dictionary (.dct)
	Each wave has a core data file and a topical module file. 

	The puw files are the Core data.
	he putm files are the Topical Module files.
	
        The original do files must be modified to match the environment in which they will be executed.
	A couple other modifications may also be useful.
	1. The original do file contains a hard-coded path to the data file.  This must be modified to
		match your environment.  In the version current as of this writing, the macro requiring
		modification is named dat_name.
	2. The original do file uses the "saveold" command instead of "save".  You may wish to change
		this to "save" to use the DTA format current for your version of Stata.  Saveold uses
		a backward compatible format, version 13 as of this writing. You'll also need to add "" around the file names. 
		i.e. change saveold `dta_name' , replace  -->  save "`dta_name'" , replace
	3. The original do file opens a log file but does not close it.  You may wish to add a
		"log close" to the do file. 

	Also, you may find that the dictionary files are downloaded as "sippxxxx.dct.txt" rather than
	"sippxxxx.dct".  If so, you should rename them to remove the ".txt".

        You also need to unzip the data files before running the do files.

Part 3. Produce variables for analysis and conduct analysis

	To get started with any code in this repository:
		1.  start stata
		2.  cd to the directory that holds this file as well as setup_childhh_environment
		3.  do setup_project.do
		4.  do do_all_months.do
		5.  do /analysis/analysis.do 

	setup_project.do defines several macros that locate the project data and otherwise establish project norms.  
	It also executes a personalized setup do file, named setup_<username>.do.

	Note that you should not need to alter any files except your setup file. 
	Keep path separators as "/" to be able to run in either a windows or Mac environment. 

	The remaining do files in this directory provide a convenient way to ensure that results are logged and
	that random number generator state is preserved so that results are repeatable.

