clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off

*-------------------------------------------------------------------------------
*TO USE ONLY IF table_adjst IS RUN SEPARATELY FROM table_mean
*-------------------------------------------------------------------------------
*Creation of the vector Y is required before table_adjst
capture program drop create_y
program create_y
args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'


end

*Creation of the vector X is required before table_adjst
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

*Creation of the vector VA is required before table_adjst
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

*Compute tot_`wgt' : wgt = Yt or VAt or X

capture program drop compute_totwgt
program compute_totwgt
args wgt
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/csv.dta"
svmat `wgt'
sort c s-`wgt'1
bys c : egen tot_`wgt' = total(`wgt')

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

end

*----------------------------------------------------------------------------------
*ADJUSTMENT OF THE TABLE OF MEAN EFFECTS OF A PRICE SHOCK TO REMOVE THE SIZE EFFECT
*----------------------------------------------------------------------------------
capture program drop table_adjst
program table_adjst
args v wgt yrs
* yrs = years, wgt = weight : Yt (production) or VAt (value-added) or X (export), v = vector of shock : p (price) or w (wage)
*This program uses the formula : effect shock in a country shocked * Weight of Germany / Weight of the country cause of shock. It creates a new matrix corrected from the size effect. It is like if all countries had the size of Germany.
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta"
*use the matrix of mean effects

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

*generate k : it's a column with all names for countries. I create this column as a tool for computation in Stata.
generate k = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace k = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

svmat tot_`wgt'
*I take tot_weight which is 67*1. For example, is a column of total production by country.

*I extract the total weight of Germany (ex: production) and create a column 67*1 with the total weight of Germany repeated 67 times.
gen `wgt'DEU = tot_`wgt'1 if k == "DEU"
replace `wgt'DEU = `wgt'DEU[19] if missing(`wgt'DEU)

*I compute a column which is the weight part of the formula : weight of Germany / weight of country cause of shock
gen B = `wgt'DEU/tot_`wgt'

*Saved as a vector in Stata's matrix memory
mkmat B

*I extract each element of B as a scalar to multiply by each element of the matrix of the mean effect. This create a whole new corrected matrix of mean effects.
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1*`num_pays'
		scalar b`i' = B[`ligne',1]
		gen shock`i'= b`i' * shock`i'1
	}
local num_pays = `num_pays'+1
}

*I drop the former non-corrected matrix and all intermediate columns of computation
drop shockARG1-shockZAF1
drop tot_`wgt'1
drop `wgt'DEU
drop B
drop k

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country{
	rename shock`i' shock`i'1
}

*Corrected matrices of mean effects are identified as : "_cor" 
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'_cor.dta", replace
 
export excel using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'_cor.xls", firstrow(variables) replace


end

*-------------------------------------------------------------------------------
*RESHAPE TABLES OF MEAN EFFECT .dta
*-------------------------------------------------------------------------------
capture program drop reshape_mean
program reshape_mean
args yrs wgt v _cor
* yrs = years, wgt = weight : Yt (production) or VAt (value-added) or X (export), v = vector of shock : p (price) or w (wage), _cor : either type _cor if use corrected from size effect matrix or put nothing if use the non-corrected one

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'`_cor'.dta"
set more off

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

generate k = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace k = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

order shockARG-shockZAF, alphabetic after (k)
reshape long shock, i(k) j(cause) string
rename k effect
order cause, first
sort cause effect-shock

gen shock_type = "`v'"
gen weight = "`wgt'"
gen year = "`yrs'"
gen cor = "`_cor'"
replace cor = "yes" if cor =="_cor"
replace cor = "no" if cor ==""

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'`_cor'_2.dta", replace

end


*-------------------------------------------------------------------------------
*APPEND ALL TYPES OF TABLES OF MEAN EFFECT TO CREATE A GLOBAL TABLE
*-------------------------------------------------------------------------------
capture program drop append_mean
program append_mean
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_Yt_1995_2.dta"
replace cause = subinstr(cause,"1","",.)

append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_X_1995_2.dta"

foreach i of numlist 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`j'_`i'_2.dta"
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_w_`j'_`i'_2.dta"
	}
}

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`j'_`i'_cor_2.dta"
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_w_`j'_`i'_cor_2.dta"
	}
}

replace cause = subinstr(cause,"1","",.)
replace cor = "yes" if cor =="_cor"
replace cor = "no" if cor ==""

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta", replace

end 

*-------------------------------------------------------------------------------
*COMPUTE A MEASURE OF DENSITY TO COMPARE MEAN_EFFECT MATRICES
*-------------------------------------------------------------------------------
capture program drop create_nw_p
program create_nw_p
	args wgt yrs cut
*cut : 0.05 : 5% cut on self-loops
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`wgt'_`yrs'.dta"

mkmat shockARG1-shockZAF1, matrix(W)
generate t=trace(W)
generate t2=t/67
generate t3=`cut'*(t2-1)
generate t4=1/t3
mkmat t4

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach h of global country{
	gen shock`h'2 = (1/shock`h'1)
	drop shock`h'1
	rename shock`h'2 shock`h'1
}

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach c of global country{
	replace shock`c'1 = 0 if shock`c'1 > t4
}
	
nwset shockARG1-shockZAF1, name(ME_p_`wgt'_`yrs') labs(ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF)

end


capture program drop create_nw_2
program create_nw_2
	args wgt yrs v _cor
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'`_cor'.dta"

svmat t4

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach h of global country{
	gen shock`h'2 = (1/shock`h'1)
	drop shock`h'1
	rename shock`h'2 shock`h'1
}

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach c of global country{
	replace shock`c'1 = 0 if (shock`c'1 >=.)
}

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach c of global country{
	replace shock`c'1 = 0 if shock`c'1 > t4

}


nwset shockARG1-shockZAF1, name(ME_`v'_`wgt'_`yrs'`_cor') labs(ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF)

nwsummarize ME_`v'_`wgt'_`yrs'`_cor'

end


capture program drop compute_density
program compute_density
	args wgt

*Create a table with density per year for Yt, X, VAt
clear
nwsummarize ME_p_`wgt'_1995 ME_p_`wgt'_2000 ME_p_`wgt'_2005 ME_p_`wgt'_2008 ME_p_`wgt'_2009 ME_p_`wgt'_2010 ME_p_`wgt'_2011 ME_w_`wgt'_1995 ME_w_`wgt'_2000 ME_w_`wgt'_2005 ME_p_`wgt'_1995_cor ME_p_`wgt'_2000_cor ME_p_`wgt'_2005_cor ME_p_`wgt'_2008_cor ME_p_`wgt'_2009_cor ME_p_`wgt'_2010_cor ME_p_`wgt'_2011_cor ME_w_`wgt'_1995_cor ME_w_`wgt'_2000_cor ME_w_`wgt'_2005_cor, save(/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/density`wgt'.dta)
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/density`wgt'.dta"
export excel using "/Users/sandrafronteau/Desktop/density_`wgt'.xls", firstrow(variables)

end

*-------------------------------------------------------------------------------
*PREPARE DATABASE FOR GEPHI
*-------------------------------------------------------------------------------
capture program drop prepare_gephi
program prepare_gephi
args v wgt yrs _cor

*Build a database for edges

clear
nwclear
set more off
create_y `yrs'
compute_X `yrs'
compute_VA `yrs'
compute_totwgt `wgt'
		
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'`_cor'.dta"

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

foreach i of global country{
gen shock`i'2 = shock`i'1*1000
drop shock`i'1
}


mkmat shockARG2-shockZAF2, matrix(W)
nwset shockARG2-shockZAF2, name(ME_`v'_`wgt'_`yrs'`_cor') labs(ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF)


*Transform in edge list
nwtoedge ME_`v'_`wgt'_`yrs'`_cor'
gen Type = "Directed"
rename _fromid Source
rename _toid Target
rename ME_`v'_`wgt'_`yrs'`_cor' Weight

*Now the database is ready to be exported into excel spreadsheet as an edgelist.
export excel using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/edge_`v'_`wgt'_`yrs'`_cor'.xls", firstrow(variables) replace


*Build a database for nodes

clear
set more off
generate Id = ""
local num_pays 0
foreach i of numlist 1/67{
	foreach j of numlist 1/1 {
		local new = _N + 1
		set obs `new'
		local ligne = `j' + 1 *`num_pays'
		replace Id = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
generate Label = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace Label = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

svmat tot_`wgt'
rename tot_`wgt' Weight

export excel using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/node_`v'_`wgt'_`yrs'`_cor'.xls", firstrow(variables) replace

end

*-------------------------------------------------------------------------------
*CORRELATION BETWEEN MATRICES
*-------------------------------------------------------------------------------
capture program drop compute_corr
program compute_corr
	args v1 v2 wgt1 wgt2 yrs1 yrs2
clear
set more off
set matsize 7000
*2.dta obtained from program reshape_mean
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v1'_`wgt1'_`yrs1'_2.dta"
mkmat shock, matrix (`v1'_`wgt1'_`yrs1')
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v2'_`wgt2'_`yrs2'_2.dta"
mkmat shock, matrix (`v2'_`wgt2'_`yrs2')
clear
svmat `v1'_`wgt1'_`yrs1'
svmat `v2'_`wgt2'_`yrs2'
correlate `v1'_`wgt1'_`yrs1' `v2'_`wgt2'_`yrs2'

end
*-------------------------------------------------------------------------------
*COMPUTE WEIGHTED INDEGREE AND OUTDEGREE OF NODES
*-------------------------------------------------------------------------------
***************************************************************************************************
**************************We compute indegrees***********************************************
***************************************************************************************************

capture program drop indegree
program indegree
* We use mean effect non corrected matrices

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor

* We compute the vector of indegrees

collapse (sum) shock, by(effect shock_type-year) 
rename shock indegree
rename effect country

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_indegree.dta", replace

end
***************************************************************************************************
**************************We compute outdegrees***********************************************
***************************************************************************************************


***************************************************************************************************
* 1- Creation of table y of production: we create vector 1*67 of total production by country
***************************************************************************************************
capture program drop compute_Y
program compute_Y
args yrs

/*Y vecteur de production*/ 
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
drop arg_consabr-disc
rename * prod*
generate year = `yrs'
reshape long prod, i(year) j(pays_sect) string
generate pays = strupper(substr(pays_sect,1,strpos(pays_sect,"_")-1))
collapse (sum) prod, by(pays year)

end

capture program drop append_Y
program append_Y

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_Y`i'
	if `i'!=1995 {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta"
	}
	save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta", replace
	
}

