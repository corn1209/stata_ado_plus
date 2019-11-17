*!version 1.1  1999 Joseph Hilbe
* first version 1.0.0  1993 Joseph Hilbe, Walter Linde-Zwirble    (sg44: STB-28)
* Beta-binomial random deviate generator
* Example: rndbb 1000 200 0.2 0.05
*   set obs 1000 
*   200 is the denominator
*   0.2 is p=a1/(a1+a2)
*   0.05 is k, the dispersion factor k=1/(a1+a2+1)
* This generator will return beta-binomial random deviates within the 
* following constraints. Although k can take any value from 0 to 1, in this
* program we limit k because of the volotility of the distribution outside
* this range of k. k must be as follows: k< the lessor of p' and (1-p')/2
* where p'=p if p<0.5, else p'=1-p. This should work well within the
* physical representation of an overdispersed binomial.

program define rndbb
   version 3.1
   set type double
   cap drop xbb
   qui  {
      local cases `1'
      set obs `cases'
      mac shift
      local m `1'
      mac shift
      local pp `1'
      mac shift
      local k `1'
      if `pp' < 0.5  {
          local p=`pp'
      }
      else  {
          local p=1-`pp'
      }
      local eta=(1/`k')-1
      if (`k' > `p') | (`k' > (1-`p')/2)  {
          noi di in bl " k too large from program..."
          error
      }

      local varr=(`m'*`p'*(1-`p'))*(1+`k'*(`m'-1))
      if `p'>0.4  {
          local peak=`m'*`p'
          local v=4*`varr'
      }
      else  {
          local peak=`m'*`p'*(1-1.5*((`k'*`k')/(`p'*`p')))
          local v=3*`varr'
      }
      #delimit ;
      local scale=exp(lngamma(`p'*`eta'+`peak')+ lngamma(`m'-`peak'+(1-`p') *
          `eta') - lngamma(`peak'+1) - lngamma(`m'-`peak'+1));
      #delimit cr
      local sq=sqrt(`v')
      local am=`peak'
      tempvar ran1 ran2 ds ts sum1 t em y
      gen `ran1'=uniform()
      gen `ran2'=uniform()
      gen `ds'=1
      gen `ts'=1
      gen `em'=-1
      gen `t'=-1
      gen `y'=-1
      egen `sum1'=sum(`ds')
      noi di in gr "( Generating " _c
      while `sum1' > 0  {
          replace `y' = sin(_pi*`ran1')/cos(_pi*`ran1')
          replace `em'= int(`sq'*`y'+`am') if `ds'==1
          replace `ts'=0 if (( (0 > `em') | (`em'>`m') ) & (`ds'==1))
          #delimit ;
          replace `t' = 0.66 * (1+`y'*`y')*exp(lngamma(`p'*`eta'+`em') +
               lngamma(`m'-`em'+(1-`p')*`eta')-lngamma(`em'+1) - 
               lngamma(`m'-`em'+1))/`scale' if ((`ds'==1) & (`ts'==1));
          #delimit cr
          replace `ds'=0 if ((`ran2'<`t') & (`ds'==1) & (`ts'==1))
          replace `ran1'=uniform()
          replace `ran2'=uniform()
          replace `t'=-1
          replace `ts'=1
          drop `sum1'
          egen `sum1'=sum(`ds')
          noi di in gr "." _c
      }
      gen xbb = `em'
      replace xbb = `m'-`em' if (`pp'>`p')
      noi di in gr " )"
      noi di in bl "Variable " in ye "xbb " in bl "created."
      lab var xbb "Beta binomial random variable"
      set type float
   }
end

          
