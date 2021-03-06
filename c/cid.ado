*! version 1.0.2 PR 28Jun95.
program define cid
	version 3.1
	local varlist "req ex min(1) max(2)"
	#delimit ;
	local options "BY(string) UNPaired UNEqual Median
		Level(integer $S_level)" ;
	#delimit cr
	local if "opt"
	local in "opt"
	parse "`*'"
	if "`unequal'"!="" & ("`unpaire'"=="" | "`median'"!="") {
		di in red "unequal invalid in this context"
		exit 198
	}
	if "`unpaire'"=="" {
		local paired "paired"
	}
	local diff " difference in"
	local s "s"
	preserve
	tempvar Grp d x2
	quietly {
		if "`if'"!="" | "`in'"!="" { keep `if' `in' }
		parse "`varlist'", parse(" ")
		local y1 `1'
		local y2 `2'
		if "`by'"!="" {
			_crcunab `by'
			local by "$S_1"
			if "`y2'"!="" {
				error 103
			}
			keep `y1' `by'
			keep if `y1'!=. & `by'!=.
			sort `by'
			by `by': gen `Grp'=1 if _n==1
			replace `Grp'=sum(`Grp')
			if `Grp'[_N]!=2 {
				noisily di in red `Grp'[_N] /*
				 */ " groups found, 2 required"
				exit 198
			}
			drop `Grp'
			count if `by'==`by'[1]
			local n1 = _result(1)
			count if `by'==`by'[_N]
			local n2 = _result(1)
			gen `x2' = `y1'[_n+`n1']
			if "`paired'"!="" {
				if `n1'!=`n2' {
					noi di in red /*
					 */ "Paired group sizes unequal"
					exit 198
				}
				replace `x2' = `y1'-`x2'
			}
		}
		else {	/* no byvar */
			if "`y2'"!="" {
				keep `y1' `y2'
				if "`paired'"!="" {
					noi di in bl /*
					 */ "[paired data assumed]"
					gen `x2' = `y1'-`y2'
					keep if `x2'!=.
					local n1 = _N
					local n2 `n1'
				}
				else {
/*
	Unpaired data in two vars.
	Stack y2 data under y1, drop missing values,
	reposition y2 beside y1 as x2.
*/
					count if `y1'!=.
					local n1 = _result(1)
					count if `y2'!=.
					local n2 = _result(1)
					local n = _N
					local N2 = _N*2
					set obs `N2'
					replace `y1' = `y2'[_n-`n'] if _n>`n'
					keep if `y1'!=.
					gen `x2' = `y1'[_n+`n1']
				}
			}
			else {
/*
	cid var1.
	No byvar, single variable only.
	Make use of "unpaired" here equivalent to paired.
*/
				if "`paired'"=="" { local paired "paired" }
				local diff
				local s
				gen `x2' = `y1'
				keep if `x2'!=.
				local n1 = _N
				local n2 `n1'
			}
			keep `y1' `x2'
		}
		if "`paired'"!="" {
			local n12 = `n1'*(`n1'+1)/2
		}
		else {
			local n12 = `n1'*`n2'
		}
		if "`median'"=="" {
			local param " mean"
			local based "Normal"
			local setext "Std. Err."
			if "`paired'"!="" {
				global S_1 `n1'
				sum `x2'
				local mean = _result(3)
				local se = sqrt(_result(4)/`n1')
				if `se'==. { error 2001 } 
				local df = `n1'-1
			}
			else {
				global S_1 = `n1'+`n2'
				sum `y1' in 1/`n1'
				local mean1 = _result(3)
				local s1 = _result(4)
				sum `x2'
				local mean2 = _result(3)
				local s2 = _result(4)
				if `s1'==. | `s2'==. { error 2001 } 
				local mean = `mean1'-`mean2'
				if "`unequal'"!="" { 
					local S1 "(`s1'/`n1')"
					local S2 "(`s2'/`n2')"
					local se = sqrt(`S1'+`S2')
					local df = -2 + int( (`S1'+`S2')^2 /*
					 */ /( `S1'^2/(`n1'+1) /*
					 */ + `S2'^2/(`n2'+1) ) +.5)
				}
				else {
					local df = `n1'+`n2'-2
					local se = sqrt((1/`n1'+1/`n2')* /*
					 */ (`s1'*(`n1'-1)+`s2'*(`n2'-1))/`df')
				}
			}
			global S_2 `df'
			global S_3 `mean'
			global S_4 `se'
			local invt = invt(`df', `level'/100) 
			global S_5 = `mean'-`invt'*`se'
			global S_6 = `mean'+`invt'*`se'
		}
		else {
			local param " median"
			local based "Rank"
			local setext "       K "
			local n = `n1'*`n2'
			cap set obs `n'
			local rc=_rc
			if `rc' {
				tempfile temp
				save `temp'
				local np = int(`n'*1.02) /* 2% safety factor */
				drop _all
				cap set maxobs `np'
				if _rc {
	di in red "insufficient memory to set maxobs to `np' as required"
					exit 2002
				}
				use `temp'
				erase `temp'
				set obs `n'
			}
			gen `d'=.
			local j 1
			while `j'<=`n1' {
				local j1 = (`j'-1)*`n2'+1
				local j2 = `j1'+`n2'-1
				if "`paired'"!="" {
					local j3 = `j1'+`j'-1
					replace `x2' = `x2'[_n-`j1'+1] /*
					 */ in `j3'/`j2'
					local x1 = `x2'[`j']
					replace `d' = .5*(`x1'+`x2') /*
					 */ in `j3'/`j2'
				}
				else {
					replace `x2' = `x2'[_n-`j1'+1] /*
					 */ in `j1'/`j2'
					local x1 = `y1'[`j']
					replace `d' = `x1'-`x2' /*
					 */ in `j1'/`j2'
				}
				local j = `j'+1
			}
			sort `d'
*			noi list `y1' `by' `d'
			sum `d',detail
			local med = _result(10)
			if "`paired'"!="" {
				local e = `n1'*(`n1'+1)/4
				local v = `n1'*(`n1'+1)*(2*`n1'+1)/24
				global S_1 `n1'
			}
			else {
				local e = `n1'*`n2'/2
				local v = `n1'*`n2'*(`n1'+`n2'+1)/12
				global S_1 = `n1'+`n2'
			}
			local k1 = `e'+invnorm(.5-.5*`level'/100)*sqrt(`v')
/*
	Guess at continuity correction of 0.5. 1 or 0?
*/
			local k = int(.5+`k1')
			global S_2 `k1'
			global S_3 `med'
			global S_4 `k'
			global S_5 = `d'[`k']
			global S_6 = `d'[`n12'-`k'+1]
		}
	}
	if "`y2'"=="" & "`by'"=="" { local paired " " }
	else { local paired " `paired'" }
	if "`by'"!="" { local bv " by `by'" }
	local tt1 "    Obs "
	local ttl "Estimate"
	local skip = 8 - length("`y1'")
	local fmt : format `y1'
	if substr("`fmt'",-1,1)=="f" { 
		local ofmt="%9."+substr("`fmt'",-2,2)
	}
	else	local ofmt "%9.0g"
	#delimit ;
	di in gr _n 
"`based'-based confidence interval for`diff'`paired'`param'`s'`bv'" ;
	di in gr _n 
"Variable | `tt1'    `ttl'    `setext'       [`level'% Conf. Interval]" 
	_n "---------+" _dup(61) "-" ;
	di in gr _skip(`skip') "`y1' |" _col(10)
		in yel %8.0f $S_1
	 	_col(23) `ofmt' $S_3
	 	_col(35) `ofmt' $S_4
	 	_col(51) `ofmt' $S_5
	 	_col(63) `ofmt' $S_6 ;
	#delimit cr
end