end

***************************************************************************************************
* 2- Creation of table X of export: we create vector 1*67 of total export by country
***************************************************************************************************

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
*mkmat X

end

capture program drop append_X
program append_X

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_X `i'
	if `i'!=1995 {
	append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta" 
	}
	save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta", replace
}	

end

*************************************************************************************************************
* 3- We multiply the transposed matrix of weights by the matrix of mean effects and keep the diagonal vector.
*************************************************************************************************************
capture program drop outdegree
program outdegree

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor

rename effect pays
destring year, replace

merge m:1 pays year using prod.dta
drop _merge
sort cause  year  shock_type weight , stable


merge m:1 pays year using exports.dta
drop _merge
rename pays effect

replace prod = 0 if effect==cause
replace X = 0 if effect==cause

bys cause  year  shock_type weight : egen somme_des_poids_P=total(prod)
bys cause  year   shock_type weight : egen somme_des_poids_X=total(X)


gen somme_des_poids=somme_des_poids_P 
replace somme_des_poids=somme_des_poids_X if weight=="X"
drop somme_des_poids_P somme_des_poids_X

gen pond=prod/somme_des_poids
replace pond=X/somme_des_poids if weight=="X"
drop somme_des_poids


gen outdegree=66*pond*shock

collapse (sum) outdegree, by(cause  year  shock_type weight )
rename cause pays
sort year weight shock_type pays   , stable

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_outdegree.dta", replace

end

capture program drop data_degree
program data_degree

/*Build database with indegrees and outdegrees   */

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_outdegree.dta"

merge m:1 year weight shock_type pays using mean_all_indegree.dta
drop _merge
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta", replace


/*weigthed outdegrees*/

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"
sort pays  year  shock_type weight , stable

merge m:1 pays  year  using prod.dta
drop _merge
sort pays  year  shock_type weight , stable


merge m:1 pays  year   using exports.dta
drop _merge

gen wgt_DEU=0
replace wgt_DEU=prod if (weight=="Yt" & pays=="DEU")
replace wgt_DEU=X if (weight=="X" & pays=="DEU")

collapse (sum) wgt_DEU, by(year  shock_type weight )
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/DEU.dta", replace

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"
merge m:1   year  shock_type weight using DEU.dta
drop _merge

merge m:1 pays  year   using prod.dta
drop _merge
sort pays  year  shock_type weight , stable


merge m:1 pays  year  using exports.dta
drop _merge

gen outdegree2=outdegree*wgt_DEU/prod if (weight=="Yt")
replace outdegree2=outdegree*wgt_DEU/prod if (weight=="X")

drop prod X wgt_DEU

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta", replace

*gen `wgt'DEU = tot_`wgt'1 if k == "DEU"

end

capture program drop graph_degree_1
program graph_degree_1

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_inou.dta"
*-------------------------------------------------------------------------------
* cr√©ation dummy zone euro
*-------------------------------------------------------------------------------
global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
replace dum_ZE=1 if (country=="`n'")
}


*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree pour chaque ann√©e, chaque matrice
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

end

capture program drop graph_degree_2
program graph_degree_2

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_inou.dta"

global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
replace dum_ZE=1 if (country=="`n'")
}


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

end

*---------------------------------------------------------------------------------------
*REGRESSION TO BETTER UNDERSTAND THE RELATIONSHIP BETWEEN YEARS AND SHOCK EFFECT
*---------------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*REGRESSION 1
*-------------------------------------------------------------------------------
*This program runs a regression corresponding to the first equation we have : shock ijt = a * e(alpha ij indicator ij) * e(Bt * indicator t) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha ij being the bilateral relationship between two countries, Bt being an indicator for years, epsilon being the error term.
*We run this regression for each type of matrix
capture program drop regress_effect
program regress_effect
	args v wgt
* v -> p or w
*wgt -> Yt or X
clear
set more off
set trace on 
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"

drop if cause == effect
keep if cor == "no"
drop cor
drop if shock==0

keep if shock_type == "p"
keep if weight == "Yt"


gen bilateral = cause+"_"+effect
gen matrix = shock_type+"_"+weight
gen ln_shock = log(shock)

xi i.bilateral i.year

regress ln_shock . regress ln_shock _Ibilateral_2-_Iyear_7
estimates store reg1

outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_p_Yt.xls, replace label 
testparm _Iyear_*, equal

set trace off

end
*-------------------------------------------------------------------------------
*REGRESSION 2
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to the following equation : shock ijt = a * e(alpha i indicator i) * e(alpha j indicator j) *e(g indicator g)* e(Bt r * indicator t r) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha i being the country from which the shock appears, alpha j being the country that receives the shock,
g the type of matrix,  Bt being an indicator for years and r for region, epsilon being the error term. We have one interacted variable : Bt x r
There are 5 regions : the eurozone, the rest of the EU, the region that embraces the relationships between the eurozone and the rest of the EU, the region "rest of the world", and "no", the relationships between Europe and the rest of the world;
Stata sets a reference category for each indicator :
i.cause           _Icause_1-67        (_Icause_2 for cause==AUS omitted)
i.effect          _Ieffect_1-67       (_Ieffect_6 for effect==BRA omitted)
i.matrix          _Imatrix_1-4        (_Imatrix_1 for matrix==p_X omitted)
i.yearregion      _Iyearregio_1-35    (_Iyearregio_15 for yea~n==no_1995 omitted)
*/
capture program drop regress_effect_2
program regress_effect_2

clear all
set maxvar 30000
set matsize 11000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"

drop if cause == effect

drop if cor == "yes"
drop cor

gen ln_shock = log(shock)

*gen type_cause = cause+"_"+shock_type+"_"+weight

*gen type_effect = effect+"_"+shock_type+"_"+weight

gen matrix = shock_type+"_"+weight

gen region = ""
global eurozone "AUT BEL DEU CYP ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
global restEU "BGR CZE DNK GBR HRV HUN NOR POL ROU SWE"
global rest "ARG AUS BRA BRN CAN CHL CHN CHNDOM CHNNPR CHNPRO COL CRI HKG IDN IND ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NZL PHL ROW RUS SAU SGP THA TUN TUR TWN USA VNM ZAF"


set more off
foreach m of global rest{
	foreach n of global rest{
		replace region = "rest" if cause == "`m'" & effect =="`n'"
	}
}


foreach k of global restEU{
	foreach l of global restEU{
		replace region = "restEU" if cause == "`k'" & effect == "`l'"
	}
}

foreach i of global eurozone{
	foreach j of global eurozone{
		replace region = "eurozone" if cause == "`i'" & effect == "`j'"
	}
}

set more off
foreach i of global eurozone{
	foreach j of global restEU{
		replace region = "eurozone_restEU" if cause == "`i'" & effect == "`j'"
		replace region = "eurozone_restEU" if cause == "`j'" & effect == "`i'"
	}
}

replace region = "no" if region == ""

gen yearregion = region+"_"+year

drop if shock==0


char cause[omit]"AUS"
char effect[omit]"BRA"
char yearregion[omit]"no_1995"
xi i.cause i.effect i.matrix i.yearregion

set more off
reg ln_shock _Icause_1-_Iyearregio_35
*reg ln_shock _Itype_caus_3-_Itype_caus_4 _Itype_caus_7-_Itype_effe_268 _Iyearregio_2-_Iyearregio_35
estimates store reg2


outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_2.xls, replace label 

testparm _Iyearregio_*, equal

set more on

end

