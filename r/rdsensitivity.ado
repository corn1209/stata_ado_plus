
/*#############################################################

# Sensitivity analysis for randomization inference in RDD

*!version 0.01 15-Feb-2016

Authors: Matias Cattaneo, Rocio Titiunik, Gonzalo Vazquez-Bare

##############################################################*/

version 13

capture program drop rdsensitivity
program define rdsensitivity, rclass
	
	syntax varlist (min=2 max=2 numeric) [if] [in] [, wlist(numlist) tlist(numlist min=1) /*
		*/ saving(string) noDOTS noDRAW verbose ci(numlist min=1 max=2) Cutoff(real 0) STATistic(string)  /*
		*/ p(integer 0) evalat(string) kernel(string) reps(integer 1000) /*
		*/ seed(integer 666) fuzzy(namelist min=1 max=1) ]

	tokenize `varlist'
	local outvar "`1'"
	local runv_aux "`2'"
	
	quietly summarize `runv_aux' `if' `in'
	if(`cutoff' <= r(min) | `cutoff' >= r(max)) {
		display as error "cutoff must be within the range of running variable"
		exit 125
	}
	
	tempvar runvar
	qui gen double `runvar' = `runv_aux'-`cutoff'
	
	if "`statistic'"==""|"`statistic'"=="ttest"{
		local stat "`statistic'"
		local stat_opt "stat(`statistic')"
		local statdisp "Diff. in means"
	}
	else if "`statistic'"=="ksmirnov" {
		local stat "`statistic'"
		local stat_opt "stat(`statistic')"
		local statdisp "Kolmogorov-Smirnov"
	}
	else if "`statistic'"=="ranksum"{
		local stat "`statistic'"
		local stat_opt "stat(`statistic')"
		local statdisp "Rank sum z-stat"
	}
	else {
		di "`statistic' not a valid statistic"
		exit 198
	}
	
	if "`evalat'"!=""&"`evalat'"!="means"&"`evalat'"!="cutoff"{
		di as error "evalat only admits means or cutoff"
		exit 198
	}

	if "`kernel'"!=""{
		local kernel_opt "kernel(`kernel')"
	}
	
	if "`fuzzy'"!=""{
		local fuzzy_opt "fuzzy(`fuzzy')"
		local statdisp "Anderson-Rubin"

	}
	
	if "`if'"!=""{
		gettoken aux if: if
		local ifcond "& `if'"
	}

	
	** Default wlist
	
	if "`wlist'"==""{
		qui rdwinselect `runvar', obsstep(5)
		mat Waux = r(results)
		mat Wvec = Waux[1...,5]
		forv i=1/10{
			local wnext = Wvec[`i',1]
			local wlist "`wlist' `wnext'"
		}
	}

	** Default tlist

	if "`tlist'"==""{
		gettoken wfirst: wlist
		qui {
			tempvar treated
			gen `treated' = `runvar'>=0
			reg `outvar' `treated' if abs(`runvar')<=`wfirst'
			local ci_r = round(_b[`treated']+1.96*_se[`treated'],.01)
			local ci_l = round(_b[`treated']-1.96*_se[`treated'],.01)
			local w_step = round((`ci_r'-`ci_l')/10,.01)
			numlist "`ci_l'(`w_step')`ci_r'"
			local tlist `r(numlist)'
		}
	}
	
	local nw: word count `wlist'
	local nt: word count `tlist'
	local matrows ""
	local matcols ""
	
	if "`evalat'"=="cutoff"{
		local evalr = `cutoff'
		local evall = `cutoff'
		local eval_opt "evall(`evall') evalr(`evalr')"
	}
	
	if "`ci'"!=""{
		tokenize `ci'
		local ci_wind "`1'"
		local ci_lev "`2'"
		
		if "`ci_lev'"==""{
			local ci_lev = .05
		}
		else if `ci_lev'>=1|`ci_lev'<=0{
			di as error "ci level has to be between 0 and 1"
			exit 198
		}
		local colci = 1
		foreach w of numlist `wlist'{
			if `w'!=`ci_wind'{
				local ++colci
			}
			else{
				continue, break
			}
		}

		if `colci'>`nw'{
			di as error "window specified in ci not in wlist"
			exit 198
		}
	}

	mat Res = J(`nt',`nw',.)
	mat Rows = J(`nt',1,.)
	mat Cols = J(`nw',1,.)

	di _newline as text "Running randomization-based test..."
	
	local count = 1
	local col = 1
	foreach w of numlist `wlist'{
		local row = 1
		if "`dots'"==""{
			di as text "w = " as res %9.3f `w' _c
		}
		
		if "`evalat'"=="means"{
			qui sum `runv_aux' if `treated'==1 & abs(`runvar')<=`w' `ifcond' `in'
			local evalr = r(mean)
			qui sum `runv_aux' if `treated'==0 & abs(`runvar')<=`w' `ifcond' `in'
			local evall = r(mean)
			local eval_opt "evall(`evall') evalr(`evalr')"
		}
		
		
		foreach t of numlist `tlist'{
			qui rdrandinf `outvar' `runvar' `if' `in', wl(-`w') wr(`w') p(`p') reps(`reps') nulltau(`t') /*
				*/ `stat_opt' `eval_opt' `kernel_opt' `fuzzy_opt' seed(`seed')
			mat Res[`row',`col'] = r(randpval)
			
			if "`dots'"==""{
				if mod(`count',`nt')!=0{
					di _col(16) as text "." _cont
				}
				else{
					di _col(16) as text "."
				}
			}
			
			local ++row
			local ++count
		}
		local ++col
	}
	
	di _newline as text "Randomization-based test complete."

	local row = 1
	local col = 1
	foreach w of numlist `wlist'{
		mat Cols[`col',1]=`w'
		local wname = round(`w',.001)
		local matcols " `matcols' `""`wname'""'"
		local ++col
	}
	foreach t of numlist `tlist'{
		mat Rows[`row',1]=`t'
		local matrows " `matrows' `""`t'""'"
		local ++row
	}

	mat colnames Res = `matcols'
	mat rownames Res = `matrows'

	if "`verbose'"!=""{
		if colsof(Res)>=10{
			matlist Res[1...,1..10]
		}
		else {
			matlist Res
		}
	}
	
	** Confidence interval

	if "`ci'"!=""{
		
		local count=1
		mata: T=J(`nt',1,.)
		foreach t of numlist `tlist'{
			mata: T[`count',1]=`t'
			local ++count
		}

		mata: confint(`colci',`ci_lev',T)
		
		if cilb!=. & ciub !=.{
			
			di as text _newline "Confidence interval for w = `ci_wind'"
			di as text "{hline 18}{c TT}{hline 23}"
			di as text "{ralign 18:Statistic}{c |}" 		_col(16) "   [" (1-`ci_lev')*100 "% Conf. Interval]"
			di as text "{hline 18}{c +}{hline 23}"
			di as text "{ralign 18:`statdisp'}{c |}" 		_col(22) as res %9.3f cilb _col(34) as res %9.3f ciub
			di as text "{hline 18}{c BT}{hline 23}"
			
			return scalar ci_lb = cilb
			return scalar ci_ub = ciub
		}
		else {
			di _newline as error "Confidence interval cannot be found for chosen window length"
		}
	}
	
	** Plot
	
	preserve
	clear
	qui {
		svmat Rows, name(T)
		expand `nw'
		sort T
		svmat Cols, name(W)
		replace W = W[_n-`nw'] if W == .

		gen pvalue = .

		local n = 1

		forv r=1/`nt'{
			forv c=1/`nw'{
				qui replace pvalue = Res[`r',`c'] in `n'
				local ++n
			}
		}

		rename W1 w
		rename T1 t
		
		if "`draw'"==""{
			twoway contour pvalue t w, ccuts(0(0.05)1)
		}
		
		if "`saving'"!=""{
			save "`saving'", replace
		}
	}
	restore
	
	return matrix results = Res

end


*****************************************
** Mata program to calculate ci

capture mata: mata drop confint()
mata:
void confint(real scalar colci, real scalar level, real matrix T)
{
	R=st_matrix("Res")
	if (!allof(R[,colci]:>=level,0)){
		maxindex(R[,colci]:>=level,1,i=.,j=.)
		st_numscalar("cilb",T[i[1,1],1])
		st_numscalar("ciub",T[i[rows(i),1],1])
	}
	else {
		st_numscalar("cilb",.)
		st_numscalar("ciub",.)
	}

}
end


