*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe                            (sg44: STB-28)
* revised 10Mar97 Hilbe      STB-41 sg44.1
* Poisson distribution random number generator for use with mu
/* Example: set obs 1000
            gen x1=invnorm(unform())
            gen x2=invnorm(unform())
            gen byte b0=1
            gen b1=.5
            gen b2=-.25
            gen lp=b0+b1*x1+b2*x2
            gen mu=exp(lp)   [inverse link function]
            rndpoix mu       [variable xp created]
            glm xp x1 x2, f(poi)
*/
program define rndpoix
   version 3.1
   set type double
   local varlist "req ex"
   parse "`*'"
   parse "`varlist'",parse(" ")
   qui  {
      local xm `1'
      mac shift
      tempvar em t ds sum1 ran1 g
      gen `g' = exp(-`xm')
      gen `em'= -1
      gen `t' = 1.0
      gen `ran1' = uniform()
      gen `ds' = 1
      count if `ds'>0
      noi di in gr "( Generating " _c
      while _result(1) > 0 {
          replace `em' = `em'+ 1 if (`ds'==1)
          replace `t' = `t' * `ran1' if (`ds'==1)
          replace `ds'=0 if (`g' > `t')
          replace `ran1' = uniform()
          noi di in gr "." _c
          count if `ds'>0
      }
      noi di in gr " )"
      gen xp = int(`em'+.5)
      noi di in bl "Variable " in ye "xp " in bl "created."
      lab var xp "Constructed Poisson random variable"
      set type float
      }
end

