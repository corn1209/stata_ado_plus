
/* call mlboolfirst variable */

capture program drop mlboolfirst
program define mlboolfirst
version 8
	preserve
	forvalues i = 1/100 {
	   capture drop PathProb`i'
	   }
	drop boolpred
	local path "$feed"
	foreach i of numlist 1000 0 1001 1/$n {
	   gettoken path`i' path: path, match(holder)
	   }
	local j = 0
	forvalues i = 1/$n {
		local path = subinstr(subinstr("`path`i''","(","",.),")","",.)
		while "`path'" ~= "" {
		   local j = `j' + 1
		   gettoken var`j' path : path 
		   }
        }
    forvalues i = 1/`j' {
		if ("`var`i''" ~= "`0'"){
		    capture confirm int variable `var`i''
		    if !_rc {
		       tempvar varmode
		       capture quietly egen `varmode'=mode(`var`i'')
		       capture quietly replace `var`i'' = `varmode'
               }
            else {
		       capture quietly sum `var`i''
		       capture quietly replace `var`i'' = r(mean)
		       capture quietly sum `var`i''
               }
            }
	    else {
	        capture confirm int variable `var`i''
	        if !_rc {
	           local q = `i'
	           capture quietly sum `var`q''
	           local varmin=r(min)
	           local varmax=r(max)
	           }
	        else {
		       capture quietly sum `var`i''
		       capture quietly replace `var`i'' = (r(max)-r(min))*uniform()+r(min)
		       local q = `i'
			}
		}
	}
	mlboolpred

/* v7 command:	graph boolpred `var`q'',s(.) c(s) xlabel */

    local gphtitl=e(title)
    local gphdv=e(depvar)

if "`q'"=="" {
    di in red "Variable not found in last estimation."
    exit 198
	}
capture confirm int variable `var`q''
if !_rc {
    graph twoway scatter boolpred `var`q'', title(`gphtitl') ytitle("Pr(`gphdv'=1)") ylabel(0(.2)1) xlabel(`varmin'(1)`varmax')
   }
   else {
    graph twoway mspline boolpred `var`q'', msymbol(none) title(`gphtitl') ytitle("Pr(`gphdv'=1)") ylabel(0(.2)1)
   }

	restore


end

