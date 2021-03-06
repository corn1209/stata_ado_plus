*! version 1.0.8 CFBaum 22oct2003 from
*! version 1.0.7  09oct2002
* 1.0.8: enable onepanel, req v8 for ac2

program define wntestq2, rclass
	version 8.0

	local vv : display "version " _caller() ":"

	syntax varname(ts) [if] [in] [, Lags(passthru)]

	marksample touse
	_ts t1 panelvar `if' `in', sort onepanel
	markout `touse' `t1'

	tempvar p
	`vv' ac2 `varlist' if `touse', gen(`p') `lags' nograph

	quietly {
		count if `touse'
		local n = r(N)
		count if `p' != .
		local df = r(N)
		replace `p' = sum(`p'^2/(`n'-_n))
	}

	return scalar stat = `p'[_N] * `n' * (`n'+2)
	return scalar p    = chiprob(`df',return(stat))
	return scalar df   = `df'

	di _n in gr "Portmanteau test for white noise"
	di in smcl in gr "{hline 39}"
	di in gr " Portmanteau (Q) statistic = " in ye %10.4f return(stat)
	di in gr " Prob > chi2(" in ye `df' in gr ") " _col(28) "= " /*
		*/ in ye %10.4f return(p)
end