*-------------------------------------------------------------------------------
*REGRESSION 3
*-------------------------------------------------------------------------------
capture program drop regress_effect_3
program regress_effect_3
/*
This program runs a regression corresponding to the following equation : shock ijt = a * e(alpha i indicator i) * e(alpha j indicator j) *e(g indicator g)* e(Bt r * indicator t r) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha i being the country from which the shock appears, alpha j being the country that receives the shock,
g the type of matrix,  Bt being an indicator for years and r for region, epsilon being the error term. We have one interacted variable : Bt x r
There are 10 regions : ASIA, EU, NAFTA, ROW, EU_ASIA, EU_NAFTA, ASIA_ROW, EU_ROW, ASIA_NAFTA, NAFTA_ROW
We set a reference category for each indicator :
i.cause          cause==AUS omitted
i.effect         effect==BRA omitted
i.matrix         p_X
i.yearregion    EU_ROW_1995, NAFTA_ROW_1995, ROW_1995
*/
clear all
set maxvar 30000
set matsize 11000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"

drop if cause == effect

drop if cor == "yes"
drop cor

drop if shock==0

gen ln_shock = log(shock)

*gen cause_matrix = cause+"_"+shock_type+"_"+weight

*gen effect_matrix = effect+"_"+shock_type+"_"+weight

gen matrix = shock_type + "_" + weight


gen region = ""
global EU3 "AUT BEL BGR CHE CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ISL ITA LTU LUX LVA MLT NLD NOR POL PRT ROU SVK SVN SWE"
global ASIA "BRN CHN CHNDOM CHNNPR CHNPRO HKG IDN JPN KHM KOR MYS PHL SGP THA TWN VNM"
global NAFTA "CAN MEX MEXGMF MEXNGM USA"
global ROW "ARG AUS BRA CHL COL CRI IND ISR NZL ROW RUS SAU TUN TUR ZAF"

foreach i of global ROW{
	foreach j of global ROW{
		replace region = "ROW" if cause == "`i'" & effect == "`j'"
	}
}

set more off
foreach m of global EU3 {
	foreach n of global EU3 {
		replace region = "EU+3" if cause == "`m'" & effect =="`n'"
	}
}


foreach k of global ASIA{
	foreach l of global ASIA{
		replace region = "ASIA" if cause == "`k'" & effect == "`l'"
	}
}

set more off
foreach i of global NAFTA{
	foreach j of global NAFTA{
		replace region = "NAFTA" if cause == "`i'" & effect == "`j'"
	}
}


set more off
foreach i of global EU3{
	foreach j of global ASIA{
		replace region = "EU+3_ASIA" if cause == "`i'" & effect == "`j'"
		replace region = "EU+3_ASIA" if cause == "`j'" & effect == "`i'"
	}
}

set more off
foreach i of global EU3{
	foreach j of global NAFTA{
		replace region = "EU+3_NAFTA" if cause == "`i'" & effect == "`j'"
		replace region = "EU+3_NAFTA" if cause == "`j'" & effect == "`i'"
	}
}



set more off
foreach i of global EU3{
	foreach j of global ROW{
		replace region = "EU+3_ROW" if cause == "`i'" & effect == "`j'"
		replace region = "EU+3_ROW" if cause == "`j'" & effect == "`i'"
	}
}

set more off
foreach i of global ASIA{
	foreach j of global NAFTA{
		replace region = "ASIA_NAFTA" if cause == "`i'" & effect == "`j'"
		replace region = "ASIA_NAFTA" if cause == "`j'" & effect == "`i'"
	}
}


set more off
foreach i of global ASIA{
	foreach j of global ROW{
		replace region = "ASIA_ROW" if cause == "`i'" & effect == "`j'"
		replace region = "ASIA_ROW" if cause == "`j'" & effect == "`i'"
	}
}


set more off
foreach i of global NAFTA{
	foreach j of global ROW{
		replace region = "NAFTA_ROW" if cause == "`i'" & effect == "`j'"
		replace region = "NAFTA_ROW" if cause == "`j'" & effect == "`i'"
	}
}



replace region = "no" if region == ""

gen yearregion = region+"_"+year



*Stata set _Itype_caus_1 = ARG_p_X_no, _Itype_effe_1 = ARG_p_X_no, _Iyearregio_1 = ASIA_1995 as reference dummies (alphabetical logic)

set more off

char cause[omit] "AUS"
char effect[omit] "BRA"
char yearregion[omit] "ASIA_ROW_1995"
xi i.cause i.effect i.matrix i.yearregion

*xi, noomit i.type_cause i.type_effect i.yearregion
*reg ln_shock _Itype_caus_2-_Itype_effe_268 _Iyearregio_2-_Iyearregio_70, noconstant


save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/reg2.dta", replace

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/reg2.dta"

reg ln_shock _Icause_1-_Iyearregio_42 _Iyearregio_44-_Iyearregio_56 _Iyearregio_58-_Iyearregio_63 _Iyearregio_65-_Iyearregio_70
estimates store reg_3

*reg ln_shock _Itype_caus_2-_Itype_caus_3 _Itype_caus_7-_Iyearregio_14 _Iyearregio_16-_Iyearregio_42 _Iyearregio_44-_Iyearregio_56 _Iyearregio_58-_Iyearregio_70
*reg ln_shock _Itype_caus_2-_Itype_caus_4 _Itype_caus_13-_Itype_effe_12 _Itype_effe_17-_Itype_effe_536 _Iyearregio_2-_Iyearregio_56 _Iyearregio_58-_Iyearregio_70
*set more off
*xi, noomit : reg ln_shock i.type_cause i.type_effect i.yearregion, noconstant

outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_3.xls, replace label 

*testparm _Iyearregio_*, equal

set more on
end

