*! spgmmxt V1.0 21/06/2012
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage:               http://emadstat.110mb.com/stata.htm
*! WebPage at IDEAS:      http://ideas.repec.org/f/psh494.html
*! WebPage at EconPapers: http://econpapers.repec.org/RAS/psh494.htm
program define spgmmxt, eclass 
version 11.0
syntax varlist [aw fw iw pw] , nc(str) [WMFile(str) diag LL(str) ///
 stand vce(passthru) MFX(str) NOLog tobit INV2 LMHet LMSPac ROBust ///
 gmm(int 1) zero coll INV iter(int 100) level(passthru) PREDict(str) ///
 RESid(str) tech(str) tolog TESTs DN NOCONStant LMNorm]
local sthlp spgmmxt
if "`tests'"!="" {
local lmspac "lmspac"
local diag "diag"
local lmhet "lmhet"
local lmnorm "lmnorm"
 }
 if "`mfx'"!="" {
if !inlist("`mfx'", "lin", "log") {
di 
di as err " {bf:mfx( )} {cmd:must be} {bf:mfx({it:lin})} {cmd:for Linear Model, or} {bf:mfx({it:log})} {cmd:for Log-Log Model}"
exit
 }
 }
 if inlist("`mfx'", "log") {
 if "`tolog'"=="" {
di 
di as err " {bf:tolog} {cmd:must be combined with} {bf:mfx(log)}"
 exit
 }
 } 
tempvar Bw D DE DF1 DumE E e dcs XQX_
tempvar EE Eo Es Ev Ew Hat ht idv itv LE LEo P Q SBB Sig2 SSE
tempvar SST Time tm U U2 Ue wald weit Wi Wio WS X X0 eigw Bo
tempvar Xb XB Xo XQ Yb Yh Yh2 Yhb Yt YY YYm YYv Yh_ML Ue_ML Z
tempname A B b B1 b1 B12 B1b B1t b2 BB2 Beta BetaSP Bm BOLS Bt Bv Bv1 Bx
tempname Cov Cov1 Cov2s CovC D den DVE DVNE Dx E E1 EE1 Eg Eo Eom Ew F
tempname h Hat hjm idv itv IPhi J K L lf lmhs Ls M M1 M2 mfxe mfxlin mfxlog
tempname P Phi Pm q Q Qr q1 q2 s kbm IN xMx v V1 v1 V1s v2 In WXb
tempname S11 S12 sd Sig2 Sig2b Sig2o Sig2u Sig2w Sn SSE SST1 SST2
tempname Vec vh VM VP VQ Vs W W1 W2 Wald We Wi Wi1 Wio WY X X0 XB V
tempname xq Xx Y Yh Yi YMB YYm YYv Z Z0 Z1 Zo X0 WMTD Sw Sig2n Sig2o1 kb
tempname Yfe Xfe Yre Xre WS D WW eVec eigw Xo mh n nw olsin TRa2 wWw1 xBx
tempname N DF kx kb NC NT Nmiss llf kbd Sig21 dfab sigox Dim wmat xAx xAx2
tempname minEig maxEig waldm waldmp waldm_df waldr waldrp waldr_df
tempname waldl waldlp waldl_df waldx waldxp waldx_df waldj waldjp waldj_df
tempvar `varlist'
gettoken yvar xvar : varlist
local both : list yvar & xvar
if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS and RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS: `xvar'"
 exit
 }
 if "`xvar'"=="" {
di as err "  {bf:Independent Variable(s) must be combined with Dependent Variable}"
 exit
 }
 local both : list yvar & xvar
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS & RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS:`xvar'"
 exit
 } 
 if "`weight'" != "" {
 local wgt "[`weight'`exp']"
 if "`weight'" == "pweight" {
 local awgt "[aw`exp']"
 }
 else local awgt "`wgt'"
 }
di
scalar `N'=_N
scalar `NC'=`nc'
scalar `NT'=_N/`NC'
local N=`N'
local NT=`NT'
local NC=`NC'
if "`wmfile'" != "" {
preserve
qui use `"`wmfile'"', clear
qui summ
if `NT' !=int(`N'/r(N)) {
di 
di as err " Cross Section Weight Matrix = " r(N)
di as err " Time Series obs             = " `NT'
di as err " Sample Size (Number of obs) = " `N'
di as res " {bf:(Cross Sections x Time) must be Equal Sample Size}"
di as err " {bf:Spatial Cross Section Weight Matrix Dimension not correct}"
 exit
 }
mkmat * , matrix(_WB)
qui egen ROWSUM=rowtotal(*)
qui count if ROWSUM==0
local NN=r(N)
if `NN'==1 {
di as err "*** {bf:Spatial Weight Matrix Has (`NN') Location with No Neighbors}"
 }
else if `NN'>1 {
di as err "*** {bf:Spatial Weight Matrix Has (`NN') Locations with No Neighbors}"
 }
local NROW=rowsof(_WB)
local NCOL=colsof(_WB)
if `NROW'!=`NCOL' {
di as err "*** {bf:Spatial Weight Matrix is not Square}"
 exit
 }
di _dup(78) "{bf:{err:=}}"
if "`stand'"!="" {
di as res "{bf:*** Standardized Weight Matrix: `N'x`N' - NC=`NC' NT=`NT' (Normalized)}"
matrix `Xo'=J(`NC',1,1)
matrix WB=_WB*`Xo'*`Xo''
mata: X = st_matrix("_WB")
mata: Y = st_matrix("WB")
mata: _WS=divide(X, Y)
mata: _WS=st_matrix("_WS",_WS)
mata: _WS = st_matrix("_WS")
 if "`inv'"!="" {
di as res "{bf:*** Inverse Standardized Weight Matrix (1/W)}"
mata: _WS=divide(1, _WS)
mata: _WS=st_matrix("_WS",_WS)
 }
 if "`inv2'"!="" {
di as res "{bf:*** Inverse Squared Standardized Weight Matrix (1/W^2)}"
mata: _WS=product(_WS, _WS)
mata: _WS=divide(1, _WS)
mata: _WS=st_matrix("_WS",_WS)
 }
qui forvalue i=1/`NC' {
qui forvalue j=1/`NC' {
if _WS[`i',`j']==. {
matrix _WS[`i',`j']= 0
 }
 }
 }
matrix WCS=_WS
 }
else {
di as res "{bf:*** Binary (0/1) Weight Matrix: `N'x`N' - NC=`NC' NT=`NT' (Non Normalized)}"
matrix WCS=_WB
 }
matrix eigenvalues eigw eVec = WCS
matrix eigw=vecdiag(diag(eigw')#I(`NT'))'
matrix WMB=WCS#I(`NT')
di _dup(78) "{bf:{err:=}}"
restore
qui cap drop `eigw'
qui svmat eigw , name(`eigw')
qui rename `eigw'1 `eigw'
qui cap confirm numeric var `eigw'
 }
ereturn scalar Nn=_N
qui marksample touse
qui cap count 
local N = r(N)
local NC=`nc'
local NT=`N'/`NC'
qui count 
local N = _N
qui markout `touse' `varlist' , strok
qui mean `varlist'
scalar `Nmiss' = e(N)
if "`zero'"=="" {
if `N' !=`Nmiss' {
di
di as err "*** {bf:Observations have {bf:(" `N'-`Nmiss' ")} Missing Values}"
di as err "*** {bf:You can use {cmd:zero} option to Convert Missing Values to Zero}"
 exit
 }
 }
qui cap drop `idv'
qui cap drop `itv'
qui cap drop `Time'
qui gen `Time'=_n
qui gen `idv'=0 
qui gen `itv'=0 
qui forvalue i = 1/`nc' {
qui summ `Time' , meanonly
local min=int(`NT'*`i'-`NT'+1)
local max=int(`NT'*`i')
 replace `idv'= `i' in `min'/`max'
 replace `itv'= `Time'-`min'+1 in `min'/`max'
 }
mkmat `idv' , matrix(idv)
mkmat `itv' , matrix(itv)
qui summ `idv' 
 local NC=r(max)
qui summ `itv' 
 local NT=r(max)
 if `N' != `NC'*`NT' {
di 
di as err " Cross Section Units = " `NC'
di as err " Time Series obs     = " `NT'
di as err " Sample Size (Number of obs) = " `N'
di as res " {bf:(Cross Sections x Time) must be Equal Sample Size}"
di as err " {bf:Check Correct Number Units, Unequal Time Series not Allowed}"
 exit
 }
scalar `Dim' = `N'
local MSize= `Dim'
if `c(matsize)' < `MSize' {
di as err " {bf:Current Matrix Size = (`c(matsize)')}"
di as err " {bf:{help matsize##|_new:matsize} must be >= Sample Size" as res " (`MSize')}"
qui set matsize `MSize'
di as res " {bf:matsize increased now to = (`c(matsize)')}"
 }
qui marksample touse
markout `touse' `varlist' `zvar' , strok
local NC=`NC'
local NT=`NT'
 if "`zero'"!="" {
tempvar ZEROMISS
qui foreach var of local varlist {
qui gen `ZEROMISS'`var'=`var'
qui replace `var'=0 if `var'==.
 }
 }
_vce_parse , opt(Robust oim opg) argopt(CLuster): `wgt' , `vce'
gettoken yvar xvar : varlist
 mlopts mlopts, `cns' `vce' `coll' iter(`iter') tech(`tech')
_fv_check_depvar `yvar'
 if "`tolog'"!="" {
di _dup(45) "-"
di as err " {cmd:** Data Have been Transformed to Log Form **}"
di as txt " {cmd:** `varlist'} "
di _dup(45) "-"
qui foreach var of local varlist {
tempvar xyind`var'
qui gen `xyind`var''=`var'
qui replace `var'=ln(`var')
qui replace `var'=1 if `var'==0
qui replace `var'=0 if `var'==.
 }
 }
mkmat `yvar' , matrix(`Y')
tempname WS1 xyvar
mkmat `yvar' , matrix(`xyvar')
matrix `WS1'= WMB
qui forvalue i = 1/1 {
qui cap drop w`i'y_*
tempname w`i'y_`yvar'
matrix `w`i'y_`yvar'' = `WS`i''*`xyvar'
svmat  `w`i'y_`yvar'' , name(w`i'y_`yvar')
rename  w`i'y_`yvar'1 w`i'y_`yvar'
label variable w`i'y_`yvar' `"AR(`i') `yvar' Spatial Lag"'
 }
qui forvalue i = 1/1 {
qui foreach var of local xvar {
qui cap drop w`i'x_`var'
tempname w`i'x_`var'
mkmat `var' , matrix(`xyvar')
matrix `w`i'x_`var'' = `WS`i''*`xyvar'
svmat `w`i'x_`var'' , name(w`i'x_`var')
rename w`i'x_`var'1 w`i'x_`var'
label variable w`i'x_`var' `"AR(`i') `var' Spatial Lag"'
 }
 }

scalar spat_llt=0
 if "`ll'" != "" {
qui replace `yvar' = 0 if `yvar' <= `ll'
qui local llt `"`ll'"'
scalar spat_llt=`llt'
qui count if `yvar' == 0
local minyvar=r(N)
if `minyvar' > 0 { 
di _dup(60) "-"
di "{cmd:***} {bf:{err: Truncated Dependent Variable Lower Limit =} `llt'}"
di "{cmd:***} {bf:{err: Left-Censoring Dependent Variable Number =} `minyvar'}"
di _dup(60) "-"
 }
 }
qui xtset `idv' `itv'
qui gen `X0'=1
qui mkmat `X0' , matrix(`X0')
qui tabulate `idv' , generate(`dcs')
mkmat `dcs'* , matrix(`D')
matrix `P'=`D'*invsym(`D''*`D')*`D''
matrix `Q'=I(`N')-`P'
matrix `Xo'=J(`NT',1,1)
matrix `D'=I(`NC')#`Xo'
local SPXvar `xvar' 
 if "`coll'"=="" {
_rmcoll `SPXvar' , `noconstant' `coll' forcedrop
local SPXvar "`r(varlist)'"
 }
local kx : word count `SPXvar'
scalar `kb'=`kx'+1
scalar `DF'=`N'-`kx'-`NC'
if "`noconstant'"!="" {
qui mkmat `SPXvar' , matrix(`X')
scalar `kb'=`kx'
qui mean `SPXvar'
 }
 else { 
qui mkmat `SPXvar' `X0' , matrix(`X')
scalar `kb'=`kx'+1
qui mean `SPXvar' `X0'
 }
matrix `Xb'=e(b)
qui mean `yvar'
matrix `Yb'=e(b)'
if "`dn'"!="" {
scalar `DF'=`N'
 }
