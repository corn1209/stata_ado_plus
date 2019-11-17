capture program drop mlboolpred
program define mlboolpred
version 8
	local j = 1
	local path "$feed"
	foreach k of numlist 1000 1001 1002 1/$n {
	   gettoken path`k' path : path, match(holder)
	   }
	
	forvalues i = 1/$n {
	   local theta`i'= 0
	   }

	forvalues i = 1/$n {	
		while "`path`i''" ~= "" {
			gettoken var path`i' : path`i', match(holder)
			local theta`i' "`theta`i'' + b[1,`j']*`var'"
			local j = `j' + 1
			}
		local theta`i' "`theta`i'' + b[1,`j']"
		local j = `j' + 1
		}	

	if "$typepl" == "logit" {
	   forvalues i = 1/$n {
	      quietly gen double PathProb`i' = (1/(1+exp(-1*(`theta`i''))))
          }
       }

	if "$typepl" == "probit" {
	   forvalues i = 1/$n {
	      quietly gen double PathProb`i' = normprob(`theta`i'')
	      }
       }

	local kiss "$keys"

	forvalues i = 1/$n {
	   local kiss = subinstr("`kiss'","ps`i'","PathProb`i'",.)
       }
	gen double boolpred = `kiss'

	local k = 0
	
end

