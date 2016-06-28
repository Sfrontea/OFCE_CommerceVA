clear

global dir "H:\Agents\Cochard\Papier_chocCVA"

if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"
if ("`c(username)'"=="L841580") global dir "H:\Agents\Cochard\Papier_chocCVA"


capture log using "$dir/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off

*-------------------------------------------------------------------------------
*COMPUTING LEONTIEF INVERSE MATRIX  : matrix L1
*-------------------------------------------------------------------------------
clear
set more off
*set matsize 7000
capture program drop compute_leontief
program compute_leontief
	args yrs
*Create vector Y of output from troncated database
clear
use "$dir/Bases/OECD_`yrs'_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)

*Create matrix Z of inter-industry inter-country trade
use "$dir/Bases/OECD_`yrs'_Z.dta"



mkmat arg_c01t05agr-zaf_c95pvh, matrix (Z)

*From vector Y create a diagonal matrix Yd which contains all elements of vector Y on the diagonal
matrix Yd=diag(Y)
*Take the inverse of Yd (with invsym instead of inv for more accurateness and to avoid errors)
matrix Yd1=invsym(Yd)

*Then multiply Yd1 by Z 
matrix A_`yrs'=Z*Yd1

clear
svmat A_`yrs', names(col)
save "$dir/Bases/A_`yrs'.dta", replace


*Create identity matrix at the size we want
mat I=I(2159)

*I-A
matrix L=(I-A_`yrs')

*Leontief inverse
matrix L1_`yrs'=inv(L)

clear
svmat L1_`yrs', names(col)
save "$dir/Bases/L1_`yrs'.dta", replace


display "fin de compute_leontieff" `yrs'

end

*-------------------------------------------------------------------------------
* On construit la matrice ZB avec des matrices B diagonales
*-------------------------------------------------------------------------------


clear
set more off
*set matsize 7000
capture program drop compute_leontief_chocnom
program compute_leontief_chocnom
	args yrs groupeduchoc
*ex : compute_leontief_chocnom 2005 ARG	
*Create vector Y of output from troncated database
clear


*use "H:\Agents\Cochard\Papier_chocCVA/Bases/OECD_`yrs'_OUT.dta"
*mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)

*Create matrix Z of inter-industry inter-country trade

use "$dir/Bases/A_`yrs'.dta", clear


merge 1:1 _n using "$dir/Bases/csv.dta"
drop _merge

***----  On construit la matrice B avec des matrices 0 diagonales  pour les pays choqués ------*

gen grchoc = 0

foreach p of local groupeduchoc {
	replace grchoc = 1 if c == "`p'" 

	if ("`p'"=="MEX") {
		replace grchoc = 1 if c == "MEXGMF" 
		replace grchoc = 1 if c == "MEXNGM" 
		}
	if ("`p'"=="CHN") {
		replace grchoc = 1 if c == "CHNDOM" 
		replace grchoc = 1 if c == "CHNNPR" 
		replace grchoc = 1 if c == "CHNPRO" 
		}
}
 

gen pays="0"
gen grchoc2=0

