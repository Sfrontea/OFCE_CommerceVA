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
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/dofiles/OECD`i'.dta", replace
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
*First I sort the ICIO: 
/*
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta", replace
*/
*From the original database I keep only the output vector
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
keep if v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta", replace

*From the original database I keep only the table for inter-industry inter-country trade
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
drop arg_consabr-disc
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_Z.dta", replace

*From the original database I keep only the table for final demand
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
display "`yrs'"
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
	global restcountry "ISL BRN CHN_DOM CHN_NPR CHN_PRO COL CRI HKG HRV KHM MEX_GMF MEX_NGM MYS PHL RoW SAU SGP THA TUN "
*List of all countries
	global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN_DOM CHN_NPR CHN_PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX_GMF MEX_NGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
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
*Note: this is not the same output vector as Y. Indeed O comes from the wage database. For now, I use O for output in this section to distinguish them.

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
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

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

rename v1 c_shock

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta", replace

end

*---------------------------------------------------------------------------------------------
*COMPUTING THE EFFECT OF A SHOCK ON INPUT PRICES IN ONE SECTOR OF ONE COUNTRY ON OUTPUT PRICES
*---------------------------------------------------------------------------------------------
capture program drop vector_shock
program vector_shock
		args shk cty
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"

replace c_shock = `shk' if c == "`cty'"
*Example: c_shock = 0.05 if (c = "ARG" & s == "C01T05")

*I extract vector c_shock from database with mkmat
mkmat c_shock
matrix c_shockt=c_shock'
*The transpose of c_shock will be necessary for further computations

*I compute vector s_shock which is the vector of a shock on wages
matrix c_shockd = diag(c_shock)
matrix s_shock  = c_shockd * S
svmat s_shock
matrix s_shockt = s_shock'

end

capture program drop shock_price
program shock_price
	args cty v
*Multiplying the transpose of vector shock `v'_shockt by L1 to get the impact of a shock on the output price vector
matrix P`cty' = `v'_shockt * L1
*Result example: using c_shock = 0.05 if c == "ARG" & s == "C01T05": if prices in agriculture increase by 5% in Argentina, output prices in the sector of agriculture in Argentina increase by 5.8%

end

*----------------------------------------------------------------------------------
*CREATION OF A VECTOR CONTAINING MEAN EFFECTS OF A SHOCK ON PRICES FOR EACH COUNTRY
*----------------------------------------------------------------------------------
*Creation of the vector of export X
capture program drop compute_X
program compute_X
	args yrs
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
drop arg_c01t05agr-zaf_c95pvh
global country2 "arg aus aut bel bgr bra brn can che chl chn col cri cyp cze deu dnk esp est fin fra gbr grc hkg hrv hun idn ind irl isl isr ita jpn khm kor ltu lux lva mex mlt mys nld nor nzl phl pol prt rou row rus sau sgp svk svn swe tha tun tur twn usa vnm zaf"
foreach i of global country2 {
drop `i'_gfcf
drop `i'_ggfc
drop `i'_hc
drop `i'_invnt
drop `i'_npish
}
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
egen X = rowtotal(arg_consabr-disc)
mkmat X

end

*Creation of the vector of value-added V
capture program drop compute_V
program compute_V
	args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD`yrs'.dta"
keep if v1 == "VA.TAXSUB"
drop v1
mkmat arg_c01t05agr-zaf_c95pvh, matrix(V)
matrix Vt = V'
end

capture program drop compute_mean
program compute_mean
	args cty wgt
set matsize 7000
set more off
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv_`cty'.dta"
matrix Yt = Y'
svmat Yt
svmat X
svmat Vt
*I decide whether I use the production or export or value-added vector as weight modifying the argument "wgt" : Yt or X or Vt
*Compute the vector of mean effects :
matrix P`cty't= P`cty''
svmat P`cty't
generate Bt = P`cty't1* `wgt'
bys c : egen tot_`wgt' = total(`wgt')
generate sector_shock = Bt/tot_`wgt'
bys c : egen shock`cty' = total(sector_shock)

set more off
local country2 "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
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
*yrs = years, wgt = Yt (output) or X (export) or V (value-added), v = c (shock on price) or s (shock on wages)
clear
set matsize 7000
set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country {
	compute_wage `yrs'
	vector_shock `shk' `i'
	shock_price `i' `v'
	compute_xpt `yrs'
	compute_V `yrs'
	compute_mean `i' `wgt'
}
clear
set more off
foreach i of global country {
svmat shock`i'
}
* shockARG1 represents the mean effect of a price shock coming from Argentina for each country
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_`v'_`wgt'_`yrs'.dta", replace
*We obtain a table of mean effect of a price shock from each country to all countries

end



/*
--------------------------------------------------------------------------------
LIST ALL PROGRAMS AND RUN THEM
--------------------------------------------------------------------------------
save_data
prepare_database
compute_leontief
compute_fd
base_wage
compute_wage
database_csv
vector_shock
shock_price
compute_xpt
compute_V
compute_mean
table_mean
table_adjst
*/

/*
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	prepare_database `i'
}

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	compute_leontief `i'
}

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	compute_fd `i'
}

foreach i of numlist 1995 2000 2005 {
	base_wage `i' REM
	base_wage `i' OUT
}

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	table_mean `i' wgt shk c 
}

foreach i of numlist 1995 2000 2005 {
	table_mean `i' wgt shk s
}


*/

save_data
prepare_database 2011
compute_leontief 2011

set more on
log close
