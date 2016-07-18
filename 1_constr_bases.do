clear



if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"
if ("`c(username)'"=="L841580") global dir "H:/Agents/Cochard/Papier_chocCVA"




capture log using "$dir/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off


*-------------------------------------------------------------------------------
* SAVE DATABASE FOR EACH YEAR
*-------------------------------------------------------------------------------
capture program drop save_data
program save_data

clear
*Loop to save data for each year
set more off
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
insheet using "$dir/Bases/ICIO/OECD_ICIO_June2015_`i'.csv", clear
*I sort the ICIO: 
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
save "$dir/Bases/OECD`i'.dta", replace
}

*Same with the database for wages
clear
set more off
local tab "WAGE OUT"
foreach n of local tab{
	foreach i of numlist 1995 2000 2005 {
	clear
	import excel "$dir/Bases/ICIO/WAGE_`i'.xlsx", sheet("`n'") firstrow
	keep A-VNM
	drop if A == ""
	save "$dir/Bases/`n'_`i'.dta", replace
	}
}

end

*-------------------------------------------------------------------------------
*TRIMMING THE DATABASE ICIO
*-------------------------------------------------------------------------------
capture program drop prepare_database
program prepare_database
	args yrs 

*From the ICIO database I keep only the output vector
use "$dir/Bases/OECD`yrs'.dta"
keep if v1 == "OUT"
drop v1
drop arg_consabr-disc
save "$dir/Bases/OECD_`yrs'_OUT.dta", replace

*From the ICIO database I keep only the table for inter-industry inter-country trade
clear
use "$dir/Bases/OECD`yrs'.dta"
drop arg_consabr-disc
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
drop v1
save "$dir/Bases/OECD_`yrs'_Z.dta", replace

*From the ICIO database I keep only the table for final demand
clear
use "$dir/Bases/OECD`yrs'.dta"
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
keep arg_consabr-disc
save "$dir/Bases/finaldemand_`yrs'.dta", replace

end



*-------------------------------------------------------------------------------
*TRIMMING THE DATABASE FOR WAGES
*-------------------------------------------------------------------------------
capture program drop base_wage
program base_wage
	args yrs n
*yrs = years, n = onglet WAGE or OUT
	clear
	use "$dir/Bases/`n'_`yrs'.dta"

*List of countries for which there is no data available for wages
	global restcountry "ISL BRN COL CRI HKG HRV KHM MEX_GMF MEX_NGM MYS PHL ROW SAU SGP THA TUN "
	global chncountry "CHN_DOM CHN_NPR CHN_PRO"

*List of all countries
	global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX_GMF MEX_NGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
*Lists of sectors
	global sector "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector2 "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 "
	global sector3 "C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector4 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
	global sector5 "C01T05 C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

	foreach i of global chncountry {
			gen `i'=CHN
									}

	
	foreach i of global restcountry {
			gen `i'=0
									}
									
	order AUS-TUN, alphabetic after (A)

*We reshape the database as a column-vector with a variable WAGE for wages and OUT for output

	foreach i of global country {
			rename `i' country_`i'
	}	

	reshape long country_, i(A) j(country) string
	
	sort country  in 1/2278, stable
	rename country_ `n'
	
*We delete observations for CHN and MEX that do not exist in the ICIO

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
	
save "$dir/Bases/`n'_`yrs'.dta", replace
	
end


*----------------------------------------------------------------------------------
*BUILDING A DATABASE WITH VECTORS OF COUNTRIES AND SECTORS AND VECTOR CONTAINING 0
*----------------------------------------------------------------------------------
capture program drop database_csv
program database_csv

clear
set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

