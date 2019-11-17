*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe, Walter Linde-Zwirble
* negative binomial random number generator with mu variable specified
* Example: rndnbl mu, k(0.15)  
* k the quadratic variance parameter = 0.15]

program define rndnblx
	version 3.1
        set type double
        local varlist "ex req"
	local options "`options' K(real 1.0)"
	parse "`*'"
	parse "`varlist'",parse(" ")
	qui {
	   local mu "`1'"
	   mac shift
	   tempvar ran1 ran2 ds ts sum1 t em y al c1 c2 c3 sq am
	   gen `al'=(`mu'-0.5)*(1-`k')
	   gen `c1'=lngamma(`al'+1)-lngamma(`al'+ 1/`k')
	   gen `c2'=log(1+1/(`mu'*`k'))
	   gen `c3'=lngamma(1/`k')
	   gen `sq'=sqrt(2.0*(`mu'+`mu'*`mu'*`k'))
	   if `k' < 1 {
		   gen `am'=(`mu'-0.5)*(1-`k')
	   }
	   else {
		   gen `am'=0.0
	   }
	   gen `ran1'=uniform()
	   gen `ran2'=uniform()
	   gen `ds'=1
	   gen `ts'=1
	   gen `em'=-1
	   gen `t'=-1
	   gen `y'=-1
	   egen `sum1'=sum(`ds')
	   noi di in gr "( Generating " _c
	   while `sum1' > 0 {
*              noi display `sum1'
	       replace `y'=sin(_pi*`ran1')/cos(_pi*`ran1')
	       replace `em'= `sq'*`y'+`am' if `ds'==1
	       replace `ts'=0 if ((0>`em') & (`ds'==1))
	       if `k' < 1 {
		  #delimit ;
		  replace `t'=0.9*(1+`y'*`y')*exp(lngamma(`em'+1/`k') - 
		      lngamma(`em'+1) - (`em'-`al')*`c2'+`c1') if 
		      ((`ds'==1) & (`ts'==1));
		  #delimit cr
	       }
	       else {
		  #delimit ;
		  replace `t'=0.9*(1+`y'*`y')*exp(lngamma(`em'+1/`k') - 
		      lngamma(`em'+1)-`c3' - `em'*`c2') if 
		      ((`ds'==1) & (`ts'==1));
		  #delimit cr
	       }
		  replace `ds'=0 if ((`ran2'<`t') & (`ds'==1) & (`ts'==1))
		  replace `ran1'=uniform()
		  replace `ran2'=uniform()
		  replace `t'=-1
		  replace `ts'=1
		  drop `sum1'
		  egen `sum1'=sum(`ds')
		  noi di in gr "." _c
	   }
	   noi di in gr " )"
	   gen xnb =int(`em'+0.5)
	   noi di in bl "Variable " in ye "xnb " in bl "created."
           lab var xnb "Constructed negative binomial random variable"
           set type float
   }
end
	
