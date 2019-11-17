program define pantest2
* Requires name of time variable as 1st argument
*
*! Version 1.0.2
*! 10/09/98
*
* Various diagnostic tests in fixed effects panel regression.
* (1) Test for serial correlation of residuals [See B.H. Baltagi
*     "Econometric analysis of panel data" (Wiley, 1995), pp. 93-100].
* (2) F test for significance of fixed effects [Baltagi (1995), p.12]
* (3) Test for normality of residuals
*
  version 5.0
  if "`1'"=="" {
    dis in red "Name of time variable required as 1st argument"
    exit
  }
  confirm variable `1'
  if "$S_E_cmd2"~="xtreg_fe" {
     dis "last command was not xtreg ..., fe"
     error 301
    }
  tempname np LM LM5 see see1 N T nobs chi URSS K
  tempvar e ee ee1 sumee sumee1 smpl
*
  scalar `T'=   S_E_nobs/S_E_n
*   Actually, this is 'Tbar' if panel is unbalanced
  scalar `N'=   S_E_n
  scalar `nobs'=S_E_nobs
  scalar `URSS'=S_E_sse
*  "Unrestricted Residual Sum of Squares" from within regression
  scalar `K' =  $S_E_dfb
*   No of RHS variables, excluding constant & fixed effects
  local depvar  $S_E_depv
  local rhsvl   $S_E_vl
  local id      $S_E_ivar
*
* (1) Test for serial correlation in residuals
*
  qui {
  xtpred `e', e
  sort `id' `1'
  gen `ee'=`e'*`e'
  gen `sumee'=sum(`ee')
  drop `ee'
  scalar `see'=`sumee'[_N]
  drop `sumee'
  gen `ee1'=`e'*`e'[_n-1] if `id'==`id'[_n-1]
    /* omit 1st obs on each unit */
  gen `sumee1'=sum(`ee1')
  drop `ee1'
  scalar `see1'=`sumee1'[_N]
  drop `sumee1'
  scalar `LM'=`N'*`T'*(`T'/(`T'-1))*((`see1'/`see')^2)
*   strictly, valid only for balanced panel
  scalar `LM5'=sqrt(`LM')
*   strictly, valid only for balanced panel
  scalar `chi'=chiprob(1,`LM')
  scalar `np'=1-normprob(abs(`LM5'))
  }
*
  dis _newline
  dis in gr "Test for serial correlation in residuals"
  dis in gr "Null hypothesis is either that rho=0 if residuals are AR(1)"
  dis in gr "or that lamda=0 if residuals are MA(1)"
  if $S_E_Tcon==0 /*
   */ {dis in gr "Following tests only approximate for unbalanced panels" }
  dis in gr "LM= " in ye `LM'
  dis in gr "which is asy. distributed as chisq(1) under null, so:"
  dis in gr "Probability of value greater than LM is " in ye `chi'
  dis in gr "LM5= " in ye `LM5'
  dis in gr "which is asy. distributed as N(0,1) under null, so:"
  dis in gr "Probability of value greater than abs(LM5) is " in ye `np'
  dis _newline
*
* (2) Test for significance of fixed effects [Baltagi (1995), p.12].
*
  tempname F RRSS
  quietly {
  fit `depvar' `rhsvl'
  scalar `RRSS'=_result(4)
  scalar `F'=((`RRSS'-`URSS')/(`N'-1))/(`URSS'/(`nobs'-`N'-`K'))
  }
  dis in gr "Test for significance of fixed effects"
  dis in gr "F= " in ye `F'
  dis in gr "Probability>F= " in ye fprob(`N'-1,`nobs'-`N'-`K',`F')
  dis _newline
*
* (3) Test for normality of residuals
*
  dis in gr "Test for normality of residuals"
  sktest `e'
  dis _newline
*
end
