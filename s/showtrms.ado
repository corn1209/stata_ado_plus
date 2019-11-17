*! version 1.0, 12Sep2000, J.Hendrickx@mailbox.kun.nl
/*
Direct comments to: 

John Hendrickx <J.Hendrickx@mailbox.kun.nl>
Nijmegen Business School
University of Nijmegen
P.O. Box 9108
6500 HK Nijmegen
The Netherlands 

Desmat is available at 
http://baserv.uci.kun.nl/~johnh/desmat/stata/

Called by desmat to show variables, associated dummy variables, and their
parameterizations. Can be called separately now, primarily for when desmat 
is used in conjunction with a colon to directly estimate the model and 
present the results, in which case showtrms output is suppressed.
*/

program define showtrms
  version 6

  if "$ncols" == "" {
    display "showtrms is for use after running desmat, to produce a legend of variables"
    display "and the dummy variables used to represent them."
    exit
  }

  display _newline "Desmat generated the following design matrix:" _newline
  display "nr   Variables"  _col(22) "Term" _col(50) "Parameterization"
  display "     First    Last" _newline
  local pzation `_x_1[pzat]'
  local varn1="`_x_1[varn]'"
  local strtcol 1
  local term 1
  
  local i 1
  while `i' <= $ncols {
    local i=`i'+1

    local varn="`_x_`i'[varn]'"
    if "`varn'" ~= "`varn1'" {
      local endcol=`i'-1
      if `endcol'==`strtcol' {
        local fin "        "
        * global "$term*" variables for use by testparm and alltst.ado
        global term`term'="_x_`strtcol'"
      }
      else {
        local fin "_x_`endcol'"
        global term`term'="_x_`strtcol'-`fin'"
      }
      display %2s "`term'" %8s "_x_`strtcol'" %8s "`fin'" /*
      */ _col(22) "`varn1'" _col(50) "`pzation'"
      local term=`term'+1
      local strtcol `i'
      local pzation `_x_`i'[pzat]'
    }
    local varn1="`varn'"

  }
end
