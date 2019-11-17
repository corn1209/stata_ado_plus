*! Version 1.0.2 24 June 1998 Vincent Kang Fu 

/*
** goll.ado
**
** log-likelihood program file for gologit generalized ordered logit 
** 	model command
**
** estimate generalized ologit coefficients for an ordinal dependent 
** 	variable with any number of categories
**
** usage: gologit depvar varlist [if exp] [in range] [weight], 
**	[cluster(var)] [robust] [level(#)] [or]
**
** gologit with no arguments redisplays the last estimates
**
** Version 1.0.0 
** distributed to Statalist 
** 3 December 1997
**
** revised	6 December 1997		to remove #delimit ;/#delimit cr blocks
**
** Version 1.0.1
** 7 December 1997
**
** revised:	24 June 1998		to incorporate constants into the same equations
**					as the coefficients for the logits they correspond to
**
** Version 1.0.2
** 24 June 1998
**
*/


program define goll
	local lnf "`1'"

	* how many categories does the dependent variable have?
	local n = $S_golog

	* xb1 is `2', xb2 is `3', ..., xb(n-1) is `n' 

	quietly replace `lnf' =  -ln( 1 + exp(  `2'   ) ) if $S_mldepn == 1
	quietly replace `lnf' =  -ln( 1 + exp( -``n'' ) ) if $S_mldepn == `n'

	local i = 2
	while ( `i' < `n' )	{

		local j = `i' + 1		/* ``j'' is xb`i' 	*/
						/* ``i'' is xb`i-1'	*/

		quietly replace `lnf' =  ln( 1 / ( 1 + exp( ``j'' ) ) - 1 / ( 1 + exp( ``i'' ) ) ) if $S_mldepn == `i'

		local i = `i' + 1
	}
end


