clear
capture log using "H:\Agents\Cochard\Papier_chocCVA/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off
global dir "H:\Agents\Cochard\Papier_chocCVA"

*-------------------------------------------------------------------------------
*COMPUTING LEONTIEF INVERSE MATRIX  : matrix L1
*-------------------------------------------------------------------------------
clear
set more off

use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD_2011_OUT.dta"
mkmat arg_c01t05agr-zaf_c95pvh, matrix(Y)

*Create matrix Z of inter-industry inter-country trade
use "H:\Agents\Cochard\Papier_chocCVA\Bases/OECD_2011_Z.dta"
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


svmat L1, name(L1)

keep L1*
* shockARG1 represents the mean effect of a price shock coming from Argentina for each country
save "H:\Agents\Cochard\Papier_chocCVA\Bases/Leontieff2011.dta", replace


*We obtain a table of mean effect of a price shock from each country to all countries

export excel using "H:\Agents\Cochard\Papier_chocCVA\Bases/mean_effect/Leontieff2011.xls", firstrow(variables)


