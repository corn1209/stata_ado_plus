*! Information criteria. v.1.1. by Stas Kolenikov, skolenik@yahoo.com
program define icomp, rclass
  version 6
  syntax , [RSS]
  if "`e(cmd)'"=="" {  error 301 }
  if e(ll)==. {
     di in red "Cannot retrieve the estimate of likelihood"
     exit 301
  }
  if "`rss'"=="" { local lackfit = e(ll) }
            else { local lackfit = -.5*e(N)*log(e(rss)/e(N)) }
  return scalar AIC=-2*`lackfit'+2*e(df_m)
  return scalar SBIC=-2*`lackfit'+e(df_m)*log(e(N))
  return scalar CAIC=-2*`lackfit'+e(df_m)*(log(e(N))+1)
  tempname IFIM
  matrix `IFIM'=e(V)
  local s=rowsof(`IFIM')
  return scalar ICOMP=-2*`lackfit'+`s'*log(trace(`IFIM')/`s')-log(det(`IFIM'))
  di in gre _n "  Information criteria"
  di in green "AIC   = " in yellow %8.5f return(AIC)
  di in green "SBIC  = " in yellow %8.5f return(SBIC)
  di in gre   "ICOMP = " in ye %8.5f return(ICOMP)
end
