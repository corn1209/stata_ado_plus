program define ztpnm_ll
args ll xb lnsigma

quietly {

tempname sigma 
sca `sigma' = exp(`lnsigma')

/* Get points and weights for Gaussian-Hermite quadrature. */
tempvar x w
gen `x'=.
gen `w'=.
_GetQuad, avar(`x') wvar(`w') quad($R)
replace `x' = sqrt(2)*`x'

tempvar li lnpri pri lambda
gen double `lambda'=.
gen double `lnpri'=.
gen double `pri'=.
gen double `li'=0

  forvalues r=1/$R{
   replace `lambda'   = exp(`xb'+`sigma'*`x'[`r'])
   replace `lnpri'    = -`lambda' + $ML_y1*ln(`lambda') - ln(1-exp(-`lambda')) - lngamma($ML_y1 + 1)
   replace `pri'      = exp(`lnpri')  
   replace `li'       = `li' + `pri'*`w'[`r']
  }

replace $f=`li'			/*for vuong test*/

replace `ll' = ln((1/sqrt(_pi))*`li') if $ML_samp

}

end 
