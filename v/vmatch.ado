*! version 2.0.0 , GvM, 25aug97
*
prog def vmatch
  version 5.0
/* 
- -- keep # vars used in S_4, original _N in S_5
    will store vars used in temp `vars'
    must make sure # vars does not exceed _N
- -- convention for option distances: 
    absolute dist are stored as positive, relative dist as negative
*/
  tempvar seq vars wV dVL dVH who touse ok dv dd fst Mfor
  g  long `seq'=_n
  loc srt : sortedby
  glo S_4= 0
  glo S_5=_N
  loc j=int(log10(_N)+1e-6)+2
  format `seq' %`j'.0f
  loc fm3 %3.0f
  loc fm6 %6.0f
  loc dib di in blu
  loc dir di in red

  loc  S (string)
  loc XD Devia`S'
  loc XE Eucli`S'
  loc XO Outof`S'
  loc XS Strng`S'      /* will also allow matching of string vars */
  loc XP Power(real 2) /* minkovski p:  
	 d = { sum_i(x_i^p) }^(1/p); if p=0-->use ln */
  loc xD devia
  loc xE eucli
  loc xO outof
  loc xS strng

* preliminary parsing and checking
*---------------------------------
  loc varlist "req ex min(1) max(1)"
  loc if      "opt"
  #delimit ;
  loc options
    "Generate`S' show`S' save`S' fuzz(real 1e-6) First
    `XD'  R`XD'  `XE'  R`XE'  `XO'  `XS' `XP'";
  #delimit cr

  parse  "`*'"
  parse  "`varlist'", parse(" ")
  if "`generate'"=="" {
    `dir' "need to specify a new var to store number of matches"
    `dir' "see option <generate>"
    error 198
  }
  loc  pow `power'
 di in blu "power `pow'"
  confirm new var `generate'
  loc tbM `1'
  loc nbM `generate'
  qui {
   g      `nbM' =0
   g str8 `vars'=""        /* a temp containing all vars used  */
   g str8 `wV'  =""        /* a temp containing vars in an opt */
   g      `dVL' =0         /* a temp containing deviations Lo  */
   g      `dVH' =0         /* a temp containing deviations Hi  */
  }
  loc locs "`vars' `wV' `dVL' `dVH'"

