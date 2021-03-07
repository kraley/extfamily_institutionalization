* This file executes do files, but first executes
* standard startup boilerplate and last executes
* standard completion boilerplate.

* It takes three parameters, 
*  1. the directory where the project code lives.
*  2. the directory where log files should go.
*  3. the basename of the do file.  
*
* "Basename" just means the name without the .do or .log on the end.
* The basename is also used as the basename of the log file.



args codedir logdir fname


do "$base_code/prolog" "`logdir'" "`fname'"


do "`codedir'/`fname'"


do "$base_code/epilog" "`logdir'" "`fname'"