global spat_kx=`kx'
global spat_kxw=2*`kx'
ereturn scalar df_m=$spat_kx
qui gen `Wi'=1 
qui gen `weit' = 1 
scalar `llf'=.
matrix `In'=I(`N')
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Spatial Panel Autoregressive Generalized Method of Moments (SPGMM)}}"
di _dup(78) "{bf:{err:=}}"
qui cap drop Time
ereturn scalar kb=`kb'
ereturn scalar DF=`DF'
ereturn scalar Nn=`N'
ereturn scalar NC=`NC'
ereturn scalar NT=`NT'
qui spgmmxts `yvar' `SPXvar' `wgt' , gmm(`gmm') `noconstant' `vce' `robust' `tobit' `dn'
scalar `llf'=e(llf)
matrix `Beta'=e(b)
matrix `Cov'= e(V)
matrix `Beta'=`Beta'[1,1..`kb']'
matrix `Cov'=`Cov'[1..`kb', 1..`kb']
matrix `Yh_ML'=`X'*`Beta'
matrix `Ue_ML'=`Q'*(`Y'-`Yh_ML')
qui svmat `Yh_ML' , name(`Yh_ML')
qui rename `Yh_ML'1 `Yh_ML'
qui svmat `Ue_ML' , name(`Ue_ML')
qui rename `Ue_ML'1 `Ue_ML'
local N=_N
matrix Yh_ML=`Yh_ML'
matrix Ue_ML=`Ue_ML'
if "`predict'"!="" | "`resid'"!="" {
mata: Yhxt= st_matrix("Yh_ML")
mata: Uext= st_matrix("Ue_ML")
 }

tempname SSEo Sigo r2bu r2bu_a r2raw r2raw_a f fp wald waldp
tempname r2v r2v_a fv fvp r2h r2h_a fh fhp SSTm SSE1 SST11 SST21 Rho
matrix `SSE'=`Ue_ML''*`Ue_ML'
scalar `SSEo'=`SSE'[1,1]
matrix `Sig2o'=(`Ue_ML''*`Ue_ML')/`DF'
scalar `Sig2n'=`SSEo'/`N'
scalar `Sigo'=sqrt(`Sig2o'[1,1])
scalar `Sig2o1'=`Sig2o'[1,1]
qui summ `Yh_ML' 
local NUM=r(Var)
qui summ `yvar' 
local DEN=r(Var)
scalar `r2v'=`NUM'/`DEN'
scalar `r2v_a'=1-((1-`r2v')*(`N'-1)/`DF')
scalar `fv'=`r2v'/(1-`r2v')*(`N'-`kb')/(`kx')
scalar `fvp'=Ftail(`kx', `DF', `fv')
qui correlate `Yh_ML' `yvar' 
scalar `r2h'=r(rho)*r(rho)
scalar `r2h_a'=1-((1-`r2h')*(`N'-1)/`DF')
scalar `fh'=`r2h'/(1-`r2h')*(`N'-`kb')/(`kx')
scalar `fhp'=Ftail(`kx', `DF', `fh')
matrix `SSE'=`Ue_ML''*`Ue_ML'
local Sig=`Sigo'
qui summ `yvar' 
local Yb=r(mean)
qui gen `YYm'=(`yvar'-`Yb')^2
qui summ `YYm'
qui scalar `SSTm' = r(sum)
qui gen `YYv'=(`yvar')^2
qui summ `YYv'
local SSTv = r(sum)
qui summ `weit' 
qui gen `Wi1'=sqrt(`weit'/r(mean))
mkmat `Wi1' , matrix(`Wi1')
matrix `P' =diag(`Wi1')
qui gen `Wio'=(`Wi1') 
mkmat `Wio' , matrix(`Wio')
matrix `Wio'=diag(`Wio')
matrix `Pm' =`Wio'
matrix `IPhi'=`P''*`P'
matrix `Phi'=invsym(`P''*`P')
matrix `J'= J(`N',1,1)
matrix `D'=(`J'*`J''*`IPhi')/`N'
matrix `SSE'=`Ue_ML''*`IPhi'*`Ue_ML'
matrix `SST1'=(`Y'-`D'*`Y')'*`IPhi'*(`Y'-`D'*`Y')
matrix `SST2'=(`Y''*`Y')
scalar `SSE1'=`SSE'[1,1]
scalar `SST11'=`SST1'[1,1]
scalar `SST21'=`SST2'[1,1]
scalar `r2bu'=1-`SSE1'/`SST11'
scalar `r2bu_a'=1-((1-`r2bu')*(`N'-1)/`DF')
scalar `r2raw'=1-`SSE1'/`SST21'
scalar `r2raw_a'=1-((1-`r2raw')*(`N'-1)/`DF')
scalar `f'=`r2bu'/(1-`r2bu')*(`N'-`kb')/`kx'
scalar `fp'= Ftail(`kx', `DF', `f')
scalar `wald'=`f'*`kx'
scalar `waldp'=chi2tail(`kx', abs(`wald'))
if `llf' == . {
scalar `llf'=-(`N'/2)*log(2*_pi*`SSEo'/`N')-(`N'/2)
 }
local Nof =`N'
local Dof =`DF'
matrix `B'=`Beta''
if "`noconstant'"!="" {
matrix colnames `Cov' = `SPXvar'
matrix rownames `Cov' = `SPXvar'
matrix colnames `B'   = `SPXvar'
 }
 else { 
matrix colnames `Cov' = `SPXvar' _cons
matrix rownames `Cov' = `SPXvar' _cons
matrix colnames `B'   = `SPXvar' _cons
 }
yxregeq `yvar' `SPXvar'
di as txt _col(3) "Sample Size" _col(21) "=" %12.0f as res `N' _col(37) "|" _col(41) as txt "Cross Sections Number" _col(65) "=" _col(73) %5.0f as res `nc'
ereturn post `B' `Cov' , dep(`yvar') obs(`Nof') dof(`Dof')
qui test `SPXvar'
scalar `f'=r(F)
scalar `fp'= Ftail(`kx', `DF', `f')
scalar `wald'=`f'*`kx'
scalar `waldp'=chi2tail(`kx', abs(`wald'))
di as txt _col(3) "Wald Test" _col(21) "=" %12.4f as res `wald' _col(37) "|" _col(41) as txt "P-Value > Chi2(" as res `kx' ")" _col(65) "=" %12.4f as res `waldp'
di as txt _col(3) "F-Test" _col(21) "=" %12.4f as res `f' _col(37) "|" _col(41) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(65) "=" %12.4f as res `fp'
di as txt _col(2) "(Buse 1973) R2" _col(21) "=" %12.4f as res `r2bu' _col(37) "|" as txt _col(41) "Raw Moments R2" _col(65) "=" %12.4f as res `r2raw'
ereturn scalar r2bu =`r2bu'
ereturn scalar r2bu_a=`r2bu_a'
ereturn scalar f =`f'
ereturn scalar fp=`fp'
ereturn scalar wald =`wald'
ereturn scalar waldp=`waldp'
di as txt _col(2) "(Buse 1973) R2 Adj" _col(21) "=" %12.4f as res `r2bu_a' _col(37) "|" as txt _col(41) "Raw Moments R2 Adj" _col(65) "=" %12.4f as res `r2raw_a'
di as txt _col(3) "Root MSE (Sigma)" _col(21) "=" %12.4f as res `Sigo' as txt _col(37) "|" _col(41) "Log Likelihood Function" _col(65) "=" %12.4f as res `llf'
di _dup(78) "-"
di as txt "- {cmd:R2h}=" %7.4f as res `r2h' _col(17) as txt "{cmd:R2h Adj}=" as res %7.4f `r2h_a' as txt _col(34) "{cmd:F-Test} =" %8.2f as res `fh' _col(51) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(72) %5.4f as res `fhp'
di as txt "- {cmd:R2v}=" %7.4f as res `r2v' _col(17) as txt "{cmd:R2v Adj}=" as res %7.4f `r2v_a' as txt _col(34) "{cmd:F-Test} =" %8.2f as res `fv' _col(51) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(72) %5.4f as res `fvp'
ereturn scalar r2raw =`r2raw'
ereturn scalar r2raw_a=`r2raw_a'
ereturn scalar llf =`llf'
ereturn scalar sig=`Sigo'
ereturn scalar r2h =`r2h'
ereturn scalar r2h_a=`r2h_a'
ereturn scalar r2v =`r2v'
ereturn scalar r2v_a=`r2v_a'
ereturn scalar fh =`fh'
ereturn scalar fv=`fv'
ereturn scalar fhp=`fhp'
ereturn scalar fvp=`fvp'
ereturn scalar kb=`kb'
ereturn scalar kx=`kx'
ereturn scalar DF=`DF'
ereturn scalar Nn=_N
ereturn scalar NC=`NC'
ereturn scalar NT=`NT'
ereturn display , `level'
matrix `b'=e(b)
matrix `V'=e(V)
matrix `Bx' =`b'[1..1, 1..`kx']'

if "`diag'"!= "" {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Panel Model Selection Diagnostic Criteria}}"
di _dup(78) "{bf:{err:=}}"
if `llf' == . {
ereturn scalar llf=-(`N'/2)*ln(2*_pi*`SSEo'/`N')-(`N'/2)
 }
scalar `kbm'=`kb'
ereturn scalar aic=(2*`kbm')-(2*e(llf))
ereturn scalar laic=ln(`SSEo'/`N')+2*`kbm'/`N'
ereturn scalar fpe=(`SSEo'/`DF')*(1+`kbm'/`N')
ereturn scalar sc=(`kbm'*ln(`N'))-(2*e(llf))
ereturn scalar lsc=ln(`SSEo'/`N')+`kbm'*ln(`N')/`N'
ereturn scalar hq=`SSEo'/`N'*ln(`N')^(2*`kbm'/`N')
ereturn scalar rice=`SSEo'/`N'/(1-2*`kbm'/`N')
ereturn scalar shibata=`SSEo'/`N'*(`N'+2*`kbm')/`N'
ereturn scalar gcv=`SSEo'/`N'*(1-`kbm'/`N')^(-2)
di
di as txt "- Log Likelihood Function       LLF" _col(50) " = " as res %10.4f e(llf)
di as txt "- Akaike Final Prediction Error AIC" _col(50) " = " as res %10.4f e(aic)
di as txt "- Schwartz Criterion            SC" _col(50)  " = " as res %10.4f e(sc)
di as txt "- Akaike Information Criterion  ln AIC" _col(50) " = " as res %10.4f e(laic)
di as txt "- Schwarz Criterion             ln SC" _col(50) " = " as res %10.4f e(lsc)
di as txt "- Amemiya Prediction Criterion  FPE" _col(50) " = " as res %10.4f e(fpe)
di as txt "- Hannan-Quinn Criterion        HQ" _col(50) " = " as res %10.4f e(hq)
di as txt "- Rice Criterion                Rice" _col(50) " = " as res %10.4f e(rice)
di as txt "- Shibata Criterion             Shibata" _col(50) " = " as res %10.4f e(shibata)
di as txt "- Craven-Wahba Generalized Cross Validation-GCV" _col(50) as res " = " as res %10.4f e(gcv)
di _dup(78) "-"
 }

if "`lmspac'"!= "" {
tempname B0 B1 B2 b2k B3 B4 chi21 chi22 DEN DIM E EI Ein Esp eWe
tempname I m1k m2k m3k m4k MEAN NUM NUM1 NUM2 NUM3 RJ 
tempname S0 S1 S2 sd SEI SG0 SG1 TRa1 TRa2 trb TRw2 VI wi wj wMw wMw1
tempname WZ0 Xk NUM Zk m2 m4 b2 M eWe1 wWw2 zWz eWy eWy1 CPX SUM DFr
tempvar WZ0 Vm2 Vm4
matrix `wmat'=_WB#I(`NT')
scalar `DFr'=`N'-`kb'
scalar `S1'=0
qui forvalue i = 1/`N' {
qui forvalue j = 1/`N' {
scalar `S1'=`S1'+(`wmat'[`i',`j']+`wmat'[`j',`i'])^2
local j=`j'+1
 }
 }
matrix `zWz'=`X0''*`wmat'*`X0'
scalar `S0'=`zWz'[1,1]
scalar `SG0'=`S0'*2
matrix `WZ0' =`wmat'*`X0'
qui svmat `WZ0' , name(`WZ0')
qui rename `WZ0'1 `WZ0'
qui replace `WZ0'=(`WZ0'+`WZ0')^2 
qui summ `WZ0'
scalar `SG1'=r(sum)
matrix `E'=`Ue_ML'
matrix `eWe'=`E''*`wmat'*`E'
scalar `eWe1'=`eWe'[1,1]
matrix `CPX'=`X''*`X'
matrix `A'=inv(`CPX')
matrix `xAx'=`A'*`X''*`wmat'*`X'
scalar `TRa1'=trace(`xAx')
matrix `xAx2'=`xAx'*`xAx'
scalar `TRa2'=trace(`xAx2')
matrix `wWw1'=(`wmat'+`wmat'')*(`wmat'+`wmat'')
matrix `B'=inv(`CPX')
matrix `xBx'=`B'*`X''*`wWw1'*`X'
scalar `trb'=trace(`xBx')
scalar `VI'=(`N'^2/(`N'^2*`DFr'*(2+`DFr')))*((`S1'/2)+2*`TRa2'-`trb'-2*`TRa1'^2/`DFr')
scalar `SEI'=sqrt(`VI')
scalar `I'=(`N'/`S0')*`eWe1'/`SSEo'
scalar `EI'=-(`N'*`TRa1')/(`DFr'*`N')
ereturn scalar mi1=(`I'-`EI')/`SEI'
ereturn scalar mi1p=2*(1-normal(abs(e(mi1))))
 matrix `wWw2'=`wmat''*`wmat'+`wmat'*`wmat'
scalar `TRw2'=trace(`wWw2')
 matrix `WY'=`wmat'*`Y'
 matrix `eWy'=`E''*`WY'
scalar `eWy1'=`eWy'[1,1]
 matrix `WXb'=`wmat'*`X'*`Beta'
 matrix `IN'=I(`N')
 matrix `M'=inv(`CPX')
 matrix `xMx'=`IN'-`X'*`M'*`X''
 matrix `wMw'=`WXb''*`xMx'*`WXb'
scalar `wMw1'=`wMw'[1,1]
scalar `RJ'=1/(`TRw2'+`wMw1'/`Sig2o1')
ereturn scalar lmerr=((`eWe1'/`Sig2o1')^2)/`TRw2'
ereturn scalar lmlag=((`eWy1'/`Sig2o1')^2)/(`TRw2'+`wMw1'/`Sig2o1') 
ereturn scalar lmerrr=(`eWe1'/`Sig2o1'-`TRw2'*`RJ'*(`eWy1'/`Sig2o1'))^2/(`TRw2'-`TRw2' *`TRw2'*`RJ')
ereturn scalar lmlagr=(`eWy1'/`Sig2o1'-`eWe1'/`Sig2o1')^2/((1/`RJ')-`TRw2')
ereturn scalar lmsac1=e(lmerr)+e(lmlagr)
ereturn scalar lmsac2=e(lmlag)+e(lmerrr)
ereturn scalar lmerrp=chi2tail(1, abs(e(lmerr)))
ereturn scalar lmerrrp=chi2tail(1, abs(e(lmerrr)))
ereturn scalar lmlagp=chi2tail(1, abs(e(lmlag)))
ereturn scalar lmlagrp=chi2tail(1, abs(e(lmlagr)))
ereturn scalar lmsac1p=chi2tail(2, abs(e(lmsac1)))
ereturn scalar lmsac2p=chi2tail(2, abs(e(lmsac2)))
scalar `DIM'=rowsof(`wmat')
 matrix `m2'=J(1,1,0)
 matrix `m4'=J(1,1,0)
 matrix `b2'=J(1,1,0)
 matrix `M'=J(1,4,0)
