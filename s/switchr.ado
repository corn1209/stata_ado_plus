* switchr.ado   12/2/97

capture program drop switchr 
program define switchr /* component_equation classification_eq'n options */
  version 5.0
  

  /* Parsing */
  _crceprs `*'
  local weight "pweight nop"
  local options "CLuster(string) STRATA(string) NOISYN(int 16000)"
  local options "`options' ITOUT(int 50) TOL(real 1e-4) SIGEqual" 
  local if "opt"
  local eqnames "$S_1"
  parse "$S_2"
  parse "`eqnames'", parse(" ")
  local wei `exp'
  if "`sigequal'" ~= "" {local sige=1}
  else { local sige=0 }
  set more off

  tempname main2
  local main "`1'"
  eq ? "`main'"
  eq `main2' : "$S_1"
  local depvar : word 1 of $S_1
  global S_mldepn = "`depvar'" + " " + "`depvar'"
  local vars1 : word count $S_1
  local vars2 : word count $S_1
  local regime "`2'"
  eq ? "`regime'"
  global xi : word 1 of $S_1
  
  tempvar touse 
  mark `touse' `if' 
  eq ? "`main'"
  markout `touse' $S_1
  eq ? "`regime'"
  markout `touse' $S_1
  if "`cluster'" ~= "" {
	confirm variable `cluster'
	markout `touse' `cluster', strok
	local clopt "cluster(`cluster')"
	local svyopt = 1
  }

  if "`strata'" ~= "" {
	confirm variable `strata'
	markout `touse' `strata', strok
	local stropt "strata(`strata')"
	local svyopt = 1
  }
  if "`wei'" ~= "" {
	confirm variable `wei'
	markout `touse' `wei'
	local wopt "[pw=`wei']"
  }

  set more off
  di "Here is the regression for the full sample."
  if "`svyopt'" ~="" {
	svyset pweight `wei'
  	svyset psu `cluster'
	svyset strata `strata'
  	eq ? "`main'"
  	svyreg $S_1, subpop("`touse'")
  }
  else {
	eq ? "`main'"
	regress $S_1 `wopt'
  }

  tempname nmainb omainb b1 ob1 b2 ob2 nregb oregb
  mat `nmainb' = get(_b)
  local qqq : colnames(`nmainb')
  mat `b1' = (0)
  mat `b2' = (0)
  mat `nregb' = (0)

  tempvar olam pd1 pd2 lam xb3 w1 w2 wei1 wei2 s1 s11 s2 llvar
  tempvar xb1 xb2 err1 err2 sumw sse1 sse2 sss1 sss2
  tempvar sum1 sw1 we1 ss1 
quietly {
  gen double `xb1' = .
  gen double `xb2' = .
  gen double `err1' = .
  gen double `err2' = .
  gen double `olam' = .
  gen double `pd1' = 1
  gen double `pd2' = 1 
  gen double `lam' = .
  gen double `xb3' = 0
  gen double `w1' = .
  gen double `w2' = .
  gen double `wei1' = .
  gen double `wei2' = .
  gen double `sumw' = .
  gen double `sse1' = .
  gen double `sss1' = .
  gen double `sse2' = .
  gen double `sss2' = .
  gen double `s1' = .
  gen double `s2' = .
  gen double `llvar' = .
  gen double `s11' = .
  gen double `sum1' = .
  gen double `sw1' = .
  gen double `we1' = .
  gen double `ss1' = .
}

  tempname tempr serr bdiff bddn bddo bdds bdiffi
  tempname bdiffs bdiffm 
  local crit = 1
  local iter = 1 
  local isnoi = 0
  local isout = 0 
  local l0 = -1e28
  if `noisyn' == 1 {local isnoi = 1}
  if `itout' == 1 {local isout = 1}
  
  quietly summarize $xi if `touse', detail
  if _result(7)==_result(13) {
	di in r "Sorry, more than 5% of the sample must be in each of the groups."
	error 409
  }
  quietly {
    replace `xb3' = 0.5 if $xi > _result(3)
    replace `xb3' = -0.5 if $xi <= _result(3)
    replace $xi = `xb3'
    replace `xb3' = 0
    local meanxi = _result(3)
  }

  local st = "$S_TIME"

  while `crit' > 0 { 

	local st1 = "$S_TIME"

	/*------The E-Step--------*/

	 quietly {
	  if "`svyopt'" ~= "" {
	    svyset pweight `wei'
	    svyset psu `cluster'
	    svyset strata `strata'
	    if `isnoi' { 
		noi di "Here is the regression for the switching eq'n"
		replace $xi = -$xi
		eq ? "`regime'"
	 	noi svyreg $S_1 , subpop(`touse')
		replace $xi = -$xi
	    }
	    eq ? "`regime'"
	    qui svyreg $S_1 , subpop(`touse')
	  }
	  else {
	    if `isnoi' { 
		noi di "Here is the regression for the switching eq'n"
		replace $xi = -$xi
		eq ? "`regime'"
	 	noi regress $S_1 `wopt'
		replace $xi = -$xi
	    }
	    eq ? "`regime'"
	    qui regress $S_1 `wopt' 
	  }
	  mat `oregb' = `nregb'
  	  mat `nregb' = get(_b)
	  capture drop `xb3'
	  predict double `xb3' , index
	  replace `olam' = `lam'
	  replace `lam' = normprob(-`xb3')
	  replace `w1' = (`lam' * `pd1') / (((1-`lam' ) * `pd2') + (`lam' * `pd1') )
	  replace `w2' = 1 - `w1'
	  replace $xi = `xb3' - (`w1'*normd(-`xb3')/`lam') + /*
	  */ (`w2'*normd(-`xb3')/(1-`lam'))
	  replace `olam' = abs(`olam'-`lam')
	  quietly summarize `olam' if `touse', detail
	  local corr = _result(3)
	  if `isout' {
		noisily di "On iter `iter' the mean absolute change in " _c
		noisily di "the probability vector is : " %7.5f `corr'
	  }
	  summarize `lam' if `touse', detail
	  local meanxi = _result(3)
	  if `isout' {
		noi di "Average of the probability vector  is: " in gr %5.3f `meanxi' 
	  }

 	}

	/*------The M-Step------------*/
	quietly {
	if "`wopt'" ~= "" {replace `wei1' = `w1' * `wei'}
	else { replace `wei1' = `w1' }
  	  if "`svyopt'" ~="" {
		svyset pweight `wei1'
  		svyset psu `cluster'
		svyset strata `strata'
  		eq ? "`main'"
		if `isnoi' { 
		  noi di "First component regression"
		  noi svyreg $S_1, subpop("`touse'") 
		} 
  		else { qui svyreg $S_1, subpop("`touse'") }
 	  }
  	  else {
		local wopt1 = "[pw=`wei1']"
		eq ? "`main'"
		if `isnoi' { 
		  noi di "First component regression"
		  noi regress $S_1 `wopt1' 
		}
		else { qui regress $S_1 `wopt1' }
	  }
  	}

   	quietly {
	  mat `ob1' = `b1'
	  mat `b1'=get(_b)
	  capture drop `xb1'
	  predict double `xb1' , index
	  replace `err1' = `depvar' - `xb1' if `touse'
	  qui summarize `err1' [aw=`w1'], detail
	  local sig1 = sqrt(_result(4))

	  /*  ---  */
	  if "`wopt'" ~= "" {replace `wei2' = `w2' * `wei'}
	  else { replace `wei2' = `w2' }
  	  if "`svyopt'" ~="" {
		svyset pweight `wei2'
  		svyset psu `cluster'
		svyset strata `strata'
  		eq ? "`main'"
		if `isnoi' { 
		  noi di "Second component regression"
		  noi svyreg $S_1, subpop("`touse'") 
		} 
  		else { qui svyreg $S_1, subpop("`touse'") }
 	  }
  	  else {
		local wopt2 "[pw=`wei2']"
		eq ? "`main'"
		if `isnoi' { 
		  noi di "Second component regression"
		  noi regress $S_1 `wopt2' 
		}
		else { qui regress $S_1 `wopt2' }
  	  }

	  mat `ob2' = `b2'
	  mat `b2'=get(_b)
	  capture drop `xb2'
	  predict double `xb2' , index
	  replace `err2' = `depvar' - `xb2' if `touse'
	  summarize `err2' [aw=(`w2')], detail
	  local sig2 = sqrt(_result(4))
	  if `sige' {
	  	replace `sum1' = sum(`w1')
	 	local sw1 = `sum1'[_N]
	  	replace `we1' = `err1'*`w1'*`err1'
		replace `sum1' = sum(`we1')
		local ss1 = `sum1'[_N]
	  	replace `sum1' = sum(`w2')
	 	local sw2 = `sum1'[_N]
	  	replace `we1' = `err2'*`w2'*`err2'
		replace `sum1' = sum(`we1')
		local ss2 = `sum1'[_N]
		local siga = sqrt((`ss1' + `ss2')/(`sw1'+`sw2'))
		local sig1 = `siga'
		local sig2 = `siga'
	  }
	  replace `err1' = `err1' / `sig1'
	  replace `pd1' = normd(`err1') / `sig1'

	  replace `err2' = `err2' / `sig2'
	  replace `pd2' = normd(`err2') / `sig2'

    	}

	/*--------The Test Step-----------*/
	local ll0 = `l0'
	quietly {
	  if `sige' {
		replace `llvar' = 0
		replace `s1' = `siga'
		capture _sw_lik `llvar' `xb1' `xb2' `siga' `xb3'
		if _rc == 0 {
		  replace `s1' = sum(`llvar')
		  local l0 = `s1'[_N]
		}
	  }
	  else {
		replace `llvar' = 0
		replace `s1' = `sig1'
		replace `s2' = `sig2'
		capture _sw_lik2 `llvar' `xb1' `xb2' `sig1' `sig2' `xb3'
		if _rc == 0 {
		  replace `s1' = sum(`llvar')
		  local l0 = `s1'[_N]
		}
	  }
/*
	  if (`l0' < `ll0') & (`meanxi' < 0.92) & (`meanxi' > 0.08) {
		local tt= real(substr("$S_TIME",1,2)) + real(substr("$S_TIME",4,2))*60 /*
			*/ + real(substr("$S_TIME",7,2))
		local tt = string(`tt')
		local cv = "cv" + "`tt'"
		di "The log-likelihood is `l0' and decreasing.  Saving current"
		di "    classification vector as  `cv' "
		tempfile scratch
		save `scratch', replace
		replace $xi = `lam' 
		keep hhid $xi
		save `cv' , replace
		use `scratch' , replace
	  }
*/
	  global S_E_ll = `l0'
	}
	if `iter' == 1 {
		di in gr "(Reporting of crit for first iteration skipped)"
	}
	else if `crit' == 3 { local crit = -1 }
	else {
		local isnoi = 0
		mat `nmainb' = `b1' , `b2'
		mat `omainb' = `ob1' , `ob2'
		mat `bdiff' = (0) 
		mat `bddn' = `nmainb' /*, `nregb'*/
		mat `bddo' = `omainb' /*, `oregb' */
		local i = 1 
		local bdeq "first main "
		mat `bdiffi' = `bddn' - `bddo'
		mat `bdiffs' = `bdiffi'
		while `i' <= colsof( `bddo' ) { 
			mat `bdiffi'[1,`i'] = abs(`bdiffi'[1,`i'])
			if `bddo'[1,`i'] ~= 0 {
			  mat `bdiffi'[1,`i'] = `bdiffi'[1,`i'] / `bddo'[1,`i']
			}
			else { mat `bdiffi'[1,`i'] = 0 }
			if (`bdiffi'[1,`i'] ~= . ) & (`bdiff'[1,1] < `bdiffi'[1,`i']) {
				mat `bdiff'[1,1] = `bdiffi'[1,`i']
				local si = sign(`bdiffs'[1,`i'])
				* bdiff is the reigning leader -- bdiffm is 
				*     just a place-holder
				mat `bdiffm' = `bdiffi'[1,`i']
				local qqq : colnames(`bdiffm')
				mat colnames `bdiff' = `qqq'
				if (`i' > `vars1') & (`i' <= `vars1' + `vars2') {
					local bdeq "second main "
				}
				else if `i' > (`vars1' + `vars2' ) {
					local bdeq "classification "
				}
			}
			local i = `i' + 1 
		} 
		if `isout' {
		  local bdf = `si' * `bdiff'[1,1]
		  local bdn : colnames(`bdiff')
		  di in gr "On iteration " in wh %1.0f `iter' in 	/*
		  */ gr " greatest diff is: " in wh %8.6f `bdf' 	/*
		  */ " on `bdn' in the" in bl " `bdeq'" in wh "eqn"
		  di in gr "Log-likelihood is : " `l0'
		}
		* The convergence criteria is that no coefficient
		* should have changed by more than tol
		if (`bdiff'[1,1] < `tol') {
			local crit = 3
			local isnoi = 1
			di in bl "Done ..." in wh "Here are the " _c
			di in wh "probabilities of being in the first " _c
			di in wh "component regression...."
			summarize `lam' if `touse', detail
			di in y "Final Results Follow"
		}
	}

	if int(`iter'/`itout') == (`iter'/`itout') {
	  local oper "This iteration"
	  elapse "`st1'" "`oper'"
	  di _newline(1)
	}

  	local iter = `iter' + 1
  	local isout = (int(`iter'/`itout') == (`iter'/`itout')) + `isnoi'
  	local isnoi = (int(`iter'/`noisyn') == /* 
		*/ (`iter'/`noisyn')) + `isnoi'


} /* end of outer loop */

replace $xi = `lam'
local oper "This Switching Regression"
elapse "`st'" "`oper'"

end 
