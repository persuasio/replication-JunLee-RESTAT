//  MODIFIED:                     APRIL 15, 2026
//  DESCRIPTION:                  Impact of TV Debates
//                                Balance Check

clear all
set more off
set emptycells drop
set matsize 11000
set maxvar 30000

* ------------------------------------------------------------------------------
* 0. DEPENDENCIES
* ------------------------------------------------------------------------------
* Requires the "estout" package. Install once by running:
*   ssc install estout, replace

* ------------------------------------------------------------------------------
* 1. SETUP AND PATHS
* ------------------------------------------------------------------------------
* Set working directory to the folder containing this do-file
* (run.do sets this globally; if running standalone, set it manually here)
* global workdir "/path/to/replication/folder"
* cd "$workdir"

* Load Data
use "LePennecPons2023", clear

* ------------------------------------------------------------------------------
* 2. DATA PREPARATION
* ------------------------------------------------------------------------------
keep if int_act != .
egen id_date = group(country date_debate)

* Keep observations within +/- 3 days
keep if inrange(dist_debate, -3, 3)

* Define treatment (Post-Debate)
gen treat = (dist_debate >= 0)

* Robust country handling
capture confirm numeric variable country
if _rc == 0 {
    decode country, gen(country_str)
}
else {
    gen country_str = country
}

* Ensure age is numeric
capture destring age, replace force

* ------------------------------------------------------------------------------
* 3a. INDIVIDUAL BALANCE REGRESSIONS
* ------------------------------------------------------------------------------
local covariates "male age highschoolm college income50 income75 income100 employed"

eststo clear

* Run individual regressions (Column by Column)
foreach x in `covariates' {
    eststo bal_`x': reg `x' treat, cl(id_date)
}

* ------------------------------------------------------------------------------
* 3b. JOINT ORTHOGONALITY TEST (Joint F-Test)
* ------------------------------------------------------------------------------
* We regress Treatment on ALL covariates to test if they jointly predict treatment.
* The Null Hypothesis is that all coefficients are jointly zero (Balance holds).

reg treat `covariates', cl(id_date)
testparm `covariates'
local joint_p = r(p)
local joint_f = r(F)

* Format the p-value for the footer string
local p_str : display %9.3f `joint_p'

* ------------------------------------------------------------------------------
* 4. GENERATE LATEX TABLE
* ------------------------------------------------------------------------------

esttab bal_* using "balance_test.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs ///
    keep(treat) ///
    coeflabels(treat "Difference (Treat - Control)") ///
    mtitles("Male" "Age" "HS" "Coll" "Inc50" "Inc75" "Inc100" "Empl") ///
    title("Covariate Balance Test (3-Day Window)") ///
    addnotes("Standard errors clustered by debate ID." "Joint F-test p-value: `p_str'") ///
    nonotes
    
* Display in Stata window
esttab bal_*, keep(treat) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label mtitles addnotes("Joint p-value: `p_str'")
