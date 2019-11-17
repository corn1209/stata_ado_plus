*!Version 2.3.1 10feb09 (By Judson Caskey)
*!Version 2.3.0 5Feb07 (By Jonah B. Gelbach)
*!Version 2.2.0 24Jan07 (By Jonah B. Gelbach)
*!Version 2.1.0 19Sep06 (By Jonah B. Gelbach)
*!Version 2.0.1 	(By Douglas L. Miller)
*!Version 2.0.0 22May06 (By Jonah B. Gelbach)
*!Version 1.0.1 22May06 (By Jonah B. Gelbach)
*!Version 1.0.0 28Mar06 (By Jonah B. Gelbach)

*************
* CHANGELOG *
*************

* 2.3.1: Modifications to base F-test on cluster-adjusted variance matrix and moved ereturns so that they are overwritten by the post command
* 2.3.0: medium edit by JBG to 
*
*		## add treatment of if & in conditions
*		## add treatment of weights
*	
*        (required edit of syntax of to sub_robust subroutine, as well as adding some code on main regress line)
*
*
* 2.2.0: medium edit by JBG to make sure that "robust" option doesn't get passed to regress for line where we obtain (X'X)^(-1) using mse1 option.
*	 (comment: this seems like a stata bug to me -- why should stata allow you to use the robust option when the whole point is to get (X'X)^(-1)????
*
* 2.1.0: medium edit by JBG to move from use of -tab- to -unique- (I just dumped in the text of unique.ado to address this locally)
*
* 2.0.1: minor edit by Doug to unabbreviate "pred"
*
* 2.0.0: major addition: command now handles arbitrary number of grouping vars
*	 		 also, we now use cgmreg to calculate manually when only one clustering variable is used.
*			       this feature helps show that the sub_robust routine is correct

* 1.0.1: corrected error in 1.0.0:
*	I forgot to subtract out the estimate with cluster(bothvars) when `numcvars'==2


*********************
* SCHEMATIC OF CODE *
*********************

/*

	1. Run the regression, with mse1 option (this option sets robust off and variance=1, so that resulting "cov" matrix is (X'X)^-1)

	2. Save some matrices, scalars, and macros from the ereturned regress output

	3. Generate predicted residuals

	4. Set up a giant matrix that has

		* one column for every clustering variable
		* [(2^K) - 1] rows, where K is the number of clustering variables
		* elements equal to either 0 or 1

	   Each row of this matrix corresponds to one subcase, so that it provides a list of clustering vars for which we will calculate the middle matrix.

	   We then add or subtract the middle matrices according to the inclusion/exclusion rule: 

		* when the number of included clustering vars is odd, we add
		* when the number of included clustering vars is even, we subtract

	5. We then iterate over the rows of this matrix, using egen, group() and the list of included clustering variables 
	   to create a grouped var indicating an observation's membership category according to this group

	6. We then use the sub_robust subroutine (which uses _robust) to calculate the appropriate part of the covariance matrix

	7. The resulting part of the covariance matrix is added/subtracted to the matrix `running_mat', as given by the inc/exc rule

	8. The header in the stata output tells us

				Number of obs		[Total number of included observations]
				Num clusvars 		[Number of clustering vars, i.e., dimensions]
				Num combinations	[Total number of possible combinations of the clusvars, i.e., 2^K-1]

	   Followed by a list of the number of distinct categories in each clustering variable.

	9. Then the regression output appears, and we are done.

*/


program define cgmregF, eclass byable(onecall) sortpreserve

	syntax anything [if] [in] [aweight fweight iweight pweight /], Cluster(string) level(cilevel) testmat(namelist max=2 min=2) [*]

	tempname bT e_chi2 e_p e_df_m e_df_r e_r2 e_rmse e_mss e_rss e_r2_a e_ll e_ll_0 numcvars S b xxinv rows running_sum Bigmat ///
		elementM element matrixN matrixD mn md A B C rn rd nint rhs tc vc g gv cl cu bTr

	tempvar regvar clusvar resid groupvar

	tokenize "`testmat'"
	local `matrixN'="`1'"
	mac shift
	local `matrixD'="`1'"

	marksample touse
	qui egen `regvar'=rowmiss(`anything')
	qui egen `clusvar'=rowmiss(`cluster')
	qui replace `touse'=(`touse' & `regvar'==0 & `clusvar'==0)

	local `numcvars' : word count `cluster'

	di
	while ( regexm("`options'","robust")==1 ) {

		di " -> Removing string 'robust' from your options line: it's unnecessary as an option,"
		di "    but it can cause problems if we leave it in."
		di "    If some variable in your options list contains the string 'robust', you will"
		di "    have to rename it."
		di 
		local options = regexr("`options'", "robust", "")

	} 

	/* deal with weights */
	if "`weight'"~="" {
		local weight "[`weight'=`exp']"
	} 
	else {
		local weight ""
	}

	/* main regression */
	qui regress `anything' if `touse' `weight', `options' mse1
	di in green "Note: +/- means the corresponding matrix is added/subtracted"
	di

	/* copy some information that regress provides */
	
	mat `b' = e(b)
	mat `bTr'=e(b)'

* ---------------------------------------------------------------- 
* ----- Check whether matrices are valid ------------------------- 
* ---------------------------------------------------------------- 

	capture confirm matrix ``matrixN''
	if _rc != 0 {
		di as error "Missing numerator matrix"
		exit
		}
	capture confirm matrix ``matrixD''
	if _rc != 0 {
		di as error "Missing denominator matrix"
		exit
		}

	local `rhs'=colsof(`b')
	if colsof(``matrixN'')!=``rhs'' {
		di as error "Numerator matrix has incorrect number of columns"
		exit
		}
	if colsof(``matrixD'')!=``rhs'' {
		di as error "Denominator matrix has incorrect number of columns"
		exit
		}

	local `nint'=rowsof(``matrixN'')
	if rowsof(``matrixD'')!=``nint'' {
		di as error "Numerator matrix and denominator matrix have different number of rows"
		exit
		}
	local `tc'=invttail(e(N)-e(df_m)-1,(1-`level'/100)/2)

