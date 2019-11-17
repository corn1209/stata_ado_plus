*! version 1.1.7 CFBaum 21oct2003 from official
*! version 1.1.6  03sep2000
* 1.1.7: allow use with onepanel

program define dfuller2, rclass
	version 6.0
	syntax varname(ts) [if] [in] [, TRend noCONstant Lags(int -1) REGress]

	if      "`constan'" != "" & "`trend'" == "" { local case 1 }
	else if "`constan'" == "" & "`trend'" == "" { local case 2 }
	else if "`constan'" == "" & "`trend'" != "" { local case 4 }
	else {
		noi di in red "Cannot choose trend if constant is excluded"
		exit 198
	}

        marksample touse
	_ts tvar panelvar `if' `in', sort onepanel
	markout `touse' `tvar'
        local samp "if `touse'==1"


	quietly {
		if `lags' < 0 { local lags 0 }
		local mac
		if `case' == 2 { local mac "c"  }
		if `case' == 4 { local mac "ct" }
                if "`trend'" != "" {
                        summ `tvar' `samp', meanonly
                        local min = r(min)
                        tempvar tt
                        gen long `tt' = `tvar'-r(min)
                }
		if `lags' == 0 {
			reg D.`varlist' L.`varlist' `tt' `samp', `constan' 
		}
		else {
			reg D.`varlist' L.`varlist' DL(1/`lags').`varlist' /*
				*/ `tt' `samp', `constan' 
			local aug "Augmented "
		}
		local T = e(N)
		local n = e(N) - e(df_r)
		test L.`varlist'
		local Zt = sign(_b[L.`varlist'])*sqrt(r(F))

		if "`mac'" != "" {
			MacP `mac' 1 `Zt'
			local ztp = `r(p)'
		}
		GetCrit `case' `T'
	}
	noi di in gr _n "`aug'Dickey-Fuller test for unit root" /* 
		*/ _col(52) "Number of obs   = " in ye %9.0g `T'
	di _n in smcl in gr _col(32) /*
		*/ "{hline 10} Interpolated Dickey-Fuller {hline 9}"
	di in gr _col (19) "Test" /*
		*/ _col(32)  "1% Critical" /*
		*/ _col(50)  "5% Critical" /*
		*/ _col(67) "10% Critical"
	di in gr _col (16) "Statistic" /*
		*/ _col(36)  "Value" /*
		*/ _col(54)  "Value" /*
		*/ _col(72) "Value"
	di in gr in smcl "{hline 78}"

	di in gr " Z(t)" /*
		*/ _col(15) in ye %10.3f `Zt' /*
		*/ _col(33) %10.3f `r(Zt1)' /*
		*/ _col(51) %10.3f `r(Zt5)' /*
		*/ _col(69) %10.3f `r(Zt10)'

	if "`ztp'" != "" {
		di in gr in smcl "{hline 78}"
		di in gr "* MacKinnon approximate p-value for Z(t) = " /*
			*/ in ye %6.4f `ztp'
		ret scalar p   = `ztp'
	}

        if "`regress'" != "" {
                di
                if "`tt'" != "" {
                        DispReg `tt' `lags' `varlist'
                }
                else {
                        regress, nohead
                }
        }

	ret scalar Zt     = `Zt'
	ret scalar N      = `T'
	ret scalar lags   = `lags'
end

program define GetCrit, rclass

	args case N

	tempname zt
	
	if `case' == 1 {
		mat `zt' = ( -2.66,-2.62,-2.60,-2.58,-2.58,-2.58\ /*
			  */ -1.95,-1.95,-1.95,-1.95,-1.95,-1.95\ /*
			  */ -1.60,-1.61,-1.61,-1.62,-1.62,-1.62)
	}
	else if `case' == 2 {
		mat `zt' = ( -3.75,-3.58,-3.51,-3.46,-3.44,-3.43\ /*
			  */ -3.00,-2.93,-2.89,-2.88,-2.87,-2.86\ /*
			  */ -2.63,-2.60,-2.58,-2.57,-2.57,-2.57)
	}
	else {
		mat `zt' = ( -4.38,-4.15,-4.04,-3.99,-3.98,-3.96\ /*
			  */ -3.60,-3.50,-3.45,-3.43,-3.42,-3.41\ /*
			  */ -3.24,-3.18,-3.15,-3.13,-3.13,-3.12)
	}

	if `N' <= 25 {
		local zt1  = `zt'[1,1] 
		local zt5  = `zt'[2,1]
		local zt10 = `zt'[3,1]
	}
	else if `N' <= 50 {
		local zt1  = `zt'[1,1] + (`N'-25)/25 * (`zt'[1,2]-`zt'[1,1])
		local zt5  = `zt'[2,1] + (`N'-25)/25 * (`zt'[2,2]-`zt'[2,1])
		local zt10 = `zt'[3,1] + (`N'-25)/25 * (`zt'[3,2]-`zt'[3,1])
	}
	else if `N' <= 100 {
		local zt1  = `zt'[1,2] + (`N'-50)/50 * (`zt'[1,3]-`zt'[1,2])
		local zt5  = `zt'[2,2] + (`N'-50)/50 * (`zt'[2,3]-`zt'[2,2])
		local zt10 = `zt'[3,2] + (`N'-50)/50 * (`zt'[3,3]-`zt'[3,2])
	}
	else if `N' <= 250 {
		local zt1  = `zt'[1,3] + (`N'-100)/150 * (`zt'[1,4]-`zt'[1,3])
		local zt5  = `zt'[2,3] + (`N'-100)/150 * (`zt'[2,4]-`zt'[2,3])
		local zt10 = `zt'[3,3] + (`N'-100)/150 * (`zt'[3,4]-`zt'[3,3])
	}
	else if `N' <= 500 {
		local zt1  = `zt'[1,4] + (`N'-250)/250 * (`zt'[1,5]-`zt'[1,4])
		local zt5  = `zt'[2,4] + (`N'-250)/250 * (`zt'[2,5]-`zt'[2,4])
		local zt10 = `zt'[3,4] + (`N'-250)/250 * (`zt'[3,5]-`zt'[3,4])
	}
	else {
		local zt1  = `zt'[1,6]
		local zt5  = `zt'[2,6]
		local zt10 = `zt'[3,6]
	}
	return scalar Zt1  = `zt1'
	return scalar Zt5  = `zt5'
	return scalar Zt10 = `zt10'
end


program define MacP, rclass
	args type vars tau

	local stype = lower("`type'")
	if "`stype'"=="c" { local type 0 }
	else              { local type 1 }


	local g3=0
        local min=.
	local max=.
	if `type'==0 {	/* no trend */
		if `vars'==1 {
			if `tau'>-1.586 {
#d ;
local min=-6.07 ; local max=1.73 ; local g0=1.7325 ; local g1=0.8898 ; local g2=-0.1836 ; local g3=-0.02820 ;
#d cr
			}
			else {
#d ;
local min=-18.83 ; local g0=2.1659 ; local g1=1.4412 ; local g2=0.03827 ;
#d cr
			}
		} /* vars==1 */
		else if `vars'==2 {
			if `tau'>-2.285 {
#d ;
local min=-5.74 ; local max=1.03 ; local g0=2.2092 ; local g1=0.6808 ; local g2=-0.2705 ; local g3=-0.03833 ;
#d cr
			}
			else {
#d ;
local min=-18.86 ; local g0=2.9200 ; local g1=1.5012 ; local g2=0.03980 ;
#d cr
			}
		} /* vars==2 */
		else if `vars'==3 {
			if `tau'>-2.877 {
#d ;
local min=-6.30 ; local max=1.09 ; local g0=2.7246 ; local g1=0.6720 ; local g2=-0.2545 ; local g3=-0.03256 ;
#d cr
			}
			else {
#d ;
local min=-23.48 ; local g0=3.4699 ; local g1=1.4856 ; local g2=0.03164 ;
#d cr
			}
		} /* vars==3 */
		else if `vars'==4 {
			if `tau'>-3.330 {
#d ;
local min=-7.09 ; local max=1.47 ; local g0=3.2776 ; local g1=0.7667 ; local g2=-0.2066 ; local g3=-0.02452 ;
#d cr
			}
			else {
#d ;
local min=-28.07 ; local g0=3.9673 ; local g1=1.4777 ; local g2=0.02632 ;
#d cr
			}
		} /* vars==4 */
		else if `vars'==5 {
			if `tau'>-3.399 {
#d ;
local min=-7.96 ; local max=2.02 ; local g0=3.8227 ; local g1=0.8783 ; local g2=-0.1617 ; local g3=-0.01817 ;
#d cr
			}
			else {
#d ;
local min=-25.96 ; local g0=4.5509 ; local g1=1.5338 ; local g2=0.02954 ;
#d cr
			}
		} /* vars==5 */
		else if `vars'==6 {
			if `tau'>-3.498 {
#d ;
local min=-8.70 ; local max=2.50 ; local g0=4.3062 ; local g1=0.9499 ; local g2=-0.1353 ; local g3=-0.01455 ;
#d cr
			}
			else {
#d ;
local min=-23.27 ; local g0=5.1399 ; local g1=1.6036 ; local g2=0.03445 ;
#d cr
			}
		} /* vars==6 */
	} /* type==0 */
	else if `type'==1 {	/* linear trend */
		if `vars'==1 {
			if `tau'>-2.657 {
#d ;
local min=-5.51 ; local max=1.11 ; local g0=2.6130 ; local g1=0.7831 ; local g2=-0.2828 ; local g3=-0.04285 ;
#d cr
			}
			else {
#d ;
local min=-16.18 ; local g0=3.2512 ; local g1=1.6047 ; local g2=0.04959 ;
#d cr
			}
		} /* vars==1 */
		else if `vars'==2 {
			if `tau'>-2.998 {
