*! 1.0.1 NJC 11 May 1999 
* 1.0.0 NJC 3 March 1999
program define cistat
        version 6.0
        #delimit ;
        syntax varlist(numeric) [if] [in] [aweight fweight]
        [ , BY(varname) Matname(str) Format(str)
        Exposure(varname) Binomial Poisson Level(int $S_level) Total * ] ;
        #delimit cr
        tokenize `varlist'

        if "`total'" != "" & "`by'" == "" {
                di "by( ) option required with total"
                exit 198
        }

        local nvars : word count `varlist'

        if `nvars' > 1 & ("`by'" != "" | "`total'" != "") {
                di in r "too many variables specified"
                exit 103
        }

        if "`exposure'" != "" { local exposur "e(`exposure')" }

        if "`by'" != "" {
                local bylab : value label `by'
                qui tab `by' `if' `in', miss
                local nobs = _result(2) + ("`total'" == "total")
        }
        else local nobs = `nvars'

        if `nvars' > _N {
                tempvar orig
                gen byte `orig' = 1
                qui set obs `nvars'
        }
        local extra = "`orig'" != ""

        tempvar touse a group id n mean se llimit ulimit which

        qui {
                gen long `which' = _n
                compress `which'
                gen str1 `n' = ""
                if "`exposure'" == "" { label var `n' "n" }
                else label var `n' "exposure"
                gen `mean' = .
                label var `mean' "mean"
                gen `se' = .
                label var `se' "se"
                gen `llimit' = .
                label var `llimit' "lower limit"
                gen `ulimit' = .
                label var `ulimit' "upper limit"
        }

        if "`matname'" != ""  { mat `matname' = J(`nobs',5,0) }

        local I = 1
        qui while "`1'" != "" {
                mark `touse' `if' `in'
                markout `touse' `1'

                sort `touse' `by' `1'
                by `touse' `by' : gen `group' = _n == 1 if `touse'
                by `touse' `by' : gen `id' = _n if `touse'
                replace `group' = sum(`group')
                local max = `group'[_N]
                count if !`touse'
                local J = 1 + r(N)
                local j = 1

                while `j' <= `max' {
                        count if `group' == `j'
                        local obs = r(N)
                        ci `1' [`weight' `exp'] if `group' == `j', /*
                         */ `exposure' `binomial' `poisson' l(`level')
                        replace `n' = "$S_1" if `which' == `I'
                        replace `mean' = $S_3 if `which' == `I'
                        replace `se' = $S_4 if `which' == `I'
                        replace `llimit' = $S_5 if `which' == `I'
                        replace `ulimit' = $S_6 if `which' == `I'

                        if "`matname'" != "" {
                                mat `matname'[`I',1] = $S_1
                                mat `matname'[`I',2] = $S_3
                                mat `matname'[`I',3] = $S_4
                                mat `matname'[`I',4] = $S_5
                                mat `matname'[`I',5] = $S_6
                        }

                        if "`by'" != "" {
                                local name = `by'[`J']
                                if "`name'" == "" | "`name'" == "." {
                                        local name "missing"
                                }
                                else if "`bylab'" != "" {
                                        local name : label `bylab' `name'
                                }
                        }
                        else local name "`1'"
                        label def which `I' "`name'", modify
                        local name = substr("`name'",1,8)
                        local name : subinstr local name " " "_", all 
                        local rnames "`rnames' `name'"

                        local I = `I' + 1
                        local J = `J' + `obs'
                        local j = `j' + 1
                }

                mac shift
                if `nvars' > 1 { drop `touse' `id' `group' }
        }

        qui if "`total'" == "total" {
                ci `varlist' [`weight' `exp'] if `touse', /*
                */ `exposure' `binomial' `poisson' l(`level')
                replace `n' = "$S_1" if `which' == `I'
                replace `mean' = $S_3 if `which' == `I'
                replace `se' = $S_4 if `which' == `I'
                replace `llimit' = $S_5 if `which' == `I'
                replace `ulimit' = $S_6 if `which' == `I'
                label def which `I' "total", modify
                if "`matname'" != "" {
                        mat `matname'[`I',1] = $S_1
                        mat `matname'[`I',2] = $S_3
                        mat `matname'[`I',3] = $S_4
                        mat `matname'[`I',4] = $S_5
                        mat `matname'[`I',5] = $S_6
                }
                local I = `I' + 1
        }

        if "`matname'" != "" {
                if "`exposure'" != "" {
                	mat colnames `matname' = /*
			*/ exposure mean se llimit ulimit
                }
                else  mat colnames `matname' = n mean se llimit ulimit

                mat rownames `matname' = `rnames' `total'
        }

        label val `which' which
        if "`by'" != "" { label var `which' "Group" }
        else label var `which' "Variable"

        if "`format'" == "" { local format "%9.3f" }

        di
        di in g /*
    */ %~79s "Means, standard errors and `level'% confidence intervals" _c

        tabdisp `which' if `which' < `I', /*
        */  c(`n' `mean' `se' `llimit' `ulimit') f(`format') miss `options'

        label drop which
        if `extra' { qui keep if `orig' == 1 }
end

