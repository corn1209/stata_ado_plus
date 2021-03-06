capture program drop _vibli_update
program define _vibli_update
   args paste
  
   set more off

   preserve

   if `paste' == 1 {
   capture file open paste2 using _vibli_paste_syntax.do, write text append
   local mydate = c(current_date)
   local mytime = c(current_time)  
   file write paste2 "/*---------------------------------------------" _n
   file write paste2 "Session starts at `mytime'  `mydate'." _n
   file write paste2 "----------------------------------------------*/" _n
	}

   local cplot = "`._vibli_dlg.main.ck_cc_all.value'"  
 
   local dbl_logit  = "`._vibli_dlg.main.ck_logit.value'"
   local dbl_prob   = "`._vibli_dlg.main.ck_prob.value'"
   local dbl_v7     = "`._vibli_dlg.main.ck_v7.value'"
   local dbl_om_int = "`._vibli_dlg.main.om_int.value'"
   local dbl_clow   = "`._vibli_dlg.main.ex_cc_min.value'"
   local dbl_chigh  = "`._vibli_dlg.main.ex_cc_max.value'"
 
   local dbl_b0 = "`._vibli_dlg.main.ex_b0.value'"  
   local dbl_b1 = "`._vibli_dlg.main.ex_b1.value'"  
   local dbl_b2 = "`._vibli_dlg.main.ex_b2.value'"  
   local dbl_b12 = "`._vibli_dlg.main.ex_b12.value'"  
   local dbl_cc  = "`._vibli_dlg.main.ex_cc.value'"  


   local dbl_p1 = "`._vibli_dlg.main.ck_p1.value'"
   local dbl_p2 = "`._vibli_dlg.main.ck_p2.value'"
   local dbl_p3 = "`._vibli_dlg.main.ck_p3.value'"
   local dbl_p4 = "`._vibli_dlg.main.ck_p4.value'"

   capture confirm number `dbl_b0'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }
   capture confirm number `dbl_b1'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }
   capture confirm number `dbl_b2'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }
   capture confirm number `dbl_b12'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }
   capture confirm number `dbl_cc'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }

   capture confirm number `dbl_clow'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }

  capture confirm number `dbl_chigh'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }

   
  global DB_x1_lab = "`._vibli_dlg.main.ex_x1_lab.value'"  
  global DB_x2_lab = "`._vibli_dlg.main.ex_x2_lab.value'" 
 
  global toplot1 = "b0(`dbl_b0') b1(`dbl_b1') b2(`dbl_b2') b12(`dbl_b12') ccmin(`dbl_clow') ccmax(`dbl_chigh') "
  global toplot2 = "nodraw omitint(`dbl_om_int') abcd  x1name($DB_x1_lab) x2name($DB_x2_lab)"


  if `cplot' == 1 { /*show plots for various covariate contribution*/

  
     local cc_list = "`._vibli_dlg.main.ex_cc_all.value'"
     
   	  	   
