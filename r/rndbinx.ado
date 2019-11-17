*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 04/14/95 Joseph Hilbe                       (sg44: STB-28)
* Binomial distribution random number generator
* EX: rndbinx mu den : mu= variable with p values; den=case denominator
program define rndbinx
  version 3.0
  set type double
  local varlist "ex req"
  parse "`*'"
  parse "`varlist'",parse(" ")
  local pp "`1'"
  mac shift
  local n "`1'"
  mac shift
  qui {
  tempvar m am ran1 ran2 ds ts sum1 e y en em bnl mu pc p plog pclog oldg 
  tempvar s t j g
  gen `p'=`pp'
  replace `p'=1.0-`pp' if `pp' > 0.5
  gen `am'=`n'*`p'
  gen `m'=3
  replace `m'=1 if `n' < 25
  replace `m'=2 if ((`am'<1.0) & (`n'>=25))
  gen `mu'=`n'*`p'
  gen `pc'=1.0-`p'
  gen `plog'=log(`p')
  gen `pclog'=log(`pc')
  gen `bnl'=0
  gen `en'=`n'
  gen `oldg'=lngamma(`en' +1.0)
  gen `em'=-1
  gen `e'=-1
  gen `ran1'=uniform()
  gen `ran2'=uniform()
  gen `j'=0
  gen `t'=1.0
  gen `g'=exp(-`am')
  gen `ds'=1
  gen `ts'=1
  gen `y'=-1
  gen `s'=sqrt(2.0*`am'*`pc')
  egen `sum1'=sum(`ds')
  noi di in gr "( Generating " _c 
  while `sum1' > 0 {
* method 1 for small denominators
  replace `bnl'=`bnl'+1 if ((`ran1' < `p') & (`j'<`n')& (`m'==1) )
  replace `j'=`j'+1     if ((`j'<`n') & (`m'==1))
  replace `ds'=0        if ((`j'==`n') & (`m'==1))
* method 2 for small expected numbers
  replace `em'=`em'+1    if ((`ds'==1) & (`m'==2))
  replace `t'=`t'*`ran1' if ((`ds'==1) & (`m'==2))
  replace `ds'=0         if ((`g'>`t') & (`m'==2))
* method 3 for general case
  replace `y'=sin(_pi*`ran1')/cos(_pi*`ran1') if ((`ds'==1) & (`m'==3))
  replace `em'=`s'*`y' +`am'                  if ((`ds'==1) & (`m'==3))
  replace `ts'=0 if (((0 >`em') | (`em' >=(`en'+1.0))) & (`ds'==1) & (`m'==3))
  #delimit ;
  replace `e'=1.2*`s'*(1.0+(`y'*`y'))*exp(`oldg'-lngamma(`em'+1.0)
    -lngamma(`en'-`em'+1.0)+(`em'*`plog')+(`en'-`em')*`pclog') if
    ((`ds'==1)&(`ts'==1) & (`m'==3));
  #delimit cr
  replace `ds'=0 if ((`ran2'<`e') & (`ds'==1) & (`ts'==1) & (`m'==3))
* get ready for the next time through the loop
  noi di in gr "." _c 
  replace `ran1'=uniform()
  replace `ran2'=uniform()
  replace `e'=-1
  replace `ts'=1
  drop `sum1'
  egen `sum1'=sum(`ds')
  }
* clean up for exit
  noi di in gr " )" 
  replace `bnl'=`em' if (`m'==2)
  replace `bnl'=`n' if ((`m'==2) & (`em'>`n'))
  replace `bnl'=int(`em'+0.5) if (`m'==3)
  replace `bnl'=`n'-`bnl' if `p' ~= `pp'
  gen bnlx=`bnl'
  noi di in gr "Variable " in ye "bnlx " in gr "created."
  lab var bnlx "Constructed binomial random variable"
  set type float
}
end

