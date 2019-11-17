*! catgraph 1.3.0 NJGW 4/23/2001
*! Program to plot means by category
* Version 1.3.0 added ability to specify statistics

program define catgraph
	version 7.0

	syntax varlist(min=2 max=2) [if] [in] , [ by(varlist min=1 max=1)  stat(string) * ]

	local xvar : word 1 of `varlist'
	local catvar : word 2 of `varlist'

	if "`by'"=="" {
		tempvar by
		qui gen `by'=1
		local userby 0
	}
	else {
		local userby 1
	}
	
	if `"`stat'"'!="" {
		local stat (`stat')
	}

	local bytype : type `by'
	if substr("`bytype'",1,3)=="str" {
		tempvar numby
		encode `by', gen(`numby')
		local by `numby'
	}
		
	preserve
	
	if `"`if'`in'"'!="" {
		qui keep `if' `in'
	}
	
	qui drop if `by'==. 
	
	collapse `stat' `xvar' , by(`catvar' `by') fast
	tempname byvals
	
	qui ta `by', matrow(`byvals')
	local bynum `r(r)'
	local bylab : val lab `by'
	if `userby' {
		forval i=1(1)`bynum' {
			local val`i'=`byvals'[`i',1]
			if "`bylab'"!="" {
				local byname`i' : label (`by') `val`i''
			}
			else {
				local byname`i' `"`by'==`val`i''"'
			}
		}
	}

	qui reshape wide `xvar' , i(`catvar') j(`by') 

	forval i=1(1)`bynum' {
			la var `xvar'`val`i'' `"`byname`i''"'
	}

	capture textgph `xvar'* `catvar', `options'
	if _rc {
		gr `xvar'* `catvar', `options'
	}

end

*end&