#d ;
local min=-6.31 ; local max=1.37 ; local g0=3.0348 ; local g1=0.8084 ; local g2=-0.2317 ; local g3=-0.03125 ;
#d cr
			}
			else {
#d ;
local min=-21.15 ; local g0=3.6646 ; local g1=1.5419 ; local g2=0.03645 ;
#d cr
			}
		} /* vars==2 */
		else if `vars'==3 {
			if `tau'>-3.372 {
#d ;
local min=-7.19 ; local max=1.79 ; local g0=3.4954 ; local g1=0.8754 ; local g2=-0.1840 ; local g3=-0.02271 ;
#d cr
			}
			else {
#d ;
local min=-25.37 ; local g0=4.0983 ; local g1=1.5173 ; local g2=0.02990 ;
#d cr
			}
		} /* vars==3 */
		else if `vars'==4 {
			if `tau'>-3.447 {
#d ;
local min=-8.11 ; local max=2.42 ; local g0=3.9904 ; local g1=0.9717 ; local g2=-0.1408 ; local g3=-0.01650 ;
#d cr
			}
			else {
#d ;
local min=-26.63 ; local g0=4.5844 ; local g1=1.5338 ; local g2=0.02880 ;
#d cr
			}
		} /* vars==4 */
		else if `vars'==5 {
			if `tau'>-3.510 {
