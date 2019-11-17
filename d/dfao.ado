*! version 1.0.7  R Sperling  Mar 28, 2002
* 12/11/01: display centered outlier table; fixed problem with display of dates
* 12/11/01: number of outliers now displays 0 if noao option selected
* 12/12/01: nonnegative integer or noninteger value entered for maxlag generates an error
* 12/12/01: added lltc option so user can choose between seq-t test or either aic, sc, and hq information criteria in lag length tests
* 12/17/01: lag length testing extended to test of zero lag
* 12/17/01: display of confidence intervals reversed
* 12/17/01: corrected omitted dummy variables bug and ml1 is used for markout in lag-length testing
* 02/14/02: fixed bug in calculation of first and last observations for output.
* 03/28/02: added noconstant option
* 03/28/02: fixed display bug that occurred with noconstant option
* 06/01/02: Improved time-series handling; specifying noCONstant automatically suppresses outlier test and trend, i.e.,
*           the noCONstant option is equivalent to specifying options "noCONstant noAOtest notrend"

program define dfao, rclass

/* Tests for a single unit root in a univariate time series when additive outliers are present. Follows the method
   for a modifed ADF test outlined in Vogelsang (1999). If the user suppresses the outlier test, then this routine
   performs the standard ADF unit root test, but still provides more functionality than dfuller. */

    version 7

    syntax varname(ts) [if] [in] [ , Maxlag(string) LLTC(string) noLAgtest noAOtest noCONstant noTRend /*
        */ GENerate(string) REGress LEVel(integer $S_level) ]

