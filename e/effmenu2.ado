*! Command line version of effmenu1
*! Michael Hills 1/5//2002
*! version 3.0.0

program define effmenu2
version 7.0
syntax [varlist] [if] [in] , Res(string) Typ(string) Exp(string) /*
*/ [FUP(string) Mod(string) EFFects(string) PERY(integer 1000) /*
*/ PERU(integer 1) PERC(integer 100) MCC MVAR(string) BASE(integer 1) EXM /*
*/ MOM SHOWAT(numlist) CON(string) MET(string) /*
*/ VERbose LEVel(integer $S_level)]

macro drop EF_*
macro drop ef_*

global ef_res `res'
global ef_typ `typ'
global ef_fup `fup'
global ef_exp `exp'
global ef_mod `mod'
if "`typ'"=="metric" {
    if "`effects'"=="md" {global ef_sca 1}
    if "`effects'"=="mr" {global ef_sca 2}
}
if "`typ'"=="binary" {
    if "`effects'"=="pd" {global ef_sca 1}
    if "`effects'"=="pr" {global ef_sca 2}
    if "`effects'"=="or" {global ef_sca 3}
}
if "`typ'"=="failure" | "`type'"=="count" {
    if "`effects'"=="rd" {global ef_sca 1}
    if "`effects'"=="rr" {global ef_sca 2}
}
global ef_peru `peru'
global ef_pery `pery'
global ef_perc `perc'
global ef_bas `base'
global ef_sho `showat'
global ef_mvar `mvar'
global ef_con `con'
global ef_met `met'
global ef_ver `verbose'
global ef_lev `level'
global ef_bas `base'

global ef_exm 0
if "`exm'" == "exm" {
    global ef_exm 1
}
global ef_mom 0
if "`mom'" == "mom" {
    global ef_mom 1
}
global ef_mcc 0
if "`mcc'" == "mcc" {
    global ef_mcc 1
}
global ef_ver 0
if "`verbose'" == "verbose" {
    global ef_ver 1
}
global ef_opt

/* Sets all variables to categorical as default */

tokenize "`varlist'"
while "`1'" != "" {
    char `1'[type] "categorical"
    mac shift 
}

/* sets type for categorical variables */

if $ef_exm==1 {
    char $ef_exp[type] "metric"
}
if $ef_mom==1  {
    if "$ef_mod" == "" {
      di as error "Metric modifier specified, but no modifier given"
      exit
    }
    else {
      char $ef_mod[type] "metric"
    }
}

/* basic error checking */

global ef_exp = ltrim("$ef_exp")
global ef_mod = ltrim("$ef_mod")
global ef_res = ltrim("$ef_res")

if "$ef_res"=="" {
    di as error "No response variable has been specified!"
    exit
}
else {
    cap confirm numeric variable $ef_res
    if _rc==7 {
        di as error "Response variable must be numeric"
        exit
    }
}
if "$ef_typ" == "" {
    di as error "Type of response variable must be selected"
    exit
}
if "$ef_exp"=="" {
    di as error "Explanatory variable must be specified"
    exit
}
else {
    cap confirm numeric variable $ef_exp
    if _rc==7 {
        di as error "Exposure variable must be numeric"
        exit
  }
}
if "$ef_res"=="$ef_exp" {
    di as error "Variable occurs as both response and main explanatory"
    exit
}
if "$ef_res"=="$ef_mod" {
    di as error "Variable occurs as both response and modifier"
    exit
}
if "$ef_mod"=="$ef_exp" {
    di as error "Variable occurs as both main explanatory and modifier"
    exit
}
if "$ef_mod" != "" {
    cap confirm numeric variable $ef_mod
    if _rc==7 {
        di as error "Modifier variable must be numeric"
        exit
    }
}
if "$ef_typ"=="binary" {
    cap assert $ef_res ==0 | $ef_res ==1 | $ef_res==.
    if _rc==9 {
        di in red "Binary response must be coded 0/1"
        exit
    }
}
if "$ef_typ"=="binary" {
    cap assert "$ef_fup"==""
    if _rc==9 {
        di in red "Cannot have follow-up time with binary repsonse"
        exit
    }
}
if "$ef_typ"=="failure" {
    cap assert $ef_res ==0 | $ef_res ==1 | $ef_res==.
    if _rc==9 {
        di in red "Failure response must be coded 0/1"
        exit
    }
}
if "$ef_typ"=="failure" | "$ef_typ"=="count"  {
    cap assert "$ef_fup" != ""
    if _rc==9 {
        di in red "Failure and count responses must have follow-up time"
        exit
    }
}
qui inspect $ef_exp
if r(N_unique)>15 & "`$ef_exp[type]'"!="metric" {
    display as error" More than 15 values for exposure ($ef_exp)" 
    display as text "Should it be declared as metric?"
    exit
}
if "$ef_mod" != "" {
    qui inspect $ef_mod
    if r(N_unique)>15 & "`$ef_mod[type]'"!="metric" {
        display as error " More than 15 values for modifier ($ef_mod)"
        di as text "Should it be declared as metric?"
        exit
    }
}
qui inspect $ef_exp
if $ef_bas == 0 | $ef_bas > r(N_unique) {
    di as error "Baseline out of range"
    exit
}
if "$ef_con"!="" {
    tokenize "$ef_con"
    while "`1'" != "" {
        if "`1'" == "$ef_mod" {
            di as error "Cannot include variable as both modifier and control"
            exit
        }
    mac shift
    }
}

/* displays exposure and modifier type */

if "$ef_exp" != "" {
    if "`$ef_exp[type]'" == "categorical" {
        global EF_exptype "is categorical"
    }
    if "`$ef_exp[type]'" == "metric" {
        global EF_exptype " is metric"
    }
}

if "$ef_mod" != "" {
   if "`$ef_mod[type]'" == "categorical" {
       global EF_modtype "is categorical"
       global ef_sho
   }
  if "`$ef_mod[type]'" == "metric" {
       global EF_modtype "is metric"
  }
}

tokenize "$ef_met"
while "`1'" != "" {
    char `1'[type] "metric"
    mac shift 
}

dis ""
effects1 `if' `in' , level($ef_lev)
end