* ---------------------------------------------------------------- 
* ----- Continue estimation              ------------------------- 
* ---------------------------------------------------------------- 

	local depname = e(depvar)


	/* generate the residuals */

	qui predict double `resid' if `touse'==1, residual
	local n = e(N)
	

	*save (x'x)^-1
	mat `xxinv' = e(V)
	mat `rows' = rowsof(e(V))
	local rows = `rows'[1,1]
	local cols = `rows'		/* avoid confusion */

	/* matrix that holds the running sum of covariance matrices as we go through clustering subsets */
	mat `running_sum' = J(`rows',`cols',0)

	/* we will use a_cluster for matrix naming below as our trick to enumerate all clustering combinations */

	mat `Bigmat' = J(1,1,1)

	*taking inductive approach
	forvalues a=2/``numcvars'' { /* inductive loop for Bigmat */

		mat `Bigmat' = J(1,`a',0) \ ( J(2^(`a'-1)-1,1,1) , `Bigmat' ) \ (J(2^(`a'-1)-1,1,0) , `Bigmat' ) 
		mat `Bigmat'[1,1] = 1

	} /* end inductive loop for Bigmat */

	mat colnames `Bigmat' = `cluster'

	local numsubs = 2^``numcvars'' - 1
	local `S' = `numsubs' 			/* for convenience below */

	forvalues s=1/``S'' { /* loop over rows of `Bigmat' */

		{	/* initializing */
			local included=0
			local grouplist
		} /* done initializing */

		foreach clusvar in `cluster' { /* checking whether each `clusvar' is included in row `s' of `Bigmat' */

			mat `elementM' = `Bigmat'[`s',"`clusvar'"] 
			local `element' = `elementM'[1,1]


			if ``element'' == 1 { /* add `clusvar' to grouplist if it's included in row `s' of `Bigmat' */

				local included= `included' + 1
				local grouplist "`grouplist' `clusvar'"

			} /* end add `clusvar' to grouplist if it's included in row `s' of `Bigmat' */
		} /* checking whether each `clusvar' is included in row `s' of `Bigmat' */


		*now we use egen to create the var that groups observations by the clusvars in `grouplist'

		qui egen `groupvar' = group(`grouplist') if `touse'

		*now we get the robust estimate
		local plusminus "+"
		if mod(`included',2)==0 { /* even number */
			local plusminus "-"
		} /* end even number */

                sub_robust `if' `in' `weight', groupvar(`groupvar') xxinv(`xxinv') plusminus(`plusminus') resid(`resid') running_sum(`running_sum') touse(`touse')
	
		di in green "Calculating cov part for variables: `grouplist' (`plusminus')"

		drop `groupvar'

	} /* end loop over rows of `Bigmat' */
	

	scalar `e_df_m' =              e(df_m)
	scalar `e_df_r' =              e(df_r)

	* Compute F-test
	if regexm("`options'","noconstant") == 0 mat `bT'=[I(colsof(`b')-1),J(colsof(`b')-1,1,0)]
	else mat `bT'=[I(colsof(`b'))]
	matrix `e_chi2'=`b'*`bT''*inv(`bT'*`running_sum'*`bT'')*`bT'*`b''
	scalar `e_p'		= chi2tail(`e_df_m',`e_chi2'[1,1])

	scalar `e_r2' =                e(r2)
	scalar `e_rmse' =              e(rmse)
	scalar `e_mss' =               e(mss)
	scalar `e_rss' =               e(rss)
	scalar `e_r2_a' =              e(r2_a)
	scalar `e_ll' =                e(ll)
	scalar `e_ll_0' =              e(ll_0)


	/* final cleanup and post */
	di

	dis " "
	dis in green "Regress with clustered SEs" ///
		_column (50) "Number of obs" _column(69) "=" _column(71) %8.0f in yellow `n'
	dis in green _column(50) "Wald chi2(" in yellow `e_df_m' in green ")" _column(69) "=" _column(71) %8.2f in yellow `e_chi2'[1,1]
	dis in green "Number of clustvars" _column(20) "=" _column(21) %5.0f in yellow ``numcvars'' ///
          in green _column(50) "Prob > chi2" _column(69) "=" _column(71)  %8.4f in yellow `e_p'
   	dis in green "Num cobminations" _column(20) "=" _column(21) %5.0f in yellow ``S'' ///
	    in green _column(50) "R-squared" _column(69) "=" _column(71) %8.4f in yellow `e_r2'
	if "`if'"~="" di in green _column(50) "If condition" _column(69) "= `if'"
	if "`in'"~="" di in green _column(50)     "In condition" _column(69) "= `in'"
	if "`weight'"~="" di in green _column(50) "Weights are" _column(69) "= `weight'"



	if "`if'"~="" di _column(50) "If condition      =    `if'"
	if "`in'"~="" di _column(50)     "In condition      =    `in'"
	if "`weight'"~="" di _column(50) "Weights are       =    `weight'"
	di
	local c 0
	foreach clusvar in `cluster' { /* getting num clusters by cluster var */

		local c = `c' + 1
		qui unique `clusvar' if `touse'
		di _column(50) in green "G(`clusvar')" _column(69) "=" %8.0f in yellow _result(18)
		
	} /* end getting num obs by cluster var */
	di

	mat `vc'=`running_sum'


	ereturn post `b' `running_sum', e(`touse') depname(`depname') 

	ereturn scalar N       =           `n' 
	ereturn scalar df_m =              `e_df_m'
	ereturn scalar df_r =              `e_df_r'
	ereturn scalar chi2 =                 `e_chi2'[1,1]
	ereturn scalar p =			`e_p'
	ereturn scalar r2 =                `e_r2'
	ereturn scalar rmse =              `e_rmse'
	ereturn scalar mss =               `e_mss'
	ereturn scalar rss =               `e_rss'
	ereturn scalar r2_a =              `e_r2_a'
	ereturn scalar ll =                `e_ll'
	ereturn scalar ll_0 =              `e_ll_0'
	
	ereturn local title =             e(title)
	ereturn local depvar =            `depname'
	ereturn local cmd =               "cgmreg"
	ereturn local properties =        e(properties)
	ereturn local predict =           e(predict)
	ereturn local model =             e(model)
	ereturn local estat_cmd =         e(estat_cmd)
	ereturn local vcetype =           e(vcetype)
	ereturn local clustvar =          "`cluster'"
	ereturn local clusvar  =          "`cluster'"



	ereturn display


* Display confidence intervals

	di as result ""
	di as result ""
	di as result in green "Confidence intervals of ratios using Fieller's method"
	di as result _dup(70) in green "_"
	di as result  _column(20) "     Fieller method      " _column(45) "      Delta method      "
	di as result "     Ratio" _column(20) "  [`level'% Conf. Interval]  " _column(45) "  [`level'% Conf. Interval]  "
	di as result _dup(70) in green "_"
	forvalues k=1(1)``nint'' {
		matrix `mn'=``matrixN''[`k',1...]
		matrix `md'=``matrixD''[`k',1...]

		matrix `A'=(`md'*`bTr')*(`md'*`bTr')-((``tc'')^2)*`md'*`vc'*`md''
		local `A'=`A'[1,1]
		matrix `B'=2*(((``tc'')^2)*`mn'*`vc'*`md''-(`mn'*`bTr')*(`md'*`bTr'))
		local `B'=`B'[1,1]
		matrix `C'=(`mn'*`bTr')*(`mn'*`bTr')-((``tc'')^2)*`mn'*`vc'*`mn''
		local `C'=`C'[1,1]

		matrix `rn'=`mn'*`bTr'
		matrix `rd'=`md'*`bTr'
		ereturn scalar ratio`k'=(`rn'[1,1])/(`rd'[1,1])

		matrix `g'=((`mn')/(`rn'[1,1])-(`md')/(`rd'[1,1]))*(`rn'[1,1])/(`rd'[1,1])
		matrix `gv'=`g'*`vc'*`g''

		* Check conditions and compute confidence interval

		local `cl'=(-(``B'')-sqrt((``B'')^2-4*(``A'')*(``C'')))/(2*(``A''))
		local `cu'=(-(``B'')+sqrt((``B'')^2-4*(``A'')*(``C'')))/(2*(``A''))

		ereturn scalar cD`k'L=(`rn'[1,1])/(`rd'[1,1])-(``tc'')*sqrt(`gv'[1,1])
		ereturn scalar cD`k'H=(`rn'[1,1])/(`rd'[1,1])+(``tc'')*sqrt(`gv'[1,1])

		if ``A''<=0 {
			if ``A''==0 | (``B'')^2-4*(``A'')*(``C'')<0 {
				ereturn scalar cF`k'L=.
				ereturn scalar cF`k'H=.
				di as result %10.4f `rn'[1,1]/`rd'[1,1] _column(20) %10.4f . _column(32) %10.4f .  /// 
					_column(45) %10.4f (`rn'[1,1])/(`rd'[1,1])-(``tc'')*sqrt(`gv'[1,1]) ///
					_column(57) %10.4f (`rn'[1,1])/(`rd'[1,1])+(``tc'')*sqrt(`gv'[1,1])
				}
			else {
				ereturn scalar cF`k'L1=.
				ereturn scalar cF`k'L2=``cl''
				ereturn scalar cF`k'H1=``cu''
				ereturn scalar CF`k'H2=.
				di as result %10.4f `rn'[1,1]/`rd'[1,1] _column(20) %10.4f . _column(32) %10.4f ``cl'' /// 
					_column(45) %10.4f (`rn'[1,1])/(`rd'[1,1])-(``tc'')*sqrt(`gv'[1,1]) ///
					_column(57) %10.4f (`rn'[1,1])/(`rd'[1,1])+(``tc'')*sqrt(`gv'[1,1])
				di as result %10.4f                     _column(20) %10.4f ``cu'' _column(32) %10.4f .
				}
			}
		else {
			ereturn scalar cF`k'L=``cl''
			ereturn scalar cF`k'H=``cu''
			di as result %10.4f `rn'[1,1]/`rd'[1,1] _column(20) %10.4f ``cl'' _column(32) %10.4f ``cu'' ///
				_column(45) %10.4f (`rn'[1,1])/(`rd'[1,1])-(``tc'')*sqrt(`gv'[1,1]) ///
				_column(57) %10.4f (`rn'[1,1])/(`rd'[1,1])+(``tc'')*sqrt(`gv'[1,1])


			}

		}

	di as result _dup(70) in green "_"
	di as result ""
	di as result ""



