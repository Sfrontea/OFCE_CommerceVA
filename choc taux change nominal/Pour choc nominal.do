clear
** À partir de commerce_va

if ("`c(hostname)'"=="W7-Rifflart") global dir "C:\Users\christine.rifflart\Dropbox\commerce en VA\Choc_CVA\Data\Bases stata"


*capture log using "H:\Agents\Cochard\Papier_chocCVA/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
*global dir "H:\Agents\Cochard\Papier_chocCVA"

*-------------------------------------------------------------------------------
*COMPUTING LEONTIEF INVERSE MATRIX  : matrix L1
*-------------------------------------------------------------------------------
clear
set more off
*set matsize 7000
capture program drop compute_leontief_chocnom
program compute_leontief_chocnom
	args yrs groupeduchoc
*ex : compute_leontief_chocnom 2005 "chn chnnpr chnpro chndom"	
*Create vector Y of output from troncated database
clear
*use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD_`yrs'_OUT.dta"
if ("`c(hostname)'"=="W7-Rifflart") use  "C:\Users\christine.rifflart\Dropbox\commerce en VA\Choc_CVA\Data\Bases stata/OECD_`yrs'_OUT.dta"
local sector6 "c10t14 c15t16 c17t19 c20 c21t22 c23 c24 c25 c26 c27 c28 c29 c30t33x c31 c34 c35 c36t37 c40t41 c45 c50t52 c55 c60t63 c64 c65t67 c70 c71 C72 c73t74 c75 c80 c85 c90t93 c95"

generate groupeduchoc_c10t14 = cze_c10t14 + svk_c10t14


mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)

end

compute_leontief_chocnom 2005 "cze svk"


*Create matrix Z of inter-industry inter-country trade
use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD_`yrs'_Z.dta"
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

display "fin de compute_leontief" `yrs'

end

*-------------------------------------------------------------------------------
*COMPUTING THE FINAL DEMAND VECTOR : matrix F
*-------------------------------------------------------------------------------
capture program drop compute_fd
program compute_fd
	args yrs
*Create a final demand column-vector for all countries with a loop
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/finaldemand_`yrs'.dta"

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
*COMPUTING A VECTOR CONTAINING THE WAGE SHARES IN PRODUCTION : matrix S
*-------------------------------------------------------------------------------
capture program drop compute_wage
program compute_wage
	args yrs
clear
*set matsize 7000
set more off
use "H:\Agents\Cochard\Papier_chocCVA\Bases/WAGE_`yrs'.dta"
mkmat WAGE, matrix (W)
use "H:\Agents\Cochard\Papier_chocCVA\Bases/OUT_`yrs'.dta"
mkmat OUT, matrix (O)
*Note: this is not the same output vector as Y. Indeed O comes from the wage database. For now, I use O for output in this section to distinguish from Y.

matrix Od=diag(O)
matrix Od1=invsym(Od)
matrix S=Od1*W
*S is the column-vector containing the wage shares in production
end

*---------------------------------------------------------------------------------------------
*COMPUTING THE EFFECT OF A SHOCK ON INPUT PRICES IN ONE SECTOR OF ONE COUNTRY ON OUTPUT PRICES : matrix P`cty'
*---------------------------------------------------------------------------------------------
capture program drop vector_shock_p
program vector_shock_p
		args shk cty
clear
*set matsize 7000
set more off
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/csv.dta"


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
clear
*set matsize 7000
set more off
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/csv.dta"
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
*Creation of the vector Y is required before table_adjst : matrix Yt
capture program drop create_y
program create_y
args yrs
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'

end

*Creation of the vector of export X : matrix X
capture program drop compute_X
program compute_X
	args yrs

use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD`yrs'.dta", clear

global country2 "arg aus aut bel bgr bra brn can che chl chn chn.npr chn.pro chn.dom col cri cyp cze deu dnk esp est fin fra gbr grc hkg hrv hun idn ind irl isl isr ita jpn khm kor ltu lux lva mex mex.ngm mex.gmf mlt mys nld nor nzl phl pol prt rou row rus sau sgp svk svn swe tha tun tur twn usa vnm zaf"

generate pays = strlower(substr(v1,1,strpos(v1,"_")-1))
drop if pays==""

