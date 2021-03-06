*!version 1.1 1999 Joseph Hilbe
* version 1.0.0  1993 Joseph Hilbe, Walter Linde-Zwirble        (sg44: STB-28)
* Inverse Gaussian random number generator
* Example rndivg 1000 10 0.5; set obs 1000; mean=10; sigma=0.5; 
*         variance is sigma^2*mu^3

program define rndivg
   version 3.1
   set type double
   cap drop xig
   qui  {
      local cases `1'
      set obs `cases'
      mac shift
      local mu `1'
      mac shift
      local sig `1'
      local s=`sig'*`sig'*`mu'
      local peak = `mu'*((sqrt(4+9*`s'*`s')-(3*`s'))/2)
      local sq=sqrt(`s'*`mu'*`mu')
      #delimit ;
      local maxx=exp(-(`peak'-`mu')*(`peak'-`mu')/(2*`peak'*`mu'*`s')) 
           / sqrt(2*`s'*_pi*(`peak'^3)/`mu');
      #delimit cr
      tempvar ran1 ran2 ds ts sum1 t em y
      gen `ran1'=uniform()
      gen `ran2'=uniform()
      gen byte `ds'=1
      gen byte `ts'=1
      gen `em'=-1
      gen `t'=-1
      gen `y'=-1
      egen `sum1'=sum(`ds')
      noi di in gr "( Generating " _c
      while `sum1' > 0 {
         replace `y' = sin(_pi*`ran1')/cos(_pi*`ran1')
         replace `em'= `sq'*`y'+`peak' if `ds'==1
         replace `ts'=0 if ((0 > `em') & (`ds'==1))
         #delimit ;
         replace `t' = 0.66*(1+`y'*`y')*exp(-(`em'-`mu')*(`em'-`mu') /
            (2*`em'*`mu'*`s')) / sqrt(2*`s'*_pi*(`em'^3)/`mu') /`maxx' 
            if ((`ds'==1) & (`ts'==1));
         #delimit cr
         replace `ds'=0 if ((`ran2'<`t') & (`ds'==1) & (`ts'==1))
         replace `ran1'=uniform()
         replace `ran2'=uniform()
         replace `t' = -1
         replace `ts'=1
         drop `sum1'
         egen `sum1'=sum(`ds')
         noi di in gr "." _c
      }
      noi di in gr " )"
      gen xig = `em' 
      noi di in bl "Variable " in ye "xig " in bl "created."
      lab var xig "Inverse Gaussian random variable"
      set type float
   }
end




