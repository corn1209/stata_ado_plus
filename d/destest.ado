*! version 2.3, 28Feb2001, J.Hendrickx@mailbox.kun.nl  (STB-61: dm73.3)
/*
Direct comments to: 

John Hendrickx <J.Hendrickx@mailbox.kun.nl>
Nijmegen Business School
University of Nijmegen
P.O. Box 9108
6500 HK Nijmegen
The Netherlands 

Desmat is available at 
http://baserv.uci.kun.nl/~johnh/desmat/stata/

Version 2.3, February 28 2001
moved the "incrmnt" subprogram below destest, for compatibility with version 7
Version 2.2, Sept 19
Use svytest for svy programs
Version 2.1, September 12, 2000
Added "using" option, write results to a tab delimited file
Version 2.0, Jun 30 2000
Added options for significance cutpoints, symbols, separation space,
number of decimal points. Can be specified using macro variables as in 
-desrep-. Output using option "joint" now in compact for as well
Version 1.1, April 3 2000
Compact results, no display of the variables being tested, asterisks to 
indicate significance
Version 1.0, October 27 1999

Program to be used in conjuction with desmat. Arguments are a list of model
terms to be tested. If no arguments are specified, all terms are tested.
An option "joint" can be specified to test for the joint siginficance of all
model terms.
An option "equal" can be specified to test for equality among the model terms.
*/

