*! Jarque-Bera normality test 
*! Corrected 12 Sep 2000 
* Orignally written by Gregorio Impavido
* GI gimpavido@worldbank.or
* Formula and code slightly modified by J. Sky David (6-28-99)
* See C.M. Jarque and A.K. Bera. 1987. "A Test for Normality 
* of Observations and Regression Residuals."  International 
* Statistical Review 55:163-172.;
* In Gujarati 1995 Basic Econometrics pp. 143-144

program define jb6, rclass
	version 6.0
	syntax varlist
	qui summ `1', det
	local JB = (r(N)/6)*((r(skewness)^2)+[(1/4)*(r(kurtosis)-3)^2])
	local JBsig = chiprob(2, `JB')
	noi di in gr "Jarque-Bera normality test: " /*
	*/in ye %6.5g `JB' , in gr /*
	*/ "Chi(" in ye "2" in gr ")" , in ye %6.5g (`JBsig')
	
	noi di in gr "Jarque-Bera test for Ho: normality: (" in ye "`1'" in gr")" 
	
	end 



