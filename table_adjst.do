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

end

*----------------------------------------------------------------------------------
*ADJUSTMENT OF THE TABLE OF MEAN EFFECTS OF A PRICE SHOCK TO REMOVE THE SIZE EFFECT
*----------------------------------------------------------------------------------
capture program drop table_adjst
program table_adjst
args v wgt yrs
* yrs = years, wgt = weight : Yt (production) or VAt (value-added) or X (export), v = vector of shock : p (price) or w (wage)
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta"

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

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

gen `wgt'DEU = tot_`wgt'1 if k == "DEU"
replace `wgt'DEU = `wgt'DEU[19] if missing(`wgt'DEU)


gen B = `wgt'DEU/tot_`wgt'

mkmat B

local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1*`num_pays'
		scalar b`i' = B[`ligne',1]
		gen new_shock`i'= b`i' * shock`i'1
	}
local num_pays = `num_pays'+1
}

drop shockARG1-shockZAF1
drop tot_`wgt'1
drop `wgt'DEU
drop B

rename cause country_of_shock
rename effect country_shocked
rename shock intensity

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'_cor.dta", replace

end

*-------------------------------------------------------------------------------
*RESHAPE TABLES OF MEAN EFFECT .dta
*-------------------------------------------------------------------------------
capture program drop reshape_mean
program reshape_mean
args yrs wgt v
* yrs = years, wgt = weight : Yt (production) or VAt (value-added) or X (export), v = vector of shock : p (price) or w (wage)

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta"
set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

generate k = ""
local num_pays 0
foreach i of global country {
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace k = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

order shockARG1-shockZAF1, alphabetic after (k)
reshape long shock, i(k) j(cause) string
rename k effect
order cause, first
sort cause effect-shock

gen shock_type = "`v'"
gen weight = "`wgt'"
gen year = "`yrs'"

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'_2.dta", replace

end


*-------------------------------------------------------------------------------
*APPEND ALL TYPES OF TABLES OF MEAN EFFECT TO CREATE A GLOBAL TABLE
*-------------------------------------------------------------------------------
capture program drop append_mean
program append_mean
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_VAt_1995_2.dta"

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	foreach j in VA Y X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`j'_`i'_2.dta"
		}
}

foreach i of numlist 2000 2005 {
	foreach j in VA Y X {
append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_w_`j'_`i'_2.dta"
	}
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all_cor.dta"

end 

*-------------------------------------------------------------------------------
*COMPUTE A MEASURE OF DENSITY TO COMPARE MEAN_EFFECT MATRICES
*-------------------------------------------------------------------------------
capture program drop compute_density
program compute_density
args v wgt yrs
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta"


set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country{
gen shock`i'2 = (1/shock`i'1)
drop shock`i'1
rename shock`i'2 shock`i'1
}

save "/Users/sandrafronteau/Desktop/mean_`v'_`wgt'_`yrs'_3.dta", replace

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU RoW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country{
replace shock`i'1 = 0 if shock`i'1 > 500
}

foreach i  of global country{
egen m_`i'1 = mean(shock`i'1)
}

egen d = rowtotal(m_ARG1-m_ZAF1)
rename d d_`yrs'
mkmat d_`yrs'
*d is a measure of integration
end

capture program drop table_density
program table_density
clear
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt VAt X{
		compute_density p `j' `i'
	}
}

clear
set more off
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	svmat d_`i'
}

end

*-------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*-------------------------------------------------------------------------------

/*
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X VAt{
		clear
		clear matrix
		set more off
		create_y `i'
		compute_X `i'
		compute_VA `i'
		compute_totwgt `j'
		table_adjst p `j' `i'
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X VAt{
		clear
		clear matrix
		set more off
		create_y `i'
		compute_X `i'
		compute_VA `i'
		compute_totwgt `j'
		table_adjst w `j' `i'
	}
}

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in VAt Yt X {
		reshape_mean `i' `j' p
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in VAt Yt X{
		reshape_mean `i' `j' w
	}
}

append_mean

table_density

*/


set more on
log close
