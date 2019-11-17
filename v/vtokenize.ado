*! version 1.0.0 December 9, 2003 @ 22:27:59
*! parses a variable into subvariables a la tokenize with macros
program define vtokenize
version 8.2
	local me vtokenize
	syntax varname [if] [in] [, stub(str) noDELIMiters Parse(passthru) noSPACE ]

	if `"`stub'"'=="" {
		local stub "`varlist'"
		}

	capture confirm names `stub'_1
	local rc = _rc
	if `rc' {
		if `rc' == 7 {
			display as error "[`me']: The first resulting variable: " as result "`stub'_1" as error " is an illegal name!"
			exit 7
			}
		else {
			display as error "[`me']: Had trouble with stub."
			error `rc'
			}
		}
	
	capture confirm new variable `stub'_1
	local rc = _rc
	if `rc' {
		if `rc' == 110 {
			display as error "[`me']: the first resulting  variable " as result "`stub'_1" as error "already exists!"
			exit 110
			}
		else {
			display as error `"[`me']: had trouble with first resulting stub variable `stub'_1"'
			error `rc'
			}
		}	/* end of error check for new variable. */

	marksample useme, strok
	quietly sum `useme'
	if r(max) == 0 {
		display as result "[`me']: no observations chosen ... nothing done"
		exit
		}
	tempvar source size
	quietly gen str `source' = `varlist'

	local cnt 1
	while `cnt' {
*set trace on
		tempvar chunk_`cnt'
*set trace off
		vgettoken `chunk_`cnt'' `source' : `source' if `useme' , replacerest `parse' `space' `delimiters'
*set trace on
		quietly {
			gen int `size' = length(`source') if `useme'
			sum `size' if `useme'

			if `r(max)'==0 {
				/* cleanup routine */
				local digits = max(1,int(log10(`cnt')))
				local recnt 1
				while `recnt'<= `cnt' {
					local newname = "`stub'_" + substr("00000",1,`digits' - length("`recnt'")) + "`recnt'"
					rename `chunk_`recnt'' `newname'
					label var `newname' "Token `recnt' from `varlist'"
					local ++recnt
					}
				local cnt 0
				}
			else {
				drop `size'
				local ++cnt
				}
			}
		}
end