*-------------------------------------------------------------------------------
*REGRESSION 4
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to this equation : shock ijt = a * e(alpha i indicator i) * e(g indicator g) * e(alpha j indicator j) * e(alpha ig indicator ig)
* e(alpha jg indicator jg) * e(Bt indicator Bt) * e(r indicator r) * e(Bt r * indicator t r) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha i being the country from which the shock appears, alpha j being the country that receives the shock, g is the type of matrix.
Bt being an indicator for years and r an indicator for region, epsilon being the error term.We have three interacted variables : alpha i x g , alpha j x g, Bt x r.
There are 10 regions : ASIA_ASIA, EU_EU, NAFTA_NAFTA, ROW_ROW, ASIA_EU, ASIA_NAFTA, ASIA_ROW, EU_NAFTA, EU_ROW, NAFTA_ROW
We set one reference indicator for each category :
For alpha i : ARG
For alpha j : BRA
For g : p_X (matrix of price shock and export weights
For Bt : 1995
For r : ASIA_ROW
Stata omits those categories for collinearity:
causexmatrix ZAF-wX, ZAF-wYt
region 7, 9, 10 (EU_ROW, NAFTA_ROW, ROW_ROW)
*/
capture program drop regress_effect_4
program regress_effect_4

*Create pays_region.dta
clear
set matsize 11000, perm
set more off

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

generate pays = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local new = _N + 1
		set obs `new'
		local ligne = `j' + 1 *`num_pays'
		replace pays = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

local EU "AUT BEL BGR CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HRV HUN IRL ITA LTU LUX LVA MLT NLD POL PRT ROU SVK SVN SWE"
local NAFTA "CAN MEX MEXGMF MEXNGM USA"
local ASIA "BRN CHN CHNDOM CHNNPR CHNPRO HKG IDN JPN KHM KOR MYS PHL SGP THA TWN VNM"
local ROW "ARG AUS BRA CHE CHL COL CRI IND ISL ISR NOR NZL ROW RUS SAU TUN TUR ZAF"

generate region = ""
foreach i of local EU{
replace region = "EU" if pays == "`i'"
}
foreach j of local NAFTA{
replace region = "NAFTA" if pays == "`j'"
}
foreach k of local ASIA{
replace region = "ASIA" if pays == "`k'"
}
foreach l of local ROW{
replace region = "ROW" if pays == "`l'"
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions.dta", replace

*Do the regression

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
*Withdraw the corrected or not criteria
drop if cor =="yes"
drop cor
*Withdraw self-effects
drop if cause==effect
*Take the log of shock
generate ln_shock=ln(shock)
*Create a variable type of matrix
generate matrix= shock_type+weight
*Prepare to merge
rename cause pays
*From a .dta where we created regions
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions.dta"
drop _merge
rename region region_cause
rename pays cause
rename effect pays
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions.dta"
drop _merge
rename region region_effect
rename pays effect
generate region = region_cause + "_" + region_effect if region_cause <= region_effect
replace region  = region_effect + "_" + region_cause if region_cause >= region_effect
generate region_year=region+"_"+year
destring year, replace
generate cause_matrix = cause+matrix
generate effect_matrix=effect+matrix
encode cause, generate (ncause)
encode effect, generate (neffect)
encode matrix, generate (nmatrix)
encode  cause_matrix, generate (ncause_matrix)
encode  effect_matrix, generate (neffect_matrix)
encode region, generate (nregion)
encode region_year, generate (nregion_year)

set more off
regress ln_shock  i.ncause##i.nmatrix ib2.neffect##i.nmatrix ib4.nregion##i.year

estimates store reg4
outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_4.xls, replace label
/*
You have to read the results in a different way. Indeed, when we tell Stata to use interacted variable like i.ncause##i.nmatrix for example, Stata decomposes the coefficients and creates an indicator for
cause, an indicator for matrix and an indicator for cause and matrix. Thus, when we want to understand the result coefficients for region x year, we have to know that the coefficients
for years correspond in fact to the reference category region of ASIA_ROW. Coefficients for other regions are the difference from the reference coefficients of ASIA_ROW. 
To plot the graph, we should therefore compute coeff of region + coeff of ASIA_ROW to get the coefficient we are interested in. The indicator "region" is a fixed effect (it changes the levels only)
But we are interested in the impact of time on shocks. The indicator "years" corresponds to the reference category, ASIA_ROW. The constant corresponds to the mean of the situation of reference, it is the value
when all indicators = 0.
*/

/*
testparm i.nregion#year, equal

*Same as first line:
testparm 1o.nregion#1995b.year 1.nregion#2000.year 1.nregion#2005.year 1.nregion#2008.year 1.nregion#2009.year 1.nregion#2010.year 1.nregion#2011.year ///
2o.nregion#1995b.year 2.nregion#2000.year 2.nregion#2005.year 2.nregion#2008.year 2.nregion#2009.year 2.nregion#2010.year 2.nregion#2011.year ///
3o.nregion#1995b.year 3.nregion#2000.year 3.nregion#2005.year 3.nregion#2008.year 3.nregion#2009.year 3.nregion#2010.year 3.nregion#2011.year ///
5o.nregion#1995b.year 5.nregion#2000.year 5.nregion#2005.year 5.nregion#2008.year 5.nregion#2009.year 5.nregion#2010.year 5.nregion#2011.year 6o.nregion#1995b.year 6.nregion#2000.year 6.nregion#2005.year 6.nregion#2008.year 6.nregion#2009.year 6.nregion#2010.year 6.nregion#2011.year ///
7o.nregion#1995b.year 7.nregion#2000.year 7.nregion#2005.year 7.nregion#2008.year 7.nregion#2009.year 7.nregion#2010.year 7.nregion#2011.year 8o.nregion#1995b.year 8.nregion#2000.year 8.nregion#2005.year 8.nregion#2008.year 8.nregion#2009.year 8.nregion#2010.year 8.nregion#2011.year ///9o.nregion#1995b.year 9.nregion#2000.year 9.nregion#2005.year 9.nregion#2008.year 9.nregion#2009.year 9.nregion#2010.year 9.nregion#2011.year 10o.nregion#1995b.year 10.nregion#2000.year 10.nregion#2005.year 10.nregion#2008.year 10.nregion#2009.year 10.nregion#2010.year 10.nregion#2011.year, equal

testparm 2000.year 2005.year 2008.year 2009.year 2010.year 2011.year 1o.nregion#1995b.year 1.nregion#2000.year 1.nregion#2005.year 1.nregion#2008.year 1.nregion#2009.year 1.nregion#2010.year 1.nregion#2011.year ///
2o.nregion#1995b.year 2.nregion#2000.year 2.nregion#2005.year 2.nregion#2008.year 2.nregion#2009.year 2.nregion#2010.year 2.nregion#2011.year ///
3o.nregion#1995b.year 3.nregion#2000.year 3.nregion#2005.year 3.nregion#2008.year 3.nregion#2009.year 3.nregion#2010.year 3.nregion#2011.year ///
5o.nregion#1995b.year 5.nregion#2000.year 5.nregion#2005.year 5.nregion#2008.year 5.nregion#2009.year 5.nregion#2010.year 5.nregion#2011.year 6o.nregion#1995b.year 6.nregion#2000.year 6.nregion#2005.year 6.nregion#2008.year 6.nregion#2009.year 6.nregion#2010.year 6.nregion#2011.year ///
7o.nregion#1995b.year 7.nregion#2000.year 7.nregion#2005.year 7.nregion#2008.year 7.nregion#2009.year 7.nregion#2010.year 7.nregion#2011.year 8o.nregion#1995b.year 8.nregion#2000.year 8.nregion#2005.year 8.nregion#2008.year 8.nregion#2009.year 8.nregion#2010.year 8.nregion#2011.year ///9o.nregion#1995b.year 9.nregion#2000.year 9.nregion#2005.year 9.nregion#2008.year 9.nregion#2009.year 9.nregion#2010.year 9.nregion#2011.year 10o.nregion#1995b.year 10.nregion#2000.year 10.nregion#2005.year 10.nregion#2008.year 10.nregion#2009.year 10.nregion#2010.year 10.nregion#2011.year, equal

*Test for the equality of coefficients of all regions in 2000: 

testparm 1.nregion#2000.year 2.nregion#2000.year 3.nregion#2000.year 4.nregion#2000.year 5.nregion#2000.year 6.nregion#2000.year 7.nregion#2000.year 8.nregion#2000.year ///9.nregion#2000.year 10.nregion#2000.year, equal

*Result: there are significantly different at a 95% confidence interval


testparm 5.nregion#2009.year 8.nregion#2009.year, equal


*Are the coefficients for regions in 2000 significantly different?

forvalues i=1/10{
	forvalues j=1/10{
		test `i'.nregion#2000.year=`j'.nregion#2000.year
	}
}

*We cannot reject the hypothesis that coefficients for all regions with region 1 (ASIA_ASIA) in 2000 are equal at a 95% confidence interval.

*Are the coefficients for regions in 2008 and 2009 significantly different? Apart from ASIA_ROW, ASIA_EU, EU_NAFTA,ROW_ROW that are away from the mass of curves?

local var1 "1 3 5 7 8 9"

foreach i of local var1{
	foreach j of local var1{
		test `i'.nregion#2008.year=`j'.nregion#2008.year
	}
}
	
local var1 "1 3 5 7 8 9"

foreach i of local var1{
	foreach j of local var1{
		test `i'.nregion#2010.year=`j'.nregion#2010.year
	}
}
*Some are not significantly different from others but some are significanty different.
*/

end
*-------------------------------------------------------------------------------
*REGRESSION 5
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to this equation : shock ijt = a * e(alpha i indicator i) * e(g indicator g) * e(alpha j indicator j) * e(alpha ig indicator ig)
* e(alpha jg indicator jg) * e(Bt indicator Bt) * e(r indicator r) * e(Bt r * indicator t r) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha i being the country from which the shock appears, alpha j being the country that receives the shock, g is the type of matrix.
Bt being an indicator for years and r an indicator for region, epsilon being the error term.We have three interacted variables : alpha i x g , alpha j x g, Bt x r.
There are 6 regions : the eurozone, the rest of the EU, the rest of the world, eurozone-rest of the EU, eurozone-rest of the world, rest of the EU-rest of the world.
We set one reference category for each indicator :
For alpha i : ARG
For alpha j : BRA
For g : p_X (matrix of price shock and export weights
For Bt : 1995
For r : Rest of EU-ROW
Stata omits those categories for collinearity:
causexmatrix ZAF-wX, ZAF-wYt
region 3 and 6 (EUROZONE_ROW, ROW_ROW)
*/

capture program drop regress_effect_5
program regress_effect_5

clear
set matsize 11000
set more off

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

generate pays = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local new = _N + 1
		set obs `new'
		local ligne = `j' + 1 *`num_pays'
		replace pays = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

local EUROZONE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
local REST_OF_EU "BGR CZE DNK GBR HRV HUN POL ROU SWE"
local ROW "ARG AUS BRA BRN CAN CHE CHN CHNDOM CHNNPR CHNPRO CHL COL CRI HKG IDN IND ISL ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NOR NZL PHL ROW RUS SAU SGP THA TUN TUR TWN USA VNM ZAF"

generate region = ""
foreach i of local EUROZONE{
replace region = "EUROZONE" if pays == "`i'"
}
foreach j of local REST_OF_EU{
replace region = "REST_OF_EU" if pays == "`j'"
}
foreach k of local ROW{
replace region = "ROW" if pays == "`k'"
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions_2.dta", replace

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
*Withdraw the corrected or not criteria
drop if cor =="yes"
drop cor
*Withdraw self-effects
drop if cause==effect
*Take the log of shock
generate ln_shock=ln(shock)
*Create a variable type of matrix
generate matrix= shock_type+weight
*Prepare to merge
rename cause pays

*From a .dta where we created regions
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions_2.dta"
drop _merge
rename region region_cause
rename pays cause
rename effect pays
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions_2.dta"
drop _merge
rename region region_effect
rename pays effect
generate region = region_cause + "_" + region_effect if region_cause <= region_effect
replace region  = region_effect + "_" + region_cause if region_cause >= region_effect
generate region_year=region+"_"+year
destring year, replace
generate cause_matrix = cause+matrix
generate effect_matrix=effect+matrix
encode cause, generate (ncause)
encode effect, generate (neffect)
encode matrix, generate (nmatrix)
encode  cause_matrix, generate (ncause_matrix)
encode  effect_matrix, generate (neffect_matrix)
encode region, generate (nregion)
encode region_year, generate (nregion_year)

set more off
regress ln_shock  i.ncause##i.nmatrix ib2.neffect##i.nmatrix ib5.nregion##i.year

estimates store reg5
outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_5.xls, replace label

/*
You have to read the results in a different way. Indeed, when we tell Stata to use interacted variable like i.ncause##i.nmatrix for example, Stata decomposes the coefficients and creates an indicator for
cause, an indicator for matrix and an indicator for cause and matrix. Thus, when we want to understand the result coefficients for region x year, we have to know that the coefficients
for years correspond in fact to the reference category region of REST_OF_EU_ROW. Coefficients for other regions are the difference from the reference coefficients of ASIA_ROW. 
To plot the graph, we should therefore compute coeff of region + coeff of REST_OF_EU_ROW to get the coefficient we are interested in. The indicator "region" is a fixed effect (it changes the levels only)
But we are interested in the impact of time on shocks. The indicator "years" corresponds to the reference category, REST_OF_EU_ROW. The constant corresponds to the mean of the situation of reference, it is the value
when all indicators = 0.
*/
/*
*According to the graph_5 we have the intuition that the coefficients for ROW_ROW are significantly different from those of other regions. But other region's curves seem very embedded.
*We test if the coefficients for those regions are significantly different.


testparm 1o.nregion#1995b.year 1.nregion#2000.year 1.nregion#2005.year 1.nregion#2008.year 1.nregion#2009.year 1.nregion#2010.year 1.nregion#2011.year ///
2o.nregion#1995b.year 2.nregion#2000.year 2.nregion#2005.year 2.nregion#2008.year 2.nregion#2009.year 2.nregion#2010.year 2.nregion#2011.year 3o.nregion#1995b.year 3.nregion#2000.year 3.nregion#2005.year 3.nregion#2008.year 3.nregion#2009.year 3.nregion#2010.year 3.nregion#2011.year 4o.nregion#1995b.year 4.nregion#2000.year 4.nregion#2005.year 4.nregion#2008.year 4.nregion#2009.year 4.nregion#2010.year 4.nregion#2011.year ///
5b.nregion#1995b.year 5b.nregion#2000o.year 5b.nregion#2005o.year 5b.nregion#2008o.year 5b.nregion#2009o.year 5b.nregion#2010o.year 5b.nregion#2011o.year, equal

forvalues i=1/6{
	forvalues j=1/6{
		test `i'.nregion#2000.year=`j'.nregion#2000.year
	}
}

*Testing the equality of coefficients between EUROZONE_EUROZONE and EUROZONE_REST_OF_EU:
local yrs "1995 2000 2005 2008 2009 2010 2011"
foreach i of local yrs{
	test 1.nregion#`i'.year=2.nregion#`i'.year
}
*We can reject the hypothesis that they are equal at a 95% confidence interval in 2005 only.
*Testing the equality of coefficients between EUROZONE_EUROZONE and REST_OF_EU_REST_OF_EU:
local yrs "1995 2000 2005 2008 2009 2010 2011"
foreach i of local yrs{
	test 1.nregion#`i'.year=4.nregion#`i'.year
}
*Cannot reject the hypothesis for any year.
*/

end
*---------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 1
*---------------------------------------------------------------------------------------------------
capture program drop draw_graph
program draw_graph
	args v wgt
	*with v = p or w, wgt = Yt or X
clear
set more off

regress_effect `v' `wgt'

*Once finished :
*gen a variable coeff of coefficients (take from e(b) )
*gen a variable se of standard deviation (écart-type also called "standard error" in Stata)
*gen a variable year with 2000 to 2011
clear
set more off

matrix coeff = e(b)'
svmat coeff
rename coeff1 coeff

*generate a variable of standard deviations
matrix V = e(V)
matrix SE2 = vecdiag(V)
matrix SE = SE2'
matmap SE se, m(sqrt(@))
svmat se
rename se1 se

gen category = ""
local num_pays 0
forvalues i = 1/4428{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace

*Drop the very last coefficient (corresponding to the constant), and keep the last six coefficients corresponding to 2000, 2005, 2008, 2009, 2010, 2011

drop if category == 4428
keep if category >4421


local yrs "1995 2000 2005 2008 2009 2010 2011"
generate year = ""
local num_pays 0
local new = _N+1
set obs `new'
foreach i of local yrs {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace year = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring year, replace

generate upperbound = coeff+se*1.96
generate lowerbound = coeff-se*1.96

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace coeff = coeff[_n-1] if year == `i'
}
replace coeff = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound = upperbound[_n-1] if year == `i'
}
replace upperbound = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound = lowerbound[_n-1] if year == `i'
}
replace lowerbound = 0 if year == 1995

local var "coeff upperbound lowerbound"
foreach i of local var{
replace `i' = exp(`i') * 100
replace coeff = 100 if year == 1995
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph1.dta", replace

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph1.dta"

graph twoway connected coeff upperbound lowerbound year, xlabel(1995(2)2011) ///
 title("Evolution of integration 1995-2011") subtitle("Price shock, production weight, noncorrected") ///
ytitle(index) xtitle(year) mcolor(red none none) lcolor(red black black) lpattern(solid dash dash)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph_evolution_10.gph", replace

end

*----------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 2
*----------------------------------------------------------------------------------------------------
capture program drop draw_graph_2
program draw_graph_2

clear
set more off

regress_effect_2

*Once finished :
*gen a variable coeff of coefficients (take from e(b) )
*gen a variable se of standard deviation (écart-type also called "standard error" in Stata)
*gen a variable year with 1995 to 2011

clear 
set more off

matrix coeff = e(b)'
svmat coeff
rename coeff1 coeff

*generate a variable of standard deviations
matrix V = e(V)
matrix SE2 = vecdiag(V)
matrix SE = SE2'
matmap SE se, m(sqrt(@))
svmat se
rename se1 se

*generate a confidence interval with upperbound and lowerbound
generate upperbound = coeff+se*1.96
generate lowerbound = coeff-se*1.96

*generate a variable category for each region
gen category = ""
local num_pays 0
forvalues i = 1/170{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace

drop if category == 170
keep if category > 135

tostring category, replace

local region1 "136 137 138 139 140 141 142"
foreach i of local region1 {
	replace category = "eurozone" if category == "`i'"
}

local region2 "143 144 145 146 147 148 149"
foreach i of local region2 {
	replace category = "eurozone_restEU" if category == "`i'"
}


local region3 "150 151 152 153 154 155"
foreach i of local region3 {
	replace category = "no" if category == "`i'"
}

local region4 "156 157 158 159 160 161 162"
foreach i of local region4 {
	replace category = "restEU" if category == "`i'"
}

local region5 "163 164 165 166 167 168 169"
foreach i of local region5 {
	replace category = "rest" if category == "`i'"
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta", replace

*-------------------------------------------------------------------------------
*create a variable of coefficients for each region as well as upperbounds and lowerbounds that correspond to a confidence interval for each region over the period
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta"

keep if category == "eurozone"

generate eurozone = coeff if category == "eurozone"
replace eurozone = 0 if eurozone >= .
mkmat eurozone
rename upperbound upperbound1
rename lowerbound lowerbound1
mkmat upperbound1
mkmat lowerbound1

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta"

keep if category == "eurozone_restEU"

generate eurozone_restEU = coeff if category == "eurozone_restEU"
mkmat eurozone_restEU
rename upperbound upperbound2
rename lowerbound lowerbound2
mkmat upperbound2
mkmat lowerbound2

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta"
keep if category == "no"
generate no = coeff if category == "no"
replace no = 0 if no >=.
mkmat no
rename upperbound upperbound3
rename lowerbound lowerbound3
mkmat upperbound3
mkmat lowerbound3

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta"
keep if category == "restEU"
generate restEU = coeff if category == "restEU"
mkmat restEU
rename upperbound upperbound4
rename lowerbound lowerbound4
mkmat upperbound4
mkmat lowerbound4

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients.dta"
keep if category == "rest"
generate rest = coeff if category == "rest"
mkmat rest
rename upperbound upperbound5
rename lowerbound lowerbound5
mkmat upperbound5
mkmat lowerbound5

clear
svmat eurozone_restEU
svmat no 
svmat restEU
svmat rest
svmat eurozone
svmat upperbound1
svmat lowerbound1
svmat upperbound2
svmat lowerbound2
svmat upperbound3
svmat lowerbound3
svmat upperbound4
svmat lowerbound4
svmat upperbound5
svmat lowerbound5

local yrs "1995 2000 2005 2008 2009 2010 2011"
generate year = ""
local num_pays 0
foreach i of local yrs {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace year = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring year, replace
replace year = 0 if year>=.

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region.dta", replace

*-------------------------------------------------------------------------------
*adjustement : indeed, the eurozone in 1995 is the dummy reference in the regression. Its coefficient is therefore 0 so we have to shift all values and set 0 in 1995 for the graph to be correct.
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region.dta"

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace no1 = no1[_n-1] if year == `i'
}
replace no1 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound31 = upperbound31[_n-1] if year == `i'
}
replace upperbound31 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound31 = lowerbound31[_n-1] if year == `i'
}
replace lowerbound31 = 0 if year == 1995

local var "eurozone_restEU1 no1 restEU1 rest1 eurozone1 upperbound11 lowerbound11 upperbound21 lowerbound21 upperbound31 lowerbound31 upperbound41 lowerbound41 upperbound51 lowerbound51"
foreach i of local var{
replace `i' = exp(`i') * 100
}

local var2 "eurozone_restEU1 no1 restEU1 rest1 eurozone1 upperbound31 lowerbound31"
foreach i of local var2{
replace `i' = 100 if year == 1995
}

*-------------------------------------------------------------------------------
*plot the graph
graph twoway connected eurozone1 eurozone_restEU no restEU rest1 upperbound1 lowerbound1 upperbound2 lowerbound2 upperbound3 lowerbound3 upperbound4 lowerbound4 upperbound5 lowerbound5 ///
year, xlabel(1995(2)2011) ylabel(0(200)1500) title("Evolution of density 1995-2011") mcolor(red green yellow blue purple none none none none none none none none none none) ///
lcolor(red green yellow blue purple dark dark dark dark dark dark dark dark dark dark) lpattern(solid solid solid solid solid dot dot dot dot dot dot dot dot dot dot) ///
 legend(order(1 2 3 4 5)) ytitle(index) xtitle(year)
 
graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph_region_10.gph", replace

end

*-------------------------------------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 3
*-------------------------------------------------------------------------------------------------------------------------------
capture program drop draw_graph_3
program draw_graph_3

clear
set more off

regress_effect_3
estimates store reg3


*Once finished :
*gen a variable coeff of coefficients (take from e(b) )
*gen a variable se of standard deviation (écart-type also called "standard error" in Stata)
*gen a variable year with 1995 to 2011

clear 
set more off

matrix coeff = e(b)'
svmat coeff
rename coeff1 coeff

*generate a variable of standard deviations
matrix V = e(V)
matrix SE2 = vecdiag(V)
matrix SE = SE2'
matmap SE se, m(sqrt(@))
svmat se
rename se1 se

*generate a confidence interval with upperbound and lowerbound
generate upperbound = coeff+se*1.96
generate lowerbound = coeff-se*1.96

*------------------------------------------
*generate a variable category
set more off
gen category = ""
local num_pays 0
forvalues i = 1/202{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace

keep if category > 135
drop if category == 202

tostring category, replace

/*
local reg "ASIA ASIA_NAFTA ASIA_ROW EU+3 EU+3_ASIA EU+3_NAFTA EU+3_ROW NAFTA NAFTA_ROW ROW"
generate region = ""
local num_reg 0
foreach i of local reg {
	foreach j of numlist 1/7 {
		local new = _N + 1
		set obs `new'
		local ligne = `j' + 7*`num_reg'
		replace region = "`i'" in `ligne'
	}
	local num_reg = `num_reg'+1
}
*/


*--------------------------------------------------

local region1 "136 137 138 139 140 141 142"
foreach i of local region1 {
	replace category = "ASIA" if category == "`i'"
}

local region2 "143 144 145 146 147 148 149"
foreach i of local region2 {
	replace category = "ASIA_NAFTA" if category == "`i'"
}

local region3 "150 151 152 153 154 155"
foreach i of local region3 {
	replace category = "ASIA_ROW" if category == "`i'"
}

local region4 "156 157 158 159 160 161 162"
foreach i of local region4 {
	replace category = "EU+3" if category == "`i'"
}

local region5 "163 164 165 166 167 168 169"
foreach i of local region5 {
	replace category = "EU+3_ASIA" if category == "`i'"
}

local region6 "170 171 172 173 174 175 176"
foreach i of local region6 {
	replace category = "EU+3_NAFTA" if category == "`i'"
}

local region7 "177 178 179 180 181 182"
foreach i of local region7 {
	replace category = "EU+3_ROW" if category == "`i'"
}

local region8 "183 184 185 186 187 188 189"
foreach i of local region8 {
	replace category = "NAFTA" if category == "`i'"
}

local region9 "190 191 192 193 194 195"
foreach i of local region9 {
	replace category = "NAFTA_ROW" if category == "`i'"
}

local region10 "196 197 198 199 200 201"
foreach i of local region10 {
	replace category = "ROW" if category == "`i'"
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta", replace

*-------------------------------------------------------------------------------
*create a variable of coefficients for each region as well as upperbounds and lowerbounds that correspond to a confidence interval for each region over the period
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"

keep if category == "ASIA"

generate ASIA = coeff if category == "ASIA"
replace ASIA = 0 if ASIA >= .
mkmat ASIA
rename upperbound upperbound1
rename lowerbound lowerbound1
mkmat upperbound1
mkmat lowerbound1

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"

keep if category == "ASIA_NAFTA"

generate ASIA_NAFTA = coeff if category == "ASIA_NAFTA"
replace ASIA_NAFTA = 0 if ASIA_NAFTA >= .
mkmat ASIA_NAFTA
rename upperbound upperbound2
rename lowerbound lowerbound2
mkmat upperbound2
mkmat lowerbound2

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "ASIA_ROW"
generate ASIA_ROW = coeff if category == "ASIA_ROW"
replace ASIA_ROW = 0 if ASIA_ROW >=.
mkmat ASIA_ROW
rename upperbound upperbound3
rename lowerbound lowerbound3
mkmat upperbound3
mkmat lowerbound3

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "EU+3"
generate EU3 = coeff if category == "EU+3"
replace EU3 = 0 if EU3 >=.
mkmat EU3
rename upperbound upperbound4
rename lowerbound lowerbound4
mkmat upperbound4
mkmat lowerbound4

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "EU+3_ASIA"
generate EU3_ASIA = coeff if category == "EU+3_ASIA"
replace EU3_ASIA = 0 if EU3_ASIA >=.
mkmat EU3_ASIA
rename upperbound upperbound5
rename lowerbound lowerbound5
mkmat upperbound5
mkmat lowerbound5

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "EU+3_NAFTA"
generate EU3_NAFTA = coeff if category == "EU+3_NAFTA"
replace EU3_NAFTA = 0 if EU3_NAFTA >=.
mkmat EU3_NAFTA
rename upperbound upperbound6
rename lowerbound lowerbound6
mkmat upperbound6
mkmat lowerbound6

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "EU+3_ROW"
generate EU3_ROW = coeff if category == "EU+3_ROW"
replace EU3_ROW = 0 if EU3_ROW >=.
mkmat EU3_ROW
rename upperbound upperbound7
rename lowerbound lowerbound7
mkmat upperbound7
mkmat lowerbound7

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "NAFTA"
generate NAFTA = coeff if category == "NAFTA"
replace NAFTA = 0 if NAFTA >=.
mkmat NAFTA
rename upperbound upperbound8
rename lowerbound lowerbound8
mkmat upperbound8
mkmat lowerbound8

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "NAFTA_ROW"
generate NAFTA_ROW = coeff if category == "NAFTA_ROW"
replace NAFTA_ROW = 0 if NAFTA_ROW >=.
mkmat NAFTA_ROW
rename upperbound upperbound9
rename lowerbound lowerbound9
mkmat upperbound9
mkmat lowerbound9

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if category == "ROW"
generate ROW = coeff if category == "ROW"
replace ROW = 0 if ROW >=.
mkmat ROW
rename upperbound upperbound10
rename lowerbound lowerbound10
mkmat upperbound10
mkmat lowerbound10

clear
svmat ASIA
svmat ASIA_NAFTA
svmat ASIA_ROW
svmat EU3
svmat EU3_ASIA
svmat EU3_NAFTA
svmat EU3_ROW
svmat NAFTA
svmat NAFTA_ROW
svmat ROW
svmat upperbound1
svmat lowerbound1
svmat upperbound2
svmat lowerbound2
svmat upperbound3
svmat lowerbound3
svmat upperbound4
svmat lowerbound4
svmat upperbound5
svmat lowerbound5
svmat upperbound6
svmat lowerbound6
svmat upperbound7
svmat lowerbound7
svmat upperbound8
svmat lowerbound8
svmat upperbound9
svmat lowerbound9
svmat upperbound10
svmat lowerbound10

local yrs "1995 2000 2005 2008 2009 2010 2011"
generate year = ""
local num_pays 0
foreach i of local yrs {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace year = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring year, replace
replace year = 0 if year>=.

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region.dta", replace

*-------------------------------------------------------------------------------
*adjustement : indeed, the eurozone in 1995 is the dummy reference in the regression. Its coefficient is therefore 0 so we have to shift all values and set 0 in 1995 for the graph to be correct.
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region.dta"

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace ASIA_ROW1 = ASIA_ROW1[_n-1] if year == `i'
}
replace ASIA_ROW1 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound31 = upperbound31[_n-1] if year == `i'
}
replace upperbound31 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound31 = lowerbound31[_n-1] if year == `i'
}
replace lowerbound31 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace EU3_ROW1  = EU3_ROW1[_n-1] if year == `i'
}
replace EU3_ROW1 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound71 = upperbound71[_n-1] if year == `i'
}
replace upperbound71 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound71 = lowerbound71[_n-1] if year == `i'
}
replace lowerbound71 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace NAFTA_ROW1 = NAFTA_ROW1[_n-1] if year == `i'
}
replace NAFTA_ROW1 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound91 = upperbound91[_n-1] if year == `i'
}
replace upperbound91 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound91 = lowerbound91[_n-1] if year == `i'
}
replace lowerbound91 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace ROW1 = ROW1[_n-1] if year == `i'
}
replace ROW1 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace upperbound101 = upperbound101[_n-1] if year == `i'
}
replace upperbound101 = 0 if year == 1995

local yrs "2011 2010 2009 2008 2005 2000 1995"
foreach i of local yrs{
replace lowerbound101 = lowerbound101[_n-1] if year == `i'
}
replace lowerbound101 = 0 if year == 1995



