clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off


*-------------------------------------------------------------------------------
*RESHAPE TABLES OF MEAN EFFECT .dta
*-------------------------------------------------------------------------------
capture program drop reshape_mean
program reshape_mean
args yrs wgt v 
* yrs = years, wgt = weight : Yt (production) or VAt (value-added) or X (export), v = vector of shock : p (price) or w (wage), _cor : either type _cor if use corrected from size effect matrix or put nothing if use the non-corrected one
*This program reshapes existing matrices of mean effects of shocks and tranform them in columns for further computations.
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_`v'_`wgt'_`yrs'.dta"
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

save "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_`v'_`wgt'_`yrs'_2.dta", replace

end


*-------------------------------------------------------------------------------
*APPEND ALL TYPES OF TABLES OF MEAN EFFECT TO CREATE A GLOBAL TABLE
*-------------------------------------------------------------------------------
capture program drop append_mean
program append_mean
*This program appends all reshaped matrices to create a global .dta.
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_p_Yt_1995_2.dta"
replace cause = subinstr(cause,"1","",.)

append using "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_p_X_1995_2.dta"

foreach i of numlist 2000 2005 2008 2009 2010 2011{
	foreach j in Yt X {
		append using "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_p_`j'_`i'_2.dta"
	}
}

foreach i of numlist 1995 2000 2005{
	foreach j in Yt X {
		append using "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_w_`j'_`i'_2.dta"
	}
}


replace cause = subinstr(cause,"1","",.)

save "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_all.dta", replace
/*
It contains the columns : "cause" (which is i the country where the shock comes from), "effect" (which is j the country that receives the shock), "shock" (which is the value
of the average effect of the shock coming from i to j), "shock_type" (which is the type of the shock : shock of price or shock of wage), "weight" (which is the weight used in 
the computation of the weighted average of the effect of the shock : production or export), "year", and "cor" (which is whether the matrix is corrected from the size effect
or not).
*/

end 



*-------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*-------------------------------------------------------------------------------



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

append_mean

***************************************************************************************************
************************** On calcule des effets moyens en agrégeant Chine et Mexique ***********************************************
***************************************************************************************************


capture program drop concat_CHN_MEX_mean_effect

program concat_CHN_MEX_mean_effect

capture use "$dir/Bases/mean_effect/mean_all.dta"

/*
display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	use "$dir/Results mean_effect/mean_all.dta"
}
*/


*On agrège sur le pays cause

replace cause="CHN" if (cause=="CHN" | cause=="CHNDOM" |cause=="CHNNPR" |cause=="CHNPRO" )
replace cause="MEX" if (cause=="MEX" | cause=="MEXGMF" |cause=="MEXNGM"  )

collapse (sum) shock, by(cause effect shock_type-year)  

* On merge avec prod.dta et exports.dta pour aggréger sur le pays effet

gen pays=effect
destring year, replace


merge m:1 pays year using "H:\Agents\Cochard\Papier_chocCVA\Bases/prod.dta"
drop _merge
sort cause  year  shock_type weight , stable


merge m:1 pays year using "H:\Agents\Cochard\Papier_chocCVA\Bases/exports.dta"
drop _merge

* On calcule la somme des exports et production pour la chine et le mexique

gen effect2=effect
replace effect2="CHN" if (effect=="CHN" | effect=="CHNDOM" |effect=="CHNNPR" |effect=="CHNPRO" )
replace effect2="MEX" if (effect=="MEX" | effect=="MEXGMF" |effect=="MEXNGM"  )

bys cause effect2 year  shock_type weight : egen somme_prod=total(prod)
bys cause effect2 year  shock_type weight  : egen somme_X=total(X)

gen shock_pond=shock*prod/somme_prod
replace shock_pond=shock*X/somme_X if weight=="X"


drop pays effect shock
collapse (sum) shock_pond prod X, by(cause effect2 shock_type-year)  

rename shock_pond shock
rename effect2 effect

save "$dir/Bases/mean_effect/concat_CHN_MEX_mean_effect.dta", replace

end

concat_CHN_MEX_mean_effect



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
		compute_totwgt `j' `i'
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

regress_effect_1bis
regress_effect_2
regress_effect_3


*(graph of regression 1:)
draw_graph_1 p Yt

draw_graph_1bis
draw_graph_2
draw_graph_3


*/

regress_effect_2
draw_graph_2

set more on
log close

