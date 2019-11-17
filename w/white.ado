
*! 1.0.2  17 May 97  (Jeroen Weesie/ICS)

* White omnibus heteroscedasticity test (Judge et al 1985:453)
* help for -white- is contained in -htest.hlp-

program define white
    version 5.0

    /* -fit- saves required information in the following macros  
        S_E_vl            yvar/xvars
        S_E_in            in-range
        S_E_if            if-expression
        S_E_wgh S_E_exp   type-of-weights, weighting-expression
    */    
 
    if "$S_E_cmd" != "reg" { 
        di in re "White's homoscedasticity test is only possible after /// 
-fit-"         exit 301
    }

    if "$S_E_wgh" == "aweight" {
        di in re "-white- currently is not appropriate with analytical 
weights"         exit
    }

  * parse options 

    local options "Preserv"
    parse "`*'"

    parse "$S_E_vl", p(" ")
    local lhs "`1'"
    mac shift
    local rhs "`*'"
    local nrhs : word count `rhs'
    
    tempvar res touse

    mark `touse' $S_E_in $S_E_if [$S_E_wgh $S_E_exp]
    if "$S_E_wgh" != "" {
        tempvar wght
        quietly gen `wght' = $S_E_exp if `touse'
    }

  * keep only variables/observations needed lateron
 
    if "`preserv'" != "" {
        preserve
        quietly keep if `touse'
        quietly keep $S_E_vl `touse' `wght'
    }

  * verify constraints on matsize 

    local matreq = (`nrhs'*`nrhs' + 3*`nrhs')/2 + 3     
    local matsize : set matsize
    if `matsize' < `matreq' {
        if "`preserv'" != "" {
            drop _all
            set matsize `matreq'
            restore, preserve
        }
        else {
            * preserve anyway to reset matsize
            preserve
            drop _all
            set matsize `matreq'
            restore, preserve
        }
    }        
 
  * create temporary variates x(i)*x(j) i=1..n, j=1..i

    parse "`rhs'", p(" ")
    local k 0
    local i 1
    while `i' <= `nrhs' {
        local j 1
        while `j' <= `i' {
            local k = `k'+1
            tempvar x`k'
            quietly gen `x`k'' = (``i'') * (``j'') if `touse'
            local rhs2 "`rhs2' `x`k''"
            local j = `j'+1
        }
        local i = `i'+1
    }

  * compute and display statistic 
    
    * quietly fit
    quietly predict `res' if `touse', res
    quietly replace `res' = `res'^2  if `touse'

    * ensure that the estimate results of -fit- are not changed
    tempname est
    estimates hold `est'
    
    quietly reg `res' `rhs' `rhs2' [$S_E_wgh `wght'] if `touse'
    scalar S_1 = _result(1)*_result(7) /* #obs * R^2 */
    scalar S_2 = _result(3)-1          /* mdf - 1 */
    
    estimates unhold `est' 

  * display results

    di in gr "White's test for Ho: homoscedasticity" _n /*
        */   "         against Ha: unrestricted heteroscedasticity" _n

    di in gr _col(5) "test statistic W = " _col(28) in ye %9.0g S_1 
    di in gr _col(5) "Pr(chi2(" in ye S_2 in gr ") > W)" _col(22) /*
                       */ "=" _col(31) in ye %6.4f chiprob(S_2,S_1)
end        
