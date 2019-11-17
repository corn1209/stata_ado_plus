*!version 1.2 1999 Joseph Hilbe
*!version 1.1 1993 Joseph Hilbe                            (sg44: STB-28)
* revised 10Mar97 Hilbe with assistance from Guy van Mille  STB-41 sg44.1
* Poisson distribution random number generator
* Example: rndpoi 1000 4  [set obs 1000;  4 is the mean]

program define rndpoi
   version 3.1
   set type double
   cap drop xp
   qui  {
      local cases `1'
      set obs `cases'
      mac shift
      local xm `1'
      mac shift
      tempvar em t ds sum1 ran1
      local g = exp(-`xm')
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
      noi di in gr " )"
      gen xp = int(`em'+0.5)
      noi di in bl "Variable " in ye "xp " in bl "created."
      lab var xp "Poisson random variable"
      set type float
   }
end

