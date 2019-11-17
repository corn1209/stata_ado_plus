**************************************
*This is outtex6.ado v1
*05 Sep 2001
*Questions, comments and bug reports : 
*terracol@univ-paris1.fr
************************************* 

cap prog drop outtex6 
prog define outtex6
version 6.0 
syntax , [BELow] [LEVel] [LEgend] [DIGits(integer 3)] [LABels] [DEtails] [NOPar] [PLAIN] [TITle(string)] [KEY(string)] [PLace(string)] [LONGtable] [NOCHECK] 

********************
* Verifying syntax
******************** 

if "`legend'"!="" {
			local level="level"
			} 
if `digits'<0 | `digits' >20 {
					di as error "DIGits must be between 0 and 20"
					exit
					} 


************************
*Number and type of cols
************************ 
local nbcol=3 


local colpos=" l c c " 
if  "`level'"!="" { 
			if  "`below'"=="" & "`plain'"=="" {
									local colpos=" l r @{} l c "
									local nbcol=4
									} 
			if  "`below'"=="" & "`plain'"!="" {
									local colpos=" l c c "
									local nbcol=3
									} 
			if  "`below'"!="" & "`plain'"=="" {
									local colpos=" l r @{} l "
									local nbcol=3
									} 
			if  "`below'"!="" & "`plain'"!="" {
									local colpos=" l c  "
									local nbcol=2
									} 
			} 
local nbcol2=`nbcol'-1 
if "`level'"!="" {
			local addcol="&"
			} 

************************
*Table heads
************************ 
local nm_vr="Variable" 
local nm_cf="Coefficient" 
local nm_se="Std. Err." 
local nm_LL="Log-likelihood" 
local cons="Intercept" 
local nm_eq="Equation" 
local nm_lg="Significance levels" 
local headlo="... table \thetable{} continued" 
local footlo="Continued on next page..." 
local command=e(cmd) 
*******************************
*significance levels symbols
******************************* 
local symb10="\dag"  /* a dag */
local symb5="\ast"   /* "*" */
local symb1="\ast\ast"  /*  "**" */
********************************* 
if "`below'"!="" {
			local sep="[\sep]"
			}
if "`place'"=="" {
				local place="htbp"
				} 

local s="`level'" 
if "`legend'"!="" {
			local leg="\legend"
			} 
if "`nopar'"=="" {
			local op="("
			} 
if "`nopar'"=="" {
			local fp=")"
			} 
if "`title'"=="" {
			local title="Estimation results : `command'"
			} 
if "`key'"=="" {
			local key="tabresult `command'"
			} 
if "`level'"!="" & "`plain'"=="" {
						local mcol="\multicolumn{2}{c}"
						} 

if "`longtable'"!="" {
				local nobreak="*"
				} 

local disp="`mcol'{\textbf{`nm_cf'}}  & \textbf{`op'`nm_se'`fp'}" 
if "`below'"!="" {
			local disp=" \textbf{`nm_cf'} \"+"\"+"\\"+"`nobreak'& \fns{`op'`nm_se'`fp'}"
			} 
***********************
* Number of digits
*********************** 

local nbdec="0." 
local i=1 
while `i'<=`digits'-1 {
				local nbdec="`nbdec'0" 
				local i=`i'+1 
				} 
if `digits'==0 {
			local nbdec="1"
			} 
if `digits'>0 {
			local nbdec="`nbdec'1"
			} 


matrix coeff=get(_b) 
local a=colsof(coeff) 
matrix var=get(VCE) 
matrix var2=vecdiag(var) 
local noms : colnames coeff 
local eqs : coleq coeff 
matrix input pval=() 

