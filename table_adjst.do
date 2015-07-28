clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "/Users/sandrafronteau/Documents/Stage_OFCE/Stata"

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
capture program drop compute_degree
program compute_degree

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cause == effect
collapse (sum) shock, by(cause shock_type-cor) 
rename shock outdegree
rename cause country

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_outdegree.dta", replace

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cause == effect
collapse (sum) shock, by(effect shock_type-cor) 
rename shock indegree
rename effect country

merge 1:1 country-cor  using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_outdegree.dta"
drop _merge

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_inou.dta"

export excel using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_inou.xls", firstrow(variables)

end

*---------------------------------------------------------------------------------------
*REGRESSION TO BETTER UNDERSTAND THE RELATIONSHIP BETWEEN YEARS, REGION AND SHOCK EFFECT
*---------------------------------------------------------------------------------------
*---------------------------------------------------------------------------------------
*REGRESSION TO BETTER UNDERSTAND THE RELATIONSHIP BETWEEN YEARS, REGION AND SHOCK EFFECT
*---------------------------------------------------------------------------------------
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

set trace off

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
*/
regress_effect w Yt no
regress_effect w X no
testparm _Iyear_*, equal




set more on
log close
