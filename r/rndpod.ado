*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe, Walter Linde-Zwirble
* Poisson distribution random number generator with dispersion parameter
* Example: rndpod 1000 4 1.2  [set obs 1000;  4 = mean, 
*                              1.2 the sigma of xm - the random deviate]

program define rndpod
   version 3.1
   clear
   set type double
   qui  {
      local cases `1'
      set obs `cases'
      mac shift
      local xm `1'
      mac shift
      local sp `1'
      tempvar em t ds sum1 ran1 g ran2    
      gen `ran2' = invnorm(uniform())
      gen `g' = exp(-`xm'+(`ran2'*`sp'))
      gen `em'= -1
      gen `t' = 1.0
      gen `ran1' = uniform()
      gen `ds' = 1
      count if `ds'>0
      noi di in gr "( Generating " _c
      while _result(1)>0  {
          replace `em' = `em'+ 1 if (`ds'==1)
          replace `t' = `t' * `ran1' if (`ds'==1)
          replace `ds'=0 if (`g' > `t')
          replace `ran1' = uniform()
          noi di in gr "." _c
          count if `ds'>0 
      }
      gen xp = int(`em'+0.5)
      noi di in gr " )"
      noi di in bl "Variable " in ye "xp " in bl "created."
      lab var xp "Poisson random variable with dispersion"
      set type float
  }
end

