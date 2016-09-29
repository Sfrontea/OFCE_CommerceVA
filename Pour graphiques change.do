

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

merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_1.dta"

drop _merge 

replace pond_Y = (pond_Y - 1)/2 

label var pond_Y "Prix de production"

label var pond_X "Prix d'export"

save "$dir/Results/Devaluations/Pour_Graph_1.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_1.csv", replace






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


label var pond_X_1995 "Prix d'export, 1995"

label var pond_X_2011 "Prix d'export, 2011"

save "$dir/Results/Devaluations/Pour_Graph_2.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_2.csv", replace


graph bar (asis) pond_X_1995 pond_X_2011 , over(c, sort(pond_X_2011) label(angle(vertical) labsize(tiny))) 

graph export "$dir/Results/Devaluations/Graph_2.png", replace







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

label var pond_Yt "Prix de production"

label var pond_X "Prix d'export"

save "$dir/Results/Devaluations/Pour_Graph_3.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_3.csv", replace

graph bar (asis) pond_X pond_Yt , over(c, sort(pond_X) label(angle(vertical) )) 


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




merge 1:1 c using "$dir/Results/Devaluations/Pour_Graph_4.dta"

label var pond_Yt "Prix de production"

label var pond_X "Prix d'export"

save "$dir/Results/Devaluations/Pour_Graph_4.dta", replace
export delimited "$dir/Results/Devaluations/Pour_Graph_4.csv", replace

graph bar (asis) pond_X pond_Yt , over(c, sort(pond_X) descending label(angle(vertical) labsize(vsmall))) 


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

replace pond_Y = (pond_Y - 1)

label var pond_Y "Prix de production"

label var pond_X "Prix d'export"

save "$dir/Results/Choc de prod/Pour_Graph_5.dta", replace
export delimited "$dir/Results/Choc de prod/Pour_Graph_5.csv", replace






graph bar (asis) pond_X pond_Y , over(c, sort(pond_X) descending label(angle(vertical) labsize(tiny))) 


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
	
		export excel "$dir/Results/Devaluations/Tableau_1_`pond'.xls", firstrow(variables) cell(`column'1) sheetmodify

	}
}

***Tableau 2


foreach year in 1995 2000 2005 2009 2010 2011 {
	use "$dir/Results/Devaluations/mean_chg_X_`year'.dta", clear
	keep if strpos("$eurozone",c)!=0
	
	if `year'==1995 local column A
	if `year'==2000 local column C
	if `year'==2005 local column D
	if `year'==2009 local column E
	if `year'==2010 local column F
	if `year'==2011 local column G
		
	keep c shockEUR1
	if `year'!=1995 drop c 
	rename shockEUR1 shockEUR_`year'
	replace shockEUR_`year' = (shockEUR_`year' - 1)/2
	
	
	export excel "$dir/Results/Devaluations/Tableau_2.xls", firstrow(variables) cell(`column'1) sheetmodify
}
	
	

	

***Tableau 3


local orig USA CHN JPN GBR EAS RUS SAU

use "$dir/Results/Devaluations/mean_chg_Yt_2011.dta", clear
drop if strpos("$eurozone",c)==0
	
keep c shockUSA1 shockCHN1 shockJPN1 shockGBR1 shockEAS1 shockRUS1 shockSAU1   

export excel "$dir/Results/Devaluations/Tableau_3.xls", firstrow(variables) sheetmodify

		
	
	
***Tableau 4


local orig USA CHN JPN GBR EAS RUS SAU

use "$dir/Results/Devaluations/mean_chg_X_2011.dta", clear
drop if strpos("$eurozone",c)==0
	
keep c shockUSA1 shockCHN1 shockJPN1 shockGBR1 shockEAS1 shockRUS1 shockSAU1   

export excel "$dir/Results/Devaluations/Tableau_4.xls", firstrow(variables) sheetmodify

	

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
		
	keep c shockEAS1
	if `year'!=1995 drop c 
	rename shockEAS1 shockEAS_`year'
	
	
	export excel "$dir/Results/Devaluations/Tableau_5.xls", firstrow(variables) cell(`column'1) sheetmodify
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

preserve


local tokeep c 
foreach euro of global eurozone {
		rename shock`euro'1 `euro'
		local tokeep `tokeep' `euro'
		replace `euro'=0 if c=="`euro'"
}

keep `tokeep'

gen Europe_Est = SVK + SVN + EST + LTU + LVA
drop SVK SVN EST LTU LVA
gen Europe_Sud = CYP + GRC + MLT + PRT
drop CYP  GRC  MLT  PRT
gen AUT_IRL_FIN = AUT + IRL + FIN
drop AUT IRL FIN


egen EUR =rowtotal(BEL-AUT_IRL_FIN)

foreach euro in BEL DEU ESP FRA ITA LUX NLD {
		replace `euro'=. if c=="`euro'"
}

export excel "$dir/Results/Devaluations/Tableau_7.xls", firstrow(variables) replace



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

egen PECO= rowtotal($eastern)

local tokeep c PECO
foreach pays in USA CHN JPN GBR RUS SAU {
		rename shock`pays'1 `pays'
		local tokeep `tokeep' `pays'
}

keep `tokeep'
order c PECO

export excel "$dir/Results/Devaluations/Tableau_7.xls", firstrow(variables) replace












