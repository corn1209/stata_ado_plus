*! Program to calculate effects
*! Michael Hills 1/5/2002
*! version 3.0.0


program define effects1 
version 7.0
syntax [if] [in] [, Display LEVel(integer $S_level)]
marksample touse
markout `touse' $ef_res $ef_exp $ef_mod $ef_fup $ef_con

tempvar resp

cap drop _A*
cap drop _B*
cap drop _N*
cap drop _I*

/* sets up a dummy wt macro */

global ef_wt 

/* sets up a local variable for the response */

qui gen `resp' = $ef_res

/* lists basic summary of attributes */

di as text "Response variable is: " in ye "$ef_res" in gr " type "in ye "$ef_typ"
if "$ef_fup" != "" {
    di as text "Follow-up time variable is: " in ye "$ef_fup"
}
di as text "Exposure variable is: " in ye "$ef_exp "/*
*/ in gr " which is"in ye " `$ef_exp[type]'"
if "$ef_mod"!="" {
    di as text "Modifier variable is: " in ye "$ef_mod "/*
    */ in gr "which is"in ye " `$ef_mod[type]'"
}

/* setting up the model */

if "$ef_typ"=="metric"{
    if $ef_sca==1 {
        global ef_nam "regress"
        di as text "Effects measured as " in ye "differences in means"
    }
    if $ef_sca==2 {
        global ef_nam "glm"
        global ef_opt "family(gaussian) link(log)"         
        di as text "Effects measured as " in ye "ratios of means"
    }
}

if "$ef_typ"=="binary" & $ef_mcc==1 {
    di as text "Matched set variable is    " in ye "$ef_mvar"
    global ef_sca 4
    global ef_nam "clogit"
    global ef_opt "group($ef_mvar)"
    di as text "Effects measured as " in ye "odds ratios"
}

if "$ef_typ"=="binary" & $ef_mcc == 0 {
    if $ef_sca==3 {
        global ef_nam "logit"
        di as text "Effects measured as " in ye "odds ratios"
    }
    if $ef_sca==2 {
        global ef_nam "binreg"
        global ef_opt "rr"
        di as text "Effects measured as " in ye "ratios of proportions"
    }
    if $ef_sca==1 {
        global ef_nam "binreg"
        global ef_opt "rd"
        di as text "Effects measured as " as res "differences of proportions"/*
	*/ as text " per " as res $ef_perc
    }
}
if "$ef_typ"=="failure" | "$ef_typ"=="count" {
    if $ef_sca==2 {
        global ef_nam "poisson"
        global ef_opt "e($ef_fup)"
        di as text "Effects measured as " in ye "rate ratios"
    }
    if $ef_sca==1 {
        global ef_nam "glm"
        qui replace `resp' = `resp'/$ef_fup*$ef_pery
        global ef_wt [iw=$ef_fup/$ef_pery]
        global ef_opt "fam(poisson) link(identity)"
        di as text "Effects measured as " as res "rate differences" as text " per "/*
        */ as res $ef_pery
    }
}

/* Sets up indicators for exposure and modifier */    

if "`$ef_exp[type]'"=="categorical" {
    qui inspect $ef_exp
    if r(N_unique)==1 {
        di as error "categorical exposure must have two or more levels"
        exit
    }
    local a = r(N_unique)
    qui tab $ef_exp, gen(_A)
}

if "`$ef_exp[type]'"=="metric" {
    local a 2
}
local b 0
if "$ef_mod" != "" {
    if "`$ef_mod[type]'"=="categorical" {
        qui inspect $ef_mod
        if r(N_unique)==1 {
            di as error "categorical modifier must have two or more levels"
            exit
        }
        local b = r(N_unique)
        qui tab $ef_mod, gen(_B)
    }
    if "`$ef_mod[type]'"=="metric" {
        local b 1
    }
}


/* sets length (num) of showat */