foreach var of varlist arg_c01t05agr-zaf_c95pvh {
	replace pays = strupper(substr("`var'",1,strpos("`var'","_")-1))
	foreach p of local groupeduchoc {
	
		replace grchoc2 = 1 if pays == "`p'" 
		

		if ("`p'"=="MEX") {
			replace grchoc2 = 1 if pays == "MEXGMF" 
			replace grchoc2 = 1 if pays == "MEXNGM" 
		}
		if ("`p'"=="CHN") {
			replace grchoc2 = 1 if pays == "CHNDOM" 
			replace grchoc2 = 1 if pays == "CHNNPR" 
			replace grchoc2 = 1 if pays == "CHNPRO" 
		}

	}
	
replace `var'=0 if (grchoc==1 & grchoc2==1)
replace grchoc2=0

}
drop grchoc grchoc2 pays
mkmat arg_c01t05agr-zaf_c95pvh, matrix (B)

***----  On construit la matrice B2 avec des colonnes 0  pour les pays non choqués ------*
clear
use "$dir/Bases/A_`yrs'.dta", clear



merge 1:1 _n using "$dir/Bases/csv.dta"
drop _merge

gen grchoc_ligne = 0

foreach p of local groupeduchoc {
	replace grchoc_ligne = 1 if c == "`p'" 

	if ("`p'"=="MEX") {
		replace grchoc_ligne = 1 if c == "MEXGMF" 
		replace grchoc_ligne = 1 if c == "MEXNGM" 
		}
	if ("`p'"=="CHN") {
		replace grchoc_ligne = 1 if c == "CHNDOM" 
		replace grchoc_ligne = 1 if c == "CHNNPR" 
		replace grchoc_ligne = 1 if c == "CHNPRO" 
		}
}
 

gen pays="0"
gen grchoc2=0

foreach var of varlist arg_c01t05agr-zaf_c95pvh {
	replace pays = strupper(substr("`var'",1,strpos("`var'","_")-1))
	foreach p of local groupeduchoc {
	
		replace grchoc2 = 1 if pays == "`p'" 

		if ("`p'"=="MEX") {
			replace grchoc2 = 1 if pays == "MEXGMF" 
			replace grchoc2 = 1 if pays == "MEXNGM" 
		}
		if ("`p'"=="CHN") {
			replace grchoc2 = 1 if pays == "CHNDOM" 
			replace grchoc2 = 1 if pays == "CHNNPR" 
			replace grchoc2 = 1 if pays == "CHNPRO" 
		}

	}

	
	replace `var'=0 if (grchoc_ligne==0 & grchoc2==0)
replace grchoc2=0


}
drop grchoc_ligne grchoc2 pays
mkmat arg_c01t05agr-zaf_c95pvh, matrix (B2)

display "fin de compute_leontief_chocnom`groupeduchoc'" `yrs'

end
   
*---------------------------------------------------------------------------------------------
*COMPUTING THE EFFECT OF A SHOCK ON EXCHANGE RATE IN ONE COUNTRY  : matrix C`cty'
*---------------------------------------------------------------------------------------------
capture program drop vector_shock_exch
program vector_shock_exch
		args shk groupeduchoc 
clear
*set matsize 7000
set more off
clear
use "$dir/Bases/csv.dta", clear
foreach p of local groupeduchoc {

	replace p_shock = `shk' if c == "`groupeduchoc'"
}
*I extract vector p_shock from database with mkmat
mkmat p_shock
matrix p_shockt=p_shock'

generate p_shock2=1/(1+`shk')
foreach p of local groupeduchoc {

	replace p_shock = 0 if c == "`groupeduchoc'"
}
*I extract vector p_shock from database with mkmat
mkmat p_shock2
matrix p_shock2t=p_shock2'

*Example: p_shock = 0.05 if (c = "ARG" & s == "C01T05")

*I extract vector p_shock from database with mkmat
mkmat p_shock
matrix p_shockt=p_shock'
*The transpose of p_shock will be necessary for further computations

end


capture program drop shock_exch
program shock_exch
	args yrs groupeduchoc 
	
clear	
use "$dir/Bases/L1_`yrs'.dta"
mkmat r1-r2159, matrix (L1)


*Multiplying the transpose of vector shock `v'_shockt by L1 to get the impact of a shock on the output price vector
matrix C`groupeduchoc' = p_shockt+(p_shockt*B+p_shock2t*B2)*L1
*Result example: using p_shock = 0.05 if c == "ARG" & s == "C01T05": if prices in agriculture increase by 5% in Argentina, output prices in the sector of agriculture in Argentina increase by 5.8%

end


*----------------------------------------------------------------------------------
*CREATION OF A VECTOR CONTAINING MEAN EFFECTS OF A SHOCK ON EXCHANGE RATE FOR EACH COUNTRY
*----------------------------------------------------------------------------------
*Creation of the vector Y is required before table_adjst : matrix Yt
capture program drop create_y
program create_y
args yrs
clear

use "$dir/Bases/OECD_`yrs'_OUT.dta"


mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)
matrix Yt = Y'

end

*Creation of the vector of export X : matrix X
capture program drop compute_X
program compute_X
	args yrs

use "$dir/Bases/OECD`yrs'.dta", clear


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
use "$dir/Bases/OECD`yrs'.dta", clear
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
use "$dir/Bases/csv.dta"
matrix Yt = Y'
svmat Yt
svmat X
svmat VAt

*I decide whether I use the production or export or value-added vector as weight modifying the argument "wgt" : Yt or X or VAt
*Compute the vector of mean effects :

matrix C`cty't= C`cty''
svmat C`cty't
generate Bt = C`cty't1* `wgt'
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

*Vector shock`cty' contains the mean effects of a shock on exchange rate (coming from the country `cty') on overall prices for each country

end

*----------------------------------------------------------------------------------------------------
*CREATION OF THE TABLE CONTAINING THE MEAN EFFECT OF A EXCHANGE RATE SHOCK FROM EACH COUNTRY TO ALL COUNTRIES
*----------------------------------------------------------------------------------------------------
capture program drop table_mean
program table_mean
	args yrs wgt shk 
