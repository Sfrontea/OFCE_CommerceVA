clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off

*----------------------------------------------------------------------------------------
*TO USE ONLY IF table_adjst IS RUN SEPARATELY FROM table_mean (program in commerce_va.do)
*----------------------------------------------------------------------------------------
*Creation of the vector of production Y is required before table_adjst
capture program drop create_y
program create_y
args yrs
clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'

end

*Creation of the vector of export X is required before table_adjst
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
collapse (sum) X, by (pays year)

end

*Creation of the vector of value-added VA is required before table_adjst (even though we did not use it after all)
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

capture program drop compute_totwgt
program compute_totwgt
args wgt yrs
*Compute tot_`wgt' : wgt = Yt or VAt or X. It creates a column vector containing, if Yt, the total production for each country (1*67 lines)
*If X, the total exports for each country.
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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/tot_`wgt'_`yrs'.dta"

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
*This program reshapes existing matrices of mean effects of shocks and tranform them in columns for further computations.
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
*This program appends all reshaped matrices to create a global .dta.
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
/*
It contains the columns : "cause" (which is i the country where the shock comes from), "effect" (which is j the country that receives the shock), "shock" (which is the value
of the average effect of the shock coming from i to j), "shock_type" (which is the type of the shock : shock of price or shock of wage), "weight" (which is the weight used in 
the computation of the weighted average of the effect of the shock : production or export), "year", and "cor" (which is whether the matrix is corrected from the size effect
or not).
*/

end 

*-------------------------------------------------------------------------------
*COMPUTE A MEASURE OF DENSITY TO COMPARE MEAN_EFFECT MATRICES
*-------------------------------------------------------------------------------
*(This program was not used in the study after all.)
capture program drop create_nw_p
program create_nw_p
	args wgt yrs cut
/*
cut : 0.05 : 5% cut on self-loops
This program creates a network from existing matrices of mean effects of shocks and remove all effect that is lower than 5% of the self-loops (a self-loop accounts for the effects of a country i to country i itself).
From the value of the effects, it also computes distances by taking the inverse. We have to cut the elements of the matrix because otherwise when computing density we would
get 1 (as the formula for density is "number of actual vertices in the graph/number of all potential vertices in the graph that could exist between all nodes")
*/
clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_p_`wgt'_`yrs'.dta"

*This takes the average of the self-loops (computing the trace of matrix W).
mkmat shockARG1-shockZAF1, matrix(W)
generate t=trace(W)
generate t2=t/67
*We multiply it by the cut. (-1 to obtain the effects in delta)
generate t3=`cut'*(t2-1)
*Convert into distance
generate t4=1/t3
mkmat t4

*Convert into distance of all elements of the matrix 
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach h of global country{
	gen shock`h'2 = (1/shock`h'1)
	drop shock`h'1
	rename shock`h'2 shock`h'1
}

/*
If the value of an effect of the shock is lower than a certain percentage of the mean of self-loops, we set it at 0. (As we work with distances, it must be greater than
the percentage of self-loop expressed in distance.
*/

set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach c of global country{
	replace shock`c'1 = 0 if shock`c'1 > t4
}

