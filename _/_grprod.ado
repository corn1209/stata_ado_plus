*! version 1.0.1  Philip Ryan  12 Dec 2000  STB-60 dm87
*! extension to egen
*! calculate the row product of observations
* 1.0.1 use type byte where possible
* 1.0.1 fix syntax of "word count" macro

program define _grprod
version 6
gettoken type 0 : 0
gettoken g    0 : 0
gettoken eqs  0 : 0
syntax varlist(min=2) [if] [in] [, PMiss(string)]
tempvar touse
mark `touse' `if' `in'
#delimit ;
if "`pmiss'" == "" {;
 local pmiss "ignore";
};
if "`pmiss'" != "missing" & "`pmiss'" != "1" & "`pmiss'" != "ignore" {;
displ in re "Syntax error: specify " in wh "pmiss(missing)" in re " or "
in wh "pmiss(1)"  in re " or " in wh "pmiss(ignore)";
 exit 198;
};
#delimit cr
quietly { 
tokenize `varlist'
local nvar : word count `varlist'
tempvar nmiss zflag sign
egen `nmiss' = rmiss(`varlist') if `touse'
gen byte `zflag' = cond(`1'==0,1,0) if `touse'
gen byte `sign' = cond(`1' != ., sign(`1'),1) if `touse'
gen double `g' = cond(`1'==.|`1'==0,0,log(abs(`1'))) if `touse'
mac shift 
while "`1'"!="" {
replace `zflag' = `zflag' + cond(`1'==0,1,0) if `touse'
replace `g' = `g' + cond(`1'==.|`1'==0,0,log(abs(`1'))) if `touse'
replace `sign' = `sign' * cond(`1' != ., sign(`1'), 1) if `touse'
mac shift 
}
replace `g' = exp(`g') * `sign' if `touse'
replace `g' = . if `nmiss' == `nvar' & `touse'
replace `g' = 0 if `zflag' & `touse'
if "`pmiss'" == "missing" {
replace `g' = cond(`nmiss' > 0, ., `g') if `touse'
}
else if  "`pmiss'" == "1" {
replace `g' = cond(`nmiss' == `nvar', 1, `g') if `touse'
}
}
end