if `dbl_v7' == 1 {
	
        local mycount = 1	
        local toshow  ""

        set graph off

        if `dbl_prob' == 1 {

         if `dbl_p1' == 1 {

	    foreach num of numlist `cc_list' { 
   		if `paste' == 0 {
		 vibligraph, $toplot1 $toplot2 ccat(`num') v7  type(1) saving(g`mycount', replace)
		}
                else {
                _view_write,  rest("ccat(`num') type(1)  v7  saving(g`mycount', replace)")
		}
            local toshow  `toshow'   g`mycount'.gph
            local mycount = `mycount' + 1
			}
	}

       
       if `dbl_p2' == 1 {
   		if `paste' == 0 {
                 vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list') type(2) saving(g`mycount', replace)
			}
                else {
                _view_write,  rest("ccat(`cc_list')  v7 type(2)  saving(g`mycount', replace)")
		}

                local toshow  `toshow'  g`mycount'.gph
          	local mycount = `mycount' + 1
       		}
      
       if `dbl_p3' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list')  type(3) saving(g`mycount', replace)
			}
                  else {
                _view_write,  rest("ccat(`cc_list')  v7 type(3) saving(g`mycount', replace)")
		}

                local toshow  `toshow'  g`mycount'.gph
          	local mycount = `mycount' + 1
       		}
  
       if `dbl_p4' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list') type(4) saving(g`mycount', replace)
			}
                  else {
                _view_write,  rest("ccat(`cc_list')  v7 type(4) saving(g`mycount', replace)")
		}

                local toshow  `toshow'  g`mycount'.gph
          	local mycount = `mycount' + 1
       		}

	  } /*end of `dbl_prob' = 1, probability plots*/
	 

       if `dbl_logit' == 1 {

	    foreach num of numlist `cc_list' { 
   		if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2  v7 ccat(`num')  logit type(1) saving(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`num')  v7  logit type(1) saving(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'.gph
            local mycount = `mycount' + 1
			}

   
       if `dbl_p2' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list')  logit type(2) saving(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`cc_list')  v7 logit type(2) saving(g`mycount', replace)")
		}
                local toshow  `toshow'  g`mycount'.gph
          	local mycount = `mycount' + 1
       		}
      
       if `dbl_p3' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list') logit type(3) saving(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`cc_list')  v7 logit type(3) saving(g`mycount', replace)")
		}
                local toshow  `toshow'  g`mycount'.gph
          	local mycount = `mycount' + 1
       		}
  
       if `dbl_p4' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2  v7 ccat(`cc_list') logit type(4) saving(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`cc_list') v7  logit type(4) saving(g`mycount', replace)")
		}
                local toshow  `toshow'   g`mycount'.gph
          	local mycount = `mycount' + 1
       		}

	}/*end of `dbl_logit' = 1, logit plots*/

       set graph on
      if `paste' == 0 {
	  graph7 using `toshow'
	}
      else {
          _view_write, rest("graph7 using `toshow'") com
       }
} /*end of version 7*/

    
if `dbl_v7' == 0 { /*version 8 plots*/

  	local mycount = 1	
        local toshow  ""
     	
        set graph off

        if `dbl_prob' == 1 {
	
             if `dbl_p1' == 1 {

	  foreach num of numlist `cc_list' {
   		if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2 ccat(`num') type(1) name(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`num') type(1) name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
		}
	}

       if `dbl_p2' == 1 {
   		if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(2) name(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`num') type(2) name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
		}
      
       if `dbl_p3' == 1 {
   		if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(3) name(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`num') type(3) name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
		}
  
       if `dbl_p4' == 1 {
   		if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(4) name(g`mycount', replace)
		}
                  else {
                _view_write,  rest("ccat(`num') type(4) name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
		}

     	} /*end of `dbl_prob' == 1, probability plot*/

	
      if `dbl_logit' == 1 {

	  foreach num of numlist `cc_list' {
           if `paste' == 0 {
   		 vibligraph, $toplot1 $toplot2 logit ccat(`num') type(1) name(g`mycount', replace)
		}
                  else {
                _view_write,  rest("logit ccat(`num') type(1) name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
		}

       if `dbl_p2' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(2) logit name(g`mycount', replace)
			}
                  else {
                _view_write,  rest("ccat(`cc_list') type(2) logit name(g`mycount', replace)")
		}
                local toshow  `toshow'  g`mycount'
          	local mycount = `mycount' + 1
       		}
      
       if `dbl_p3' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(3) logit name(g`mycount', replace)
			}
                  else {
                _view_write,  rest("ccat(`cc_list') type(3) logit name(g`mycount', replace)")
		}
                local toshow  `toshow'  g`mycount'
          	local mycount = `mycount' + 1
       		}
       if `dbl_p4' == 1 {
   		if `paste' == 0 {
	         vibligraph, $toplot1 $toplot2 ccat(`cc_list') type(4) logit name(g`mycount', replace)
			}
                  else {
                _view_write,  rest("ccat(`cc_list') type(4) logit name(g`mycount', replace)")
		}
               local toshow  `toshow'  g`mycount'
          	local mycount = `mycount' + 1
       		}

     		} /*end of logit plot*/
    set graph on

   if `paste' == 0 {
	  graph combine `toshow'
	}
    else {
	_view_write, rest("graph combine  `toshow'") com
	}

	 } /*end of version 8*/

  } /*end of cplot== 1 */


   if `cplot' == 0 {

     local dbl_p1 = "`._vibli_dlg.main.ck_p1.value'"
     local dbl_p2 = "`._vibli_dlg.main.ck_p2.value'"
     local dbl_p3 = "`._vibli_dlg.main.ck_p3.value'"
     local dbl_p4 = "`._vibli_dlg.main.ck_p4.value'"
  

  
  *getting the list of panels to show

   local pnum = " "
   if `dbl_p1' == 1 {
      local pnum = "`pnum'" + " " + "1"
 	}

   if `dbl_p2' == 1 {
      local pnum = "`pnum'" + " " + "2"
 	}
   if `dbl_p3' == 1 {
      local pnum = "`pnum'" + " " + "3"
 	}
   if `dbl_p4' == 1 {
      local pnum = "`pnum'" + " " + "4"
 	}

   if `dbl_v7' == 1 { /*version 7 stuff*/
      
     if `dbl_logit' == 1 & `dbl_prob' == 1 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' {
   	    if `paste' == 0 {
   	     vibligraph, $toplot1 $toplot2 ccat(`dbl_cc')  v7 type(`num') saving(g`mycount', replace)
          		}
           else {
                _view_write,  rest("ccat(`dbl_cc')  v7 type(`num') saving(g`mycount', replace)")
		}
            local toshow   `toshow' g`mycount'.gph
            local mycount = `mycount' + 1
	 
	    if `paste' == 0 {
             vibligraph, $toplot1 $toplot2 ccat(`dbl_cc')  v7 type(`num') logit saving(g`mycount', replace)
   	  	}
           else {
                _view_write,  rest("ccat(`dbl_cc')  v7 type(`num') logit saving(g`mycount', replace)")
		}
            local toshow   `toshow' g`mycount'.gph
            local mycount = `mycount' + 1
     	} 
 
     set graph on
     if `paste' == 0 {
     	graph7 using `toshow'
       }
     else {
       _view_write , rest("graph7 using `toshow'") com
	}

   } /*end of prob and logit plots*/

    
     if `dbl_logit' == 0 & `dbl_prob' == 1 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' { 
        if `paste' == 0 {
   	     vibligraph, $toplot1 $toplot2 ccat(`dbl_cc')  v7 type(`num') saving(g`mycount', replace)
   	  	}
           else {
                _view_write,  rest("ccat(`dbl_cc')  v7 type(`num') logit saving(g`mycount', replace)")
		}
            local toshow   `toshow' g`mycount'.gph
            local mycount = `mycount' + 1
     	} 
 
     set graph on 
     if `paste' == 0 {
     graph7 using `toshow' 
         }
     else {
    _view_write,  rest("graph7 using `toshow'") com
		}
   
} /*end of prob plots*/

 
     if `dbl_logit' == 1 & `dbl_prob' == 0 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' {
	
	if `paste' == 0 {
             vibligraph, $toplot1 $toplot2 ccat(`dbl_cc')  v7 type(`num') logit saving(g`mycount', replace)
	}
        else {
                _view_write,  rest("ccat(`dbl_cc')  v7 type(`num') logit saving(g`mycount', replace)")
		}
         
            local toshow   `toshow' g`mycount'.gph
            local mycount = `mycount' + 1
     	} 
 
     set graph on
     if `paste' == 0 {
	     graph7 using `toshow' 
		}
     else {
	 _view_write,  rest("graph7 using `toshow' ") com
		}
	} /*end of logit plots*/

} /*end of version 7*/

   if `dbl_v7' == 0 { /*version 8 stuff*/
      
       if `dbl_logit' == 1 & `dbl_prob' == 1 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' {

     if `paste' == 0 {
   	     vibligraph, $toplot1 $toplot2 ccat(`dbl_cc') type(`num') name(g`mycount', replace)
		}
     else {
	 _view_write,  rest("ccat(`dbl_cc') type(`num') name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
	
     if `paste' == 0 {
             vibligraph, $toplot1 $toplot2 ccat(`dbl_cc') type(`num') logit name(g`mycount', replace)
		}
     else {
	 _view_write,  rest("ccat(`dbl_cc') type(`num') logit name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
     	} 
 
     set graph on
     if `paste' == 0 {
     graph combine `toshow' 
		}
     else {
	 _view_write,  rest("graph combine `toshow' ") com
		}
     			} /*end of prob and logit plots*/

    
     if `dbl_logit' == 0 & `dbl_prob' == 1 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' {
   	 
     if `paste' == 0 {
       vibligraph, $toplot1 $toplot2 ccat(`dbl_cc') type(`num') name(g`mycount', replace)
		}
     else {
	 _view_write,  rest("ccat(`dbl_cc') type(`num') name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
     	} 
 
     set graph on

     if `paste' == 0 {
     graph combine `toshow' 
		}
     else {
	 _view_write,  rest("graph combine `toshow' ") com
		}
			} /*end of prob plots*/

 
     if `dbl_logit' == 1 & `dbl_prob' == 0 {

      set graph off

      local mycount = 1	
      local toshow  ""
  
      foreach num of numlist `pnum' {
	
     if `paste' == 0 {
             vibligraph, $toplot1 $toplot2 ccat(`dbl_cc') type(`num') logit name(g`mycount', replace)
		}
     else {
	 _view_write,  rest("ccat(`dbl_cc') type(`num') logit name(g`mycount', replace)")
		}
            local toshow  `toshow'  g`mycount'
            local mycount = `mycount' + 1
     	} 
 
     set graph on

     if `paste' == 0 {
     graph combine `toshow' 
		}
     else {
	 _view_write,  rest("graph combine `toshow' ") com
		}
			} /*end of logit plots*/


	} /*end of version 8*/

} /*end of cplot==0*/

   if `paste' == 1 {
   capture file close paste2
   display 
   display in yellow "Syntax has been pasted to _vibli_paste_syntax.do file. "
	}

end

capture program drop _view_write
program _view_write
   syntax, [rest(string) com]
     if "`com'" == "" {
     file write paste2 "vibligraph, "
     file write paste2 "$toplot1" 
     file write paste2 "$toplot2" 
    }
     file write paste2 "`rest'" _n 


end
