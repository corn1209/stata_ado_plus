*! hansen--Bruce Hansen's test for parameter instability     
*! version 1.1.0     Ken Heinecke     Dec 1994            sts7.5: STB-23
*	HANSEN.ado		Program update for Bruce Hansen's
*				Test for parameter instability
*				Written by Ken Heinecke, May 1994
*  (removed mkmat.ado from the program)
program define hansen
	version 3.1
	local varlist "req ex"
	local if "opt pre"
	local in "opt pre"
	local options "noCOnstant Current(str) Lags(str) noSAmple Static(str) Regress *"
	parse "`*'"

capture {
tempfile __t
local savfn "$S_FN"
local tsind = 0
quietly { save `__t',replace }
if ("`regress'" != "") { local sound "noisily" }
if ("`current'" != "") {
	local c "current(`current')"
	}
if ("`static'" != "") {
	local s "static(`static')"
	}
if ("`lags'" != "") {
	local l "lags(`lags')"
	local tsind=1
	}

quietly {
if(`tsind'==1) {
	`sound' tsfit `varlist' `if' `in',`l' `c' `s' `constan' `sample' `options'
	}
else {
	`sound' tsfit `varlist' `if' `in', current(`varlist') `constan' `sample' `options'
}

local nvar : word count $S_E_vl 
capture drop _e
predict _e `if' `in',res
capture drop if _e==.
local nobs=_N
capture drop _ee
gen double _ee = _e*_e
sum _ee
capture drop _sig2
gen double _sig2=_result(3)

/*
	_f`i's are the first order conditions
*/
parse "$S_E_vl",parse(" ")
   local i 1
   while ("`2'" != "") {
   	gen double _f`i'=`2'*_e
	local i = `i'+1
	mac shift	
	}
if ("`constan'" == "") {
	gen double _f`i'=_e
	local i = `i'+1
}
gen double _f`i' = _ee-_sig2

if ("`constan'" != "") {
	local number = `nvar'
	}
else {
	local number = `nvar'+1
	}

/*
	Create Si's with sums of the
	elements of the "f" vectors.
*/
local j 1
   while(`j'<=`number') {
	gen double _s`j'=sum(_f`j')
	local j = `j'+1
	}

local j 1
   while(`j'<=`number') {
	gen double _sS`j'=_s`j'*_s`j'
	local j = `j'+1
	}

local j 1
   while(`j'<=`number') {
	gen double _SS`j'=sum(_sS`j')
	drop _sS`j'
	local j = `j'+1
	}

local j 1
   while(`j'<=`number') {
	gen double _fS`j'=_f`j'*_f`j'
	local j = `j'+1
	}

local j 1
   while(`j'<=`number') {
	gen double _V`j'=sum(_fS`j')
	drop _fS`j'
	local j = `j'+1
	}

/*
	Create Vi with summed squares of the
	elements of the "f" vectors.
*/	
local i 1
local nvar : word count $S_E_vl
while (`i'<=`number') {
	scalar _V`i'= _V`i' in l
	drop _V`i'
	local i = `i'+1
	}

/*
	Create Li with summed squares of the
	elements of the "s" vectors and appropriate
	scaling factor (appropriate Vi).
*/
local i 1
while (`i'<=`number') {
	tempname _S`i'
	scalar `_S`i''= _SS`i' in l
	drop _SS`i'
	local i = `i'+1
	}

local i 1
while (`i'<=`number') {
	scalar _L`i'=(1/(`nobs'*scalar(_V`i')))*scalar(`_S`i'')
	scalar drop _V`i'
	local i = `i'+1
	} 

*** label scalars with variable names
parse "$S_E_vl",parse(" ")
local n 1
local llist1 ""
local llist2 ""
local half = int(`nvar'/2)
while (`n'<=`half') {
	scalar `2'=_L`n'
	scalar drop _L`n'
	local n = `n'+1
	local llist1 = "`llist1'" + " `2'"
	mac shift
	}
while (`n'<=`nvar'-1) {
	scalar `2'=_L`n'
	scalar drop _L`n' 
	local n = `n'+1
	local llist2 = "`llist2'" + " `2'"
	mac shift
	}
if ("`constan'" == "") {
	scalar _cons = _L`n'
	scalar drop _L`n'
	local n = `n'+1
	}
scalar sigma = _L`n'
scalar drop _L`n'

if ("`constan'" == "") {
	local llist2 = "`llist2'" + " _cons sigma"
	}
else {
	local llist2 = "`llist2'" + " sigma"
	}

noi display " "
noi display " "
noi display "Individual Statistics"
noi display " "

noi scalar l `llist1' `llist2'

/*
	Create L for the whole model
*/
tempname invV V row rowp temp ts
matrix accum `V' = _f1-_f`number',nocons
mat `invV' = inv(`V')

mat _Lc=J(1,1,0)
mat `row' = J(1,`number',0)
local j 1
   while (`j'<=`nobs'){
	local i 1
	while (`i'<=`number'){
		local ob`j' = _s`i'[`j']
		mat `row'[1,`i']= `ob`j''
		local i = `i'+1
		}
	mat `rowp' = `row''
	mat `temp' = `row'*`invV'
	mat `ts' = `temp'*`rowp' 
	mat _Lc =  _Lc + `ts'
	local j = `j'+1
	}

scalar _Lc = _Lc[1,1]
local df = 1/`nobs'
scalar _Lc = `df'*_Lc

noi display " "
noi display " "
noi display "Joint test statistic with `number' degrees of freedom:"
noi display " "
noi scalar l _Lc
	
drop _all
use `__t',clear
mac def S_FN "`savfn'"
** end quietly
 }
** end capture
}
if (_rc != 0) {
	local oldrc = _rc
	quietly use `__t',clear
	mac def S_FN "`savfn'"
	exit `oldrc'
}	
end
