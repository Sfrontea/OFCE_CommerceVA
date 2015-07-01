*------------------------------------------------------------------------------------
*ADJUSTMENT OF THE TABLE OF MEAN EFFECTS OF A PRICE SHOCK TO REMOVE THE SIZE EFFECT
*------------------------------------------------------------------------------------
capture program drop table_adjst
program table_adjst
args v wgt yrs
clear
set matsize 7000
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'.dta"

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
*tot_Yt is the vector of total production by country
svmat tot_Yt
*We standardize by the size of Germany. YDEU stands for the German total production
gen YDEU = 6823167.5
gen B = YDEU/tot_Yt

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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_`v'_`wgt'_`yrs'_cor.dta", replace

end

*-------------------------------------------------------------------------------
*RESHAPE TABLES OF MEAN EFFECT .dta
*-------------------------------------------------------------------------------
capture program drop reshape_mean
program reshape_mean
args yrs wgt v

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

*-------------------------------------------------------------------------------
*APPEND ALL TYPES OF TABLES OF MEAN EFFECT TO CREATE A GLOBAL TABLE
*-------------------------------------------------------------------------------
capture program drop append_mean
program append_mean
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_w_VAt_1995_2.dta"

foreach i of numlist 2000 2005 {
	foreach j in VAt Yt X {
append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_w_`j'_`i'_2.dta"
	}
}


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {
	foreach j in VAt Yt X {
		append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`j'_`i'_2.dta"
		}
}

end

*-------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*-------------------------------------------------------------------------------

/*
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X VAt{
		table_adjst p `j' `i'
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X VAt{
		table_adjst w `j' `i'
	}
}
*/

