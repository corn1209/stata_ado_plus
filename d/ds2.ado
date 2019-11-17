*! ds2 NJC 1.2.1 25 November 1999 
* ds2 NJC 1.2.0 25 February 1999
* ds version 3.1.0  06jun1998
program define ds2, rclass
        version 6
        syntax [varlist] /*
        */ [, String Numeric Detail Type(str) Hasval(str) Withval(str) ]

        if "`type'" != "" {
                if index("byte","`type'") { local type "byte" }
                else if index("int","`type'")  { local type "int" }
                else if index("long","`type'") { local type "long" }
                else if index("float","`type'")  { local type "float" }
                else if index("double","`type'")  { local type "double" }
                else if index("string","`type'") {
                        local type
                        local string "string"
                }
                else if substr("`type'",1,3) != "str" {
                        di in r "invalid data type"
                        exit 198
                }
                else {
                        local rest = real(substr("`type'",4,.))
                        if `rest' < 1 | `rest' > 80 {
                                di in r "invalid data type"
                                exit 198
                        }
                }
        }

        if "`type'" != "" & "`string'`numeric'" != "" {
                di in r "may not combine type( ) with `string' `numeric'"
                exit 198
        }

        if "`hasval'`withval'" != "" {
                if "`string'" != "" { di in bl "may not label strings" }
                if "`hasval'" != "" {
                        local hasval = lower("`hasval'")
                        if !index("ynau","`hasval'") {
                                di in r "invalid hasval( ) option"
                                exit 198
                        }
                }
                else if "`withval'" != "" { qui label list `withval' }
        }

        /* valid input! */
        tokenize `varlist'

        if "`string'" != "" | "`numeric'" != "" {
                if "`string'" != "" & "`numeric'" != "" {
                        di in bl "string and numeric specified together"
                }
                else {
                        local i 1
                        while "``i''" != "" {
                                capture confirm string variable ``i''
                                if _rc == 0 { local slist "`slist' ``i''" }
                                else local nlist "`nlist' ``i''"
                                local i = `i' + 1
                        }
                        if "`string'" != "" { tokenize `slist' }
                        else tokenize `nlist'
                }
        }

        if "`type'" != "" {
                local i 1
                while "``i''" != "" {
                        local this : type ``i''
                        if "`this'" == "`type'" {
                                local typlist "`typlist' ``i''"
                        }
                        local i = `i' + 1
                }
                tokenize `typlist'
        }

        if "`hasval'" != "" {
                local hasval = index("ya", "`hasval'") != 0
                local i 1
                while "``i''" != "" {
                        local vlabel : value label ``i''
                        local vlabel = "`vlabel'" != ""
                        if `vlabel' == `hasval' {
                                local vallist "`vallist' ``i''"
                        }
                        local i = `i' + 1
                }
                tokenize `vallist'
        }
        else if "`withval'" != "" {
                local i 1
                while "``i''" != "" {
                        local vlabel : value label ``i''
                        if "`vlabel'" == "`withval'" {
                                local vallist "`vallist' ``i''"
                        }
                        local i = `i' + 1
                }
                tokenize `vallist'
        }

        if "`detail'" != "" { 
		if "`*'" != "" { describe `*' }
	} 	
        else {
                local i 1
                while "``i''" != "" {
                        if (mod(`i'-1,8)==0 & `i'!=1) { di }
                        local l=9-length("``i''")+(mod(`i',8)!=0)
                        di in gr "``i''" _skip(`l') _c
                        local i=`i'+1
                }
                di
        }
        return local varlist `*'
end
exit

    1        2          3          4         5       6        7          8
variname  variname  variname  variname  variname  variname  variname  variname
