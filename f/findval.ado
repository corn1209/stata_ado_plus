*! FindValue by Stas Kolenikov, v.1.1, 25 Mar 2000
* version 1.1: option generate included
program define findval, rclass
  version 6
  gettoken value 0: 0 , parse(" ,")
  if "`value'"=="" {
    di in red "No value to compare with."
    exit 198
  }
  syntax [varlist] [if] [in], [SUBstr GENerate(str)]

  tokenize `varlist'
  marksample touse, novarlist
  if "`generat'"~="" { confirm new v `generat' }
  cap confirm number `value'
  if _rc==0 { local num 1 }
  else { local num 0 }
  if "`substr'"~="" & `num' {
    di in red "Does not make sense to consider a number as a substring"
    exit 198
  }
  di in gre "The value of " in yel "`value'"  _c
  qui {
   tempvar t p any
   qui g byte `p'=.
   qui g byte `any'=0 if `touse'
   qui g int `t'=.
   local k=1
   while "``k''"~="" {
      cap confirm numeric variable ``k''
      local numv=(_rc==0)
      if `numv' {
       if `num' {
        * makes sense: compare numeric value to numeric variable
        replace `p'=.
        replace `p'=(``k''==`value') & `touse'
        replace `any'=`any'|`p' if `p'~=.
        qui count if `p'
        if r(N)>0 { local res "`res' ``k''" }
       }
      }
      else {
       if !`num' {
        * makes sense: compare string value to string variable
        if "`substr'"=="" {
          replace `p'=.
          replace `p'=``k''==`"`value'"' & `touse'
          replace `any'=`any'|`p' if `p'~=.
          qui count if `p'
          if r(N)>0 { local res "`res' ``k''" }
        } /* exact match */
        else {
          qui replace `t'=.
          qui replace `t'=index(``k'',`"`value'"')
          replace `p'=.
          replace `p'=`t'>0 & `t'<. if `touse'
          replace `any'=`any'|`p' if `p'~=.
          qui count if `p'
          if r(N)>0 { local res "`res' ``k''" }
        } /* substr */
       }
      }
      local k=`k'+1
   }
  } /* end of quietly */
  if "`res'"~="" {
    di in gre " is found in variables: " in yel "`res'"
  }
  else { di in gre " is never found." }
  if "`generat'"~="" {
     qui g byte `generat'=`any' if `touse'
     lab var `generat' `"1 if `value' found in `res'"'
  }
  ret local vars `res'
  if `num' { ret scalar value=`value' }
  else { ret local value `value' }
end
