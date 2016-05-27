clear
set more off
set matsize 7000

global dir "H:\Agents\Cochard\Papier_chocCVA"

cd "$dir"


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

use "$dir/Bases/mean_effect/concat_CHN_MEX_mean_effect.dta"


* On calcule le vecteur des indegree
replace shock = 0 if effect==cause
collapse (sum) shock, by(effect shock_type-year) 
rename shock indegree
rename effect pays
sort year weight shock_type pays   , stable
destring year, replace

save "$dir\Bases\Degrees\mean_all_indegree.dta", replace
end

***************************************************************************************************
************************** On calcule les outdegrees***********************************************
***************************************************************************************************


***************************************************************************************************
*  On multiplie la matrice des pondérations transposée par la matrice des effets moyens, et on garde le vecteur diagonale
***************************************************************************************************

/* Production et exports agrégés  */

capture program drop compute_XProd
program compute_XProd


use "$dir\Bases\prod.dta"
merge m:1 pays  year  using "$dir\Bases\exports.dta"
drop _merge

gen pays2=pays
replace pays2="CHN" if (pays=="CHN" | pays=="CHNDOM" |pays=="CHNNPR" |pays=="CHNPRO" )
replace pays2="MEX" if (pays=="MEX" | pays=="MEXGMF" |pays=="MEXNGM"  )

collapse (sum) prod X, by(  year  pays2)
rename pays2 pays

save "$dir\Bases\XProd.dta", replace

end

/* Calcul des outdegrees  */

capture program drop outdegree
program outdegree

clear
use "$dir/Bases/mean_effect/concat_CHN_MEX_mean_effect.dta"

replace prod = 0 if effect==cause
replace X = 0 if effect==cause

bys cause  year  shock_type weight : egen somme_des_poids_P=total(prod)
bys cause  year   shock_type weight : egen somme_des_poids_X=total(X)


gen somme_des_poids=somme_des_poids_P 
replace somme_des_poids=somme_des_poids_X if weight=="X"
drop somme_des_poids_P somme_des_poids_X

gen pond=prod/somme_des_poids
replace pond=X/somme_des_poids if weight=="X"
*drop somme_des_poids


gen outdegree=61*pond*shock

collapse (sum) outdegree, by(cause  year  shock_type weight )
rename cause pays
sort year weight shock_type pays   , stable

save "$dir\Bases\Degrees\mean_all_outdegree.dta", replace

end

***************************************************************************************************
************************** Fabrication de la base avec les indegrees et outdegrees***********************************************
***************************************************************************************************


capture program drop compute_degree
program compute_degree


use "$dir\Bases\Degrees/mean_all_outdegree.dta"

merge m:1 year weight shock_type pays using "$dir\Bases\Degrees\mean_all_indegree.dta"
drop _merge
save "$dir\Bases\Degrees\degrees.dta", replace

merge m:1 year pays using "$dir\Bases\XProd.dta"
drop _merge
save "$dir\Bases\Degrees\degrees.dta", replace

end


***************************************************************************************************
*******  On calcule les degrees pondérés : corrigés des taux d'ouverture  ****************************
***************************************************************************************************


***************************************************************************************************
*  On calcule l'évolution de la production et des exportations totales par rapport à 1995


/* Calcul de la somme des production et des exportations par année */
capture program drop compute_pond95
program compute_pond95

clear

use "$dir\Bases\Degrees\degrees.dta"
sort pays  year  shock_type weight , stable

merge m:1 pays  year  using "$dir\Bases\XProd.dta"
drop _merge
sort pays  year  shock_type weight , stable


collapse (sum) prod X, by(  year  shock_type weight)
rename X Sum_X
rename prod Sum_prod

save "$dir\Bases\Sum_XProd.dta", replace


gen pond_X_1995=0
replace pond_X_1995=Sum_X  if (year==1995)

gen pond_prod_1995=0
replace pond_prod_1995=Sum_prod  if (year==1995)

collapse (sum) pond_prod_1995 pond_X_1995, by(  shock_type weight)

save "$dir\Bases\Pond_XProd.dta", replace

