*! version 1.0.1  26Sep1997  Rory Wolfe and Bill Gould  STB-42 sg76
program define omodel
	version 5.0
	local cmd1 "`1'"
	if "`cmd1'"=="logit" { 
		local cmd "ologit"
	}
	else if "`cmd1'"=="probit" { 
		local cmd "oprobit"
	}
	else {
		di in red "Incorrect link function"
		error 198
	}
	mac shift

	local varlist "req ex min(2)"
	local if "opt"
	local in "opt"
	local weight "fweight"
	parse "`*'"
	parse "`varlist'", parse(" ")
	local depv "`1'"

	tempvar touse
	mark `touse' `if' `in' [`weight'`exp']
	markout `touse' `varlist'

	quietly { 
		tempvar cat lhs
		egen `cat' = group(`depv') if `touse'
		summ `cat'
		local n = _result(6)
		if `n'==0 {
			error 2000
		}
		if `n'==1 { 
			di in red "`depv' takes on only one value"
			exit 498
		}
		if `n'==2 { 
			di in red "`depv' takes on only two values"
			exit 498
		}
	}

/*
   we run the ordered command first so that, if any variables are dropped, 
   we can omit them from the independent binaries models as well
*/
	tempvar id p1 p2 g1 g2 cateq ll1 ll2 binary
	tempname res
	`cmd' `varlist' [`weight'`exp'] if `touse'
	if _result(1)==. { 
		exit 2000
	}
	preserve
	Getnames
	local rhs1 $S_1
	local rhs2 $S_2

	global S_1
	global S_2
	estimates hold `res'

        qui keep if `touse'
	if "`weight'"!="" {
		tempvar wvar 
		qui gen double `wvar' `exp'
		qui compress `wvar'
		local weight "[`weight'=`wvar']"
	}
	qui keep `rhs1' `cat' `wvar'

/* 
   now we estimate the independent binaries models
*/

        capture assert __cut 
        if _rc==0 {
                di in red "omodel needs to use variable name __cut"
                exit _rc 
        }

	quietly{
		gen `id'=_n
		expand `n'
		sort `id'
		by `id': gen __cut=_n
		by `id': gen `binary'=(`cat'<=__cut)
	
		local dof 0
		local ll 0
		* ordered link model fitted through independent binaries
		xi: `cmd1' `binary' i.__cut `rhs1' `weight' if __cut!=`n'
		local dof = `dof' + _result(3)
		predict double `g1'
		sort `id' __cut
		gen double `p1'=`g1' if __cut==1
		replace `p1'=`g1'-`g1'[_n-1] if __cut!=1 & __cut!=`n'
		replace `p1'=1-`g1'[_n-1] if __cut==`n'
		gen `cateq'= `cat'==__cut
	        if "`wvar'"=="" {
			local wvar 1
		}
		gen double `ll1' = sum(`wvar'*`cateq'*log(`p1'))
		local ll = `ll' + `ll1'[_N]
		drop `ll1' `g1' `p1'
		}

	if "`cmd1'"=="logit" { local coeff "proportionality of odds" }
	if "`cmd1'"=="probit" { local coeff "equality of coefficients" }
	di _n in gr "Approximate likelihood-ratio test of `coeff'"
	di in gr "across response categories:"

	quietly{
		* generalised model fitted through independent binaries
		local gdof 0
		local gll 0
		xi: `cmd1' `binary' `rhs2' `weight' if __cut!=`n'
		local gdof = `gdof' + _result(3)
		predict double `g2'
		sort `id' __cut
		gen double `p2'=`g2' if __cut==1
		replace `p2'=`g2'-`g2'[_n-1] if __cut!=1 & __cut!=`n'
		replace `p2'=1-`g2'[_n-1] if __cut==`n'
		gen double `ll2' = sum(`wvar'*`cateq'*log(`p2'))
		local gll =`gll'+`ll2'[_N]
		drop `ll2' `g2' `p2'
		local ratio = -2*(`ll' - (`gll'))
		local testdf = `gdof'-`dof'
		}
	estimates unhold `res'

	global S_1 `ratio'
	global S_2 `testdf'
	di _col(10) in gr "chi2(" in ye %1.0f `testdf' in gr ") = " /* 
		*/ in ye %9.2f `ratio'
	di _col(8) in gr "Prob > chi2 = " in ye %9.4f chiprob(`testdf',`ratio')
end

program define Getnames
	tempname b 
	mat `b' = get(_b) 
	local names : colnames(`b')
	parse "`names'", parse(" ")
	global S_1
	global S_2
	while "`1'"!="" { 
		if "`1'"=="_cut1" { 
			exit
		}
	* Rename I* variables as they are erased by xi: before fitting
	if substr("`1'",1,1)=="I" {
		local newname = substr("`1'",2,.)
		rename `1' `newname'
		global S_1 $S_1 `newname'
		global S_2 "$S_2 i.__cut*`newname'"
		}
	else {
		global S_1 $S_1 `1'
		global S_2 "$S_2 i.__cut*`1'"
		}
		mac shift
	}
end

exit


