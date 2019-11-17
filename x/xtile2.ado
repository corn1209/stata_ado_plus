*! 1.0.1 ZWang 1Jun1999
program define xtile2
_parsewt "aw fw pw" `0' 
local 0  "`s(newcmd)'" 
local wt "`s(weight)'" 
syntax newvarname =exp [if] [in], by(varlist) /*
    */ [Nquantiles(string) ALTdef ]
token "`0'", pars(" =")
tempvar x touse group tile
mark `touse' `wt' `if' `in'
markout `touse' `by'
qui gen double `x' `exp' if `touse'
qui egen `group'= group(`by') if `touse'
qui sum `group'
local ngr=r(max)
if "`nquantiles'"!=""{local nq "n(`nquantiles')"}
local i=1
qui { 
  gen `1'=. 
  while `i'<=`ngr'{
        xtile `tile'=`x' `wt' if `group'==`i', `nq' `altdef'
        replace `1'=`tile' if `group'==`i'
        drop `tile'
    local i=`i'+1
  }
}
end
