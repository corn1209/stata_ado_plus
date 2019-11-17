*! 1.1.0  20Dec1998  Jeroen Weesie/ICS
program define qsortidx, sclass
	version 6.0

	if `"`0'"' == "" {
		sreturn clear
		global S_1
		exit 
	}
      
	* parse command line on "\" into list1 list2 etc, and on options
	*   m := number of lists 
	*   n := length of lists
	* A list "*" is translated into 1..n

	tokenize `"`0'"', p(",\")
	local m 0
	while `"`1'"' ~= "," & `"`1'"' ~= "" {
		if `"`1'"' ~= "\" {
			local m = `m'+1
			local list`m' `"`1'"'
			if `m' == 1 {
				local n : word count `list`m''
			}
			else if trim(`"`list`m''"') == "*" {
				local list`m'
				local i 1
				while `i' <= `n' {
					local list`m' `"`list`m''`i' "'
					local i = `i'+1
				}
			}
			else {
				local n0 : word count `list`m''
				if `n0' ~= `n' {
					di in re "number of words in lists 1 and `m' differ"
					exit 198
				}
			}
		}
		mac shift
	}
	
	local 0 `"`*'"'
	syntax [, Ascend Descend ALpha DIsplay]
	
	* initialize keys: keyi = i
	local i 1
	while `i' <= `n' {
		local key`i' `i'
		local i = `i'+1
	}

	* define macros 1..n from list1
	tokenize `"`list1'"'

	* check that list1 is numeric
	if "`alpha'" == "" {                
		local i 1
		while `i' <= `n' {
			confirm number ``i''  
			local i = `i'+1
		}
	}                
                                        
	* sorting order
	if "`descend'" ~= "" & "`ascend'" == "" { 
		local direct ">" 
	}
	else local direct "<"

	* non-recursive quicksort (Wirth 1976: 80, with modification p 82)   
	local s 1
	local stl_1 1                       /* stack[s].l == stl_s */
	local str_1 `n'                     /* stack[s].r == str_s */
       
	while `s' > 0 {                     /* take top request from stack */
		local l `stl_`s''
		local r `str_`s''
		local s = `s'-1
                
		while `l' < `r' {           /* split key[l] ... key[r] */
			local i `l'
			local j `r'
			local ix = int((`l'+`r')/2)
			local x ``key`ix'''     
			
			while `i' <= `j' {

				if "`alpha'" == "" {
					while ``key`i''' `direct' `x'        { local i = `i'+1 }
					while `x'        `direct' ``key`j''' { local j = `j'-1 }
				}
				else {
					while `"``key`i'''"' `direct' `"`x'"' { local i = `i'+1 }
					while `"`x'"' `direct' `"``key`j'''"' { local j = `j'-1 }                                
				}                                        

				if `i' <= `j' {         /* swap keys for elements i and j */
					local tmp    `key`i''
					local key`i' `key`j''  
					local key`j' `tmp'
					local i = `i'+1   
					local j = `j'-1   
				}          
			}

			* stack request to sort either left or right partition
			if `j'-`l' < `r'-`i' {
				if `i' < `r' {        /* sort right partition */
					local s = `s'+1
					local stl_`s' `i'    
					local str_`s' `r'    
				}
				local r `j'     
			}
			else {
				if `l' < `j' {       /* sort left partition */
					local s = `s'+1
					local stl_`s' `l'    
					local str_`s' `j'    
				}
				local l `i'     
			}
		} /* while l < r */
	}   
     
	* apply sort ordering, leaving results in slist1 (S_1), slist2 (S_2), .. etc 
	sreturn clear
	local j 1
	while `j' <= `m' {
		local i 1
		local list
		if `j' > 1 {
			tokenize `"`list`j''"'
			local list
		}
		while `i' <= `n' {
			local list `"`list'``key`i''' "'
			local i = `i'+1
		}
		* double save
		sreturn local slist`j' `"`list'"'
		global S_`j' `"`list'"'
		if "`display'" ~= "" {
			di `"`j': `list`j'' --> `list'"'
		}                        
		local j = `j'+1
	}               
        
	* return the ordering
	local i 1
	while `i' <= `n' {
		local order `"`order' `key`i''"'
		local i = `i'+1
	}                
	global S_0 `"`order'"'
	sreturn local order `"`order'"'
end