local j=1
 while `j'<=4 {
 tempvar EQsq
qui gen `EQsq' = `Ue_ML'^`j'
qui summ `EQsq' , mean 
 matrix `M'[1,`j'] = r(sum)
local j=`j'+1
 }
qui summ `Ue_ML' , mean
scalar `MEAN'=r(mean)
qui replace `Ue_ML'=`Ue_ML'-`MEAN' 
qui gen `Vm2'=`Ue_ML'^2 
qui summ `Vm2' , mean
 matrix `m2'[1,1]=r(mean)	
scalar `m2k'=r(mean)
qui gen `Vm4'=`Ue_ML'^4
qui summ `Vm4' , mean
 matrix `m4'[1,1]=r(mean)	
scalar `m4k'=r(mean)
 matrix `b2'[1,1]=`m4k'/(`m2k'^2)
 mkmat `Ue_ML' , matrix(`Ue_ML')
scalar `S0'=0
scalar `S1'=0
scalar `S2'=0
local i=1
 while `i'<=`N' {
scalar `wi'=0
scalar `wj'=0
local j=1
 while `j'<=`N' {
scalar `S0'=`S0'+`wmat'[`i',`j']
scalar `S1'=`S1'+(`wmat'[`i',`j']+`wmat'[`j',`i'])^2
scalar `wi'=`wi'+`wmat'[`i',`j']
scalar `wj'=`wj'+`wmat'[`j',`i']
local j=`j'+1
 }
scalar `S2'=`S2'+(`wi'+`wj')^2
local i=`i'+1
 }
scalar `S1'=`S1'/2
scalar `m2k'=`m2'[1,1]
scalar `b2k'=`b2'[1,1]
matrix `Zk'=`Ue_ML'[1...,1]
matrix `Zk'=`Zk''*`wmat'*`Zk'
scalar `Ein'=-1/(`N'-1)
scalar `NUM1'=`N'*((`N'^2-3*`N'+3)*`S1'-(`N'*`S2')+(3*`S0'^2))
scalar `NUM2'=`b2k'*((`N'^2-`N')*`S1'-(2*`N'*`S2')+(6*`S0'^2))
scalar `DEN'=(`N'-1)*(`N'-2)*(`N'-3)*(`S0'^2)
scalar `sd'=sqrt((`NUM1'-`NUM2')/`DEN'-(1/(`N'-1))^2)
ereturn scalar mig=`Zk'[1,1]/(`S0'*`m2k')
ereturn scalar migz=(e(mig)-`Ein')/`sd'
ereturn scalar migp=2*(1-normal(abs(e(migz))))
ereturn scalar mi1z=(e(mi1)-`Ein')/`sd'
scalar `m2k'=`m2'[1,1]
scalar `b2k'=`b2'[1,1]
matrix `Zk'=`Ue_ML'[1...,1]
scalar `SUM'=0
local i=1
 while `i'<=`N' {
local j=1
 while `j'<=`N' {
scalar `SUM'=`SUM'+`wmat'[`i',`j']*(`Zk'[`i',1]-`Zk'[`j',1])^2
local j=`j'+1
 }
local i=`i'+1
 }
scalar `NUM1'=(`N'-1)*`S1'*(`N'^2-3*`N'+3-(`N'-1)*`b2k')
scalar `NUM2'=(1/4)*(`N'-1)*`S2'*(`N'^2+3*`N'-6-(`N'^2-`N'+2)*`b2k')
scalar `NUM3'=(`S0'^2)*(`N'^2-3-((`N'-1)^2)*`b2k')
scalar `DEN'=(`N')*(`N'-2)*(`N'-3)*(`S0'^2)
scalar `sd'=sqrt((`NUM1'-`NUM2'+`NUM3')/`DEN')
ereturn scalar gcg=((`N'-1)*`SUM')/(2*`N'*`S0'*`m2k')
ereturn scalar gcgz=(e(gcg)-1)/`sd'
ereturn scalar gcgp=2*(1-normal(abs(e(gcgz))))
scalar `B0'=((`N'^2)-3*`N'+3)*`S1'-`N'*`S2'+3*(`S0'^2)
scalar `B1'=-(((`N'^2)-`N')*`S1'-2*`N'*`S2'+6*(`S0'^2))
scalar `B2'=-(2*`N'*`S1'-(`N'+3)*`S2'+6*(`S0'^2))
scalar `B3'=4*(`N'-1)*`S1'-2*(`N'+1)*`S2'+8*(`S0'^2)
scalar `B4'=`S1'-`S2'+(`S0'^2)
scalar `m1k'=`M'[1,1]
scalar `m2k'=`M'[1,2]
scalar `m3k'=`M'[1,3]
scalar `m4k'=`M'[1,4]
 matrix `Xk'=`Ue_ML'[1...,1]
 matrix `NUM'=`Xk''*`wmat'*`Xk'
scalar `DEN'=0
local i=1
 while `i'<=`N' {
local j=1
 while `j'<=`N' {
 if `i'!=`j' {
scalar `DEN'=`DEN'+`Xk'[`i',1]*`Xk'[`j',1]
 }
local j=`j'+1
 }
local i=`i'+1
 }
ereturn scalar gog=`NUM'[1,1]/`DEN'
scalar `Esp'=`S0'/(`N'*(`N'-1))
scalar `NUM'=(`B0'*`m2k'^2)+(`B1'*`m4k')+(`B2'*`m1k'^2*`m2k') ///
 +(`B3'*`m1k'*`m3k')+(`B4'*`m1k'^4)
scalar `DEN'=(((`m1k'^2)-`m2k')^2)*`N'*(`N'-1)*(`N'-2)*(`N'-3)
scalar `sd'=(`NUM'/`DEN')-((`Esp')^2)
ereturn scalar gogz=(e(gog)-`Esp')/sqrt(`sd')
ereturn scalar gogp=2*(1-normal(abs(e(gogz))))
scalar `chi21'=invchi2(1,0.95)
scalar `chi22'=invchi2(2,0.95)
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:*** Spatial Panel Aautocorrelation Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt _col(2) "{bf: Ho: Error has No Spatial AutoCorrelation}"
di as txt _col(2) "{bf: Ha: Error has    Spatial AutoCorrelation}"
di
di as txt "- GLOBAL Moran MI" as res _col(30) "=" %9.4f e(mig) _col(45) as txt "P-Value > Z(" %6.3f e(migz) ")" _col(67) %5.4f as res e(migp)
di as txt "- GLOBAL Geary GC" as res _col(30) "=" %9.4f e(gcg) _col(45) as txt "P-Value > Z(" %5.3f e(gcgz) ")" _col(67) %5.4f as res e(gcgp)
di as txt "- GLOBAL Getis-Ords GO" as res _col(30) "=" %9.4f e(gog) as txt _col(45) "P-Value > Z(" %5.3f e(gogz) ")" _col(67) %5.4f as res e(gogp)
di _dup(78) "-"
di as txt "- Moran MI Error Test" as res _col(30) "=" %9.4f e(mi1) _col(45) as txt "P-Value > Z(" %5.3f e(mi1z) ")" _col(67) %5.4f as res e(mi1p)
di _dup(78) "-"
di as txt "- LM Error (Burridge)" as res _col(30) "=" %9.4f e(lmerr) _col(45) as txt "P-Value > Chi2(1)" _col(67) %5.4f as res e(lmerrp)
di as txt "- LM Error (Robust)" as res _col(30) "=" %9.4f e(lmerrr) _col(45) as txt "P-Value > Chi2(1)" _col(67) %5.4f as res e(lmerrrp)
di _dup(78) "-"
di as txt _col(2) "{bf: Ho: Spatial Lagged Dependent Variable has No Spatial AutoCorrelation}"
di as txt _col(2) "{bf: Ha: Spatial Lagged Dependent Variable has    Spatial AutoCorrelation}"
di
di as txt "- LM Lag (Anselin)" as res _col(30) "=" %9.4f e(lmlag) _col(45) as txt "P-Value > Chi2(1)" _col(67) %5.4f as res e(lmlagp)
di as txt "- LM Lag (Robust)" as res _col(30) "=" %9.4f e(lmlagr) _col(45) as txt "P-Value > Chi2(1)" _col(67) %5.4f as res e(lmlagrp)
di _dup(78) "-"
di as txt _col(2) "{bf: Ho: No General Spatial AutoCorrelation}"
di as txt _col(2) "{bf: Ha:    General Spatial AutoCorrelation}"
di
di as txt "- LM SAC (LMErr+LMLag_R)" as res _col(30) "=" %9.4f e(lmsac2) _col(45) as txt "P-Value > Chi2(2)" _col(67) %5.4f as res e(lmsac2p)
di as txt "- LM SAC (LMLag+LMErr_R)" as res _col(30) "=" %9.4f e(lmsac1) _col(45) as txt "P-Value > Chi2(2)" _col(67) %5.4f as res e(lmsac1p)
di _dup(78) "-"
 }

if "`lmhet'"!= "" {
tempvar Yh Yh2 LYh2 E E2 E3 E4 LnE2 absE time LE ht DumE EDumE U2
tempname mh vh h Q LMh_cwx lmhmss1 mssdf1 lmhmss1p 
tempname lmhmss2 mssdf2 lmhmss2p dfw0 lmhw01 lmhw01p lmhw02 lmhw02p dfw1 lmhw11
tempname lmhw11p lmhw12 lmhw12p dfw2 lmhw21 lmhw21p lmhw22 lmhw22p lmhharv
tempname lmhharvp lmhwald lmhwaldp lmhhp1 lmhhp1p lmhhp2 lmhhp2p lmhhp3 lmhhp3p lmhgl
tempname lmhglp lmhcw1 cwdf1 lmhcw1p lmhcw2 cwdf2 lmhcw2p lmhq lmhqp
qui tsset `Time'
matrix `SSE'=`Ue_ML''*`Ue_ML'
qui gen `U2' =`Ue_ML'^2/`Sig2n'
qui gen `Yh'=`Yh_ML'
qui gen `Yh2'=`Yh_ML'^2
qui gen `LYh2'=ln(`Yh2')
qui gen `E' =`Ue_ML'
qui gen `E2'=`Ue_ML'^2
qui gen `E3'=`Ue_ML'^3
qui gen `E4'=`Ue_ML'^4
qui gen `LnE2'=log(`E2') 
qui gen `absE'=abs(`E') 
qui gen `DumE'=0 
qui replace `DumE'=1 if `E' >= 0
qui summ `DumE' 
qui gen `EDumE'=`E'*(`DumE'-r(mean)) 
qui regress `EDumE' `Yh' `Yh2' , `noconstant' `vce'
scalar `lmhmss1'=e(N)*e(r2)
scalar `mssdf1'=e(df_m)
scalar `lmhmss1p'=chi2tail(`mssdf1', abs(`lmhmss1'))
qui regress `EDumE' `SPXvar' , `noconstant' `vce'
scalar `lmhmss2'=e(N)*e(r2)
scalar `mssdf2'=e(df_m)
scalar `lmhmss2p'=chi2tail(`mssdf2', abs(`lmhmss2'))
local kx =`kx'
qui forvalue j=1/`kx' {
qui foreach i of local SPXvar {
tempvar VN
gen `VN'`j'=`i' 
qui cap drop `XQX_'`i'
 gen `XQX_'`i' = `VN'`j'*`VN'`j'
 }
 }
qui regress `E2' `SPXvar' , `noconstant'
scalar `dfw0'=e(df_m)
scalar `lmhw01'=e(r2)*e(N)
scalar `lmhw01p'=chi2tail(`dfw0' , abs(`lmhw01'))
scalar `lmhw02'=e(mss)/(2*`Sig2n'^2)
scalar `lmhw02p'=chi2tail(`dfw0' , abs(`lmhw02'))
qui regress `E2' `SPXvar' `XQX_'* , `noconstant'
scalar `dfw1'=e(df_m)
scalar `lmhw11'=e(r2)*e(N)
scalar `lmhw11p'=chi2tail(`dfw1' , abs(`lmhw11'))
scalar `lmhw12'=e(mss)/(2*`Sig2n'^2)
scalar `lmhw12p'=chi2tail(`dfw1' , abs(`lmhw12'))
qui cap drop `VN'*
qui cap drop `XQX_'*
mkmat `SPXvar' , matrix(`VN')
qui svmat `VN' , names(`VN')
unab WWVN: `VN'*
local ZWvar `WWVN'
qui foreach i of local ZWvar {
qui foreach j of local ZWvar {
if `i' >= `j' {
qui cap drop `XQX_'`i'`j'
qui gen `XQX_'`i'`j' = `i'*`j'
 }
 }
 }
