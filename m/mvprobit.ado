*! version 1.0.0  15jan2003  Cappellari & Jenkins            (SJ3-3:st0045)
*! Multivariate probit by method of SML.  

program define mvprobit, eclass byable(onecall)
	version 7.0
	if replay() {
		if "`e(cmd)'" != "mvprobit" {
			noi di in red "results for mvprobit not found"
			exit 301
		}
		if _by() { 
			error 190 
		} 
		Display `0'
		exit `rc'
	}
	if _by() {
		by `_byvars'`_byrc0': Estimate `0'
	}
	else	Estimate `0'
end

program define Estimate, eclass byable(recall)

		/* First parse the equation stuff into constituent 
		   components and thereby get the number of equations.
		   Much code hacked from -biprobit- (with references 
		   to -offset- and -score- deleted).
		*/

	local i = 1
	local paren "("

	while "`paren'" == "(" {    
		gettoken e`i' 0:0, parse(" ,[") match(paren)
		local left "`0'"
		local junk: subinstr local e`i' ":" ":", count(local number)
		if "`number'" == "1" {
			gettoken dep`i'n  e`i':  e`i', parse(":")
			gettoken junk  e`i':  e`i', parse(":")
		}
		local  e`i' : subinstr local  e`i' "=" " "
		gettoken dep`i' 0:  e`i', parse(" ,[") 
		unab dep`i': `dep`i'' 

			/* collecting together -- for e.g. marking sample */
		local deps "`deps' `dep`i''"
		confirm variable `dep`i''
		if "`dep`i'n'" == "" {
			local dep`i'n "`dep`i''"
		}
		syntax [varlist(default=none)] [, noCONstant]
		local ind`i' `varlist'        
		local ninds`i' : word count `ind`i''
		if "`constant'" == "" {
			local ninds`i' = `ninds`i'' + 1
		}
		local inds "`inds' `ind`i''"
		local nc`i' `constant'
		local  0 "`left'"
				/* reset `paren' to empty when thru eqns */
		gettoken check : left, parse(" ,[") match(paren)
		local i = `i' + 1
	}

			/* Ensure globals used later are already clear */
			/* Using horrible prefix reduces chance of overwriting */
	foreach g in S_MLE_C S_MLE_I S_MLE_tvar S_MLE_rho S_MLE_atrho S_MLE_slatrho S_MLE_eqs { 
	        global `g' 
	} 
	capture macro drop S_MLE_z*


			/* number of equations */
	local neq = `i'-1  
	global S_MLE_M "`neq'"   

	if $S_MLE_M < 1 { 
		di in red "equation(s) required" 
		exit 198
	}

			/* remaining options in command line */
	local 0 "`left'"
	syntax [if] [in] [pw fw iw] [, DRaws(integer 5)  Robust Cluster(varname)    /*
		*/ Level(integer $S_level) Beta0  Seed(integer 123456789)    /*
		*/ Atrho0(string) noLOG MLOpts(string) * ]

	global S_MLE_D  "`draws'"
	local title "Multivariate probit (SML, # draws = $S_MLE_D)"
	set seed `seed'

	local option0 `options'
	marksample touse
	markout `touse' `deps' `inds'   

	local wtype `weight'
	local wtexp `"`exp'"'
	if "`weight'" != "" { 
		local wgt `"[`weight'`exp']"'  
	}
	if "`weight'" == "pweight" | "`cluster'" != "" {
	        local robust "robust"
	}

	if "`cluster'" ! = "" { 
		local clopt "cluster(`cluster')" 
	}
	mlopts stdopts, `option0'

	if "`level'" != "" {
		local level "level(`level')"
	}
		

	if "`log'" == "" {
                local log "noisily"
        }
        else   {
		 local log "quietly"
	}

	local log2 = cond("`beta0'" == "", "quietly", "noisily")


				/*  Checking of depvars etc. */
	quietly {
		count if `touse' 
		if r(N) == 0 { 
			di in red "no valid observations"
		   	error 2000
		}
		local N = r(N)
		foreach var of local deps {
			capture assert (`var' == 1 | `var' == 0) if `touse'
				if _rc==9 {
					di in red "depvar `var' should be binary (0 or 1)"
					exit 450
				}	
			count if `var' == 0 & `touse'
			local d0 = r(N)
			if `d0' == 0 {
				di in red "`var' is never zero"
				exit 2000
			}
			else if `d0' == `N' {
				di in red "`var' is always zero"
				exit 2000 
			}
		}
	}

	tempname C
	global S_MLE_C "`C'"  /* used for matrix name in evaluation program */

			/* draws -> vbles for Cholesky decomposition */
			/* check collinearities among RHS vbles */
			/* starting values from marginal univariate probits */
			/* create macros containing bits of syntax for -ml- */
		
	tempname b0    

	forval i = 1/$S_MLE_M {
		forval d = 1/$S_MLE_D {
			tempvar z
			draws `z' `touse'
			global S_MLE_z`i'`d' "`z'"
		}
 
		_rmcoll `ind`i'' `wgt' if `touse', `nc`i''
		local ind`i' "`r(varlist)'"
		`log2'  probit `dep`i'' `ind`i'' `wgt' if `touse', `nc`i'' nolog

		tempname beta`i'
		mat `beta`i'' = e(b)
		mat coleq `beta`i'' = `dep`i'n'
		if `i' == 1 {
			mat `b0' = `beta`i''
			local ll0 = e(ll)
		}
		if `i' > 1  {
			mat `b0' = `b0', `beta`i''
			local ll0 = e(ll) + `ll0'   /* logL for comparison model */
		}

		global S_MLE_eqs "$S_MLE_eqs (`dep`i'n': `dep`i'' = `ind`i'', `nc`i'') "
		global S_MLE_I "$S_MLE_I S_MLE_I`i'"
		global S_MLE_tvar "$S_MLE_tvar k`i' d`i' sp`i' arg`i'"

		local jj = `i'+1
		forval j = `jj'/$S_MLE_M { 
			global S_MLE_rho "$S_MLE_rho rho`j'`i' ="
			global S_MLE_atrho "$S_MLE_atrho atrho`j'`i'"
			global S_MLE_slatrho "$S_MLE_slatrho /atrho`j'`i'"
		}
	}

	if "`atrho0'" != "" {
		matrix `b0' = `b0', `atrho0'
	}

	`log' ml model lf mvprob_ll $S_MLE_eqs $S_MLE_slatrho `wgt' if `touse', maximize /*
		*/ collinear wald(-$S_MLE_M) init(`b0') title(`title') `robust' /*
		*/ search(off) `clopt' `level' `mlopts' `stdopts'

	estimate scalar neqs = $S_MLE_M
	estimate scalar draws = $S_MLE_D
	estimate scalar seed = `seed'
	estimate scalar ll0 = `ll0'
	estimate scalar chi2_c = abs(-2*(e(ll0)-e(ll)))
	estimate scalar nrho = (e(neqs)-1)*e(neqs)/2

	estimate local cmd "mvprobit"

	forval i = 1/$S_MLE_M {
		est local rhs`i' "`ind`i''"
		est local nrhs`i' "`ninds`i''"
		local jj = `i'+1
		forval j = `jj'/$S_MLE_M { 
			local t = [atrho`j'`i']_b[_cons]
			local tse = [atrho`j'`i']_se[_cons]
			est scalar rho`j'`i' = 	(exp(2*`t')-1)/(exp(2*`t')+1)	
			est scalar serho`j'`i' = `tse'*4*(exp(2*`t'))/(exp(2*`t')+1)^2
		}
	}

	Display, `level' 

	if $S_MLE_M > 1 {
					/* LR test of models without & without rhos */
		di in gr "Likelihood ratio test of $S_MLE_rho 0:  " 
		di in gr "             chi2(" in ye "`e(nrho)'" in gr ") = " /*
			*/ in ye %8.0g e(chi2_c) _c
		di in gr "   Prob > chi2 = " in ye %6.4f /*
			*/ chiprob(`e(nrho)', e(chi2_c))
	}

					/* clear up globals no longer needed */
	foreach g in S_MLE_C S_MLE_I S_MLE_tvar S_MLE_rho S_MLE_atrho S_MLE_slatrho  { 
	        global `g' 
	} 
	capture macro drop S_MLE_z*
end


program define Display
	syntax [,Level(int $S_level)]
	ml di, level(`level') neq($S_MLE_M) plus

	forval i = 1/$S_MLE_M {
		local jj = `i'+1
		forval j = `jj'/$S_MLE_M { 
			DispA atrho`j'`i' `level'			
		}
	}
	forval i = 1/$S_MLE_M {
		local jj = `i'+1
		forval j = `jj'/$S_MLE_M { 
			if (`j' < $S_MLE_M) | (`j' == $S_MLE_M & `i' < `j'-1) {
				DispB atrho`j'`i' rho`j'`i' `level'			
			}
			else  {
				DispC atrho`j'`i' rho`j'`i' `level'			
			}
		}
	}
end


program define DispA
	local level = `2'
	_diparm `1', level(`level') prob
	di in smcl in gr "{hline 13}{c +}{hline 64}"
end


program define DispB
	local level = `3'
	_diparm `1', level(`level') tanh label("`2'") prob
	di in smcl in gr "{hline 13}{c +}{hline 64}"
end


program define DispC
	local level = `3'
	_diparm `1', level(`level') tanh label("`2'") prob
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
end


program define draws
	quietly gen `1' = uniform() if `2'
end