egen utilisations = rowtotal(arg_c01t05agr-disc)
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

*Creation of the vector of value-added VA : matrices Y, X, VA

capture program drop compute_VA
program compute_VA
	args yrs
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD`yrs'.dta"
keep if v1 == "VA.TAXSUB"
drop v1
mkmat arg_c01t05agr-zaf_c95pvh, matrix(VA)
matrix VAt = VA'
end

capture program drop compute_mean    // matrix shock`cty'
program compute_mean
	args cty wgt
clear
*set matsize 7000
set more off
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/csv.dta"
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
*set matsize 7000
set trace on
set more off
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global country {
	vector_shock_p `shk' `i'   //
	if ("`v'"=="w") {
	vector_shock_w `shk' `i'
	}
	shock_price `i' `v'
	create_y `yrs'
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
save "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_`v'_`wgt'_`yrs'.dta", replace
*We obtain a table of mean effect of a price shock from each country to all countries

export excel using "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/mean_`v'_`wgt'_`yrs'.xls", firstrow(variables)

set trace off
set more on

end


*-------------------------------------------------------------------------------
*DEVALUATION OF THE EURO
*-------------------------------------------------------------------------------
*What happens when the euro is devaluated? To know that, we do a shock of 1 on all countries but the eurozone.
capture program drop shock_deval
program shock_deval
	args shk zone
*shk = 1, zone = noneuro (for a shock corresponding to a devaluation of the euro), china or eastern

set matsize 7000
set more off
clear
use "H:\Agents\Cochard\Papier_chocCVA\Bases/csv.dta"

global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"

local eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
local noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CZE DNK GBR HKG HRV HUN IDN IND ISL ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"
local china "CHN CHNDOM CHNNPR CHNPRO"
local eastern "BGR CZE HRV HUN POL ROU "

foreach i of local `zone'{
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


capture program drop compute_mean_deval
program compute_mean_deval
	args yrs zone
set matsize 7000
clear
set more off
use "H:\Agents\Cochard\Papier_chocCVA\Bases/csv.dta"
svmat Yt
svmat X

*I decide whether I use the production or export or value-added vector as weight modifying the argument "wgt" : Yt or X or VAt
*Compute the vector of mean effects :
matrix Pt= P'
svmat Pt
generate Bt = Pt1* Yt
bys c : egen tot_Yt = total(Yt)
generate sector_shock = Bt/tot_Yt
bys c : egen shock = total(sector_shock)

generate Bt2 = Pt1* X
bys c : egen tot_X = total(X)
generate sector_shock2 = Bt2/tot_X
bys c : egen shock2 = total(sector_shock2)


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

mkmat tot_Yt
mkmat tot_X
mkmat shock
mkmat shock2
*Vector shock`cty' contains the mean effects of a shock on prices (coming from the country `cty') on overall prices for each country

local noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CZE DNK GBR HKG HRV HUN IDN IND ISL ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of local noneuro{
drop if c == "`i'"
}

generate C = shock * tot_X
egen x_eu = total(tot_X)
generate mean_per_country = C/x_eu
egen mean_eu = total(mean_per_country)
gen ratio = shock/mean_eu

generate C2 = shock2 * tot_X
egen x_eu2 = total(tot_X)
generate mean_per_country2 = C2/x_eu2
egen mean_eu2 = total(mean_per_country2)
gen ratio2 = shock2/mean_eu2

save "H:\Agents\Cochard\Papier_chocCVA\Bases/results_deval_`yrs'_`zone'.dta", replace
export excel using "H:\Agents\Cochard\Papier_chocCVA\Bases/results_deval_`yrs'_`zone'.xls", firstrow(variables) replace

end

*--------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*--------------------------------------------------------------------------------
/*
clear
set more off

foreach i of numlist 1995 2000 2005 2009 2010 2011{
	compute_leontief `i'
	foreach j in Yt X {
		table_mean `i' `j' 1 p
	}
}


clear matrix
set more off

foreach i of numlist 1995 2000 2005{
	clear
	compute_leontief `i'
	compute_wage `i'
	foreach j in Yt X {
		table_mean `i' `j' 4 w
	}
}

shock_deval 1 noneuro
create_y 2011
compute_X 2011
compute_mean_deval 2011 noneuro

*/

set more on
log close
