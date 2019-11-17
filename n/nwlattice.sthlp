{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 8 18 22 2}{...}
{p2col :nwlattice {hline 2} Generate a lattice network}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwlattice} 
{it: {help int:rows cols}}
{cmd:,}
[{opt undirected}
{opt xwrap}
{opt ywrap}
{opt name}({it:{help newnetname}})
{opt vars}({it:{help newvarlist}})
{opt xvars}
{opth ntimes(int)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:rows}}}number of rows in lattice{p_end}
{synopt:{it:{help int:cols}}}number of columns in lattice{p_end}
{synopt:{opt xwrap}}wrap horizontally{p_end}
{synopt:{opt ywrap}}wrap vertically{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt vars}({it:{help newvarlist}})}new variables that are used for the network{p_end}
{synopt:{opt xvars}}do not generate Stata variables{p_end}
{synopt:{opth ntimes(int)}}number of networks to be generated; default = 1{p_end}

{title:Description}

{pstd}
{cmd:nwlattice} generates a lattice network. Each node is connected to maximally four other nodes. With options {it:xwrap} and {it:ywrap} 
each node is connected to exactly four other nodes.


{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwlattice 4 4}
	{cmd:. nwplot, label(_nodeid)}
	
	{cmd:. nwclear}
	{cmd:. nwlattice 4 4, xwrap ywrap}
	{cmd:. nwplot, layout(grid) label(_nodeid)}	
	
	
{title:See also}

	{help nwpref}, {help nwrandom}, {help nwring}, {help nwsmall}
