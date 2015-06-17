clear
capture log using "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata"

*Loop to save data for each database year
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
insheet using "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/OECD_ICIO_June2015_`i'.csv", clear
save "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/dofiles/OECD`i'.dta", replace
}

*-------------------------------------------------------------------------------
*TRIMMING THE DATABASE TO CONVERT TABLES INTO MATRICES
*-------------------------------------------------------------------------------
capture program drop prepare_database
program prepare_database
	*args yrs 

*From the original database I keep only the output vector
clear
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/dofiles/OECD2011.dta"
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
keep if v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/OECD_2011_OUT.dta", replace
*From the original database I keep only the table for inter-industry inter-country trade
clear
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/dofiles/OECD2011.dta"
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
drop arg_consabr-disc
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
drop v1
save "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/OECD_2011_Z.dta", replace
*From the original database I keep only the table for final demand
clear
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/dofiles/OECD2011.dta"
sort v1 aus_c01t05agr-disc in 1/2159
order aus_c01t05agr-row_c95pvh, alphabetic after (v1)
order aus_hc-row_consabr, alphabetic after (zaf_c95pvh)
drop if v1 == "VA.TAXSUB" | v1 == "OUT"
keep arg_consabr-disc
save "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/finaldemand_2011.dta", replace

end

*-------------------------------------------------------------------------------
*COMPUTING LEONTIEF INVERSE MATRIX
*-------------------------------------------------------------------------------
capture program drop compute_leontief
program compute_leontief
	*args yrs
*Create vector X of output from troncated database
clear
set more off
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/OECD_2011_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(X)

*Create matrix Z of inter-industry inter-country trade
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/OECD_2011_Z.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix (Z)

*From vector X create a diagonal matrix Xd which contains all elements of vector X on the diagonal
matrix Xd=diag(X)
*Take the inverse of Xd (with invsym instead of inv for more accurateness and to avoid errors)
matrix Xd1=invsym(Xd)

*Then multiply Xd1 by Z 
matrix A=Z*Xd1

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
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/finaldemand_`yrs'.dta"

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

*----------------------------------------------------------------------------------
*BUILDING A DATABASE WITH VECTORS OF COUNTRIES AND SECTORS AND VECTOR CONTAINING 0
*----------------------------------------------------------------------------------
capture program drop database_csv
program database_csv

clear
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHN.DOM CHN.NPR CHN.PRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEX.GMF MEX.NGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

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
	foreach j in CHN.DOM CHN.NPR CHN.PRO {
		drop if (c == "`j'" & s == "`i'")
	}
}

drop if (c == "CHN.PRO" & s == "C01T05")

*MEXICO
global sector4 "C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30T33X C31 C34 C35 C36T37"

foreach i of global sector4 {
drop if (c == "MEX" & s == "`i'")
}


global sector5 "C01T05 C10T14 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73T74 C75 C80 C85 C90T93 C95"

foreach i of global sector5 {
	foreach j in MEX.GMF MEX.NGM {
		drop if (c == "`j'" & s == "`i'")
	}
}

save "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/csv.dta", replace

end

*---------------------------------------------------------------------------------------------
*COMPUTING THE EFFECT OF A SHOCK ON INPUT PRICES IN ONE SECTOR OF ONE COUNTRY ON OUTPUT PRICES
*---------------------------------------------------------------------------------------------

capture program drop vector_shock
program vector_shock

clear
use "/Users/sandrafronteau/Desktop/Stage_OFCE/Stata/data/ocde/csv.dta"

*args shk cty scr
replace v1 = 0.05 if (c == "ARG" & s == "C01T05")

*Example: v1 = 0.05 if c = "ARG" & s == "C01T05"

*I extract vector v1 from database with mkmat
mkmat v1
matrix v1t=v1'

end

*Multiplying v1t by L1 to get the impact of a shock on the price vector
matrix P = v1t * L1
matrix list P
*Result example: if prices in agriculture increase by 5% in Argentina, output prices in the sector of agriculture in Argentina increase by 5.8%

*replace v1 = 0 if (c == "ARG" & s == "C01T05")
*replace v1 = 0.02 if (c == "DEU" & s == "C29")
*mkmat v1
*matrix v1t=v1'
*matrix P = v1t * L1
*matrix list P
*Result example: if prices in input machinery and equipment increase by 2% in Germany, then prices of output machinery and equipment increase by 2.35% in Germany and by 0.032212% in France.

*-------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*-------------------------------------------------------------------------------
*prepare_database
*compute_leontief
*compute_fd
*database_csv
*vector_shock

set more on
log close
