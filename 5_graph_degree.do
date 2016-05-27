clear
set more off
set matsize 7000

global dir "H:\Agents\Cochard\Papier_chocCVA"

cd "$dir"
use "$dir\Bases\Degrees\degrees.dta"


*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------


local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

		graph twoway scatter indegree outdegree if (weight=="`n'" & shock_type=="p" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/outdegree price choc, `i'") subtitle("weighted : `n'") xtitle("outdegree") ytitle("indegree")  saving($dir\Graphiques\Graphiques_2502/graphp_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphp_`i'_`n'.pdf
	}
}
				
local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 {

		graph twoway scatter indegree outdegree if (weight=="`n'" & shock_type=="w" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("indegreee/outdegree wage choc, `i'") subtitle(" weighted : `n'") xtitle("outdegree") ytitle("indegree") saving($dir/Graphiques\Graphiques_2502/graphw_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphw_`i'_`n'.pdf
		
	}
}

*-------------------------------------------------------------------------------
* graphiques pin-degree/pout-degree Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------


local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

		graph twoway scatter pindegree poutdegree if (weight=="`n'" & shock_type=="p" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("pindegreee/poutdegree price choc, `i'") subtitle("weighted : `n'") xtitle("poutdegree") ytitle("pindegree")  saving($dir\Graphiques\Graphiques_2502/graphpp_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphpp_`i'_`n'.pdf
	}
}
				
local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 {

		graph twoway scatter pindegree poutdegree if (weight=="`n'" & shock_type=="w" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("pindegreee/poutdegree wage choc, `i'") subtitle(" weighted : `n'") xtitle("poutdegree") ytitle("pindegree") saving($dir/Graphiques\Graphiques_2502/graphwp_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphwp_`i'_`n'.pdf
		
	}
}

*-------------------------------------------------------------------------------
* graphiques pin-degree_chap/pout-degree_chap Zone euro pour chaque année, chaque matrice
*-------------------------------------------------------------------------------


local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

		graph twoway scatter pindegree_chap poutdegree_chap if (weight=="`n'" & shock_type=="p" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("pindegreee_chap/poutdegree_chap price choc, `i'") subtitle("weighted : `n'") xtitle("poutdegree_chap") ytitle("pindegree_chap")  saving($dir\Graphiques\Graphiques_2502/graphchap_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphpchap_`i'_`n'.pdf
	}
}
				
local poids "X Yt"
foreach n of local poids{

	foreach i of numlist 1995 2000 2005 {

		graph twoway scatter pindegree_chap poutdegree_chap if (weight=="`n'" & shock_type=="w" & year==`i' & dum_GP==1), mlabel(pays) yscale(log) xscale(log) title("pindegreee_chap/poutdegree_chap wage choc, `i'") subtitle(" weighted : `n'") xtitle("poutdegree_chap") ytitle("pindegree_chap") saving($dir/Graphiques\Graphiques_2502/graphwchap_`i'_`n') 
		graph export $dir/Graphiques\Graphiques_2502/graphwchap_`i'_`n'.pdf
		
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
		
	graph twoway (scatter indegree1 indegree7 outdegree,mlabel(pays pays) ) (line diagonale outdegree) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_GP==1),  yscale(log) xscale(log) title("indegreee/outdegree price shock, 1995/2011") subtitle("weighted : `n'") xtitle("outdegree") ytitle("indegree") saving($dir/Graphiques\Graphiques_2502/graphp_95_2011_`n') 
	graph export $dir/Graphiques\Graphiques_2502/graphp_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						

*-------------------------------------------------------------------------------
* graphiques pin-degree/pout-degree Zone euro pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------

tostring year, replace
separate pindegree, by(year)

local poids "X Yt"

foreach n of local poids{

	egen mini=min(pindegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	egen maxi=max(pindegree) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	gen diagonale=poutdegree if (poutdegree<maxi & poutdegree>mini)
		
	graph twoway (scatter pindegree1 pindegree7 poutdegree,mlabel(pays pays) ) (line diagonale poutdegree) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_GP==1),  yscale(log) xscale(log) title("pindegreee/poutdegree price shock, 1995/2011") subtitle("weighted : `n'") xtitle("poutdegree") ytitle("pindegree") saving($dir/Graphiques\Graphiques_2502/graphp2_95_2011_`n') 
	graph export $dir/Graphiques\Graphiques_2502/graphp2_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						
						
*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Zone euro pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------


tostring year, replace
separate pindegree_chap, by(year)

local poids "X Yt"
foreach n of local poids{

	egen mini=min(pindegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	egen maxi=max(pindegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	gen diagonale=poutdegree_chap if (poutdegree<maxi & poutdegree_chap>mini)
		
	graph twoway (scatter pindegree_chap1 pindegree_chap7 poutdegree_chap,mlabel(pays pays) ) (line diagonale poutdegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_ZE==1),  yscale(log) xscale(log) title("pindegree_chap/poutdegree_chap price shock, 1995/2011") subtitle("weighted : `n'") xtitle("poutdegree_chap") ytitle("pindegree_chap") saving($dir/Graphiques\Graphiques_2502/graphpZE_95_2011_`n') 
	graph export $dir/Graphiques\Graphiques_2502/graphpZE_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						
*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree Grands Pays pour 1995/2011, chaque matrice
*-------------------------------------------------------------------------------


tostring year, replace
separate pindegree_chap, by(year)

local poids "X Yt"
foreach n of local poids{

	egen mini=min(pindegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	egen maxi=max(pindegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995" | year=="2011"))
	gen diagonale=poutdegree_chap if (poutdegree<maxi & poutdegree_chap>mini)
		
	graph twoway (scatter pindegree_chap1 pindegree_chap7 poutdegree_chap,mlabel(pays pays) ) (line diagonale poutdegree_chap) if (weight=="`n'" & shock_type=="p" & (year=="1995"|year=="2011") & dum_GP==1),  yscale(log) xscale(log) title("pindegree_chap/poutdegree_chap price shock, 1995/2011") subtitle("weighted : `n'") xtitle("poutdegree_chap") ytitle("pindegree_chap") saving($dir/Graphiques\Graphiques_2502/graphp_95_2011_`n') 
	graph export $dir/Graphiques\Graphiques_2502/graphp_95_2011_`n'.pdf
		
	drop mini
	drop maxi
	drop diagonale								
						}
						

				
*-------------------------------------------------------------------------------
* graphiques in-degree par taille, avec une droite de régression
*-------------------------------------------------------------------------------

local poids "X Yt"
local deg "indegree outdegree poutdegree pindegree"

foreach d of local deg{
	foreach n of local poids{

		foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
		
			reg `d' `n' if (weight=="`n'" & shock_type=="p" & year==`i' )
			predict `d'_chap_`n'_`i'
			graph twoway (scatter `d'  `n',mlabel(pays pays)) (line `d'_chap_`n'_`i' `n') if (weight=="`n'" & shock_type=="p" & year==`i' & dum_GP==1),  title("`d'/weight price choc, `i'") subtitle("weighted : `n'") xtitle("poids `n'") ytitle("`d'")  saving($dir/Graphiques\Graphiques_2502/graphp_`d'_`i'_`n') 
			*yscale(log) xscale(log)   || lfit `d' `n'   & dum_UE==1
			graph export $dir/Graphiques\Graphiques_2502/graphp_`d'_`i'_`n'.pdf
		}
	}
}				

