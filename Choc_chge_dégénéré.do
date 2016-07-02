clear

global dir "H:\Agents\Cochard\Papier_chocCVA"

if ("`c(username)'"=="guillaumedaudin") global dir "~/Dropbox/commerce en VA"
if ("`c(username)'"=="L841580") global dir "H:\Agents\Cochard\Papier_chocCVA"


capture log using "$dir/$S_DATE $S_TIME.log", replace
set matsize 7000
*set mem 700m if earlier version of stata (<stata 12)
set more off


capture program drop compute_CT_dégénéré
program compute_CT_dégénéré
	args yrs groupeduchoc
*ex : compute_leontief_dégénéré 2005 SGP

use "$dir/Bases/A_`yrs'.dta", clear

merge 1:1 _n using "$dir/Bases/csv.dta"
drop _merge

replace c="RDM" if c!="`groupeduchoc'"

local blif =strlower("`groupeduchoc'")
display "`blif'"

egen `groupeduchoc'=rowmean(`blif'*) 
egen RDM=rowmean(arg_c01t05agr-zaf_c95pvh)
*replace RDM = RDM-`groupeduchoc'
keep c s RDM `groupeduchoc'



collapse (sum) RDM `groupeduchoc' , by (c)


list


end

compute_CT_dégénéré 2005 SGP

drop c
mkmat *,matrix(A)
matrix list A


matrix X = I(2)-A
matrix list X

matrix I_A_1=inv(X)
matrix list I_A_1

matrix test = Z*X
matrix list test

matrix define V =(0,1)
matrix define V1 =(-0.5,0)
local blif = el(A,0,1)
display "`blif'"
matrix  B1 =(0 , el(A,1,2) \ 0,0)
matrix list B1

matrix B=(0,0 \ el(A,2,1),0)
matrix list B

matrix result = V + V*B*I_A_1 + V1*B1*I_A_1
matrix list result