qui cap matrix drop `VN'
qui cap drop `VN'*
qui regress `E2' `SPXvar' `XQX_'* , `noconstant'
scalar `dfw2'=e(df_m)
scalar `lmhw21'=e(r2)*e(N)
scalar `lmhw21p'=chi2tail(`dfw2' , abs(`lmhw21'))
scalar `lmhw22'=e(mss)/(2*`Sig2n'^2)
scalar `lmhw22p'=chi2tail(`dfw2' , abs(`lmhw22'))
qui regress `LnE2' `SPXvar' , `noconstant'
scalar `lmhharv'=e(mss)/4.9348
scalar `lmhharvp'= chi2tail(2, abs(`lmhharv'))
qui regress `LnE2' `SPXvar' , `noconstant'
scalar `lmhwald'=e(mss)/2
scalar `lmhwaldp'=chi2tail(1, abs(`lmhwald'))
qui regress `E2' `Yh' , `noconstant'
scalar `lmhhp1'=e(N)*e(r2)
scalar `lmhhp1p'=chi2tail(1, abs(`lmhhp1'))
qui regress `E2' `Yh2' , `noconstant'
scalar `lmhhp2'=e(N)*e(r2)
scalar `lmhhp2p'=chi2tail(1, abs(`lmhhp2'))
qui regress `E2' `LYh2' , `noconstant'
scalar `lmhhp3'=e(N)*e(r2)
scalar `lmhhp3p'= chi2tail(1, abs(`lmhhp3'))
qui regress `absE' `SPXvar' , `noconstant'
scalar `lmhgl'=e(mss)/((1-2/_pi)*`Sig2n')
scalar `lmhglp'=chi2tail(2, abs(`lmhgl'))
qui regress `U2' `Yh' , `noconstant'
scalar `lmhcw1'= e(mss)/2
scalar `cwdf1' = e(df_m)
scalar `lmhcw1p'=chi2tail(`cwdf1', abs(`lmhcw1'))
qui regress `U2' `SPXvar' , `noconstant'
scalar `lmhcw2'=e(mss)/2
scalar `cwdf2' =e(df_m)
scalar `lmhcw2p'=chi2tail(`cwdf2', abs(`lmhcw2'))
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:*** Panel Heteroscedasticity Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt _col(2) "{bf: Ho: Panel Homoscedasticity - Ha: Panel Heteroscedasticity}"
di
tempvar Time
tempname lmharch lmharchp lmhbg lmhbgp
qui gen `Time'=_n
qui tsset `Time'
qui cap drop `LE'*
qui gen `LE'1=L1.`E2' 
qui regress `E2' `LE'* 
scalar `lmharch'=e(r2)*e(N)
scalar `lmharchp'= chi2tail(1, abs(`lmharch'))
qui regress `E2' L1.`E2' `SPXvar' , `noconstant'
scalar `lmhbg'=e(r2)*e(N)
scalar `lmhbgp'=chi2tail(1, abs(`lmhbg'))
di as txt "- Engle LM ARCH Test AR(1): E2 = E2_1" _col(41) "=" as res %9.4f `lmharch' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmharchp'
di _dup(78) "-"
di as txt "- Hall-Pagan LM Test:   E2 = Yh" _col(41) "=" as res %9.4f `lmhhp1' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmhhp1p'
di as txt "- Hall-Pagan LM Test:   E2 = Yh2" _col(41) "=" as res %9.4f `lmhhp2' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmhhp2p'
di as txt "- Hall-Pagan LM Test:   E2 = LYh2" _col(41) "=" as res %9.4f `lmhhp3' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmhhp3p'
di _dup(78) "-"
di as txt "- Harvey LM Test:    LogE2 = X" _col(41) "=" as res %9.4f `lmhharv' _col(54) as txt "P-Value > Chi2(2)" _col(73) as res %5.4f `lmhharvp'
di as txt "- Wald Test:         LogE2 = X " _col(41) "=" as res %9.4f `lmhwald' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmhwaldp'
di as txt "- Glejser LM Test:     |E| = X" _col(41) "=" as res %9.4f `lmhgl' _col(54) as txt "P-Value > Chi2(2)" _col(73) as res %5.4f `lmhglp'
di as txt "- Breusch-Godfrey Test:  E = E_1 X" _col(41) "=" as res %9.4f `lmhbg' _col(54) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f `lmhbgp'
di _dup(78) "-"
di as txt "- Machado-Santos-Silva Test: Ev=Yh Yh2" _col(41) "=" as res %9.4f `lmhmss1' _col(54) as txt "P-Value > Chi2(" `mssdf1' ")" _col(73) as res %5.4f `lmhmss1p'
di as txt "- Machado-Santos-Silva Test: Ev=X" _col(41) "=" as res %9.4f `lmhmss2' _col(54) as txt "P-Value > Chi2(" `mssdf2' ")" _col(73) as res %5.4f `lmhmss2p'
ereturn scalar lmhmss2p= `lmhmss2p'
ereturn scalar lmhmss2= `lmhmss2p'
ereturn scalar lmhmss1p= `lmhmss1p'
ereturn scalar lmhmss1= `lmhmss1'
di _dup(78) "-"
di as txt "- White Test - Koenker(R2): E2 = X" _col(41) "=" as res %9.4f `lmhw01' _col(54) as txt "P-Value > Chi2(" `dfw0' ")" _col(73) as res %5.4f `lmhw01p'
di as txt "- White Test - B-P-G (SSR): E2 = X" _col(41) "=" as res %9.4f `lmhw02' _col(54) as txt "P-Value > Chi2(" `dfw0' ")" _col(73) as res %5.4f `lmhw02p'
di _dup(78) "-"
di as txt "- White Test - Koenker(R2): E2 = X X2" _col(41) "=" as res %9.4f `lmhw11' _col(54) as txt "P-Value > Chi2(" `dfw1' ")" _col(73) as res %5.4f `lmhw11p'
di as txt "- White Test - B-P-G (SSR): E2 = X X2" _col(41) "=" as res %9.4f `lmhw12' _col(54) as txt "P-Value > Chi2(" `dfw1' ")" _col(73) as res %5.4f `lmhw12p'
di _dup(78) "-"
di as txt "- White Test - Koenker(R2): E2 = X X2 XX" _col(41) "=" as res %9.4f `lmhw21' _col(54) as txt "P-Value > Chi2(" `dfw2' ")" _col(73) as res %5.4f `lmhw21p'
di as txt "- White Test - B-P-G (SSR): E2 = X X2 XX" _col(41) "=" as res %9.4f `lmhw22' _col(54) as txt "P-Value > Chi2(" `dfw2' ")" _col(73) as res %5.4f `lmhw22p'
di _dup(78) "-"
di as txt "- Cook-Weisberg LM Test: E2/S2n = Yh" _col(41) "=" as res %9.4f `lmhcw1' _col(54) as txt "P-Value > Chi2(" `cwdf1' ")" _col(73) as res %5.4f `lmhcw1p'
di as txt "- Cook-Weisberg LM Test: E2/S2n = X" _col(41) "=" as res %9.4f `lmhcw2' _col(54) as txt "P-Value > Chi2(" `cwdf2' ")" _col(73) as res %5.4f `lmhcw2p'
di _dup(78) "-"
di as res "*** Single Variable Tests (E2/Sig2):"
local nx : word count `SPXvar'
tokenize `SPXvar'
local i 1
while `i' <= `nx' {
qui regress `U2' ``i''
ereturn scalar lmhcwx_`i'= e(mss)/2
ereturn scalar lmhcwxp_`i'= chi2tail(1 , abs(e(lmhcwx_`i')))
di as txt "- Cook-Weisberg LM Test: " "``i''" _col(44) "=" as res %9.4f e(lmhcwx_`i') _col(53) as txt " P-Value > Chi2(1)" _col(73) as res %5.4f e(lmhcwxp_`i')
local i =`i'+1
 }
di _dup(78) "-"
di as res "*** Single Variable Tests:"
foreach i of local SPXvar {
qui cap drop `ht'`i'
tempvar `ht'`i'
qui egen `ht'`i' = rank(`i')
qui summ `ht'`i'
scalar `mh' = r(mean)
scalar `vh' = r(Var)
qui summ `ht'`i' [aw=`E'^2] , meanonly
scalar `h' = r(mean)
ereturn scalar lmhq_`i'=(`N'^2/(2*(`N'-1)))*(`h'-`mh')^2/`vh'
ereturn scalar lmhqp_`i'= chi2tail(1, abs(e(lmhq_`i')))
di as txt "- King LM Test: " "`i'" _col(44) "=" as res %9.4f e(lmhq_`i') _col(53) as txt " P-Value > Chi2(1)" _col(73) as res %5.4f e(lmhqp_`i')
 }
di _dup(78) "-"
tempvar Sig2 SigLR SigLRs SigLM SigLMs SigW SigWs E E2 EE1 En cN cT Obs Egh
local idv `idv'
qui tsset `Time'
qui regress `yvar' `SPXvar' `wgt' , `noconstant'
qui predict `E' , res
qui gen double `E2' = `E'^2 
qui summ `E2' , meanonly
local Sig2 = r(mean)
qui gen double `SigLR' = . 
qui gen double `SigLM' = . 
qui gen double `SigW'  = . 
local SigLRs = 0
local SigLMs = 0
local SigWs  = 0
qui levelsof `idv' , local(levels)
qui foreach l of local levels {
 summ `E2' if `idv' == `l', meanonly
 replace `SigLM'= (r(mean)/`Sig2'-1)^2 if `idv' == `l'
 replace `SigLR'= ln(r(mean))*r(N) if `idv' == `l'
 replace `SigW' = (`Sig2'/r(mean)-1)^2 if `idv' == `l'
 summ `SigLM' if `idv' == `l', meanonly
local SigLMs =`SigLMs'+ r(mean)
 summ `SigLR' if `idv' == `l', meanonly
local SigLRs = `SigLRs' + r(mean)
 summ `SigW' if `idv' == `l', meanonly
local SigWs =`SigWs'+ r(mean)
 }
