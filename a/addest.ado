prog define addest, eclass
*!  version 1.6 by Mead Over  8Oct2015
*   Program to modify previously stored estimation results for later saving & recall

*   For example, a subsequent estimates save command will save these additions and modifications 
*	along with other estimation results, enabling a subsequent estimates table command to recall
*   and display these modified results.

	version 11.1
	syntax   [, Name(string) Value(real 0) ///  Add a single scalar to saved results
				Bvector(string) VCEmatrix(string) ///  Change elements of existing b and V
				AUGBvector(string) AUGVCEmatrix(string) ///  Augment existing b and V
				AUGEqname(string) AUGCoefname(string)  ///  Names of added row & col
				TEXTName(string) TEXTString(string)    ///  Add a local string to saved results
				rename  ]  //   Allows addest to change the row and column names of b and V
				
	if "`e(cmd)'" =="" {
    	di _n as err "No estimation results are currently in memory."
    	exit 198
	}
	if `"`name'`bvector'`vcematrix'`augbvector'`augvcematrix'`textname'`textstring'"'=="" {
		di _n as err "No options specified."
		exit 198
	}
	if (`"`name'"'~="") + ("`bvector'`vcematrix'"~="")  ///
		+ ("`augbvector'`augvcematrix'"~="") + ("`textname'"~="") > 1 {
		di _n as err "Only one of the following four pairs of options can be specified:" ///
			_n "  o    Name(string) Value(real 0)" ///
			_n "  o    Bvector(string) VCEmatrix(string)" ///
			_n "  o    AUGBvector(string) AUGVCEmatrix(string)" ///
			_n "  o    TEXTName(string) TEXTString(string)"
		exit 198
	}
	else {
		if `"`name'"'~="" {
			if "`e(`name')'"=="" {
				di _n in gr "To the results from the estimation command, " in ye "`e(cmd)'" in gr ", currently in memory,"
				di    in gr "has been added the scalar value of " in ye "e(`name')" in gr " = " in ye `value' in gr " ."
			}
			else {
				di _n in gr "For the estimates from the estimation command, " in ye "`e(cmd)'" in gr ", currently in memory,"
				di    in gr "the previously stored value of " in ye "e(`name')" in gr " which was " in ye `e(`name')' ///
					in gr " has now been replaced by " in ye `value' in gr " ."
			}
			local name = subinstr(`"`name'"'," ", "_",.)
			ereturn scalar `name' = `value'
		}
		if "`bvector'`vcematrix'"~="" {
			ereturn repost b=`bvector' V=`vcematrix' , `rename'
		}
		if "`augbvector'`augvcematrix'"~="" {
			tempname tempb tempV rowfullof0 colfullof0 augmentedrow 
			mat define `rowfullof0' = 0 * e(b)
			mat define `colfullof0' = `rowfullof0''
			mat define `tempb' = e(b)
			mat define `tempV' = e(V)
			local bcolnames : colnames `tempb'
			local beqnames  : coleq    `tempb'
			
			mat define  `tempb' =(`tempb', `augbvector')
			mat colname `tempb' =`bcolnames' `augcoefname'
			mat coleq   `tempb' =`beqnames' `augeqname'
			

			mat define  `tempV' =(`tempV', `colfullof0')
			mat define  `augmentedrow' = (`rowfullof0', `augvcematrix') 
			mat define  `tempV' =(`tempV' \ `augmentedrow')  // Space is essential after the backslash

			mat colname `tempV' =`bcolnames' `augcoefname'
			mat coleq   `tempV' =`beqnames' `augeqname'
			mat rowname `tempV' =`bcolnames' `augcoefname'
			mat roweq   `tempV' =`beqnames' `augeqname'
			
			
			capture confirm matrix e(Cns)
			if _rc==0 {
				tempname tempCns tempCnsm1 tempCnscol0 tempCnscollast
				local ncolsofCns = `e(k)' + 1
				mat def `tempCns' = e(Cns)
					mat def `tempCnscol0'    =  0*`tempCns'[1...,1]
					mat colname `tempCnscol0' = `augcoefname'
					mat coleq   `tempCnscol0' = `augeqname'
				mat def `tempCnscollast' = `tempCns'[1...,`ncolsofCns']
				local ncolsm1 = `ncolsofCns'-1
				mat def `tempCnsm1' = `tempCns'[1...,1..`ncolsm1']
				mat def `tempCns' = (`tempCnsm1',`tempCnscol0',`tempCnscollast')
			}
			
			local df_r = `e(df_r)' + 1
			local k = `e(k)' + 1
			local depvar `e(depvar)'			
			local obs = `e(N)'
			local cmd `e(cmd)'
			local cmdline `e(cmdline)'
			tempvar touse
			gen byte `touse' = e(sample)
			
			ereturn post `tempb' `tempV' `tempCns' ,  dof(`df_r') obs(`obs') esample(`touse')
			
			ereturn scalar k = `k'
			
			ereturn local cmd `cmd'
			ereturn local depvar `depvar'
			ereturn local cmdline `cmdline'
		}
		if "`textname'"~="" {
			ereturn local `textname' `textstring'
		}
   	}
end

*	Version 1.1 7/16/2012 adds the ability to augment the b and V matrices
*	Version 1.2 1/15/2013 adds the ability to add a local macro string 
*	Version 1.3 2/14/2013 adds the ability to add a local macro string 
*	Version 1.4 7/8/2013 checks whether e(Cns) exists before augmenting it.
*	Version 1.5 4/27/2014 add the -rename- option 
*	Version 1.6 8Oct2015 Allow statistics names ith blanks