********************************
* Number of equations
******************************* 
local nbeq=1 
tokenize "`eqs'" 
while "`1'"!="" {
				if "`2'"!="`1'" & "`2'"!="" {
									local nbeq=`nbeq'+1
									} 
				mac shift 
			} 


******************************
* Generating LaTeX code
****************************** 


if "`file'"=="" {
			di in wh _newline  "%------- Begin LaTeX code -------%"_newline
			} 
if "`file'"!="" {
			di in wh ""_n
			} 

**********************
* New LaTeX commands
********************** 
di in wh "{"  
if "`below'"!="" {
			di in wh "\def\sep{0.5em}"_newline"\def\fns{\footnotesize}"
			} 
if ("`leg'"=="\legend" | "`s'"!="")  {
						di in wh "\def\onepc{$^{`symb1'}$} \def\fivepc{$^{`symb5'}$}" _newline "\def\tenpc{$^{`symb10'}$}" 
						} 
if ("`leg'"=="\legend" | "`s'"!="")  {
						di in wh "\def\legend{\multicolumn{`nbcol'}{l}{\footnotesize{`nm_lg'" _newline ":\hspace{1em} $`symb10'$ : 10\% \hspace{1em}" _newline "$`symb5'$ : 5\% \hspace{1em} $`symb1'$ : 1\% \normalsize}}}" 
 						} 


**********************
* "regular" table
********************** 
if "`longtable'"=="" { 

di in wh "\begin{table}[`place']\centering \caption{`title'"_newline"\label{`key'}}"  
di in wh "\begin{tabular}{`colpos'}\hline\hline "  
di in wh "\multicolumn{1}{c}"_newline"{\textbf{`nm_vr'}}"_newline" & `disp' \\\ \hline"  
}

********************
*longtable
******************** 

if "`longtable'"!=""  {
if ("`legend'"!="" | "`details'"!="") {
						local nwline="\\\ "
							} 


di in wh  "\begin{center}"_newline "\begin{longtable}{`colpos'}"  
di in wh "\caption{`title'\label{`key'}}\\\"_newline "\hline\hline\multicolumn{1}{c}{\textbf{`nm_vr'}}"_newline" & `disp' \\\ \hline"  
di in wh "\endfirsthead"  
di in wh "\multicolumn{`nbcol'}{l}{\emph{`headlo'}}"_newline"\\\ \hline\hline\multicolumn{1}{c}{\textbf{`nm_vr'}}"_newline" & `disp' \\\ \hline"  
di in wh "\endhead"  
di in wh "\hline"  
di in wh "\multicolumn{`nbcol'}{r}{\emph{`footlo'}}\\\"  
di in wh "\endfoot"  
di in wh "\endlastfoot"  
}


*************************
*Building table lines
*************************;

local i=1 
while `i'<=`a'  {

			**************************************************
			*Variable names or labels
			************************************************** 
			tokenize "`noms'" 
		        local nom= "``i''" 
			if "`nom'"!="_cons" {
						   cap local lab : variable label `nom'
						} 
			if "`lab'" !="" & "`labels'"!="" & "`nom'"!="_cons"{
												local nom="`lab'"
												} 
			if "`nom'"=="_cons" {
							local nom="`cons'"
							} 


			***************************
			*LaTeX special characters
			************************** 
			if "`nocheck'"=="" {
							latres ,name(`nom')
							local nom="$nom"
							} 
			**************************** 



			***************************************************************
			*Rounding numbers
			*************************************************************** 
			local beta=round(coeff[1,`i'] , `nbdec') 
			if substr("`beta'",1,1)=="." {
								local beta="0`beta'"
								} 
			if substr("`beta'",1,2)=="-." {
								local pb=substr("`beta'",3,.)
								local beta="-0.`pb'"
								} 
			local ecty=round(sqrt(var2[1,`i']),`nbdec') 
			if substr("`ecty'",1,1)=="." {
								local ecty="0`ecty'"
								} 
			
			***************************
			*few corrections
			*************************** 
			tokenize "`beta'" ,parse(.) 
			if "`2'"=="" & `digits'>0 {
								local beta="`beta'"+"."
								} 
			else if "`2'"=="." {
							local beta="`1'"+"`2'"+substr("`3'",1,`digits')
						} 	
			tokenize "`ecty'" ,parse(.) 
			if "`2'"=="" & `digits'>0 {
								local ecty="`ecty'"+"."
								} 
			else if "`2'"=="." {
							local ecty="`1'"+"`2'"+substr("`3'",1,`digits')
						} 			
			tokenize "`beta'" ,parse(.) 
			local diff=`digits'-length("`3'") 
			while `diff'>0 {
						local beta="`beta'"+"0" 
						local diff=`diff'-1 
						} 
			tokenize "`ecty'" ,parse(.) 
			local diff=`digits'-length("`3'") 
			while `diff'>0 {
						local ecty="`ecty'"+"0" 
						local diff=`diff'-1 
						} 
			************************
			*significance levels
			************************ 
			if e(r2)!=. {
					matrix  pval=pval,(tprob(e(df_r), abs(coeff[1,`i']/sqrt(var2[1,`i']))))
					} 
			if e(r2)==. {
					matrix  pval=pval,2*(normprob( -abs(coeff[1,`i']/sqrt(var2[1,`i']))))
					} 

  	    		local seuil="" 
			if pval[1,`i']<=0.01 & "`s'"!="" {
									local seuil="\onepc"
									} 
			if pval[1,`i']<=0.05 & pval[1,`i']>0.01 & "`s'"!="" {
												local seuil="\fivepc"
												} 
			if pval[1,`i']<=0.1 & pval[1,`i']>0.05 & "`s'"!="" {
												local seuil="\tenpc"
												} 

			*********************
			*Table lines
			********************* 
			if "`below'"=="" & "`plain'"=="" {
									local ligne="\`nom'  &  `beta'`addcol'`seuil'  & `op'`ecty'`fp' "
									} 	
			else if "`below'"=="" & "`plain'"!="" {
									local ligne="\`nom' & `beta'`seuil' & `op'`ecty'`fp' "
										} 
			else if "`below'"!="" & "`plain'"=="" {
									local ligne="\`nom' & `beta'`addcol'`seuil' \\\"+"\\`nobreak' & \fns{`op'`ecty'`fp'} `addcol'"
										} 
			else local ligne="\`nom'  & `beta'`seuil' \\\"+"\\`nobreak' & \fns{`op'`ecty'`fp'}" 

			************************
			* displaying table lines
			************************
			if `nbeq'==1 {
					di in wh "`ligne'\\\""`sep'" 
						}
			if `nbeq'>1 {
					tokenize "`eqs'" 
					local ff=`i'-1
					if "``ff''"!="``i''" | `i'==1 {
									local var_dep="``i''"
									latres ,name(`var_dep') sortie(var_dep)
									local var_dep="$var_dep"
									local eq=`eq'+1
									di in wh  "\hline \multicolumn{`nbcol'}{c}{`nm_eq' `eq' : `var_dep'} \" "\\ \hline" 
								      di in wh "`ligne'\\\""`sep'" 	
									}
					else di in wh "`ligne'\\\""`sep'"  									
					}
							
	
	local i=`i'+1 
} 





di in wh "\hline" 


*************************
* Details
************************* 
if "`details'"!="" {
			local N=e(N) 
			di in wh  "\multicolumn{`nbcol'}{c}{}\\\" _newline"\hline N & \multicolumn{`nbcol2'}{c}{`N'}\\\" 
			}  
if "`details'"!="" & e(r2)==. {
			local LL=round(e(ll),`nbdec')
			 tokenize "`LL'" ,parse(.)
			 local LL="`1'"+"`2'"+substr("`3'",1,`digits') 
			di in wh  "`nm_LL' & \multicolumn{`nbcol2'}{c}{`LL'}\\\" 
				}  
if "`details'"!="" & e(r2)!=. {
			local R2=round(e(r2),`nbdec')
			tokenize "`R2'" ,parse(.)
			local R2="`1'"+substr("`2'",1,`digits')
			di in wh  "R$^{2}$ & \multicolumn{`nbcol2'}{c}{0`R2'}\\\" 
				}  
if "`details'"!="" & e(chi2)!=. {
			local chi2=round(e(chi2),`nbdec')
			local df=e(df_m)
			tokenize "`chi2'" ,parse(.)
			local chi2="`1'"+"`2'"+substr("`3'",1,`digits')
			di in wh  "$\chi^{2}_{(`df')}$ & \multicolumn{`nbcol2'}{c}{`chi2'}\\\" 
					}  
if "`details'"!="" & e(F)!=. {
			local F=round(e(F),`nbdec')
			local df1=e(df_m)
			local df2=e(df_r)
			tokenize "`F'" ,parse(.)
			local F="`1'"+"`2'"+substr("`3'",1,`digits')
			di in wh  "F $ _{(`df1',`df2')}$ & \multicolumn{`nbcol2'}{c}{`F'}\\\" 
					}  
if "`details'"!=""  {
		di in wh  "\hline"
			}    

if "`leg'"=="\legend" {
			di in wh  "`leg'" 
				} 



if "`longtable'"=="" {
				di in wh  "\end{tabular}"  
				di in wh  "\end{table}"  
				}

if "`longtable'"!="" {
				di in wh "\end{longtable}"_newline"\end{center}"  
				}
di in wh "}"_newline 
di in wh _newline  "%------- End LaTeX code -------%"
			
macro drop ligne* 
macro drop nom 

end 



***************************************************
*LaTeX special characters search and replace routine
***************************************************

cap prog drop latres
program define latres
version 6.0
syntax ,name(string) [sortie(string) nom]
if "`sortie'"=="" {
			local sortie="nom"
			}

local cr1="_" 
local crc1="\_"
local cr2="\"
local crc2="$\backslash$ "
local cr3="$"
local crc3="\symbol{36}"
local cr4="{"
local crc4="\{"
local cr5="}"
local crc5="\}"
local cr6="%"
local crc6="\%"
local cr7="#"
local crc7="\#"
local cr8="&"
local crc8="\&"
local cr9="~"
local crc9="\~{}"
local cr10="^"
local crc10="\^{}"
local cr11="<"
local crc11="$<$ "
local cr12=">"
local crc12="$>$ "

local nom="`name'"

			local t=length("`nom'")
			local rg=1
			local mot2=""
			while `rg'<=`t' {
						local let`rg'=substr("`nom'",`rg',1)
						local num=1
						while `num'<=12 {
									if "`let`rg''"=="`cr`num''" {
														local let`rg'="`crc`num''"
														}
									local num=`num'+1
									}
						if "`let`rg''"=="" {
										local mot2="`mot2'"+" " 
										}
						else if "`let`rg''"!="" {
											local mot2="`mot2'"+"`let`rg''"
										}		
						local rg=`rg'+1
						}
						
			global `sortie'="`mot2'"
end
