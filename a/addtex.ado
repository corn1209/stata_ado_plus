prog def addtex
*
* call: addtex [filename]  (must be new name, gph requirement) 
*
	if "`1'"=="" { gph open }
	else         { gph open , saving(`1') } 
	gr
	hlTex
	gph close
end