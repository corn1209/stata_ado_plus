

program githubsearchsteps
	
	syntax [anything] [, language(str) save(str) in(str) all created(str) 		///
	reference(str) duration(numlist max=1) pushed(str) Number(numlist max=1) 	///
	append replace quiet]
	
	if missing("`anything'") {
		local anything stata
	}
	if missing("`reference'") {
		di as txt "(the default time reference is used which is {bf:2016-01-01})"
		local reference "2016-01-01"
	}
	if missing("`duration'") {
		local duration 30
	}

	local today: display date(c(current_date), "DMY")
	local reference : display date("`reference'","YMD")
	local future `reference'
	
	local n 0							// indicator of the first dataset
	
	while `today' > `future' {
		
		local reference `future'
		local future = `reference' + `duration'
		
		// prepare the dates for API
		// -------------------------
		local reference : di %tdCCYY-NN-DD `reference'
		local future : di %tdCCYY-NN-DD `future'
		
		sleep 6000
		githubsearch `anything', language(`language') save(`"`save'"') in(`in')	///
		`all' created("`reference'..`future'") pushed("`pushed'") quiet			///
		`append' `replace'
	
		// return the value of date back to numeric
		local future : display date("`future'","YMD")
	}
	
	// -----------------------------------------------------------------------
	// Drawing the output table
	// =======================================================================
	if missing("`quiet'") {
		githuboutput `anything', in("`in'") `all'
	}

end