*Creates a network named "ME_p_`wgt'_`yrs'" from the matrix (using nwcommands, the special add-on for networks in STATA)
nwset shockARG1-shockZAF1, name(ME_p_`wgt'_`yrs') labs(ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF)

end

capture program drop compute_density
program compute_density
	args wgt

*Create a table with density per year for Yt, X, VAt
*Density is the number of actual vertices on the graph / the number of all potential vertices between nodes on the graph.
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

/*
Gephi is a software that draws graphs representing networks. It uses two separate databases, one for edges and one for nodes.
This program transforms matrices of mean effects of a shock into two databases, one for edges and one for nodes, that are exported into excel spreadsheet to be imported in the
software Gephi. 
*/

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

*To be visible on the graph, it is better if all elements of the matrix are artificially bigger. That is why we multiply all elements by 1000.
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

foreach i of global country{
gen shock`i'2 = shock`i'1*1000
drop shock`i'1
}

*From the matrix, we create a network using nwcommands, the special add-on for networks in STATA.
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
*Originally we use this program in order to know if matrices are strongly linked whether we use production or export weight. 
*args example: v1=p, v2=p wgt1 = Yt, wgt2 = X, yrs1 = 2011, yrs2 = 2011
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

*The result for our example is that matrices that contain mean effects of a shock of price are strongly close when using production and export weight.The correlation is 0.9977.

end
*-------------------------------------------------------------------------------
*COMPUTE WEIGHTED INDEGREE AND OUTDEGREE OF NODES
*-------------------------------------------------------------------------------
***************************************************************************************************
**************************We compute indegrees***********************************************
***************************************************************************************************
/*
Indegrees are the number of links that come from all nodes and are directed towards node 1. They are weighted because we take into account the "weights" associated, that is the distance between other nodes to node 1 for each indegree.
A weight corresponds to the value of the mean effect of a shock coming from node i to node j.
To compute indegrees of node 1, we sum the weights of all directed edges coming from all nodes to node 1.
*/
capture program drop indegree
program indegree
* We use mean effect non corrected matrices

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor

* We compute the vector of indegrees
replace shock=0 if effect== cause
collapse (sum) shock, by(effect shock_type-year) 
rename shock indegree
rename effect pays
sort year weight shock_type pays, stable
destring year, replace

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_indegree.dta", replace

end
***************************************************************************************************
**************************We compute outdegrees***********************************************
***************************************************************************************************
/*
Outdegrees are the number of links that come from node 1 and are directed towards all other nodes. They are weighted because we take into account the "weight" associated, that is the distance between node 1 to the other node for each outdegree.
A weight corresponds to the value of the mean effect of a shock coming from node 1 to node j.
To compute outdegrees of node 1, we sum the weights of all directed edges coming from node 1 to all other nodes.
*/
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

*We create a .dta that includes all vectors of production of all years.
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
collapse (sum) X, by (pays year)

end

capture program drop append_X
program append_X
*We create a .dta that includes all vectors of export of all years
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_X `i'
	if `i'!=1995 {
	append using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta" 
	}
	save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta", replace
}	

replace pays = "CHNNPR" if pays == "CHN.NPR"
replace pays = "CHNPRO" if pays == "CHN.PRO"
replace pays = "CHNDOM" if pays == "CHN.DOM"
replace pays = "MEXNGM" if pays == "MEX.NGM"
replace pays = "MEXGMF" if pays == "MEX.GMF"
 
sort year , stable
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta", replace
 

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

merge m:1 pays year using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta"
drop _merge
sort cause  year  shock_type weight , stable


merge m:1 pays year using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta"
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

merge m:1 year weight shock_type pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_all_indegree.dta"
drop _merge
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta", replace


/*weigthed outdegrees*/
*Outdegrees are normalized using this formula: outdegree2=outdegree*wgt_DEU/prod with wgt_DEU being the weight in Germany using production or export and prod being
*the production of the country we compute the outedegrees from.

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"
sort pays  year  shock_type weight , stable

merge m:1 pays  year  using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta"
drop _merge
sort pays  year  shock_type weight , stable


merge m:1 pays  year   using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta"
drop _merge

gen wgt_DEU=0
replace wgt_DEU=prod if (weight=="Yt" & pays=="DEU")
replace wgt_DEU=X if (weight=="X" & pays=="DEU")

collapse (sum) wgt_DEU, by(year  shock_type weight )
save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/DEU.dta", replace

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"
merge m:1   year  shock_type weight using DEU.dta
drop _merge

merge m:1 pays  year   using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/prod.dta"
drop _merge
sort pays  year  shock_type weight , stable


merge m:1 pays  year  using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/exports.dta"
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
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"
*-------------------------------------------------------------------------------
* création dummy zone euro
*-------------------------------------------------------------------------------
global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
replace dum_ZE=1 if (country=="`n'")
}


*-------------------------------------------------------------------------------
* graphiques in-degree/out-degree pour chaque année, chaque matrice
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
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/degrees.dta"

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
/*
This program runs a regression corresponding to the first equation we have : 
shock ijt = a * e(alpha ij indicator ij) * e(Bt * indicator t) * e(espilon ijt) 
with shock being the shock effect from country i to country j in period t, indicator ij being the bilateral relationship between two countries, 
indicator t being an indicator for years, epsilon being the error term.
We run this regression for each type of matrix. It takes approximately 45 min.
*/
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

*This command stores results of the regression in memory. To reuse those results later, use command "estimates restore reg1".
estimates store reg1

*Here outreg2 creates a table of results in an excel spreadsheet
outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_`v'_`wgt'.xls, replace label 

*This command test the coefficients of years to be significantly equal
testparm _Iyear_*, equal

set trace off

end

*-------------------------------------------------------------------------------
*REGRESSION 1 BIS
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to shock ijt = a * e(alpha ij indicator ij) * e(Bt * indicator t) 
* e(gamma * indicator gamma) * e(Btgamma * indicator t gamma) * e(espilon ijt)
with shock being the shock effect from the mean effect matrix, indicator ij being the bilateral relationship between two countries,
indicator t being an indicator for years, indicator gamma being an indicator for the type of matrix, indicator t gamma being an interacted variable for both years and 
type of matrix, epsilon being the error term.
There are four types of matrices: p_X (shock of price with export as weight), p_Yt (shock of price with production as weight), w_X (shock of wage with export weight),
w_Yt(shock of wage with production weight).
There is one reference dummy for each indicator :
For indicator ij : ARG_BRA
For indicator t : 1995
For indicator g : p_X (matrix of price shock and export weight)
It takes approximately 45 min.
*/
capture program drop regress_effect_1bis
program regress_effect_1bis

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"

drop if cause == effect
keep if cor == "no"
drop cor
drop if shock==0

gen bilateral = cause+"_"+effect
gen matrix = shock_type+"_"+weight
gen ln_shock = log(shock)
gen matrix_year = matrix +"_"+year
destring year, replace

encode bilateral, generate (nbilateral)
encode matrix, generate (nmatrix)
encode  matrix_year, generate (nmatrix_year)

set more off
regress ln_shock i.nbilateral i.nmatrix##i.year

*This command stores results of the regression in memory. To reuse those results later, use command "estimates restore reg1".
estimates store reg1bis

*outreg2 does not work with this regression because it is too heavy. Can maybe extract results properly with special command in Stata14.

end

*-------------------------------------------------------------------------------
*REGRESSION 2
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to this equation : shock ijt = a * e(alpha i indicator i) * e(g indicator g) * e(alpha j indicator j) 
* e(alpha ig indicator ig)* e(alpha jg indicator jg) * e(Bt indicator Bt) * e(r indicator r) * e(Bt r * indicator t r) * e(espilon ijt) 
with shock being the shock effect from the mean effect matrix, indicator i being the country from which the shock appears, indicator j being the country that receives the 
shock, indicator g is the type of matrix, indicator t being an indicator for years and indicator r an indicator for region, epsilon being the error term.
We have three interacted variables: indicator ig , indicator jg, indicator tr.
There are 4 regions : ASIA_ASIA, EU_EU, NAFTA_NAFTA, ROW_ROW and their interactions ASIA_EU, ASIA_NAFTA, ASIA_ROW, EU_NAFTA, EU_ROW, NAFTA_ROW.
There is one reference dummy for each category :
For indicator i : ARG
For indicator j : BRA
For indicator g : p_X (matrix of price shock and export weights
For indicator t : 1995
For indicator r : ASIA_ROW
Stata omits those categories for collinearity:
causexmatrix ZAF-wX, ZAF-wYt
region 7, 9, 10 (EU_ROW, NAFTA_ROW, ROW_ROW)
The regression takes less than 1 min.
*/
capture program drop regress_effect_2
program regress_effect_2

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

estimates store reg2
outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_2.xls, replace label
/*
You have to read the results in a different way. Indeed, when we tell Stata to use interacted variable like i.ncause##i.nmatrix for example, Stata decomposes the coefficients and creates an indicator for
cause, an indicator for matrix and an indicator for cause and matrix. Thus, when we want to understand the result coefficients for region x year, we have to know that the coefficients
for years correspond in fact to the reference category region of ASIA_ROW. Coefficients for other regions are the difference from the reference coefficients of ASIA_ROW. 
To plot the graph, we should therefore compute coeff of region + coeff of ASIA_ROW to get the coefficient we are interested in. The indicator "region" is a fixed effect (it changes the levels only)
But we are interested in the impact of time on shocks. The constant corresponds to the mean of the situation of reference, it is the value when all dummies = 0.
*/

/*
*Test for the equality of coefficients:
testparm i.nregion#year, equal
testparm i.nregion, equal
*/

end
*-------------------------------------------------------------------------------
*REGRESSION 3
*-------------------------------------------------------------------------------
/*
This program runs a regression corresponding to this equation : shock ijt = a * e(alpha i indicator i) * e(g indicator g) * e(alpha j indicator j) * e(alpha ig indicator ig)
* e(alpha jg indicator jg) * e(Bt indicator Bt) * e(r indicator r) * e(Bt r * indicator t r) * e(espilon ijt) with shock being the shock effect from the mean effect matrix,
indicator i being the country from which the shock appears, indicator j being the country that receives the shock, indicator g is the type of matrix.
indicator t being an indicator for years and inficator r an indicator for region, epsilon being the error term.
We have three interacted variables : indicator ig , indicator jg, indicator tr.
There are 4 regions : EUROZONE_EUROZONE, REST_OF_EU_REST_OF_EU, ROW_ROW, and their interactions EUROZONE_REST_OF_EU, EUROZONE_ROW, REST_OF_EU_ROW.
There is one reference dummy for each indicator :
For indicator i : ARG
For indicator j : BRA
For indicator g : p_X (matrix of price shock and export weight)
For indicator t : 1995
For indicator r : Rest of EU-ROW
Stata omits those categories for collinearity:
causexmatrix ZAF-wX, ZAF-wYt
region 3 and 6 (EUROZONE_ROW, ROW_ROW)
The regression takes less than 1 min.
*/
capture program drop regress_effect_3
program regress_effect_3

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

estimates store reg3
outreg2 using /Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/result_3.xls, replace label

/*
*According to the graph_5 we have the intuition that the coefficients for ROW_ROW are significantly different from those of other regions. But other region's curves seem very embedded.
*We test if the coefficients for those regions_year (except ROW_ROW) are significantly different (looking at pace of evolution).

testparm 1o.nregion#1995b.year 1.nregion#2000.year 1.nregion#2005.year 1.nregion#2008.year 1.nregion#2009.year 1.nregion#2010.year 1.nregion#2011.year ///
2o.nregion#1995b.year 2.nregion#2000.year 2.nregion#2005.year 2.nregion#2008.year 2.nregion#2009.year 2.nregion#2010.year 2.nregion#2011.year 3o.nregion#1995b.year 3.nregion#2000.year 3.nregion#2005.year 3.nregion#2008.year 3.nregion#2009.year 3.nregion#2010.year 3.nregion#2011.year 4o.nregion#1995b.year 4.nregion#2000.year 4.nregion#2005.year 4.nregion#2008.year 4.nregion#2009.year 4.nregion#2010.year 4.nregion#2011.year ///
5b.nregion#1995b.year 5b.nregion#2000o.year 5b.nregion#2005o.year 5b.nregion#2008o.year 5b.nregion#2009o.year 5b.nregion#2010o.year 5b.nregion#2011o.year, equal

Looking at levels (indicator r only):
testparm i.nregion, equal
*/

end
*---------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 1
*---------------------------------------------------------------------------------------------------
*Graph with one curve only. X-axis : years. Y-axis : indices of coefficients of years
capture program drop draw_graph_1
program draw_graph_1
	args v wgt
	*with v = p or w, wgt = Yt or X
clear
set more off

regress_effect `v' `wgt'

*Once finished :
*gen a variable coeff of coefficients (take from e(b) )
*gen a variable se of standard deviation (�cart-type also called "standard error" in Stata)
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

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph1.gph", replace

end

*---------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 1 BIS
*---------------------------------------------------------------------------------------------------
*Graph with four curves by types of matrices. X-axis : years. Y-axis : indices of coefficients of years 
capture program drop draw_graph_1bis
program draw_graph_1bis

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

generate upperbound = coeff+se*1.96
generate lowerbound = coeff-se*1.96

set more off
gen category = ""
local num_pays 0
forvalues i = 1/4462{
	foreach j of numlist 1/1 {
		local ligne = `j' + 1 *`num_pays'
		replace category = "`i'" in `ligne'
	}
	local num_pays = `num_pays'+1
}

destring category, replace

keep if category > 4426
drop if category == 4462

local mat_year "p_X p_X2 p_Y w_X w_Y"
generate matrix_year = ""
local num_matyrs 0
foreach i of local mat_year {
	foreach j of numlist 1/7 {
		local ligne = `j' + 7*`num_matyrs'
		replace matrix_year = "`i'" in `ligne'
	}
	local num_matyrs = `num_matyrs'+1
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta", replace

*create a variable of coefficient for each region as well as a variable of standard deviation
clear
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta"
keep if matrix_year == "p_X"
generate p_X = coeff
generate sep_X = se
mkmat p_X
mkmat sep_X

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta"

keep if matrix_year == "p_X2"
generate p_X22 = coeff if matrix_year == "p_X2"
generate sep_X2 = se
mkmat p_X22
mkmat sep_X2

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta"

keep if matrix_year == "p_Y"
generate p_Y2 = coeff if matrix_year == "p_Y"
generate sep_Y = se
mkmat p_Y2
mkmat sep_Y

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta"

keep if matrix_year == "w_X"
generate w_X2 = coeff
generate sew_X = se
mkmat w_X2
mkmat sew_X

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_1bis.dta"
keep if matrix_year == "w_Y"
generate w_Y2 = coeff
generate sew_Y = se
mkmat w_Y2
mkmat sew_Y

clear
svmat p_X
svmat p_X22
svmat p_Y2
svmat w_X2
svmat w_Y2
svmat sep_X
svmat sep_X2
svmat sep_Y
svmat sew_X
svmat sew_Y

rename p_X1 p_X


*withdraw the "1" at the end of the name of each variable of standard deviation
local mat_year2 "p_X p_X2 p_Y w_X w_Y"
foreach i of local mat_year2{
	rename se`i'1 se`i'
}

*withdraw the "1" at the end of the name of each variable of coefficients
local mat_year "p_X2 p_Y w_X w_Y"
foreach i of local mat_year{
	generate `i' = p_X + `i'21
	drop `i'21
}

drop p_X2
drop sep_X2

*create upperbounds and lowerbounds to build a confidence interval for each region if needed
local mat_year "p_X p_Y w_X w_Y"
foreach i of local mat_year{
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


local yrs2 "2008 2009 2010 2011"
foreach i of local yrs2{
	replace w_X = . if year == `i'
	replace upperboundw_X = . if year == `i'
	replace lowerboundw_X = . if year == `i'
	replace w_Y = . if year == `i'
	replace upperboundw_Y = . if year == `i'
	replace lowerboundw_Y = . if year == `i'
}



*create an index
local var "p_X p_Y w_X w_Y upperboundp_X lowerboundp_X upperboundp_Y lowerboundp_Y upperboundw_X lowerboundw_X upperboundw_Y lowerboundw_Y"
foreach i of local var{
replace `i' = exp(`i') * 100
}

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph1bis.dta", replace

clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph1bis.dta"

*plot the graph (without the confidence interval otherwise too many specifications and impossible to read the graph properly)
graph twoway connected p_X p_Y w_X w_Y upperboundp_X lowerboundp_X upperboundp_Y lowerboundp_Y upperboundw_X lowerboundw_X upperboundw_Y lowerboundw_Y ///
 year, xlabel(1995(2)2011) ///
 title("Evolution of integration 1995-2011") mcolor(red green yellow blue none none none none none none none  none none none) ///
lcolor(red green yellow blue black black black black black black black black black black) lpattern(solid solid solid solid dot dot dot dot dot dot dot dot) ///
 legend(order(1 2 3 4)) ytitle(index) xtitle(year)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph1bis.gph", replace

end

*------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 2
*------------------------------------------------------------------------------------------------
*Graph with 10 curves : four regions and their interactions. X-axis: years, Y-axis: indices of coefficients of years
capture program drop draw_graph_2
program draw_graph_2

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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta", replace

*create a variable of coefficient for each region as well as a variable of standard deviation
clear
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "ASIA_ROW"
generate ASIA_ROW = coeff
generate seASIA_ROW = se
mkmat ASIA_ROW
mkmat seASIA_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"

keep if region == "ASIA_ASIA"
generate ASIA_ASIA2 = coeff if region == "ASIA_ASIA"
generate seASIA_ASIA = se
mkmat ASIA_ASIA2
mkmat seASIA_ASIA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"

keep if region == "ASIA_EU"
generate ASIA_EU2 = coeff if region == "ASIA_EU"
generate seASIA_EU = se
mkmat ASIA_EU2
mkmat seASIA_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"

keep if region == "ASIA_NAFTA"
generate ASIA_NAFTA2 = coeff
generate seASIA_NAFTA = se
mkmat ASIA_NAFTA2
mkmat seASIA_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "ASIA_ROW2"
generate ASIA_ROW2 = coeff
generate seASIA_ROW2 = se
mkmat ASIA_ROW2
mkmat seASIA_ROW2

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "EU_EU"
generate EU_EU2 = coeff
generate seEU_EU = se
mkmat EU_EU2
mkmat seEU_EU


clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "EU_NAFTA"
generate EU_NAFTA2 = coeff
generate seEU_NAFTA = se
mkmat EU_NAFTA2
mkmat seEU_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "EU_ROW"
generate EU_ROW2 = coeff
generate seEU_ROW = se
mkmat EU_ROW2
mkmat seEU_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "NAFTA_NAFTA"
generate NAFTA_NAFTA2 = coeff
generate seNAFTA_NAFTA = se
mkmat NAFTA_NAFTA2
mkmat seNAFTA_NAFTA

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
keep if region == "NAFTA_ROW"
generate NAFTA_ROW2 = coeff
generate seNAFTA_ROW = se
mkmat NAFTA_ROW2
mkmat seNAFTA_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_2.dta"
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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph2.dta", replace


clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph2.dta"

*plot the graph (without the confidence interval otherwise too many specifications and impossible to read the graph properly)
graph twoway connected ASIA_ROW ASIA_ASIA ASIA_EU ASIA_NAFTA EU_EU EU_NAFTA EU_ROW NAFTA_NAFTA NAFTA_ROW ROW_ROW ///
 year, xlabel(1995(2)2011) ///
mcolor(red green yellow blue orange lavender pink emerald gold olive) ///
lcolor(red green yellow blue orange lavender pink emerald gold olive dark) lpattern(solid solid solid solid solid solid solid solid solid solid) ///
 legend(order(1 2 3 4 5 6 7 8 9 10)) ytitle(index) xtitle(year)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph2.gph", replace

end
*---------------------------------------------------------------------------------------------------
*PLOT A GRAPH WITH YEARS ON AXIS AND COEFFICIENTS FROM REGRESSION ON ORDINATE FROM REGRESSION 3
*---------------------------------------------------------------------------------------------------
*Graph with 6 curves : three regions and their interactions. X-axis: years, Y-axis: indices of coefficients of years
capture program drop draw_graph_3
program draw_graph_3

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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta", replace

*create a variable of coefficient for each region as well as a variable of standard deviation
clear
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if region == "REST_OF_EU_ROW"
generate REST_OF_EU_ROW = coeff
generate seREST_OF_EU_ROW = se
mkmat REST_OF_EU_ROW
mkmat seREST_OF_EU_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"

keep if region == "EUROZONE_EUROZONE"
generate EUROZONE_EUROZONE2 = coeff if region == "EUROZONE_EUROZONE"
generate seEUROZONE_EUROZONE = se
mkmat EUROZONE_EUROZONE2
mkmat seEUROZONE_EUROZONE

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"

keep if region == "EUROZONE_REST_OF_EU"
generate EUROZONE_REST_OF_EU2 = coeff if region == "EUROZONE_REST_OF_EU"
generate seEUROZONE_REST_OF_EU = se
mkmat EUROZONE_REST_OF_EU2
mkmat seEUROZONE_REST_OF_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"

keep if region == "EUROZONE_ROW"
generate EUROZONE_ROW2 = coeff
generate seEUROZONE_ROW = se
mkmat EUROZONE_ROW2
mkmat seEUROZONE_ROW

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if region == "REST_OF_EU_REST_OF_EU"
generate REST_OF_EU_REST_OF_EU2 = coeff
generate seREST_OF_EU_REST_OF_EU = se
mkmat REST_OF_EU_REST_OF_EU2
mkmat seREST_OF_EU_REST_OF_EU

clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
keep if region == "REST_OF_EU_ROW2"
generate REST_OF_EU_ROW22 = coeff
generate seREST_OF_EU_ROW2 = se
mkmat REST_OF_EU_ROW22
mkmat seREST_OF_EU_ROW2


clear
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/coefficients_3.dta"
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

save "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph3.dta", replace


clear
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/graph3.dta"

*plot the graph (without the confidence interval otherwise too many specifications and impossible to read the graph properly)
 graph twoway connected REST_OF_EU_ROW EUROZONE_EUROZONE EUROZONE_REST_OF_EU EUROZONE_ROW REST_OF_EU_REST_OF_EU ROW_ROW upperboundREST_OF_EU_ROW lowerboundREST_OF_EU_ROW upperboundEUROZONE_EUROZONE lowerboundEUROZONE_EUROZONE upperboundEUROZONE_REST_OF_EU lowerboundEUROZONE_REST_OF_EU upperboundEUROZONE_ROW lowerboundEUROZONE_ROW upperboundREST_OF_EU_REST_OF_EU lowerboundREST_OF_EU_REST_OF_EU upperboundROW_ROW lowerboundROW_ROW  ///
 year, xlabel(1995(2)2011) ylabel(100(20)220) ///
 mcolor(red green yellow blue orange pink none none none none none none none none none none none none) ///
lcolor(red green yellow blue orange pink dark dark dark dark dark dark dark dark dark dark dark dark) lpattern(solid solid solid solid solid solid dot dot dot dot dot dot dot dot dot dot dot dot) ///
 legend(order(1 2 3 4 5 6)) ytitle(index) xtitle(year)

graph save Graph "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/graph3.gph", replace

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