*-- construct `devi' to contain `nD' triplets: { var, LoDev, HiDev }
*-- all LoDevs and HiDevs stored  +/- for abs/rel (see convention at top)
*
  niOpt           `locs'
  rdOpt  "``xD''" `locs'  "D"
  rdOpt "`r`xD''" `locs' "RD"
  loc j 0
  while `j'< $S_3 {
    loc j=`j'+1
    loc x : word 2 of `locs'
    loc v =`x'[`j']
    loc x : word 3 of `locs'
    loc L : display `x'[`j']
    loc x : word 4 of `locs'
    loc H : display `x'[`j']
    loc devi `devi' `v' `L' `H'
  }
    loc nD = $S_3

*-- construct `eucl' to contain `nE' tuplets: { dist, #vars, theVars }
*-- all dist stored as +/- for abs/rel distance
*
  niOpt           `locs'
  rdOpt  "``xE''" `locs'  "E"
  loc eucl $S_1
  loc nE = $S_6
  rdOpt "`r`xE''" `locs' "RE"
  loc eucl `eucl' $S_1
  loc nE = `nE' + $S_6

*-- construct `outo' to contain `nO' tuplets: { req#, outof#, theVars }
*
  niOpt            `locs'
  rdOpt   "``xO''" `locs'  "O"
  loc outo $S_1
  loc nO = $S_6

*-- construct `strn' to contain `nS' string vars
*
  niOpt            `locs'
  rdOpt   "``xS''" `locs'  "S"
  loc strn $S_1
  loc nS : word count $S_1

*---------------
  if !($S_4+`nS') {
   `dir' "need at least one condition for matching"
   error 198
  }
  loc nV $S_4
  loc j 0
  while `j'< `nV' {
   loc j=`j'+1
   loc v=`vars'[`j']
   loc varli `varli' `v'
   loc j0=substr(string(100+`j'),2,2)
   loc fm`j0' : format `v'
   if "`show'"!="" {
    qui su `v'
    loc mi=abs(_result(5))
    loc ma=abs(_result(6))
    loc len=int(abs(log10( max(`mi',`ma')+(`mi'+`ma'==0) )))+3
    loc len=max(`len',max(length("`v'"),4))
    format `v' %`len'.0g
    loc fv: format `v'
   }
  }
*-- parsing options produced this --
  `dib' `fm3' `nD' " `xD' : `devi'."
  `dib' `fm3' `nE' " `xE' : `eucl'."
  `dib' `fm3' `nO' " `xO' : `outo'."
  `dib' `fm3' `nS' " `xS' : `strn'."
  `dib' `fm3' `nV' " Vars : `varli'"

  qui if _N> $S_5 {
    loc k =  $S_5+1
    drop in `k'/l
  }
  if "`show'"!="" {
    loc id `show'
    confirm var `id'
  }
  else { loc id `seq' }

   loc fid: format `id'
   loc tid: type   `id'
   loc idsstr= substr("`tid'",1,3)=="str"
   if `idsstr' { qui g `tid' `Mfor'="" }
   else        { qui g `tid' `Mfor'= . }
   format `Mfor' `fid'
   loc ftb: format `tbM'
   format `tbM' %3.0f
   format `nbM' %3.0f

  if "`show'"=="" & "`save'"!="" {
   `dib' "for identification obs are numbered/*
*/ sequentially in the present ordering"
  }
  qui {
    mark    `touse'   `if'
    markout `touse'   `varli'
    replace `touse'=0  if  `tbM'==1   /* cases are not acceptable matches  */
    count if `touse'
    loc r=_result(1)
  }
  di in ye `fm6' `r' " eligible records"
  if `r'==0 {
   `dir' "oops, oops"
    exit
  }
  if "`save'"!="" {
    loc dt=index("`save'",".")
    if `dt'==0 { loc save "`save'.dta" }
    loc rep
    capt confirm file `save'
    if _rc==0 { loc rep ", replace" }
    tempfile  fi1 fi2
  }
*
* match one by one
*------------------
 qui {
   g `who' =2-(`tbM'==1)
   g  `ok' =.
   g  `dv' =.
   g  `dd' =.
   g `fst' =.
   sort   `who' `seq'            /* sort tbMa (cases) before others */
   loc L=0
   while `who'[`L'+1]==1 {
     loc L=`L'+1
     loc case= `id'[`L']
     loc qase=`seq'[`L']
     replace  `ok'=`touse'
     count if `ok'
     loc cok=_result(1)
*---------------------------- devi
     if `cok' {
       loc wct : word count  `devi'
       loc m=0
       while (`m'<`wct') & `cok' {
         loc m =`m'+1
         loc v : word `m' of `devi'
         loc m =`m'+1
         loc dL: word `m' of `devi'
         loc m =`m'+1
         loc dH: word `m' of `devi'
         loc vk= `v'[`L']
         replace `dv'= `v'-`vk'
         if `dL'+`dH' < 0 {
           replace `dv'=100*`dv'/max(`vk',`fuzz')
           replace `ok'= `dv'< (-`dH'+`fuzz') & `dv'>  (`dL'-`fuzz') if `ok'
         }
         else {
           replace `ok'= `dv'< ( `dH'+`fuzz') & `dv'> -(`dL'+`fuzz') if `ok'
         }
         count if `ok'
         loc cok=_result(1)
       }
     }
*---------------------------- eucl
     if `cok' {
       loc wct : word count  `eucl'
       loc m=0
       while (`m'<`wct') & `cok' {
         loc m =`m'+1
         loc d : word `m' of `eucl'
         loc m =`m'+1
         loc o : word `m' of `eucl'
         replace `dd'=0
         loc j 0
         while `j'<`o' {
           loc j =`j'+1
           loc m =`m'+1
           loc v: word `m' of `eucl'
           loc vk= `v'[`L']
           replace `dv'= abs(`v'-`vk')
           if `d' < 0 {
             su `v' if `touse'
             replace `dv'=`dv'/max(sqrt(_result(4)),`fuzz')
           }
           if `pow'<=0 { replace `dv'=max(`dv',`fuzz') if `ok' }
           if `pow'==0 { replace `dd'=`dd' + ln(`dv')  if `ok' }
           else        { replace `dd'=`dd' +`dv'^`pow' if `ok' }
         }
         replace `dd'=cond(`pow'==0, exp(`dd'), `dd'^(1/`pow')) if `ok'
         replace `ok'=`dd'< (abs(`d')+`fuzz') if `ok'
         count if `ok'
         loc cok=_result(1)
       }
     }
*---------------------------- outo
     if `cok' {
       loc wct : word count  `outo'
       loc m=0
       while (`m'<`wct') & `cok' {
         loc m =`m'+1
         loc d : word `m' of `outo'
         loc m =`m'+1
         loc o : word `m' of `outo'
         replace `dv'=0
         loc j 0
         while `j'<`o' {
          loc j =`j'+1
          loc m =`m'+1
          loc v: word `m' of `outo'
          loc vk= `v'[`L']
          replace `dv'=`dv'+ (abs(`v'-`vk')<`fuzz') if `ok'
         }
         replace `ok'=(`dv'>=`d') if `ok'
         count if `ok'
         loc cok=_result(1)
       }
     }
