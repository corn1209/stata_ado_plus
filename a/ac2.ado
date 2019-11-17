*! version 1.3.12 CFBaum 22oct2003 from
*! version 1.3.11  10dec2002
* 1.3.12: enable onepanel (will only work under v8)

program define ac2
	version 6
	if _caller() < 8 {
		ac_7 `0'
		exit
	}

	syntax varname(ts) [if] [in]		///
		[,				///
		LAGs(int -999)			///
		GENerate(string)		///
		Level(int $S_level)		///
		FFT				///
		noGRAPH				/// graph options
		*				///
	]

	if `"`graph'"' != "" {
		syntax varname(ts) [if] [in]	///
			[,			///
			LAGs(int -999)		///
			GENerate(string)	///
			Level(int $S_level)	///
			FFT			///
			noGRAPH			///
		]
	}
	else {
		// parse graph options
		_get_gropts , graphopts(`options')	///
			getallowed(ciopts plot)
		local options `"`s(graphopts)'"'
		local ciopts `"`s(ciopts)'"'
		local plot `"`s(plot)'"'
		_check4gropts ciopts, opt(`ciopts')
	}

        if `level' < 10 | `level' > 99 {
                di in red "level must be between 10 and 99"
                exit 198
        }
	if "`graph'"!="" {
		if "`generate'"=="" {
			di in red "generate() must be specified with nograph"
			exit 198
		}
	}
	if "`generate'"!="" {
		local nword : word count `generate'
		if `nword' > 1 {
			di in red "generate() should name one new variable"
			exit 198
		}
		confirm new variable `generate'
	}

	marksample touse
	_ts tvar panelvar `if' `in', sort onepanel
	markout `touse' `tvar'

quietly {

	tempvar xm tmp ac pse
	tempname R0

	summarize `varlist' if `touse'
	scalar `R0' = r(Var)*(r(N)-1)
	local n = r(N)
	if `n' == 0 { error 2000 }
	if `n' == 1 { error 2001 }

	if `lags' == -999 {
		local lags = max(1,min(int(`n'/2)-2,40))
	}
	else if `lags' >= `n' {
		di in red "lags() too large; must be less than " `n'
		exit 498
	}
	else if `lags' <= 0 {
		di in red "lags() must be greater than zero"
		exit 498
	}

	gen double `xm' = `varlist'-r(mean) if `touse'
				/* done with r() from summarize */

	tsreport if `touse' & `varlist'!=.

	if r(N_gaps) > 0 {
		if r(N_gaps) > 1 {
			noi di in blu "(note: time series has " /*
			*/ r(N_gaps) " gaps)"
		}
		else	noi di in blu "(note: time series has 1 gap)"
	}

	if "`fft'"!="" {
		preserve
		keep if `touse'
		local new = _N + `lags'
		local op1 = _N + 1
		set obs `new'
		replace `xm' = 0 in `op1'/l
		replace `tvar' = /*
		*/ `tvar'[_n-1] + `_dta[_TSitrvl]' in `op1'/l
		sort `tvar'

		tempvar zr zi fhat
		cap noi fft `xm', gen(`zr' `zi')
		if _rc {
			if _rc==1 {
				error 1
			}
			di in red "with the fft option specified"
			exit _rc
		}
		gen double `fhat' = (`zr'^2+`zi'^2)/`n'
		drop `zr' `zi'
		fft `fhat', gen(`zr' `zi')
		replace `zr' = `zr'*(`n'+`lags')/`n'
		gen double `ac' = `zr'/`zr'[1]
		replace `ac' = `ac'[_n+1]
		replace `ac' = . if _n > `lags'
		gen double `tmp' = sum(`ac'^2)
		gen double `pse' =  sqrt((1+ cond(_n>1,2*`tmp'[_n-1],0))/`n')
		drop in `op1'/l
	}
	else {
		gen double `tmp' = . in 1
		gen double `ac'  = . in 1
		gen double `pse' = 1/sqrt(`n') in 1
		local i 1
		while `i' <= `lags' {
			replace `tmp' = `xm'*L`i'.`xm'
			summarize `tmp', meanonly
			replace `ac' = r(sum)/`R0' in `i'

			if `i' > 1 {
				local im1 = `i' - 1
				replace `tmp' = `ac'^2 in 1/`im1'
				summarize `tmp' in 1/`im1', meanonly
				replace `pse' = /*
				*/ sqrt((1+2*r(sum))/`n') in `i'
			}
			local i = `i' + 1
		}
	}

} // quietly

	if "`graph'"=="" { /* produce graph */
		quietly {
			tempvar obs mse
			tempname zz
			gen long `obs' = _n in 1/`lags'
			label var `obs' "Lag"
			local xttl : var label `obs'
			scalar `zz' = invnorm((100+`level')/200)
			replace `pse' = `zz'*`pse' in 1/`lags'
			gen double `mse' = -`pse' in 1/`lags'
			label var `pse' "`level'% CI"
			label var `mse' "`level'% CI"
		}

		format `ac' `pse' `mse' %-5.2f

		label var `ac' "Autocorrelations of `varlist'"
		local yttl : var label `ac'
		local note ///
		"Bartlett's formula for MA(q) `level'% confidence bands"

		if `"`plot'"' == "" {
			local legend legend(nodraw)
		}
		else	local draw nodraw
		version 8: graph twoway			///
		(rarea `mse' `pse' `obs'		/// the CI bands
			in 1/`lags',			///
			sort				///
			pstyle(ci)			///
			yticks(0,			///
				grid gmin gmax		///
				notick			///
			)				///
			ytitle(`"`yttl'"')		///
			xtitle(`"`xttl'"')		///
			note(`"`note'"')		///
			`legend'			///
			`draw'				///
			`ciopts'			///
		)					///
		(dropline `ac' `obs'			///
			in 1/`lags',			///
			pstyle(p1)			///
			`options'			///
		)					///
		// blank
	}

	if "`generate'"!="" {
		rename `ac' `generate'
		format `generate' %10.0g
		label var `generate' "Autocorrelations of `varlist'"

		if "`fft'"!="" {
			quietly {
				keep `generate'
				tempfile ttt
				save `ttt'
				restore
				merge using `ttt'
				drop _merge
				tsset `tvar'
			}
		}
	}
	if `"`plot'"' != "" {
		// data alread restored
		version 8: graph addplot `plot' || , norescaling
	}
end

exit

-ac- requires

1.  N >= 2,

2.  lags() <= N - 1.

If lags() not specified, by default lags() = max(1, min(int(N/2) - 2, 40)).

This default was chosen because -pac- requires lags() <= int(N/2) - 2.