#d ;
local min=-8.90 ; local max=2.91 ; local g0=4.4318 ; local g1=1.0233 ; local g2=-0.1183 ; local g3=-0.01317 ;
#d cr
			}
			else {
#d ;
local min=-26.53 ; local g0=5.0722 ; local g1=1.5634 ; local g2=0.02947 ;
#d cr
			}
		} /* vars==5 */
		else if `vars'==6 {
			if `tau'>-3.763 {
#d ;
local min=-9.63 ; local max=3.44 ; local g0=4.8639 ; local g1=1.0739 ; local g2=-0.1005 ; local g3=-0.01082 ;
#d cr
			}
			else {
#d ;
local min=-26.18 ; local g0=5.5300 ; local g1=1.5914 ; local g2=0.03039 ;
#d cr
			}
		} /* vars==6 */
	} /* type==1 */

	local h = `g0' + `g1'*`tau' + `g2'*(`tau')^2 + `g3'*(`tau')^3
	local p = cond(`tau'<`min',0,cond(`tau'>`max',1,normprob(`h')))
	return scalar p = `p'
end

program define DefMac
	local i 1 
	local j 2
	while "``i''" != "" {
		c_local ``i'' "``j''"
		local i = `j'+1
		local j = `i'+1
	}
end

program define DispReg
        args tt lags dvar
        di in smcl in gr "{hline 13}{c TT}{hline 64}"
        di in smcl in gr abbrev("`e(depvar)'",12) _col(14) "{c |}" /*
                */ _col(21) "Coef." _col(29) "Std. Err." _col(44) "t" /*
                */ _col(49) "P>|t|" _col(59) "[95% Conf. Interval]"
        di in smcl in gr "{hline 13}{c +}{hline 64}"
        di in smcl in gr abbrev("`dvar'",12) _col(14) "{c |}"
        local vv "L1.`dvar'"
        local bv "_b[`vv']"
        local sv "_se[`vv']"
        di in smcl in gr _col(11) "L1 {c |}" in ye /*
                */ _col(17) %9.0g `bv' /*
                */ _col(28) %9.0g `sv' /*
                */ _col(38) %8.2f `bv'/`sv' /*
                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                */ _col(58) %9.0g `bv' - invt(`e(df_r)',$S_level/100)*`sv' /*
                */ _col(70) %9.0g `bv' + invt(`e(df_r)',$S_level/100)*`sv'
        local vv "LD.`dvar'"
        local bv "_b[`vv']"
        local sv "_se[`vv']"
	if `lags' >= 1 {
		di in smcl in gr _col(11) "LD {c |}" in ye /*
			*/ _col(17) %9.0g `bv' /*
			*/ _col(28) %9.0g `sv' /*
			*/ _col(38) %8.2f `bv'/`sv' /*
			*/ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
			*/ _col(58) %9.0g `bv' - invt(`e(df_r)',/*
			*/ $S_level/100)*`sv' /*
			*/ _col(70) %9.0g `bv' + invt(`e(df_r)',/*
			*/ $S_level/100)*`sv'
	}
	local i 2
	while `i' <= `lags' {
		local vv "L`i'D.`dvar'"
		local bv "_b[`vv']"
		local sv "_se[`vv']"
		di in smcl in gr %12s "L`i'D" " {c |}" in ye /*
			*/ _col(17) %9.0g `bv' /*
			*/ _col(28) %9.0g `sv' /*
			*/ _col(38) %8.2f `bv'/`sv' /*
			*/ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
			*/ _col(58) %9.0g `bv' - invt(`e(df_r)',/*
			*/ $S_level/100)*`sv' /*
			*/ _col(70) %9.0g `bv' + invt(`e(df_r)',/*
			*/ $S_level/100)*`sv'
		local i = `i'+1
	}
        local vv "`tt'"
        local bv "_b[`vv']"
        local sv "_se[`vv']"
        di in smcl in gr "_trend       {c |}" in ye /*
                */ _col(17) %9.0g `bv' /*
                */ _col(28) %9.0g `sv' /*
                */ _col(38) %8.2f `bv'/`sv' /*
                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                */ _col(58) %9.0g `bv' - invt(`e(df_r)',$S_level/100)*`sv' /*
                */ _col(70) %9.0g `bv' + invt(`e(df_r)',$S_level/100)*`sv'
        local vv "_cons"
        local bv "_b[`vv']"
        local sv "_se[`vv']"
        di in smcl in gr "_cons        {c |}" in ye /*
                */ _col(17) %9.0g `bv' /*
                */ _col(28) %9.0g `sv' /*
                */ _col(38) %8.2f `bv'/`sv' /*
                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                */ _col(58) %9.0g `bv' - invt(`e(df_r)',$S_level/100)*`sv' /*
                */ _col(70) %9.0g `bv' + invt(`e(df_r)',$S_level/100)*`sv'
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
end

