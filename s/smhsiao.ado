*! NJGW 1.1.0 17 Dec 1999
*! Program to calculate Small-Hsiao test of IIA
*! Nicholas Winter (nwinter@umich.edu)
program define smhsiao

	version 6.0
	syntax varlist [if] [in] [fw pw iw], /*
		*/ Elim(real) [ Samp(varname) Basecategory(string) Quietly Detail * ]
	marksample touse
	local y : word 1 of `varlist'						/* get DV & dof for test*/
	local nvar : word count of `varlist'
	local dof = `nvar'-1

	if "`quietly'"=="quietly" {
		local shh2 "quietly"
	}
	if "`detail'"=="" {
		local shh "quietly"
	}

	if "`weight'"!="" {
		local weight "[`weight'`exp']"
	}

	tempname Vals Counts							/* get values of DV */
	qui tab `y' if `touse', matrow(`Vals') matcell(`Counts')
	local nvals = r(r)
	local i = 1
	while `i' <= `nvals' {
		local Yval`i' = `Vals'[`i',1]
		local Yvals "`Yvals' `Yval`i''"
		if `elim'==`Yval`i'' {
			local ielim `i'
		}
		local i = `i' + 1
	}

	if "`ielim'"=="" {
		di in r "`y' does not take on value `elim' in estimation sample"
		error 198
	}

	if "`basecat'"=="" {
		local xm 0
		local i 1
		while `i'<=`nvals' {
			local x = `Counts'[`i',1]
			if `x'>`xm' {
				local xm `x'
				local Yxm = `Vals'[`i',1]			/* value of y for most freq */
			}
			local i=`i'+1
		}
		local basecat `Yxm'
	}
	local bcat "b(`basecat')"

	qui tab `y' if `touse' & `y'!=`elim', matrow(`Vals')	/* get values of DV, minus elim */
	local nEvals = r(r)
	local i = 1
	while `i' <= `nEvals' {
		local EYval`i' = `Vals'[`i',1]
		local EYvals "`EYvals' `EYval`i''"
		local i = `i' + 1
	}

	local Ylab : val lab `y'
	if "`Ylab'"=="" {
		tempname junk
		local Ylab "`junk'"
	}
	local i 1
	while `i'<=`nvals' {
		local Ylab`i' : lab `Ylab' `Yval`i''
		local i=`i'+1
	}


	tempvar lnL denom
	tempname b0a b0b b0ab b1b

	if "`samp'"=="" {
		tempvar samp
		qui gen `samp'=round(uniform(),1)+1 if `touse'
		local samp1 1
		local samp2 2
	}
	else {
		tempname SVal
		qui ta `samp' if `touse', matrow(`SVal')
		if `r(r)' != 2 {
			di in r "samp() variable must take exactly two values in the estimation sample"
			error 198
		}
		local samp1 = `SVal'[1,1]
		local samp2 = `SVal'[2,1]
	}

	qui ta `y' if `touse' & `samp'==`samp1'
	local cat1 `r(r)'
	if `cat1'!=`nvals' {
		di in r "`y' is missing categories in the first half sample"
		error 148
	}
	qui ta `y' if `touse' & `samp'==`samp2'
	local cat2 `r(r)'
	if `cat2'!=`nvals' {
		di in r "`y' is missing categories in the second half sample"
		error 148
	}

	`shh2' mlogit `varlist' `if' `in' `weight', b(`basecat') `options'

	`shh' di "Estimating first-half sample model:"
	`shh' mlogit `varlist' if `touse' & `samp'==`samp1' `weight', b(`basecat') `options'
	mat `b0a' = e(b)
	`shh' di
	`shh' di "Estimating second-half sample model:"
	`shh' mlogit `varlist' if `touse' & `samp'==`samp2' `weight', b(`basecat') `options'
	mat `b0b' = e(b)
	mat `b0ab' = (0.70710678)*(`b0a') + (0.29289322)*(`b0b')		/* Zhang & Hoffman eq. 9 */


*************************************
*Get LnL for amalgamated coefficients
*************************************
*get XBs & assemble denominator

	qui gen double `denom' = 0 if `touse'
	local i 1
	while `i' <= `nEvals' {   				/* cycle through values (w/o eliminated one) */
		local cury : word `i' of `EYvals'
		tempvar xb`cury'
		if `cury' != `basecat' {
			matrix score double `xb`cury'' = `b0ab' if `touse', eq(`Ylab`cury'')
		}
		else {
			qui gen double `xb`cury''=0				/* because (exp(0)=1) */
		}
		qui replace `denom'=`denom' + exp(`xb`cury'') if `touse'
		local i=`i'+1
	}

*create Log likelihood using amalgamated coeff.
	qui gen double `lnL' = . if `touse'
	local i 1
	while `i'<=`nEvals' {
		local cury : word `i' of `EYvals'
		qui replace `lnL' = ln(exp(`xb`cury'')/(`denom')) if `y'==`cury' & `touse'
		local i=`i'+1
	}

* GET LnL, only for observations in the 2d sample, and without eliminated observations:
	sum `lnL' if `touse' & `samp'==`samp2' & `y'!=`elim', meanonly
	local lnL_0 = r(sum)

* Now get b1b: coefficients from restricted choice set
	`shh' di
	`shh' di "Estimating coefficients in second sample without `y'==`elim'"
	`shh' mlogit `varlist' if (`touse' & `samp'==`samp2' & `y'!=`elim') `weight', `options'
	local lnL_1 = e(ll)

	local SH = -2 * (`lnL_0' - `lnL_1')
	local p = chiprob(`dof',`SH')

	di 
	di in g "Small-Hsiao Test of IIA"
	di in g "-----------------------"
	di 
	di in g "  LnL for weighted average of coeffients in two half-samples: " in y %6.5f `lnL_0'
	di in g "  LnL based on restricted model (`y'==`elim' omitted): " _col(63) in y %6.5f `lnL_1'
	di in g "  Test chi2(`dof') = " in y %6.3f `SH' in g ", Pr = " in y %5.4f `p'

end

*end&
