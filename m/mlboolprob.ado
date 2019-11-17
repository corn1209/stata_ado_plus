capture program drop mlboolprob
program define mlboolprob
	version 8
	args lnf $sstring

	tempvar event  
	forvalues i = 1/$n {
	   tempvar ps`i'
	   }
	forvalues i = 1/$n {
	   quietly gen double `ps`i'' = normprob(`theta`i'')
	   }
	local kiss "$keys"
	capture forvalues i = 1/$n {
	   local kiss = subinstr("`kiss'","ps`i'","`ps`i''",.)
	   }
	capture quietly gen double `event' = `kiss'

	if $codek == 121  {
	   quietly gen double `event' = (1-(1-((1-(1-`ps2')*(1-`ps3'))*(1-(1-`ps4')*(1-`ps5'))))*(1-`ps1'))
       }
	if $codek == 112 {
	   quietly gen double `event' = (1-(1-(1-(1-`ps1')*(1-`ps2'))*(1-(1-`ps3')*(1-`ps4')))*(1-`ps5'))
       }

	
	/*quietly gen double `event' = `ps1'*`ps2'*/

	quietly replace `lnf' = ln(`event') if $ML_y1==1
	quietly replace `lnf' = ln(1-(`event')) if $ML_y1==0


   
     

	/*quietly gen double `event' = `ps1'*`ps2'*/

	quietly replace `lnf' = ln(`event') if $ML_y1==1
	quietly replace `lnf' = ln(1-(`event')) if $ML_y1==0

end

