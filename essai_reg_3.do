clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace
set matsize 10000
*set mem 700m if earlier version of stata (<stata 12)
set more off

use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"


drop if cor =="yes"
drop cor
drop if cause==effect
generate ln_shock=ln(shock)

generate matrix= shock_type+weight

generate cause_matrix = cause+matrix
generate effect_matrix=effect+matrix

encode cause, generate (ncause)
encode effect, generate (neffect)
encode matrix, generate (nmatrix)
encode  cause_matrix, generate (ncause_matrix)
encode  effect_matrix, generate (neffect_matrix)

 

*regress ln_shock i.ncause ib2.neffect i.nmatrix i.ncause#i.nmatrix ib2.neffect#i.nmatrix

regress ln_shock i.ncause i.neffect i.nmatrix i.ncause#i.nmatrix i.neffect#i.nmatrix

log close

*-------------------------------------------------------------------------------
clear
capture log using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/results/$S_DATE $S_TIME.log", replace

clear
set matsize 11000, perm
set more off
use "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/mean_effect/mean_all.dta"
*Withdraw the corrected or not criteria
drop if cor =="yes"
drop cor
*Withdraw self-effects
drop if cause==effect
*Take the log of shock
generate ln_shock=ln(shock)
*Create a variable type of matrix
generate matrix= shock_type+weight
*Prepare to merge
rename cause pays
*From a .dta where we created regions
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions.dta"
drop _merge
rename region region_cause
rename pays cause
rename effect pays
merge m:1 pays using "/Users/sandrafronteau/Documents/Stage_OFCE/Stata/data/ocde/pays_regions.dta"
drop _merge
rename region region_effect
rename pays effect
generate region = region_cause + "_" + region_effect if region_cause <= region_effect
replace region  = region_effect + "_" + region_cause if region_cause >= region_effect
generate region_year=region+"_"+year
destring year, replace
generate cause_matrix = cause+matrix
generate effect_matrix=effect+matrix
encode cause, generate (ncause)
encode effect, generate (neffect)
encode matrix, generate (nmatrix)
encode  cause_matrix, generate (ncause_matrix)
encode  effect_matrix, generate (neffect_matrix)
encode region, generate (nregion)
encode region_year, generate (nregion_year)

set more off
regress ln_shock  i.ncause##i.nmatrix ib2.neffect##i.nmatrix ib4.nregion##i.year

log close

