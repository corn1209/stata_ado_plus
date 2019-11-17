*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe                          (sg44: STB-28)
* Lognormal distribution random number generator [via normal distribution]
* Example: rndlgn 1000 0 .5  [set obs 1000; 0 = mean; .5 = std. deviation]

program define rndlgn
	version 3.1
	set type double
	cap drop xlgn
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local mn `1'
		mac shift
		local var `1'
		mac shift
		tempvar ran1
		noi di in gr "( Generating " _c
		gen `ran1' = exp(`mn'+`var' * invnorm(uniform()))
		gen xlgn = `ran1'
		noi di in gr "." _c
		noi di in gr " )"
		noi di in bl "Variable " in ye "xlgn " in bl "created."
		lab var xlgn "Lognormal random variable"
		set type float
       }
end
