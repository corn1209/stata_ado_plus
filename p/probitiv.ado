*! version 5.0 2Nov1997

*. probitiv  depvar, endog() exog() iv() stage1()

program define probitiv

local varlist "required existing max(1)"
local if "optional "
local options "ENDOG(string) EXOG( string) IV(string) STAGE1(string)"
parse "`*'"

* Run first stage
parse "`endog'", parse(" ")


 local e = 0				/* initializing endogenous variables counter  */
 while "`1'" ~= "" {			/* while routine for first stage  */


   * If stage1 = "" or stage1 = "probit"  

  local e = 1 + `e'			/* incrementing endogenous variables counter  */
  if "`stage1'" == "probit" { 

	quietly probit `1' `iv' `exog' `if'   /* running first stage probit */
							      /* on exogenous and iv */

	tempvar fitted`e'		/* declaring fitted values variables as temporary  */
	predict `fitted`e'' `if'	/* generating fitted values for this endogenous variable  */
	replace  `fitted`e'' =. if `1' ==.  /* setting fitted values missing where endogenous variable is missing  */
  				}  
  else if "`stage1'" == "" { 

	quietly regress `1' `iv' `exog' `if'	/* running first stage  regression */
						/* on exogenous and iv */

	tempvar fitted`e' resid`e'		/* declaring fitted values variables as temporary  */
	predict `fitted`e'' `if'	/* generating fitted values for this endogenous variable  */
	replace  `fitted`e'' =. if `1' ==.  /* setting fitted values missing where endogenous variable is missing  */

	predict `resid`e'' `if', residuals	/* generating fitted residuals  */
	replace `resid`e'' =. if `1' ==.	/* making sure of missing values  */
				}
  else if "`stage1'" == "linear" {

	quietly regress `1' `iv' `exog' `if' /* running first stage ols */
							     /* regression on exogenous and iv */

	tempvar fitted`e'  resid`e'	/* declaring fitted values variables as temporary  */
	predict `fitted`e'' `if'	/* generating fitted values for this endogenous variable  */
	replace  `fitted`e'' =. if `1' ==.  /* setting fitted values missing where endogenous variable is missing  */

	predict `resid`e'' `if', residuals	/* generating fitted residuals  */
	replace `resid`e'' =. if `1' ==.	/* making sure of missing values  */
  				}

	local fitted "`fitted' `fitted`e''"	/* creating list of fitted variables  */
	local resid "`resid' `resid`e''"	/* creating list of resid variables  */
	macro shift
			}  /* ends main while loop  */

 * Run probit of depvar on fitted, resid, and exog variables
 display _newline
 hyphens, lines(2)
 display "TEMPVAR: `fitted1' `endog' ;  probitiv used " _column(45) _result(1)  " observations" _newline
 quietly probit `varlist' `fitted' `exog' `resid' `if'

 matrix b = get(_b)
 matrix v = get(VCE)
 local obs = _result(1)
 local df = _result(1)
 local likely = _result(2)
 matrix post b v, dep(`varlist') obs(`obs') d(`df')
 matrix mlout
 display "ln_L" _column(10) "|" _skip(2)  "`likely' . . . . ."
end
