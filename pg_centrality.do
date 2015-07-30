clear
set more off
set matsize 7000

global dir ~/Dropbox/commerce en VA
cd "$dir"

*----------------------------------------------------------------------------------
*        Calcul des degrees
*----------------------------------------------------------------------------------

***************************************************************************************************
************************** On calcule les indegrees***********************************************
***************************************************************************************************



* On récupère la matrice des effets moyens, non corrigés

use "$dir/Results mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor

* On calcule le vecteur des indegree

collapse (sum) shock, by(effect shock_type-year) 
rename shock indegree
rename effect country

save "$dir\Centrality\mean_all_indegree.dta", replace

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


foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	create_y `i'
	if `i'!=1995 {
		append using prod.dta
	}
	save prod.dta, replace
	
}


***************************************************************************************************
* 2- Création des tables X de production : on crée le vecteur 1*67 des productions totales de chauqe pays
***************************************************************************************************

*Creation of the vector of export X
capture program drop compute_X
program compute_X
	args yrs

use "$dir/OECD`yrs'.dta", clear

global country2 "arg aus aut bel bgr bra brn can che chl chn chn*npr chn*pro chn*dom col cri cyp cze deu dnk esp est fin fra gbr grc hkg hrv hun idn ind irl isl isr ita jpn khm kor ltu lux lva mex mex*ngm mex*gmf mlt mys nld nor nzl phl pol prt rou row rus sau sgp svk svn swe tha tun tur twn usa vnm zaf"

egen utilisations = rowtotal(aus_c01t05agr-disc)
gen utilisations_dom = .

foreach i of global country2 {
	egen blouk = rowtotal(`i'_*)
	replace utilisations_dom = blouk if strmatch(v1,strupper("`i'_"))==1
	drop blouk
	egen blif = rowtotal(chn_*) if ("`i'"=="chn?npr" | "`i'"=="chn?pro" |"`i'"=="chn?dom")
	replace utilisations_dom = utilisations_dom + blif
	drop blif
	egen blif = rowtotal(mex_*) if ("`i'"=="mex?ngm" | "`i'"=="mex?gmf")
	replace utilisations_dom = utilisations_dom + blif
	drop blif
}
generate X = utilisations - utilisations_dom
	


generate pays = strupper(substr(v1,1,strpos(v1,"_")-1))


mkmat X

end

compute_X 1995



foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	compute_X `i'
	if `i'!=1995 {
		append using exports.dta
	}
	save exports.dta, replace
	
}







***************************************************************************************************
* 3- On multiplie la matrice des pondérations transposée par la matrice des effets moyens, et on garde lae vecteur diagonale
***************************************************************************************************

capture program drop outdegree
program outdegree

clear
use "$dir/Results mean_effect/mean_all.dta"
drop if cor=="yes"
drop cor
rename effect pays
destring year, replace

merge m:1 pays year using prod.dta
rename pays effect
rename prod prod_effec

replace prod = 0 if effec==cause
bys (effect cause year shock shock_type weight) : egen somme_des_poids=total(prod)

end

outdegree
/*





import excel "C:\Users\L841580\Desktop\I-O-Stan\bases_stata\mean_effect/mean_p_X_`yrs'.xls", firstrow 
mkmat shockARG1-shockZAF1, matrix(M)
matrix OMt = Omega_`yrs''  /*matrice des pondérations oméga*/ 
matrix OUTDEGREE=OMt*M
mat outegree_`yrs'=vecdiag(OUTDEGREE)

svmat OUTDEGREE
save "C:\Users\L841580\Desktop\I-O-Stan\bases_stata/outdegree_`yrs'.dta", replace

export excel using "C:\Users\L841580\Desktop\I-O-Stan\bases_stata/outdegree_`yrs'.xls", firstrow(variables) 

end

foreach i of numlist 1995 2000 2005 2008 2009 2010 2011{ 
	clear matrix
	set more off
	create_y `i'
	omega `i'
	outdegree `i'
}


