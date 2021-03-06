{smcl}
{* *! version 0.1  4 Jul 2016}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help statsby" "help statsby"}{...}
{vieweralsosee "Help table" "help table"}{...}
{vieweralsosee "Help summarize" "help summarize"}{...}
{vieweralsosee "Help basetable (if installed)" "help basetable"}{...}
{vieweralsosee "Help outsum (if installed)" "help outsum"}{...}
{vieweralsosee "Help outtable (if installed)" "help outtable"}{...}
{vieweralsosee "Help statsmat (if installed)" "help statsmat"}{...}
{vieweralsosee "Help tabexport (if installed)" "help tabexport"}{...}
{vieweralsosee "Help tabout (if installed)" "help tabout"}{...}
{vieweralsosee "Help tabstatmat (if installed)" "help tabstatmat"}{...}
{viewerjumpto "Syntax" "sumat##syntax"}{...}
{viewerjumpto "Description" "sumat##description"}{...}
{viewerjumpto "List of statistics" "sumat##statistics"}{...}
{viewerjumpto "Examples" "sumat##examples"}{...}
{viewerjumpto "Stored results" "sumat##results"}{...}
{viewerjumpto "Author and support" "sumat##author"}{...}
{title:Title}
{phang}{bf:sumat} Statistical summary table - A wrapper and extension of 
{help summarize:summarize}

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sumat} varlist [{help if}] [{help in}] [{help using}] {cmd:,}
statistics({help sumat##statistics:list of statistics}) 
[{it:options} {it:matprint_options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt stat:istics(string)}} Specify {help sumat##statistics:list of statistics}
to get summarized for each variable.{p_end}
{syntab:Optional}
{synopt:{opt coleq:(string)}} Column equation names of the matrix.{p_end}
{synopt:{opt roweq:(string)}} Row equation names of the matrix.{p_end}
{synopt:{opt p:pct(integer 95)}} An integer between 0 and 100 specifying the
p value used in confidence and predection intervals.{p_end}
{synopt: {opt row:by(varname)}} The name of a categorical variable used to group by 
rowwise.{p_end}
{synopt:{opt t:otal}} Add a row total. Only if {opt row:by} is used.{p_end}
{synopt:{opt f:ull}} Get all summary rows even if they are empty. 
Only if {opt row:by} is used.{p_end}
{synoptline}
{syntab:Matprint options}
{synopt:{opt s:tyle(string)}} Style for output. One of the values {bf:smcl} (default), 
{bf:csv} (semicolon separated style), 
{bf:latex or tex} (latex style),
{bf:html} (html style) and
{bf:md} (markdown style, experimental) 
.{p_end}
{synopt:{opt d:ecimals(string)}} Matrix of integers specifying numbers of 
decimals at cell level. If the matrix is smaller than the data matrix the right
most column is copied to get the same number of columns. 
And likewise for the bottom row.{p_end}
{synopt:{opt ti:tle(string)}} Title/caption for the matrix output.{p_end}
{synopt:{opt to:p(string)}} String containing text prior to table content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt u:ndertop(string)}} String containing text between header and table 
content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt b:ottom(string)}} String containing text after to table content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt r:eplace}} Delete an existing {help using:using} file before adding table.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:sumat} is a flexible tool to generate survey tables. It differs from 
existing tools in that more statistics are possible to report and in that
the summary table is saved for further data handling.

{pstd}
{cmd:sumat} is integrated with {help matprint:matprint} such that styling in smcl,
html, latex, csv and markdown is quite easy.


{marker statistics}{...}
{title:List of statistics}
{phang} Any non lowercase version of statistics below will also do as an argument.

{dlgtab:From summarize}
{phang} Only for non string variables. In case of a string variable the value 
missing (.) is returned.

