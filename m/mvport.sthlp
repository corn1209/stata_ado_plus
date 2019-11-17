{smcl}
{* *! version 2.0.0  17jul2016}{...}

{vieweralsosee "returnsyh" "help returnsyh"}{...}
{vieweralsosee "meanrets" "help meanrets"}{...}
{vieweralsosee "varrets" "help varrets"}{...}
{vieweralsosee "cmline" "help cmline"}{...}
{vieweralsosee "efrontier" "help efrontier"}{...}
{vieweralsosee "gmvport" "help gmvport"}{...}
{vieweralsosee "ovport" "help ovport"}{...}
{vieweralsosee "simport" "help simport"}{...}
{vieweralsosee "holdingrets" "help holdingrets"}{...}
{vieweralsosee "backtest" "help backtest"}{...}
{vieweralsosee "cbacktest" "help cbacktest"}{...}

{viewerjumpto "Syntax" "mvport##syntax"}{...}
{viewerjumpto "Description" "mvport##description"}{...}
{viewerjumpto "Options" "mvport##options"}{...}
{viewerjumpto "Remarks" "mvport##remarks"}{...}
{viewerjumpto "Examples" "mvport##examples"}{...}
{viewerjumpto "Results" "mvport##results"}{...}
{title:Title}

{phang}
{bf:mvport} {hline 2} Calculates the Minimum Variance financial portfolio given a specific required rate of return and a set of financial returns. 

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{opt mvport} {varlist} {ifin}
{cmd:,} {it:ret(#)}  [options]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt ret(#)}}required rate of return of the portfolio {p_end}
{synopt :{opt rfrate(#)}}risk-free rate of the period (e.g. if monthly data, then specify the risk-free rate per month). The default value is zero (if it is not specified).{p_end}
{synopt :{opt nport(#)}}number of portfolios along the efficient frontier to be computed. The default is 100.{p_end}
{synopt :{opt nos:hort}}Indicates that no short sales are allowed (no negative weights for the instruments). The default is to allow for short sales.{p_end}
{synopt :{opt case:wise}}Specifies casewise deletion of observations. If casewise is specified, then expected returns and variance-covariance matrix are 
computed using only the observations that have nonmissing values for all variables in varlist. If casewise is not specified, 
then all possible data of the sample for all variables will be used to compute the expected returns and variance-covariance matrix.
The default is to use all the nonmissing values for each variable.{p_end}
{synopt :{opt min:weight(#)}}Specifies the minimum weight to be allowed for all instruments. In case of specifying the noshort option, the default value for minweight is zero. {p_end}
{synopt :{opt rmin:weights}}In case of specific restrictions of minimum weights for each instrument or return, a list of minimum weights have to be indicated here.
This is a list of decimal numbers usually from 0 to 1. If the list has less numbers than the number of instruments, zero is assumed for the rest. Order of instruments is important here {p_end}
{synopt :{opt max:weight}}Specifies the maximum weight to be allowed for all instruments.{p_end}
{synopt :{opt rmax:weights}}In case of specific restrictions of maximum weights for each instrument or return, a list of maximum weights have to be indicated here.
This is a list of decimal numbers usually from 0 to 1. If the list has less numbers than the number of instruments, 1 is assumed for the rest. Order of instruments is important here {p_end}
{synopt :{opt covm:atrix(cov_matrix)}}If cov_matrix exists and has the right dimension according to the number of variables, instead of calculating the variance-covariance
matrix, then the cov_matrix will be used as the variance-covariance matrix to estimate the minimum variance portfolio.{p_end}
{synopt :{opt mr:ets(ret_matrix)}}If ret_matrix exists and has the right dimension according to the number of variables, instead of calculating the expected returns of the
assets, then the ret_matrix will be used as the vector of expected returns to estimate the minimum variance portfolio.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mvport} calculates the minimum variance financial portfolio given a specific return and a set of financial instrument returns specified in 
{varlist}. The {varlist} must be a list of continuously compounded returns of financial instruments to be considered for the portfolio.
If the noshort option is specified, short sales are not allowed; the default value is to allow short sales (allowing negative weights).  	
{it: mvport} also performs the risk decomposition of the portfolio. 
It estimates the contribution to portfolio risk of each asset (see Stored results). 

{marker remarks}{...}
{title:Remarks}

{pstd}
This command needs the installation of the meanrets command. Check the "Also See" Menu for related commands.
The return variables must be continuously compounded returns, not simple returns. 
If a specific list of minimum weights for each financial return or instrument is specified, then the option minweight is not used for computing the global minimum variance portfolio.

{marker examples}{...}
{title:Examples}

    {hline}

	{pstd} Collects online monthly stock data (adjusted prices) from Yahoo Finance with the user command returnsyh. This command also calculates simple and continuous compounded returns: {p_end}
{phang}{cmd:. returnsyh AAPL MSFT GE GM WMT XOM, fm(1) fd(1) fy(2012) lm(12) ld(31) ly(2015) frequency(m) price(adjclose)}{p_end}

{pstd} Estimates the global minimum variance portfolio : {p_end}
{phang}{cmd:. gmvport r_AAPL r_MSFT r_GE r_GM r_WMT r_XOM}{p_end}

{pstd} Estimates the minimum variance portfolio with a monthly required return of 0.50%: {p_end}
{phang}{cmd:. mvport r_AAPL r_MSFT r_GE r_GM r_WMT r_XOM}, ret(0.005){p_end}

{pstd} Estimates the minimum variance portfolio with a monthly required return of 0.50%, but now without allowing for short sales: {p_end}
{phang}{cmd:. mvport r_AAPL r_MSFT r_GE r_GM r_WMT r_XOM}, ret(0.005) noshort{p_end}

     {hline}
	 
{pstd} Estimates the same as above, but restricting periods starting from Jan 2013:{p_end}
{phang}{cmd:. mvport r_* if period>=tm(2013m1)}, ret(0.005) noshort{p_end}

{pstd} Calculates the minimum variance portfolio restricting the weights to be at least 10% for all instruments, with a required rate of 1.0%:{p_end}
{phang}{cmd:. mvport r_* , ret(0.01) minweight(0.10) }{p_end}

{pstd} Calculates the minimum variance portfolio restricting the weights to be less or equal to 30% with a required rate of 1.0% :{p_end}
{phang}{cmd:. mvport r_* , ret(0.01) noshort maxweight(0.30)}{p_end}

{pstd} Calculates the minimum variance portfolio restricting the weights to be less or equal to 30% and greater or equal to 10% (with a required rate of 1.0%):{p_end}
{phang}{cmd:. mvport r_* , ret(0.01) noshort maxw(0.30) minw(0.10)}{p_end}

{pstd} Calculates the minimum variance portfolio with different minimum weights for each instrument with a required rate of 1.0%:{p_end}
{phang}{cmd:. mvport r_* , ret(0.01) rminweights(0.1 0.1 0.1 0 0.16 0)}{p_end}
{pstd} Negative minimum weights for each instrument can also be specified.{p_end}

{pstd} Calculates the minimum variance portfolio with different maximum weights for each instrument with a required rate of 1.0%:{p_end}
{phang}{cmd:. mvport r_* , ret(0.01) rmaxweights(0.5 0.2 0.4 0.4 0.25 0.15)}{p_end}

     {hline}

{pstd} Calculates the expected returns of the instruments using the Exponential Weighted Moving Average (EWMA) method with a constant lamda=0.94:{p_end}
{phang}{cmd:. meanrets r_AAPL r_MSFT r_GE r_GM , lew(0.94)}{p_end}
{pstd} Saving the matrix of expected returns in a vector:{p_end}
{phang}{cmd:. matrix mrets=r(meanrets)}{p_end}

{pstd} Calculates the variance-covariance matrix of the instruments using the EWMA method with a constant lamda=0.94:{p_end}
{phang}{cmd:. varrets r_AAPL r_MSFT r_GE r_GM , lew(0.94)}{p_end}
{pstd} Saving the variance-covariance matrix in a local matrix:{p_end}
{phang}{cmd:. matrix cov=r(cov)}{p_end}

{pstd} Calculates the minimum variance portfolio using the calculated expected returns and variance-covariance matrix using the EWMA method, and with a required rate of 1.5%:{p_end}
{phang}{cmd:. mvport r_AAPL r_MSFT r_GE r_GM, ret(0.015) covm(cov) mrets(mrets)}{p_end}
{pstd} Any variance-covariance matrix can be used for the calculation of the global minimum variance portfolio.{p_end}

     {hline}

	
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mvport} saves results in {cmd:r()} in the following scalars, matrices/vectors:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N): }} number of observations used for computations{p_end}
{synopt:{cmd:r(varport): }}  minimum variance of the portfolio {p_end}
{synopt:{cmd:r(sdport): }} standard deviation of the minimum variance portfolio {p_end}
{synopt:{cmd:r(retport): }} return of the portfolio specified in the command{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(exprets): }} (n x 1) vector of expected simple returns for each return series {p_end}
{synopt:{cmd:r(cov): }} (n x n) variance-covariance matrix of return series {p_end}
{synopt:{cmd:r(weights):}} (n x 1) weight vector of the minimum variance portfolio{p_end}
{synopt:{cmd:r(mcr):}} (n x 1) Decomposition of risk: vector of asset marginal contributions to portfolio risk. 
   Risk decomposition is perfored using the Euler's theorem, so the marginal contributions to risk is a set of partial derivatives of portfolio risk with respect to each asset weight.{p_end}
{synopt:{cmd:r(cr):}} (n x 1) Decomposition of risk: vector of asset contributions to portfolio risk. This is equal to the marginal contributions multiplied by its respective weights.
   The sum of the elements of this vector is equal to the portfolio risk (portfolio standard deviation). {p_end}
{synopt:{cmd:r(pcr):}} (n x 1) Decomposition of risk: vector of asset percent contributions to portfolio risk. This is equal to the contributions divided by portfolio risk.
   The sum of the elements of this vector is equal to one. {p_end}  
{synopt:{cmd:r(betas):}} (n x 1) vector of asset betas with respect to the portfolio. An asset beta is defined as the covariance between the asset returns and the portfolio returns divided by the portfolio variance. {p_end} 

{p2colreset}{...}


{title: Author}

Carlos Alberto Dorantes, Tecnol�gico de Monterrey, Quer�taro Campus, Quer�taro, M�xico.
Email: cdorante@itesm.mx
