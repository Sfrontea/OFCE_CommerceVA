clear
capture log using C:/Users/L841580/Desktop/I-O-Stan/Stata-Programmes/15_june2.log, replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "C:\Users\L841580\Desktop\I-O-Stan\bases_stata"

*Loop to save data for each database year 1995 2000 2005 2008 2009 2010 2011
foreach i of numlist  1995 {
import excel "C:\Users\L841580\Desktop\I-O-Stan\Rem_`i'.xlsx", sheet("`i'") firstrow clear
save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\Rem_`i'.dta", replace
}


*Liste des pays pour lesquels on n'a pas les rémunérations, et de l'ensemble des pays
global restcountry "ARG BGR BRA BRN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP HKG HRV IDN IND KHM LTU LVA MEX_GMF MEX_NGM MLT MYS PHL ROU RoW RUS SAU SGP THA TUN TUR TWN VNM ZAF"
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX_GMF MEX_NGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
global sector "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

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
	
order AUS-ZAF, alphabetic after (A)

*On transforme cette base en vecteur colonne, avec une variable Rem, pour les rémunérations 

foreach i of global country {
		rename `i' country_`i'
}	

reshape long country_, i(A) j(country) string
	
sort country  in 1/2278, stable
gen Rem=country_
drop country_

drop in 341/358
drop in 375/390
drop in 393/408
drop in 393
drop in 410/425

drop in 1330/1345
drop in 1346/1347
drop in 1362/1377
drop in 1362/1363
drop in 1378/1393


save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\Rem_1995.dta", replace



*On calcule dans le veteur S, la part de la masse salariale dans la production
*on récupère les rémunération
clear
set matsize 7000
set more off
use "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\Rem_1995.dta"
mkmat Rem, matrix (R)

*on change les noms des lignes dans Rem


*on récupère la production
use "C:\Users\L841580\Desktop\I-O-Stan\OECD_1995_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix (X)

matrix Xd=diag(X)
matrix Xd1=invsym(Xd)

local names : rowfullnames Xd
matrix rownames R = `names'

matrix S=Xd1*R