{synoptset 25 tabbed}{...}
{synopt:{cmd:n count}}number of observations{p_end}
{synopt:{cmd:sum}}sum of variable{p_end}
{synopt:{cmd:sum_w}}sum of the weights{p_end}
{synopt:{cmd:mean}}mean{p_end}
{synopt:{cmd:sd}}standard deviation{p_end}
{synopt:{cmd:Var}}variance{p_end}
{synopt:{cmd:skewness}}skewness{p_end}
{synopt:{cmd:kurtosis}}kurtosis{p_end}
{synopt:{cmd:min}}minimum{p_end}
{synopt:{cmd:max}}maximum{p_end}
{synopt:{cmd:p1}}1st percentile{p_end}
{synopt:{cmd:p5}}5th percentile{p_end}
{synopt:{cmd:p10}}10th percentile{p_end}
{synopt:{cmd:p25}}25th percentile{p_end}
{synopt:{cmd:p50 median}}50th percentile{p_end}
{synopt:{cmd:p75}}75th percentile{p_end}
{synopt:{cmd:p90}}90th percentile{p_end}
{synopt:{cmd:p95}}95th percentile{p_end}
{synopt:{cmd:p99}}99th percentile{p_end}
{dlgtab:Derived values}
{synoptset 25 tabbed}{...}
{synopt:{cmd:semean}}Standard error of mean (= standard deviation / sqrt(n)){p_end}
{synopt:{cmd:cv}}Coefficient of variation (= standard dviation / mean){p_end}
{synopt:{cmd:range}}(= max - min){p_end}
{synopt:{cmd:ci}}confidence interval (= mean +/- z(alfa) * standard deviation / sqrt(n)). 
The value for alfa can be set by option {opt p:pct}{p_end}
{synopt:{cmd:pi}}prediction interval (= mean +/- z(alfa) * standard deviation). 
The value for alfa can be set by option {opt p:pct}{p_end}
{synopt:{cmd:iqr}}interquartile range (= p75 - p25){p_end}
{synopt:{cmd:iqi}}interquartile interval (= (p25, p75)){p_end}
{synopt:{cmd:idi}}interdecentile interval = (p10, p90)){p_end}
{synopt:{cmd:fraction}}The row fraction of nonmissing values. 
Only interesting together with the {opt row:by} option{p_end}
{synopt:{cmd:missing}}number of missing values for the variable. 
Works for all types of variables.{p_end}
{synopt:{cmd:unique}}number of unique non missing values for the variable 
Works for all types of variables.{p_end}

{marker examples}{...}
{title:Examples}

{phang}{stata `"sysuse auto ,clear"'}{p_end}

{phang} Building "Create a summary matrix statistics n, fraction, missing, 
unique, mean, sd and a 75% confidence interval for the variables price foreign 
and rep78 if rep78 > 2. And show it with a repeting pattern of decimals 
(see {help matprint:matprint}):{p_end}
{phang}{stata `"sumat price foreign rep78 if rep78 > 2, statistics(n fraction missing unique mean sd ci) total rowby(rep78) p(75) decimals((0,2,0,2))"'}{p_end}

{phang}The resulting table is saved in the return list:{p_end}
{phang}{stata `"return list"'}{p_end}

{phang}Building first part (for foreign cars) of a summary matrix:{p_end}
{phang}{stata `"sumat price length weight if foreign, statistics(n missing mean ci) coleq(Foreign)"'}{p_end}
{phang}Save the output in a matrix:{p_end}
{phang}{stata `"matrix out = r(sumat)"'}{p_end}

{phang}And now build the same for domestic cars{p_end}
{phang}{stata `"sumat price length weight if !foreign, statistics(n missing mean ci) coleq(Domestic)"'}{p_end}
{phang}Add matrices columnwise:{p_end}
{phang}{stata `"matrix out = out, r(sumat)"'}{p_end}
{phang}Show the build matrix using {help matprint:matprint} utilising the 
decimals option:{p_end}
{phang}{stata `"matprint out, decimals(J(1, 2, (0,0,2,2,2)))"'}{p_end}

{phang}The final matrix can also be build rowwise:{p_end}
{phang}{stata `"quietly sumat price length weight if foreign, statistics(n missing mean ci) roweq(Foreign) coleq(" ")"'}{p_end}
{phang}{stata `"matrix out = r(sumat)"'}{p_end}
{phang}{stata `"quietly sumat price length weight if !foreign, statistics(n missing mean ci) roweq(Domestic)"'}{p_end}
{phang}{stata `"matrix out = out \ r(sumat)"'}{p_end}
{phang}Show the final matrix:{p_end}
{phang}{stata `"matprint out, decimals((0,0,2))"'}{p_end}

{phang}The matrix can easily be exported to excel (and word) using eg 
{help putexcel:putexcel}. Below using putexcel in State 14:{p_end}
{phang}{stata `"putexcel set delete_me.xlsx, replace"'}{p_end}
{phang}{stata `"putexcel (a1) = matrix( out ), names"'}{p_end}

{phang}Before version 13 {cmd:putexcel} didn't exist. Then the final summary 
matrix can be exported to excel with using and style csv in 
{help matprint:matprint}:{p_end}
{phang}{stata `"matprint out using delete_me.csv, decimals((0,0,2)) style(csv)"'}{p_end}

{phang}The option {opt f:ull} is to maintain same tablesize when using {opt row:by}:{p_end}
{phang}{stata `"sumat foreign if !foreign, statistics(n fraction) rowby(rep78) total full"'}{p_end}
{phang}{stata `"sumat foreign if foreign, statistics(n fraction) rowby(rep78) total full"'}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:sumat} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrix}{p_end}
{synopt:{cmd:r(sumat)}}The matrix containing all the specified values{p_end}

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Section for General Practice, {break}
	Dept. Of Public Health, {break}
	Aarhus University
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:nhbr@ph.au.dk":nhbr@ph.au.dk}
{p_end}
