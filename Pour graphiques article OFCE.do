

if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"
if ("`c(username)'"=="L841580") global dir "H:\Agents\Cochard\Papier_chocCVA"


global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
global eastern "BGR CZE HRV HUN POL ROU"




*--------------------------
*-----------------Pour graphiques
*--------------------------


*GRAPHIQUE 1

use "$dir/Results/Devaluations/mean_chg_X_2011.dta", clear

foreach var of varlist shockEUR1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_X = rowtotal(shockEUR1-shockZAF1)
replace pond_X = (pond_X - 1)/2

keep c pond_X

save "$dir/Results/Devaluations/Pour_Graph_1.dta", replace


use "$dir/Results/Devaluations/mean_chg_Yt_2011.dta", clear

foreach var of varlist shockEUR1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_Y = rowtotal(shockEUR1-shockZAF1)

keep c pond_Y

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge



merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

drop _merge 

replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Prix de production"

label var pond_X "Prix d'exportation"

save "$dir/Results/Devaluations/Pour_Graph_1_old.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_1_old.csv", replace


graph bar (asis) pond_X pond_Y , over(c, sort(pond_X) label(angle(vertical) labsize(tiny))) 

graph export "$dir/Results/Devaluations/Graph_1_old.png", replace

drop if strpos("$eurozone",c)==0


graph bar (asis) pond_X pond_Y , over(c_full_FR, sort(pond_X) label(angle(vertical) labsize(small)))


graph export "$dir/Results/Devaluations/Graph_1.png", replace
save "$dir/Results/Devaluations/Pour_Graph_1.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_1.csv", replace
export excel "$dir/Results/Devaluations/Pour_Graph_1.xlsx", firstrow(variable)replace





*Graphique 2

use "$dir/Results/Devaluations/mean_chg_X_1995.dta", clear

foreach var of varlist shockEUR1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_X_1995 = rowtotal(shockEUR1-shockZAF1)
replace pond_X_1995 = (pond_X_1995 - 1)/2

keep c pond_X_1995

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1_old.dta"
drop _merge

rename pond_X pond_X_2011

drop pond_Y


label var pond_X_1995 "Prix d'exportation, 1995"

label var pond_X_2011 "Prix d'exportation, 2011"

save "$dir/Results/Devaluations/Pour_Graph_2_old.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_2_old.csv", replace


graph bar (asis) pond_X_1995 pond_X_2011 , over(c, sort(pond_X_2011) label(angle(vertical) labsize(tiny))) 

graph export "$dir/Results/Devaluations/Graph_2_old.png", replace

drop if strpos("$eurozone",c)==0

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge

label var pond_X_1995 "1995"

label var pond_X_2011 "2011"


graph bar (asis) pond_X_2011 pond_X_1995  , over(c_full_FR, sort(pond_X_2011) label(angle(vertical) labsize(small))) 


graph export "$dir/Results/Devaluations/Graph_2.png", replace
save "$dir/Results/Devaluations/Pour_Graph_2.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_2.csv", replace
export excel "$dir/Results/Devaluations/Pour_Graph_2.xlsx", firstrow(variable)replace







**Graphique 3


use "$dir/Results/Devaluations/mean_chg_X_2011.dta", clear

keep c shockEUR1
drop if strpos("$eurozone",c)==0
rename shockEUR1 pond_X
replace pond_X = (pond_X - 1)/2

save "$dir/Results/Devaluations/Pour_Graph_3.dta", replace

use "$dir/Results/Devaluations/mean_chg_Yt_2011.dta", clear

keep c shockEUR1
drop if strpos("$eurozone",c)==0



rename shockEUR1 pond_Yt
replace pond_Yt = (pond_Yt - 1)/2



merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_3.dta"
drop _merge

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge

label var pond_Yt "Prix de production"

label var pond_X "Prix d'exportation"

save "$dir/Results/Devaluations/Pour_Graph_3.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_3.csv", replace
export excel "$dir/Results/Devaluations/Pour_Graph_3.xlsx", firstrow(variable)replace

