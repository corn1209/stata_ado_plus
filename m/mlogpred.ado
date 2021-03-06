*! version 1.0.0  18sep1998
program define mlogpred
/*
   Syntax:

   	mlogpred newvarname1 [newvarname2] [if] [in]

		[, Prob SE CI Equation(#) Outcome(#) Level(#) ]

   works after -mlogit- and -svymlog-.
*/
	version 5.0
	if "$S_E_cmd"!="mlogit" & "$S_E_cmd"!="svymlog" {
		error 301
	}

/* Parse. */

	local varlist "req new max(2)"
	local if "opt"
	local in "opt"
	local options /*
*/ "Prob CI SE Equation(string) Outcome(string) Level(int $S_level)"

	nobreak {
		capture noisily break {
			parse "`*'"
			local var1 : word 1 of `varlist'
			local var2 : word 2 of `varlist'
			local type : type `var1'
		}
		local rc = _rc
		cap drop `var1'
		cap drop `var2'
		if `rc' { exit `rc' }
	}

/* Check syntax. */


	if "`prob'`ci'`se'"=="" {
		local prob "prob"
		di in blu "predicted probabilities calculated by default"
	}

	local nopts : word count `prob' `se' `ci'
	if `nopts' > 1 {
		di in red "only one of prob, se, or ci can be specified"
		exit 198
	}
	if "`ci'"=="" {
		if "`var2'"!="" {
			di in red "only one variable can be specified with " /*
			*/ "`prob'`se' option"
			exit 103
		}
	}
	else { /* ci */
		if "`var2'"=="" {
			di in red "two variables must be specified for ci"
			exit 102
		}
		if `level' < 10 | `level' > 99 {
			di in red "level() must be between 10 and 99 inclusive"
			exit 198
		}
	}
	if "`equatio'"!="" & "`outcome'"!="" {
		di in red "only one of equation() or outcome() can be specified"
		exit 198
	}
	if "`equatio'"!="" {
		local eqi "eq(`equatio')"
	}
	else if "`outcome'"!="" {
		local eqi "out(`outcome')"
		local equatio "`outcome'"
	}
	else {
		di in blu "equation() or outcome() not specified; "  /*
		*/ "first equation assumed"
		local eqi "eq(#1)"
	}

/* Mark. */

	tempvar doit den xb
	mark `doit' `if' `in'

/* Get number of equations. */

	if "$S_E_cmd"=="mlogit" {
		tempname b
		mat `b' = get(_b)
		local neq = rowsof(`b')
	}
	else	local neq = $S_E_ncat - 1

	quietly {

	/* Compute denominator `den' = 1 + Sum(exp(`xb')). */

		gen double `den' = 1 if `doit'
		local i 1
		while `i' <= `neq' {
			predict double `xb' if `doit', eq(#`i') index
			replace `den' = `den' + exp(`xb')
			drop `xb'
			local i = `i' + 1
		}

	/* Compute probability of selected category. */

		if "$S_E_cmd"=="mlogit" {
			predict double `xb' if `doit', `eqi' index
		}
		else {
			if trim("`equatio'")==trim("$S_E_base") {
				local xb 0
			}
			else predict double `xb' if `doit', `eqi' index
		}

		if "`prob'"!="" {
			noi gen `type' `var1' = exp(`xb')/`den'
			exit
		}

		tempvar p dPi dPj Vij Vp

		gen double `p' = exp(`xb')/`den'
		cap drop `xb'

	/* Compute variance of `p'. */

		tempname V
		mat `V' = get(VCE)

		gen double `Vp' = 0 if `doit'
		local i 1
		while `i' <= `neq' {
			dPdI `dPi' `i' `p' `den' `doit'
			local j `i'
			while `j' <= `neq' {
				Vindex `Vij' `i' `j' `neq' `V' `doit'

				if `j' == `i' {
					replace `Vp' = `Vp' + `Vij'*`dPi'^2
				}
				else {
					dPdI `dPj' `j' `p' `den' `doit'
					replace `Vp' = `Vp' /*
					*/ + 2*`dPi'*`Vij'*`dPj'
					drop `dPj'
				}
				drop `Vij'
				local j = `j' + 1
			}
			drop `dPi'
			local i = `i' + 1
		}

		if "`se'"!="" {
			noi gen `type' `var1' = sqrt(`Vp')
			exit
		}

	/* Compute confidence interval. */

		tempname z

		if "$S_E_cmd"=="mlogit" {
			scalar `z' = invnorm((100+`level')/200)
		}
		else	scalar `z' = invt($S_E_npsu-$S_E_nstr,`level'/100)

		gen `type' `var1' = 1/(1 + exp(-( log(`p'/(1-`p')) /*
		*/ - `z'*sqrt(`Vp')/(`p'*(1-`p')) )))

		noi gen `type' `var2' = 1/(1 + exp(-( log(`p'/(1-`p')) /*
		*/ + `z'*sqrt(`Vp')/(`p'*(1-`p')) )))
	}
end

program define dPdI
	local dPi  "`1'" /* Output: variable containing dP/dI        */
	local i    "`2'" /* Input:  equation number                  */
	local p    "`3'" /* Input:  probability of selected category */
	local den  "`4'" /* Input:  denominator for probabilities    */
	local doit "`5'" /* Input:  markvar                          */

	quietly {
		predict double `dPi' if `doit', eq(#`i') index
		replace `dPi' = exp(`dPi')/`den'

		cap assert reldif(`dPi',`p') < 1e-14
		if _rc {
			replace `dPi' = -`p'*`dPi'
		}
		else	replace `dPi' = `p'*(1 - `p')
	}
end

program define Vindex
	local Vij  "`1'" /* Output: covariance wrt indices i and j */
	local i    "`2'" /* Input:  equation number                */
	local j    "`3'" /* Input:  equation number                */
	local neq  "`4'" /* Input:  number of equations            */
	local V    "`5'" /* Input:  covariance matrix              */
	local doit "`6'" /* Input:  markvar                        */

	local nx = colsof(`V')/`neq'
	local row1 = `nx'*(`i' - 1) + 1
	local row2 = `nx'*`i'
	local col1 = `nx'*(`j' - 1) + 1
	local col2 = `nx'*`j'

	tempname Vsub
	mat `Vsub' = `V'[`row1'..`row2',`col1'..`col2']
	xVx `Vij' `Vsub' `doit'
end

program define xVx
	local xVx  "`1'"  /* Output: variable containing x'Vx */
	local V    "`2'"  /* Input:  matrix                   */
	local doit "`3'"  /* Input:  markvar                  */
	tempname Vrow
	tempvar Vx
	quietly {
		gen double `xVx' = 0 if `doit'
		local names : colnames(`V')
		parse "`names'", parse(" ")
		local dim = colsof(`V')
		local i 1
		while `i' <= `dim' {
			mat `Vrow' = `V'[`i',1...]
			mat score double `Vx' = `Vrow' if `doit'

			if "``i''"=="_cons" {
				replace `xVx' = `xVx' + `Vx'
			}
			else	replace `xVx' = `xVx' + ``i''*`Vx'

			drop `Vx'
			local i = `i' + 1
		}
	}
end

exit
