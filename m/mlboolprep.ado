/* call -- myprog (n) ( (path1 AND path2)OR(path3 AND path4) )  (y) (path1) (path2) (path3) (path4)  */
capture program drop mlboolprep
program define mlboolprep
version 8
global keys = ""
local n = `1'
global n = `n'
foreach i of numlist 1000 0 1001 1/`n' {
   gettoken path`i' 0 : 0, match(holder)
   }
global depjmk "`path1001'"  
local key "`path0'"	/* from key, choose functional form from archive */

/* finding the key */

local key = lower(subinstr("`key'"," ","",.))

global sstring "start"
forvalues i = 1/`n' {
   global sstring = subinstr("$sstring","start","theta`i' start",.)
   }
global sstring = subinstr("$sstring"," start","",.)

local s1 aandb
local match1 ps1*ps2
local s2 aorb
local match2 (1-(1-ps1)*(1-ps2))
local s3 aandbandc
local match3 ps1*ps2*ps3
local s4 aorborc
local match4 (1-(1-ps1)*(1-ps2)*(1-ps3))
local s5 (aandb)orc
local match5 (1-(1-(ps1*ps2))*(1-ps3))
local s6 aand(borc)
local match6 ps1*(1-(1-ps2)*(1-ps3)) 
local s7 (aorb)andc
local match7 ps3*(1-(1-ps2)*(1-ps1))
local s8 aor(bandc)
local match8 (1-(1-(ps3*ps2))*(1-ps1))
local s9 aand((bandc)ord)
local match9 ps1*(1-(1-ps2*ps3)*(1-ps4))
local s10 aandbandcandd
local match10 ps1*ps2*ps3*ps4
local s11 aandband(cord)
local match11 ps1*ps2*(1-(1-ps3)*(1-ps4))
local s12 (aandbandc)ord
local match12 1-(1-ps1*ps2*ps3)*(1-ps4)
local s13 aand(borc)andd
local match13 ps1*(1-(1-ps2)*(1-ps3))*ps4
local s14 (aandb)or(candd)
local match14 1-(1-ps1*ps2)*(1-ps3*ps4)
local s15 aand(bor(candd))
local match15 ps1*(1-(1-ps3*ps4)*(1-ps2))
local s16 ((aandb)orc)andd
local match16 (1-(1-ps1*ps2)*(1-ps3))*ps4
local s17 aand(borcord)
local match17 ps1*(1-(1-ps2)*(1-ps3)*(1-ps4))
local s18 (aandb)orcord
local match18 1-(1-ps1*ps2)*(1-ps3)*(1-ps4)
local s19 (aorb)andcandd
local match19 (1-(1-ps1)*(1-ps2))*ps3*ps4
local s20 (aor(bandc))andd
local match20 (1-(1-ps2*ps3)*(1-ps1))*ps4
local s21 aor(bandcandd)
local match21 1-(1-ps1)*(1-ps2*ps3*ps4)
local s22 (aorborc)andd
local match22 (1-(1-ps1)*(1-ps2)*(1-ps3))*ps4
local s23 aor((borc)andd)
local match23 1-(1-(1-(1-ps2)*(1-ps3))*ps4)*(1-ps1)
local s24 aorbor(candd)
local match24 1-(1-ps1)*(1-ps2)*(1-ps3*ps4)
local s25 ((aorb)andc)ord
local match25 (1-(1-(1-(1-ps1)*(1-ps2))*ps3)*(1-ps4))
local s26 aor(bandc)ord
local match26 1-(1-ps1)*(1-ps2*ps3)*(1-ps4)
local s27 aor(band(cord))
local match27 1-(1-(1-(1-ps3)*(1-ps4))*ps2)*(1-ps1)
local s28 aorborcord
local match28 (1-(1-ps1)*(1-ps2)*(1-ps3)*(1-ps4))
local s29 aandbandcanddande
local match29 ps1*ps2*ps3*ps4*ps5
local s30 aandbandcand(dore)
local match30 (1-(1-ps4)*(1-ps5))*ps1*ps2*ps3 
local s31 aandband((candd)ore)
local match31 (1-(1-ps4*ps3)*(1-ps5))*ps1*ps2*ps3
local s32 aand((bandcandd)ore)
local match32 (1-(1-ps2*ps3*ps4)*(1-ps5))*ps1
local s33 (aandbandcandd)ore
local match33 (1-(1-ps1*ps2*ps3*ps4)*(1-ps5))
local s34 aandband(cord)ande
local match34 (1-(1-ps3)*(1-ps4))*ps1*ps2*ps5
local s35 aandband(cor(dande))
local match35 (1-(1-ps3)*(1-ps4*ps5))*ps1*ps2
local s36 aand((bandc)or(dande))
local match36 (1-(1-ps2*ps3)*(1-ps3*ps4))*ps1
local s37 (aandbandc)or(dande)
local match37 (1-(1-ps1*ps2*ps3)*(1-ps4*ps5))
local s38 ((aandbandc)ord)ande
local match38 (1-(1-ps4)*(1-ps1*ps2*ps3))*ps5
local s39 aand((bandc)ord)ande
local match39 ps1*(1-(1-ps2*ps3)*(1-ps4))*ps5
local s40 (aandbandc)ordore
local match40 (1-(1-ps1*ps2*ps3)*(1-ps4)*(1-ps5))
local s41 aandband(cordore)
local match41 (1-(1-ps3)*(1-ps4)*(1-ps5))*ps1*ps2
local s42 aand((band(cord))ore)
local match42 (1-(1-(1-(1-ps3)*(1-ps4))*ps2)*(1-ps5))*ps1
local s43 (aandband(cord))ore
local match43 (1-(1-(1-(1-ps3)*(1-ps4))*ps1*ps2)*(1-ps5))
local s44 (aand((bandc)ord))ore
local match44 (1-(1-(1-(1-ps2*ps3)*(1-ps4))*ps1)*(1-ps5)
local s45 aand((bandc)ordore)
local match45 (1-(1-ps2*ps3)*(1-ps4)*(1-ps5))*ps1
local s46 ((aandb)orc)anddande
local match46 (1-(1-ps3)*(1-ps1*ps2))*ps4*ps5
local match47 = 0
local s47 = 0
local s48 aand(borc)anddande
local match48 (1-(1-ps2)*(1-ps3))*ps1*ps4*ps5
local s49 aand(bor(candd))ande
local match49 (1-(1-ps2)*(1-ps3*ps4))*ps1*ps5
local s50 aand(bor(canddande))
local match50 (1-(1-ps2)*(1-ps3*ps4*ps5))*ps1
local s51 (aandb)or(canddande)
local match51 (1-(1-ps1*ps2)*(1-ps3*ps4*ps5))
local s52 ((aandb)or(candd))ande
local match52 (1-(1-ps1*ps2)*(1-ps3*ps4))*ps5
local s53 ((aandb)orcord)ande
local match53 (1-(1-ps3)*(1-ps4)*(1-ps1*ps2))*ps5
local s54 (aandb)orcor(dande)
local match54 (1-(1-ps1*ps2)*(1-ps3)*(1-ps4*ps5))
local s55 (aandb)or((cord)ande)
local match55 (1-(1-(1-(1-ps3)*(1-ps4))*ps5)*(1-ps1*ps2))
local s56 aand(borcord)ande
local match56 (1-(1-ps2)*(1-ps3)*(1-ps4))*ps1*ps5
local s57 ((aand(borc))ord)ande
local match57 (1-(1-(1-(1-ps3)*(1-ps2))*ps1)*(1-ps4))*ps5
local s58 (aand(borc))or(dande)
local match58 (1-(1-(1-(1-ps2)*(1-ps3))*ps1)*(ps4*ps5))
local s59 aand(bor((cord)ande))
local match59 (1-(1-(1-(1-ps3)*(1-ps4))*ps5)*(1-ps2))*ps1
local s60 (aandb)or((cord)ande)
local match60 (1-(1-(1-(1-ps3)*(1-ps4))*ps5)*(1-ps1*ps2))
local s61 aand(borcor(dande))
local match61 (1-(1-ps2)*(1-ps3)*(1-ps4*ps5))*ps1
local s62 (((aandb)orc)andd)ore
local match62 (1-(1-(1-(1-ps3)*(1-ps1*ps2))*ps4)*(1-ps5))
local s63 (aandb)or(candd)ore
local match63 (1-(1-(1-(1-ps1*ps2)*(1-ps3*ps4)))*(1-ps5))
local s64 ((aandb)orc)and(dore)
local match64 (1-(1-ps3)*(1-ps1*ps2))*(1-(1-ps4)*(1-ps5))
local s65 (aand(borc)andd)ore
local match65 (1-(1-(1-(1-ps2)*(1-ps3))*ps1*ps4)*(1-ps5))
local s66 aand(((borc)andd)ore)
local match66 (1-(1-(1-(1-ps2)*(1-ps3))*ps4)*(1-ps5))*ps1
local s67 (aand(borc))and(dore)
local match67 (1-(1-ps2)*(1-ps3))*ps1*(1-(1-ps4)*(1-ps5))
local s68 aand(borc)and(dore)
local match68 (1-(1-ps2)*(1-ps3))*(1-(1-ps4)*(1-ps5))*ps1
local s69 aand(bor(candd)ore)
local match69 (1-(1-ps3*ps4)*(1-ps2)*(1-ps5))*ps1 
local s70 (aandb)or((candd)ore)
local match70 (1-(1-(1-(1-ps5)*(1-ps3*ps4)))*(1-ps1*ps2))
local s71 aand(bor(candd)ore)
local match71 (1-(1-ps2)*(1-ps5)*(1-ps3*ps4))*ps1
local s72 (aand(bor(candd)))ore
local match72 (1-(1-(1-(1-ps2)*(1-ps3*ps4))*ps1)*(1-ps5))
local s73 aand(bor(cand(dore)))
local match73 (1-(1-(1-(1-ps4)*(1-ps5))*ps3)*(1-ps2))*ps1
local s74 (aandb)or(cand(dore))
local match74 (1-(1-(1-(1-ps4)*(1-ps5))*ps3)*(1-ps1*ps2))
local s75 aand(borcordore)
local match75 (1-(1-ps2)*(1-ps3)*(1-ps4)*(1-ps5))*ps1
local s76 (aand(borc))ordore
local match76 (1-(1-(1-(1-ps2)*(1-ps3))*ps1)*(1-ps4)*(1-ps5))
local s77 (aandb)orcordore
local match77 (1-(1-ps1*ps2)*(1-ps3)*(1-ps4)*(1-ps5))
local s78 (aand(borcord))ore
local match78 (1-(1-(1-(1-ps2)*(1-ps3)*(1-ps4))*ps1)*(1-ps5))
local s79 (aorb)andcanddande
local match79 (1-(1-ps1)*(1-ps2))*ps2*ps3*ps4*ps5
local s80 aor(bandcanddande)
local match80 (1-(1-ps1)*(1-ps2*ps3*ps4*ps5))
local s81 (aor(bandc))anddande
local match81 (1-(1-ps1)*(1-ps2*ps3))*ps4*ps5
local s82 (aor(bandcandd))ande
local match82 (1-(1-ps1)*(1-ps2*ps3*ps4))*ps5
local s83 ((aorb)andcandd)ore
local match83 (1-(1-(1-(1-ps1)*(1-ps2))*ps3*ps4)*(1-ps5))
local s84 (aorb)andcand(dore)
local match84 (1-(1-ps1)*(1-ps2))*ps3*(1-(1-ps4)*(1-ps5))
local s85 (aorb)and((candd)ore)
local match85 (1-(1-ps5)*(1-ps3*ps4))*(1-(1-ps1)*(1-ps2))
local s86 aor(bandcandd)ore
local match86 (1-(1-ps1)*(1-ps2*ps3*ps4)*(1-ps5))
local s87 ((aor(bandc))andd)ore
local match87 (1-(1-(1-(1-ps2*ps3)*(1-ps1))*ps4)*(1-ps5))
local s88 (aor(bandc))and(dore)
local match88 (1-(1-ps1)*(1-ps2*ps3))*(1-(1-ps4)*(1-ps5))
local s89 aor(band((candd)ore))
local match89 (1-(1-(1-(1-ps5)*(1-ps4*ps3))*ps2)*(1-ps1))
local s90 (aorb)and((candd)ore)
local match90 (1-(1-ps3*ps4)*(1-ps5))*(1-(1-ps1)*(1-ps2))
local s91 aor(bandcand(dore))
local match91 (1-(1-(1-(1-ps4)*(1-ps5))*ps3*ps2)*(1-ps1))
local s92 (((aorb)andc)ord)ande
local match92 (1-(1-(1-(1-ps1)*(1-ps2))*ps3)*(1-ps4))*ps5
local s93 (aorb)and(cord)ande
local match93 (1-(1-ps1)*(1-ps2))*(1-(1-ps3)*(1-ps4))*ps5
local s94 ((aorb)andc)or(dande)
local match94 (1-(1-(1-(1-ps1)*(1-ps2))*ps3)*(1-ps4*ps5))
local s95 (aor(bandc)ord)ande
local match95 (1-(1-ps1)*(1-ps2*ps3)*(1-ps4))*ps5
local s96 aor(((bandc)ord)ande)
local match96 (1-(1-(1-(1-ps4)*(1-ps2*ps3))*ps5)*(1-ps1))
local s97 (aor(bandc))or(dande)
local match97 (1-(1-(1-(1-ps1)*(1-ps2*ps3)))*(1-ps4*ps5))
local s98 aor(bandc)or(dande)
local match99 (1-(1-ps1)*(1-ps2*ps3)*(1-ps4*ps5))
local s100 aor(band(cord)ande)
local match101 (1-(1-(1-(1-ps3)*(1-ps4))*ps2*ps5)*(1-ps1))
local s102 (aorb)and(cord)ande
local match102 (1-(1-ps3)*(1-ps4))*ps5*(1-(1-ps1)*(1-ps2))
local s103 aor(band(cord)ande)
local match103 (1-(1-(1-(1-ps3)*(1-ps4))*ps2*ps5)*(1-ps1))
local s104 (aor(band(cord)))ande
local match104 (1-(1-(1-(1-ps3)*(1-ps4))*ps2)*(1-ps1))*ps5
local s105 (aorb)and(cor(dande))
local match105 (1-(1-ps1)*(1-ps2))*(1-(1-ps3)*(1-ps4*ps5))
local s106 aor(band(cor(dande)))
local match106 (1-(1-(1-(1-ps3)*(1-ps4*ps5))*ps2)*(1-ps1))
local s107 ((aorb)andc)ordore
local match107 (1-(1-(1-(1-ps1)*(1-ps2))*ps3)*(1-ps4)*(1-ps5))
local s108 aor(bandc)ordore
local match108 (1-(1-ps1)*(1-ps2*ps3)*(1-ps4)*(1-ps5))
local s109 aor(band(cord))ore
local match109 (1-(1-(1-(1-ps3)*(1-ps4))*ps2)*(1-ps1)*(1-ps5))
local s110 aor(band(cordore))
local match110 (1-(1-(1-(1-ps3)*(1-ps4)*(1-ps5))*ps2)*(1-ps1))
local s111 (aorb)and(cordore)
local match111 (1-(1-ps1)*(1-ps2))*(1-(1-ps3)*(1-ps4)*(1-ps5))
local s112 ((aorb)and(cord))ore
local match112 (1-(1-(1-(1-ps1)*(1-ps2))*(1-(1-ps3)*(1-ps4)))*(1-ps5))
local s113 (aorborc)anddande
local match113  (1-(1-ps1)*(1-ps2)*(1-ps3))*ps4*ps5
local s114 aorbor(canddande)
local match114 (1-(1-ps1)*(1-ps2)*(1-ps3*ps4*ps5))
local s115 aor((bor(candd))ande)
local match115 (1-(1-(1-(1-ps2)*(1-ps3*ps4))*ps5)*(1-ps1))
local s116 (aorbor(candd))ande
local match116 (1-(1-ps1)*(1-ps2)*(1-ps3*ps4))*ps5
local s117 (aor((borc)andd))ande
local match117  (1-(1-(1-(1-ps2)*(1-ps3))*ps4)*(1-ps1))*ps5
local s118 aor((borc)anddande)
local match118 (1-(1-(1-(1-ps2)*(1-ps3))*ps4*ps5)*(1-ps1))
local s119 aorbor(candd)ore 
local match119 (1-(1-ps1)*(1-ps2)*(1-ps3*ps4)*(1-ps5))
local s120 aorbor(cand(dore))
local match120 (1-(1-(1-(1-ps4)*(1-ps5))*ps3)*(1-ps1)*(1-ps2))
local s121 aor((borc)and(dore))
local match121 (1-(1-((1-(1-ps2)*(1-ps3))*(1-(1-ps4)*(1-ps5))))*(1-ps1))
local s122 (aorborc)and(dore)
local match122 (1-(1-ps1)*(1-ps2)*(1-ps3))*(1-(1-ps4)*(1-ps5))
local s123 ((aorborc)andd)ore
local match123 (1-(1-(1-(1-ps1)*(1-ps2)*(1-ps3))*ps4)*(1-ps5))
local s124 aor((borc)andd)ore
local match124 (1-(1-(1-(1-ps2)*(1-ps3))*ps4)*(1-ps1)*(1-ps5))
local s125 aorborcor(dande)
local match125 (1-(1-ps1)*(1-ps2)*(1-ps3)*(1-ps4*ps5))
local s126 aorbor((cord)ande)
local match126 (1-(1-(1-(1-ps3)*(1-ps4))*ps5)*(1-ps1)*(1-ps2))
local s127 aor((borcord)ande)
local match127 (1-(1-(1-(1-ps2)*(1-ps3)*(1-ps4))*ps5)*(1-ps1))
local s128 (aorborcord)ande
local match128 (1-(1-ps1)*(1-ps2)*(1-ps3)*(1-ps4))*ps5
local s129 aorborcordore
local match129 (1-(1-ps1)*(1-ps2)*(1-ps3)*(1-ps4)*(1-ps5))
local s130 (aorb)and(cord)
local match130 (1-(1-ps1)*(1-ps2))*(1-(1-ps3)*(1-ps4))

forvalues i = 1/130 {
	if match("`key'","`s`i''") {
        global codek = `i'
		global keys = "`match`i''"
        }
    } 

if "$keys" == "" {
   di in red "Incorrect logical form entered"
   di in red "Check for superfluous parentheses"
   exit(198)
   }
forvalues i = 1/$n {
   global jpath`i' = "`path`i''"
   }
forvalues i = 2/$n {
   local mlpart`i' = "(Path`i': `path`i'')"
   }

global mlline "(Path1: `path1001' = `path1')"
global mlpart1 "$mlline"
global mlpart2 "`mlpart2'"
global mlpart3 "`mlpart3'"
global mlpart4 "`mlpart4'"
global mlpart5 "`mlpart5'"

forvalues i = 2/$n {
   global mlline = subinstr("$mlline",")"," (`mlpart`i'')",1)
   }

global mlline = subinstr("$mlline"," (",") (",.)

end

