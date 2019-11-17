capture program drop _sw_lik2
program define _sw_lik2 /* llvar xbmain xbmain2 sigma sigma2 xbclassif */
version 5.0

 quietly {
	local lnf "`1'"
	local xb1 "`2'"
	local xb2 "`3'"
	local sigm "`4'"
	local sigm2 "`5'"
	local xb3 "`6'"
	local y1    : word 1 of $S_mldepn
	local y2    : word 2 of $S_mldepn
	tempvar lnf1 lnf2 lamh os os2
	gen double `lnf1' = .
	gen double `lnf2' = .
	gen double `lamh' = .
	gen double `os' = .
	gen double `os2' = .
	replace `os' = 1/(2*(`sigm'^2))
	replace `os2' = 1/(2*(`sigm2'^2))
	replace `lnf1' = sqrt( `os'/_pi ) * exp( -`os'*((`y1'-`xb1')^2) )
	replace `lnf2' = sqrt( `os2'/_pi ) * exp( -`os2'*((`y2'-`xb2')^2) )
	replace `lamh' = /* exp(`xb3')/(1+exp(`xb3')) */ normprob(-`xb3') 
	replace `lnf' =  ln(`lamh'*`lnf1' + (1-`lamh')*`lnf2')
}

end