*yrs = years, wgt = Yt (output) or X (export) or VAt (value-added)
clear
*set matsize 7000
* set trace on
set more off

*compute_leontieff `yrs'
if ("`wgt'" == "Yt")  {
	create_y `yrs' 
	}
if ("`wgt'" == "X")  {
	compute_X `yrs'
	}
//compute_VA `yrs'

	
global noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN COL CRI CZE DNK GBR HKG HRV HUN IDN IND ISL ISR JPN KHM KOR MEX MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"
foreach i of global noneuro {
	compute_leontief_chocnom `yrs' `i'
	vector_shock_exch `shk' `i'   //
	shock_exch `yrs' `i' 
	compute_mean `i' `wgt'
}

clear
set more off
foreach i of global noneuro {
svmat shock`i'
}

* shockARG1 represents the mean effect of a price shock coming from Argentina for each country
save "$dir/Results/Devaluations/mean_chg_`wgt'_`yrs'.dta", replace
*We obtain a table of mean effect of a price shock from each country to all countries

export excel using "$dir/Results/Devaluations/mean_chg_`wgt'_`yrs'.xls", firstrow(variables) replace

* set trace off
set more on

end

/*
*-------------------------------------------------------------------------------
*DEVALUATION OF THE EURO What happens when the euro is devaluated? To know that, we do a shock of 1 on all countries but the eurozone.
*-------------------------------------------------------------------------------
*
capture program drop shock_deval
program shock_deval
	args yrs shk wgt zone
*yrs = years,shk = 1, wgt = Yt (output) or X (export) or VAt (value-added), zone = noneuro (for a shock corresponding to a devaluation of the euro), china or eastern

set matsize 7000
*set trace on
set more off
clear

compute_leontieff `yrs'
if ("`wgt'" == "Yt")  {
	create_y `yrs' 
	}
if ("`wgt'" == "X")  {
	compute_X `yrs'
	}
//compute_VA `yrs'


*global noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CZE DNK GBR HKG HRV HUN IDN IND ISL ISR JPN KHM KOR MEX MEXGMF MEXNGM MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"
	compute_leontieff_chocnom `yrs' `zone'
	vector_shock_exch `shk' `zone'   //
	shock_exch `yrs' `zone' 
	compute_mean `zone' `wgt'

clear
svmat shock`zone'

* shockARG1 represents the mean effect of a price shock coming from Argentina for each country
save "$dir/Results/Devaluations/mean_`zone'_`wgt'_`yrs'.dta", replace
*We obtain a table of mean effect of a price shock from each country to all countries

export excel using "$dir/Results/Devaluations/mean_`zone'_`wgt'_`yrs'.xls", firstrow(variables)

*set trace off
*set more on

end

*/

*--------------------------------------------------------------------------------
*LIST ALL PROGRAMS AND RUN THEM
*--------------------------------------------------------------------------------

clear
set more off

*global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN CHNDOM CHNNPR CHNPRO COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MEXGMF MEXNGM MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"
global country "ARG AUS AUT BEL BGR BRA BRN CAN CHE CHL CHN COL CRI CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HKG HRV HUN IDN IND IRL ISL ISR ITA JPN KHM KOR LTU LUX LVA MEX MLT MYS NLD NOR NZL PHL POL PRT ROU ROW RUS SAU SGP SVK SVN SWE THA TUN TUR TWN USA VNM ZAF"


local eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
local noneuro "ARG AUS BGR BRA BRN CAN CHE CHL CHN COL CRI CZE DNK GBR HKG HRV HUN IDN IND ISL ISR JPN KHM KOR MEX MYS NOR NZL PHL POL ROU ROW RUS SAU SGP SWE THA TUN TUR TWN USA VNM ZAF"
local china "CHN CHNDOM CHNNPR CHNPRO"
local eastern "BGR CZE HRV HUN POL ROU "

// Fabrication des fichiers d'effets moyens des chocs de change


foreach i of numlist 1995 /*2000 2005 2009 2010 2011*/{
	clear
	set more off
	compute_leontief `i'
	compute_X `i'
	create_y `i'
	compute_VA `i'
}

foreach i of numlist 1995 /*2000 2005 2009 2010 2011*/{

		foreach j in Yt X {
		table_mean `i' `j' 1 
	}
}


clear matrix
set more off

/*

// dévaluation de l'euro par rapport à toutes les monnaies
compute_leontieff 2011
shock_deval 2011 1 Yt noneuro    
*create_y 2011
*compute_X 2011
*compute_mean_deval 2011 noneuro


set more on
log close