if "$ef_sho" == "" {
    local num    3
}
else {
numlist "$ef_sho"
tokenize "`r(numlist)'"
local num = 0
    while "`1'" != "" {
        local num = `num' + 1
        mac shift
    }
}

if "$ef_mod"!="" & "`$ef_mod[type]'"=="metric" {
    local b = `num'
}

/* sets up the control terms */

global ef_con1 ""
global ef_con2 ""

if "$ef_con" != "" {
tokenize "$ef_con"
    while "`1'" != "" {
        global ef_con1 "$ef_con1 `1'"
        if "``1'[type]'" == "categorical" {
             qui inspect `1'
             if r(N_unique)>15 {
                 di as error "More than 15 values for a categorical confounder"
	 di as text "Should it be declared as metric?"
                 exit             
             }
             qui tab `1', gen(_I`1')
             drop _I`1'1
             global ef_con2 "$ef_con2 _I`1'*" 
        }
        else {
            global ef_con2 "$ef_con2 `1'"
        }
    mac shift
    }
    tokenize "$ef_con"
    local conlist ""
    while "`1'" != "" {
        local conlist "`conlist' `1'"
        mac shift
    }
}

if "`$ef_exp[type]'"=="categorical" {
    di as text _n(1) "Effect(s) of " in ye "$ef_exp" 
}
else {
    di as text _n(1) "Effect per " in ye "$ef_peru" in gr " unit(s) of "/*
    */ in ye "$ef_exp" 
}
if "`conlist'" != "" {
    di as text "Controlled for " as res    "`conlist'" 
}

/* Builds up a list of variables to include in the regression */
/* first deals with case where a modifier variable is specified */
    
