*! SPSS-Syntax for outdat.ado 1.4 ukohler@sowi.uni-mannheim.de
* Change-log
* ----------

* Version 1.4: New output
* Version 1.3: Lists Variable Names in Data List in Columns
* Version 1.2: New Naming, Write Commends
* Version 1.1: Write Value labels for values that exists only
* Version 1.0: New program name because new caller in outdat.ado
  
version 7.0
program define outdat_spss
syntax [varlist] using/ 

quietly {
	file open spsfile using `using'.sps, replace text write

	* DATA LIST
	* ---------

        file write spsfile `"* SPSS-syntax to read and label `using'.dat"'
	file write spsfile  /*
	*/ _n _n `"DATA LIST FILE = "`using'.dat" FREE / "' _n

        local j 1
	foreach var of varlist `varlist' { 
                local l = 9-length("`var'")+(mod(`j',7)!=0)
                file write spsfile `"`var'"' _skip(`l') 
                local j=`j'+1
                if (mod(`j'-1,7)==0) { 
			file write spsfile _n
		}
	}
	file write spsfile `" ."'

	* VARIABLE LABEL
	* --------------

	file write spsfile _n "VARIABLE LABELS"
	foreach var of varlist `varlist' {
		local varlab: variable label `var'
		file write spsfile _n (upper("`var'")) `" "`varlab'" "'
	}
	file write spsfile "."

	* VALUE LABEL
	* -----------

	file write spsfile _n "VALUE LABELS"

        local i 1
	foreach var of varlist `varlist' {

		* Count kategories of Var
		sort `var'
		tempvar kvar
		by `var': gen `kvar' = 1 if _n == 1
		replace `kvar' = sum(`kvar')
		local K = `kvar'[_N]

		local yes: value label `var'
		if "`yes'" ~= "" {
			if `i' == 1 {
				file write spsfile _n (upper("`var'"))
				local i = `i' +1 
			}
			else {
				file write spsfile _n "/" (upper("`var'"))
			}
			forvalues j = 1/`K' {
				summarize `var' if `kvar' == `j', meanonly
				local k = r(mean)
				local vallab: label (`var') `k'
                                if "`k'"  ~= "." {
                                  file write spsfile _n `"`k' "`vallab'" "'
                                }
			}
		}
                drop `kvar' 
	}
	file write spsfile "." _n "exe." _n
	file close spsfile

	noi di "{res}SPSS{txt} commands written to {view `using'.sps:`using'.sps}"

}
		
end
exit


Ulrich Kohler
University of Mannheim
Faculty of Social Sciences
68131 Mannheim
+49 (0621) 181-2053
