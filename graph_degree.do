capture log using "C:/Users/L841580/Desktop/I-O-Stan/Stata-Programmes/$S_DATE $S_TIME.log", replace
set matsize 7000
set more off
global dir "C:\Users\L841580\Desktop\I-O-Stan\bases_stata"

import excel "C:\Users\L841580\Desktop\I-O-Stan\bases_stata/mean_all_inou.xls", firstrow 

*-------------------------------------------------------------------------------
* création dummy zone euro
*-------------------------------------------------------------------------------
global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
replace dum_ZE=1 if (country=="`n'")
}


*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree pour chaque année, chaque matrice
*-------------------------------------------------------------------------------


local poids "X Yt"
foreach n of local poids{

	local correc "no yes"
	foreach c of local correc{

		foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

			graph twoway scatter indegree outdegree if (cor=="`c'" & weight=="`n'" & shock_type=="p" & year=="`i'" & dum_ZE==1), mlabel(country) yscale(log) xscale(log) title("indegreee/outdegree price choc, `i'") subtitle("correction: `c', weighted : `n'") saving($dir/graphp_`i'_`c'_`n') 
		}
	}
}
				
local poids "X Yt"
foreach n of local poids{

	local correc "no yes"
	foreach c of local correc{

		foreach i of numlist 1995 2000 2005 {

			graph twoway scatter indegree outdegree if (cor=="`c'" & weight=="`n'" & shock_type=="w" & year=="`i'" & dum_ZE==1), mlabel(country) yscale(log) xscale(log) title("indegreee/outdegree wage choc, `i'") subtitle("correction: `c', weighted : `n'") saving($dir/graphw_`i'_`c'_`n') 
		
		}
	}
}

*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------


*& inlist(country,"AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC", "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT")==1

separate indegree, by(year)

local poids "X Yt"
foreach n of local poids{

	local correc "no yes"
	foreach c of local correc{


		egen mini=min(indegree) if (cor=="`c'" & weight=="`n'" & shock_type=="p" & (year=="1995"||year=="2011"))
		egen maxi=max(indegree) if (cor=="`c'" & weight=="`n'" & shock_type=="p" & (year=="1995"||year=="2011"))
		gen diagonale=outdegree if (outdegree<maxi & outdegree>mini)
		
		graph twoway (scatter indegree1 indegree7 outdegree,mlabel(country country) ) (line diagonale outdegree) if (cor=="`c'" & weight=="`n'" & shock_type=="p" & (year=="1995"||year=="2011") & dum_ZE==1),  yscale(log) xscale(log) title("indegreee/outdegree price shock, 1995/2011") subtitle("correction: `c', weighted : `n'") saving($dir/graphp_95_2011_`c'_`n') 
		
		drop mini
		drop maxi
		drop diagonale
						
							}
						}