local dflm= `NC'-1
local dflr= `NC'-1
local dfw = `NC'
tempname lmhglr lmhglrp lmhglm lmhglmp lmhgw lmhgwp
scalar `lmhglr'=`N'*ln(`Sig2')- `SigLRs'
scalar `lmhglrp'= chi2tail(`dflr', abs(`lmhglr'))
scalar `lmhglm'=`NT'/2*(`SigLMs')
scalar `lmhglmp'= chi2tail(`dflm', abs(`lmhglm'))
scalar `lmhgw'=`NT'/2*(`SigWs')
scalar `lmhgwp'= chi2tail(`dfw', abs(`lmhgw'))
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Panel Groupwise Heteroscedasticity Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt _col(2) "{bf: Ho: Panel Homoscedasticity - Ha: Panel Groupwise Heteroscedasticity}"
di
di as txt "- Lagrange Multiplier LM Test" _col(35) "=" as res %9.4f `lmhglm' as txt _col(50) "P-Value > Chi2(" `dflm' ")" _col(70) %5.4f as res `lmhglmp'
di as txt "- Likelihood Ratio LR Test" _col(35) "=" as res %9.4f `lmhglr' _col(50) as txt "P-Value > Chi2(" `dflr' ")" _col(70) %5.4f as res `lmhglrp'
di as txt "- Wald Test" as res _col(35) "=" as res %9.4f `lmhgw' _col(50) as txt "P-Value > Chi2(" `dfw' ")" _col(70) %5.4f as res `lmhgwp'
di _dup(78) "-"
ereturn scalar lmhglr=`lmhglr'
ereturn scalar lmhglrp=`lmhglrp'
ereturn scalar lmhglm=`lmhglm'
ereturn scalar lmhglmp=`lmhglmp'
ereturn scalar lmhgw=`lmhgw'
ereturn scalar lmhgwp=`lmhgwp'
ereturn scalar lmhw01=`lmhw01'
ereturn scalar lmhw01p=`lmhw01p'
ereturn scalar lmhw02=`lmhw02'
ereturn scalar lmhw02p=`lmhw02p'
ereturn scalar lmhw11=`lmhw11'
ereturn scalar lmhw12=`lmhw12'
ereturn scalar lmhw11p=`lmhw11p'
ereturn scalar lmhw12p=`lmhw12p'
ereturn scalar lmhw21=`lmhw21'
ereturn scalar lmhw22=`lmhw22'
ereturn scalar lmhw21p=`lmhw21p'
ereturn scalar lmhw22p=`lmhw22p'
ereturn scalar lmhharv=`lmhharv'
ereturn scalar lmhharvp=`lmhharvp'
ereturn scalar lmhwald=`lmhwald'
ereturn scalar lmhwaldp=`lmhwaldp'
ereturn scalar lmhhp1=`lmhhp1'
ereturn scalar lmhhp1p=`lmhhp1p'
ereturn scalar lmhhp2=`lmhhp2'
ereturn scalar lmhhp2p=`lmhhp2p'
ereturn scalar lmhhp3=`lmhhp3'
ereturn scalar lmhhp3p=`lmhhp3p'
ereturn scalar lmhgl=`lmhgl'
ereturn scalar lmhglp=`lmhglp'
ereturn scalar lmhcw1=`lmhcw1'
ereturn scalar lmhcw1p=`lmhcw1p'
ereturn scalar lmhcw2=`lmhcw2'
ereturn scalar lmhcw2p=`lmhcw2p'
ereturn scalar lmharch=`lmharch'
ereturn scalar lmharchp=`lmharchp'
ereturn scalar lmhbg=`lmhbg'
ereturn scalar lmhbgp=`lmhbgp'
 }

if "`lmnorm'"!= "" {
tempvar Yh E E1 E2 E3 E4 Es U2 DE LDE LDF1 Yt U Hat 
tempname Hat corr1 corr3 corr4 mpc2 mpc3 mpc4 s uinv q1 uinv2 q2 ECov ECov2 Eb Sk Ku
tempname M2 M3 M4 K2 K3 K4 Ss Kk GK sksd kusd N1 N2 EN S2N SN mean sd small A2 B0 B1
tempname B2 B3 LA Z Rn Lower Upper wsq2 ve lve Skn gn an cn kn vz Ku1 Kun n1 n2 n3 eb2
tempname R2W vb2 svb2 k1 a devsq m2 sdev m3 m4 sqrtb1 b2 g1 g2 stm3b2 S1 S2 S3 S4
tempname b2minus3 sm sms y k2 wk delta alpha yalpha pc1 pc2 pc3 pc4 pcb1 pcb2 sqb1p b2p
qui tsset `Time'
qui gen `Yh'=`Yh_ML'
qui gen `E' =`Ue_ML'
qui gen `E2'=`E'*`E' 
matrix `Hat'=vecdiag(`X'*invsym(`X''*`X')*`X'')'
qui svmat `Hat' , name(`Hat')
rename `Hat'1 `Hat'
qui regress `E2' `Hat'
scalar `R2W'=e(r2)
qui summ `E' , det
scalar `Eb'=r(mean)
scalar `Sk'=r(skewness)
scalar `Ku'=r(kurtosis)
qui forvalue i = 1/4 {
qui gen `E'`i'=(`E'-`Eb')^`i' 
qui summ `E'`i'
scalar `S`i''=r(mean)
scalar `pc`i''=r(sum)
 }
