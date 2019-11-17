*! cii2.ado			
*! version 1.02, by PT Seed (paul.seed@kcl.ac.uk)
*! Confidence intervals for correlations - immediate version

* Correction made to the "level" option 6 Jan 2003

prog define cii2, rclass

	version 6.0

	local opts = substr("`*'",index("`*'",",")+1, .)
	if index("`opts'","corr") == 0  {
		cii `*'
		exit
	}

	tempname n r se z lb ub rstar
	tokenize "`*'", parse(" ,")
	scalar `n' = `1'
	scalar `r' = `2'
	mac shift 3

	while "`1'" ~= "" {
		if index("`1'","l") ~= 0  {
			tokenize "`1'", parse(" ,()")
			cap assert index("level","`1'") & "`2'" =="(" & "`4'" == ")"
			if _rc {
				di in red "Syntax error" 
				exit 198
			}
			global S_level = `3'
		}
		mac shift
	}
		

	scalar `rstar' =.5*ln((1+`r')/(1-`r'))
	scalar `se' = (`n'-3)^-.5
	scalar `z' = invnorm(.5+$S_level/200)
	scalar `lb' = `rstar' - `z'*`se'
	scalar `ub' = `rstar' + `z'*`se'
	scalar `lb' = (exp(2*`lb')-1)/(exp(2*`lb')+1)
	scalar `ub' = (exp(2*`ub')-1)/(exp(2*`ub')+1)

	return scalar rho = `r'
	return scalar N = `n'
	return scalar lb = `lb'
	return scalar ub = `ub'

	if index("`opts'", "nohead") == 0 {
		di in gr _n "Confidence interval for correlation,
		di in gr "based on Fisher's transformation.
	}

	
	di in gr "Correlation = " in ye %4.3f `r' /*
*/ in gr " on " in ye `n' in gr " observations"/*
*/ in gr " ($S_level% CI: " in ye %4.3f `lb' /*
*/ in gr " to " in ye %4.3f `ub' in gr ")"



end cii2
exit 

