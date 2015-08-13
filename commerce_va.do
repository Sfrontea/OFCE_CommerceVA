clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "/Users/sandrafronteau/Documents/Stage_OFCE/Stata"

*-------------------------------------------------------------------------------
* SAVE DATABASE FOR EACH YEAR
*-------------------------------------------------------------------------------
capture program drop save_data
program save_data

clear
*Loop to save data for each year
set more off
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
insheet using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_ICIO_June2015_`i'.csv", clear
*I sort the ICIO: 
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`i'.dta", replace
}

*Same with the database for wages
clear
set more off
local tab "WAGE OUT"
foreach n of local tab{
	foreach i of numlist 1995 2000 2005 {
	clear
	import excel "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/WAGE_`i'.xlsx", sheet("`n'") firstrow
	save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/`n'_`i'.dta", replace
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
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
keep if v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta", replace

*From the ICIO database I keep only the table for inter-industry inter-country trade
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
drop arg_consabr-disc
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_Z.dta", replace

*From the ICIO database I keep only the table for final demand
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
keep arg_consabr-disc
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/finaldemand_`yrs'.dta", replace

end

*-------------------------------------------------------------------------------
*COMPUTING LEONTIEF INVERSE MATRIX
*-------------------------------------------------------------------------------
clear
set more off
set matsize 7000
capture program drop compute_leontief
program compute_leontief
	args yrs
*Create vector Y of output from troncated database
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)

*Create matrix Z of inter-industry inter-country trade
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_Z.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix (Z)

*From vector Y create a diagonal matrix Yd which contains all elements of vector Y on the diagonal
matrix Yd=diag(Y)
*Take the inverse of Yd (with invsym instead of inv for more accurateness and to avoid errors)
matrix Yd1=invsym(Yd)

*Then multiply Yd1 by Z 
matrix A=Z*Yd1

*Create identity matrix at the size we want
mat I=I(2159)

*I-A
matrix L=(I-A)

*Leontief inverse
matrix L1=inv(L)

end

*-------------------------------------------------------------------------------
*COMPUTING THE FINAL DEMAND VECTOR
*-------------------------------------------------------------------------------
capture program drop compute_fd
program compute_fd
	args yrs
*Create a final demand column-vector for all countries with a loop
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/finaldemand_`yrs'.dta"

foreach x in aus aut bel can chl cze dnk est fin fra deu grc hun isl irl isr ita jpn kor lux mex nld nzl nor pol prt svk svn esp swe che tur gbr usa arg bgr bra brn chn col cri cyp hkg hrv idn ind khm ltu lva mlt mys phl rou rus sau sgp tha tun twn vnm zaf row {
mkmat `x'_consabr-`x'_npish
matrix F`x'=(`x'_hc+`x'_npish+`x'_ggfc+`x'_gfcf+`x'_invnt+`x'_consabr)
}
*Then add all F`x' together
foreach j in aus aut bel can chl cze dnk est fin fra deu grc hun isl irl isr ita jpn kor lux mex nld nzl nor pol prt svk svn esp swe che tur gbr usa arg bgr bra brn chn col cri cyp hkg hrv idn ind khm ltu lva mlt mys phl rou rus sau sgp tha tun twn vnm zaf row {
matrix F=Faus+F`j'
}

matrix colnames F = Final_demand
*r1...rN corresponding to each vector per country

end
*-------------------------------------------------------------------------------
*TRIMMING THE DATABASE FOR WAGES
*-------------------------------------------------------------------------------
capture program drop base_wage
program base_wage
	args yrs n
*yrs = years, n = onglet WAGE or OUT
	clear
	use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/`n'_`yrs'.dta"

*List of countries for which there is no data available for wages
	global restcountry "ISL BRN CHN_DOM CHN_NPR CHN_PRO COL CRI HKG HRV KHM MEX_GMF MEX_NGM MYS PHL ROW SAU SGP THA TUN "
*List of all countries
	global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX_GMF MEX_NGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
*Lists of sectors
	global sector "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector2 "C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 "
	global sector3 "C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
	global sector4 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
	global sector5 "C01T05 C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

	foreach i of global restcountry {
			gen `i'=0
									}
									
	order AUS-TUN, alphabetic after (A)

*We reshape the database as a column-vector with a variable REM for wages and OUT for output

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
	
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/`n'_`yrs'.dta", replace
	
end

*-------------------------------------------------------------------------------
*COMPUTING A VECTOR CONTAINING THE WAGE SHARES IN PRODUCTION
*-------------------------------------------------------------------------------
capture program drop compute_wage
program compute_wage
	args yrs
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/WAGE_`yrs'.dta"
mkmat WAGE, matrix (W)
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OUT_`yrs'.dta"
mkmat OUT, matrix (O)
*Note: this is not the same output vector as Y. Indeed O comes from the wage database. For now, I use O for output in this section to distinguish from Y.

matrix Od=diag(O)
matrix Od1=invsym(Od)
matrix S=Od1*W
*S is the column-vector containing the wage shares in production
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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta", replace

end

*---------------------------------------------------------------------------------------------
*COMPUTING THE EFFECT OF A SHOCK ON INPUT PRICES IN ONE SECTOR OF ONE COUNTRY ON OUTPUT PRICES
*---------------------------------------------------------------------------------------------
capture program drop vector_shock_p
program vector_shock_p
		args shk cty
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"


replace p_shock = `shk' if c == "`cty'"
*Example: p_shock = 0.05 if (c = "ARG" & s == "C01T05")

*I extract vector p_shock from database with mkmat
mkmat p_shock
matrix p_shockt=p_shock'
*The transpose of p_shock will be necessary for further computations

end

capture program drop vector_shock_w
program vector_shock_w
*I compute vector w_shock which is the vector of a shock on wages
	args shk cty
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"
replace p_shock = `shk' if c == "`cty'"
mkmat p_shock
matrix p_shockd = diag(p_shock)
matrix w_shock  = p_shockd * S
svmat w_shock
matrix w_shockt = w_shock'

end

capture program drop shock_price
program shock_price
	args cty v
*Multiplying the transpose of vector shock `v'_shockt by L1 to get the impact of a shock on the output price vector
matrix P`cty' = `v'_shockt * L1
*Result example: using p_shock = 0.05 if c == "ARG" & s == "C01T05": if prices in agriculture increase by 5% in Argentina, output prices in the sector of agriculture in Argentina increase by 5.8%

end

*----------------------------------------------------------------------------------
*CREATION OF A VECTOR CONTAINING MEAN EFFECTS OF A SHOCK ON PRICES FOR EACH COUNTRY
*----------------------------------------------------------------------------------
*Creation of the vector Y is required before table_adjst if not done already
capture program drop create_y
program create_y
args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'

end

*Creation of the vector of export X
capture program drop compute_X
program compute_X
	args yrs

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta", clear

global country2 "arg aus aut bel bgr bra brn can che chl chn chn.npr chn.pro chn.dom col cri cyp cze deu dnk esp est fin fra gbr grc hkg hrv hun idn ind irl isl isr ita jpn khm kor ltu lux lva mex mex.ngm mex.gmf mlt mys nld nor nzl phl pol prt rou row rus sau sgp svk svn swe tha tun tur twn usa vnm zaf"

generate pays = strlower(substr(v1,1,strpos(v1,"_")-1))
drop if pays==""

egen utilisations = rowtotal(aus_c01t05agr-disc)
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
mkmat X

end

*Creation of the vector of value-added VA
capture program drop compute_VA
program compute_VA
	args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
keep if v1 == "VA.TAXSUB"
drop v1
mkmat arg_c01t05agr-zaf_c95pvh, matrix(VA)
matrix VAt = VA'
end

capture program drop compute_mean
program compute_mean
	args cty wgt
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"
matrix Yt = Y'
svmat Yt
svmat X
svmat VAt
*I decide whether I use the production or export or value-added vector as weight modifying the argument "wgt" : Yt or X or VAt
*Compute the vector of mean effects :
matrix P`cty't= P`cty''
svmat P`cty't
generate Bt = P`cty't1* `wgt'
bys c : egen tot_`wgt' = total(`wgt')
generate sector_shock = Bt/tot_`wgt'
bys c : egen shock`cty' = total(sector_shock)

set more off
local country2 "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
local sector6 "C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach i of local country2 {
	foreach j of local sector6 {
		drop if (c == "`i'" & s == "`j'")
	}
}

local sector7 "C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach j of local sector7 {
	drop if (c == "CHN" & s == "`j'")
}

set more off
local sector8 "C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
local country3 "CHNDOM CHNNPR"
foreach i of local country3 {
	foreach j of local sector8 {
		drop if (c == "`i'" & s == "`j'")
	}
} 

local sector9 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
foreach j of local sector9 {
	drop if (c == "CHNPRO" & s == "`j'")
}

local sector10 "C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach j of local sector10 {
	drop if (c == "MEX" & s == "`j'")
}

set more off
local sector11 "C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
local country4 "MEXGMF MEXNGM"
foreach i of local country4 {
	foreach j of local sector11 {
	drop if (c == "`i'" & s == "`j'")
	}
}

mkmat tot_`wgt'
mkmat shock`cty'

*Vector shock`cty' contains the mean effects of a shock on prices (coming from the country `cty') on overall prices for each country

end

*----------------------------------------------------------------------------------------------------
*CREATION OF THE TABLE CONTAINING THE MEAN EFFECT OF A PRICE SHOCK FROM EACH COUNTRY TO ALL COUNTRIES
*----------------------------------------------------------------------------------------------------
capture program drop table_mean
program table_mean
	args yrs wgt shk v
*yrs = years, wgt = Yt (output) or X (export) or VAt (value-added), v = p (shock on price) or w (shock on wages)
clear
set matsize 7000
set trace on
set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country {
	vector_shock_`v' `shk' `i'
	shock_price `i' `v'
	compute_X `yrs'
	compute_VA `yrs'
	compute_mean `i' `wgt'
}
clear
set more off
foreach i of global country {
svmat shock`i'
}

* shockARG1 represents the mean effect of a price shock coming from Argentina for each country
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta", replace
*We obtain a table of mean effect of a price shock from each country to all countries

export excel using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.xls", firstrow(variables)

set trace off
set more on

end

*-------------------------------------------------------------------------------
*DEVALUATION OF THE EURO
*-------------------------------------------------------------------------------
*What happens when the euro is devaluated? To know that, we do a shock of 1 on all countries but the eurozone.
capture program drop shock_deval
program shock_deval
	args shk

set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

local eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
local noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CZE DNK GBR HKG HRV HUN UDN UND ISL ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"

foreach i of local noneuro{
replace p_shock = `shk' if c == "`i'"
}

*I extract vector p_shock from database with mkmat
mkmat p_shock
matrix p_shockt=p_shock'
*The transpose of p_shock will be necessary for further computations
*Must compute L1 for 2011 before going on
*Multiplying the transpose of vector shock `v'_shockt by L1 to get the impact of a shock on the output price vector
matrix P = p_shockt * L1

end

capture program drop create_y
program create_y
	args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'
end

capture program drop compute_mean
program compute_mean
	args wgt
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"
matrix Yt = Y'
svmat Yt
*svmat X

*I decide whether I use the production or export or value-added vector as weight modifying the argument "wgt" : Yt or X or VAt
*Compute the vector of mean effects :
matrix Pt= P'
svmat Pt
generate Bt = Pt1* `wgt'
bys c : egen tot_`wgt' = total(`wgt')
generate sector_shock = Bt/tot_`wgt'
bys c : egen shock = total(sector_shock)

set more off
local country2 "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
local sector6 "C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach i of local country2 {
	foreach j of local sector6 {
		drop if (c == "`i'" & s == "`j'")
	}
}

