*! version 2.2.0 JMGarrett 13Aug00
/* Bootstrap sw linear or logistic regression; count variables selected  */
/* Form:  swboot yvar xvarlist, reps(#) options                          */
/* Options allowed:  reps(#), pe(#), pr(#), forward, N(#) model roc gof  */

program define swboot
  version 6.0
  #delimit ;
    syntax varlist (min=2) [if] [in], [Reps(int 1) N(int 0) PE(real .05)
    PR(real .1) FORward MODel ROC GOF] ;
  #delimit cr
  marksample touse
  markout `touse'
  preserve
  quietly keep if `touse'
  keep `varlist'
  local yvar="`1'"
  local varlbly : variable label `yvar'
  capture assert `yvar'==1 | `yvar'==0
  if _rc==0 {local regtype "log"}
  if _rc~=0 {local regtype "lin"}

* Read in x variables
  tokenize "`varlist'"
  local i=1
  while "`2'"~=""  {
    local x`i'="`2'"
    * quietly drop if `x`i''==.  /* do not need this? */
    local xvars `xvars' `x`i''
    local count`i'=0
    local i=`i'+1
    macro shift
    }
  local numx=`i'-1
  if `n'~=0 {local sample=`n'}
  if `n'==0 {local sample=_N}

* select bootstrap sample and run stepwise regressions
  if "`forward'"=="forward" {local forprnt="(Forward Selection)"}
  local numreps=1
  tempfile tempds
  disp "  "
  if "`regtype'"=="lin" {
    #delimit ;
       disp _n(1) in gre "Model:" in gre "    Stepwise " in blue "Linear "
         in gre "Regression `forprnt'" ;
       disp in gre "Outcome:" in gre "  `varlbly' -- " in yel "`yvar'";
       disp _n(1) in gre  "Options:  pr=" in yel "`pr'" in green "  pe="
          in yel "`pe'" in green "  n=" in yel "`sample'" ;
    #delimit cr
    disp "  "
    }
  if "`regtype'"=="log" {
    #delimit ;
       disp _n(1) in gre "Model:" in gre "    Stepwise " in blue "Logistic "
         in gre "Regression `forprnt'" ;
       disp in gre "Outcome:" in gre "  `varlbly' -- " in yel "`yvar'";
       disp _n(1) in gre  "Options:  pr=" in yel "`pr'" in green "  pe="
          in yel "`pe'" in green "  n=" in yel "`sample'" ;
    #delimit cr
    disp "  "
    }
    if `n'>_N  {
      disp in red "There are only " in yel _N in red " available " /*
        */ "observations for this model;"
      }
  while `numreps'<=`reps'  {
    quietly save `tempds', replace
    bsample `sample'
    if "`regtype'"=="lin" {
       if "`forward'"=="" {
         quietly sw regress `yvar' `xvars', pe(`pe') pr(`pr')
         }
       if "`forward'"=="forward" {
         quietly sw regress `yvar' `xvars', pe(`pe') pr(`pr') forward
         }
       }
    if "`regtype'"=="log" {
       if "`forward'"=="" {
         quietly sw logistic `yvar' `xvars', pe(`pe') pr(`pr')
         }
       if "`forward'"=="forward" {
         quietly sw logistic `yvar' `xvars', pe(`pe') pr(`pr') forward
         }
       if "`roc'"=="roc" {
          quietly lroc, nograph
          local arearoc=round(r(area),.0001)
          }
       if "`gof'"=="gof" {
          quietly lfit, group(10)
          local pval=round(chiprob(r(df),r(chi2)),.0001)
          }
       }
    mat b=e(b)
    local keepX : colnames(b)
    tokenize `keepX'
    local i 1
    local xlist ""
    while "`1'"~="_cons"  {
      local keepx`i'="`1'"
      local xlist `xlist' `keepx`i''
      local i=`i'+1
      macro shift
      }
    local numkeep=`i'-1

    * If model is requested, create dataset to hold and print estimates
    if "`model'"=="model"  {
      drop _all
      mat b=b'
      mat v=e(V)
      mat v=vecdiag(v)
      mat v=v'
      mat bv=b,v
      set more off
      quietly svmat bv
      set more on
      quietly gen str8 varname=" "
      quietly drop if _n==_N
      quietly gen se=sqrt(bv2)
      quietly rename bv1 coef
      local i 1
        while `i'<=`numkeep' {
          quietly replace varname="`keepx`i''" if _n==`i'
          local i=`i'+1
          }
      if "`regtype'"=="lin"  {
         quietly gen t=coef/se
         quietly gen p=tprob(`sample'-2,t)
         format coef se p t %10.4f
         disp " "
         disp in blue "Rep `numreps':"
         list varname coef se p, noob 
        }
      if "`regtype'"=="log"  {
         quietly gen OR=exp(coef)
         quietly gen lower=exp(coef-1.96*se)
         quietly gen upper=exp(coef+1.96*se)
         quietly gen z=abs(coef/se)
         quietly gen p=2*(1-normprob(z))
         format OR lower upper %6.2f
         format se p %7.4f
         disp _n(1) in blue "Rep `numreps':"
         list varname OR se p lower upper, noob
         disp " "
         if "`roc'"=="roc" {
           disp in gr "      Area under ROC curve     = " in yel `arearoc'
           }
         if "`gof'"=="gof" {
           disp in gr "      Goodness-of-fit test:  p = " in yel `pval'
           }
         }
      }

    * If model is not selected, print a summary of variables for each rep
    if "`model'"==""  {
       if "`roc'"=="roc" | "`gof'"=="gof"  {disp "  "}
       disp in gr "Rep `numreps':" in yel "  `xlist'"
       if "`roc'"=="roc" & "`regtype'"=="log" {
          disp in gr "          Area under ROC curve   =   " in yel `arearoc'
          }
       if "`gof'"=="gof" {
          disp _s(1) in gr "         Goodness-of-fit test:  p = " in yel `pval'
          }
       }

    * Count the number of times each variable is selected
    local i 1
    while `i'<=`numx'  {
      local j 1
      while `j'<=`numkeep'  {
        if "`x`i''"=="`keepx`j''"  {local count`i'=`count`i''+1}
        local j=`j'+1
        }
      local i=`i'+1
      }
    quietly use `tempds', clear
    local numreps=`numreps'+1
    }
  
* if last rep
  local i=1
  disp _n(2) in green "Summary: (Number of times each variable is selected)"
  disp in green "----------------------------------------------------"
  while `i'<=`numx' {
    disp "   `x`i'':" _col(15) "`count`i''"
    local i=`i'+1
    }
end
