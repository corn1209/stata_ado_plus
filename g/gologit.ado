*! Version 1.0.4 14 April 2001 Vincent Kang Fu 

/*
**
** gologit.ado
**
** estimate generalized ologit coefficients for a dependent variable with any number 
** 	of categories
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
** revised:	4 December 1997		added _rmcoll to drop collinear explanatory variables
**					error message if user specifies more than one cluster() 
**					variable
**		5 December 1997		abort if equations mleq1, cons1, etc already exist
**					replace preserve with capture {} block
**		6 December 1997		expand capture {} block to enclose checkeq calls
**					also reset the data-changed-since-last-save flag
**					if necessary; change some error XXX statements
**					to exit XXX statements to avoid extra error output
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
**
** revised:	3 April 2000		to add functionality for Long and Freese's -fitstat-
**					using changes suggested by Freese
**
** revised:	14 April 2001		moved -checkeq- after -gologit- in the gologit.ado
**					because the old version no longer works in Stata 7
**
**
** Version 1.0.4beta
** 7 April 2000
**
*/

program define gologit, eclass

	version 5.0

	local options "Level(integer $S_level) OR"

	if ( "`1'" == "" | substr("`1'",1,1) == ",")	{
		if ( "$S_E_cmd" != "gologit" ) 	{
			error 301
		}
		parse "`*'"
		if ( "`or'" != "" )	{
			local or "eform(Odds Ratio)"
		}
	}
	else	{

		local varlist "required existing min(2)"
		local if "optional prefix"
		local in "optional prefix"
		local weight "pweight aweight fweight prefix"
		local options "Robust Cluster(string) `options'"

		parse "`*'"
		parse "`varlist'", parse(" ")

		local depv "`1'"
		macro shift
		local expv "`*'"

		tempvar touse
		mark `touse' `if' `in' [`weight'`exp']
		markout `touse' `varlist' `cluster'

		if ( "`weight'" == "pweight" ) 	{
			local weight "aweight"
			local robust "robust"
		}

		if ( "`or'" != "" )	{
			local or "eform(Odds Ratio)"
		}

		if ( "`cluster'" != "" ) 	{
			parse "`cluster'", parse(" ")
			if ( "`2'" != "" )	{
				display in red "only one cluster() variable allowed"
				exit 198
			}

			local cluster "cluster(`cluster')"
			local robust "robust"
		}

		if ( `level' < 10 | `level' > 99 )	{
			display in red "level must be between 10 and 99"
			exit 198
		}

		* get rid of collinear explanatory variables
	        _rmcoll `expv' if `touse'
	        local expv "$S_1"

		* run ologit on depv with no explanatory variables to get
		* starting values for our model
		quietly ologit `depv' if `touse' [`weight'`exp']

                if ( _result(1) == 0 | _result(1) == . ) {
                        error 2000
                }

		quietly tab1 `depv' if `touse'
		local n = _result(2)		/* number of categories */
		global S_golog `n'			
			/* make sure log-likelihood function goll knows how 
			** many categories the dependent variable has */

		* save the data-changed-since-last-save flag and automatically
		* restore the flag on program termination
		* gologit must change the data but will restore it
		preserve, changed

		* set up equations and create macros specifying the number of
		* dependent variables (mldv) and constants (mlc1, mlc0) in 
		* equations for the ml model command		
		* set up macros (mname, meqc, mval) so that we can create a 
		* vector using ologit cut-points to use as our starting 
		* values
		* mleq1 will have the dependent variable, the explanatory 
		* variables and a constant 
		* mleq2, mleq3, ..., mleq(n-1) will have the explanatory 
		* variables and a constant
		* to allow ml to set $S_E_depv correctly, we must change the
		* user's data because we are going to create a new variable 
		* with the name `depv' and rename the user's `depv' to `dv'
		* to ensure that everything is properly restored if an
		* error occurs we -capture- all errors

		capture	noisily	{

			* create our version of `depv' that runs from 1, ..., n where
			* n is the number of categories
			tempvar dv
			rename `depv' `dv'
			quietly egen `depv' = group( `dv' ) if `touse'

			local mval = -_coef[_cut1]
			local mname "_cons "
			local mldv
			local mlc1 "1"

			quietly checkeq mleq1
			eq mleq1: `depv' `expv'
			local meqe "mleq1"

			local i = 2
			while ( `i' < `n' )	{
				local c = -_coef[_cut`i']

				local mval "`mval', `c'"
				local mname "`mname' _cons"
				local mldv "`mldv'0"
				local mlc1 "1`mlc1'"

				* make sure equations with the names mleqN and consN
				* don't already exist
				checkeq "mleq`i'"
				eq mleq`i': `expv'
				local meqe "`meqe' mleq`i'"

				local i = `i' + 1
			}

			local mldv "1`mldv'"

			* create vector of starting values
			tempname b0
			matrix `b0' = ( `mval' )
			matrix coleq `b0' = `meqe'
			matrix colnames `b0' = `mname'

			tempname b f V
			tempvar mysamp

			ml begin
			ml function goll
			ml method lf

			ml model `b' = `meqe' , depv(`mldv') constant(`mlc1') from(`b0')

			ml sample `mysamp' if `touse' [`weight'`exp']
			ml maximize `f' `V'

			ml post gologit, lf0(i0) title("Generalized Ordered Logit Estimates") pr2

			if ( "`robust'" != "" )	{

				* use predict to get the values of xb1, xb2, ...,
				* xb(n-1), for each
				* observation so that we can use these values
				* to calculate the score index Stata needs
				* to produce the robust covariance estimator
				* create variables that will contain the score 
				* indices that we are going to calculate

				local i = 1
				local sc

				while ( `i' < `n' )	{

					tempvar xb`i' s`i' 

					predict double `xb`i'', equation(mleq`i')
					quietly generate double `s`i'' = 0

					local sc "`sc' `s`i''"

					local i = `i' + 1
				}

				local j = `n' - 1

				* compute values of the score index when the 
				* dependent variable has its smallest and largest values
				quietly replace `s1'   = -1 / ( 1 + exp( -`xb1' ) ) if `depv' == 1
				quietly replace `s`j'' = 1 / ( 1 + exp( `xb`j'' ) ) if `depv' == `n'

				* calculate values of the score index when the
				* dependent variable has values 2, 3, ..., n-1
				local i = 2
				while ( `i' < `n' )	{
					local j = `i' - 1

					quietly replace `s`j'' = 1 / ( exp( -`xb`i'' + `xb`j'' ) - 1 ) + 1 / ( 1 + exp( `xb`j'' ) ) if `depv' == `i'
					quietly replace `s`i'' = 1 / ( exp( -`xb`j'' + `xb`i'' ) - 1 ) + 1 / ( 1 + exp( `xb`i'' ) ) if `depv' == `i'

					local i = `i' + 1
				}

				_robust `sc' if `mysamp' [`weight'`exp'], `cluster'

			}
		}	/* end of capture block */

		local rc = _rc

		nobreak	{
			if ( "`meqe'" != "" )	{
				eq drop `meqe' 	/* drop the equations we created */
			}
			drop `depv'		/* get rid of the `depv' we */
			rename `dv' `depv'	/* created, restore the */
		}				/* user's `depv', and */

		error `rc'			/* report any errors */
	}

	* show table of coefficients to user
	ml mlout gologit, level(`level') `or' 

	version 6.0
	tempvar insamp
	gen `insamp' = (`mysamp' != 0 & `mysamp' != . )
	qui estimates repost, e(`insamp')
	estimates local wtype = "`weight'"
	estimates local wexp = "`exp'"

end

program define checkeq

	* check to see if an equation with the name `1' exists
	* if so, issue an error message

	capture eq dir `1'

	if !( _rc )	{
		display in red "equation `1' will be destroyed"
		display in red "drop or rename it and run command again"
		exit 110
	}

end