local var "ASIA1 ASIA_NAFTA1 ASIA_ROW1 EU31 EU3_ASIA1 EU3_NAFTA1 EU3_ROW1 NAFTA1 NAFTA_ROW1 ROW1 upperbound11 lowerbound11 upperbound21 lowerbound21 upperbound31 lowerbound31  upperbound41 lowerbound41 upperbound51 lowerbound51 upperbound61 lowerbound61 upperbound71 lowerbound71 upperbound81 lowerbound81 upperbound91 lowerbound91 upperbound101 lowerbound101"
foreach i of local var{
replace `i' = exp(`i') * 100
}

local var2 "ASIA1 ASIA_NAFTA1 ASIA_ROW1 EU31 EU3_ASIA1 EU3_NAFTA1 EU3_ROW1 NAFTA1 NAFTA_ROW1 ROW1 upperbound31 lowerbound31 upperbound71 lowerbound71 upperbound91 lowerbound91 upperbound101 lowerbound101"
foreach i of local var2{
replace `i' = 100 if year == 1995
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_2.dta", replace

*-------------------------------------------------------------------------------
*plot the graph
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_2.dta"

graph twoway connected ASIA1 ASIA_ROW1 EU31 NAFTA1 ROW1 upperbound11 lowerbound11 upperbound41 lowerbound41 upperbound81 lowerbound81 upperbound101 lowerbound101 year, xlabel(1995(2)2011) ///
 title("Evolution of density 1995-2011") mcolor(red orange green yellow blue none none none none none none none none) ///
lcolor(red orange green yellow blue dark dark dark dark dark dark dark dark) lpattern(solid solid solid solid solid dot dot dot dot dot dot dot dot) ///
 legend(order(1 2 3 4 5)) ytitle(index) xtitle(year)
 
graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph_3_1.gph", replace

end

*-------------------------------------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 4
*-------------------------------------------------------------------------------------------------------------------------------
capture program drop draw_graph_4
program draw_graph_4

clear
set more off

*create a matrix of coefficients from results
matrix coeff = e(b)'
svmat coeff
rename coeff1 coeff

*generate a variable of standard deviations
matrix V = e(V)
matrix SE2 = vecdiag(V)
matrix SE = SE2'
matmap SE se, m(sqrt(@))
svmat se
rename se1 se

*create a string variable used as a tool to build the dataset
set more off
gen category = ""
local num_pays 0
forvalues i = 1/762{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace

drop if category == 762
keep if category > 684

tostring category, replace

*create a variable region
local region "ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA ASIA_ROW2 EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW"
generate region = ""
local num_reg 0
foreach i of local region {
	foreach j of numlist 1/7 {
		local ligne = `j' + 7*`num_reg'
		replace region = "`i'" in `ligne'
	}
	local num_reg = `num_reg'+1
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta", replace

*create a variable of coefficient for each region as well as a variable of standard deviation
clear
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "ASIA_ROW"
generate ASIA_ROW = coeff
generate seASIA_ROW = se
mkmat ASIA_ROW
mkmat seASIA_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"

keep if region == "ASIA_ASIA"
generate ASIA_ASIA2 = coeff if region == "ASIA_ASIA"
generate seASIA_ASIA = se
mkmat ASIA_ASIA2
mkmat seASIA_ASIA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"

keep if region == "ASIA_EU"
generate ASIA_EU2 = coeff if region == "ASIA_EU"
generate seASIA_EU = se
mkmat ASIA_EU2
mkmat seASIA_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"

keep if region == "ASIA_NAFTA"
generate ASIA_NAFTA2 = coeff
generate seASIA_NAFTA = se
mkmat ASIA_NAFTA2
mkmat seASIA_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "ASIA_ROW2"
generate ASIA_ROW2 = coeff
generate seASIA_ROW2 = se
mkmat ASIA_ROW2
mkmat seASIA_ROW2

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "EU_EU"
generate EU_EU2 = coeff
generate seEU_EU = se
mkmat EU_EU2
mkmat seEU_EU


clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "EU_NAFTA"
generate EU_NAFTA2 = coeff
generate seEU_NAFTA = se
mkmat EU_NAFTA2
mkmat seEU_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "EU_ROW"
generate EU_ROW2 = coeff
generate seEU_ROW = se
mkmat EU_ROW2
mkmat seEU_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "NAFTA_NAFTA"
generate NAFTA_NAFTA2 = coeff
generate seNAFTA_NAFTA = se
mkmat NAFTA_NAFTA2
mkmat seNAFTA_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "NAFTA_ROW"
generate NAFTA_ROW2 = coeff
generate seNAFTA_ROW = se
mkmat NAFTA_ROW2
mkmat seNAFTA_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_4.dta"
keep if region == "ROW_ROW"
generate ROW_ROW2 = coeff
generate seROW_ROW = se
mkmat ROW_ROW2
mkmat seROW_ROW

clear
svmat ASIA_ROW
svmat ASIA_ASIA2
svmat ASIA_EU2
svmat ASIA_NAFTA2
svmat ASIA_ROW2
svmat EU_EU2
svmat EU_NAFTA2
svmat EU_ROW2
svmat NAFTA_NAFTA2
svmat NAFTA_ROW2
svmat ROW_ROW2
svmat seASIA_ROW
svmat seASIA_ASIA
svmat seASIA_EU
svmat seASIA_NAFTA
svmat seASIA_ROW2
svmat seEU_EU
svmat seEU_NAFTA
svmat seEU_ROW
svmat seNAFTA_NAFTA
svmat seNAFTA_ROW
svmat seROW_ROW

rename ASIA_ROW1 ASIA_ROW

*withdraw the "1" at the end of the name of each variable of standard deviation
local region2 "ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA ASIA_ROW2 EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW"
foreach i of local region2{
	rename se`i'1 se`i'
}

*withdraw the "1" at the end of the name of each variable of coefficients
local region "ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW"
foreach i of local region{
	generate `i' = ASIA_ROW + `i'21
	drop `i'21
}

*create upperbounds and lowerbounds to build a confidence interval for each region if needed
local region "ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW"
foreach i of local region{
generate upperbound`i' = `i' + se`i'*1.96
generate lowerbound`i' = `i' - se`i'*1.96
drop se`i'
}

drop ASIA_ROW2
drop seASIA_ROW2

*create a variable for years
local yrs "1995 2000 2005 2008 2009 2010 2011"
generate year = ""
local num_pays 0
foreach i of local yrs {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace year = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring year, replace

*create an index
local var "ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW upperboundASIA_ROW lowerboundASIA_ROW upperboundASIA_ASIA lowerboundASIA_ASIA upperboundASIA_EU lowerboundASIA_EU upperboundASIA_NAFTA lowerboundASIA_NAFTA upperboundEU_EU lowerboundEU_EU upperboundEU_NAFTA lowerboundEU_NAFTA upperboundEU_ROW lowerboundEU_ROW upperboundNAFTA_NAFTA lowerboundNAFTA_NAFTA upperboundNAFTA_ROW lowerboundNAFTA_ROW upperboundROW_ROW lowerboundROW_ROW"
foreach i of local var{
replace `i' = exp(`i') * 100
}

*the reference of 100 is set at year = 1995
local var "ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW upperboundASIA_ROW lowerboundASIA_ROW upperboundASIA_ASIA lowerboundASIA_ASIA upperboundASIA_EU lowerboundASIA_EU upperboundASIA_NAFTA lowerboundASIA_NAFTA upperboundEU_EU lowerboundEU_EU upperboundEU_NAFTA lowerboundEU_NAFTA upperboundEU_ROW lowerboundEU_ROW upperboundNAFTA_NAFTA lowerboundNAFTA_NAFTA upperboundNAFTA_ROW lowerboundNAFTA_ROW upperboundROW_ROW lowerboundROW_ROW"
foreach i of local var2{
replace `i' = 100 if year == 1995
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_4.dta", replace


clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_4.dta"

*plot the graph (without the confidence interval otherwise too many specifications and impossible to read the graph properly)
graph twoway connected ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW ///
 year, xlabel(1995(2)2011) ///
 title("Evolution of integration 1995-2011") mcolor(red green yellow blue orange lavender pink emerald gold olive) ///
lcolor(red green yellow blue orange lavender pink emerald gold olive dark) lpattern(solid solid solid solid solid solid solid solid solid solid) ///
 legend(order(1 2 3 4 5 6 7 8 9 10)) ytitle(index) xtitle(year)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph_4_3.gph", replace

end
*-------------------------------------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 5
*-------------------------------------------------------------------------------------------------------------------------------
capture program drop draw_graph_5
program draw_graph_5

*plot graph
clear
set more off

*create a matrix of coefficients from results
matrix coeff = e(b)'
svmat coeff
rename coeff1 coeff

*generate a variable of standard deviations
matrix V = e(V)
matrix SE2 = vecdiag(V)
matrix SE = SE2'
matmap SE se, m(sqrt(@))
svmat se
rename se1 se


*create a string variable used as a tool to build the dataset
set more off
gen category = ""
local num_pays 0
forvalues i = 1/730{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace
drop if category == 730
keep if category > 680
tostring category, replace

*create a variable region
local region "REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU REST_OF_EU_ROW2 ROW_ROW"
generate region = ""
local num_reg 0
foreach i of local region {
	foreach j of numlist 1/7 {
		local ligne = `j' + 7*`num_reg'
		replace region = "`i'" in `ligne'
	}
	local num_reg = `num_reg'+1
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta", replace

*create a variable of coefficient for each region as well as a variable of standard deviation
clear
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"
keep if region == "REST_OF_EU_ROW"
generate REST_OF_EU_ROW = coeff
generate seREST_OF_EU_ROW = se
mkmat REST_OF_EU_ROW
mkmat seREST_OF_EU_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"

keep if region == "EUROZONE_EUROZONE"
generate EUROZONE_EUROZONE2 = coeff if region == "EUROZONE_EUROZONE"
generate seEUROZONE_EUROZONE = se
mkmat EUROZONE_EUROZONE2
mkmat seEUROZONE_EUROZONE

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"

keep if region == "EUROZONE_REST_OF_EU"
generate EUROZONE_REST_OF_EU2 = coeff if region == "EUROZONE_REST_OF_EU"
generate seEUROZONE_REST_OF_EU = se
mkmat EUROZONE_REST_OF_EU2
mkmat seEUROZONE_REST_OF_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"

keep if region == "EUROZONE_ROW"
generate EUROZONE_ROW2 = coeff
generate seEUROZONE_ROW = se
mkmat EUROZONE_ROW2
mkmat seEUROZONE_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"
keep if region == "REST_OF_EU_REST_OF_EU"
generate REST_OF_EU_REST_OF_EU2 = coeff
generate seREST_OF_EU_REST_OF_EU = se
mkmat REST_OF_EU_REST_OF_EU2
mkmat seREST_OF_EU_REST_OF_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"
keep if region == "REST_OF_EU_ROW2"
generate REST_OF_EU_ROW22 = coeff
generate seREST_OF_EU_ROW2 = se
mkmat REST_OF_EU_ROW22
mkmat seREST_OF_EU_ROW2


clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_22.dta"
keep if region == "ROW_ROW"
generate ROW_ROW2 = coeff
generate seROW_ROW = se
mkmat ROW_ROW2
mkmat seROW_ROW

clear
svmat REST_OF_EU_ROW
svmat EUROZONE_EUROZONE2
svmat EUROZONE_REST_OF_EU2
svmat EUROZONE_ROW2
svmat REST_OF_EU_REST_OF_EU2
svmat REST_OF_EU_ROW22
svmat ROW_ROW2
svmat seREST_OF_EU_ROW
svmat seEUROZONE_EUROZONE
svmat seEUROZONE_REST_OF_EU
svmat seEUROZONE_ROW
svmat seREST_OF_EU_REST_OF_EU
svmat seREST_OF_EU_ROW2
svmat seROW_ROW

rename REST_OF_EU_ROW1 REST_OF_EU_ROW

*withdraw the "1" at the end of the name of each variable of coefficients
local region2 "EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU REST_OF_EU_ROW2 ROW_ROW"
foreach i of local region2{
	generate `i' = REST_OF_EU_ROW + `i'21
	drop `i'21
}

*withdraw the "1" at the end of the name of each variable of standard deviation
local region "REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU REST_OF_EU_ROW2 ROW_ROW"
foreach i of local region{
	rename se`i'1 se`i'
}

drop REST_OF_EU_ROW2
drop seREST_OF_EU_ROW2


*create upperbounds and lowerbounds to build a confidence interval for each region if needed
local region "REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU ROW_ROW"
foreach i of local region{
generate upperbound`i' = `i' + se`i'*1.96
generate lowerbound`i' = `i' - se`i'*1.96
drop se`i'
}

*create a variable for years
local yrs "1995 2000 2005 2008 2009 2010 2011"
generate year = ""
local num_pays 0
foreach i of local yrs {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace year = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring year, replace

*create an index
local var "REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU ROW_ROW upperboundREST_OF_EU_ROW lowerboundREST_OF_EU_ROW upperboundEUROZONE_EUROZONE lowerboundEUROZONE_EUROZONE upperboundEUROZONE_REST_OF_EU lowerboundEUROZONE_REST_OF_EU upperboundEUROZONE_ROW lowerboundEUROZONE_ROW upperboundREST_OF_EU_REST_OF_EU lowerboundREST_OF_EU_REST_OF_EU upperboundROW_ROW lowerboundROW_ROW"
foreach i of local var{
replace `i' = exp(`i') * 100
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_22.dta", replace


clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coeff_region_22.dta"

*plot the graph (without the confidence interval otherwise too many specifications and impossible to read the graph properly)
 graph twoway connected REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU ROW_ROW upperboundREST_OF_EU_ROW lowerboundREST_OF_EU_ROW upperboundEUROZONE_EUROZONE lowerboundEUROZONE_EUROZONE upperboundEUROZONE_REST_OF_EU lowerboundEUROZONE_REST_OF_EU upperboundEUROZONE_ROW lowerboundEUROZONE_ROW upperboundREST_OF_EU_REST_OF_EU lowerboundREST_OF_EU_REST_OF_EU upperboundROW_ROW lowerboundROW_ROW  ///
 year, xlabel(1995(2)2011) ylabel(100(20)220) ///
 title("Evolution of integration 1995-2011") mcolor(red green yellow blue orange pink none none none none none none none none none none none none) ///
lcolor(red green yellow blue orange pink dark dark dark dark dark dark dark dark dark dark dark dark) lpattern(solid solid solid solid solid solid dot dot dot dot dot dot dot dot dot dot dot dot) ///
 legend(order(1 2 3 4 5 6)) ytitle(index) xtitle(year)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph_5_1.gph", replace

end


*-------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*-------------------------------------------------------------------------------
/*

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	clear
	clear matrix
	set more off
	create_y `i'
	compute_X `i'
	foreach j in Yt X {
		compute_totwgt `j'
		table_adjst p `j' `i'
	}
}

foreach i of numlist 1995 2000 2005{
	clear
	clear matrix
	set more off
	create_y `i'
	compute_X `i'

	foreach j in Yt X {
		compute_totwgt `j'
		table_adjst w `j' `i'
	}
}


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X {
		reshape_mean `i' `j' p
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X{
		reshape_mean `i' `j' w
	}
}


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X {
		reshape_mean `i' `j' p _cor
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X{
		reshape_mean `i' `j' w _cor
	}
}

append_mean


nwclear
set more off
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X{
	create_nw_p `j' `i' 0.05
	}
}


foreach i of numlist 1995 2000 2005{
	foreach j in Yt X{
	create_nw_2 `j' `i' w
	}
}


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X{
	create_nw_2 `j' `i' p _cor
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X{
	create_nw_2 `j' `i' w _cor
	}
}

compute_density Yt


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	prepare_gephi p X `i' _cor
}

foreach i of numlist 1995 2000 2005{
	prepare_gephi w Yt `i'
}

foreach i of numlist 1995 2000 2005{
	prepare_gephi w Yt `i' _cor
}

compute_corr p p Yt X 1995 1995

indegree
compute_Y
append_Y
compute_X
append_X
outdegree
data_degree
graph_degree_1
graph_degree_2


global v "p w"
global wgt "X Yt"
foreach i of global v{
	foreach j of global wgt{
			regress_effect `i' `j'
		}
	}
}

regress_effect_2
regress_effect_3
regress_effect_4
regress_effect_5

*(graph of regression 1:)
draw_graph p Yt
draw_graph_2
draw_graph_3
draw_graph_4
draw_graph_5

*/

regress_effect_5

set more on
log close