*---------------------------- strn
     if `cok' {
       loc wct : word count  `strn'
       loc m=0
       while (`m'<`wct') & `cok' {
         loc m =`m'+1
         loc v : word `m' of `strn'
         loc vk= `v'[`L']
         replace `ok'= `v'=="`vk'" if `ok'
         count if `ok'
         loc cok=_result(1)
       }
     }
* --------------------------------------

     replace `nbM' =`cok'  in `L'
     replace `nbM' =`nbM'+`ok' if `touse'
     if `idsstr' {
       replace `fst' = `qase'  if `ok' & `fst'==.
       replace `Mfor'="`case'" if `ok'
     }
     else        {
       replace `fst' = `case' if `ok' & `fst'==.
       replace `Mfor'= `case' if `ok'
     }
     replace `ok'=1 in `L'
     loc wholi `tbM' `nbM' `varli' `strn'
     if "`show'"!="" {
       noi li  `id' `wholi' if `ok', nod noob
     }
     if "`save'"!="" {
       outfile  `id' `Mfor' `wholi' if `ok' using `fi1', replace nol
       preserve
        if `idsstr' {
         infile `tid' id `tid' Mfor tbM nbM `varli' `strn' using `fi1', clear
        }
        else {
         infile id  Mfor tbM nbM `varli' `strn' using `fi1', clear
        }
        if `L'==1 {
          save `save'`rep'
        }
        else {
          qui save `fi2', replace
          use `save'
          append using `fi2'
          save `save', replace
        }
       restore
     }
   }
 }
 loc sep di in gr _dup(12) "-" "+" _dup(35) "-"

 `dib' _n " cases   " in gr "   : distribution of # of matches"
 `sep'
  tab `nbM' if `tbM'==1

 `dib' _n " non-cases" in gr "  : distribution of calls as match"
 `sep'
  tab `nbM' if `touse'

 if "`first'"!="" {
   qui replace `nbM'=`fst' if `touse' 
   `dib' _n "option <first> :"
   `dib' "  `nbM' modified in non-cases to hold id.num of first case matched"
 }