graph bar (asis) pond_X pond_Yt , over(c_full_FR, sort(pond_X) label(angle(vertical) )) 


graph export "$dir/Results/Devaluations/Graph_3.png", replace

**Graphique 4


use "$dir/Results/Devaluations/mean_chg_X_2011.dta", clear

keep c shockEUR1
drop if strpos("$eurozone",c)!=0
rename shockEUR1 pond_X


save "$dir/Results/Devaluations/Pour_Graph_4.dta", replace

use "$dir/Results/Devaluations/mean_chg_Yt_2011.dta", clear

keep c shockEUR1
drop if strpos("$eurozone",c)!=0
rename shockEUR1 pond_Yt

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge




merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_4.dta"
drop _merge

label var pond_Yt "Prix de production"

label var pond_X "Prix d'exportation"

save "$dir/Results/Devaluations/Pour_Graph_4.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_4.csv", replace

graph bar (asis) pond_X pond_Yt , over(c_full_FR, sort(pond_X) descending label(angle(vertical) labsize(vsmall))) 


graph export "$dir/Results/Devaluations/Graph_4.png", replace




*GRAPHIQUE 5

use "$dir/Results/Choc de prod/mean_p_X_2011.dta", clear

merge 1:1 _n using "$dir/Bases/pays_en_ligne.dta
drop _merge

foreach var of varlist shockARG1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_X = rowtotal(shockARG1-shockZAF1)
replace pond_X = (pond_X - 1)


keep c pond_X

save "$dir/Results/Choc de prod/Pour_Graph_5.dta", replace


use "$dir/Results/Choc de prod/mean_p_Yt_2011.dta", clear
merge 1:1 _n using "$dir/Bases/pays_en_ligne.dta
drop _merge


foreach var of varlist shockARG1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_Y = rowtotal(shockARG1-shockZAF1)

keep c pond_Y

merge 1:1 c using "$dir/Results/Choc de prod/Pour_Graph_5.dta"
drop _merge

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge 

replace pond_Y = (pond_Y - 1)

label var pond_Y "Prix de production"

label var pond_X "Prix d'exportation"

save "$dir/Results/Choc de prod/Pour_Graph_5_old.dta", replace
export delimited "$dir/Results/Choc de prod/Pour_Graph_5_old.csv", replace
export excel "$dir/Results/Choc de prod/Pour_Graph_5_old.xslx", firstrow(variable)replace
graph export "$dir/Results/Choc de prod/Graph_5_old.png", replace



graph bar (asis) pond_X pond_Y , over(c_full_FR, sort(pond_X) descending label(angle(vertical) labsize(tiny))) 


drop if strpos("$eurozone",c)==0

graph bar (asis) pond_X pond_Y , over(c_full_FR, sort(pond_X) descending label(angle(vertical) labsize(small))) 

save "$dir/Results/Choc de prod/Pour_Graph_5.dta", replace
export delimited "$dir/Results/Choc de prod/Pour_Graph_5.csv", replace
export excel "$dir/Results/Choc de prod/Pour_Graph_5.xslx", firstrow(variable)replace
graph export "$dir/Results/Choc de prod/Graph_5.png", replace






***************************************
*Pour tableaux
**********************




**Tableau 1


local i =1 

