clear
set more off
set matsize 7000

global dir \\intra\profils\D001\L841580\D\Desktop\I-O-Stan\bases_stata

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Dropbox/Commerce en VA"
}



cd "$dir"


***************************************************************************************************
************************** On calcule des effets moyens en agrégeant Chine et Mexique ***********************************************
***************************************************************************************************



program concat_CHN_MEX_mean_effect

capture use "$dir/mean_all2.dta"


display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	use "$dir/Results mean_effect/mean_all.dta"
}


drop if cor=="yes"
drop cor

*On agrège sur le pays cause

replace cause="CHN" if (cause=="CHN" | cause=="CHNDOM" |cause=="CHNNPR" |cause=="CHNPRO" )
replace cause="MEX" if (cause=="MEX" | cause=="MEXGMF" |cause=="MEXNGM"  )

collapse (sum) shock, by(cause effect shock_type-year)  

* On merge avec prod.dta et exports.dta pour aggréger sur le pays effet

gen pays=effect
destring year, replace


merge m:1 pays year using prod.dta
drop _merge
sort cause  year  shock_type weight , stable


merge m:1 pays year using exports.dta
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

save "$dir/ concat_CHN_MEX_mean_effect.dta", replace

end


*----------------------------------------------------------------------------------
*        Calcul des degrees
*----------------------------------------------------------------------------------


***************************************************************************************************
************************** On calcule les indegrees***********************************************
***************************************************************************************************

* On récupère la matrice des effets moyens, non corrigés
capture program drop indegree
program indegree
*args yrs

use "$dir/mean_all3.dta"


* On calcule le vecteur des indegree
replace shock = 0 if effect==cause
collapse (sum) shock, by(effect shock_type-year) 
rename shock indegree
rename effect pays
sort year weight shock_type pays   , stable
destring year, replace

save "$dir\mean_all_indegree.dta", replace
end

indegree
***************************************************************************************************
************************** On calcule les outdegrees***********************************************
***************************************************************************************************


***************************************************************************************************
* 1- Création des tables Y de production : on crée le vecteur 1*67 des productions totales de chauqe pays
***************************************************************************************************

capture program drop create_y
program create_y
args yrs

/*Y vecteur de production*/ 
clear
use "$dir/OECD_`yrs'_OUT.dta"
drop arg_consabr-disc
rename * prod*
generate year = `yrs'
reshape long prod, i(year) j(pays_sect) string
generate pays = strupper(substr(pays_sect,1,strpos(pays_sect,"_")-1))
collapse (sum) prod, by(pays year)

end 

/*
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	create_y `i'
	if `i'!=1995 {
		append using prod.dta
	}
	save prod.dta, replace
	
}


sort year , stable

*save prod.dta, replace
use prod.dta
use exports.dta
*/
***************************************************************************************************
* 2- Création des tables X de production : on crée le vecteur 1*67 des productions totales de chauqe pays
***************************************************************************************************

*Creation of the vector of export X
capture program drop compute_X
program compute_X
	args yrs

use "$dir/OECD`yrs'.dta", clear

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
collapse (sum) X, by(pays year)

end

***************************************************************************************************
* 3- On multiplie la matrice des pondérations transposée par la matrice des effets moyens, et on garde lae vecteur diagonale
***************************************************************************************************

capture program drop outdegree
program outdegree

clear
use "$dir/mean_all3.dta"
*drop if cor=="yes"
*drop cor

/*rename effect pays
destring year, replace

merge m:1 pays year using prod.dta
drop _merge
sort cause  year  shock_type weight , stable


merge m:1 pays year using exports.dta
drop _merge
rename pays effect*/

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


gen outdegree=61*pond*shock

collapse (sum) outdegree, by(cause  year  shock_type weight )
rename cause pays
sort year weight shock_type pays   , stable

save "$dir\mean_all_outdegree.dta", replace

end

outdegree

/* Fabrication de la base avec les indegrees et outdegrees   */

use "$dir/mean_all_outdegree.dta"

merge m:1 year weight shock_type pays using mean_all_indegree.dta
drop _merge
save "$dir\degrees.dta", replace

/* Production et exports agrégés  */

use prod.dta
merge m:1 pays  year  using exports.dta
drop _merge

gen pays2=pays
replace pays2="CHN" if (pays=="CHN" | pays=="CHNDOM" |pays=="CHNNPR" |pays=="CHNPRO" )
replace pays2="MEX" if (pays=="MEX" | pays=="MEXGMF" |pays=="MEXNGM"  )

collapse (sum) prod X, by(  year  pays2)
rename pays2 pays

save "$dir\XProd.dta", replace


/* outdegree pondéré */

use "$dir\degrees.dta"
sort pays  year  shock_type weight , stable

merge m:1 pays  year  using XProd.dta
drop _merge
sort pays  year  shock_type weight , stable


*merge m:1 pays  year   using exports.dta
*drop _merge

/*gen wgt_DEU=0
replace wgt_DEU=prod if (weight=="Yt" & pays=="DEU")
replace wgt_DEU=X if (weight=="X" & pays=="DEU")

collapse (sum) wgt_DEU, by(year  shock_type weight )
save "$dir\DEU.dta", replace  

use "$dir\degrees.dta"
merge m:1   year  shock_type weight using DEU.dta
drop _merge 

merge m:1 pays  year   using prod.dta
drop _merge
sort pays  year  shock_type weight , stable


merge m:1 pays  year  using exports.dta
drop _merge*/

gen outdegree2=outdegree/prod if (weight=="Yt")
replace outdegree2=outdegree/X if (weight=="X")

*drop wgt_DEU

global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
	replace dum_ZE=1 if (pays=="`n'")
}

rename prod Yt
save "$dir\degrees.dta", replace

*gen `wgt'DEU = tot_`wgt'1 if k == "DEU"


/**** Degrees pondérés *************************/


gen pindegree=ind*Yt/X
gen poutdegree=outdegree/X

save "$dir\degrees.dta", replace

*-------------------------------------------------------------------------------
* création dummy zone euro
*-------------------------------------------------------------------------------


gen dum_UE=0
local UE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVN SVK CZE DNK HUN ISL NOR POL SWE CHE GBR USA JPN RUS HRV CHN"
foreach n of local UE{
	replace dum_UE=1 if (pays=="`n'")
}

save "$dir\degrees.dta", replace



*-------------------
*Appel des programmes
*------------------


*---------
set more off
compute_X 1995
foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_X `i'
	if `i'!=1995 {
	append using exports.dta 
	}
	save exports.dta, replace
}	

replace pays = "CHNNPR" if pays == "CHN.NPR"
replace pays = "CHNPRO" if pays == "CHN.PRO"
replace pays = "CHNDOM" if pays == "CHN.DOM"
replace pays = "MEXNGM" if pays == "MEX.NGM"
replace pays = "MEXGMF" if pays == "MEX.GMF"

sort year , stable
save exports.dta, replace
*------------------



 concat_CHN_MEX_mean_effect
 
 
 *------------Bout de programme pour passer de la matrice longue à une matrice
 /*
 use "/Users/guillaumedaudin/Dropbox/commerce en VA/mean_all3.dta"

keep if year==2011
keep if weight=="X"
drop prod X
reshape wide shock, i(cause shock_type weight year) j(effect) string
*/


