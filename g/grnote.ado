program define grnote
version 6.0
*! version 2.2 by Michael Blasnik updated 1/31/2001 , still version 6
syntax , [Text(str) Y(real 0) X(real 0) X2(real -999) Y2(real -999) /*
*/ TSize(int 100) TALign(str) TVAlign(str) TPen(int 1) XLNudge(int 0) /*
*/ YLNudge(int 0) LALign(str) LVAlign(str) LPen(int 3)  ARRow /*
*/ ASize(int 100) AANGle(real .5236) APen(int 0) SAVing(str) /*
*/ KEEP CLEAR ALL PIXel] 

* parse alignment options
chkopt `talign' , vals(RIGHT CENTER LEFT) optis(talign) err
local align=cond(`r(optnum)'==0,0,2-`r(optnum)')
chkopt `lalign' , vals(RIGHT CENTER LEFT) optis(lalign) err
local lalign "`r(optname)'"
chkopt `tvalign' , vals(TOP BOTTOM CENTER) optis(tvalign) err
local tvalign "`r(optname)'"
chkopt `lvalign' , vals(TOP BOTTOM CENTER) optis(lvalign) err
local lvalign "`r(optname)'"

* check and fix if sizes specified as fractions
if `tsize'>0 & `tsize'<1 {local tsize=`tsize'*100}
if `asize'>0 & `asize'<1 {local asize=`asize'*100}

* perform clear if specified, get next global available
if "`clear'`keep'`all'"!="" {
	local i=1
	while "${AT_`i'}" !="" {
		if "`clear'"!="" {
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
	if "`keep'`all'"!="" {local j=`i'}
	if "`keep'"!="" & "`clear'"!="" {local j=1}
}
if "`saving'"!="" {local saving `", saving(`saving')"'}
gph open `saving'
graph
local ay=_result(5)
local by=_result(6)
local ax=_result(7)
local bx=_result(8)

if "`pixel'"!="" {
	local ay=1
	local ax=1
	local by=0
	local bx=0
}

if "`all'"!="" {gphold}

local y=max(0,min(`ay'*`y'+`by',23062))
local x=max(0,min(`ax'*`x'+`bx',32000))

* draw text
if "`text'"!="" {
	local fonty=.75*923*`tsize'/100
	local fontx=.75*444*`tsize'/100
	gph font `fonty' `fontx'
	gph pen `tpen'
	local y=`y'+(("`tvalign'"=="CENTER")*.5+("`tvalign'"=="TOP"))*`fonty'
	local y=max(0,min(`y',23062))
	gph text `y' `x' 0 `align' `text'
	if "`keep'"!="" {
		global AT_`j' "`y' `x' 0 `align' `text'"
		global ATs_`j' "`fonty' `fontx' `tpen' "
	}
}

* draw line
if `x2'!=-999 | `y2'!=-999 {

	if `x2'==-999 {local x2=`x'}
	if `y2'==-999 {local y2=`y'}
	local y2=max(0,min(`ay'*`y2'+`by',23062))
	local x2=max(0,min(`ax'*`x2'+`bx',32000))
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
	if "`lalign'"=="RIGHT" { local xlnudge=`xlnudge'+200}
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

	gph pen `lpen'
	gph line `y0' `x0' `y2' `x2'
	if "`keep'"!="" {
		global ATL_`j' "`y0' `x0' `y2' `x2'"
		global ATLs_`j' "`lpen'"
	}

	if "`arrow'"!="" {
		if `apen'==0 {local apen=`lpen'}
		gph pen `apen'
		local slope=atan((`y2'-`y0')/(`x2'-`x0'))
		if `slope'==. {local slope=sign(`y2'-`y0')*1.5708}
		local alen=600*`asize'/100
		local op=cond(`x2'<`x0',"+","-")
		local xa1=`x2' `op' `alen'*cos(`slope'+`aangle')
		local ya1=`y2' `op' `alen'*sin(`slope'+`aangle')
		local ya1=max(0,min(`ya1',23062))
		local xa1=max(0,min(`xa1',32000))
		local xa2=`x2' `op' `alen'*cos(`slope'-`aangle')
		local ya2=`y2' `op' `alen'*sin(`slope'-`aangle')
		local ya2=max(0,min(`ya2',23062))
		local xa2=max(0,min(`xa2',32000))
		gph line `y2' `x2' `ya1' `xa1'
		gph line `y2' `x2' `ya2' `xa2'

		if "`keep'"!="" {
			global ATA1_`j' "`y2' `x2' `ya1' `xa1'"
			global ATA2_`j' "`y2' `x2' `ya2' `xa2'"
			global ATAs_`j' "`apen'"
		}
	}

}
gph close
end



program define gphold
local i=1
while "${AT_`i'}${ATL_`i'}"!="" {
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


program define chkopt, rclass
gettoken opt 0 : 0 , parse(" ,")
if "`opt'"=="," {local 0 ", `0'"}
syntax , vals(string) [optis(str) err]
if "`opt'"=="," {local result=0}
else {
	local opt=upper("`opt'")
	local result=-1
	tokenize `vals'
	local i=1
	while "``i''"!="" {
		if index("``i''","`opt'")==1 {
				local result=`i'
				local name "``i''"
		}
		local i=`i'+1
	}
	if "`err'"!="" & `result'==-1 {
			di in red "`optis' must be one of the following: `vals'"
			error 198
		}
}
return local optnum=`result'
return local optname `name'
end

