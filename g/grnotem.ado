program define grnotem
version 6.0
*! version 1.3.0 Michael Blasnik 2/01/2001

* frame text control
	global DB_tco "Text Options"
	window control static DB_tco 4 5 239 64 blackframe 
	window control static DB_tco 85 2 60 10 center

* text to write
        global DB_tm "Text:"
        window control static       DB_tm  6 11 18 9
        global DB_text "Test"
        window control edit         33 11 150 10 DB_text

* Text style
	global DB_ts "100"
	global DB_tsm "Size:"
        window control static       DB_tsm  5 25 17 9
        window control edit         23 25 15 9 DB_ts

	global DB_tp "1"
	global DB_pl "1 2 3 4 5 6 7 8 9"
	global DB_tpm "Pen#:"
        window control static       DB_tpm  50 25 20 9
        window control scombo    DB_pl  72 24 25 100 DB_tp

	global DB_tam "Align:"
	global DB_ta "center"
	global DB_tal "center left right"
	global DB_tvm "Valign:"
	global DB_tva "auto"
	global DB_tval "auto top bottom center"

        window control static       DB_tam  106 25 20 9
        window control scombo    DB_tal  127 24 40 100 DB_ta
        window control static       DB_tvm  174 25 20 9
        window control scombo    DB_tval  198 24 40 100 DB_tva

* text location	
        global DB_tpos "Location:"
        window control static          DB_tpos  5 40 30 9
        global DB_ty "1"
	global DB_tx "1"
        window control edit         43 40 30 10 DB_ty
        window control edit         90 40 30 10 DB_tx
	
        window control button "Y+"     43 52 16 10 DB_yp 
        window control button "Y-"     59 52 16 10 DB_ym
        window control button "X+"     90 52 16 10 DB_xp 
        window control button "X-"     106 52 16 10 DB_xm

* jump size control
	global DB_jump "2"
	global DB_jl "0.5 1 2 5 10"
	global DB_jt "Jump Size %"
        window control static       DB_jt  5 73 40 9
        window control scombo    DB_jl  50 72 30 90 DB_jump

* Pixel coordinate mode
	global DB_chkx=0
	window control check "Virtual Pixel coordinates" 140 72 90 10 DB_chkx


* frame line control
	global DB_lco "Line Drawing Options"
	window control static DB_lco 4 85 239 80 blackframe 
	window control static DB_lco 80 83 80 10 center


* line placement options
        global DB_lpos "Line End:"
        window control static          DB_lpos  5 95 30 9
        global DB_ly ""
	global DB_lx ""
        window control edit         43 95 30 10 DB_ly
        window control edit         90 95 30 10 DB_lx

        window control button "Y+"     43 107 16 10 DB_ypl 
        window control button "Y-"     59 107 16 10 DB_yml
        window control button "X+"     90 107 16 10 DB_xpl 
        window control button "X-"     106 107 16 10 DB_xml

* line style options
        global DB_lop "Style:"
        window control static          DB_lop  5 130 17 9
	global DB_lp "3"
        window control static       DB_tpm  30 130 20 9
        window control scombo    DB_pl  54 129 25 100 DB_lp

	global DB_la "auto"
	global DB_lal "auto center left right"
	global DB_lva "auto"
	global DB_lval "auto center top bottom "

        window control static       DB_tam  98 130 20 9
        window control scombo    DB_lal  119 129 40 100 DB_la

        window control static       DB_tvm  166 130 20 9
        window control scombo    DB_lval  190 129 40 100 DB_lva

* line arrow options
	global DB_arr=0
	window control check "Arrow" 30 142 30 10 DB_arr left

	global DB_as "100"
	global DB_asm "Arrow Size:"
        window control static       DB_asm  73 144 35 9
        window control edit         110 144 15 10 DB_as

	global DB_aa ".5236"
	global DB_aam "Angle:"
        window control static       DB_aam  133 144 25 9
        window control edit         159 144 17 9 DB_aa


* check boxes for all, keep and clear options and push to window
	global DB_chka=1
	global DB_chkk=0
	global DB_chkc=0
	global DB_chkp=0
	window control check "Draw With Kept" 10 170 60 10 DB_chka
	window control check "Keep This" 90 170 50 10 DB_chkk
	window control check "Clear Kept" 150 170 50 10 DB_chkc
	window control check "Push grnote command into Review Window" 10 180 150 10 DB_chkp


* basic graph and exit buttons
        window control button "GRAPH"      5 195 40 10 DB_gr
        window control button "EXIT"        185 195 40 10 DB_ex

* save file
	global DB_fnm "Save .gph"
	window control static DB_fnm 51 195 34 10
	global DB_fn ""
	window control edit 88 195 75 10 DB_fn	

