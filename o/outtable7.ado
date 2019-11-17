*! outtable 1.0.4   cfb 3612  for Petia
* 1.0.1: 1714 rev for table->caption, add table env 
* key option removed; not interacting properly with SciWord
* 1.0.2: 1C26 add option norowlab
* 1.0.3: 2227 problem with non-symmetric being claimed as symmetric (Ben Kriechel)
* 1.0.4: 3612 add option nosymm
*
program define outtable7,rclass
version 7.0
syntax using/, mat(string) [Replace APPend noBOX Center ASIS CAPtion(string) Format(string) noROWlab noSYM]
tempname hh dd ddd
local nr=rowsof(`mat')
local nc=colsof(`mat')
if "`replace'" == "replace" {local opt "replace"}
if "`append'" == "append" {local opt "append"}
file open `hh' using "`using'.tex", write `opt'
file write `hh' "% matrix: `mat' file: `using'.tex  $S_DATE $S_TIME" _n
* add h to prefer here
file write `hh' "\begin{table}[htbp]" _n
if "`caption'" ~= "" {
	file write `hh' "\caption{`caption'}\centering\medskip" _n
	}

local nc1 = `nc'-1
if "`box'" ~= "nobox" { 
	local vb "|"
	local hl "\hline" 
	}
local align "l"
if "`center'" == "center" { local align "c" }
local l "`vb'l"
forv i=1/`nc' { 
	local l "`l'`vb'`align'" 
	}
local symm 0
if "`sym'" ~= "nosym" {
	capt mat `dd' = det(`mat'-(`mat')')
	capt scalar `ddd' = `dd'[1,1]
	capt if `ddd' == 0  { local symm 1 }
	if `symm' == 1 { di _n "Note: matrix assumed symmetric" }
	}
local rnames : rownames(`mat')
local cnames : colnames(`mat')
local l "`l'`vb'"
file write `hh' "\begin{tabular}{`l'}"  "`hl'" _n
forv i=1/`nc' {
	local cn : word `i' of `cnames'
	local cnw = cond("`asis'"=="asis","`cn'",subinstr("`cn'","_"," ",.))
	if `i'==1 & "`rowlab'" == "norowlab" {
		file write `hh' " `cnw' "
		}
	else {
		file write `hh' " & `cnw' "
	}
	}
file write `hh' " \" "\ `hl'" _n 
local jlim `nc1'
local klim `nc'
forv i=1/`nr' {
	local rn : word `i' of `rnames'
	local rnw = cond("`asis'"=="asis","`rn'",subinstr("`rn'","_"," ",.))
	if "`rowlab'" ~= "norowlab" { file write `hh' "`rnw' & " }
	if `symm'==1 { 
		local jlim = `i'-1 
		local klim = `i'
		}
	forv j=1/`jlim' {
		file write `hh' `format' (`mat'[`i',`j']) " & "
		}
	file write `hh' `format' (`mat'[`i',`klim'])
	file write `hh' " \" "\ `hl'" _n 
	}
file write `hh' "\end{tabular}" _n
*if "`key'" ~= "" {
*	file write `hh' "\label{`key'}" _n
*	}
file write `hh' "\end{table}" _n
file close `hh'		
end

