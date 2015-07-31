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


***************************************************************************************************
* 3- We multiply the transposed matrix of weights by the matrix of mean effects and we keep the diagonal vector
***************************************************************************************************
capture program drop outdegree
program outdegree

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor
rename effect pays
destring year, replace

merge m:1 pays year using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta"
rename pays effect
rename prod prod_effect

replace prod_effect = 0 if effect==cause
bys effect cause year shock shock_type weight: egen somme_des_poids=total(prod)

end

capture program drop omega
program omega

/*
import excel "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\mean_effect/mean_p_X_`yrs'.xls", firstrow 
mkmat shockARG1-shockZAF1, matrix(M)
matrix OMt = Omega_`yrs''  /*matrice des pondérations oméga
*/ 

matrix OUTDEGREE=OMt*M
mat outegree_`yrs'=vecdiag(OUTDEGREE)

svmat OUTDEGREE
save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata/outdegree_`yrs'.dta", replace

export excel using "C:\Users\L841580\Desktop\I-O-Stan\bases_stata/outdegree_`yrs'.xls", firstrow(variables) 

end

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	clear matrix
	set more off
	create_y `i'
	omega `i'
	outdegree `i'
}

*---------------------------------------------------------------------------------------
*REGRESSION TO BETTER UNDERSTAND THE RELATIONSHIP BETWEEN YEARS AND SHOCK EFFECT
*---------------------------------------------------------------------------------------
*This program runs a regression corresponding to the first equation we have : shock ijt = a * e(alpha ij indicator ij) * e(Bt * indicator t) * e(espilon ijt) with shock being the shock effect from the mean effect matrix, alpha ij being the bilateral relationship between two countries, Bt being an indicator for years, epsilon being the error term.
capture program drop regress_effect
program regress_effect
	args v wgt cor
* v -> p or w
*wgt -> Yt or X
* cor -> yes or no
clear
set more off
set trace on 
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"

keep if shock_type == "`v'"
keep if weight == "`wgt'"
keep if cor == "`cor'"

gen bilateral = cause+"_"+effect
gen type = shock_type+"_"+weight+"_"+cor
gen ln_shock = log(shock)
drop if shock==0

xi : reg ln_shock i.bilateral i.year

outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_`v'_`wgt'_`cor'.xls, replace label 
testparm _Iyear_*, equal

set trace off

end

capture program drop regress_effect_2
program regress_effect_2

clear all
set maxvar 30000
set matsize 11000
set more off
set trace on 
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"


gen ln_shock = log(shock)

gen type_cause = cause+"_"+shock_type+"_"+weight+"_"+cor

gen type_effect = effect+"_"+shock_type+"_"+weight+"_"+cor

gen region = ""
global eurozone "AUT BEL DEU CYP ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
global restEU "BGR CZE DNK GBR HRV HUN NOR POL ROU SWE"
global rest "ARG AUS BRA BRN CAN CHL CHN CHNDOM CHNNPRE CHNPRO COL CRI HKG IDN IND ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NZL PHL ROW RUS SAU SGP THA TUN TUR TWN USA VNM ZAF"


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

xi i.type_cause i.type_effect i.yearregion

reg ln_shock _Itype_caus_2-_Itype_caus_4 _Itype_caus_13-_Itype_effe_536 _Iyearregio_3-_Iyearregio_35


outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_with_region.xls, replace label 

testparm _Iyearregio_*, equal

set more on
set trace off

end

*-------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE
*-------------------------------------------------------------------------------
program drop draw_graph
program draw_graph
	args v wgt cor
	*with v = p or w, wgt = Yt or X, cor = no or yes
clear
set more off

regress_effect `v' `wgt' `cor'

*Once finished :
*gen a variable coeff of coefficients (take from e(b) )
*gen a variable se of standard deviation (�cart-type also called "standard error" in Stata)
*gen a variable year with 2000 to 2011

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
forvalues i = 1/4495{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

*Drop the very last coefficient (corresponding to the constant), and keep the last six coefficients corresponding to 2000, 2005, 2008, 2009, 2010, 2011

drop if category == "4495"
keep if category == "4489" | category == "4490" | category == "4491" | category == "4492" | category == "4493" | category == "4494"


local yrs "2000 2005 2008 2009 2010 2011"
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

generate upperbound = se+1.96
generate lowerbound = se-1.96

graph twoway line coeff year, xlabel(2000(1)2011) ylabel(0(0.05)0.63) title("Evolution of density 2000-2011")

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/Graph_evolution_1.gph", replace


line coeff upperbound lowerbound year, xlabel(2000(1)2011) ylabel(-1.66(1)2.6) title("Evolution of density 2000-2011")

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/Graph_evolution_2.gph", replace

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

global v "p w"
global wgt "X Yt"
global cor "no yes"
foreach i of global v{
	foreach j of global wgt{
		foreach k of global cor{
			regress_effect `i' `j' `k'
		}
	}
}

regress_effect_2

draw_graph p Yt no

*/


set more on
log close
