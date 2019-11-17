*! NJC 1.5.1 13 October 1999 

program def mdensity, rclass
    version 6.0
    syntax varlist [if] [in] [fw aw], [ AT(varname) N(integer 50) /* 
    */ BY(varname) MISSing Width(numlist >=0) Range(numlist asc min=2 max=2) /*
    */ LOG LOGIT a(real 0) b(real 1) Zero BIweight COSine EPan GAUss /* 
    */ RECtangle PARzen TRIangle L1title(str) Intensity * ]  
       
    tokenize `varlist'
    local nvars : word count `varlist'
    
    if "`by'" != "" & `nvars' > 1 {
        di in r "too many variables specified"
        exit 103
    }

    if "`log'" != "" & "`logit'" != "" {
    	di in r "must specify only one of log and logit"
	exit 198
    } 	
 
    if "`width'" == "" { local width 0 }
    local nw : word count `width' 
  
    tempvar touse 
    mark `touse' `if' `in' 
    if "`missing'" == "" {
        if "`by'" != "" { markout `touse' `by', strok }
    }
    else {
        if "`by'" == "" { di in bl "missing only applies with by( )" }
    }

    if "`at'" == "" { 
    	if "`range'" != "" { 
	    local min : word 1 of `range' 
	    local max : word 2 of `range' 
	}
	else { 
    	    su `1' if `touse', meanonly 
	    local min = r(min) 
	    local max = r(max) 
    	    local i = 2 
	    while `i' <= `nvars' { 
		su ``i'' if `touse', meanonly  
		local min = min(`min',r(min)) 
		local max = max(`max',r(max)) 
		local i = `i' + 1 
	    }  
	}     
        tempvar at
	if `n' <= 1 { local n = 50 } 
	if `n' > _N { 
	    local n = _N 
	    di in g "n( ) set to `n'" 
	}	
	qui range `at' `min' `max' `n' 
	if `nvars' == 1 { _crcslbl `at' `1' } 
	else label var `at' "`varlist'" 
    } 

    if "`log'" != "" {
    	tempvar logat 
	qui gen `logat' = log(`at')
	local what "`logat'" 
    }
    else if "`logit'" != "" { 
    	tempvar logitat 
	qui gen `logitat' = log((`at' -`a')/(`b' - `at')) 
	local what `logitat' 
	local numer = `b' - `a' 
    } 	
    else local what "`at'" 
 
    if "`by'" == "" { /* no `by' option */
    	if `nw' < `nvars' { 
	    if `nw' == 1 { local width : di _dup(`nvars') "`width' " }
            else { 
	        local nextra = `nvars' - `nw' 
	        local extra : di _dup(`nextra') " 0" 
	        local width "`width'`extra'" 
	    }
	}    

        local i 1
        qui while `i' <= `nvars' {
            tempvar d`i'
	    if "`log'" != "" { 
	    	tempvar log`i'  
		gen `log`i'' = log(``i'') 
		local which "`log`i''"
	    }
	    else if "`logit'" != "" {
	    	tempvar logit`i' 
		gen `logit`i'' = log((``i'' - `a')/(`b' - ``i'')) 
		local which "`logit`i''" 
	    }	
	    else local which "``i''" 
            local w : word `i' of `width' 
	    kdensity `which' if `touse' [`weight' `exp'], /*
        */ `biweight' `cosine' `epan' `gauss' `rectangle' `parzen' /* 
	*/ `triangle' width(`w') nograph gen(`d`i'') at(`what')
	    local widths "`widths'`r(width)' " 
	    local ns "`ns'`r(n)' " 
	    local scales "`scales'`r(scale)' "
	    if "`log'" != "" { replace `d`i'' = `d`i'' / `at' }
	    else if "`logit'" != "" { 
	        replace `d`i'' = (`d`i'' * `numer') / ((`at' - `a') * (`b' - `at')) 
	    }	
	    if "`intensity'" != "" { 
	        count if `touse' & `which' < . 
	        replace `d`i'' = `d`i'' *  r(N) 
	    } 
	    if "`zero'" == "" { replace `d`i'' = . if `d`i'' == 0 }
	    _crcslbl `d`i'' ``i''
            local dlist "`dlist'`d`i'' "
            local i = `i' + 1
        }

        if `"`l1title'"' == `""' {
            if `nvars' == 1 { 
	        local l1title : variable label `varlist' 
		if `"`l1title'"' == `""' { local l1title "`varlist'" }
		if "`intensity'" != "" { 
			local l1title `"Intensity of `l1title'"'
		}	
		else local l1title `"Density of `l1title'"'     
	    }		
            else if length("`varlist'") < 25 {
	    	if "`intensity'" != "" { 
			local l1title `"Intensity of `varlist'"' 
		}	
                else local l1title "Density of `varlist'"
            }
            else if "`intensity'" != "" { 
	    	local l1title "Intensity" 
	    }	
	    else local l1title "Density" 
        }
    }

    else { /* by( ) */
    	tempvar group 
        sort `touse' `by'
        qui by `touse' `by': gen byte `group' = _n == 1 if `touse'
        qui replace `group' = sum(`group')
        local ng = `group'[_N]
        local bylab : value label `by'
        local vallab : value label `varlist'
	
	if `nw' < `ng' { 
	    if `nw' == 1 { local width : di _dup(`ng') "`width' " }
            else { 
		local nextra = `ng' - `nw' 
		local extra : di _dup(`nextra') " 0" 
		local width "`width'`extra'" 
            }
	}   
	
	if "`log'" != "" { 
	    	tempvar logvar  
		qui gen `logvar' = log(`varlist') 
		local which "`logvar'"
        }
	else if "`logit'" != "" { 
		tempvar lgtvar 
		qui gen `lgtvar' = log((`varlist' - `a')/(`b' - `varlist'))
		local which "`lgtvar'" 
	}	
        else local which "`varlist'" 

        local i 1
        qui count if !`touse'
        local j = 1 + r(N)
        qui while `i' <= `ng' {
            tempvar d`i'     
	    local w : word `i' of `width' 
	    kdensity `which' if `group' == `i' [`weight' `exp'] , /*
        */ `biweight' `cosine' `epan' `gauss' `rectangle' `parzen' /* 
	*/ `triangle' width(`w') nograph gen(`d`i'') at(`what')
            local widths "`widths'`r(width)' " 	
	    local ns "`ns'`r(n)' " 
	    local scales "`scales'`r(scale)' " 
	    sort `touse' `by' /* -kdensity- 2.3.3 often resorts */ 
	    if "`log'" != "" { replace `d`i'' = `d`i'' / `at' }
            else if "`logit'" != "" { 
	        replace `d`i'' = (`d`i'' * `numer') / ((`at' - `a') * (`b' - `at')) 
	    }
	    count if `group' == `i' 
	    local n = r(N) 
	    if "`intensity'" != "" { replace `d`i'' = `d`i'' * `n' } 
	    if "`zero'" == "" { replace `d`i'' = . if `d`i'' == 0 }
            local dlist "`dlist' `d`i''"
            local byval = `by'[`j']
            if "`bylab'" != "" { local byval : label `bylab' `byval' }
            label var `d`i'' `"`byval'"'
            if "`vallab'" != "" { label val `d`i'' `vallab' }
            local j = `j' + `n'
            local i = `i' + 1
        }

        if `"`l1title'"' == `""' {
            local l1title : variable label `varlist'
            if `"`l1title'"' == `""' { local l1title "`varlist'" }
            if length(`"`l1title'"') < 25 {
	    	if "`intensity'" != "" { 
		    local l1title `"Intensity of `l1title'"' 
		} 
                else local l1title `"Density of `l1title'"'
            }
	    else if "`intensity'" != "" { local l1title "Intensity" } 
	    else local l1title "Density" 
        }
   }

   gra `dlist' `at' , l1(`"`l1title'"') `options' 
   local widths = trim("`widths'")
   local ns = trim("`ns'")
   local scales = trim("`scales'")
   return local widths "`widths'" 	
   return local ns "`ns'" 
   return local scales "`scales'" 
end
   