clear
use "$dir\Bases\Sum_XProd.dta"
merge m:1   shock_type weight  using "$dir\Bases\Pond_XProd.dta"
drop _merge
sort  year  shock_type weight , stable

gen pond_year_1995=Sum_X/pond_X_1995
replace pond_year_1995=Sum_prod/pond_prod_1995  if (weight=="Yt")

drop pond_prod_1995 pond_X_1995 Sum_prod Sum_X

save "$dir\Bases\Pond_outdegree_1995.dta", replace
end


/* poutdegree et pindegree : on pondère par les taux d'ouverture, et on rapporte les poutdegree à la prod ou les exports de l'année/1995  */


capture program drop compute_pdegree
program compute_pdegree

use "$dir\Bases\Degrees\degrees.dta"
sort pays  year  shock_type weight , stable

merge m:1 pays  year  using "$dir\Bases\XProd.dta"
drop _merge
sort pays  year  shock_type weight , stable

merge m:1   year shock_type weight using "$dir\Bases\Pond_outdegree_1995.dta"
drop _merge
sort pays  year  shock_type weight , stable

*gen outdegree_95=outdegree/pond_year_1995

save "$dir\Bases\Degrees\degrees.dta", replace


*gen outdegree2=outdegree/prod if (weight=="Yt")
*replace outdegree2=outdegree/X if (weight=="X")

rename prod Yt
gen pindegree=ind*Yt/X
gen poutdegree=outdegree/X*pond_year_1995

save "$dir\Bases\Degrees\degrees.dta", replace

end


*-------------------------------------------------------------------------------
* création dummies zone euro et grands pays
*-------------------------------------------------------------------------------

capture program drop compute_dummies
program compute_dummies

use "$dir\Bases\Degrees\degrees.dta"

global ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"

gen dum_ZE=0
local ZE "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT"
foreach n of local ZE{
	replace dum_ZE=1 if (pays=="`n'")
}

gen dum_GP=0
local GP "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVN SVK CZE DNK HUN ISL NOR POL SWE CHE GBR USA JPN RUS HRV CHN"
foreach n of local GP{
	replace dum_GP=1 if (pays=="`n'")
}

save "$dir\Bases\Degrees\degrees.dta", replace

end


*-------------------------------------------------------------------------------
* correction des degrees, pas par degré d'ouverture mais par degré d'ouverture modélisé en fonction de la taille
*-------------------------------------------------------------------------------

capture program drop reg_touv
program reg_touv

use "$dir\Bases\Degrees\degrees.dta"
sort pays  year  shock_type weight , stable

gen touv=X/Yt
gen ltouv=log(X/Yt)
gen ltouv_chap=log(X/Yt)
gen lYt=log(Yt)

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011 {

	reg ltouv lYt if (year==`i')
	predict ltouv_chap_`i' 
	replace ltouv_chap=ltouv_chap_`i'  if (year==`i')
	drop ltouv_chap_`i'
}
gen touv_chap=exp(ltouv_chap)
save "$dir\Bases\Degrees\degrees.dta", replace

end


capture program drop compute_pdegree_chap
program compute_pdegree_chap

use "$dir\Bases\Degrees\degrees.dta"
sort pays  year  shock_type weight , stable

gen pindegree_chap=ind/touv_chap
gen poutdegree_chap=pond_year_1995*outdegree/Yt/touv_chap


save "$dir\Bases\Degrees\degrees.dta", replace

end




*-------------------
*Appel des programmes
*------------------
indegree 
compute_XProd 
outdegree 
compute_degree 
compute_pond95
compute_pdegree
compute_dummies
reg_touv
compute_pdegree_chap

 *------------Bout de programme pour passer de la matrice longue à une matrice
 /*
 use "/Users/guillaumedaudin/Dropbox/commerce en VA/mean_all3.dta"

keep if year==2011
keep if weight=="X"
drop prod X
reshape wide shock, i(cause shock_type weight year) j(effect) string
*/

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
*gen `wgt'DEU = tot_`wgt'1 if k == "DEU"



