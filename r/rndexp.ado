*!version 1.1 1999 Joseph Hilbe
* version 1.0.0  1993 Joseph Hilbe                            (sg44: STB-28)
* Exponential distribution random number generator 
* Example: rndexp 1000 3  [set obs 1000;  3 = shape parameter]

program define rndexp
	version 3.1
	set type double
	cap drop xe
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local mn `1'
		tempvar ran1
		noi di in gr "( Generating " _c
		gen `ran1' = -`mn'*ln(uniform())
		gen xe = `ran1'
		noi di in gr "." _c
		noi di in gr " )"
		noi di in bl "Variable " in ye "xe " in bl "created."
		lab var xe "Exponential random number generator"
		set type float
	}
end