mkmat `E'1 `E'2 `E'3 `E'4 in 1/`N' , matrix(`ECov')
scalar `M2'=`S2'-`S1'^2
scalar `M3'=`S3'-3*`S1'*`S2'+`S1'^2
scalar `M4'=`S4'-4*`S1'*`S3'+6*`S1'^2*`S2'-3*`S1'^4
scalar `K2'=`N'*`M2'/(`N'-1)
scalar `K3'=`N'^2*`M3'/((`N'-1)*(`N'-2))
scalar `K4'=`N'^2*((`N'+1)*`M4'-3*(`N'-1)*`M2'^2)/((`N'-1)*(`N'-2)*(`N'-3))
scalar `Ss'=`K3'/(`K2'^1.5)
scalar `Kk'=`K4'/(`K2'^2)
scalar `GK'= ((`Sk'^2/6)+((`Ku'-3)^2/24))
ereturn scalar lmnw=`N'*(`R2W'+`GK')
ereturn scalar lmnwp= chi2tail(2, abs(e(lmnw)))
ereturn scalar lmnjb=`N'*((`Sk'^2/6)+((`Ku'-3)^2/24))
ereturn scalar lmnjbp= chi2tail(2, abs(e(lmnjb)))
scalar `sksd'=sqrt(6*`N'*(`N'-1)/((`N'-2)*(`N'+1)*(`N'+3)))
scalar `kusd'=sqrt(24*`N'*(`N'-1)^2/((`N'-3)*(`N'-2)*(`N'+3)*(`N'+5)))
qui gen `DE'=1 if `E'>0
qui replace `DE'=0 if `E' <= 0
qui count if `DE'>0
scalar `N1'=r(N)
scalar `N2'=`N'-r(N)
scalar `EN'=(2*`N1'*`N2')/(`N1'+`N2')+1
scalar `S2N'=(2*`N1'*`N2'*(2*`N1'*`N2'-`N1'-`N2'))/((`N1'+`N2')^2*(`N1'+`N2'-1))
scalar `SN'=sqrt((2*`N1'*`N2'*(2*`N1'*`N2'-`N1'-`N2'))/((`N1'+`N2')^2*(`N1'+`N2'-1)))
qui gen `LDE'= `DE'[_n-1] 
qui replace `LDE'=0 if `DE'==1 in 1
qui gen `LDF1'= 1 if `DE' != `LDE'
qui replace `LDF1'= 1 if `DE' == `LDE' in 1
qui replace `LDF1'= 0 if `LDF1' == .
qui count if `LDF1'>0
scalar `Rn'=r(N)
ereturn scalar lmng=(`Rn'-`EN')/`SN'
ereturn scalar lmngp= chi2tail(2, abs(e(lmng)))
scalar `Lower'=`EN'-1.96*`SN'
scalar `Upper'=`EN'+1.96*`SN'
qui summ `E' 
scalar `mean'=r(mean)
scalar `sd'=r(sd)
scalar `small'= 1e-20
qui gen `Es' =`E'
qui sort `Es'
qui replace `Es'=normal((`Es'-`mean')/`sd') 
qui gen `Yt'=`Es'*(1-`Es'[`N'-_n+1]) 
qui replace `Yt'=`small' if `Yt' < =0
qui replace `Yt'=sum((2*_n-1)*ln(`Yt')) 
scalar `A2'=-`N'-`Yt'[`N']/`N'
scalar `A2'=`A2'*(1+(0.75+2.25/`N')/`N')
scalar `B0'=2.25247+0.000317*exp(29.5/`N')
scalar `B1'=2.16872+0.00243*exp(27.7/`N')
scalar `B2'=0.19135+0.00255*exp(28.3/`N')
scalar `B3'=0.110978+0.00001624*exp(39.04/`N')+0.00476*exp(21.37/`N')
scalar `LA'=ln(`A2')
ereturn scalar lmnad=(`A2')
scalar `Z'=abs(`B0'+`LA'*(`B1'+`LA'*(`B2'+`LA'*`B3')))
ereturn scalar lmnadp= normal(abs(-`Z'))
scalar `wsq2'=-1+sqrt(2*((3*(`N'^2+27*`N'-70)/((`N'-2)*(`N'+5))*((`N'+1)/(`N'+7))*((`N'+3)/(`N'+9)))-1))
scalar `ve'=`Sk'*sqrt((`N'+1)*(`N'+3)/(6*(`N'-2)))/sqrt(2/(`wsq2'-1))
scalar `lve'=ln(`ve'+(`ve'^2+1)^0.5)
scalar `Skn'=`lve'/sqrt(ln(sqrt(`wsq2')))
scalar `gn'=((`N'+5)/(`N'-3))*((`N'+7)/(`N'+1))/(6*(`N'^2+15*`N'-4))
scalar `an'=(`N'-2)*(`N'^2+27*`N'-70)*`gn'
scalar `cn'=(`N'-7)*(`N'^2+2*`N'-5)*`gn'
scalar `kn'=(`N'*`N'^2+37*`N'^2+11*`N'-313)*`gn'/2
scalar `vz'= `cn'*`Sk'^2 +`an'
scalar `Ku1'=(`Ku'-1-`Sk'^2)*`kn'*2
scalar `Kun'=(((`Ku1'/(2*`vz'))^(1/3))-1+1/(9*`vz'))*sqrt(9*`vz')
ereturn scalar lmndh =`Skn'^2 + `Kun'^2
ereturn scalar lmndhp= chi2tail(2, abs(e(lmndh)))
scalar `n1'=sqrt(`N'*(`N'-1))/(`N'-2)
scalar `n2'=3*(`N'-1)/(`N'+1)
scalar `n3'=(`N'^2-1)/((`N'-2)*(`N'-3))
scalar `eb2'=3*(`N'-1)/(`N'+1)
scalar `vb2'=24*`N'*(`N'-2)*(`N'-3)/(((`N'+1)^2)*(`N'+3)*(`N'+5))
scalar `svb2'=sqrt(`vb2')
scalar `k1'=6*(`N'*`N'-5*`N'+2)/((`N'+7)*(`N'+9))*sqrt(6*(`N'+3)*(`N'+5)/(`N'*(`N'-2)*(`N'-3)))
scalar `a'=6+(8/`k1')*(2/`k1'+sqrt(1+4/(`k1'^2)))
scalar `devsq'=`pc1'*`pc1'/`N'
scalar `m2'=(`pc2'-`devsq')/`N'
scalar `sdev'=sqrt(`m2')
scalar `m3'=`pc3'/`N'
scalar `m4'=`pc4'/`N'
scalar `sqrtb1'=`m3'/(`m2'*`sdev')
scalar `b2'=`m4'/`m2'^2
scalar `g1'=`n1'*`sqrtb1'
scalar `g2'=(`b2'-`n2')*`n3'
scalar `stm3b2'=(`b2'-`eb2')/`svb2'
ereturn scalar lmnkz=(1-2/(9*`a')-((1-2/`a')/(1+`stm3b2'*sqrt(2/(`a'-4))))^(1/3))/sqrt(2/(9*`a'))
ereturn scalar lmnkzp=2*(1-normal(abs(e(lmnkz))))
scalar `b2minus3'=`b2'-3
matrix `ECov2'=`ECov''*`ECov'
scalar `sm'=`ECov2'[1,1]
scalar `sms'=1/sqrt(`sm')
matrix `corr1'=`sms'*`ECov2'*`sms'
matrix `corr3'=`corr1'[1,1]^3
matrix `corr4'=`corr1'[1,1]^4
scalar `y'=`sqrtb1'*sqrt((`N'+1)*(`N'+3)/(6*(`N'-2)))
scalar `k2'=3*(`N'^2+27*`N'-70)*(`N'+1)*(`N'+3)/((`N'-2)*(`N'+5)*(`N'+7)*(`N'+9))
scalar `wk'=sqrt(sqrt(2*(`k2'-1))-1)
scalar `delta'=1/sqrt(ln(`wk'))
scalar `alpha'=sqrt(2/(`wk'*`wk'-1))
matrix `yalpha'=`y'/`alpha'
scalar `yalpha'=`yalpha'[1,1]
ereturn scalar lmnsz=`delta'*ln(`yalpha'+sqrt(1+`yalpha'^2))
ereturn scalar lmnszp= 2*(1-normal(abs(e(lmnsz))))
ereturn scalar lmndp=e(lmnsz)^2+e(lmnkz)^2
ereturn scalar lmndpp= chi2tail(2, abs(e(lmndp)))
matrix `uinv'=invsym(`corr3')
matrix `q1'=e(lmnsz)'*`uinv'*e(lmnsz)
ereturn scalar lmnsms=`q1'[1,1]
ereturn scalar lmnsmsp= chi2tail(1, abs(e(lmnsms)))
matrix `uinv2'=invsym(`corr4')
matrix `q2'=e(lmnkz)'*`uinv2'*e(lmnkz)
ereturn scalar lmnsmk=`q2'[1,1]
ereturn scalar lmnsmkp= chi2tail(1, abs(e(lmnsmk)))
matrix `mpc2'=(`pc2'-(`pc1'^2/`N'))/`N'
matrix `mpc3'=(`pc3'-(3/`N'*`pc1'*`pc2')+(2/(`N'^2)*(`pc1'^3)))/`N'
matrix `mpc4'=(`pc4'-(4/`N'*`pc1'*`pc3')+(6/(`N'^2)*(`pc2'*(`pc1'^2)))-(3/(`N'^3)*(`pc1'^4)))/`N'
scalar `pcb1'=`mpc3'[1,1]/`mpc2'[1,1]^1.5
scalar `pcb2'=`mpc4'[1,1]/`mpc2'[1,1]^2
scalar `sqb1p'=`pcb1'^2
scalar `b2p'=`pcb2'
ereturn scalar lmnsvs=`sqb1p'*`N'/6
ereturn scalar lmnsvsp= chi2tail(1, abs(e(lmnsvs)))
ereturn scalar lmnsvk=(`b2p'-3)*sqrt(`N'/24)
ereturn scalar lmnsvkp= 2*(1-normal(abs(e(lmnsvk))))
qui sort `Time'
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Panel Non Normality Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt "{bf: Ho: Normality - Ha: Non Normality}"
di _dup(78) "-"
di "{bf:*** Non Normality Tests:}
di as txt "- Jarque-Bera LM Test" _col(40) "=" as res %9.4f e(lmnjb) _col(55) as txt "P-Value > Chi2(2) " _col(73) as res %5.4f e(lmnjbp)
di as txt "- White IM Test" _col(40) "=" as res %9.4f e(lmnw) _col(55) as txt "P-Value > Chi2(2) " _col(73) as res %5.4f e(lmnwp)
di as txt "- Doornik-Hansen LM Test" _col(40) "=" as res %9.4f e(lmndh) _col(55) as txt "P-Value > Chi2(2) " _col(73) as res %5.4f e(lmndhp)
di as txt "- Geary LM Test" _col(40) "=" as res %9.4f e(lmng) _col(55) as txt "P-Value > Chi2(2) " _col(73) as res %5.4f e(lmngp)
di as txt "- Anderson-Darling Z Test" _col(40) "=" as res %9.4f e(lmnad) _col(55) as txt "P > Z(" %6.3f `Z' ")" _col(73) as res %5.4f e(lmnadp)
di as txt "- D'Agostino-Pearson LM Test " _col(40) "=" as res %9.4f e(lmndp) _col(55) as txt "P-Value > Chi2(2)" _col(73) as res %5.4f e(lmndpp)
di _dup(78) "-"
di "{bf:*** Skewness Tests:}
di as txt "- Srivastava LM Skewness Test" _col(40) "=" as res %9.4f e(lmnsvs) _col(55) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f e(lmnsvsp)
di as txt "- Small LM Skewness Test" _col(40) "=" as res %9.4f e(lmnsms) _col(55) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f e(lmnsmsp)
di as txt "- Skewness Z Test" _col(40) "=" as res %9.4f e(lmnsz) _col(55) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f e(lmnszp)
di _dup(78) "-"
di "{bf:*** Kurtosis Tests:}
di as txt "- Srivastava  Z Kurtosis Test" _col(40) "=" as res %9.4f e(lmnsvk) _col(55) as txt "P-Value > Z(0,1)" _col(73) as res %5.4f e(lmnsvkp)
di as txt "- Small LM Kurtosis Test" _col(40) "=" as res %9.4f e(lmnsmk) _col(55) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f e(lmnsmkp)
di as txt "- Kurtosis Z Test" _col(40) "=" as res %9.4f e(lmnkz) _col(55) as txt "P-Value > Chi2(1)" _col(73) as res %5.4f e(lmnkzp)
di _dup(78) "-"
di as txt _col(5) "Skewness Coefficient =" _col(28) as res %7.4f `Sk' as txt "   " "  - Standard Deviation = " _col(48) as res %7.4f `sksd'
di as txt _col(5) "Kurtosis Coefficient =" _col(28) as res %7.4f `Ku' as txt "   " "  - Standard Deviation = " _col(48) as res %7.4f `kusd'
di _dup(78) "-"
di as txt _col(5) "Runs Test:" as res " " "(" `Rn' ")" " " as txt "Runs - " as res " " "(" `N1' ")" " " as txt "Positives -" " " as res "(" `N2' ")" " " as txt "Negatives"
di as txt _col(5) "Standard Deviation Runs Sig(k) = " as res %7.4f `SN' " , " as txt "Mean Runs E(k) = " as res %7.4f `EN' 
di as txt _col(5) "95% Conf. Interval [E(k)+/- 1.96* Sig(k)] = (" as res %7.4f `Lower' " , " %7.4f `Upper' " )"
 }

local lmhlmn `lmhet' `lmnorm'
 if "`ll'" != "" {
qui replace `yvar' = 0 if `yvar' <= `ll'
qui local llt `"`ll'"'
scalar llt=`llt'
qui count if `yvar' == 0
local minyvar=r(N)
 }
 else {
scalar llt=0
qui replace `yvar' = 0 if `yvar' <= 0
qui local llt 0
scalar llt=`llt'
qui count if `yvar' == 0
local minyvar=r(N)
 }
 
if "`lmhlmn'"!="" {
qui tsset `Time'
qui summ `yvar' 
local minyvar=r(min)
local lmnohet :word count `lmnorm' `lmhet'
if `minyvar'==0 & !inlist(`lmnohet'0,2) { 
tempname K B XBM XB E E2 Sig XBs Es Eg Gz Eg3 Eg4
tempname ImR D0 D1 DB DS U3 U4 M1 M2 DB0 XBX SigV SigV2 Yh SigM H kxt
tempvar EXwXw AM SSE YYR R2Raw
qui tsset `Time'
scalar `kxt' = `kx'
qui xtset `idv' `itv'
qui xttobit `yvar' `SPXvar' , nolog ll(`llt') `noconstant' `coll'
qui predict `XBX' , xb
local k = `kxt'
qui gen `SigV'=_b[/sigma_e]
qui gen `E'=`yvar'-`XBX' 
qui gen `SigV2'= `SigV'^2 
qui gen `XBs'= `XBX'/`SigV' 
qui gen `Es'= `E'/`SigV' 
qui gen `ImR'=normalden(`XBs')/(1-normal(`XBs')) 
qui replace `ImR'=0 if `ImR' == .
qui gen `D0'=0 
qui gen `D1'=0 
qui replace `D0'=1 if `yvar' == `llt'
qui replace `D1'=1 if `yvar' > `llt'
qui gen `DB' =(`D1'*`Es'-`D0'*`ImR')/`SigV' 
qui gen `DS' =(`D1'*(`Es'^2-1)+`D0'*`ImR'*`XBs')/`SigV' 
qui gen `Eg'=(`D1'*(`yvar'-`XBX')-`D0'*`SigV'*`ImR')/(`SigV2') 
qui foreach var of local SPXvar {
qui gen `EXwXw'`var'=`Eg'*`var' 
 }
qui gen `Gz'=(`D1'*(((`yvar'-`XBX')^2/`SigV2')-1)+`D0'*`XBs'*`ImR')/(2*`SigV2') 
qui gen `Eg3'=`Eg'^3 
qui gen `Eg4'=(`Eg'^4)-3*`Eg'*`Eg' 
qui regress `X0' `EXwXw'* `Eg' `Gz' `Eg3' `Eg4' , noconst
tempname SSE YYR lmnci NR2 
tempvar dfdb dfds B sig yc D0 D1 XB XBs Es u1 u2 u3 u4
scalar `SSE'=e(rss)
scalar `YYR'=_N
scalar `R2Raw'=1-(`SSE'/`YYR')
scalar `lmnci'=`N'*`R2Raw'
qui gen `D0'=0 
qui gen `D1'=1-`D0' 
qui gen `yc'=`yvar'
qui replace `yc'=0 if `yc'<=0
qui tobit `yc' `SPXvar' , nolog ll(0) `noconstant' `coll'
qui predict `dfdb' `dfds' , score
qui gen `sig'=_b[/sigma]
qui predict `XB' , xb
qui gen `XBs'=`XB'/`sig' 
qui gen `Es'=(`yvar'-`XB')/`sig' 
qui replace `ImR'=normalden(`XBs')/(1-normal(`XBs')) 
qui replace `ImR'=0 if `ImR' == .
qui gen `u1'= -`D0'*`ImR' +`D1'*`Es' 
qui gen `u2'= `D0'*`XBs'*`ImR' +`D1'*(`Es'^2 - 1) 
qui gen `u3'= -`D0'*(2+`XBs'^2)*`ImR' +`D1'*`Es'^3 
qui gen `u4'= `D0'*(3*`XBs'+`XBs'^3) *`ImR' +`D1'*(`Es'^4 - 3) 
 tempvar d0 
qui summ `dfdb' 
qui gen `d0'=`dfdb' 
local vlist "`d0'"
local mlist ""
local vlist ""
local mlist ""
local j=1
qui while `j'<=`kx' {
 tempvar d`j' mom`j'
local j=`j'+1
 }
local j=0
 tokenize `SPXvar'
qui while "`1'"~="" {
local j=`j'+1
qui gen `d`j''=`dfdb'*`1' 
qui gen `mom`j''=`u2'*`1' 
local vlist "`vlist' `d`j''"	
local mlist "`mlist' `mom`j''"	
 macro shift
local vlist "`vlist' `dfdb' `dfds'"
 }
local j=1
qui while "`1'"~="" {
local vlist "`vlist' dfdb`j'"
local j=`j'+1
 }
 tempvar const
 gen `const'=1 
local q=0
 while `q'<=4 {
 if `q'==0 {
local j=1
 tokenize `SPXvar'
di 
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:*** Tobit Heteroscedasticity LM Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt " {bf:Separate LM Tests - Ho: Homoscedasticity}"
 while `j'<=`kx' {
qui regress `const' `mom`j'' `vlist' , noconstant
scalar `NR2'=e(r2)*e(N)
local df=1
di as txt "- LM Test: " "``j''" _col(33) "=" as res %10.4f `NR2' _col(47) as txt "P-Value > Chi2(1)" _col(67) as res %5.4f chi2tail(`df', abs(`NR2'))
local j=`j'+1
 }
 }
 if `q'==1 {
di
di as txt " {bf:Joint LM Test     - Ho: Homoscedasticity}"
qui regress `const' `mlist' `vlist' , noconstant
 }
 if `q'==2 {
di 
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:*** Tobit Non Normality LM Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt " {bf:LM Test - Ho: No Skewness}"
qui regress `const' `u3' `vlist' , noconstant
 }
 if `q'==3 {
di
di as txt " {bf:LM test - Ho: No Kurtosis}"
qui regress `const' `u4' `vlist' , noconstant
 }
 if `q'==4 {
di
di as txt " {bf:LM Test - Ho: Normality (No Kurtosis, No Skewness)}"
qui regress `const' `u3' `u4' `vlist' , noconstant
 }
scalar `NR2'=e(r2)*e(N)
 if `q'==1 {
local df=`kx'
 }
 if `q'==2 {
local df=1
 }
 if `q'==3 {
local df=1
 }
 if `q'==4 {
local df=2
 }
 if `q'>0 & `q'<4 {
di as txt _col(2) "- LM Test"  _col(33) "=" %10.4f as res `NR2' as txt _col(47) "P-Value > Chi2(" `df' ")" _col(67) as res %5.4f chi2tail(`df', abs(`NR2'))
 }
 if `q' == 4 {
di as txt _col(2) "- Pagan-Vella LM Test" _col(33) "=" %10.4f as res `NR2' as txt _col(47) "P-Value > Chi2(2)" _col(67) as res %5.4f chi2tail(2, abs(`NR2'))
ereturn scalar lmnpv=`NR2'
ereturn scalar lmnpvp=chi2tail(`df', abs(`NR2'))
 }
 if `q'==1 {
scalar phom= chi2tail(`df', abs(`NR2'))
 }
 if `q'==4 {
scalar pnor= chi2tail(`df', abs(`NR2'))
 }
