*! Limdep-Syntax for outdat.ado 1.3 ukohler@sowi.uni-mannheim.de

* Change-log
* ----------

* Version 1.3: New Output
* Version 1.2: Varlist is writen nicer
* Version 1.1: New Naming, Write Commends

version 7.0
program define outdat_limdep

syntax [varlist] using/ 

local nobs = _N
local nvar: word count `varlist'

quietly {
	file open limfile using `using'.lim, replace text write

	* DATA LIST
	* ---------

        file write limfile `"* Limdep-syntax to read and label `using'.dat"'
	file write limfile _n _n `"READ "' _n
	file write limfile `"  ; File = `using'.dat "' _n
	file write limfile `"  ; Nobs = `nobs' "' _n
	file write limfile `"  ; Nvars = `nvar' "' _n
	file write limfile `"  ; Names = "' _n
        local j 1
	foreach var of varlist `varlist' { 
                local l = 9-length("`var'")+(mod(`j',7)!=0)
                file write limfile `"`var',"' _skip(`l') 
                local j=`j'+1
                if (mod(`j'-1,7)==0) { 
			file write limfile _n
		}
	}
	file write limfile "$" _n
	file close limfile
	noi di "{res}Limdep{txt} commands written to {view `using'.lim:`using'.lim}"
end
exit


Ulrich Kohler
University of Mannheim
Faculty of Social Sciences
68131 Mannheim
+49 (0621) 181-2053
