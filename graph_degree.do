clear
set more off
set matsize 7000

global dir C:\Users\L841580\Desktop\I-O-Stan\bases_stata
cd "$dir"

use "$dir/degrees.dta"

*-------------------------------------------------------------------------------
* création dummy zone euro
*-------------------------------------------------------------------------------


gen dum_UE=0
local UE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVN SVK CZE DNK HUN ISL NOR POL SWE CHE GBR USA JPN RUS HRV CHNPRO CHNNPR"
foreach n of local UE{
	replace dum_UE=1 if (pays=="`n'")
}

*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------


local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

		graph twoway scatter indegree outdegree if (weight=="`n'" & shock_type=="p" & year==`i' & dum_UE==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/outdegree price choc, `i'") subtitle("weighted : `n'") xtitle("outdegree") ytitle("indegree")  saving($dir/graphiques/graphp_`i'_`n') 
		graph export $dir/graphiques/graphp_`i'_`n'.pdf
	}
}
				
local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 {

		graph twoway scatter indegree outdegree if (weight=="`n'" & shock_type=="w" & year==`i' & dum_UE==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/outdegree wage choc, `i'") subtitle(" weighted : `n'") xtitle("outdegree") ytitle("indegree") saving($dir/graphiques/graphw_`i'_`n') 
		graph export $dir/graphiques/graphw_`i'_`n'.pdf
		
	}
}

*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree pondéré Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------

local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

		graph twoway scatter indegree outdegree2 if (weight=="`n'" & shock_type=="p" & year==`i' & dum_UE==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/weighted outdegree price choc, `i'") subtitle("weighted : `n'") xtitle("weighted outdegree") ytitle("indegree")  saving($dir/graphiques/graphp2_`i'_`n') 
		graph export $dir/graphiques/graphp2_`i'_`n'.pdf
	}
}
				
local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 {

		graph twoway scatter indegree outdegree2 if (weight=="`n'" & shock_type=="w" & year==`i' & dum_UE==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/weighted outdegree wage choc, `i'") subtitle(" weighted : `n'") xtitle("weighted outdegree") ytitle("indegree") saving($dir/graphiques/graphw2_`i'_`n') 
		graph export $dir/graphiques/graphw2_`i'_`n'.pdf
		
	}
}


*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------


tostring year, replace
separate indegree, by(year)

local poids "X Yt"
foreach n of local poids{

	egen mini=min(indegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	egen maxi=max(indegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	gen diagonale=outdegree if (outdegree<maxi & outdegree>mini)
		
	graph twoway (scatter indegree1 indegree7 outdegree,mlabel(pays pays) ) (line diagonale outdegree) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_UE==1),  yscale(log) xscale(log) title("indegreee/outdegree price shock, 1995/2011") subtitle("weighted : `n'") xtitle("outdegree") ytitle("indegree") saving($dir/graphiques/graphp_95_2011_`n') 
	graph export $dir/graphiques/graphp_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						

*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree2 Zone euro pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------


foreach n of local poids{

	egen mini=min(indegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	egen maxi=max(indegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	gen diagonale=outdegree2 if (outdegree2<maxi & outdegree2>mini)
		
	graph twoway (scatter indegree1 indegree7 outdegree2,mlabel(pays pays) ) (line diagonale outdegree2) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_UE==1),  yscale(log) xscale(log) title("indegreee/outdegree2 price shock, 1995/2011") subtitle("weighted : `n'") xtitle("outdegree") ytitle("indegree") saving($dir/graphiques/graphp2_95_2011_`n') 
	graph export $dir/graphiques/graphp2_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						
*-------------------------------------------------------------------------------
* graphiques in-degree par taille, avec une droite de régression
*-------------------------------------------------------------------------------

local poids "X Yt"
local deg "indegree outdegree outdegree2"

foreach d of local deg{
	foreach n of local poids{

		foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
		
			reg `d' `n' if (weight=="`n'" & shock_type=="p" & year==`i' )
			predict `d'_chap_`n'_`i'
			graph twoway (scatter `d'  `n',mlabel(pays pays)) (line `d'_chap_`n'_`i' `n') if (weight=="`n'" & shock_type=="p" & year==`i' & dum_UE==1),  title("`d'/weight price choc, `i'") subtitle("weighted : `n'") xtitle("poids `n'") ytitle("`d'")  saving($dir/graphiques/graphp_`d'_`i'_`n') 
			*yscale(log) xscale(log)   || lfit `d' `n'   & dum_UE==1
			graph export $dir/graphiques/graphp_`d'_`i'_`n'.pdf
		}
	}
}				

