*! version 1.1.2  24mar1998        statalist distribution
*  tobit with full and conditioned marginal effects.
program define dtobit2
	version 4.0
	local varlist	"req ex"
	local if	"opt"
	local in	"opt"
	local weight	"aweight fweight" 
	local options	"LL(string) UL(string)"
	parse "`*'"

	if "`ll'" == "" & "`ul'" == "" {
		noi di in red "must specify ll() or ul()"
		exit 198
	}
	if "`ll'" != "" {
		confirm number `ll'
		local opt "ll(`ll')"
	}
	if "`ul'" != "" {
		confirm number `ul'
		local opt "`opt' ul(`ul')"
	}
	tobit `varlist' `if' `in' [`weight'`exp'], `opt'
	local nobs = _result(1)
	if `nobs' == 0  | `nobs' == . {
		exit 
	}
	tempvar touse
	mark `touse' `if' `in' [`weight'`exp']
	markout `touse' `varlist' 
	quietly {
		tempname sigma b
		scalar `sigma' = _b[_se]
		mat `b' = get(_b)
		local cens = 0
		if "`ll'" != "" {
			count if $S_E_depv <= `ll'  & `touse' 
			local cens = _result(1)
		}
		if "`ul'" != "" {
			count if $S_E_depv >= `ul'  & `touse' 
			local cens = _result(1) + `cens'
		}
		tempname Fz fz z
		scalar `Fz' = (`nobs' - `cens')/`nobs'
		scalar `z' = invnorm(`Fz')
		scalar `fz' = 1/sqrt(2*_pi)*exp(-0.5*(`z'*`z'))

		tempname uncond cond prob
		scalar `prob' = `fz'/`sigma'
		scalar `uncond' = `Fz'
		scalar `cond' = ( 1 - (`z'*`fz'/`Fz') ) - (`fz'*`fz')/(`Fz'*`Fz')

		if `cens' == 0 {
			scalar `prob' = .
			scalar `cond' = 1
			scalar `uncond' = 1
		}

		local vnam : colnames(`b')
		local nnam : word count `vnam'
		local nnam = `nnam'-2

		if `nnam' >= 1 {
			noi di 
			noi di in gr /*
				*/ "-----------------------------------------------------------"
			noi di in gr /*
				*/ "         | Marginal Effects at Observed Censoring Rate    " 
			noi di in gr /*
				*/ "         |-------------------------------------------------" 
			noi di in gr /*
				*/ "         |  Unconditional    Conditional on    Probability"
			noi di in gr /*
				*/ "  Name   | Expected Value   being Uncensored    Uncensored"
			noi di in gr /*
				*/ "---------+-------------------------------------------------"

			local i 1
			while `i' <= `nnam' {
				local v : word `i' of `vnam'
				local l = length("`v'")
				local skip = 9 - `l'
				local t1 = _b[`v'] * `uncond'
				local t2 = _b[`v'] * `cond'
				local t3 = _b[`v'] * `prob'
				noi di in gr _col(`skip') "`v'" _col(10) "|" /*
					*/ _col(13) in ye %10.0g `t1' /*
					*/ _col(31) in ye %10.0g `t2' /*
					*/ _col(48) in ye %10.0g `t3'
				local i = `i'+1
			}
			noi di in gr /*
				*/ "---------+-------------------------------------------------"
		}
	}
end
exit
