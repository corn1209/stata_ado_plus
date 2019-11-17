*! version 1.0.0  24feb1997
program define rfregk
        version 4.0
        local options "Level(integer $S_level) OLD"
        if (substr("`1'",1,1)=="," | "`*'"=="") {
                if "$S_E_cmd2"~="xtreg_re" { error 301 }
                parse "`*'"
        }
        else {
                local options "`options' I(string)"
                local varlist "req ex"
                local if "opt"
                local weight "aweight"
                parse "`*'"

                xt_iis `i'
                local ivar "$S_1"

                tempname T Tbar s_e s_u theta Bf VCEf n T_new
                tempvar touse dup T_i XB U tmp
                mark `touse' [`weight'`exp'] `if'
                markout `touse' `varlist' `ivar'
                qui count if `touse'
                if _result(1)<3 {
                        error cond(_result(1)==0,2000,2001)
                        /*NOTREACHED*/
                }
                sort `ivar' `touse'
                preserve
                qui keep if `touse'
                if "`weight'"!="" {
                        tempvar w
                        qui gen double `w' `exp'
                        local origexp "`exp'"
                        local exp "=`w'"
                        qui keep `varlist' `ivar' `w'
                }
                else {
                        qui keep `varlist' `ivar'
                        local w 1
                }

                quietly {
                                        /* obtain fixed-effects estimates */
                        ffxreg2 `varlist' [`weight'`exp'], i(`ivar')
                        * scalar `s_e' = _result(9)
                        scalar `s_e' = sqrt(scalar(S_E_sse)/$S_E_tdf)
                        matrix `Bf' = get(_b)
                        matrix `VCEf' = get(VCE)
                        restore, preserve
                        keep if `touse'
                        if "`weight'"!="" {
                                tempvar w
                                gen double `w' `origexp'
                                local exp "=`w'"
                                keep `varlist' `ivar' `w'
                        }
                        else {
                                keep `varlist' `ivar'
                                local w 1
                        }

                                                /* count T_i            */
                        by `ivar': gen long `T_i'=_N if _n==_N
                        summ `T_i'
                        scalar `T' = _result(6)

if "`old'"!="" { scalar `Tbar' = _result(3) }

                        if `T'==_result(5) {            /* min=max, constant */
                                local T_cons 1
                                local consopt "hascons"
                                drop `T_i'
                        }
                        else {
                                local T_cons 0
                                local consopt "nocons"
                                by `ivar': replace `T_i'=_N
                        }

if "`old'"=="" {
by `ivar' : gen double `T_new' = 1/_N if _n==_N
summ `T_new'
scalar `Tbar' = 1/_result(3)
drop `T_new'
}

                                                /* create averages      */
                        by `ivar': gen byte `dup' = cond(_n==_N,2,1)
                        expand `dup'
                        sort `ivar' `dup'
                        by `ivar': replace `dup'=cond(_n<_N,0,1)
                                                /* dup=0,1; 1->mean obs */

                        parse "`varlist'", parse(" ")
                        local i 1
                        while "``i''"!="" {
                                if "`weight'"!="" {
                                        by `ivar': replace ``i'' = /*
                                        */
cond(`dup',sum(`w'[_n-1]*``i''[_n-1])/s
um(`w'[_n-1]),``i'')
                                }
                                else {
                                        by `ivar': replace ``i'' = /*
                                        */
cond(`dup',sum(``i''[_n-1])/(_n-1),``i'
')
                                }
                                local i=`i'+1
                        }

                                        /* obtain between-effects estimates */
                        regress `varlist' if `dup'
                        scalar `n' = _result(1)
                        scalar `s_u' = sqrt((_result(9)^2) - `s_e'^2/`Tbar')

                                        /* obtain theta                   */
                        if `s_u'==. {
                                scalar `s_u' = 0
                                if `T_cons' {
                                        scalar `theta' = 0
                                }
                                else    gen byte `theta' = 0
                        }
                        else {
                                if `T_cons' {
                                        scalar `theta' = /*
                                        */ 1-`s_e'/sqrt(`T'*`s_u'^2+`s_e'^2)
                                }
                                else {
                                        by `ivar': gen double `theta' = /*
                                        */ 1-`s_e'/sqrt(`T_i'*`s_u'^2+`s_e'^2)
                                }
                        }

                                /* obtain random-effects estimates      */
                        local i 1
                        while "``i''"!="" {
                                by `ivar': replace ``i''= /*
                                        */ ``i''-`theta'*``i''[_N] if !`dup'
                                local i=`i'+1
                        }
                        drop if `dup'
                        gen float constant = 1-`theta'
                        regress `varlist' constant [`weight'`exp'], `consopt'
                }
                tempname mdf chi2 B V
                local   depv  = "`1'"
                local   nobs  = _result(1)
                scalar `mdf'  = _result(3) - cond(`T_cons',0,1)
                scalar `chi2' = _result(6) * `mdf'

                mat `B' = get(_b)
                mat `V' = get(VCE)
                if `T_cons'==1 {
                        local cols = colsof(`B') - 1
                        mat `B' = `B'[1,1..`cols']
                        mat `V' = `V'[1..`cols',1..`cols']
                }
                else    local cols = colsof(`B')
                local names : colnames(`B')
                parse "`names'", parse(" ")
                local `cols' "_cons"
                mat colnames `B' = `*'
                mat rownames `V' = `*'
                mat colnames `V' = `*'
                mat post `B' `V', depname(`depv') obs(`nobs')

                if `T_cons'==0 {
                        parse "`varlist'", parse(" ")
                        mac shift
                        qui test `*'
                        scalar `chi2' = _result(6)
                }

                matrix S_E_bf = `Bf'
                matrix drop `Bf'
                matrix S_E_Vf = `VCEf'
                matrix drop `VCEf'

                local `cols'
                global S_E_vl "`*'"
                local names
                global S_E_depv "`depv'"
                global S_E_if "`if'"

                scalar S_E_ui = `s_u'
                scalar S_E_eit = `s_e'
                global S_E_ivar "`ivar'"

                scalar S_E_nobs = `nobs'
                scalar S_E_T = `T'
                scalar S_E_Tbar = `Tbar'
                global S_E_Tcon   `T_cons'
                scalar S_E_n = `n'
                scalar S_E_mdf = `mdf'
                scalar S_E_chi2 = `chi2'

                if $S_E_Tcon {
                        scalar S_E_thta = `theta'
                }
                else quietly {
                        by `ivar': replace `theta'=. if _n!=_N
                        summ `theta', d
                        matrix S_E_thta = J(1,5,0)
                        matrix S_E_thta[1,1] = _result(5)       /* min */
                        matrix S_E_thta[1,2] = _result(7)       /* 5%  */
                        matrix S_E_thta[1,3] = _result(10)      /* med */
                        matrix S_E_thta[1,4] = _result(13)      /* 95% */
                        matrix S_E_thta[1,5] = _result(6)       /* max */
                }

                quietly {
                        restore

                        if "`weight'"!="" {
                                tempvar w
                                gen double `w' `origexp'
                                local exp "=`w'"
                        }
                        else {
                                local w 1
                        }

                                        /* obtain R^2 overall   */
                        predict double `XB' if `touse'
                        corr `XB' $S_E_depv [`weight'`exp']
                        scalar S_E_r2o = _result(4)^2

                                        /* obtain R^2 between */

                                by `ivar' `touse': gen double `U' = /*
                                        */ cond(_n==_N & `touse', /*
                                        */ sum(`w'*`XB')/sum(`w'), .)

                                by `ivar' `touse': gen double `tmp' = /*
                                        */ cond(_n==_N & `touse', /*
                                        */ sum(`w'*$S_E_depv)/sum(`w'), .)
                        corr `U' `tmp'
                        scalar S_E_r2b = _result(4)^2

                                /* obtain R^2 within */
                        by `ivar' `touse': replace `U' = `XB'-`U'[_N]
                        by `ivar' `touse': replace `tmp'=$S_E_depv-`tmp'[_N]
                        corr `U' `tmp' [`weight'`exp']
                        scalar S_E_r2w = _result(4)^2

                        drop `U' `tmp'


                }
                global S_E_cmd2 "xtreg_re"
                global S_E_cmd "xtreg"
        }
        di _n in gr _col(50) "Random-effects GLS regression"

        if $S_E_Tcon {
                local Twrd "    T"
        }
        else    local Twrd "T-bar"

        #delimit ;
        di in gr
        "sd(u_$S_E_ivar)" _col(30) "= " in ye %9.0g scalar(S_E_ui) in gr
                _col(56) "Number of obs =" in ye %8.0f scalar(S_E_nobs) ;

        di in gr
        "sd(e_${S_E_ivar}_t)" _col(30) "= " in ye %9.0g scalar(S_E_eit) in gr
                _col(68) "n =" in ye %8.0f scalar(S_E_n) ;


        di in gr
                "sd(e_${S_E_ivar}_t + u_$S_E_ivar)" _col(30) "= " in ye
                %9.0g sqrt(scalar(S_E_eit^2+S_E_ui^2)) in gr
                _col(64) "`Twrd' =" in ye %8.0g scalar(S_E_Tbar) ;

        di _n in gr
                "corr(u_$S_E_ivar, X)" _col(30) "=  " in ye "0"
                in gr " (assumed)"
                _col(56) "R-sq within   =" in ye %8.4f scalar(S_E_r2w) ;

        #delimit cr
        di in gr _col(61) "between  =" in ye %8.4f scalar(S_E_r2b)
        di in gr _col(61) "overall  =" in ye %8.4f scalar(S_E_r2o)

        if $S_E_Tcon {
                di in gr _n /*
                */ _col(56) "chi2(" /*
                */ %3.0f scalar(S_E_mdf) ")     =" in ye %8.2f scalar(S_E_chi2)
                di in gr "(theta =" in ye %7.4f scalar(S_E_thta) in gr ")" /*
                */ _col(56) _c
        }
        else {
                di in gr _dup(19) "-" " theta " _dup(20) "-"
                di in gr "  min      5%       median        95%      max" /*
                */ _col(56) "chi2(" /*
                */ %3.0f scalar(S_E_mdf) ")     =" in ye %8.2f scalar(S_E_chi2)
                di in ye %6.4f S_E_thta[1,1] %9.4f S_E_thta[1,2] /*
                */ %11.4f S_E_thta[1,3] %11.4f S_E_thta[1,4] /*
                */ %9.4f S_E_thta[1,5] in gr /*
                */ in gr _col(56) _c
        }

        di in gr /*
                */ /* in gr _col(56) */ "  Prob > chi2 =" /*
                */ in ye %8.4f scalar(chiprob(S_E_mdf,S_E_chi2))  _n

        mat mlout, level(`level')
end


/*
        ffxreg2:
                ffxreg2 varlist, i(ivar)
                defines mse, b and covariance matrix
                no syntax checking
                may corrupt data in memory.
*/
program define ffxreg2
        version 4.0
        local varlist "req ex"
        local options "I(string)"
        local weight "aweight"
        parse "`*'"
        parse "`varlist'", parse(" ")
        local ivar `i'

        tempvar x tmp w
        tempname sst sse

        if "`weight'"!="" {
                gen double `w'`exp'
        }
        else {
                local w 1
        }

        quietly {
                sort `ivar'

                summ `1' [`weight'`exp']
                scalar `sst' = (_result(1)-1)*_result(4)

                while ("`1'"!="") {
                        by `ivar': gen double `x' = sum(`w'*`1')/sum(`w')
                        summ `1' [`weight'`exp']
                        by `ivar': replace `1' = `1' - `x'[_N] + _result(3)
                        drop `x'
                        mac shift
                }

                count if `ivar'!=`ivar'[_n-1]
                local dfa = _result(1)-1

                regress `varlist' [`weight'`exp']
                local nobs = _result(1)
                local dfb = _result(3)
                scalar `sse' = _result(4)
                local dfe = _result(5) - `dfa'
                if `dfe'<=0 | `dfe'==. { noi error 2001 }

                * we could avoid this if only we knew dfe in advance
                regress `varlist' [`weight'`exp'], dof(`dfe')
                scalar S_E_sse = `sse'
                global S_E_mdf = `dfa' + `dfb'
                global S_E_tdf = `nobs'-1-$S_E_mdf
        }
end