foreach pond in X Yt {

	foreach orig in USA EUR CHN JPN GBR RUS  EAS {
		use "$dir/Results/Devaluations/mean_chg_`pond'_2011.dta", clear
		format shock* %3.2f
		keep c shock`orig'1
		gsort - shock`orig'1
	
		drop if strmatch(c,"*`orig'*")==1
		if "`orig'"=="EUR" drop if strpos("$eurozone",c)!=0
		if "`orig'"=="EAS" drop if strpos("$eastern",c)!=0

	
	
		keep if _n<=10
	
		if "`orig'"=="USA" local column A
		if "`orig'"=="EUR" local column C
		if "`orig'"=="CHN" local column E
		if "`orig'"=="JPN" local column G
		if "`orig'"=="GBR" local column I
		if "`orig'"=="RUS" local column K
		if "`orig'"=="EAS" local column M
	
		export excel "$dir/Results/Devaluations/Tableau_1_old_`pond'.xlsx", firstrow(variables) cell(`column'1) sheetmodify

	}
}

***Tableau 2


foreach year in 1995 2000 2005 2009 2010 2011 {
	use "$dir/Results/Devaluations/mean_chg_X_`year'.dta", clear
	keep if strpos("$eurozone",c)!=0
	
	merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
	drop _merge 
	
	if `year'==1995 local column A
	if `year'==2000 local column C
	if `year'==2005 local column D
	if `year'==2009 local column E
	if `year'==2010 local column F
	if `year'==2011 local column G
		
	keep c_full_FR shockEUR1
	order c_full_FR
	if `year'!=1995 drop c_full_FR 
	rename shockEUR1 _`year'
	replace _`year' = (_`year' - 1)/2
	
	
	export excel "$dir/Results/Devaluations/Tableau_1.xlsx", firstrow(variables) cell(`column'1) sheetmodify
}
	
	

	

***Tableau 3


local orig USA CHN JPN GBR EAS RUS SAU

use "$dir/Results/Devaluations/mean_chg_Yt_2011.dta", clear
drop if strpos("$eurozone",c)==0

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge    

	
keep c_full_FR  shockUSA1 shockCHN1 shockJPN1 shockGBR1 shockEAS1 shockRUS1 shockSAU1
order c_full_FR shockGBR1 shockUSA1 shockJPN1 shockEAS1 shockCHN1 shockRUS1 shockSAU1 
rename shockGBR1 Royaume_Uni
rename shockUSA1 États_Unis
rename shockJPN1 Japon
rename shockEAS1 Pecos_hors_ZE
rename shockCHN1 Chine
rename shockRUS1 Russie
rename shockSAU1 Arabie_Saoudite



export excel "$dir/Results/Devaluations/Tableau_2.xlsx", firstrow(variables) sheetmodify

		
	
	
***Tableau 4


local orig USA CHN JPN GBR EAS RUS SAU

use "$dir/Results/Devaluations/mean_chg_X_2011.dta", clear
drop if strpos("$eurozone",c)==0

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge 
	
keep c_full_FR shockUSA1 shockCHN1 shockJPN1 shockGBR1 shockEAS1 shockRUS1 shockSAU1  
order c_full_FR shockGBR1 shockUSA1 shockJPN1 shockEAS1 shockCHN1 shockRUS1 shockSAU1 
rename shockGBR1 Royaume_Uni
rename shockUSA1 États_Unis
rename shockJPN1 Japon
rename shockEAS1 Pecos_hors_ZE
rename shockCHN1 Chine
rename shockRUS1 Russie
rename shockSAU1 Arabie_Saoudite

export excel "$dir/Results/Devaluations/Tableau_3.xlsx", firstrow(variables) sheetmodify

	

***Tableau 5


foreach year in 1995 2000 2005 2009 2010 2011 {
	use "$dir/Results/Devaluations/mean_chg_X_`year'.dta", clear
	keep if strpos("$eurozone",c)!=0
	
	if `year'==1995 local column A
	if `year'==2000 local column C
	if `year'==2005 local column D
	if `year'==2009 local column E
	if `year'==2010 local column F
	if `year'==2011 local column G
		
	merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
	drop _merge 
	
	keep c_full_FR shockEAS1
	order c_full_FR
	if `year'!=1995 drop c_full_FR
	rename shockEAS1 _`year'
	
	
	
	export excel "$dir/Results/Devaluations/Tableau_4.xlsx", firstrow(variables) cell(`column'1) sheetmodify
}



***Tableau 6
	
use "$dir/Results/Choc de prod/mean_p_X_2011.dta", clear


foreach euro of global eurozone {
		local tokeep `tokeep' + shock`euro'
}

merge 1:1 _n using "$dir/Bases/pays_en_ligne.dta
drop _merge
order c

keep if strpos("$eurozone",c)!=0


local tokeep c 
foreach euro of global eurozone {
		rename shock`euro'1 `euro'
		local tokeep `tokeep' `euro'
		replace `euro'=`euro'-1 if c=="`euro'"
}

keep `tokeep'

*egen Zone_euro =rowtotal(AUT-SVN)

*foreach euro in BEL DEU ESP FRA ITA LUX NLD {
*		replace `euro'=. if c=="`euro'"
*}


*gen Europe_Est = (SVK + SVN + EST + LTU + LVA)
drop SVK SVN EST LTU LVA
*gen Europe_Sud = (CYP + GRC + MLT + PRT)
drop CYP  GRC  MLT  PRT
*gen AUT_IRL_FIN = (AUT + IRL + FIN)
drop AUT IRL FIN





rename BEL Belgique
rename DEU Allemagne
rename ESP Espagne
rename FRA France
rename ITA Italie
*rename LUX Luxembourg
rename NLD Pays_Bas

drop LUX

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge 
drop c
order c_full_FR Allemagne Belgique *

export excel "$dir/Results/Choc de prod/Tableau_5.xlsx", firstrow(variables) replace



***Tableau 7

use "$dir/Results/Choc de prod/mean_p_X_2011.dta", clear


foreach euro of global eurozone {
		local tokeep `tokeep' + shock`euro'
}

merge 1:1 _n using "$dir/Bases/pays_en_ligne.dta
drop _merge
order c
keep if strpos("$eurozone",c)!=0

foreach east of global eastern {
		rename shock`east'1 `east'
}

egen Pecos_hors_ZE= rowtotal($eastern)

local tokeep c Pecos_hors_ZE
foreach pays in USA CHN JPN GBR RUS SAU {
		rename shock`pays'1 `pays'
		local tokeep `tokeep' `pays'
}


keep `tokeep'


rename GBR Royaume_Uni
rename USA États_Unis
rename JPN Japon
rename CHN Chine
rename RUS Russie
rename SAU Arabie_Saoudite

merge 1:1 c using "$dir/Bases/Pays_FR.dta",keep(3)
drop _merge 
drop c
order c_full_FR Pecos_hors_ZE

order c_full_FR Royaume_Uni  États_Unis Japon Pecos_hors_ZE  Chine Russie Arabie_Saoudite 

export excel "$dir/Results/Choc de prod/Tableau_6.xlsx", firstrow(variables) replace




**------------------ Pour graphiques de la fin

clear

if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"

if ("`c(username)'"=="L841580") global dir "H:/Agents/Cochard/Papier_chocCVA"

cd "$dir"


set matsize 7000

set more off

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"


use "$dir/Bases/imp_inputs_2011.dta" , clear //,keep(3)

gen c=upper(pays)
drop pays

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

drop _merge pond_X

//replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Prix de production"

label var input_prod "Parts des inputs importés dans la production"

drop if strpos("$eurozone",c)==0

save "$dir/Results/Devaluations/Pour_Graph_imp_deval.dta", replace
drop if c_full_FR=="Luxembourg"
graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  , ///
			xtitle("Parts des inputs importés dans la production") ytitle("Elasticité des prix de production en euro") ///
			yscale(range(0 -.2) reverse) xscale(range(0 .3)) xlabel (0(0.05) .3) ylabel(0 (0.05) -.2)
			
			
graph export "$dir/Results/Devaluations/Graph_1_imp.png", replace 
export excel "$dir/Results/Devaluations/Pour_Graph_1_imp.xlsx", firstrow(variable)replace
 /*
graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  ,    xtitle("Parts des inputs importés dans la production") ytitle("Prix de production")
graph export "$dir/Results/Devaluations/Graph_1_imp.png", replace   */

//////////////////////////////////////////////////////////////////////////////////////////////////////

global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"


use "$dir/Bases/imp_inputs_hze_2011.dta", clear  //,keep(3)
//drop _merge

gen c=upper(pays)
drop pays

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_3.dta"

drop _merge pond_X

//replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Prix de production"

label var input_prod "Parts des inputs importés en provenance de pays hors zone euro dans la production"

drop if strpos("$eurozone",c)==0

save "$dir/Results/Devaluations/Pour_Graph_imp_deval.dta", replace
//export delimited "$dir/Results/Devaluations/Pour_Graph_1_old.csv", replace

//graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  , ///
	//		xtitle("Parts des inputs importés dans la production") ytitle("Elasticité des prix de production en euro") ///
		//	yscale(range(0 -.2) reverse) xscale(range(0 .3)) xlabel (0(0.05) .3) ylabel(0 (0.05) -.2)
			

graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  , ///
			xtitle("Parts des inputs importés en provenance de pays hors zone euro dans la production") ytitle("Elasticité des prix de production en euro") ///
			yscale(range(0 -.2) reverse) xscale(range(0 .2)) xlabel (0(0.05) .2) ylabel(0 (0.05) -.2)

			
			graph export "$dir/Results/Devaluations/Graph_2_imp.png", replace
export excel "$dir/Results/Devaluations/Pour_Graph_2_imp.xlsx", firstrow(variable)replace


//////////////////////////////////////////////////////////////////////////////////////////////////////



global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"


use "$dir/Bases/loc_inputs_2011.dta", clear  //,keep(3)
//drop _merge

gen c=upper(pays)
drop pays

merge 1:1 c using "$dir/Results/Choc de prod/Pour_Graph_5.dta"

drop _merge pond_X

//replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Prix de production"

label var loc_inputs "Parts des inputs produits lacalement dans la production"

drop if strpos("$eurozone",c)==0

save "$dir/Results/Devaluations/Pour_Graph_8.dta", replace
//export delimited "$dir/Results/Devaluations/Pour_Graph_1_old.csv", replace

//graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  , ///
	//		xtitle("Parts des inputs importés dans la production") ytitle("Elasticité des prix de production en euro") ///
		//	yscale(range(0 -.2) reverse) xscale(range(0 .3)) xlabel (0(0.05) .3) ylabel(0 (0.05) -.2)
			


graph twoway (scatter pond_Y loc_inputs, mlabel(c_full_FR)) (qfit pond_Y loc_inputs)  , ///
			xtitle("Parts des inputs produits localement dans la production") ytitle("Elasticité des prix de production en euro") ///
			yscale(range(0 1)) xscale(range(0 .5)) xlabel (0(0.1) .5) ylabel(0 (0.1) 1)

			
			graph export "$dir/Results/Choc de prod/Graph_8.png", replace
export excel "$dir/Results/Choc de prod/Pour_Graph_8.xlsx", firstrow(variable)replace

//////////////////////////////////////////////////////////////////////////////////////////////////////



global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"


use "$dir/Bases/imp_inputsX_2011.dta", clear  //,keep(3)
//drop _merge

gen c=upper(pays)
drop pays

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

drop _merge pond_Y

//replace pond_Y = (pond_Y - 1)/2 

label var pond_X "Prix d'exportation"

label var imp_inputs "Parts des inputs importés dans les exportations"

drop if strpos("$eurozone",c)==0

save "$dir/Results/Devaluations/Pour_Graph_9.dta", replace
//export delimited "$dir/Results/Devaluations/Pour_Graph_1_old.csv", replace

//graph twoway (scatter pond_Y input_prod, mlabel(c_full_FR)) (qfit pond_Y input_prod)  , ///
	//		xtitle("Parts des inputs importés dans la production") ytitle("Elasticité des prix de production en euro") ///
		//	yscale(range(0 -.2) reverse) xscale(range(0 .3)) xlabel (0(0.05) .3) ylabel(0 (0.05) -.2)
			


graph twoway (scatter pond_X imp_inputs, mlabel(c_full_FR)) (lfit pond_X imp_inputs)  , ///
			xtitle("Parts des inputs importés en provenance de pays hors zone euro dans les exportations") ytitle("Elasticité des prix d'exportation en euro") ///
			yscale(range(0 -.3) reverse) xscale(range(0.4 .8)) xlabel (0.4(0.1) .8) ylabel(0 (0.05) -.3)


			
			graph export "$dir/Results/Devaluations/Graph_9.png", replace
export excel "$dir/Results/Devaluations/Pour_Graph_9.xlsx", firstrow(variable)replace
