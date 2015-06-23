clear
capture log using C:/Users/L841580/Desktop/I-O-Stan/Stata-Programmes/15_june2.log, replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "C:\Users\L841580\Desktop\I-O-Stan\bases_stata"

*----------------------------------------------------------------------------------
* Programme de construction de la base des rémunérations
*-----------------------------------------------------------------------------------

capture program drop base_rem

program base_rem
	args yrs 
	
local onglet "REM OUT"

foreach n of local onglet {	
	
	import excel "C:\Users\L841580\Desktop\I-O-Stan\REM_`yrs'.xlsx", sheet("`n'") firstrow clear
	save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\`n'_`yrs'.dta", replace

	*Liste des pays pour lesquels on n'a pas les rémunérations, et de l'ensemble des pays
	global restcountry "ISL BRN CHN_DOM CHN_NPR CHN_PRO COL CRI HKG HRV KHM MEX_GMF MEX_NGM MYS PHL RoW SAU SGP THA TUN "
	global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX_GMF MEX_NGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
	global sector "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector2 "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 "
	global sector3 "C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector4 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
	global sector5 "C01T05 C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"


	global listrow
	foreach p of global country {
		foreach s of global sector {
			global listrow $listrow to `p'_`s'
									}
								}

	*On crée une base avec l'ensemble des pays, et des 0 pour les pays pour lesquels on n'a pas de données de rémunération
	foreach i of global restcountry {
			gen `i'=0
									}
	
	order AUS-TUN, alphabetic after (A)

	*On transforme cette base en vecteur colonne, avec une variable Rem, pour les rémunérations 

	foreach i of global country {
			rename `i' country_`i'
	}	

	reshape long country_, i(A) j(country) string
	
	sort country  in 1/2278, stable
	gen `n'=country_
	drop country_

	* On supprime les observation de CHN et MEX qui n'existent pas dans la base ICIO
	foreach i of global sector2 {
	drop if (country=="CHN" & A=="`i'")
	}


	foreach i of global sector3 {
		foreach j in CHN_DOM CHN_NPR CHN_PRO {
			drop if (country=="`j'" & A=="`i'")
		}
	}
	drop if (country=="CHN_PRO" & A=="C01T05")

	*MEXICO 

  
	foreach i of global sector4 { 
	drop if (country == "MEX" & A == "`i'") 
	} 

 
	foreach i of global sector5 { 
		foreach j in MEX_GMF MEX_NGM { 
			drop if (country == "`j'" & A == "`i'") 
		} 
	} 


	save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\`n'_`yrs'.dta", replace
}
end


*--------------------------------------------------------------------------------
* Programme de calcul du vecteur S, la part de la masse salariale dans la production
*---------------------------------------------------------------------------
clear
set matsize 7000
set more off

capture program drop compute_rem

program compute_rem
	args yrs
	
use "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\Rem_1995.dta"
mkmat REM, matrix (R)

*on récupère la production
use "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\out_1995.dta"
mkmat OUT, matrix (X)


matrix Xd=diag(X)
matrix Xd1=invsym(Xd)
matrix S=Xd1*R

*Pour changer les noms des lignes (on peut sans doute faire mieux)
use "C:\Users\L841580\Desktop\I-O-Stan\OECD_1995_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix (N)
matrix Nt=N'
local names : rowfullnames Nt
matrix rownames S = `names'

end

*---------------------------------------------
* On lance les programmes ------------------
*-------------------------------------------

base_rem  1995 
base_OUT  1995 
compute_rem 1995


