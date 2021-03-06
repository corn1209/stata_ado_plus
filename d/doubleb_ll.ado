

* Version: September 2013
* Alejandro Lopez-Feldman
* Division de Economia
* Centro de Investigacion y docencia economicas, CIDE
* lopezfeldman@gmail.com
* This is called by doubleb.ado

program doubleb_ll
	version 10.1
	args lnf xb sig
	tempvar bid1 bid2 nn ny yn yy check
	gen double `bid1'= $ML_y1 
	gen double `bid2'= $ML_y2
	gen  `yy' = $ML_y3 * $ML_y4  
	gen `nn' = 0 
	qui replace `nn' =1 if $ML_y3==0  & $ML_y4==0   
	gen `ny' = 0 
	qui replace `ny' = 1 if $ML_y3==0  & $ML_y4==1 
	gen `yn' = 0 
	qui replace `yn' = 1 if $ML_y3==1  & $ML_y4==0 

	qui replace `lnf' = ln(normal(((`xb'-`bid2')/(`sig')))) if `yy' ==1
	qui replace `lnf' = ln(1-normal(((`xb'-`bid2')/(`sig')))) if `nn' ==1
	qui replace `lnf' = ln(normal(((`xb'-`bid1')/(`sig')))-normal(((`xb'-`bid2')/(`sig')))) if `yn' ==1
	qui replace `lnf' = ln(normal(((`xb'-`bid2')/(`sig')))-normal(((`xb'-`bid1')/(`sig')))) if `ny' ==1	

end
