*! ci2.ado			
*! version 1.01, by PT Seed (paul.seed@kcl.ac.uk)
*! Confidence intervals for correlations 

*! Updated 29 Sept 2001
*! to work with version 7.0

prog define ci2, rclass 
version 7.0

	syntax varlist(min= 2 max = 2) [if] [in] [fw aw] , [COrr SPearman Level(real -99) *]

	if "`corr'`spearman'" == "" {
		ci `*'
		exit
	}

	if `level' ~= -99 { global S_level = `level' }

	if "`spearman'" ~= "" { local corr "spearman" }
	quietly `corr' `varlist' `if' `in' [`weight' `exp'] 

	if "`spearman'" ~= "" { local c_type "Spearman's rank" }
	else { local c_type "Pearson's product-moment" }

	tokenize "`varlist'"
	
	di in gr _n "Confidence interval for `c_type' correlation "
	di in gr "of " in ye "`1' " /*
*/ in gr "and " in ye "`2'" /*
*/ in gr ", based on Fisher's transformation.

	cii2 r(N) r(rho) , corr nohead 

	if r(N) <=10 & "`spearman'" ~= "" { 
		di in red _n "Warning: This method may not give valid results 
		di in red "with small samples (n<= 10) for rank correlations." _n
	}


	return scalar ub = r(ub)
	return scalar lb = r(lb)
	return scalar N = r(N)
	return scalar rho = r(rho)
	return local corr "`c_type'"

end ci2
exit 