local q=`q'+1
 }
ereturn scalar lmnci=`lmnci'
ereturn scalar lmncip=chi2tail(2, abs(`lmnci'))
di as txt _col(2) "- Chesher-Irish LM Test" _col(33) "=" %10.4f as res e(lmnci) as txt _col(47) "P-Value > Chi2(2)" _col(67) as res %5.4f e(lmncip)
 }
 }
if "`lmnorm'"!="" | "`lmhet'"!="" {
di _dup(78) "-"
 }

if "`predict'"!= "" {
qui cap drop `predict'
mata: `predict'=Yhxt
getmata `predict' , force replace
label variable `predict' `"Yh - Prediction"'
 }
if "`resid'"!= "" {
qui cap drop `resid'
mata: `resid'=Uext
getmata `resid' , force replace
label variable `resid' `"Ue - Residual"'
 }

if "`tolog'"!="" {
qui foreach var of local varlist {
qui replace `var'= `xyind`var'' 
 }
 }
 
if inlist("`mfx'", "lin", "log") {
tempname XMB YMB XYMB SumW TRWS1 NSumW NTRWS InDirect Direct Total
tempname B TRW spmfx spmfxe YMB1 TRWS InDirectES DirectES TotalES Betaes
tokenize "`SPXvar'"
qui mean `SPXvar'
matrix `XMB'=e(b)'
qui summ `yvar'  
scalar `YMB1'=r(mean)
matrix `YMB'=J(rowsof(`XMB'),1,`YMB1')
mata: X = st_matrix("`XMB'")
mata: Y = st_matrix("`YMB'")
if inlist("`mfx'", "lin") {
mata: `XYMB'=divide(X, Y)
mata: `XYMB'=st_matrix("`XYMB'",`XYMB')
 }
if inlist("`mfx'", "log") {
mata: `XYMB'=divide(Y, X)
mata: `XYMB'=st_matrix("`XYMB'",`XYMB')
 }
if inlist("`mfx'", "lin") {
matrix `spmfx' =`Bx'
matrix `spmfxe'=vecdiag(`Bx'*`XYMB'')'
tempname mfxlin
matrix `mfxlin' =`spmfx',`spmfxe',`XMB'
mat rownames `mfxlin' = `*'
mat colnames `mfxlin' = Marginal_Effect(B) Elasticity(Es) Mean
matlist `mfxlin' , title({bf:{err:* Linear:}} Marginal Effect - Elasticity - {bf:Spatial Panel *}) twidth(10) border(all) lines(columns) rowtitle(Variable) format(%18.4f)
ereturn matrix mfx=`mfxlin'
 }
if inlist("`mfx'", "log") {
matrix `spmfxe'=`Bx'
matrix `spmfx'=vecdiag(`Bx'*`XYMB'')'
tempname mfxlog
matrix `mfxlog' =`spmfxe',`spmfx',`XMB'
matrix rownames `mfxlog' = `*'
matrix colnames `mfxlog' = Elasticity(Es) Marginal_Effect(B) Mean
matlist `mfxlog' , title({bf:{err:* Log-Log:}} Elasticity - Marginal Effect - {bf:Spatial Panel *}) twidth(10) border(all) lines(columns) rowtitle(Variable) format(%18.4f)
ereturn matrix mfx=`mfxlog'
 }
di as txt " Mean of Dependent Variable =" as res _col(30) %12.4f `YMB1'
 }

qui cap matrix drop _all
qui cap drop spat_*
qui cap matrix drop Ue_ML Yh_ML Bx Y X eigw WCS eVec
qui sort `Time'
qui cap mata: mata drop *
qui cap matrix drop Yh_ML
qui cap matrix drop Ue_ML
qui cap matrix drop _WB WCS
end

program define spgmmxts , eclass 
 version 11.0
syntax varlist [aw fw iw pw] , [gmm(int 1) NOCONStant vce(passthru) DN ///
 ROBust tobit coll iter(int 100) tech(str) tolog]
tempvar `varlist'
gettoken yvar xvar : varlist
 if "`coll'"=="" {
qui _rmcoll `xvar' , `noconstant' `coll' forcedrop
local xvar "`r(varlist)'"
 }
gettoken yvar xvar : varlist
qui {
tempvar Time tm idv itv _Cons
tempname Y varx var kb N NC NT
qui gen `Time'=_n
svmat idv , name(`idv')
svmat itv , name(`itv')
rename `idv'1 `idv'
rename `itv'1 `itv'
preserve
tempname matg h1 h1t h2 h2t h3 h3t HM1 HM1t HM2 HM2t HM3 HM3t HM4 HM4t HMY
tempname HMYt hy Z0 hyt mats matj wmat wmat1 mtr MQ0 MQ1 MW1 MWT1 MWT2 MWT21
tempname MW2 MW3 MW4 OMGINV Q0 Q1 P matt Q1UVEC UQVEC VCOV Q1VVEC B
tempname VQVEC VVEC Q1WVEC WQVEC WVEC UVEC XB X Y E Cov Beta Sig2 RhoGM
tempvar ss2 u u2 X0
local kb=e(kb)
local NC=e(NC)
local NT=e(NT)
local N=e(Nn)
local DF=e(DF)
local llt=0
 if "`ll'" != "" {
qui replace `yvar' = 0 if `yvar' <= `ll'
qui local lltob `"`ll'"'
local llt=`lltob'
 }
qui matrix `wmat'=WCS
qui matrix `mtr'=trace(`wmat''*`wmat')/_N
qui matrix `mats'=I(`NC')
qui matrix `matt'=I(`NT')
qui matrix `matj'=J(`NT',`NT',1/`NT')
qui matrix `wmat1'=`matt'#`wmat'
qui matrix `Q0'=(`matt'-`matj')#`mats'
qui matrix `Q1'=`matj'#`mats'
qui matrix `MW1'=`wmat''*`wmat'
qui matrix `MWT1'=trace(`MW1')/`NC'
qui matrix `MWT21'=`MW1'*(`wmat'+`wmat'')
qui matrix `MWT2'=trace(`MWT21')/`NC'
qui matrix `MW2'=`wmat'*`wmat'
qui matrix `MW3'=`MW1'*`MW1'
qui matrix `MW4'=`MW1'+`MW2'
qui matrix `MQ0'=trace(`MW3')/`NC'
qui matrix `MQ1'=trace(`MW4')/`NC'
qui cap matrix drop `MWT21' `MW1' `MW2' `MW3' `MW4'
 if "`tobit'"!="" {
qui xtset `idv' `itv'
qui xttobit `yvar' `xvar' `wgt' , `noconstant' `vce' ///
 ll(spat_llt) iter(`iter') tech(`tech') `coll' 
tempvar yhat res res2
qui predict `yhat' , xb
qui gen `res'=`yvar'-`yhat'  
 }
else { 
qui tsset `Time'
qui regress `yvar' `xvar' `wgt' , `noconstant' `vce' `robust'
tempvar res res2
qui predict `res' , resid
 }
qui tsset `Time'
qui gen `res2'=`res'^2
tempname L T1 T2
scalar `L'=`gmm'
mkmat `res' , matrix(`UVEC')
qui matrix `VVEC'=`wmat1'*`UVEC'
qui matrix `WVEC'=`wmat1'*`VVEC'
qui matrix `UQVEC'=`Q0'*`UVEC'
qui matrix `VQVEC'=`Q0'*`VVEC'
qui matrix `WQVEC'=`Q0'*`WVEC'
qui matrix `Q1UVEC'=`Q1'*`UVEC'
qui matrix `Q1VVEC'=`Q1'*`VVEC'
qui matrix `Q1WVEC'=`Q1'*`WVEC'
tempvar US VS WS UQS VQS WQS UTS VTS WTS
qui svmat `UVEC', name(`US')
qui svmat `VVEC', name(`VS')
qui svmat `WVEC', name(`WS')
qui svmat `UQVEC', name(`UQS')
qui svmat `VQVEC', name(`VQS')
qui svmat `WQVEC', name(`WQS')
qui svmat `Q1UVEC' , name(`UTS')
qui svmat `Q1VVEC' , name(`VTS')
qui svmat `Q1WVEC' , name(`WTS')
qui cap matrix drop `wmat1' `VVEC' `UVEC' `WVEC'
qui cap matrix drop `UQVEC' `VQVEC' `WQVEC' `Q1UVEC' `Q1VVEC' `Q1WVEC'
rename `US'1 `US'
rename `VS'1 `VS'
rename `WS'1 `WS'
rename `UQS'1 `UQS'
rename `VQS'1 `VQS'
rename `WQS'1 `WQS'
rename `UTS'1 `UTS'
rename `VTS'1 `VTS'
rename `WTS'1 `WTS'
tempvar UQ2 VQ2 WQ2 UQVQ UQWQ VQWQ UQ12 VQ12 WQ12 UQ1VQ1 UQ1WQ1 VQ1WQ1
gen `UQ2'=`UQS'*`UQS'
gen `VQ2'=`VQS'*`VQS'
gen `WQ2'=`WQS'*`WQS'
gen `UQVQ'=`UQS'*`VQS'
gen `UQWQ'=`UQS'*`WQS'
gen `VQWQ'=`VQS'*`WQS'
gen `UQ12'=`UTS'*`UTS'
gen `VQ12'=`VTS'*`VTS'
gen `WQ12'=`WTS'*`WTS'
gen `UQ1VQ1'=`UTS'*`VTS'
gen `UQ1WQ1'=`UTS'*`WTS'
gen `VQ1WQ1'=`VTS'*`WTS'
matrix `mtr'=trace(`wmat''*`wmat')/`NC'
scalar `T1'=`NT'/(`NT'-1)
scalar `T2'=`NT'
tempvar UQ2M VQ2M WQ2M UQVQM UQWQM VQWQM UQ12M VQ12M WQ12M UQ1VQ1M UQ1WQ1M VQ1WQ1M
egen `UQ2M' = mean(`UQ2')
egen `VQ2M' = mean(`VQ2')
egen `WQ2M' = mean(`WQ2')
egen `UQVQM' = mean(`UQVQ')
egen `UQWQM' = mean(`UQWQ')
egen `VQWQM' = mean(`VQWQ')
egen `UQ12M' = mean(`UQ12')
egen `VQ12M' = mean(`VQ12')
egen `WQ12M' = mean(`WQ12')
egen `UQ1VQ1M' = mean(`UQ1VQ1')
egen `UQ1WQ1M' = mean(`UQ1WQ1')
egen `VQ1WQ1M' = mean(`VQ1WQ1')
tempname SUQ2M SVQ2M SWQ2M SUQVQM SUQWQM SVQWQM SUQ12M
tempname SVQ12M SWQ12M SUQ1VQ1M SUQ1WQ1M SVQ1WQ1M RhoH SIGV SIG1 VAR1 VAR2
scalar `SUQ2M'=`UQ2M'*`T1'
scalar `SVQ2M'=`VQ2M'*`T1'
scalar `SWQ2M'=`WQ2M'*`T1'
scalar `SUQVQM'=`UQVQM'*`T1'
scalar `SUQWQM'=`UQWQM'*`T1'
scalar `SVQWQM'=`VQWQM'*`T1'
scalar `SUQ12M'=`UQ12M'*`T2'
scalar `SVQ12M'=`VQ12M'*`T2'
scalar `SWQ12M'=`WQ12M'*`T2'
scalar `SUQ1VQ1M'=`UQ1VQ1M'*`T2'
scalar `SUQ1WQ1M'=`UQ1WQ1M'*`T2'
scalar `SVQ1WQ1M'=`VQ1WQ1M'*`T2' 
tempvar h11 h12 h13 h21 h22 h23 h31 h32 h33 hy1 hy2 hy3
gen `h11'=2*`SUQVQM'
gen `h12'=-`SVQ2M'
gen `h13'=1
gen `h21'=2*`SVQWQM'
gen `h22'=-`SWQ2M'
gen `h23'=trace(`mtr')
gen `h31'=(`SVQ2M'+`SUQWQM')
gen `h32'=-`SVQWQM'
gen `h33'=0
gen `hy1'=`SUQ2M'
gen `hy2'=`SVQ2M'
gen `hy3'=`SUQVQM'
collapse `h11' `h12' `h13' `hy1' `h21' `h22' `h23' `hy2' `h31' `h32' `h33' `hy3'
mkmat `h11' `h21' `h31', matrix(`h1t')
mkmat `h12' `h22' `h32', matrix(`h2t')
mkmat `h13' `h23' `h33', matrix(`h3t')
mkmat `hy1' `hy2' `hy3', matrix(`hyt')
qui matrix `h1'=`h1t''
qui matrix `h2'=`h2t''
qui matrix `h3'=`h3t''
qui matrix `hy'=`hyt''
qui set obs 3
tempvar V1 V2 V3 Z
svmat `h1' , name(`V1')
svmat `h2' , name(`V2')
svmat `h3' , name(`V3')
svmat `hy' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `Z'1 `Z'
qui nl (`Z'=`V1'*{Rho} +`V2'*{Rho}^2 +`V3'*{Sigma2}) , init(Rho 0 Sigma2 1) nolog
tempname RhoH SIGV SIG1 VAR1 VAR2 SIGVV SIG11
scalar `RhoH'=_b[/Rho]
scalar `SIGV'=_b[/Sigma2]
scalar `SIG1'=`SUQ12M'-(2*`SUQ1VQ1M'*`RhoH')-(-1*`SVQ12M'*(`RhoH'^2))
scalar `VAR1'= ((`SIGV'^2)/(`NT'-1))^0.5
scalar `VAR2'= (`SIG1'^2)^0.5
tempname VAR11 VAR22 VAR33 VAR44 VAR55 VAR66 VAR12 VAR23 VAR45 VAR56
if `L' == 1 {
scalar `RhoGM'=`RhoH'
scalar `SIGVV'=`SIGV'
scalar `SIG11'=`SIG1'
 }
if `L' == 2 {
scalar `VAR11'=`NC'*((1*(`SIGV'^2)/(`NC'*(`NT'-1))))
scalar `VAR22'=`NC'*((1*(`SIGV'^2)/(`NC'*(`NT'-1))))
scalar `VAR33'=`NC'*((1*(`SIGV'^2)/(`NC'*(`NT'-1))))
scalar `VAR44'=`NC'*((1*(`SIG1'^2)/`NC'))
scalar `VAR55'=`NC'*((1*(`SIG1'^2)/`NC'))
scalar `VAR66'=`NC'*((1*(`SIG1'^2)/`NC'))
scalar `VAR12' = 0
scalar `VAR23' = 0
scalar `VAR45' = 0
scalar `VAR56' = 0
 }
if `L' == 3 {
scalar `VAR11' = `NC'*((2*(`SIGV'^2)/(`NC'*(`NT'-1))))
scalar `VAR22' = `NC'*((2*(`SIGV'^2)/(`NC'*(`NT'-1)))*trace(`MQ0'))
scalar `VAR33' = `NC'*((1*(`SIGV'^2)/(`NC'*(`NT'-1)))*trace(`MQ1'))
scalar `VAR44' = `NC'*((2*(`SIG1'^2)/`NC'))
scalar `VAR55' = `NC'*((2*(`SIG1'^2)/`NC')*trace(`MQ0'))
scalar `VAR66' = `NC'*((1*(`SIG1'^2)/`NC')*trace(`MQ1'))
scalar `VAR12' = `NC'*(2*(`SIGV'^2)/(`NC'*(`NT'-1)))*trace(`MWT1')
scalar `VAR23' = `NC'*(1*(`SIGV'^2)/(`NC'*(`NT'-1)))*trace(`MWT2')
scalar `VAR45' = `NC'*(2*(`SIG1'^2)/`NC')*trace(`MWT1')
scalar `VAR56' = `NC'*(1*(`SIG1'^2)/`NC')*trace(`MWT2')
 }
