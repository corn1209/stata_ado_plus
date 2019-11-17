*! butterworth 1.0.0 CFBaum / MLopez 03jul2006
* 1.0.0: butterworth Mata version from
*        http://ideas.repec.org/c/wpa/wuwppr/0507001.html

program define butterworth, rclass byable(recall,noheader)
        version 9.2
        
syntax varlist(ts) [if] [in],  FREQ(string) STUB(string) [Order(int 2)]
 
	    marksample touse
        _ts timevar panelvar if `touse', sort onepanel
    	markout `touse' `timevar'
    	tsreport if `touse', report
    	if r(N_gaps) {
        	di as err "sample may not contain gaps"
        	exit 198 
    	}
   
        if `order' <= 0 {
        	 di in red "order must be at least 1"
        	 error 198
 		}
 		local n `order'    
        
        if `freq'  <= 2 {
                di in red "Cut-off frequency (periods per cycle) must be > 2"
                error 198
        }
      
* validate each new varname defined by stub()
        local kk: word count `varlist'
        local varlist2: subinstr local varlist "." "_", all   
        local suf = _byindex()
        qui forval i = 1/`kk' {
                local v: word `i' of `varlist2'
                confirm new var `stub'_`v'_`suf'
                gen float `stub'_`v'_`suf' = .
                local varlist3 "`varlist3' `stub'_`v'_`suf'"              
        }
* create temp vars for any ts operators in the varlist
* pass the resulting varlist1 to Mata fn
        tsrevar `varlist'
        local varlist1 `r(varlist)'

        mata: bwmata("`varlist1'","`varlist3'","`touse'", `n', `freq')
 
		return local rawvars "`varlist'"
    	return local filtvars "`varlist3'"
    	return local n "`n'"  
    	return local freq "`freq'"
    end
        
mata:
// from Pawel Kowal's butterworth function for MATLAB

void bwmata(string scalar vname, 
            string scalar vname3,
            string scalar touse, 
            real scalar n,
            real scalar freq)
               
		{
    	    real scalar T, cut_off, mu
        	real matrix  X, I, LT, Q, b, SIGMA_R, SIGMA_T, g, A, base, Z, res
        	string rowvector vars, vars3
        	string scalar v, v3
                
// access the Stata variables in varlist, varlist3, honoring touse
        	vars = tokens(vname)
        	v = vars[|1,.|]
        	st_view(X,.,v,touse)
        	vars3 = tokens(vname3)
        	v3 = vars3[|1,.|]
// Y contains the filtered series
        	st_view(Y,.,v3,touse)
        	T = rows(X)
  			cut_off = 2*pi()/freq
       		mu = (1/(tan(cut_off/2)))^(2*n) 
        	I = I(T)
       		LT = J(T,T,0)
        	for (i=2; i<=T; i++){
            	    LT[i,i-1] = 1.0
        	}
		
	  		base = (I-LT)
	     	Z = pow(base, n)       
	        Q = (Z[(3::T),.])'
	        SIGMA_R = Q' * Q
    	    SIGMA_T = abs(SIGMA_R) 
			g = Q' * X
			A = (SIGMA_T + mu * SIGMA_R) 
			b = cholsolve(A, g)
        	Y[.,.] = mu * Q * b 
}

matrix function pow(real matrix X, real scalar n) {
// raise matrix to a power
	    real scalar i
     	real matrix res
     	res = I(rows(X))
	    for (i=1; i<=n; i++){
    		res = res * X
		}
		return(res)
}

end