local sector7 "C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach j of local sector7 {
	drop if (c == "CHN" & s == "`j'")
}

set more off
local sector8 "C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
local country3 "CHNDOM CHNNPR"
foreach i of local country3 {
	foreach j of local sector8 {
		drop if (c == "`i'" & s == "`j'")
	}
} 

local sector9 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
foreach j of local sector9 {
	drop if (c == "CHNPRO" & s == "`j'")
}

local sector10 "C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"
foreach j of local sector10 {
	drop if (c == "MEX" & s == "`j'")
}

set more off
local sector11 "C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"
local country4 "MEXGMF MEXNGM"
foreach i of local country4 {
	foreach j of local sector11 {
	drop if (c == "`i'" & s == "`j'")
	}
}

mkmat tot_`wgt'
mkmat shock

*Vector shock`cty' contains the mean effects of a shock on prices (coming from the country `cty') on overall prices for each country

end
*--------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*--------------------------------------------------------------------------------
/*
clear
set more off
database_csv

foreach i of numlist 2009 2010 2011{
	compute_leontief `i'
	foreach j in X {
		table_mean `i' `j' 1 p
	}
}


clear matrix
set more off
database_csv
foreach i of numlist 1995 2000 2005{
	clear
	compute_leontief `i'
	compute_wage `i'
	foreach j in Yt X {
		table_mean `i' `j' 4 w
	}
}

compute_leontief 2011
shock_deval 1
create_y 2011
compute_mean Yt

*/

set more on
log close