* cleanup: restore formats and sort-order

 format `tbM' `ftb'
 if "`show'"!="" {
   loc j=0
   while `j'<`nV' {
     loc j =`j'+1
     loc v : word `j' of `varli'
     loc j0=substr(string(100+`j'),2,2)
     format `v' `fm`j0''
   }
 }
 sort `srt' `seq'
end
*
*--------------------- subroutines
 prog def niOpt
*
  glo S_1
  glo S_3 0
  qui {
   replace `2'=""
   replace `3'=.
   replace `4'=.
  }
end
*---------------
 prog def rdOpt
*
*   parse `1'(texopt) adjusting
*         `2'(vars) `3'(optV) `4' (dVL) `5'(dVH)
*         `6'= code = e.g. RD for <rel.dev (%)>
  loc tex   `1'
  loc vars  `2'
  loc wV    `3'
  loc dVL   `4'
  loc dVH   `5'
  loc rel = length("`6'")==2
  loc typ = substr("`6'",1+`rel',1)
  loc stor
  loc nitm  0
  loc prev  0

  parse "`tex'", parse(" ")
  while "`1'"!="" {
    loc wk "`1'"
    capt su `wk'
    loc svar=_rc==0
    if `svar' {
      unabbrev `wk'
      loc wk  $S_1
      loc wc  $S_2
      loc j 0
      while `j' < `wc' {
        loc  j = `j'+1
        loc  w : word `j' of `wk'
        if "`typ'"=="S" { loc stor `stor' `w' }
        else {
          glo S_3 = $S_3+1
          if $S_3 > _N { set obs $S_3 }
          qui replace `wV'="`w'" in $S_3
          qui count if `vars'=="`w'"
          if _result(1)==0 {
            glo S_4 = $S_4+1
            if $S_4 >_N { set obs $S_4 }
            qui replace `vars'="`w'" in $S_4
          }
        }
      }
      loc prev `svar'
    }
    else {
      if !`prev' {
        `dir' "don't understand `wk' in `tex'"
        error 198
      }
* D
      if       "`typ'"=="D" {
        if real("`wk'")!=. { loc wk "`wk'/`wk'" }
        loc x=index("`wk'","/")
        if `x'==0 {
          `dir' "`wk': missing  / in <dLo/dHi>"
          error 198
        }
          loc w=substr("`wk'",1,`x'-1)
        adju `dVL' `w' `rel' "<devia> below"
          loc w=substr("`wk'",`x'+1,.)
        adju `dVH' `w' `rel' "<devia> above"
      }
* E
      else if  "`typ'"=="E" {
        adju `dVL' `wk' `rel' "<euclid>"
        loc sg=cond(`rel',-1,1)*`wk'
        loc stor `stor' `sg' $S_2
        loc  j $S_3-$S_2
        while `j' < $S_3 {
          loc j=`j'+1
          loc v=`wV'[`j']
          loc stor `stor' `v'
        }
      }
* O
      else if  "`typ'"=="O" {
        adju `dVL' `wk'   0   "<out of>"
        loc stor `stor' `wk' $S_2
        loc  j $S_3-$S_2
        while `j' < $S_3 {
          loc j=`j'+1
          loc v=`wV'[`j']
          loc stor `stor' `v'
        }
      }
      loc nitm=`nitm'+1
      loc prev= 0
    }
    mac shift
  }
  glo S_1 `stor'
  glo S_6 `nitm'
end
*--------------
 prog def adju
*
  loc w=real("`2'")
  glo S_2= 0
  if `w'!=. {
    loc j= $S_3
    if `3' { loc w= -`w' }
    while (`j'>0) & (`1'[`j']==.) {
      qui replace `1'=`w' in `j'
      glo S_2= $S_2 +1
      loc  j =  `j' -1
    }
  }
  else {
   `dir' "`w' : bad request for <" substr("R",`3',1) substr("`4'",2,.)
   error 198
  }
end
