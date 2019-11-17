capture program drop mlboolean  /* Version 1.3 */
program define mlboolean
version 8.1
	global xpath "`0'"
	gettoken rem feed: 0
	global feed "`feed'"
	global typepl "`1'"
	capture assert "$typepl"=="logit" | "$typepl"=="probit"
	if _rc { 
		di in red "Improper link function: $typepl"
		di in red "Link function must be either logit or probit"
		exit 198
	}
	local n = "`2'"
	capture assert `n'<6 & `n'>1
	if _rc { 
		di in red "Invalid number of causal paths (`n')"
		exit 198
	}

	foreach i of numlist 900 1000 0 1001 1/`n' {
	   gettoken path`i' 0 : 0, match(holder)
	   }
	global depvarxx "`path1001'"
    confirm variable $depvarxx
	capture assert $depvarxx==0 | $depvarxx==1 | $depvarxx==.
	if _rc { 
		di in red "$depvarxx is not a 0/1 variable."
		exit 450
	}

	gettoken bs ps: 0, parse(",")
	local boptions = subinstr("`bs'",",","",.)
	tokenize "`boptions'", parse("(",")")
	   local foo `1'
	   local foo2 `3'
	   if "`foo'" != "" {
	      if "`foo'" == "ystar" {
	         local vname="`foo2'"
	         }
	         else{
	            di in red "Unknown pre-comma option: `foo'."
	            exit 450
	         }
	      }
	      else{
	         local vname="ystar"
	         }
	 
	 capture confirm variable boolpred
	 if !_rc{
	    di in red "Warning: Variable boolpred exists and will be overwritten."
	    di in green "Continue? (y/n)" _request(cont)
	    if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Exiting..."
	       exit 110
	       }
	       else {
	          di in green "Dropping variable boolpred and continuing..."
	          quietly capture drop boolpred
	          }
	    }
	 capture confirm variable `vname'_a
	 if !_rc{
	    di in red "Warning: Variable `vname'_a exists and will be overwritten."
	    di in green "Continue? (y/n)" _request(cont)
	    if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Names for saved latent variables can be set with the ystar() option."
	       di in green "Exiting..."
	       exit 110
	       }
	       else {
	          di in green "Dropping variable `vname'_a and continuing..."
	          quietly capture drop `vname'_a
	          }
	    }
     if `n' > 1 {
		 capture confirm variable `vname'_b
		 if !_rc{
			di in red "Warning: Variable `vname'_b exists and will be overwritten."
			di in green "Continue? (y/n)" _request(cont)
			if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Names for saved latent variables can be set with the ystar() option."
	       di in green "Exiting..."
	       exit 110
			   }
			   else {
				  di in green "Dropping variable `vname'_b and continuing..."
				  quietly capture drop `vname'_b
				  }
			}
     }
     if `n' > 2 {
		 capture confirm variable `vname'_c
		 if !_rc{
			di in red "Warning: Variable `vname'_c exists and will be overwritten."
			di in green "Continue? (y/n)" _request(cont)
			if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Names for saved latent variables can be set with the ystar() option."
	       di in green "Exiting..."
	       exit 110
			   }
			   else {
				  di in green "Dropping variable `vname'_c and continuing..."
				  quietly capture drop `vname'_c
				  }
			}
     }
     if `n' > 3 {
		 capture confirm variable `vname'_d
		 if !_rc{
			di in red "Warning: Variable `vname'_d exists and will be overwritten."
			di in green "Continue? (y/n)" _request(cont)
			if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Names for saved latent variables can be set with the ystar() option."
	       di in green "Exiting..."
	       exit 110
			   }
			   else {
				  di in green "Dropping variable `vname'_d and continuing..."
				  quietly capture drop `vname'_d
				  }
			}
     }
     if `n' > 4 {
		 capture confirm variable `vname'_e
		 if !_rc{
			di in red "Warning: Variable `vname'_e exists and will be overwritten."
			di in green "Continue? (y/n)" _request(cont)
			if "$cont" != "y" & "$cont" != "Y" & "$cont" != "yes" {
	       di in green "Names for saved latent variables can be set with the ystar() option."
	       di in green "Exiting..."
	       exit 110
			   }
			   else {
				  di in green "Dropping variable `vname'_e and continuing..."
				  quietly capture drop `vname'_e
				  }
			}
     }

	      
	local poptions = subinstr("`ps'",",","",.)
/* End programming in progress. */
	if "$typepl" == "logit" {
	    mlboolprep `feed'
	    ml model lf mlboollog $mlpart1 $mlpart2 $mlpart3 $mlpart4 $mlpart5, maximize title(Boolean Logit Estimates) `poptions'
        ml display
        }
        
	if "$typepl" == "probit" {
	    mlboolprep `feed'
	    ml model lf mlboolprob $mlpart1 $mlpart2 $mlpart3 $mlpart4 $mlpart5, maximize title(Boolean Probit Estimates) `poptions'
        ml display
        }
    tempvar dropme
    quietly predict `dropme' if e(sample)
	matrix b = e(b)
	mlboolpred
	tempvar hitsasf
	quietly gen `hitsasf' = (boolpred >= .5)*($depvarxx==1)+(boolpred < .5)*($depvarxx==0)
    quietly replace `hitsasf'=. if `dropme'==.
	capture quietly sum `hitsasf'
	di "Correctly predicted " in yellow r(sum) in green " of " in yellow e(N) in green " cases, or " in yellow round((r(sum)/e(N))*100,0.01) "%" in green "."
	capture rename PathProb1 `vname'_a
	capture rename PathProb2 `vname'_b
	capture rename PathProb3 `vname'_c
	capture rename PathProb4 `vname'_d
	capture rename PathProb5 `vname'_e

end