* actions for buttons
        global DB_gr  "grnotex 0 0 0 0 " 
        global DB_yp  "grnotex 1 0 0 0 " 
        global DB_ym  "grnotex -1 0 0 0 " 
        global DB_xp  "grnotex 0 1 0 0 " 
        global DB_xm  "grnotex 0 -1 0 0" 
        global DB_ypl  "grnotex 0 0 1 0" 
        global DB_yml  "grnotex 0 0 -1 0" 
        global DB_xpl  "grnotex 0 0 0 1 " 
        global DB_xml  "grnotex 0 0 0 -1" 
        global DB_ex "exit 3000"

        cap noisily wdlg "grnotem: Graph Annotation" 10 5 250 230

end


program define grnotex
version 6.0
*based on version 2.1 of standalong grnote by M Blasnik updated 1/26/2001 
args ymove xmove ylmove xlmove

* line start nudge feature not yet incoporated
local ylnudge=0
local xlnudge=0

* default arrow pen to line pen
global DB_ap=$DB_lp

* grab options
local aangle=$DB_aa
if "$DB_tva"=="auto" {local tvalign ""}
else {local tvalign=upper("$DB_tva")}
if "$DB_lva"=="auto" {local lvalign ""}
else {local lvalign=upper("$DB_lva")}
if "$DB_la"=="auto" {local lalign ""}
else {local lalign=upper("$DB_la")}
local align=((index("left  centerright","$DB_ta")-1)/6)-1
local text "$DB_text"

