*! version 1.0.0 Stephen P. Jenkins, Jan 1998   STB-48 sg104
*! Asymptotic standard errors for selected GE inequality measures


prog define geivars

	version 5.0
	local varlist "req ex max(1)"
	local if "opt"
	local in "opt"
*	local options " "
	local weight "aweight fweight"
	parse "`*'"
	parse "`varlist'", parse (" ")
	local x "`varlist'"

	tempvar w touse fi m1_1 m2_1 m2_2 m10 m11 m12 m20 m21 m22 m23 m24 /*
		*/ t10 t20 t11 t21 t22 t23 t24 badinc

	if "`weight'" == "" {qui ge `w' = 1}
	else {qui ge `w' `exp'}

	mark `touse' `if' `in'
	markout `touse' `varlist' `w'

	set more 1

	* x = income; w = weightvar (z in Cowell (1989))

quietly {

	count if `x' < 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `x' has `ct' values < 0." _c
		noi di in blue " Not used in calculations"
		}
	count if `x' == 0 & `touse'
	local ct = _result(1)
	if `ct' > 0 {
		noi di " "
		noi di in blue "Warning: `x' has `ct' values = 0." _c
		noi di in blue " Not used in calculations"
		}
	ge `badinc' = 0
	replace `badinc' =. if `x' <= 0
	markout `touse'  `badinc'

    sum `x' if `touse'
    local xmean = _result(3)
    local n = _result(1)   		/* # of observations */
    sum `w' if `touse'
    local wmean = _result(3)		
    ge `fi' = `w'/_result(2) if `touse' /* w normalised by sum of weights */

    /* moments */

    egen `m1_1' = sum(`fi'*(`x'^-1)/`n') if `touse'
    egen `m2_1' = sum((`fi'^2)*(`x'^-1)/`n') if `touse'
    egen `m2_2' = sum((`fi'^2)*(`x'^-2)/`n') if `touse'	
	
    egen `m10' = sum(`fi'/`n') if `touse'	
    egen `m11' = sum(`fi'*`x'/`n') if `touse'	
    egen `m12' = sum(`fi'*(`x'^2)/`n') if `touse'

    egen `m20' = sum((`fi'^2)/`n') if `touse'	
    egen `m21' = sum((`fi'^2)*`x'/`n') if `touse'	
    egen `m22' = sum((`fi'^2)*(`x'^2)/`n') if `touse'	
    egen `m23' = sum((`fi'^2)*(`x'^3)/`n') if `touse'	
    egen `m24' = sum((`fi'^2)*(`x'^4)/`n') if `touse'	

    egen `t10' = sum(`fi'*(log(`x'))/`n') if `touse'	
    egen `t20' = sum((`fi'^2)*(log(`x'))/`n') if `touse'

    egen `t11' = sum(`fi'*`x'*(log(`x'))/`n') if `touse'	
    egen `t21' = sum((`fi'^2)*`x'*(log(`x'))/`n') if `touse'	
    egen `t22' = sum((`fi'^2)*(`x'^2)*(log(`x'))/`n') if `touse'	

    egen `t23' = sum((`fi'^2)*((log(`x'))^2)/`n') if `touse'	
    egen `t24' = sum((`fi'^2)*(`x'^2)*((log(`x'))^2)/`n') if `touse'	

    local th0 = `t10'/`m10' - 1
    local th1 = 1 + `t11'/`m11'

    local Y_1 = `m1_1'*`m11'/(`m10')^2
    local Y2 = `m12'*`m10'/(`m11')^2

    /* Generalized entropy inequality measures for alpha = -1, 0, 1, 2 */

    local I_1 = 0.5*((`m1_1'*`m11'*(`m10'^(-2)))-1)	/* a=-1 */
    local I0 = (-`t10'/`m10')+log(`m11'/`m10')	        /* a=0  */
    local I1 = (`t11'/`m11')-log(`m11'/`m10')	        /* a=1  */
    local I2 = 0.5*((`m12'*(`m11'^(-2))*`m10')-1)	/* a=2  */


    /* 
    Asymptotic variance formulae 
        Of form: Vab where a = 0,1,2 (the 3 types of formulae), and
                           b = -1,0,1,2 (the values of alpha)
    	a=0: eqns (19)-(21)
    	a=1: eqns (22)-(25)
    	a=2: eqns (26)-(29)
    */
    local q = (1/(`n'-1))
    local V0_1 = `q'*.25*(`m11'^2)*(`m10'^(-4))*(`m2_2'-(`m1_1'^2))	 
    local se0_1 = sqrt(`V0_1')

    local V00 = `q'*((`t23'-(`t10'^2))/(`m10'^2))
    local se00 = sqrt(`V00')

    local V01 = `q'*((`t24'-(`t11'^2))/(`m11'^2))
    local se01 = sqrt(`V01')

    local V02 = `q'*.25*(`m11'^(-4))*(`m10'^2)*(`m24'-(`m12'^2))
    local se02  = sqrt(`V02')

    * create some local macros in stages given 80 character limit in
    * local macro expression parser [U24.3.4, p182]


    local D1_1 = ((`m22'/`m11'^2)-1) + 2*((`m20'/(`m1_1'*`m11'))-1) 
    local D1_1 = `q'*.25*(`Y_1')^2 * `D1_1'

    local D10 = (`m22'/`m11'^2) + 1 - 2*((`t21'/(`m11'*`m10')) - `th0')
    local D10 = `q'* `D10'

    local D11 = `th1'^2*((`m22'/`m11'^2)+1) - 2*`th1'*((`t22'/`m11'^2)+1)
    local D11 = `q'* `D11'

    local D12 = ((`m22'/`m11'^2)-1) - ((`m23'/(`m12'*`m11'))-1)
    local D12 = `q'*(`Y2'^2)* `D12'

    local V1_1 = `V0_1' + `D1_1'
    local se1_1 = sqrt(`V1_1')

    local V10 = `V00' + `D10'
    local se10 = sqrt(`V10')

    local V11 = `V01' + `D11'
    local se11 = sqrt(`V11')

    local V12 = `V02' + `D12'
    local se12 = sqrt(`V12')

    local D2_1 = ((`m20'/`m10'^2)-1) - ((`m2_1'/(`m1_1'*`m10'))-1)
    local D2_1 = `D2_1' - ((`m21'/(`m11'*`m10'))-1)
    local D2_1 = `q'*(`Y_1'^2)*`D2_1'

    local D20 = 2*`th0'*( (`t20'/`m10'^2)-(`m21'/(`m10'*`m11')) )
    local D20 =  `q'*( (`th0'^2)*((`m20'/`m10'^2)+1) - `D20' )

    local D21 =  2*(`t21' - `th1'*`m21')/(`m10'*`m11')
    local D21 = `q'*( `m20'/`m10'^2 + 1 + `D21' )

    local D22 = .25*((`m20'/`m10'^2)-1) + .5*((`m22'/(`m12'*`m10'))-1)
    local D22 = `q'*(`Y2'^2)*(`D22' - ((`m21'/(`m11'*`m10'))-1) )

    local V2_1 = `V1_1' + `D2_1'
    local se2_1 = sqrt(`V2_1')

    local V20 = `V10' + `D20'
    local se20 = sqrt(`V20')

    local V21 = `V11' + `D21'
    local se21 = sqrt(`V21')

    local V22 = `V12' + `D22'
    local se22 = sqrt(`V22')

    }

    di " "
    di in gr "Generalized entropy inequality measures, GE(a), with asym. s.e.s"
    di in gr _dup(65) "-"
    di in gr _col(4) "a" _col(10) "|" _col(18) "-1" _col(28) " 0" _c 
    di in gr _col(9) " 1" _col(19) " 2"
    di in gr _dup(65) "-"

    di in gr "GE(a)" _col(10) "|" in ye _col(14) %9.5f `I_1' _c
    di in ye _col(2) %9.5f `I0' _col(12) %9.5f `I1' _col(22) %9.5f `I2' 
    di " "

    di in gr "Var0"  _col(10) "|" in ye _col(14) %9.5f `V0_1' _c
    di in ye _col(2) %9.5f `V00' _col(12) %9.5f `V01' _col(22) %9.5f `V02' 

    di in gr "s.e.0" _col(10) "|" in ye _col(14) %9.5f `se0_1' _c
    di in ye _col(2) %9.5f `se00' _col(12) %9.5f `se01' _col(22) %9.5f `se02'

    di in gr "asym. t" _col(10) "|" in ye _col(14) %9.5f `I_1'/`se0_1' _c 
    di in ye _col(2) %9.5f `I0'/`se00' _col(12) %9.5f `I1'/`se01' _c
    di  in ye _col(2) %9.5f `I2'/`se02'

    di in gr "P > |t|" _col(10) "|" _c
    di in ye _col(4) %9.5f tprob(1/`q',`I_1'/`se0_1') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I0'/`se00') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I1'/`se01') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I2'/`se02')

	/* NB use of tprob(df, `t') rather than 2*(1-normprob(`t')) */

    di " "
    di in gr "delta1" _col(10) "|" in ye _col(14) %9.5f `D1_1' _c
    di in ye _col(2) %9.5f `D10' _col(12) %9.5f `D11' _col(22) %9.5f `D12'  

    di in gr "Var1"  _col(10) "|" in ye _col(14) %9.5f `V1_1' _c
    di in ye _col(2) %9.5f `V10' _col(12) %9.5f `V11' _col(22) %9.5f `V12' 

    di in gr "s.e.1" _col(10) "|" in ye _col(14) %9.5f `se1_1' _c
    di in ye _col(2) %9.5f `se10' _col(12) %9.5f `se11' _col(22) %9.5f `se12'

    di in gr "asym. t" _col(10) "|" in ye _col(14) %9.5f `I_1'/`se1_1' _c 
    di in ye _col(2) %9.5f `I0'/`se10' _col(12) %9.5f `I1'/`se11' _c
    di  in ye _col(2) %9.5f `I2'/`se12'

    di in gr "P > |t|" _col(10) "|" _c
    di in ye _col(4) %9.5f tprob(1/`q',`I_1'/`se1_1') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I0'/`se10') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I1'/`se11') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I2'/`se12')
    di " "

    di in gr "delta2" _col(10) "|" in ye _col(14) %9.5f `D2_1' _c
    di in ye _col(2) %9.5f `D20' _col(12) %9.5f `D21' _col(22) %9.5f `D22' 

    di in gr "Var2"  _col(10) "|" in ye _col(14) %9.5f `V2_1' _c
    di in ye _col(2) %9.5f `V20' _col(12) %9.5f `V21' _col(22) %9.5f `V22' 

    di in gr "s.e.2" _col(10) "|" in ye _col(14) %9.5f `se2_1' _c
    di in ye _col(2) %9.5f `se20' _col(12) %9.5f `se21' _col(22) %9.5f `se22'

    di in gr "asym. t" _col(10) "|" in ye _col(14) %9.5f `I_1'/`se2_1' _c 
    di in ye _col(2) %9.5f `I0'/`se20' _col(12) %9.5f `I1'/`se21' _c
    di  in ye _col(2) %9.5f `I2'/`se22'

    di in gr "P > |t|" _col(10) "|" _c
    di in ye _col(4) %9.5f tprob(1/`q',`I_1'/`se2_1') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I0'/`se20') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I1'/`se21') _c
    di in ye _col(2) %9.5f tprob(1/`q',`I2'/`se22')


    /* Monte-Carlo program requires globals or results in order to process,
       so set them: */

    global S_I_1 `I_1'
    global S_V0_1 `V0_1'
    global S_se0_1 `se0_1'
    global S_D1_1 `D1_1'
    global S_V1_1 `V1_1'
    global S_se1_1 `se1_1'
    global S_D2_1 `D2_1'
    global S_V2_1 `V2_1'
    global S_se2_1 `se2_1'

    global S_I0 `I0'
    global S_V00 `V00'
    global S_se00 `se00'
    global S_D10 `D10'
    global S_V10 `V10'
    global S_se10 `se10'
    global S_D20 `D20'
    global S_V20 `V20'
    global S_se20 `se20'

    global S_I1 `I1'
    global S_V01 `V01'
    global S_se01 `se01'
    global S_D11 `D11'
    global S_V11 `V11'
    global S_se11 `se11'
    global S_D21 `D21'
    global S_V21 `V21'
    global S_se21 `se21'

    global S_I2 `I2'
    global S_V02 `V02'
    global S_se02 `se02'
    global S_D12 `D12'
    global S_V12 `V12'
    global S_se12 `se12'
    global S_D22 `D22'
    global S_V22 `V22'
    global S_se22 `se22'

    global S_xmean = `xmean'
    global S_wmean = `wmean'

end

