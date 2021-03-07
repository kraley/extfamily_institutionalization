* Set up the base ChildHH (Children's Households) environment.

* The current directory is assumed to be the one with the base ChildHH code.

* We expect to find your setup file, named setup_<username>.do
* in the base ChildHH directory (as defined above).


* Find my home directory, depending on OS.
if ("`c(os)'" == "Windows") {
    local temp_drive : env HOMEDRIVE
    local temp_dir : env HOMEPATH
    global homedir "`temp_drive'`temp_dir'"
    macro drop _temp_drive _temp_dir`
}
else {
    if ("`c(os)'" == "MacOSX") | ("`c(os)'" == "Unix") {
        global homedir : env HOME
    }
    else {
        display "Unknown operating system:  `c(os)'"
        exit
    }
}

*global childhh_base_code "`c(pwd)'"

do setup_`c(username)'


********************************************************************************
* Check for package dependencies 
********************************************************************************
* This checks for packages that the user should install prior to running the project do files.

// fre: https://ideas.repec.org/c/boc/bocode/s456835.html
capture : which fre
if (_rc) {
    display as error in smcl `"Please install package {it:fre} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install fre":auto-install fre}"'
    exit 199
}

capture : which combomarginsplot
if (_rc) {
    display as error in smcl `"Please install package {it:combomarginsplot} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install combomarginsplot":auto-install combomarginsplot}"'
    exit 199
}

capture : which confirmdir
if (_rc) {
    display as error in smcl `"Please install package {it:confirmdir} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install confirmdir":auto-install confirmdir}"'
    exit 199
}

capture : which mdesc
if (_rc) {
    display as error in smcl `"Please install package {it:mdesc} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install mdesc":auto-install mdesc}"'
    exit 199
}

