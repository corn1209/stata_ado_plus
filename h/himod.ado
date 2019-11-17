program define himod

* part of a program to conduct a Blinder-Oaxaca decomposition of earnings.
* Requires regression for subgroup of high wage persons to be
* run first, followed by himod [,ds]. Then the regression for the
* low wage persons, followed by lomod [,ds]. Then decomp is run.
*! ver 1.6 25jan05 - added Tobit correction & removed Heck option (now built-in)
* ver 1.5 30sept04 - added Heckman option
* ver 1.4 26nov02 - added weighting
* ver 1.3 25july02 - fixed typo in himod and lomod
* ver 1.2  4feb02 - changed output presentation
* ver 1.1 14apr00 - original program developed

version 8.2
syntax [fweight aweight] [, ds heck] 

mat beta=e(b)
mat beta=beta'
local total=0
local varnms : rownames(beta)
local k=rowsof(beta)
if e(cmd)=="heckman" | e(cmd)=="tobit" {
*if "`heck'" ~="" {
     local n=0
     while `n'<`k' {
     local `++n'
     local varnm: word `n' of `varnms'
     local reducednms="`reducednms' `varnm'"
     if "`varnm'"=="_cons"{
          local k=`n'
          }
     }
mat hicoef=J(`k',1,1)
mat rownames hicoef=`reducednms'
foreach r of numlist 1/`k'{
     mat hicoef[`r',1]=beta[`r',1]
     }
}
else{
    mat hicoef=beta
}
mat himean=J(`k',1,1)
mat hipred=J(`k',1,1)
foreach r of numlist 1/`k'{
  local varnm: word `r' of `varnms'
  if `r'<`k'{
    quietly sum `varnm' if e(sample) [`weight' `exp']
    local varmn=r(mean)
    mat himean[`r',1]=`varmn'
  }
  mat hipred[`r',1]=hicoef[`r',1]*himean[`r',1]  
  local total=`total'+hipred[`r',1]
}
local dtotal=exp(`total')
mat hifinal=hicoef,himean,hipred
mat colnames hifinal=Coeffs Means Predictions
if "`ds'" ~="" {
     di
     di as text "{title:Coefficients, means & predictions for high model}"
     di
     di as text "{hline 13}{c TT}{hline 40}"
     di as text "{ralign 12: Variable} {c |} {ralign 13: Coefficent}" /*
          */ "{ralign 12: Mean} {ralign 13: Prediction}"
     di in text "{hline 13}{c +}{hline 40}"
     foreach r of numlist 1/`k'{
         local varnm: word `r' of `varnms'
         local varnm=abbrev("`varnm'",15)
         di as text "{ralign 12:`varnm'} {c |} {col 20}" /*
            */ as result %9.3f hifinal[`r',1] "{col 32}" /*
            */ as result %9.3f hifinal[`r',2] "{col 46}" /*
            */ as result %9.3f hifinal[`r',3] 
     }
     di as text "{hline 13}{c BT}{hline 40}"
     di
     di as text "Prediction (ln): " as result %9.3f `total'
     di as text "Prediction ($): " as result %9.2f `dtotal'
     }

end
