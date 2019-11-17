*! version 1.0.7 CFBaum 21oct2003 from
*! version 1.0.6  20nov2002
* 1.0.7: enable onepanel

program define dwstat2, rclass
	version 6
	syntax [if] [in] [, noDetail noSample ]

	marksample touse
	if "`sample'" == "" { qui replace `touse' = 0 if !e(sample) }

					/* get time variables */
	if "`if'" == "" {
		local if "if e(sample)"
	_ts timevar panelvar `if' `in', sort onepanel
	markout `touse' `timevar'

					/* fetch residuals */
	tempname res dw
	qui predict double `res' if `touse' , res

	tsreport if `touse',  report
	return scalar N_gaps = r(N_gaps)
	qui count if `touse'
	return scalar N = r(N)
	return scalar k = e(N) - e(df_r)

	DW `dw' : `res'
	return scalar dw = `dw'

	di _n in gr "Durbin-Watson d-statistic("   /*
		*/ in ye %3.0f return(k) in gr "," in ye %6.0f return(N) /*
		*/ in gr ") = " in ye %9.0g `dw'

end


/* Compute Durbin-Watson statistic -- over all resids */

program define DW 
	args        scl_dw	/*  scalar name to hold DW result 
		*/  colon	/*  :
		*/  resids	/*  residuals */

	tempvar tres
	tempname esqlag

	qui gen double `tres' = (`resids' - l.`resids')^2
	sum `tres', meanonly
	scalar `esqlag' = r(sum)

	drop `tres'
	qui gen double `tres' = `resids' * `resids'
	sum `tres', meanonly

	scalar `scl_dw' = `esqlag' / r(sum)

end


exit

Durbin-Watson d-statistic(  #,    #):  1.2345678

Note:  sample has gaps, statistic may not follow exact
       d-statistic distribution.
---------------------------------------------------------------
                                      | Numerator   Denominator
--------------------------------------+------------------------
Obervations used                      |    65          64
Observations with assumed 0 elements  |     0           0
--------------------------------------+------------------------

