*! pwcorrw version 1.0.0  NJC 16 June 1998
*! pwcorr version 3.0.1  02oct1995
program define pwcorrw
	version 3.0
	local varlist "opt min(2)"
	local if "opt"
	local in "opt"
	local weight "aweight fweight"
	local options "Bonferroni Obs Print(real -1) SIDak SIG STar(real -1)"
    local options "Width (int 6) `options'"
	parse "`*'"
	parse "`varlist'", parse(" ")
	local weight "[`weight'`exp']"
	local nvar : word count `varlist'
	local adj 1
	if "`bonferr'"!="" | "`sidak'"!="" {
		if "`bonferr'"!="" & "`sidak'"!="" { error 198 }
		local nrho=(`nvar'*(`nvar'-1))/2
		if "`bonferr'"!="" { local adj `nrho' }
	}
	if (`star'>=1) {
		local star = `star'/100
		if `star'>=1 {
			di in red "star() out of range"
			exit 198
		}
	}

	local j0 1
	while (`j0'<=`nvar') {
		di
		local j1=min(`j0'+ `width',`nvar')
		local j `j0'
		di in gr "          |" _c
		while (`j'<=`j1') {
			local l = 9-length("``j''")
			di in gr _skip(`l') "``j''" _c
			local j=`j'+1
		}
		local l=9*(`j1'-`j0'+1)
		di in gr _n "----------+" _dup(`l') "-"

		local i `j0'
		while `i'<=`nvar' {
			local l= 9-length("``i''")
			di in gr _skip(`l') "``i'' | " _c
			local j `j0'
			while (`j'<=min(`j1',`i')) {
				qui corr ``i'' ``j'' `if' `in' `weight'
				local c`j'=_result(4)
				local n`j'=_result(1)
				local p`j'=min(`adj'*tprob(_result(1)-2,/*
				*/ _result(4)*sqrt(_result(1)-2)/ /*
				*/ sqrt(1-_result(4)^2)),1)
				if "`sidak'"!="" {
					local p`j'=min(1,1-(1-`p`j'')^`nrho')
				}
				local j=`j'+1
			}
			local j `j0'
			while (`j'<=min(`j1',`i')) {
				if `p`j''<=`star' & `i'!=`j' {
					local ast "*"
				}
				else local ast " "
				if `p`j''<=`print' | `print'==-1 |`i'==`j' {
					di " " %7.4f `c`j'' "`ast'" _c
				}
				else 	di _skip(9) _c
				local j=`j'+1
			}
			di
			if "`sig'"!="" {
				di in gr "          |" _c
				local j `j0'
				while (`j'<=min(`j1',`i'-1)) {
					if `p`j''<=`print' | `print'==-1 {
						di "  " %7.4f `p`j'' _c
					}
					else	di _skip(9) _c
					local j=`j'+1
				}
				di
			}
			if "`obs'"!="" {
				di in gr "          |" _c
				local j `j0'
				while (`j'<=min(`j1',`i')) {
					if `p`j''<=`print' | `print'==-1 /*
					*/ |`i'==`j' {
						di "  " %7.0g `n`j'' _c
					}
					else	di _skip(9) _c
					local j=`j'+1
				}
				di
			}
			if "`obs'"!="" | "`sig'"!="" {
				di in gr "          |"
			}
			local i=`i'+1
		}
		local j0=`j0'+ `width' + 1
	}
end
