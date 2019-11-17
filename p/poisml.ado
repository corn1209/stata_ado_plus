*! verson 1.0  STB-45 sg91
* MAXIMUM LIKELIHOOD POISSON REGRESSION : Joseph Hilbe 4Feb1998
* OPTIONS: tolerance,log,iteration,offset,score,robust,cluster
program define poisml
 version 5.0
 local options "Level(integer $S_level) IRr"
 if "`*'"=="" | substr("`1'",1,1)=="," {
   if "$S_E_cmd"=="poisml" {
     error 301
   }
   parse "`*'"
   if `level'<10 | `level'> 99 {
     di in red "level() must be between 10 and 99"
     exit 198
   }
 }
 else {
   local varlist "req ex"
   #delimit ;
   local options "`options' LTolerance(real -1) noLOg ITerate OFfset(string) 
       SCore(string) Robust CLuster(string) *";
   #delimit cr
   local in "opt"
   local if "opt"
   local weight "fweight aweight"
   parse "`*'"
   parse "`varlist'",parse(" ")
   if "`log'"!="" { local log "quietly" }
   global S_mloff "`offset'"

 tempvar touse mysamp
 tempname b f V
 mark `touse' `if' `in'
 markout `touse' `varlist' `offset'

  if "`weight'" != "" {
        tempvar wvar
        gen double `wvar' `exp'
  }
  else  local wvar   1

  if ("`weight'"=="aweight")  {
        qui sum `wvar'
        qui replace `wvar' = `wvar'/_result(3)
  }

  if "`offset'" != "" {
        local ovar "`offset'"
  }
  else  local ovar   0
 
* ANALYTIC ESTIMATION OF LL0
  tempvar num den
  tempname r 
  qui gen double `num' = sum(`wvar'*`1') if `touse'
  qui gen double `den' = sum(`wvar'*exp(`ovar')) if `touse'
  scalar `r' = ln(`num'[_N]/`den'[_N])
  qui replace `num' = sum(-`wvar'*exp(`r'+`ovar') + /*
        */ `wvar'*(`r'+`ovar')*`1' - `wvar'*lngamma(`1'+1)) 
  local lf0 = `num'[_N]
  qui capture drop `num' `den'

* ESTIMATION OF FULL MODEL
   eq `1': `varlist'
   ml begin
   ml function mypoislf
   ml method lf
   ml model `b' = `1'
   ml sample `mysamp' [`weight' `exp'] if `touse' 
   `log' ml maximize `f' `V', `options' 
   ml post mypois, title("Poisson Estimates") lf0(`lf0') pr2
* ROBUST CALCULATIONS
   local y "`1'"
   mac shift
   global rhs `*' 
   tempname b V
   tempvar xb e

   mat `b' = get(_b)
   mat `V' = get(VCE)
   predict double `xb', index
   qui gen double `e' = (`y'-exp(`xb'+`ovar')) if `y'!=0 & `touse'
   qui replace `e' = -exp(`xb'+`ovar') if `y'==0 & `touse'
   if "`score'"!="" {
     gen `score' = `e'
   }
   if "`robust'"!="" & "`cluster'"=="" {
      _robust `e' if `touse'
      qui test $rhs, min
      local ch2 = _result(6)
   }
   if "`cluster'"!="" {
      _robust `e' if `touse', cluster(`cluster')
      qui test $rhs, min
      local ch2 = _result(6)
   }
}
if "`irr'"!="" {
      local eform "eform(IRR)"
   }
ml mlout mypois, level(`level') `eform'
end
