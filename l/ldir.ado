*! version 2.6 Januar 31, 2013 @ 10:25:30 UK
*! Clickable list of folders
* Hack on -folders- by NJC
* 1.0 Initial version
* 1.1 Bug for Direcory names with blanks -> fixed
* 2.0 Add some fastcd functionality
* 2.1 Add current directory name and filetypes present,
*     lcd local
* 2.2 Program did not returned folder-list. -fixed
* 2.3 Allways list ado-files in working directory
* 2.4 Bookmarks for Windows did not work - fixed (Thanks D. Elliot)
* 2.5 Bug calling leps and ltex - fixed
* 2.6 User string is search pattern

// Main Caller
// -----------

program ldir, rclass
version 10.1

gettoken subcmd 0: 0
if "`subcmd'"=="LCD" {
	LCD `0'
}
else {
	LISTIT `0'
	return local files `"`r(folders)'"'
}
end


// LISTIT
// ------

program LISTIT, rclass
version 10.1

syntax [name] [, Hidden]

// Collect subfolder names
local pwd `"`c(pwd)'"'
local pwd: subinstr local pwd `"\"' `"/"', all

local names: dir `"`pwd'"' dirs "*`namelist'*"
local names: list sort names

if "`hidden'" == "" {
foreach name of local names {
	if `"`=substr(`"`name'"',1,1)'"' != `"."'  /// 
	  local folders `"`folders' `"`name'"'"'
}
}
else local folders `"`names'"'

// Collect filetypes present
foreach ext in do dta gph smcl ado mata tex eps {
local here = cond("`ext'" == "ado",".","")
local type: dir `"`pwd'"' files "*.`ext'"
if `"`type'"' != `""' local types `types' {txt:[}{stata `"l`ext' `here'"':.`ext'}{txt:]}
}

// Get Bookmarks 
GetBookmarks
local bookmarks `"`r(bookmarks)'"'
local bookmarknames `"`r(bookmarknames)'"'

// Autogenerate Bookmarkname
local thispath `c(pwd)'
local lasttoken: subinstr local thispath `" "' `"_"', all
local lasttoken: subinstr local lasttoken `"`c(dirsep)'"' `" "', all
local count: word count `lasttoken'
local lasttoken: word `count' of `lasttoken'

// Add or Remove Bookmark?
local bookmarked: list lasttoken in bookmarknames
if `bookmarked' local fastcdcommand `"stata `"c drop `lasttoken'"':-"'
else local fastcdcommand `"stata `"c cur `lasttoken'"':+"'


// Output
di _n `"{txt:Working directory now: {res:`c(pwd)'}} {txt:[}{`fastcdcommand'}{txt:]}"'
di _n `"{txt:Places to go:}"' 

display 								/// 
  `"{txt:[}{stata `"ldir LCD `"`pwd'/.."'"':up}{txt:]}"' ///
  `"{txt: [}{stata `"ldir LCD "':home}{txt:]}"' ///
  `"`bookmarks'"'

di _n `"{txt:Subfolders:}"' 
DisplayInCols_ldir `"`pwd'"' res 0 2 0 `folders' 
if trim(`"`folders'"') != "" {
	return local folders `"`folders'"' 
}	

di _n `"{txt:Known filetypes here:}"' 
di `"`types'"'

end


// VERBOSE CHANGE DIRECTORY
// ------------------------

program define LCD
version 10.1
	quietly cd `0'
	ldir
end


// Formatted Output for bookmarks
// ------------------------------

program DisplayInCols_bookmarks /* sty #indent #pad #wid <list>*/
	gettoken indent 0 : 0
	gettoken pad    0 : 0
	gettoken wid	0 : 0

	local indent = cond(`indent'==. | `indent'<0, 0, `indent')
	local pad    = cond(`pad'==. | `pad'<1, 2, `pad')
	local wid    = cond(`wid'==. | `wid'<0, 0, `wid')
	
	local n : list sizeof 0
	if `n'==0 { 
		exit
	}

	foreach x of local 0 {
		local wid = max(`wid', length(`"`x'"'))
	}

	local wid = `wid' + `pad'
	local cols = int((`c(linesize)'+1-`indent')/`wid')

	if `cols' < 2 { 
		if `indent' {
			local col "column(`=`indent'+1)"
		}
		foreach x of local 0 {
			di as `sty' `col' `"{stata `"ldir LCD `pwd'/`x'"':`x'}"'
		}
		exit
	}
	local lines = `n'/`cols'
	local lines = int(cond(`lines'>int(`lines'), `lines'+1, `lines'))

	* di "n=`n' cols=`cols' lines=`lines'"
	forvalues i=1(1)`lines' {
		local top = min((`cols')*`lines'+`i', `n')
		local col = `indent' + 1 
		* di "`i'(`lines')`top'"
		forvalues j=`i'(`lines')`top' {
			local x : word `j' of `0'
			di as `sty' _column(`col') `"{stata `"ldir LCD `"`pwd'/`x'"'"':`x'}"' _c
			local col = `col' + `wid'
		}
		di as `sty'
	}
end


// Formatted Output for folders
// ----------------------------
// Hack on DisplayInCols (as used by -folders-)

program DisplayInCols_ldir /* sty #indent #pad #wid <list>*/
	gettoken pwd    0 : 0
	gettoken sty    0 : 0
	gettoken indent 0 : 0
	gettoken pad    0 : 0
	gettoken wid	0 : 0

	local indent = cond(`indent'==. | `indent'<0, 0, `indent')
	local pad    = cond(`pad'==. | `pad'<1, 2, `pad')
	local wid    = cond(`wid'==. | `wid'<0, 0, `wid')
	
	local n : list sizeof 0
	if `n'==0 { 
		exit
	}

	foreach x of local 0 {
		local wid = max(`wid', length(`"`x'"'))
	}

	local wid = `wid' + `pad'
	local cols = int((`c(linesize)'+1-`indent')/`wid')

	if `cols' < 2 { 
		if `indent' {
			local col "column(`=`indent'+1)"
		}
		foreach x of local 0 {
			di as `sty' `col' `"{stata `"ldir LCD `pwd'/`x'"':`x'}"'
		}
		exit
	}
	local lines = `n'/`cols'
	local lines = int(cond(`lines'>int(`lines'), `lines'+1, `lines'))

	* di "n=`n' cols=`cols' lines=`lines'"
	forvalues i=1(1)`lines' {
		local top = min((`cols')*`lines'+`i', `n')
		local col = `indent' + 1 
		* di "`i'(`lines')`top'"
		forvalues j=`i'(`lines')`top' {
			local x : word `j' of `0'
			di as `sty' _column(`col') `"{stata `"ldir LCD `"`pwd'/`x'"'"':`x'}"' _c
			local col = `col' + `wid'
		}
		di as `sty'
	}
end

// Reads out Bookmarks of fastcd
// -----------------------------
// Hack on c.ado by Nick Winter

program GetBookmarks, rclass
version 11
local x : sysdir PERSONAL
local file `"`x'directoryfile.txt"'

cap confirm file `"`file'"'
if !_rc {	/* file exists -- read in the database */
	tempname hdl
	capture file open `hdl' using `"`file'"' , text read
	file read `hdl' line
	local i 0
	while !r(eof) {
		local i=`i'+1
		tokenize `"`line'"', parse("*")
		local bookmark 					/// 
	   `"`bookmark' {txt:[}{stata `"ldir LCD `"`3'"'"':`1'}{txt:]}"'
	   local bookmarknames `"`bookmarknames' `1'"'
		file read `hdl' line
	}
	file close `hdl'
}

return local bookmarks `"`bookmark'"'
return local bookmarknames `"`bookmarknames'"'
end

