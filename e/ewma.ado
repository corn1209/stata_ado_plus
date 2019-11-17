program define ewma
*! NJC 1.1.0 27 March 1998
version 3.0
    local varlist "req max(1)"
    local options "a(real 1) Generate(string)"
    parse "`*'"
    if "`generat'" == "" {
        di in r "generate( ) option required"
        exit 198
    }
    local x `varlist'
    gen `generat' = `x'[1]
    qui replace `generat' = /*
     */ `a' * `x'[`i'] + (1 - `a') * `generat'[_n - 1] in 2/l
end