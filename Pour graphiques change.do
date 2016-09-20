

if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"
if ("`c(username)'"=="L841580") global dir "H:\Agents\Cochard\Papier_chocCVA"






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

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

drop _merge 

replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Production prices"

label var pond_X "Export prices"

save "$dir/Results/Devaluations/Pour_Graph_1.dta", replace






graph bar (asis) pond_X pond_Y , over(c, sort(pond_X) label(angle(vertical) labsize(tiny))) 


graph export "$dir/Results/Devaluations/Graph_1.png", replace


*Graphique 2

use "$dir/Results/Devaluations/mean_chg_X_1995.dta", clear

foreach var of varlist shockEUR1-shockZAF1 {
	local pays = substr("`var'",6,3)
	replace `var' = 0 if strmatch(c,"*`pays'*")==0
}

egen pond_X_1995 = rowtotal(shockEUR1-shockZAF1)
replace pond_X_1995 = (pond_X_1995 - 1)/2

keep c pond_X_1995

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

rename pond_X pond_X_2011

drop pond_Y

save "$dir/Results/Devaluations/Pour_Graph_2.dta", replace

label var pond_X_1995 "Export prices, 1995"

label var pond_X_2011 "Export prices, 2011"

graph bar (asis) pond_X_1995 pond_X_2011 , over(c, sort(pond_X_2011) label(angle(vertical) labsize(tiny))) 

graph export "$dir/Results/Devaluations/Graph_2.png", replace




**Tableau 1

global eurozone "AUT BEL CYP DEU ESP EST FIN FRA GRC IRL ITA LTU LUX LVA MLT NLD PRT SVK SVN"
global eastern "BGR CZE HRV HUN POL ROU"

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
	
		export excel "$dir/Results/Devaluations/Tableau_1_`pond'.xls", firstrow(variables) cell(`column'1) sheetmodify

	}
}









