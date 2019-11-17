program bytwoway, rclass 
syntax anything [if] [in], /// 
by(varlist) ///
[Missing ///
AESthetics(string) ///
Palette(string) Colors(string asis) MColors(string asis) ///
LColors(string asis) MSymbols(string asis) LPatterns(string asis) ///
legend(string) SEParation(string) noPLOT * ///
]


/* syntax */
if regexm("`anything'", "^\((.*)\)$"){
    local anything `=regexs(1)'
    if regexm("`anything'", "^(.*)\,(.*)$"){
        local anything `=regexs(1)'
        local optionwithin `=regexs(2)'
    }
}
if "`separation'" == ""{
    local separation ", "
}
if "`legend'" ~= ""{
    local legendoption legend(`legend')
}
/* save initial sort */
local sortedby `:sortedby'
local withinsort `=subinstr(" `sortedby' ","`by'", "", 1)'

/* missing */
marksample touse
if "`missing'" == "" {
    markout `touse' `by' , strok
}

qui count if `touse'
local samplesize=r(N)
local touse_first=_N-`samplesize'+1
local touse_last=_N
tempvar bylength

bys `touse' `by' (`withinsort'): gen long `bylength' = _N 
local start = `touse_first'
local iter = 0

tempvar t
bys `touse' `by' : gen long `t' = _n == _N if `touse'
count if `t' & `touse'
local bynum = r(N)



/* aesthetics */
* default aesthetics to color and replace color by mcolor and lcolor
if "`aesthetics'" == ""{
    local aesthetics mcolor lcolor
}
local aesthetics = subinstr(" `aesthetics' ", " color ", " mcolor lcolor ", 1)


if `"`colors'"' == ""{
    if "`palette'" ~= ""{
        if regexm("`aesthetics'", "mcolor") | regexm("`aesthetics'", "lcolor"){
            cap which colorscheme.ado
            if _rc {
                di as error "colorscheme.ado required when using the option palette: {stata net install colorscheme, from(https://github.com/matthieugomez/stata-colorscheme)}"
                exit 111
            }
            colorscheme `bynum', palette(`palette')
            local colors `"`=r(colors)'"'
        }
        else{
            di as error "You must specify one of color, mcolor, lcolor in the option aes"
            exit      
        }
    }
    else{
        local colors ///
        navy maroon forest_green dkorange teal cranberry lavender ///
        khaki sienna emidblue emerald brown erose gold bluishgray ///
        lime magenta cyan pink blue
    }
}

/* prepare script for each by value */


* Fill colors if missing
local color1 `: word 1 of `colors''
local color2 `: word 2 of `colors''
if `"`mcolors'"'=="" {
  if regexm("`aesthetics'","mcolor"){
    local mcolors `"`colors'"'
}
else{
    local aesthetics `aesthetics' mcolor
    local mcolors `color1' `color1' `color1' `color1' `color1' `color1' `color1' ///
    `color1' `color1' `color1' `color1' `color1' `color1' `color1' `color1' ///
    `color1' `color1' `color1' `color1' `color1' `color1' `color1' `color1'
}
}

if `"`lcolors'"'=="" {
    if regexm("`aesthetics'","lcolor"){
        local lcolors `"`colors'"'
    }
    else{
        local aesthetics `aesthetics' lcolor
        local lcolors `color2' `color2' `color2' `color2' `color2' `color2' `color2' ///
        `color2' `color2' `color2' `color2' `color2' `color2' `color2' `color2' ///
        `color2' `color2' `color2' `color2' `color2' `color2' `color2' `color2'
    }
}

if `"`lpatterns'"'=="" {
    if regexm("`aesthetics'","lpattern"){
        local lpatterns solid dash vshortdash longdash longdash_dot shortdash_dot dash_dot_dot longdash_shortdash dash_dot  dash_3dot longdash_dot_dot shortdash_dot_dot longdash_3dot dot tight_dot
    }
    else{
        local aesthetics `aesthetics' lpattern
        local lpatterns solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid 
    }
}

if `"`msymbols'"'=="" {
    if regexm("`aesthetics'","msymbol"){
        local msymbols circle diamond square triangle x plus circle_hollow diamond_hollow square_hollow triangle_hollow smcircle smdiamond smsquare smtriangle smx

    }
    else{
        local aesthetics `aesthetics' msymbol
        local msymbols circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle circle 
    }
}


/* create byname, bylabel (bylabel if by == 1) */
local byn: word count `by'
if `byn' >1 {
    local iby = 0
    foreach v in `by'{
       local ++iby
       local bylabel`iby' `: value label `v''
       local byname`iby' `: var label `v''
       if `"byname`iby'"' == ""{
           local byname`iby' `v'
       }
       local byname `"`byname'`separation'`byname`iby''"'
   }
   local byname =subinstr(`"`byname'"',"`separation'"," ",1)
   local bylegend legend(subtitle(`"`byname'"'))
}
else{
    local byname `: var label `by''
    if `"`byname'"' == ""{
        local byname `by'
    }
    local bylegend legend(subtitle(`"`byname'"'))
    local bylabel `:value label `by''
}




while `start' <= `touse_last'{
    local ++iter
    local optionlabel
    local optionaes
    local end = `start' + `bylength'[`start'] - 1
    local byvalname 
    if `byn' == 1{
        local byval `=`by'[`start']'
        if ("`bylabel'"=="") {
            local byvalname `byval'
        }
        else {
            local byvalname `: label `bylabel' `byval''
        }
    }
    else{
        local iby = 0
        foreach v in `by'{
            local ++iby
            local byval`iby' = `v'[`start']
            if ("`bylabel`iby''"=="") {
                local byvalname `byvalname'`separation'`byval`iby''
            }
            else {
                local byvalname `"`byvalname'`separation'`: label `bylabel`iby'' `byval`iby'''"'
            }
        }
        local byvalname `=subinstr(`"`byvalname'"',"`separation'"," ",1)'
    }
    foreach a in `aesthetics' {
        local optionaes `optionaes'  `a'(`"`:word `iter' of ``a's''"')
    }
    if "`legend'" ~= "off"{
        local optionlabel `optionlabel' legend(label(`iter' `"`byvalname'"'))
    }
    local script `script' (`anything' in `start'/`end', `optionwithin' `optionaes' `optionlabel')
    local start = `end' + 1
}

/* graph */
local cmd twoway `script',  `bylegend'  `options' `legendoption'
if "`plot'" == ""{
    qui `cmd'
}
return local cmd  `"`cmd'"'

end

/***************************************************************************************************
sysuse nlsw88.dta, clear
collapse (mean) wage, by(grade race)
bytwoway line wage grade, by(race)

sysuse nlsw88.dta, clear
collapse (mean) wage, by(grade smsa race)
bytwoway line wage grade, by(smsa race)
***************************************************************************************************/