generate c = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/34 {
		local new = _N + 1
		set obs `new'
		local ligne = `j' + 34*`num_pays'
		replace c = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

global sector "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

generate s =""
local num_sector 0
foreach i of global sector {
	forvalues j = 1(34)2278 {
		local ligne = `j' + 1*`num_sector'
		replace s = "`i'" in `ligne'
	}
	local num_sector = `num_sector'+1
}

gen v1=0

*I withdraw the industries for different types of CHN and MEX that are not in the dataset from v1

*CHINA
global sector2 "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"

foreach i of global sector2 {
drop if (c == "CHN" & s == "`i'")
}

global sector3 "C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

foreach i of global sector3 {
	foreach j in CHNDOM CHNNPR CHNPRO {
		drop if (c == "`j'" & s == "`i'")
	}
}

drop if (c == "CHNPRO" & s == "C01T05")

*MEXICO
global sector4 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"

foreach i of global sector4 {
drop if (c == "MEX" & s == "`i'")
}


global sector5 "C01T05 C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

foreach i of global sector5 {
	foreach j in MEXGMF MEXNGM {
		drop if (c == "`j'" & s == "`i'")
	}
}

rename v1 p_shock

save "$dir/Bases/csv.dta", replace

end




***************************************************************************************************
* 1- Création des tables Y de production : on crée le vecteur 1*67 des productions totales de chauqe pays
***************************************************************************************************

capture program drop compute_y
program compute_y
args yrs

/*Y vecteur de production*/ 
clear
use "$dir/Bases/OECD_`yrs'_OUT.dta"
*drop arg_consabr-disc
rename * prod*
generate year = `yrs'
reshape long prod, i(year) j(pays_sect) string
generate pays = strupper(substr(pays_sect,1,strpos(pays_sect,"_")-1))
collapse (sum) prod, by(pays year)

end 

capture program drop append_y
program append_y

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_y `i'
	if `i'!=1995 {
		append using "$dir/Bases/prod.dta"
				}
	save "$dir/Bases/prod.dta", replace
	}
sort year , stable
end

***************************************************************************************************
* 2- Création des tables X d'exportations : on crée le vecteur 1*67 des productions totales de chauqe pays
***************************************************************************************************

*Creation of the vector of export X
capture program drop compute_X
program compute_X
	args yrs

use "$dir/Bases/OECD`yrs'.dta", clear

global country2 "arg aus aut bel bgr bra brn can che chl chn chn.npr chn.pro chn.dom col cri cyp cze deu dnk esp est fin fra gbr grc hkg hrv hun idn ind irl isl isr ita jpn khm kor ltu lux lva mex mex.ngm mex.gmf mlt mys nld nor nzl phl pol prt rou row rus sau sgp svk svn swe tha tun tur twn usa vnm zaf"

generate pays = strlower(substr(v1,1,strpos(v1,"_")-1))
drop if pays==""

egen utilisations = rowtotal(arg_c01t05agr-disc)
gen utilisations_dom = .

foreach j of global country2 {
	local i = "`j'"
	if  ("`j'"=="chn.npr" | "`j'"=="chn.pro" |"`j'"=="chn.dom" ) {
		local i = "chn" 
	}
	if  ("`j'"=="mex.ngm" | "`j'"=="mex.gmf") {
			local i = "mex"
	}
	egen blouk = rowtotal(`i'*)
	display "`i'" "`j'"
	replace utilisations_dom = blouk if pays=="`j'"
	codebook utilisations_dom if pays=="`j'"
	drop blouk
}
generate X = utilisations - utilisations_dom
	
replace pays = strupper(pays)
generate year = `yrs'
keep year pays X
collapse (sum) X, by(pays year)

end


capture program drop append_X
program append_X
*We create a .dta that includes all vectors of export of all years
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_X `i'
	if `i'!=1995 {
	append using "$dir/Bases/exports.dta" 
	}
	save "$dir/Bases/exports.dta", replace
}	

replace pays = "CHNNPR" if pays == "CHN.NPR"
replace pays = "CHNPRO" if pays == "CHN.PRO"
replace pays = "CHNDOM" if pays == "CHN.DOM"
replace pays = "MEXNGM" if pays == "MEX.NGM"
replace pays = "MEXGMF" if pays == "MEX.GMF"
 
sort year , stable
save "$dir/Bases/exports.dta", replace
 

end


**** Lancement des programmes ****************

save_data 

foreach i of numlist 1995 2000 2005{
	clear
	prepare_database `i'
}

foreach i of numlist 2008 2009 2010 2011 {
	clear
	prepare_database `i'
}



foreach i of numlist 1995 2000 2005 {
	foreach n in WAGE OUT {
		clear
		base_wage  `i'  `n'
		}
}



database_csv

set more off
append_y
append_X
