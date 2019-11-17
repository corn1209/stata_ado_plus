program define outdat_rats
*! Rats-Programm for outdat.ado ukohler@sowi.uni-mannheim.de
* builds on torats.ado from cfb v1.2.1 1314 

* Change Log
* ----------

* 1.1: New Output

version 7.0
syntax [varlist] using/

local nobs = _N
        
quietly {
	file open ratfile using `using'.rat, replace text write

	* RAT-Program
	* ------------

        file write ratfile `"* RAT-Program to read and label `using'.dat"'
	file write ratfile  /*
	*/ _n _n `"alloc `nobs'"'  /*
        */ _n `"open data `using'.dat"'  /*
        */ _n `"data(unit=data,org=obs) / $"' _n
        local j 1
	foreach var of varlist `varlist' {
                local type : type `var'
                if substr("`type'",1,3) == "str" {
			local note 1
		}
                local l = 9-length("`var'")+(mod(`j',7)!=0)
                file write ratfile `"`var'"' _skip(`l') 
                local j=`j'+1
                if (mod(`j'-1,7)==0) { 
			file write ratfile `" $ "' _n
		}
	}
	file close ratfile
}
di "{res}RATS{txt} commands written to {view `using'.rat:`using'.rat}"

if "`note'" == "1" {
	di "{txt}Note: Data contains strings."
        di "RATS cannot handle strings. Consider nostring option" 
}

end
exit
