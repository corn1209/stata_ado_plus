*! outdat.ado Version 1.6 ukohler@sowi.uni-mannheim.de 03-Sep-2002

* Change Log
*-----------

* Version 1.6: More than one Argument in type() added.
*              nobs-flag added to output
* Version 1.5: upper and create options added 
* Version 1.4: Nostring and listwise options added
* Version 1.3: Set display formats before saving
* Version 1.2: if,in included
* Version 1.1: New Caller for external programs


program define outdat
version 7.0
syntax [varlist] using/ [in] [if] [, replace Type(string) NOSTring LISTWISE  /*
*/ UPper CREate ] 

* Error-Checks
* ------------

capture which file
if _rc == 111 {
	di "{txt} transfer requires up to date stata -- See help {help update}"
}

preserve

* DEFAULT
* -------

if "`type'" == "" {local type "spss"}

* IF/IN
* -----

if "`if'" ~= "" | "`in'" ~= "" {
	keep `if' `in'
}

* NOSTRING
* --------

if "`nostring'" ~= "" {
	foreach var of varlist `varlist' {
		local storage : type `var'
		if substr("`storage'",1,3)  ~= "str" {
			local outlist "`outlist' `var'"
		}
	}
}
else {
	local outlist "`varlist'" 
}

* NOMISSING
* ---------

if "`listwise'" ~= "" {
	mark touse
	markout touse `outlist' 
	keep if touse
	local cwd "after listwise deletion"
}

local nobs = _N
if `nobs' == 0 {
  error 2000
  exit
}
di _n "{txt}Selected data set contains {result}`nobs' {txt}rows {result}`cwd'"


* UPPER
* -----

global outdatuc 0  /* Used in outdat_sql.ado */
if "`upper'" ~= "" {
	foreach var of varlist `outlist' {
		local new = upper("`var'")
		capture rename `var' `new'
		if _rc ~= 0 {
			noi di `"{error}varnames not unique after upper"'
		        exit _rc
		}
		local Outlist "`Outlist' `new'"
	}
	local outlist "`Outlist'"
	global outdatuc 1  /* Used in outdat_sql.ado */
}

* CREATE
* ------

global outdatcr 0  /* Used in outdat_sql.ado */
if "`create'" ~= "" {
	global outdatcr 1  /* Used in outdat_sql.ado */
}


* SAVE DATA
* ---------
	
quietly compress
foreach var of local outlist {
    capture confirm byte `var'
    if _rc == 0 {
      format `var' %4.0g
    }
    capture confirm int `var'
    if _rc == 0 {
      format `var' %8.0g
    }
    capture confirm long `var'
    if _rc == 0 {
      format `var' %16.0g
    }
    capture confirm float `var'
    if _rc == 0 {
      format `var' %10.0g
    }
    capture confirm double `var'
    if _rc == 0 {
      format `var' %18.0g
    }
}

if "`type'" ~= "sql" {
  quietly outfile `outlist' using `using'.dat, nolabel `replace'
  di "{txt}Raw data written to {res} `using'.dat" _n
}

* DATA LIST
* ---------

foreach part of local type {
	outdat_`part' `outlist' using `using'
}
		
end
exit


Ulrich Kohler
University of Mannheim
Faculty of Social Sciences
68131 Mannheim
+49 (0621) 181-2053
