*! bking  1.0.4  CF Baum/MLopez  28jun2006
*  from bking(8).ado  1.0.3  22Oct2004
* 1.0.1: perform B mtx code in variable, reduce max matrix to T
*        require tsset, enable if/in/ts ops in varlist
* 1.0.2: change naming of result vars to F..., remove generate option
* 1.0.3: correct handling of magic, restore missings in generated series,
*        create new vars with mandatory stub option; trap large K
* 1.0.4: bking Mata version from
*        http://ideas.repec.org/c/wpa/wuwppr/0507001.html
*        corr for tsrevar, byable(recall)

program define bking, rclass byable(recall,noheader)
        version 9.2

syntax varlist(ts) [if] [in], PLO(string) PHI(string) STUB(string) [K(int 12)] 

        marksample touse
        _ts timevar panelvar if `touse', sort onepanel
        markout `touse' `timevar'
        tsreport if `touse', report
        if r(N_gaps) {
                di in red "sample may not contain gaps"
                exit
                }
        if `plo' >= `phi' {
                di in red "Lower bound (plo) must be less than upper bound (phi)"
                error 198
                }
        if `plo' < 2     {
                di in red "Lower bound (plo) must be at least 2"
                error 198
                }
        if `k' < 1     {
                di in red "K must be at least 1"
                error 198
                }
        su `touse', mean
        if 2*`k'>=r(mean)*r(N) {
                di in r "K too large for sample size"
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

        mata: bkmata("`varlist1'","`varlist3'","`touse'",`plo', `phi', `k')

        return local rawvars "`varlist'"
        return local filtvars "`varlist3'"      
        return local phi "`phi'"  
        return local plo "`plo'"
        return local K "`K'"
        end
        

mata:
// from Pawel Kowal's BK function for MATLAB

       void bkmata(string scalar vname, 
                   string scalar vname3, 
                   string scalar touse,
                   real scalar plo,
                   real scalar phi,
                   real scalar K)                         
        {      
        real scalar a, b, s, c 
        real matrix X, Y
        real vector J, B, B1, BB, T, t, BB1
        string rowvector vars, vars3
        string scalar v, v3    
        		       
// access the Stata variables in varlist, varlist3, honoring touse
       	vars = tokens(vname)
       	v = vars[|1,.|]
        st_view(X,.,v,touse)
        vars3 = tokens(vname3)
        v3 = vars3[|1,.|]
// Y contains cyclical components to be extracted from X 
        st_view(Y,.,v3,touse)
        T = rows(X)
        c = cols(X)
        plo = max((2, plo))
      
        a = 2*pi()/phi
        b = 2*pi()/plo
       
        J   = (1::K)
        B   = (sin(b:*J) - sin(a:*J)):/ (pi():*J)
        B  = ( (b-a)/pi() \ B )
        
        s = (1,J(1,K,2)) * B
		BB = B :- s/(2*K+1)
		BB = (flipud(BB[|2\.|]) \ BB)
	
    	for (t= K+1; t<=T-K; t++){
 			Y[t,.] = BB' * X[| t-K, 1 \ t+K, c|]
 		} 			
  }
  matrix function flipud(matrix X)
  {
  		return(rows(X)>1  ?  X[rows(X)..1,.] : X)
  		
  }	    
    end
    
   
