*! Version 1.0.0  (STB-55: sg135)
program define archlm, rclass
	version 6.0
	syntax [if] [in] [,Lags(numlist integer>0) noSample]

	if "`e(cmd)'" ~= "regress" {
		error 301
	}

	if "`lags'" == "" {
		local lags=1
	}
	
	marksample touse
	if "`sample'" == "" { qui replace `touse' = 0 if !e(sample) }

					/* get time variables */
	_ts timevar, sort
	markout `touse' `timevar'
	
	tempname res2
					/* fetch residuals */
	qui predict double `res2' if `touse' , res
	qui replace `res2' = `res2'*`res2'
	qui count if `touse'
	return scalar N = r(N)

	tsreport if `touse',  report
	return scalar N_gaps = r(N_gaps)
	qui count if `touse'
	return scalar N = r(N)
	return scalar k = e(N) - e(df_r)

	tokenize `lags'
	local i 1
	while "``i''" != "" {
		ArchLM1 ``i'' `res2'
		return scalar arch``i'' = r(arch)
		return scalar df``i'' = r(df)
		return scalar p``i'' = r(p)
		local i = `i' + 1
	}
	return local lags `lags'
end

program define ArchLM1, rclass
	args lags res2	

	tempname regest
   					/* regress resids^2 on lagged 
					 * resids^2 to order `lags'  */
	estimates hold `regest'

	qui regress `res2' l(1/`lags').`res2' 
	return scalar arch = e(N)*e(r2)
	return scalar df = `lags'
	return scalar p  = chiprob(`lags',return(arch))
	estimates unhold `regest'
	
	di in gr "ARCH LM test statistic, order(" %3.0f `lags' "): "   /*
		*/ in ye %9.0g return(arch) in gr /* 
		*/ in gr "  Chi-sq(" %2.0f return(df)  ")  P-value = " /*
		*/ in ye %6.0g return(p)
end
	
exit