* Suppress outlier test and/or trend in auxiliary regression if noCONstant option is specified
    if "`constant'" != "" & ("`aotest'" == "" | "`trend'" == "") {
        if "`aotest'" == "" { local aotest "noaotest" }
        if "`trend'" == "" { local trend "notrend" }
    }
    
    if "`maxlag'" == "" {
        capture confirm integer number `maxlag'
    }
    else {
        capture confirm integer number `maxlag'
        if _rc {
            di in re "Noninteger value entered for lags"
            exit 198
        }
        else if `maxlag' < 0 {
            di in re "Maxlag must be a nonnegative integer"
            exit
        }
    }
    
    if "`lltc'" != "" & "`lagtest'" != "" {
        di in re "Error! The lltc and nolagtest options are mutually exclusive."
        exit 198
    }
    else if "`lltc'" != "" & "`lltc'" != "t" & "`lltc'" != "aic" & "`lltc'" !="sc" & "`lltc'" != "hq" {
        di in re `"Invalid lltc entry. Valid entries are "t", "aic", "sc", and "hq"."'
        exit
    }
    else if "`lltc'" == "" | "`lltc'" == "t" { local lagcrit = "Ng-Perron sequential-t test" }
    else if "`lltc'" == "aic" { local lagcrit = "Akaike information criterion" }
    else if "`lltc'" == "sc" { local lagcrit = "Bayesian Schwarz criterion" }
    else if "`lltc'" == "hq" { local lagcrit = "Hannan-Quinn criterion" }

    if `level' != 75 & `level' != 90 & `level' != 95 & `level' != 99 { 
        di in r "LEVel must be 75, 90, 95, or 99"
        exit 198
    }

    local generat = cond("`generate'" == "", "", "`generate'") 
    if "`generat'" != "" {
        capture confirm new variable `generat' 
        if _rc { 
            di in r "`generat' already exists: " _c  
            di in r "specify new variable with generate( ) option"
            exit 110 
        } 
    }

    marksample touse
    /* get time variables */
    _ts timevar, sort
    markout `touse' `timevar'
    tsreport if `touse', report
    if r(N_gaps) {
        di in red "sample may not contain gaps"
        exit
    }
    qui tsset
    local tv = r(timevar)
    local tmin = r(tmin)
    local tfmt = r(tsfmt)
    local tunit = r(unit1)
    
    tempvar y t useltest indicator

    qui gen byte `useltest' = `touse'      /* for use in lag testing */
    qui gen double `y' = `varlist'
    qui gen long `t' = sum(`touse')
    local numobs = `t'[_N]
    qui summ `touse', meanonly
    local totobs = r(N)
    if `touse' == 1 in 1 { local first = 1 }
    else {
        qui gen `indicator' =_n if `t' == 1     /* Thanks to Nick Winter */
        summ `indicator', meanonly
        local first `r(min)'
    }

    local kmax = "user"
    if "`maxlag'" == "" {
        /* set maxlag via Schwert criterion (Ng/Perron JASA 1995) */
        local maxlag = int(12*(`numobs'/100)^0.25)
        local kmax = "Schwert criterion"
    }
    local ml1 = `maxlag' + 1
    
    local mac
    local dt = "None"
    if "`constant'" == "" {
        local mac = "c"
        local dt = "Constant"
    }
    if "`trend'" == "" {
      local trd = "t"
        local mac = "ct"
        local dt = "`dt' + trend"
    }

    local size = (100 - `level')    /* set test size */

    local ol = ""
    local numol = 0
    if "`aotest'" == "" {

        tempvar obsno dtao

        gen `obsno' = _n
        gen byte `dtao' = 0     /* dummy var for each observation in outlier test */

        /* Get critical value for outlier test */
        GetCritO `level' `trend'
        local CVO = r(CVO)

        local stop = 0      /* stop flag for while loop 0=false; 1=true */

        /* In the code that follows, because outliers are dropped from the sample and the regression is run 
           again over the remaining observations, you need to distinguish between the observation number of the 
           outlier in the full sample, which is stored in the local macro `outlier', and the observation number 
           in the current sample (i.e., the full sample less the dropped observations), which is stored in the 
           local macro `currobs'. */

        preserve

        /* find outliers */
        while !`stop' {
            local tau = 0           /* t-statistic */
            local tausup = 0        /* supremum of t-statistics */
            local outlier = 0
            forv i = `first'/`numobs' {
                qui {
                    replace `dtao' = 1 in `i'
                    reg `y' `dtao' ``trd'' if `touse'       /* See equation (10) on p. 241 in Vogelsang */
                }
                local tau = abs(_b[`dtao'] / _se[`dtao'])
                if (`tau' > `CVO') & (`tau' > `tausup') {
                    local currobs = `i'
                    local outlier = `obsno' in `currobs'
                    local tausup = `tau'
                }
                qui replace `dtao' = 0 in `i'
            } /* end forv */
            if `outlier' != 0 {
                local numol = `numol' + 1                   /* number of outliers found */
                local ol "`ol' `outlier'"                   /* list of outlier observation numbers */
                local date`outlier' = `tv' in `currobs'     /* date of current outlier */
                if "`tfmt'" == "%ty" {
                    local dl "`dl' `date`outlier''"         /* list of all outlier dates */
                }
                else {
                    local odate : di `tfmt' `date`outlier'' /* convert numeric date to string -- Nick Cox */
                    local dl "`dl' `odate'"
                }
                local tau`outlier' = `tausup'
                qui drop in `currobs'
                local numobs = `numobs' - 1
           }
            else { local stop 1 }
        } /* while */

        restore

        /* Create dummy variables for use in ADF regression */
        foreach outlier of local ol {
            tempvar d`outlier'
            qui gen byte `d`outlier'' = (`outlier' == _n)   /* =1 if outlier, 0 otherwise -- Nick Cox */
        }
    } /* end if "`aotest'" */

    /* Sequential lag-length test */

    if "`lagtest'" == "" {
        markout `useltest' L(1/`ml1').`tv'      /* ensures each loop of lag test uses same number of obs; */
        local lOpt  = .
        local bRMSE = .
        local b`lltc' = .
        forv i = `maxlag'(-1)0 {
            local ml1 = `i' + 1
            if "`ol'" != "" {   /* changed */
                local dumvars
                foreach outlier of local ol {
                    local dumvars "`dumvars' L(0/`ml1').`d`outlier''"
                }
                if `i' != 0 { qui reg D.`y' L.`y' DL(1/`i').`y' `dumvars' ``trd'' if `useltest' }
                else { qui reg D.`y' L.`y' `dumvars' ``trd'' if `useltest' }
            }
            else if `i' != 0 { qui reg D.`y' L.`y' DL(1/`i').`y' ``trd'' if `useltest' }
            else { qui reg D.`y' L.`y' ``trd'' if `useltest' }
            local rmse`i' = sqrt(e(rss)/e(N))
            if "`lltc'" == "" | "`lltc'" == "t" {
                if `i' != 0 {
                    local tprob`i' = tprob(e(df_r),_b[DL`i'.`y']/_se[DL`i'.`y'])
                    if `tprob`i'' < `size'/100 {
                        local lOpt = `i'
                        local rmse`i' = `rmse`i''
                        local bRMSE = `rmse`lOpt''
                        continue, break
                    }
                }
                else {
                    local lOpt = `i'
                    local rmse`i' = `rmse`i''
                    local bRMSE = `rmse`i''
                }
            } /* end sequential-t */
            else {
                if "`lltc'" == "aic" { local aic`i' = log(`rmse`i''^2) + 2 * e(df_m) / e(N) }
                else if "`lltc'" == "sc" { local sc`i' = log(`rmse`i''^2) + e(df_m) * log(e(N)) / e(N) }
                else { local hq`i' = log(`rmse`i''^2) + 2 * e(df_m) * log(log(e(N))) / e(N) }
                local lOpt = cond(``lltc'`i'' < `b`lltc'',`i',`lOpt')
                local b`lltc' = min(`b`lltc'',``lltc'`i'')
                local bRMSE = `rmse`lOpt''
            } /* end information criteria */
        } /* end forv */
        if `lOpt' > 0 {
            local ml1 = `lOpt' + 1
            /* Following code corrects omitted dummy variables bug */
            if "`ol'" != "" {
                local dumvars
                foreach outlier of local ol {
                    local dumvars "`dumvars' L(0/`ml1').`d`outlier''"
                }
            }
        }
    } /* end lag-length testing */

    else {
        local lOpt = `maxlag'
        local ml1 = `lOpt' + 1
        if "`ol'" != "" {   /* changed */
            foreach outlier of local ol {
                local dumvars "`dumvars' L(0/`ml1').`d`outlier''"
            }
        }
    }

    /* Run ADF regression over all usable observations with dummies for additive outliers (if required); see 
       equation (9) on p. 240 in Vogelsang (1999). */

    qui {
        if "`ol'" != "" {   /* changed */
            if `lOpt' > 0 {
                reg D.`y' L.`y' DL(1/`lOpt').`y' `dumvars' ``trd'' if `touse', `constant'
            }
            else {
                reg D.`y' L.`y' `dumvars' ``trd'' if `touse', `constant'
            }
        }
        else if `lOpt' > 0 {
            reg D.`y' L.`y' DL(1/`lOpt').`y' ``trd'' if `touse', `constant'
        }
        else {
            reg D.`y' L.`y' ``trd'' if `touse', `constant'
        }
        if "`generat'" != "" { qui predict double `generat', r }
    }
    
    local Zt = _b[L.`y']/_se[L.`y']
    local rho = 1 + _b[L.`y']
    local N = e(N)

    /* Get DF critical values */
    if "`constant'" == "noconstant" { GetCritNC `N' `lOpt' }
    else if "`trend'" == "notrend" { GetCritC `N' `lOpt' }
    else { GetCritCT `N' `lOpt' }

    if `lOpt' != 0 { local aug "A" }

    /* Display output */

    /* Determine start and end date for sample */
    if `first' <= `ml1' { local tmin = `tmin' + `ml1' }
    else { local tmin = `tmin' + `first' - 1 }
    local tmax = `tmin' + `N' - 1

    local tmins : di `tfmt' `tmin'
    tokenize `tmins'                     /* Get rid of extra spaces in tmins */
    local tmins "`*'"
    local tmaxs : di `tfmt' `tmax'
    tokenize `tmaxs'                     /* Get rid of extra spaces in tmaxs */
    local tmaxs "`*'"
    
    local tlen = length("`varlist'") + length("`tmins'") + length("`tmaxs'") + 36
    local llen = length("`varlist'") + 18
    local blen = 78 - `tlen' + 1
    local col = `llen' + `blen'
    if `col' == 53 { local space = 5 }
    else { local space = 6 }

    di
    if "`aotest'" == "" {
        di in gr _col(17) "`aug'DF test for a unit root with additive outliers"
    }
    else {
        di in gr _col(28) "`aug'DF test for a unit root"
    }
    di
    di in gr "Variable tested : " in ye "`varlist'" _col(`col') /*
        */ in gr "Time Period : " in ye "`tmins'" in gr " to " in ye "`tmaxs'"
    di in gr "Maxlag = " in ye "`maxlag' " in gr "chosen by " in ye "`kmax'" /*
        */ _col(`col') in gr "# obs = " _col(73) in ye %6.0g `N'
    di in gr "Deterministic terms : " in ye "`dt'" _col(`col') /*
        */ in gr "# outliers = " _col(73) in ye %`space'.0g `numol'
    di _n in smcl in gr _col(32) /*
        */ "{hline 7} Response Surface Critical Values {hline 6}"
    di in gr _col (19) "Test" /*
        */ _col(32)  "1% Critical" /*
        */ _col(50)  "5% Critical" /*
        */ _col(67) "10% Critical"
    di in gr _col (16) "Statistic" /*
        */ _col(36)  "Value" /*
        */ _col(54)  "Value" /*
        */ _col(72)  "Value"
    di in gr in smcl "{hline 78}"

    di in gr " Z(t)" /*
    */ _col(15) in ye %10.3f `Zt' /*
        */ _col(33) %10.3f r(resp01) /*
        */ _col(51) %10.3f r(resp05) /*
        */ _col(69) %10.3f r(resp10)
    
    di in gr in smcl "{hline 78}"

    /* Get MacKinnon p-value */
    local pval
    if "`mac'" != "" {
      MacP `mac' 1 `Zt'
      local pval = r(p)
    }

    if "`pval'" != "" {
        di in gr "MacKinnon approximate p-value for Z(t) = " /*
                */ in ye %6.4f `pval'
        return scalar p = `pval'
    }

    if "`lagtest'" == "" {
        di in gr "Opt Lag (`lagcrit') = " in ye %2.0f `lOpt' _col(22) in gr /*
            */ " with RMSE  = " in ye %9.0g `bRMSE'
    }

    /* Display table of outliers and statistics */

    if "`aotest'" == "" {
        if "`ol'" != "" {
            #d ;
            di ; di ; di ;
            #d cr
            di in gr _col(9) "Outlier" /*
                */ _col(23) "Name of Test" /*
                */ _col(46) "Test" /*
                */ _col(59) %2.0f `size' "% Critical"
            di in gr _col(10) "Date" /*
                */ _col(24) "Statistic" /*
                */ _col(43) "Statistic" /*
                */ _col(63) "Value"
            di in gr _col(9) in smcl "{hline 62}"
            foreach outlier of local ol {
                if "`tunit'" == "y" { local col = 10 }
                else { local col = 9 }
                local odate : di `tfmt' `date`outlier''
                tokenize `odate'
                di in ye _col(`col') "`*'" /*
                    */ _col(25) "tau`outlier'" /*
                    */ _col(42) %10.3f `tau`outlier'' /*
                    */ _col(61) %10.3f `CVO'
            }
            di in gr _col(9) in smcl "{hline 62}"
            di in gr _col(9) "Outliers listed in order found, from most "/*
                */ "to least significant"
            if "`regres'" == "" { di }
        }
        else {
            di in gr "No outliers detected"
        }
    }

    /* This section of code comes from the DispReg program in dfuller.ado
       Some modifications by author */
    if "`regress'" != "" {
        di
        di
        di in smcl in gr "{hline 13}{c TT}{hline 64}"
        di in smcl in gr abbrev("`varlist'",12) _col(14) "{c |}" /*
            */ _col(21) "Coef." _col(29) "Std. Err." _col(44) "t" /*
            */ _col(49) "P>|t|" _col(59) "[`level'% Conf. Interval]"
        di in smcl in gr "{hline 13}{c +}{hline 64}"
        di in smcl in gr abbrev("`varlist'",12) _col(14) "{c |}"
        local vv "L1.`y'"
        local bv "_b[`vv']"
        local sv "_se[`vv']"
        if `bv'/`sv' == . {
            di in smcl in gr _col(11) "L1 {c |}" %11s in ye "(dropped)"
        }
        else {
            di in smcl in gr _col(11) "L1 {c |}" in ye /*
                */ _col(17) %9.0g `bv' /*
                */ _col(28) %9.0g `sv' /*
                */ _col(38) %8.2f `bv'/`sv' /*
                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
        }
        if `lOpt' >= 1 {
            local vv "LD.`y'"
            local bv "_b[`vv']"
            local sv "_se[`vv']"
            if `bv'/`sv' == . {
                di in smcl in gr _col(11) "LD {c |}" %11s in ye "(dropped)"
            }
            else {
                di in smcl in gr _col(11) "LD {c |}" in ye /*
                    */ _col(17) %9.0g `bv' /*
                    */ _col(28) %9.0g `sv' /*
                    */ _col(38) %8.2f `bv'/`sv' /*
                    */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                    */ _col(58) %9.0g `bv' + invttail(`e(df_r)',/*
                    */ `level'/100)*`sv' /*
                    */ _col(70) %9.0g `bv' - invttail(`e(df_r)',/*
                    */ `level'/100)*`sv'
            }
        } /* end if lOpt >=1 */
        forval i = 2/`lOpt' {
            local vv "L`i'D.`y'"
            local bv "_b[`vv']"
            local sv "_se[`vv']"
            if `bv'/`sv' == . {
                di in smcl in gr _col(11) "L`i'D {c |}" %11s in ye "(dropped)"
            }
            else {
                di in smcl in gr %12s "L`i'D" " {c |}" in ye /*
                    */ _col(17) %9.0g `bv' /*
                    */ _col(28) %9.0g `sv' /*
                    */ _col(38) %8.2f `bv'/`sv' /*
                    */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                    */ _col(58) %9.0g `bv' + invttail(`e(df_r)',/*
                    */ `level'/100)*`sv' /*
                    */ _col(70) %9.0g `bv' - invttail(`e(df_r)',/*
                    */ `level'/100)*`sv'
            }
        } /* end forval i = 2/lOpt */
        if "`ol'" != "" {   /* changed */
            foreach outlier of local ol {
                /* Display statistics for contemporaneous dummy */
                di in smcl in gr abbrev("d`outlier'",12) _col(14) "{c |}"
                local vv "`d`outlier''"
                local bv "_b[`vv']"
                local sv "_se[`vv']"
                if `bv'/`sv' == . {
                    di in smcl in gr _col(11) "-- {c |}" %11s in ye "(dropped)"
                }
                else {
                    di in smcl in gr _col(11) "-- {c |}" in ye /*
                        */ _col(17) %9.0g `bv' /*
                        */ _col(28) %9.0g `sv' /*
                        */ _col(38) %8.2f `bv'/`sv' /*
                        */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                        */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                        */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
                }
                /* Display statistics for L1.dummy */
                local vv "L.`d`outlier''"
                local bv "_b[`vv']"
                local sv "_se[`vv']"
                if `bv'/`sv' == . {
                    di in smcl in gr _col(11) "L1 {c |}" %11s in ye "(dropped)"
                }
                else {
                    di in smcl in gr _col(11) "L1 {c |}" in ye /*
                        */ _col(17) %9.0g `bv' /*
                        */ _col(28) %9.0g `sv' /*
                        */ _col(38) %8.2f `bv'/`sv' /*
                        */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                        */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                        */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
                }
                if `lOpt' > 1 {
                    forval i = 2/`ml1' {
                        local vv "L`i'.`d`outlier''"
                        local bv "_b[`vv']"
                        local sv "_se[`vv']"
                        if `bv'/`sv' == . {
                            di in smcl in gr %12s "L`i'" " {c |}" %11s in ye "(dropped)"
                        }
                        else {
                            di in smcl in gr %12s "L`i'" " {c |}" in ye /*
                                */ _col(17) %9.0g `bv' /*
                                */ _col(28) %9.0g `sv' /*
                                */ _col(38) %8.2f `bv'/`sv' /*
                                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                                */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                                */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
                        }
                    } /end forval i */
                } /* end if lOpt > 1 */
            } /* end foreach outlier */
        } /* end if outliers */
        if "`constant'" == "" {
            if "`trend'" == "" {
                local vv "``trd''"
                local bv "_b[`vv']"
                local sv "_se[`vv']"
                di in smcl in gr "_trend" _col(14) "{c |}" in ye /*
                    */ _col(17) %9.0g `bv' /*
                    */ _col(28) %9.0g `sv' /*
                    */ _col(38) %8.2f `bv'/`sv' /*
                    */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                    */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                    */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
            } /* end if trend */
            local vv "_cons"
            local bv "_b[`vv']"
            local sv "_se[`vv']"
            di in smcl in gr "_cons        {c |}" in ye /*
                */ _col(17) %9.0g `bv' /*
                */ _col(28) %9.0g `sv' /*
                */ _col(38) %8.2f `bv'/`sv' /*
                */ _col(48) %6.3f tprob(e(df_r),`bv'/`sv') /*
                */ _col(58) %9.0g `bv' + invttail(`e(df_r)',`level'/100)*`sv' /*
                */ _col(70) %9.0g `bv' - invttail(`e(df_r)',`level'/100)*`sv'
        } /* end if constant */
        di in smcl in gr "{hline 13}{c BT}{hline 64}"
    } /* end if regress */

    /* Return data */
    return scalar Zt = `Zt'
    return scalar rho = `rho'
    return scalar lags = `lOpt'
    return scalar maxlag = `maxlag'
    return scalar N = `N'
    if "`lagtest'" == "" {
        if "`lltc'" == "" | "`lltc'" == "t" {
            forv i = `maxlag'(-1)`lOpt' { return scalar rmse`i' = `rmse`i'' }
            if `lOpt' > 0 {
                forv i = `maxlag'(-1)`lOpt' { return scalar tprob`i' = `tprob`i'' }
            }
            else {
                forv i = `maxlag'(-1)1 { return scalar tprob`i' = `tprob`i'' }
            }
        }
        else {
            forv i = `maxlag'(-1)0 { return scalar rmse`i' = `rmse`i'' }
            forv i = `maxlag'(-1)0 { return scalar `lltc'`i' = ``lltc'`i'' }
        }
    }
    if "`ol'" != "" {   /* changed */
        tokenize `ol'
        forv i = `numol'(-1)1 { return scalar tau``i'' = `tau``i''' }
        if "`ol'" != "" {
            tokenize `dl'
            return local outliers "`*'"
            return scalar numol = `numol'
        }
    }
end

program define GetCritO, rclass

/* CVs for outlier detection test
   CVs from table II on p. 241 in Vogelsang (1999)
   CV for test size = 25% is interpolated */

    args lvl tr
    local size = 100 - `lvl'
    if "`tr'" == "notrend" {
        if `size' == 1 { local CVO = 3.55 }
        else if `size' == 5 { local CVO = 3.13 }
        else if `size' == 10 { local CVO = 2.93 }
        else { local CVO = 2.72 } /* Test Size = 25% */
    }
    else {
        if `size' == 1 { local CVO = 3.72 }
        else if `size' == 5 { local CVO = 3.31 }
        else if `size' == 10 { local CVO = 3.11 }
        else { local CVO = 2.92 } /* Test Size = 25% */
    }
    return scalar CVO = `CVO'
end

program define GetCritNC, rclass

/* response surface values for ADF test from Cheung and Lai JBES 1995 Table 1, cols 2-4 and eq (3)
   10%, 5%, and 1% CVs for no constant, no trend */

    args N k
    tempname rsc
    mat `rsc' = ( -1.609, -0.285,  - 4.090, 0.321, -0.525 \ /*
    */            -1.931, -1.289,  - 5.719, 0.380, -0.722 \ /*
    */            -2.564, -2.906,  -29.773, 0.599, -1.580 )
    
    local n1 = 1.0/`N'
    local kt1 = (`k'- 1) / `N'

    local cr10 = `rsc'[1,1] + `rsc'[1,2]*`n1' + `rsc'[1,3]*(`n1'^2) + /*
    */ `rsc'[1,4]*`kt1' + `rsc'[1,5]*(`kt1'^2)
    local cr05 = `rsc'[2,1] + `rsc'[2,2]*`n1' + `rsc'[2,3]*(`n1'^2) + /*
    */ `rsc'[2,4]*`kt1' + `rsc'[2,5]*(`kt1'^2)
    local cr01 = `rsc'[3,1] + `rsc'[3,2]*`n1' + `rsc'[3,3]*(`n1'^2) + /*
    */ `rsc'[3,4]*`kt1' + `rsc'[3,5]*(`kt1'^2)

    return scalar resp10 = `cr10'
    return scalar resp05 = `cr05'
    return scalar resp01 = `cr01'
end

program define GetCritC, rclass

/* response surface values for ADF test from Cheung and Lai JBES 1995 Table 1, cols 5-7 and eq (3)
   10%, 5%, and 1% CVs for constant, no trend */

    args N k
    tempname rsc
    mat `rsc' = ( -2.566, -1.319,  -15.086, 0.667, -0.650 \ /*
    */            -2.857, -2.675,  -23.558, 0.748, -1.077 \ /*
    */            -3.430, -4.959,  -72.303, 0.842, -2.090 )
    
    local n1 = 1.0/`N'
    local kt1 = (`k'- 1) / `N'

    local cr10 = `rsc'[1,1] + `rsc'[1,2]*`n1' + `rsc'[1,3]*(`n1'^2) + /*
    */ `rsc'[1,4]*`kt1' + `rsc'[1,5]*(`kt1'^2)
    local cr05 = `rsc'[2,1] + `rsc'[2,2]*`n1' + `rsc'[2,3]*(`n1'^2) + /*
    */ `rsc'[2,4]*`kt1' + `rsc'[2,5]*(`kt1'^2)
    local cr01 = `rsc'[3,1] + `rsc'[3,2]*`n1' + `rsc'[3,3]*(`n1'^2) + /*
    */ `rsc'[3,4]*`kt1' + `rsc'[3,5]*(`kt1'^2)

    return scalar resp10 = `cr10'
    return scalar resp05 = `cr05'
    return scalar resp01 = `cr01'
end

program define GetCritCT, rclass

/* response surface values for ADF test from Cheung and Lai JBES 1995 Table 1, cols 8-10 and eq(3)
   10%, 5%, and 1% CVs for constant and trend */

    args N k
    tempname rsct
    mat `rsct' = ( -3.122, -2.850,  -15.813, 0.907, -0.804 \ /*
    */             -3.406, -4.060,  -40.552, 1.021, -1.501 \ /*
    */             -3.958, -7.448, -104.947, 1.327, -3.753)
    
    local n1 = 1.0/`N'
    local kt1 = (`k'- 1) / `N'

    local cr10 = `rsct'[1,1] + `rsct'[1,2]*`n1' + `rsct'[1,3]*(`n1'^2) + /*
    */ `rsct'[1,4]*`kt1' + `rsct'[1,5]*(`kt1'^2)
    local cr05 = `rsct'[2,1] + `rsct'[2,2]*`n1' + `rsct'[2,3]*(`n1'^2) + /*
    */ `rsct'[2,4]*`kt1' + `rsct'[2,5]*(`kt1'^2)
    local cr01 = `rsct'[3,1] + `rsct'[3,2]*`n1' + `rsct'[3,3]*(`n1'^2) + /*
    */ `rsct'[3,4]*`kt1' + `rsct'[3,5]*(`kt1'^2)

    return scalar resp10 = `cr10'
    return scalar resp05 = `cr05'
    return scalar resp01 = `cr01'
end

/* MacP taken from dfuller.ado */
program define MacP, rclass
    args type vars tau

    local stype = lower("`type'")
    if "`stype'"=="c" { local type 0 }
    else              { local type 1 }

    local g3=0
        local min=.
    local max=.
    if `type'==0 {  /* no trend */
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
    else if `type'==1 { /* linear trend */
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
exit 
