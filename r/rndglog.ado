*!version 1.1 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe, Walter Linde-Zwirble
* Generalized logistic distribution 3 parameter random number generator
* Example: rndglog 1000 3.0 0.7 4.5 [set obs 1000; L=3.0; A=0.7; T=4.5]

program define rndglog
  version 3.1
  clear
  set type double
  qui  {
     local cases `1'
     set obs `cases'
     mac shift
     local L `1'
     mac shift
     local A `1'
     mac shift
     local T `1'
     tempvar ran1
     noi di in gr "( Generating " _c
     gen `ran1'=uniform()
     gen xgl =`A'*log((`ran1')^(-`L'/`A')*(1+exp(`T'/`A')) - exp(`T'/`A'))
     noi di in gr "." _c
     noi di in gr " )"
     noi di in bl "Variable " in ye "xgl " in bl "created."
     lab var xgl "Generalized logit random variable"
     set type float
  }
end