* perform clear if specified, get next global available
if ($DB_chka==1) | ($DB_chkk==1) | ($DB_chkc==1) {
	local i=1
	while "${ATs_`i'}"!="" |  "${ATLs_`i'}"!=""{
		if $DB_chkc==1  {
			global AT_`i'
			global ATs_`i'
			global ATL_`i'
			global ATLs_`i'
			global ATA1_`i'
			global ATA2_`i'
			global ATAs_`i'
			}
		local i=`i'+1
	}
	if $DB_chkk==1 {local j=`i'}
	if $DB_chkk==1 & $DB_chkc==1 {local j=1}
}

* check file name for saving
if "$DB_fn"!="" & "$DB_fn"!="Error - exists" {
		cap confirm new file `"$DB_fn.gph"'
		if _rc==602 {global DB_fn "Error - exists"}
		else {local saving `", saving($DB_fn)"'}
}
gph open `saving'
graph
local ay=_result(5)
local by=_result(6)
local ax=_result(7)
local bx=_result(8)

if `ax'==. | `bx'==. {global DB_chkx=1}

if $DB_chkx==1 {
	local ay=1
	local ax=1
	local by=0
	local bx=0
}
global DB_ty=$DB_ty+($DB_jump*(`ymove')/100)*abs(23062/(`ay'))
global DB_tx=$DB_tx+($DB_jump*(`xmove')/100)*abs(32000/(`ax'))
* move onto edge of graph if coordinates outside
if (`ax'*($DB_tx)+`bx')<0 {global DB_tx=((0-`bx')/`ax')}
if (`ax'*($DB_tx)+`bx')>32000 {global DB_tx=((32000-`bx')/`ax')}
if (`ay'*($DB_ty)+`by')<0 {global DB_ty=((0-`by')/`ay')}
if (`ay'*($DB_ty)+`by')>23062 {global DB_ty=((23062-`by')/`ay')}
local y=max(0,min(`ay'*($DB_ty)+`by',23062))
local x=max(0,min(`ax'*($DB_tx)+`bx',32000))

if $DB_chka==1 {gphold}

* draw text
if "`text'"!="" {
	local fonty=.75*923*$DB_ts/100
	local fontx=.75*444*$DB_ts/100
	gph font `fonty' `fontx'
	gph pen $DB_tp
	local y=`y'+(("`tvalign'"=="CENTER")*.5+("`tvalign'"=="TOP"))*`fonty'
	local y=max(0,min(`y',23062))
	gph text `y' `x' 0 `align' `text'
	if $DB_chkk==1 {
		global AT_`j' "`y' `x' 0 `align' `text'"
		global ATs_`j' "`fonty' `fontx' $DB_tp "
	}
}

* draw line

* if user hit +/- keys on line with none there, default to text position
if "$DB_lx"=="" & (`xlmove'!=0 | `ylmove'!=0) {global DB_lx=$DB_tx}
if "$DB_ly"=="" & (`xlmove'!=0 | `ylmove'!=0) {global DB_ly=$DB_ty}

if "$DB_lx"!="" & "$DB_ly"!="" {

	global DB_ly=$DB_ly+($DB_jump*(`ylmove')/100)*abs(23062/(`ay'))
	global DB_lx=$DB_lx+($DB_jump*(`xlmove')/100)*abs(32000/(`ax'))
	local y2=max(0,min(`ay'*($DB_ly)+`by',23062))
	local x2=max(0,min(`ax'*($DB_lx)+`bx',32000))
	local offsety=0
	local offsetx=0
	local angle=abs((`y2'-`y')/(`x2'-`x'))

	if "`lalign'"=="" {
 		if `angle'<1.3 {
			if `x'>`x2' {local lalign "LEFT"}
			if `x'<`x2' {local lalign "RIGHT"}
		}
		else {local lalign "CENTER"}
	}
	* put a little room between text & line start
	if "`lalign'"=="RIGHT" { local xlnudge=`xlnudge'+`fontx'*.8}
	if "`lalign'"=="LEFT" { local xlnudge=`xlnudge'-`fontx'*.6}

	local xlen=int(length("`text'")*`fontx')
	local offsetx=(-1*`align'/2)+.5*("`lalign'"=="RIGHT")-.5*("`lalign'"=="LEFT")
	local x0=max(0,min(`x'+`xlnudge'+`offsetx'*`xlen',32000))

	if "`lvalign'"=="CENTER" | ("`lvalign'"=="" & `angle'<.3) {
		local offsety=-.5*`fonty'
	}
	else {
		if "`lvalign'"=="BOTTOM" | ("`lvalign'"=="" & `y'<`y2') {
			local offsety=100
		}
		if "`lvalign'"=="TOP" | ("`lvalign'"=="" & `y'>`y2') {
			local offsety=-100-`fonty'
		}
	}
	local y0=max(0,min(`y'+`ylnudge'+`offsety',23062))

	gph pen $DB_lp
	gph line `y0' `x0' `y2' `x2'
	if $DB_chkk==1 {
		global ATL_`j' "`y0' `x0' `y2' `x2'"
		global ATLs_`j' "$DB_lp"
	}

	if $DB_arr {
		gph pen $DB_ap
		local slope=atan((`y2'-`y0')/(`x2'-`x0'))
		if `slope'==. {local slope=sign(`y2'-`y0')*1.5708}
		local alen=600*$DB_as/100
		local op=cond(`x2'<`x0',"+","-")
		local xa1=`x2' `op' `alen'*cos(`slope'+$DB_aa)
		local ya1=`y2' `op' `alen'*sin(`slope'+$DB_aa)
		local ya1=max(0,min(`ya1',23062))
		local xa1=max(0,min(`xa1',32000))
		local xa2=`x2' `op' `alen'*cos(`slope'-$DB_aa)
		local ya2=`y2' `op' `alen'*sin(`slope'-$DB_aa)
		local ya2=max(0,min(`ya2',23062))
		local xa2=max(0,min(`xa2',32000))
		gph line `y2' `x2' `ya1' `xa1'
		gph line `y2' `x2' `ya2' `xa2'

		if $DB_chkk {
			global ATA1_`j' "`y2' `x2' `ya1' `xa1'"
			global ATA2_`j' "`y2' `x2' `ya2' `xa2'"
			global ATAs_`j' "$DB_ap"
		}
	}
}
* assemble command and push into review window if checked
if $DB_chkp==1 {
	local ty: di %8.0g $DB_ty
	local tx: di %8.0g $DB_tx
	if "$DB_text"!="" {local opt "text($DB_text) "}
	if $DB_chkk==1 {local opt "`opt'keep "}
	if $DB_chka==1 {local opt "`opt'all "}
	if $DB_chkc==1 {local opt "`opt'clear "}
	if $DB_chkx==1 {local opt "`opt'pixel "}
	if "$DB_lx"!="" & "$DB_ly"!="" {
		local lx2: di %8.0g $DB_lx
		local ly2: di %8.0g $DB_ly
		local lopt "x2(`lx2') y2(`ly2') lpen($DB_lp)"
		if "`lvalign'"!="" {local lopt "`lopt'  lvalign(`lvalign')"}
		if "`lalign'"!="" {local lopt "`lopt' lalign(`lalign')"}
		if $DB_arr {local lopt "`lopt' arrow asize($DB_as) apen($DB_ap) aangle($DB_aa)"}
	}
	window push grnote , `opt' y(`ty') x(`tx') `lopt' 
}

* uncheck the keep and clear options after they are used
if $DB_chkk==1 {global DB_chkk=0}
if $DB_chkc==1 {global DB_chkc=0}

gph close
end



program define gphold
local i=1
while "${ATs_`i'}${ATLs_`i'}"!="" {
		if "${AT_`i'}"!="" {
			tokenize ${ATs_`i'}
			gph font `1' `2'
			gph pen `3'
			gph text ${AT_`i'}
		}
		if "${ATL_`i'}"!="" {
			gph pen ${ATLs_`i'}
			if "${ATL_`i'}"!="" {gph line ${ATL_`i'} }
			if "${ATA1_`i'}"!="" {
				gph pen ${ATAs_`i'}
				gph line ${ATA1_`i'} 
				gph line ${ATA2_`i'}
			} 
		}
		local i=`i'+1
	}
end

	
