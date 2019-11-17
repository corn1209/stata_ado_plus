program define outdat_sql
*! SQL-Programm for outdat.ado ukohler@sowi.uni-mannheim.de
* builds on tosql.ado from cfb v1.1.0 1531

* Change log
* ----------

* Version 1.1: informations about nobs to main-program,
*              new output

version 7.0
syntax [varlist] using/ 

local nobs = _N

* DETERMINE IMPLIED TABLE-NAME
* ----------------------------

local using: subinstr local using `"\\"' `"/"', all
local path = index(reverse("`using'"),"/")
if `path' ~= 0 {
  local table = substr("`using'",-`path'+1,.)
}
else {
  local table `using'
}

* CATCH OPTIONS FROM OUTDAT
* -------------------------

if $outdatuc == 1 {
  local upper upper
}
if $outdatcr == 1 {
  local cre cre
}

* PRODUCE SOME OUTPUT
* -------------------
  
* Mirror Input file-name
local more : set more
set more off

if "`upper'" == "" {
  local uc "`table'"
  local outfile "`table'.sql"
  local crefile "cre_`table'.sql"
}
else {
  local uc = upper("`table'")
  local outfile "`uc'.SQL"
  local crefile "CRE_`uc'.SQL"
}	
di "{res}SQL{txt} input script written to {view `outfile':`outfile'}"

if "`cre'" != "" {
  di "{res}SQL{txt} table-creation script written to {view `crefile':`crefile'}" 
  qui file open scr using `crefile',write replace 
  if "`upper'" == "" {
    file write scr "create table `table' (" _n
  }
  else {
    file write scr "CREATE TABLE `UC' (" _n
  }
}

* CATCH VARNAMES ETC
* ------------------

local outlist "insert into `uc' ("
tokenize "`varlist'"
local i 1
while "``i''" != "" {
  local j = `i'+1
  local s`i' = 0
  local type : type ``i''
  if substr("`type'",1,3) == "str" { local s`i' = 1}
  if "`upper'" == "" {
    local outlist "`outlist'``i''"
  }
  else {
    local k = upper("``i''")
    local outlist "`outlist'`k'"
  }
  if "``j''" != "" {
    local outlist "`outlist',"
    if mod(`i',10) == 0 {local outlist "`outlist'" _n " "}
  }
  else {
    local outlist "`outlist')"
  }

  * TABLE CREATION
  * --------------
  
  if "`cre'" != "" {
    local tt = "`type'"
    if "`tt'" == "byte" { local tt = "int"}
    if `s`i'' == 1 {
      local tt = "char("+substr("`type'",4,2)+")"
    }
    if "``j''" != "" {
      local tt "`tt',"
    }
    else {
      local tt "`tt');"
    }                	
    if "`upper'" == "" {    
      file write scr "``i'' `tt'" _n
    }
    else {
      local up = upper("``i''")
      local ut = upper("`tt'")
      file write scr "`up' `ut'" _n
    }
  }     
  local i = `i' + 1 
}
if "`cre'" != "" { 
  file write scr _n
  file close scr 
}

* WRITE DATA
* ----------

qui file open sql using `outfile',write replace        
local n 1
while `n'<=`nobs' {
  if `touse'[`n']>0 {
    local j 1
    local row " values ("
    while "``j''" != "" {
      local k = `j'+1
      if `s`j'' == 0 {
        if ``j''[`n'] !=. {
          local val = ``j''[`n']
        }
        else {
          local val = "NULL"
        }
      }
      else {
      * deal with embedded single quote
      local sv = subinstr(``j''[`n'],"'","_",.)
      local val = "'`sv''"
      *        				local val = "'"+``j''[`n']+"'"
    }
      if "``k''" != "" {
        local row "`row'`val',"
        if mod(`j',10) == 0 {local row "`row'" _n " "}
      }
      else {
        local row "`row'`val');"
      }
      local j = `j'+1
    }
    file write sql "`outlist'"
    file write sql "`row'" _n
  }
  local n = `n'+1
}
file close sql
set more `more'
end
exit