if `L' > 1 {
qui matrix `VCOV'=I(6)
qui matrix `VCOV'[1,1]=`VAR11'
qui matrix `VCOV'[1,2]=`VAR12'
qui matrix `VCOV'[2,1]=`VAR12'
qui matrix `VCOV'[2,2]=`VAR22'
qui matrix `VCOV'[2,3]=`VAR23'
qui matrix `VCOV'[3,2]=`VAR23'
qui matrix `VCOV'[3,3]=`VAR33'
qui matrix `VCOV'[4,4]=`VAR44'
qui matrix `VCOV'[4,5]=`VAR45'
qui matrix `VCOV'[5,4]=`VAR45'
qui matrix `VCOV'[5,5]=`VAR55'
qui matrix `VCOV'[5,6]=`VAR56'
qui matrix `VCOV'[6,5]=`VAR56'
qui matrix `VCOV'[6,6]=`VAR66'
qui matrix `VCOV'=invsym(`VCOV')
qui matrix `P' = (cholesky(`VCOV'))'
tempname P11 P12 P21 P22 P23 P32 P33 P44 P45 P54 P55 P56 P65 P66
scalar `P11' = `P'[1,1]
scalar `P12' = `P'[1,2]
scalar `P21' = `P'[2,1]
scalar `P22' = `P'[2,2]
scalar `P23' = `P'[2,3]
scalar `P32' = `P'[3,2]
scalar `P33' = `P'[3,3]
scalar `P44' = `P'[4,4]
scalar `P45' = `P'[4,5]
scalar `P54' = `P'[5,4]
scalar `P55' = `P'[5,5]
scalar `P56' = `P'[5,6]
scalar `P65' = `P'[6,5]
scalar `P66' = `P'[6,6]
tempvar HM11 HM21 HM31 HM41 HM51 HM61
tempvar HM12 HM22 HM32 HM42 HM52 HM62
tempvar HM13 HM23 HM33 HM43 HM53 HM63
tempvar HM14 HM24 HM34 HM44 HM54 HM64
tempvar HMY1 HMY2 HMY3 HMY4 HMY5 HMY6
gen `HM11' = 2*`SUQVQM'*`P11'+2*`SVQWQM'*`P12'
gen `HM12' = -`SVQ2M'*`P11'-`SWQ2M'*`P12'
gen `HM13' = 1*`P11'+trace(`mtr')*`P12'
gen `HM14' = 0
gen `HMY1' = `SUQ2M'*`P11'+`SVQ2M'*`P12'
gen `HM21' = 2*`SUQVQM'*`P21'+2*`SVQWQM'*`P22'+(`SVQ2M'+`SUQWQM')*`P23'
gen `HM22' = -`SVQ2M'*`P21'-`SWQ2M'*`P22'-`SVQWQM'*`P23'
gen `HM23' = 1*`P21'+trace(`mtr')*`P22'
gen `HM24' = 0
gen `HMY2' = `SUQ2M'*`P21'+`SVQ2M'*`P22'+`SUQVQM'*`P23'
gen `HM31' = 2*`SVQWQM'*`P32'+(`SVQ2M'+`SUQWQM')*`P33'
gen `HM32' = -`SWQ2M'*`P32'-`SVQWQM'*`P33'
gen `HM33' = trace(`mtr')*`P32'
gen `HM34' = 0
gen `HMY3' = `SVQ2M'*`P32'+`SUQVQM'*`P33'
gen `HM41' = 2*`SUQ1VQ1M'*`P44'+2*`SVQ1WQ1M'*`P45'
gen `HM42' = -`SVQ12M'*`P44'-`SWQ12M'*`P45'
gen `HM43' = 0
gen `HM44' = 1*`P44'+trace(`mtr')*`P45'
gen `HMY4' = `SUQ12M'*`P44'+`SVQ12M'*`P45'
gen `HM51' = 2*`SUQ1VQ1M'*`P54'+2*`SVQ1WQ1M'*`P55'+(`SVQ12M'+`SUQ1WQ1M')*`P56'
gen `HM52' = -`SVQ12M'*`P54'-`SWQ12M'*`P55'-`SVQ1WQ1M'*`P56'
gen `HM53' = 0
gen `HM54' = 1*`P54'+trace(`mtr')*`P55'
gen `HMY5' = `SUQ12M'*`P54'+`SVQ12M'*`P55'+`SUQ1VQ1M'*`P56'
gen `HM61' = 2*`SVQ1WQ1M'*`P65'+(`SVQ12M'+`SUQ1WQ1M')*`P66'
gen `HM62' = -`SWQ12M'*`P65'-`SVQ1WQ1M'*`P66'
gen `HM63' = 0
gen `HM64' = trace(`mtr')*`P65'
gen `HMY6' = `SVQ12M'*`P65'+`SUQ1VQ1M'*`P66'
 collapse `HM11' `HM12' `HM13' `HM14' `HMY1' `HM21' `HM22' `HM23' `HM24' `HMY2' ///
`HM31' `HM32' `HM33' `HM34' `HMY3' `HM41' `HM42' `HM43' `HM44' `HMY4' `HM51' ///
`HM52' `HM53' `HM54' `HMY5' `HM61' `HM62' `HM63' `HM64' `HMY6'
mkmat `HM11' `HM21' `HM31' `HM41' `HM51' `HM61', matrix(`HM1t')
mkmat `HM12' `HM22' `HM32' `HM42' `HM52' `HM62', matrix(`HM2t')
mkmat `HM13' `HM23' `HM33' `HM43' `HM53' `HM63', matrix(`HM3t')
mkmat `HM14' `HM24' `HM34' `HM44' `HM54' `HM64', matrix(`HM4t')
mkmat `HMY1' `HMY2' `HMY3' `HMY4' `HMY5' `HMY6', matrix(`HMYt')
qui matrix `HM1'=`HM1t''
qui matrix `HM2'=`HM2t''
qui matrix `HM3'=`HM3t''
qui matrix `HM4'=`HM4t''
qui matrix `HMY'=`HMYt''
qui set obs 6
tempvar V1 V2 V3 V4 Z
svmat `HM1' , name(`V1')
svmat `HM2' , name(`V2')
svmat `HM3' , name(`V3')
svmat `HM4' , name(`V4')
svmat `HMY' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `V4'1 `V4'
rename `Z'1 `Z'
qui nl (`Z'=`V1'*{Rho}+`V2'*{Rho}^2+`V3'*{sigv}+`V4'*{sig1}), init(Rho 0 sigv 1 sig1 1) nolog
scalar `RhoGM'=_b[/Rho]
scalar `SIGVV'=_b[/sigv]
scalar `SIG11'=_b[/sig1]
 }
qui matrix `matg'=`matt'#(`mats'-`RhoGM'*`wmat')
qui matrix `OMGINV' = (1/(`SIGVV'^0.5))*`Q0'+(1/(`SIG11'^0.5))*`Q1'
restore 
preserve
mkmat `yvar', matrix(`yvar')
qui matrix `yvar'=`matg'*`yvar'
qui matrix `yvar'=`OMGINV'*`yvar'
qui cap drop `yvar'
svmat `yvar', name(`yvar')
qui rename `yvar'1 `yvar'
gen `X0'=1
mkmat `X0' , matrix(`X0')
qui matrix `X0'=`matg'*`X0'
qui matrix `X0'=`OMGINV'*`X0'
svmat `X0' , name(`X0')
qui rename `X0'1 `_Cons'
foreach var of local xvar {
mkmat `var' , matrix(`var')
qui matrix `var'=`matg'*`var'
qui matrix `var'=`OMGINV'*`var'
qui cap drop `var'
svmat `var' , name(`var')
qui rename `var'1 `var'
 } 
 }
local `xvar' `var'*
if `L'==1 {
di as txt _col(3) "{bf:* Initial GMM Model: 1 }"
 }
if `L'==2 {
di as txt _col(3) "{bf:* Partial Weighted GMM Model: 2 }"
 }
if `L'==3 {
di as txt _col(3) "{bf:* Full Weighted GMM Model: 3 }"
 }
 if "`tobit'"!="" {
qui mkmat `yvar' , matrix(`Y')
 if "`noconstant'"!=""  { 
qui mkmat `xvar' , matrix(`X')
qui xtset `idv' `itv'
qui xttobit `yvar' `xvar' `wgt' , noconstant `vce' ll(0) ///
 iter(`iter') tech(`tech') `coll' 
 }
 else {
qui mkmat `xvar' `_Cons' , matrix(`X')
qui xtset `idv' `itv'
qui xttobit `yvar' `xvar' `_Cons' `wgt' , noconstant ///
 `vce' ll(0) iter(`iter') tech(`tech') `coll' 
 }
matrix `Beta'=e(b)
matrix `Beta'=`Beta'[1,1..`kb']'
matrix `E'=`Y'-`X'*`Beta'
matrix `Sig2'=`E''*`E'/`DF'
matrix `Cov'= e(V)
matrix `Cov' =`Cov'[1..`kb', 1..`kb']
ereturn scalar llf=e(ll)
 } 
else { 
tokenize `varlist'
local yvar "`1'"
macro shift 1
local xvar "`*'"
tokenize `varlist'
local yvar `1'
macro shift
local xvar "`*'"
qui mkmat `yvar' , matrix(`Y')
if "`noconstant'"!="" {
qui mkmat `xvar' , matrix(`X')
 }
 else { 
qui mkmat `xvar' `_Cons' , matrix(`X')
 }
matrix `Beta'=invsym(`X''*`X')*`X''*`Y'
matrix `E'=(`Y'-`X'*`Beta')
matrix `Sig2'=`E''*`E'/`DF'
matrix `Cov'=`Sig2'*invsym(`X''*`X')
 }
matrix `Beta'=`Beta''
if "`noconstant'"!="" {
matrix colnames `Cov' = `xvar'
matrix rownames `Cov' = `xvar'
matrix colnames `Beta'= `xvar'
 }
 else { 
matrix colnames `Cov' = `xvar' _cons
matrix rownames `Cov' = `xvar' _cons
matrix colnames `Beta'= `xvar' _cons
 }
local Nof =`N'
local Dof =`DF'
matrix `B'=`Beta'
ereturn post `B' `Cov' , dep(`yvar') obs(`Nof') dof(`Dof')
restore
end

program define yxregeq
version 10.0
 syntax varlist 
tempvar `varlist'
 gettoken yvar xvar : varlist
local LEN=length("`yvar'")
local LEN=`LEN'+3
di "{p 2 `LEN' 5}" as res "{bf:`yvar'}" as txt " = " "
local kx : word count `xvar'
local i=1
 while `i'<=`kx' {
local X : word `i' of `xvar'
 if `i'<`kx' {
di " " as res " {bf:`X'}" _c
di as txt " + " _c
 }
 if `i'==`kx' {
di " " as res "{bf:`X'}"
 }
local i=`i'+1
 }
di "{p_end}"
di as txt "{hline 78}"
end