if "$ef_mod"!="" {
    if "`$ef_exp[type]'"=="categorical" & "`$ef_mod[type]'"=="categorical" {
        local vnames ""
        local i = 2
        while `i' <= `a' {
            local j = 1
            while `j' <= `b' {
                qui gen _N`i'`j' = _A`i' * _B`j'
                local vnames "`vnames' _N`i'`j'"
                local j = `j' + 1
            }
            local i=`i'+1
        }
        local j=2
        while `j'<=`b' {
            local vnames    "`vnames' _B`j'"
            local j=`j'+1
        }
    }
    if "`$ef_exp[type]'"=="metric" & "`$ef_mod[type]'"=="categorical" {
        local vnames ""
        local j = 1
        while `j' <= `b' {
            qui gen _N`j' = $ef_exp * _B`j'
            local vnames "`vnames' _N`j'"
            local j = `j' + 1
        }
        local j=2
        while `j'<=`b' {
            local vnames "`vnames' _B`j'"
            local j=`j'+1
        }
    }
    if "`$ef_exp[type]'"=="categorical" & "`$ef_mod[type]'"=="metric" {
        local vnames ""
        local i = 2
        while `i' <= `a' {
            qui gen _N`i' = _A`i' * $ef_mod
            local vnames "`vnames' _N`i'"
            local i = `i' + 1
        }
        local i=2
        while `i'<=`a' {
            local vnames "`vnames' _A`i'"
            local i=`i'+1
        }
        local vnames "`vnames' $ef_mod"
    }
    if "`$ef_exp[type]'"=="metric" & "`$ef_mod[type]'"=="metric" {
        qui gen _N11 = $ef_exp * $ef_mod
        local vnames "_N11 $ef_exp $ef_mod"
    }

/* Does regression using the list of variable */

    qui $ef_nam `resp' `vnames' $ef_con2 if `touse' $ef_wt, $ef_opt
    di as text _n(1) "Number of records used: " in ye e(N) in gr " out of " in ye _N

/* retrieves any variables which have been dropped in the estimation
*/

    qui _undrop `vnames' $ef_con2, b(bsave) v(vsave)
}

/* now deals with case where no modifier variable is specified */

else {
    if "`$ef_exp[type]'"=="metric" {local vnames $ef_exp}
    else {
        local vnames 
        local i=2
        while `i'<=`a' {
            local vnames "`vnames' _A`i'"
            local i=`i'+1
        }
    }

    qui $ef_nam `resp' `vnames'    $ef_con2 if `touse' $ef_wt, $ef_opt
    di as text _n(1) "Number of records used: " in ye e(N) in gr " out of " in ye _N
    qui _undrop    `vnames'    $ef_con2, b(bsave) v(vsave)

}

/* output the results according to command used if verbose is specified */

if $ef_ver==1 {
        di    in gr "Number of parameters estimated    " in ye e(df_m)+1
        di    in gr "Log likelihood     " in ye %12.6f e(ll)


    if e(cmd)=="regress" {
        di    in gr "Residual SE  " in ye %12.4f e(rmse) in gr " on"/*
	*/ in ye %5.0f e(df_r) in gr " df"
    }
}

    if e(cmd)=="regress" {
        local mult = invttail(e(df_r),`level'*0.005+0.5)
    }
    else {
        local mult = invnorm(`level'*0.005+0.5)
    }

tempvar metmod

/* if a modifier variable is specified, sets up contrast matrix C */    

if "$ef_mod"!="" {
    if "`$ef_mod[type]'"=="categorical" {
        cmat1, a(`a') b(`b') base($ef_bas)
    }
    else {
        cmat2, a(`a') b(`b') base($ef_bas) showat("$ef_sho")
    } 

/* sets up the number of effects (e) in output */

    if "`$ef_exp[type]'"=="categorical" {
        local e=(`a'-1)*`b'
    }
    else {
        local e=`b'
    }
    if "`$ef_mod[type]'"=="metric" {
        local e=2*(`a'-1)
    }

/* retrieves the matrices created in fit and transforms by C */
    
    mat b = bsave[1,1..`e']
    mat v = vsave[1..`e',1..`e']
    mat b = b*C'
    mat v = C*v*C'
    mat v = vecdiag(v)

/* outputs the effects and CI's */

    local i = 1
    local fst = 1
    local lst = `b'

/* tokenizes the values taken by the modifier if categorical */
/* uses p25 p50 p75 if metric */

    while `i' <= `a' {
        if "`$ef_mod[type]'"=="categorical" {
            qui vallist $ef_mod, label
            tokenize "$S_1"
        }
        else {
            if    "$ef_sho" != "" {
                numlist "$ef_sho"
                tokenize "`r(numlist)'"
            }
            else {tokenize "p25 p50 p75"}
        }

        if `i' != $ef_bas {
            if "`$ef_exp[type]'"=="categorical"    {
                di as text _n(1) "Level " in ye `i' in gr/*
		*/ " vs level " in ye $ef_bas in gr " of "/*
		*/ in ye "$ef_exp"_n(1)
            }
            mat bb = b[1,`fst'..`lst']
            mat vv=v[1,`fst'..`lst']
            local j = 1
            di as text _n(1) "Level or value"
            di as text "of " in ye "$ef_mod" _col(31) in gr "Effect"/*
            */_col(40) "`level'% Confidence Interval" _n(1)
            while `j' <= `b' {
	        /*suppresses output if a parameter was dropped in the estimation command*/		    
                if vv[1,`j'] > 0 {
                    if $ef_sca==1 {
	                local scale 1
			if "$ef_typ" == "binary" {local scale = $ef_perc}
			if $ef_exm == 1 {local scale = `scale' * $ef_peru}
			local low = (bb[1,`j'] - `mult' *sqrt(vv[1,`j']))*`scale'
			local high = (bb[1,`j'] + `mult' *sqrt(vv[1,`j']))*`scale'
			local effect = bb[1,`j']*`scale'
			di in ye "`1'" in ye _col(30) %7.4f `effect' "     [ "%5.3f `low' " , " %5.3f `high' " ]"
		    }                    
                    if $ef_sca>1 {
	                if $ef_exm == 1 {
                            local effect = exp(bb[1,`j']*$ef_peru)
                            local low = exp((bb[1,`j'] - `mult' *sqrt(vv[1,`j']))*$ef_peru )
                            local high = exp((bb[1,`j'] + `mult' *sqrt(vv[1,`j']))*$ef_peru )
                            di in ye "`1'" in ye _col(30) %7.4f `effect'/*
			    */ "     [ "%5.3f `low' " , " %5.3f `high' " ]"
			}
	                if $ef_exm == 0 {
                            local effect = exp(bb[1,`j'])
                            local low = exp(bb[1,`j'] - `mult' *sqrt(vv[1,`j']))
                            local high = exp(bb[1,`j'] + `mult' *sqrt(vv[1,`j']))
                            di in ye "`1'" in ye _col(30) %7.4f `effect'/*
			    */ "     [ "%5.3f `low' " , " %5.3f `high' " ]"
	                }
                    }
                }
*                else {
*                    di "`1'" _col(30) "(dropped)"
*                }
            local j = `j'+1
            mac shift
            }
            local fst = `fst' + `b'
            local lst = `lst' + `b'
        }
    local i = `i' + 1
    }
}

/* deals with case of no strata */
  
else {
    cmat1 , a(`a') b(1) base($ef_bas)
    mat b = bsave[1,1..`a'-1]
    mat v = vsave[1..`a'-1,1..`a'-1]
    mat b = b*C'
    mat v = C*v*C'
    mat v = vecdiag(v)
    local i 1
    local j 1
            if "`$ef_exp[type]'"=="categorical" {
                di as text _n(1) _col(25) "Effect" _col(35)/*
	*/ "`level'% Confidence Interval" _n(1)
            }
            else {
                di as text _n(1) _col(25) "Effect" _col(35)/*
	*/ "`level'% Confidence Interval" _n(1)
            }

    while `i' <= `a' {
        if `i' != $ef_bas {

	    /*supresses output if parameter was dropped in the estimation command*/

            if v[1,`j'] > 0 {
                if $ef_sca==1 {
	            local scale 1
	            if "$ef_typ" == "binary" {local scale = $ef_perc}
	            if $ef_exm == 1 {local scale = `scale' * $ef_peru}
                    local low = (b[1,`j'] - `mult' *sqrt(v[1,`j']))*`scale'
                    local high = (b[1,`j'] + `mult' *sqrt(v[1,`j']))*`scale'
                    local effect = b[1,`j']*`scale'
	            if $ef_exm==1 {
                        di in ye _col(25) %7.4f `effect' /*
	                */ "     [ "%5.3f `low' " , " %5.3f `high' " ]"
	            }     
                    if $ef_exm==0 {
	                di as text "Level " in ye `i' in gr " vs level " in ye /*
	                */ $ef_bas in ye _col(25) %7.4f `effect'/*
	                */ "     [ "%5.3f `low' " , " %5.3f `high' " ]"
	            }    
                }
                if $ef_sca>1 {
	            local scale 1
	            if $ef_exm == 1 {local scale = $ef_peru}
                    local effect = exp(b[1,`j']*`scale')
                    local low = exp((b[1,`j'] - `mult' *sqrt(v[1,`j']))*`scale')
                    local high = exp((b[1,`j'] + `mult' *sqrt(v[1,`j']))*`scale')
	            if $ef_exm == 0 {
                        di as text "Level " in ye `i' in gr " vs level " in ye /*
	                */ $ef_bas in ye _col(25) %7.4f `effect'/*
	                */ " [ "%5.3f `low' " , " %5.3f `high' " ]"
	            }
	            if $ef_exm==1 {
                        di in ye _col(25) %7.4f `effect' /*
	                */ "     [ "%5.3f `low' " , " %5.3f `high' " ]"
	            }
                }
            }
            else {
                di    _col(25) "(dropped)"
            }
        local j = `j' +1
        }
    local i = `i'+1
    }
}

/* carries out the effect modification test by fitting the model */
/* in the standard form, and testing interactions */

if "$ef_mod"!="" {
    local e=substr("$ef_exp",1,3)
    local s=substr("$ef_mod",1,3)
    if "`$ef_exp[type]'"=="categorical" & "`$ef_mod[type]'"=="categorical" {
        qui xi:$ef_nam `resp' i.$ef_exp*i.$ef_mod $ef_con2 if `touse' $ef_wt, $ef_opt
        qui testparm _I`e'X*
    }
    if "`$ef_exp[type]'"=="categorical" & "`$ef_mod[type]'"=="metric" {
        qui xi:$ef_nam `resp' i.$ef_exp*$ef_mod $ef_con2 if `touse' $ef_wt, $ef_opt
        qui testparm _I`e'X*
    }
    if "`$ef_exp[type]'"=="metric" & "`$ef_mod[type]'"=="categorical" {
        qui xi:$ef_nam `resp' i.$ef_mod*$ef_exp $ef_con2 if `touse' $ef_wt, $ef_opt
        qui testparm _I`s'X*
    }
    if "`$ef_exp[type]'"=="metric" & "`$ef_mod[type]'"=="metric" {
        qui gen `metmod' = $ef_exp*$ef_mod
        qui xi:$ef_nam `resp' $ef_exp $ef_mod `metmod' $ef_con2 if `touse' $ef_wt, $ef_opt
        qui testparm `metmod'
    }
        di    in gr _n(1) "Overall test for effect modification"
        if e(cmd) == "regress" {
            di    in gr "F(" in ye %2.0f r(df) "," %3.0f r(df_r) in gr ")" "     = " in ye %7.3f r(F)
        }
        else {
            di    in gr "chi2(" in ye %3.0f r(df)    in gr ")" "     = " in ye %7.3f r(chi2)
        }
        di as text "P-value       = " in ye %7.3f r(p)
}

if "$ef_mod"=="" {
    di as text _n(1) "Test for no effects"
    di ""

    if "`$ef_exp[type]'"=="categorical" {
        qui xi:$ef_nam `resp' i.$ef_exp $ef_con2 if `touse' $ef_wt, $ef_opt
        local expos = substr("$ef_exp",1,8)
        local expos = "_I`expos'*"
        qui testparm    `expos'
        if "$ef_nam"=="regress" {
            di    in gr "F(" in ye %2.0f r(df) " , " %5.0f r(df_r)    in gr ")" "     = " in ye %7.3f r(F)
            di as text "P-value           = " in ye %7.3f r(p)
        }
        else {
            di    in gr "chi2(" in ye %3.0f r(df)    in gr ")" "     = " in ye %7.3f r(chi2)
            di as text "P-value      = " in ye %7.3f r(p)
        }
    }

    if "`$ef_exp[type]'"=="metric" {
        qui xi:$ef_nam `resp' $ef_exp $ef_con2 if `touse' $ef_wt, $ef_opt
        qui testparm    $ef_exp
        if "$ef_nam"=="regress" {
            di as text "F(" in ye %2.0f r(df) " , " %5.0f r(df_r)    in gr ")" "     = "/*
            */ in ye %7.3f r(F)
            di as text "P-value           = " in ye %7.3f r(p)
        }
        else {
            di as text "chi2(" in ye %3.0f r(df)    in gr ")" "     = "/*
            */ in ye %7.3f r(chi2)
            di as text "P-value       = " in ye %7.3f r(p)
        }
    }
}

cap drop _A*
cap drop _B*
cap drop _N*
cap drop _I*

end




*! _undrop -- version 1.0 5 Feb 2000
*! Restore any parameters dropped by a regression command
program define _undrop
     version 6.0
     syntax varlist, B(string) V(string)
     local nv : word count `varlist'
     /* Coefficients estimated */
     matrix best = e(b)
     matrix Vest = e(V)
     local fn : colfullnames best
     /* Check if multiple equation model; if so get equation name */
     local first : word 1 of `fn'
     tokenize `first', parse(":")
     if "`1'"!="`first'" {
         local eqn "`1':"
     }
     /* Compute complete parameter list */
     local i = 1
     local j = 1
     local n = 0
     local new
     local old
     tokenize `fn'
     while "`1'"!="" {
         if `i'>`nv' {
             local new "`new' `1'"
             local old "`old' `j'"
             local j = `j' + 1
             di "`1'"
             mac shift
         }
         else {
             local next : word `i' of `varlist'
             local next "`eqn'`next'"
             if "`next'"=="`1'" {
                 local new "`new' `1'"
                 local i = `i' + 1
                 local old "`old' `j'"
                 local j = `j' + 1
                 mac shift
             }
             else {
                 local new "`new' `next'"
                 local old "`old' 0"
                 local i = `i'+ 1
                 local drop "T"
             }
         }
         local n = `n' + 1
     }
     /* If anything dropped, expand b, V */
     if "`drop'"!="" {
         local row : rowfullnames best
         matrix `b' = J(1,`n',0)
         matrix `v' = J(`n',`n',0)
         matrix rownames `b' = `row'
         matrix colnames `b' = `new'
         matrix rownames `v' = `new'
         matrix colnames `v' = `new'
         local i = 0
         while `i'<`n' {
             local i = `i'+1
             local ii : word `i' of `old'
             if `ii'!=0 {
                 matrix `b'[1,`i'] = best[1,`ii']
                 local j = 0
                 while `j'<`n' {
                     local j = `j'+1
                     local jj : word `j' of `old'
                     if `jj'!=0 {
                         matrix `v'[`i',`j'] = Vest[`ii',`jj']
                     }
                 }
             }
         }
     }
     else {
         matrix `b' = best
         matrix `v' = Vest
     }
     matrix drop best Vest
     end
*! cmat1 -- version 1.0 mh 7/4/2000
program define cmat1
version 7.0
syntax [, A(integer 1) B(integer 1) BASE(integer 1)]
/*
            p is the number of parameters used from the regression
*/    



local p = (`a'-1)*`b'

/*
            sets up (a-1)x(a-1) diagonal matrix of D's where D is diagonal unit
            matrix of size bxb
*/
mat C = I(`p')

/*
            if base > 1, replace D with -D in col (base-1)
*/
if $ef_bas > 1 {
    mat D=I(`b')
    mat Z=J(`b',`b',0)
    local i=1
    local row=1
    local col=($ef_bas-2)*`b'+1
    while `i'<`a' {
        mat C[`row',`col']=-D
        local i=`i'+1
        local row=`row'+`b'
    }
/*
            drop diagonal D's before the replaced column by b
*/
    local i=1
    local row=1
    while `i'<$ef_bas-1 {
        mat C[`row',`row']=Z
        mat C[`row'+`b',`row']=D
        local i=`i'+1
        local row=`row'+`b'
    }
}
/*
        Example with 4 levels of exposure, base=3

        D 0 0     D -D 0     0 -D 0
        0 D 0 ->0 _D 0 ->D -D 0
        0 0 D     0 -D 0     0 -D 0
*/
end

*! cmat2 -- version 1.0 mh 8/4/200
program define cmat2
version 7.0
syntax [, A(integer 1) B(integer 1) BASE(integer 1) SHOWAT(numlist)]
/*
            pp is the number of parameters used from the regression
            Dp is col matrix containing the percentiles of the modifier
            or the values in showat.
            D1 is a col vector of 1's and Z1 is a col vector of 0's, both
            same size as D.
*/

/*
            starts by building up Dp, D1, Z1 from percentiles of from showat
*/
if "`showat'" == "" {
    qui summ $ef_mod, detail
    mat Dp =(r(p25)\ r(p50)\ r(p75))
    mat D1=J(3,1,1)
    mat Z1=J(3,1,0)
}
else {
    tokenize "`showat'"
    mat Dp=real("`1'")
    mat D1=1
    mat Z1=0
    mac shift
    while "`1'" != "" {
        mat Dp=Dp\real("`1'")
        mat D1=D1\1
        mat Z1=Z1\0
        mac shift
    }
}
/*
            sets up C as a matrix of zeros and then converts it
*/    
local pp = (`a'-1)*`b' 
mat C = J(`pp',2*(`a'-1),0)

/*
            C = diag(Dp) diag(D1)
*/    
local row 1
local col 1
while `col' <= `a'-1 {
    mat C[`row',`col'] = Dp
    mat C[`row',`col'+`a'-1]=D1
    local row = `row' + rowsof(Dp)
    local col = `col' + 1
}
/*
            if base > 1, replace col base-1 in diag matrices with -Dp and -D1
*/    
if $ef_bas > 1 {
    local next    1
    while `next' < `pp' {
        mat C[`next',$ef_bas-1]=-Dp
        mat C[`next',$ef_bas+`a'-2]=-D1
        local next = `next' + rowsof(Dp)
    }
/*
            drop diagonal Dp's and D1's before the replaced column by one place
*/    
    local row=1
    local col=1
    while `col'<$ef_bas-1 {
        mat C[`row',`col']=Z1
        mat C[`row'+rowsof(Dp),`col']=Dp
        mat C[`row',`col'+`a'-1]=Z1
        mat C[`row'+rowsof(Dp),`col'+`a'-1]=D1
        local row=`row'+rowsof(Dp)
        local col=`col'+1
    }
}
/*
   Example with 4 levels of exposure, base=3

   Dp 0  0  D1 0  0     Dp -Dp  0  D1 -D1  0     0   -Dp  0  0   -D1  0
   0  Dp 0  0  D1 0  -> 0  -Dp  0  0  -D1  0  -> Dp  -Dp  0  D1  -D1  0
   0  0  Dp 0  0  D1    0  -Dp  0  0  -D1  D1    0   -Dp  0  0   -D1  0
*/
end

*! 2.0.1 NJC 4 Nov 1998
program define vallist
        version 5.0
        local varlist "max(1)"
        local if "opt"
        local in "opt"
        local options "Labels Sep(string) Max(int 0) Words Format(string)"
        parse "`*'"

        if "`format'" != "" { /* try out format */
                if substr("`format'",1,1) != "%" {
                        di in r "invalid %format"
                        exit 120
                }
                qui di `format' 1.23456789
        }
        if "`sep'" == "" { local sep " " }

        tempvar touse
        mark `touse' `if' `in'
        markout `touse' `varlist', strok

        capture confirm string variable `varlist'

        qui if _rc != 7 { /* string variable */
                tempvar counter
                sort `touse' `varlist'
                by `touse' `varlist' : /*
                 */ gen byte `counter' = 1 if _n == 1 & `touse'
                replace `counter' = sum(`counter') if `counter' < .
                su `counter', meanonly
                local nvals = _result(6)
                sort `counter'

                local i = 1
                while `i' <= `nvals' {
                        local val = trim(`varlist'[`i'])
                        if `max' {
                                local val = substr("`val'",1,`max')
                        }
                        if "`words'" != "" {
                                local end = index("`val'"," ") - 1
                                local val = substr("`val'",1,`end')
                        }
                        if `i' < `nvals' { local vals "`vals'`val'`sep'" }
                        else { local vals "`vals'`val'" }
                        local i = `i' + 1
                }
        }
        else { /* numeric variable */
                tempname Vals
                qui tab `varlist' if `touse', matrow(`Vals')
                local nvals = _result(2)
                local lblname : value label `varlist'

                local i = 1
                while `i' <= `nvals' {
                        local val = `Vals'[`i',1]
                        if "`labels'" != "" & "`lblname'" != "" {
                                local val : label `lblname' `val'
                                local val = trim("`val'")
                                if `max' {
                                        local val = substr("`val'",1,`max')
                                }
                                if "`words'" != "" {
                                        local end = index("`val'"," ") - 1
                                        local val = substr("`val'",1,`end')
                                }
                        }
                        else if "`format'" != "" {
                               local val : di `format' `val'
                        }
                        if `i' < `nvals' { local vals "`vals'`val'`sep'" }
                        else { local vals "`vals'`val'" }
                        local i = `i' + 1
                }
        }

        di in g "`vals'"
        global S_1 "`vals'"
end