program define destest
  version 6.0

  * quit of not used after desmat
  if "$ncols" == ""  {
    display "destest is for use after using desmat and estimating a model"
    display "to perform tests on model terms"
    exit
  }

  * get the arguments and the options, watch out in case no arguments are
  * specified
  tokenize "`0'", parse(",")
  if "`1'" == "," {
    local opts `2'
  }
  else {
    local args `1'
    local opts `3'
  }

  local 0 ", `opts'"

  #delimit ;
  syntax [,  Joint Equal OUTRAW REPLACE
             ndec(numlist > 0 integer max=1)
             sigcut(numlist)
             sigsym(string)
             sigsep(numlist >=0 integer max=1) ];
  #delimit cr

  * options can be be specified as global macro variables,
  * overridden by the command string
  if "`ndec'"=="" {
    if "$D_NDEC" ~= "" {local ndec $D_NDEC }
    else {local ndec 3 }
  }
  if "`sigcut'" == "" {
    if "$D_SIGCUT" ~= "" {local sigcut $D_SIGCUT }
    else {local sigcut ".05 .01" }
  }
  if "`sigsym'" == "" {
    if "$D_SIGSYM" ~= "" {local sigsym $D_SIGSYM }
    else {local sigsym "* **" }
  }
  if "`sigsep'" == "" {
    if "$D_SIGSEP" ~= "" {local sigsep $D_SIGSEP }
    else {local sigsep 0}
  }
  * add trailing space for checking
  local zero "`0' "
  if "$D_RAW" ~= "" & index(lower("`zero'"),"outraw ") == 0 {
    local outraw "$D_RAW"
  }
  if "$D_REPL" ~= "" & index(lower("`zero'"),"replace ") == 0 {
    local replace "$D_REPL"
  }

  * find the length of the longest significance symbol
  tokenize "`sigsym'"
  local sigwd=length("`1'")
  while "`1'" ~= "" {
    local sigwd=max(`sigwd',length("`1'"))
    macro shift
  }

  * see if "using" was specified
  local pnt=index("`args'","using")
  if `pnt' ~= 0 {
    preserve
    local args1=substr("`args'",1,`pnt'-1)
    local usin=substr("`args'",`pnt',.)
    gettoken usin1 usin: usin
    gettoken usin2 args2: usin
    local args "`args1' `args2'"
    local args=trim("`args'")
    local using "`usin1' `usin2'"
    if "`e(F)'" ~= "" {
      local lstcol 5
    }
    if "`e(chi2)'" ~= "" | "`e(deviance)'" ~= "" {
      local lstcol 4
    }
    if `sigsep' > 0 | "`outraw'" ~= "" {
      local lstcol=`lstcol'+1
    }
    local i 1
    while `i' <= `lstcol' {
      quietly gen str80 __O__`i'=""
      local i=`i'+1
    }
    global D__WRT 1
    if "`outraw'" == "" {
      global D__FMT `", "%12.`ndec'f""'
    }
  }

  * change any asterisks in the argument list to periods
  local alltrms: subinstr local args "*" ".", all
  * table headers
  if "`alltrms'" == "" {
    display "Testing all model terms ..." 
    if "`using'" ~= "" {
      quietly replace __O__1 = "Testing all model terms ..." if _n==$D__WRT
      incrmnt
    }
  }
  if "`equal'" ~= "" {
    display "Testing equality of coefficients"
    if "`using'" ~= "" {
      quietly replace __O__1 = "Testing equality of coefficients" if _n==$D__WRT
      incrmnt
    }
  }
  if "`joint'" ~= "" {
    display "Testing joint significance"
    if "`using'" ~= "" {
      quietly replace __O__1 = "Testing joint significance" if _n==$D__WRT
      incrmnt
    }
  }
  if substr("`e(cmd)'",1,3) == "svy" {
    display "Using svytest"
    if "`using'" ~= "" {
      quietly replace __O__1 = "Using svytest" if _n==$D__WRT
      incrmnt
    }
  }
  if "`e(chi2)'" ~= "" | "`e(deviance)'" ~= "" {
    local div=80-(10+`sigsep'+`sigwd'+6+10)
    display _dup(79) "-"
    display "Term" _col(`div') " Wald chi2" _col(68) "df  P > chi2"
    display _dup(79) "-"
    if "`using'" ~= "" {
      quietly replace __O__1 = "Term" if _n==$D__WRT
      quietly replace __O__2 = "Wald chi2" if _n==$D__WRT
      local curcol 3
      if `sigsep' > 0 | "$D__FMT" == "" {
        local curcol 4
      }
      quietly replace __O__`curcol' = "df" if _n==$D__WRT
      local curcol=`curcol'+1
      quietly replace __O__`curcol' = "P > chi2" if _n==$D__WRT
      incrmnt
      incrmnt
    }
  }
  if "`e(F)'" ~= "" {
    local div=80-(10+`sigsep'+`sigwd'+10+10+10)
    local hdiv=`div'-1
    display _dup(79) "-"
    display "Term" _col(`hdiv') "F statistic" _col(55) "Model  Residual  Prob > F"
    display _col(58) "df        df"
    display _dup(79) "-"
    if "`using'" ~= "" {
      quietly replace __O__1 = "Term" if _n==$D__WRT
      quietly replace __O__2 = "F statistic" if _n==$D__WRT
      local curcol 3
      if `sigsep' > 0 | "$D__FMT" == "" {
        local curcol 4
      }
      quietly replace __O__`curcol' = "Model" if _n==$D__WRT
      quietly replace __O__`curcol' = "df" if _n==$D__WRT+1
      local curcol=`curcol'+1
      quietly replace __O__`curcol' = "Residual" if _n==$D__WRT
      quietly replace __O__`curcol' = "df" if _n==$D__WRT+1
      local curcol=`curcol'+1
      quietly replace __O__`curcol' = "P > F" if _n==$D__WRT
      incrmnt
      incrmnt
    }
  }

  * if no arguments are specified, test all terms
  if "`alltrms'" == "" {
    local i 1
    local nr 1
    local termcnt="${term`i'}"

    while "`termcnt'" ~= "" {
      tokenize "`termcnt'", parse("-")
      local varn="``1'[varn]'"
      if "`joint'" ~= "" {
        local jtest "`jtest' `termcnt'"
        display "`varn'" _col(`div')
        if "`using'" ~= "" {
          quietly replace __O__1 = "`varn'" if _n==$D__WRT
          incrmnt
        }
      }
      else {
        #delimit ;
        dotest `using' , nr(`nr') term(`varn') termcnt(`termcnt') `equal'
        ndec(`ndec') sigsep(`sigsep') 
        sigcut(`sigcut') sigsym(`sigsym') sigwd(`sigwd');
        #delimit cr
        local nr=`nr'+1
      }
      local i=`i'+1
      local termcnt="${term`i'}"
    }
  }
  else {
    tokenize "`alltrms'"
    local term `1'
    local nr 1
    while "`term'" ~= "" {
      macro shift
      local alltrms `*'
      
      * find contents of term
      local i 1
      local tryterm="${term`i'}"
      local termcnt=""
      while "`tryterm'" ~= "" & "`termcnt'" == "" {
        tokenize "`tryterm'", parse("-")
        local varn="``1'[varn]'"
        if "`term'" == "`varn'" {
          local termcnt="`tryterm'"
        }
        local i=`i'+1
        local tryterm="${term`i'}"
      }
    
      if "`joint'" ~= "" {
        local jtest "`jtest' `termcnt'"
        display "`term'" _col(`div')
        if "`using'" ~= "" {
          quietly replace __O__1 = "`term'" if _n==$D__WRT
          incrmnt
        }
      }
      else {
        #delimit ;
        dotest `using' , nr(`nr') term(`term') termcnt(`termcnt') `equal'
        ndec(`ndec') sigsep(`sigsep')
        sigcut(`sigcut') sigsym(`sigsym') sigwd(`sigwd');
        #delimit cr
        local nr=`nr'+1
      }
      
      tokenize `alltrms'
      local term `1'
    }
  }

  if "`joint'" ~= "" {
    #delimit ;
    dotest `using' , nr(1) term("joint significance") termcnt(`jtest') `equal'
    ndec(`ndec') sigsep(`sigsep')
    sigcut(`sigcut') sigsym(`sigsym') sigwd(`sigwd');
    #delimit cr
  }

  display _dup(79) "-"
  if "`using'" ~= "" { incrmnt }

  * legend for significance symbols
  gettoken cut sigct: sigcut
  gettoken sym sigsm: sigsym
  while "`cut'" ~= "" {
    display %-`sigwd's "`sym'" " p < `cut'"
    if "`using'" ~= "" {
      quietly replace __O__1="`sym' p < `cut'" if _n == $D__WRT
      incrmnt
    }
    gettoken cut sigct: sigct
    gettoken sym sigsm: sigsm
  }

  if "`using'" ~= "" {
    global D__WRT=$D__WRT-1
    outshee2 __O__1-__O__`lstcol' `using' in 1/$D__WRT, nonames noquote `replace'
    restore
  }
  macro drop D__*
end

program define incrmnt
  version 6
    if $D__WRT >= _N {
      local n=_N+10
      quietly set obs `n'
    }
    global D__WRT=$D__WRT+1
end

program define dotest
  version 6
  #delimit ;
  syntax [using] , nr(integer) term(string) termcnt(string)
             ndec(numlist > 0 integer max=1)
             sigcut(numlist)
             sigsym(string)
             sigsep(numlist >=0 integer max=1)
             sigwd(numlist >=0 integer max=1) 
             [ equal ];
  #delimit cr

  tokenize "`termcnt'", parse("-")
  local lastvar "`3'"

  if "`termcnt'" == "" {
    display "Can't find dummies for test of `term'"
  }
  else {
    local tstprog "testparm"
    if substr("`e(cmd)'",1,3) == "svy" {
      local tstprog "svytest"
    }
    if "`lastvar'" == "" {
      * don't test for equality of a single variable, even if requested
      capture `tstprog' `termcnt'
    }
    else {
      capture `tstprog' `termcnt', `equal'
    }
    * "capture" preceding testparm plows ahead even if the variables in
    * question have been dropped. If everything did go according to plan,
    * display the results now:
    if _rc == 0 {
      * determine significance level

      * r(p) isn't stored for svytest
      if substr("`e(cmd)'",1,3) == "svy" {
        local prob=fprob(`r(df)',`r(df_r)',`r(F)')
      }
      else {
        local prob=`r(p)'
      }

      local sig_=""
      gettoken cut sigct: sigcut
      gettoken sym sigsm: sigsym
      while "`cut'" ~= "" {
        if `prob' < `cut' {
          local sig_="`sym'"
        }
        gettoken cut sigct: sigct
        gettoken sym sigsm: sigsm
      }

      if "`r(chi2)'" ~= "" {
        local div=80-(10+`sigsep'+`sigwd'+6+10)
        #delimit ;
        display "`term'" _col(`div') %10.`ndec'f `r(chi2)'
          _skip(`sigsep') %-`sigwd's "`sig_'"
          %6.0f `r(df)' %10.`ndec'f `prob';
        #delimit cr
        if "`using'" ~= "" {
          quietly replace __O__1 = "`term'" if _n==$D__WRT
          quietly replace __O__2 = string(`r(chi2)'$D__FMT) if _n==$D__WRT
          * place a tab between statistics and sig symbols 
          * if raw output is requested or a separation space was specified
          if `sigsep' > 0 | "$D__FMT" == "" {
            quietly replace __O__3="`sig_'" if _n==$D__WRT
            local curcol 4
          }
          else {
            quietly replace __O__2=string(`r(chi2)'$D__FMT)+"`sig_'" if _n==$D__WRT
            local curcol 3
          }
          quietly replace __O__`curcol' = string(`r(df)') if _n==$D__WRT
          local curcol=`curcol'+1
          quietly replace __O__`curcol' = string(`prob'$D__FMT) if _n==$D__WRT
          incrmnt
        }
      }
      if "`r(F)'" ~= "" {
        local div=80-(10+`sigsep'+`sigwd'+10+10+10)
        #delimit ;
        display "`term'" _col(`div') %10.`ndec'f `r(F)'
          _skip(`sigsep') %-`sigwd's "`sig_'"
          %10.0f `r(df)' %10.0f `r(df_r)' %10.`ndec'f `prob';
        #delimit cr
        if "`using'" ~= "" {
          quietly replace __O__1 = "`term'" if _n==$D__WRT
          quietly replace __O__2 = string(`r(F)'$D__FMT) if _n==$D__WRT
          * place a tab between statistics and sig symbols 
          * if raw output is requested or a separation space was specified
          if `sigsep' > 0 | "$D__FMT" == "" {
            quietly replace __O__3="`sig_'" if _n==$D__WRT
            local curcol 4
          }
          else {
            quietly replace __O__2=string(`r(F)'$D__FMT)+"`sig_'" if _n==$D__WRT
            local curcol 3
          }
          quietly replace __O__`curcol' = string(`r(df)') if _n==$D__WRT
          local curcol=`curcol'+1
          quietly replace __O__`curcol' = string(`r(df_r)') if _n==$D__WRT
          local curcol=`curcol'+1
          quietly replace __O__`curcol' = string(`prob'$D__FMT) if _n==$D__WRT
          incrmnt
        }
      }
    }
    else {
      display "An error occurred while testing `term', `termcnt'"
      display "One or more estimates do not exist."
    }
  }
end