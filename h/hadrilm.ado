*! version 1.0.3     20030408     C F Baum
*  Performs test for stationarity in heterogenous panel data 
*  of K. Hadri, Econometrics Journal 3, 148-161 (2001)
* 1717 1.0.2: add lr variance
* 3408 1.0.3: per Liang suggestion on levinlin, calc pval from signed statistic

program define hadrilm, rclass
	version 7.0
	syntax varname(ts) [if] [in] [ , Maxlag(integer -1) ]	
	qui tsset
	local id `r(panelvar)'
	local time `r(timevar)'
	scalar schwert = 4
	if ( r(unit1) == "m" | r(unit1) == "." ) { scalar schwert = 12 }
   	marksample touse
	markout `touse' `time'
	tsreport if `touse', report panel
	if r(N_gaps) {
		di in red "sample may not contain gaps"
		error 198
	}
	qui xtsum `id' if `touse'
	local N `r(n)'
	local T `r(Tbar)'
	if int(`T')*`N' ~= r(N) {
		di in red "panel must be balanced"
		error 198
		}
	tempname Vals 	
	qui tab `id' if `touse', matrow(`Vals')     
	local nvals = r(r)
    local i = 1
    while `i' <= `nvals' {
    	local val = `Vals'[`i',1]
    	local vals "`vals' `val'"
    	local i = `i' + 1
    	}
    tempvar enn epsmu eps2mu pspmu epstau eps2tau psptau acmu actau
    local reg1 ""
    local reg2 ""
    local ii 0
    foreach i of local vals {
    	tempvar v`i' t`i'
    	qui gen `v`i'' = (`id'==`i') if `touse'
    	local reg1 "`reg1' `v`i''"
    	qui gen `t`i'' = `v`i''*(_n-`ii'*`T')
       	local ii = `ii'+1
    	local reg2 "`reg2' `t`i''"
    	}
    qui {
    	reg `varlist' `reg1' if `touse', noc
    	predict double `epsmu', r
    	gen double `eps2mu' = `epsmu'^2
    	reg `varlist' `reg1' `reg2' if `touse', noc
    	predict double `epstau', r
    	gen double `eps2tau' = `epstau'^2
* eqn 10 for both level, trend
		gen double `pspmu' = .
		gen double `psptau' = .
		gen `enn' = _n
		}
* eqn 9 with finite sample correction p.157
	summ `eps2mu' if `touse',meanonly
	scalar s2mu = r(sum)/(`N'*(`T'-1))
	summ `eps2tau' if `touse',meanonly
	scalar s2tau = r(sum)/(`N'*(`T'-2))
* heteroskedastic errors across panel	
	scalar ot2 = 1 / `T'^2
	scalar etamu = 0
	scalar etatau = 0
	scalar hetamu = 0
	scalar hetatau = 0
*
	foreach i of local vals {
		qui replace `pspmu' = sum(`epsmu')^2 if `id'==`i'
		qui summ `eps2mu' if `id'==`i'
		scalar s2mi = r(sum)/(`T'-1)
		scalar s2m`i' = r(sum)/`T'
	 	qui summ `pspmu' if `id'==`i'
		scalar etamu = etamu + ot2*r(sum)
* eqn 27
		scalar hetamu = hetamu + ot2*r(sum)/s2mi
		qui replace `psptau' = sum(`epstau')^2 if `id'==`i'
		qui summ `eps2tau' if `id'==`i'
		scalar s2ti = r(sum)/(`T'-2)
		scalar s2t`i' = r(sum)/`T'
		qui summ `psptau' if `id'==`i', meanonly
		scalar etatau = etatau + ot2*r(sum)
		scalar hetatau = hetatau + ot2*r(sum)/s2ti
		}
	scalar etamu = etamu / `N'
	scalar etatau = etatau / `N'
	scalar hetamu = hetamu / `N'
	scalar hetatau = hetatau / `N'	
* serially dependent errors across panel
	if `maxlag'==-1 {
* set maxlag via Schwert criterion (Ng/Perron JASA 1995)
		local maxlag = int(schwert*(`N'/100)^0.25)
		local kmax = "Maxlag = `maxlag' chosen by Schwert criterion" 
		}
	else {
		local kmax "Maxlag = `maxlag'"
		}
	scalar s2mulr = 0
	scalar s2taulr = 0
	scalar twot = 2 /`T'
	foreach i of local vals {
		scalar s2mui = 0
		scalar s2taui = 0
* generate autocovariances from all available data
			forv l = 1/`maxlag' {
				local w = 1-(`l'/(`maxlag'+1))
				capt drop `acmu' `actau'
				qui gen `acmu' = `epsmu'*L`l'.`epsmu' if `id'==`i'
				qui summ `acmu' if `id'==`i'
				scalar s2mui = s2mui + `w'*r(sum)*twot
				qui gen `actau' = `epstau'*L`l'.`epstau' if `id'==`i'
				qui summ `actau' if `id'==`i'
				scalar s2taui = s2taui + `w'*r(sum)*twot
				}
			scalar s2mulr = s2mulr + s2mui + s2m`i'
			scalar s2taulr = s2taulr + s2taui + s2t`i'
		}
	scalar s2mulr = s2mulr / `N'
	scalar s2taulr = s2taulr / `N'
*	di "s2mulr, s2mu " s2mulr " " s2mu
*	di "s2taulr, s2tau " s2taulr " " s2tau
* eqn 12
	scalar lmmu = etamu/s2mu
	scalar lmtau = etatau/s2tau
	scalar lmmulr = etamu/s2mulr
	scalar lmtaulr = etatau/s2taulr
* eqn 17, 25
	scalar vmu = 1/6
	scalar wmu = sqrt(1/45)
	scalar vtau = 1/15
	scalar wtau = sqrt(11/6300)
* eqn 14
* 3408 Evaluate all of these as one-tailed tests
	scalar rtn = sqrt(`N')
	scalar zmu = rtn*(lmmu-vmu)/wmu
*	scalar pmu = 1-norm(abs(zmu))
	scalar pmu = 1-norm(zmu)
	scalar zmulr = rtn*(lmmulr-vmu)/wmu
*	scalar pmulr = 1-norm(abs(zmulr))
	scalar pmulr = 1-norm(zmulr)
	scalar zhmu = rtn*(hetamu-vmu)/wmu
*	scalar phmu = 1-norm(abs(zhmu))
	scalar phmu = 1-norm(zhmu)
* eqn 22
	scalar ztau = rtn*(lmtau-vtau)/wtau
* 	scalar ptau = 1-norm(abs(ztau))
	scalar ptau = 1-norm(ztau)
	scalar ztaulr = rtn*(lmtaulr-vtau)/wtau
*	scalar ptaulr = 1-norm(abs(ztaulr))
	scalar ptaulr = 1-norm(ztaulr)
	scalar zhtau = rtn*(hetatau-vtau)/wtau
*	scalar phtau = 1-norm(abs(zhtau))
	scalar phtau = 1-norm(zhtau)
*
	di as text _n "Hadri (2000) panel unit root test for " as result "`varlist'"
	di as text "with " as result "`T'" as text " observations on "/*
	*/ as result "`N'" as text " cross-sectional units"
	di as text "{hline 59}"
	di as text " eps       Z(mu)    P-value      Z(tau)    P-value"
	di as text "{hline 59}" 	
	di as text "Homo" as result _col(8) %9.3f zmu _col(22) %6.4f pmu _col(31)  /*
		*/ %9.3f ztau _col(45) %6.4f ptau
	di _n as text "Hetero" as result _col(8) %9.3f zhmu _col(22) %6.4f phmu _col(31) /*
		*/ %9.3f zhtau _col(45) %6.4f phtau		
	di _n as text "SerDep" as result _col(8) %9.3f zmulr _col(22) %6.4f pmulr _col(31) /*
		*/ %9.3f ztaulr _col(45) %6.4f ptaulr	
	di as text "{hline 59}" 	
	di as text "H0: all `N' timeseries in the panel are stationary processes" 	
	di as text "Homo: homoskedastic disturbances across units"
	di as text "Hetero: heteroskedastic disturbances across units"
	di as text "SerDep: controlling for serial dependence in errors (lag trunc = `maxlag')"
*
return local depvar `varlist'
return scalar N = `N'
return scalar T = `T'
return scalar zmu = zmu
return scalar pmu = pmu
return scalar ztau = ztau
return scalar ptau = ptau
return scalar zhmu = zhmu
return scalar phmu = phmu
return scalar zhtau = zhtau
return scalar phtau = phtau
return scalar zmulr = zmulr
return scalar pmulr = pmulr
return scalar ztaulr = ztaulr
return scalar ptaulr = ptaulr
*
end

exit

