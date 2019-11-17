*! NJC 1.0.0 11 August 1998
program define catenate
    version 5.0

    local g "`1'"
    confirm new variable `g'

    mac shift
    mac shift               /* discard = sign */

    local varlist "req ex min(1)"
    local in "opt"
    local if "opt"
    local options "Punct(str)"
    parse "`*'"

    if "`punct'" == "" { local punct " " }
    else if "`punct'" == "no" { local punct "" }
    local plen = length("`punct'")

    quietly {
        gen str1 `g' = "" `if' `in'
        parse "`varlist'", parse(" ")
        while "`1'" != "" {
            capture confirm string variable `1'
            if _rc {
                capture assert `1' == int(`1') `if' `in'
                if _rc == 9 {
                    noi di in bl "warning: non-integer values in `1'"
                }
                replace `g' = `g' + "`punct'" + string(`1') `if' `in'
            }
            else { replace `g' = `g' + "`punct'"  + `1' `if' `in' }
            mac shift
        }
        replace `g' = substr(`g',1 + `plen',.)
    }
end
