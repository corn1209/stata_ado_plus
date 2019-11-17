*!version 1.1 1999 Joseph Hilbe
* version 1.0.0  1993 Joseph Hilbe                           (sg44: STB-28)
* Weibull distribution random number generator
* Example: rndwei 1000 3 2 [set obs 1000; 3 = shape gamma; 2 = scale lambda]

program define rndwei
	version 3.1
	set type double
	cap drop xw
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local gam `1'
		mac shift
		local lam `1'
		tempvar ran1
		noi di in gr "( Generating " _c
		gen `ran1'=uniform()
		gen xw =((log(1/`ran1'))^(1/`gam'))/`lam'
		noi di in gr "." _c
		noi di in gr " )"
		noi di in bl "Variable " in ye "xw " in bl "created."
		lab var xw "Weibull random variable"
		set type float
	}
end