end



prog define sub_robust

	syntax [if] [in] [aweight fweight iweight pweight /] , groupvar(string) xxinv(string) plusminus(string) resid(string) running_sum(string) touse(string) 

/*
	local cvar 		"`1'"	/* cluster var, to be fed to us as argument 1 */
	local xxinv 		"`2'"	/* xxinv estimate, to be fed to us as argument 2 */
	local plusminus 	"`3'"	/* whether to add or subtract to `running_sum', argument 3 */
	local resid 		"`4'"	/* name of tempvar with resids in it, arg 4 */
	local running_sum 	"`5'"	/* running_sum estimate, to be fed to us as argument 5 */
	local touse		"`6'"
*/	
	tempname rows m


	/* deal with weights */
	if "`weight'"~="" {
		local weight "[`weight'=`exp']"
	} 
	else {
		local weight ""
	}

	mat `rows' = rowsof(`xxinv')
	local rows = `rows'[1,1]

	cap mat drop `m'
	mat `m' = `xxinv'

	if "`if'"=="" local if "if 1"
	else          local if "`if' & `touse'"

	qui _robust `resid' `if' `in' `weight', v(`m') minus(`rows') cluster(`groupvar')
	mat `running_sum' = `running_sum' `plusminus' `m'

*	mat li `running_sum'
end


*! version 1.1  mh 15/4/98  arb 20/8/98
*got this from http://fmwww.bc.edu/repec/bocode/u/unique.ado
program define unique
local options "BY(string) GENerate(string) Detail"
local varlist "req ex min(1)"
local if "opt"
local in "opt"
parse "`*'"
tempvar uniq recnum count touse
local sort : sortedby
mark `touse' `if' `in'
qui gen `recnum' = _n
sort `varlist'
summ `touse', meanonly
local N = _result(18)
sort `varlist' `touse'
qui by `varlist': gen byte `uniq' = (`touse' & _n==_N)
qui summ `uniq'
di in gr "Number of unique values of `varlist' is  " in ye _result(18)
di in gr "Number of records is  "in ye "`N'"
if "`detail'" != "" {
	sort `by' `varlist' `touse'
	qui by `by' `varlist' `touse': gen int `count' = _N if _n == 1
	label var `count' "Records per `varlist'"
	if "`by'" == "" {
		summ `count' if `touse', d
	}
	else {
		by `by': summ `count' if `touse', d
	}
}
if "`by'" !="" {
	if "`generate'"=="" {
		cap drop _Unique
		local generat _Unique
	}
	else {
		confirm new var `generate'
	}

        drop `uniq'
	sort `by' `varlist' `touse'
	qui by `by' `varlist': gen byte `uniq' = (`touse' & _n==_N)
	qui by `by': replace `uniq' = sum(`uniq')
	qui by `by': gen `generate' = `uniq'[_N] if _n==1
	di in blu "variable `generate' contains number of unique values of `varlist' by `by'"
	list `by' `generate' if `generate'!=., noobs nodisplay
}
sort `sort' `recnum'
end

