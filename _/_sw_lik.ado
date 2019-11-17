capture program drop _sw_lik
program define _sw_lik /* llvar xbmain xbmain2 sigma xbclassif */
version 5.0

 quietly {
	local lnf "`1'"
	local xb1 "`2'"
	local xb2 "`3'"
	local sigm "`4'"
	local xb3 "`5'"
	local y1    : word 1 of $S_mldepn
	local y2    : word 2 of $S_mldepn
	tempvar lnf1 lnf2 lamh os 
	gen double `lnf1' = .
	gen double `lnf2' = .
	gen double `lamh' = .
	gen double `os' = .
	replace `os' = 1/(2*(`sigm'^2))
	replace `lnf1' = sqrt( `os'/_pi ) * exp( -`os'*((`y1'-`xb1')^2) )
	replace `lnf2' = sqrt( `os'/_pi ) * exp( -`os'*((`y2'-`xb2')^2) )
	replace `lamh' = /* exp(`xb3')/(1+exp(`xb3')) */ normprob(-`xb3')
	replace `lnf' =  ln(`lamh'*`lnf1' + (1-`lamh')*`lnf2')
}

end
