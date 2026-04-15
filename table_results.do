//  MODIFIED:                     APRIL 15, 2026
//  DESCRIPTION:                  Impact of TV Debates
//                                Estimates ATE, APR, R-APR, and Bounds (Stoye 2009)

clear all
set more off
set emptycells drop
set matsize 11000
set maxvar 30000

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
* Drop observations with missing outcome
keep if int_act != .

* Create cluster ID based on country and debate date
egen id_date = group(country date_debate)

* Keep observations within +/- 3 days of the debate
keep if inrange(dist_debate, -3, 3)

* Define treatment indicator (post-debate)
gen treat = (dist_debate >= 0)

* --- ROBUST COUNTRY HANDLING ---
* Create 'country_str' string variable to ensure safe looping over country codes
* (Handles cases where 'country' might be labeled numeric or already string)
capture confirm numeric variable country
if _rc == 0 {
    decode country, gen(country_str)
}
else {
    gen country_str = country
}

* Ensure 'age' is numeric for inequality conditions
capture destring age, replace force

* ------------------------------------------------------------------------------
* 3. ESTIMATION PROGRAMS
* ------------------------------------------------------------------------------

* --- Program 1: Estimate upper bounds on ATE, APR, and R-APR ---
capture program drop est_persuasion
program define est_persuasion, rclass
    syntax [if]
    
    tempname t_alpha t_cv
    scalar `t_alpha' = 0.05
    scalar `t_cv' = invnormal(1 - `t_alpha')

    tempname n_obs ub_ate se_ate ci_ate ub_apr se_apr ci_apr ub_apr_r se_apr_r ci_apr_r mat_b mat_v
    
    * Check if observations exist in the subsample
    quietly count `if'
    if r(N) == 0 {
        matrix row_res = J(1, 10, .)
        return matrix results = row_res
        exit
    }

    quietly reg int_act treat `if', cl(id_date)
    scalar `n_obs' = e(N)

    * ATE (in percentage)
    scalar `ub_ate' = _b[treat] * 100
    scalar `se_ate' = _se[treat] * 100
    scalar `ci_ate' = `ub_ate' + `t_cv' * `se_ate'

    * APR (in percentage)
    quietly nlcom _b[treat] / (1 - _b[_cons])
    matrix `mat_b' = r(b)
    matrix `mat_v' = r(V)
    scalar `ub_apr' = `mat_b'[1,1] * 100
    scalar `se_apr' = sqrt(`mat_v'[1,1]) * 100
    scalar `ci_apr' = `ub_apr' + `t_cv' * `se_apr'

    * R-APR (in percentage)
    quietly nlcom _b[treat] / (_b[_cons] + _b[treat])
    matrix `mat_b' = r(b)
    matrix `mat_v' = r(V)
    scalar `ub_apr_r' = `mat_b'[1,1] * 100
    scalar `se_apr_r' = sqrt(`mat_v'[1,1]) * 100
    scalar `ci_apr_r' = `ub_apr_r' + `t_cv' * `se_apr_r'
    
    matrix row_res = (scalar(`n_obs'), scalar(`ub_ate'), scalar(`se_ate'), scalar(`ci_ate'), ///
                      scalar(`ub_apr'), scalar(`se_apr'), scalar(`ci_apr'), ///
                      scalar(`ub_apr_r'), scalar(`se_apr_r'), scalar(`ci_apr_r'))
    return matrix results = row_res
end

* --- Program 2: Estimate upper and lower bounds on AP and NP ---
capture program drop est_bounds
program define est_bounds, rclass
    syntax [if]
    
    tempname t_alpha t_mincv t_maxcv
    scalar `t_alpha' = 0.05
    scalar `t_mincv' = invnormal(1 - `t_alpha') - 0.01
    scalar `t_maxcv' = invnormal(1 - (`t_alpha'/2)) + 0.01
    
    tempname lb_ap se_lb_ap lb_np se_lb_np ub_ap se_ub_ap ub_np se_ub_np
    tempname correction gridsize cv_stoye cvtmp difftmp n_obs mat_b mat_v
    
    quietly count `if'
    if r(N) == 0 {
        matrix row_res = J(1, 8, .)
        return matrix results = row_res
        exit
    }
    
    quietly reg int_act treat `if', cl(id_date)
    scalar `n_obs' = e(N)
    
    * Lower Bounds
    scalar `lb_ap' = _b[_cons]
    scalar `se_lb_ap' = _se[_cons]
    quietly nlcom 1 - (_b[_cons] + _b[treat])    
    matrix `mat_b' = r(b)
    matrix `mat_v' = r(V)
    scalar `lb_np' = `mat_b'[1,1]
    scalar `se_lb_np' = sqrt(`mat_v'[1,1])

    * Upper Bounds
    quietly reg int_act `if', cl(id_date)
    scalar `ub_ap' = _b[_cons]
    scalar `se_ub_ap' = _se[_cons]
    quietly nlcom 1 - _b[_cons]
    matrix `mat_b' = r(b)
    matrix `mat_v' = r(V)
    scalar `ub_np' = `mat_b'[1,1]
    scalar `se_ub_np' = sqrt(`mat_v'[1,1])

    * Compute Stoye (2009) Confidence Intervals
    local types ap np
    foreach t in `types' {
        scalar `correction' = (`ub_`t'' - `lb_`t'') / max(`se_ub_`t'', `se_lb_`t'')
        scalar `gridsize' = (`t_maxcv' - `t_mincv') / (`n_obs' - 1)
        
        quietly {
            cap drop `cvtmp' `difftmp'
            egen `cvtmp' = fill(0 `=`gridsize'')
            replace `cvtmp' = `cvtmp' + `t_mincv'
            gen `difftmp' = abs(normal(`cvtmp' + `correction') - normal(-`cvtmp') - (1 - scalar(`t_alpha')))
            summ `difftmp'
            replace `cvtmp' = . if `difftmp' > r(min)
            summ `cvtmp'
            scalar `cv_stoye' = r(mean)
        }
        tempname ci_lb_`t' ci_ub_`t' val_lb_`t' val_ub_`t'
        scalar `ci_lb_`t'' = `lb_`t'' - `cv_stoye' * `se_lb_`t''
        scalar `ci_ub_`t'' = `ub_`t'' + `cv_stoye' * `se_ub_`t''
        scalar `val_lb_`t'' = `lb_`t''
        scalar `val_ub_`t'' = `ub_`t''
    }
    
    matrix row_res = (scalar(`ci_lb_ap'), scalar(`val_lb_ap'), scalar(`val_ub_ap'), scalar(`ci_ub_ap'), ///
                      scalar(`ci_lb_np'), scalar(`val_lb_np'), scalar(`val_ub_np'), scalar(`ci_ub_np'))
    return matrix results = row_res
end


* ------------------------------------------------------------------------------
* 4. GENERATE MATRICES
* ------------------------------------------------------------------------------

* Define conditions for subsamples
* IMPORTANT: We do NOT use outer quotes (" ") for the conditions here.
* This avoids syntax errors when Stata tries to nest the quotes for string variables.
local cond1 
local cond2 if age < 50
local cond3 if age >= 50
local cond4 if country_str == "US"
local cond5 if country_str == "UK"

* Define labels for the LaTeX table
local label1 "All"
local label2 "Age $<$ 50"
local label3 "Age $\ge$ 50"
local label4 "U.S."
local label5 "U.K."

* Initialize empty matrices
matrix drop _all

forvalues i = 1/5 {
    
    * Access macros directly
    local curr_lbl "`label`i''"
    
    * Display strictly for debugging
    di "Processing: `curr_lbl'"
    
    * 1. Panel A: Persuasion Rates
    est_persuasion `cond`i''
    matrix res_A_tmp = r(results)
    
    * 2. Panel B: Bounds on Types
    est_bounds `cond`i''
    matrix res_B_tmp = r(results)
    
    * Stack Results
    if `i' == 1 {
        matrix MAT_A = res_A_tmp
        matrix MAT_B = res_B_tmp
    }
    else {
        matrix MAT_A = MAT_A \ res_A_tmp
        matrix MAT_B = MAT_B \ res_B_tmp
    }
}

* Scale Panel B by 100 for percentage reporting
matrix MAT_B = MAT_B * 100

* ------------------------------------------------------------------------------
* 5. WRITE COMBINED LATEX TABLE DIRECTLY
* ------------------------------------------------------------------------------
capture file close fh
file open fh using "tv_debate_combined_final.tex", write replace

* --- Preamble ---
file write fh "\begin{table}[!htbp]" _n
file write fh "  \centering" _n
file write fh "  \caption{Estimation Results}" _n
file write fh "  \label{tab:combined_results}" _n

* ==============================================================================
* PANEL A
* ==============================================================================
file write fh _n "  % --- Panel A ---" _n
file write fh "  Panel A: Upper Bounds on the Persuasion Rates (in Percentage)" _n
file write fh "  \medskip" _n
file write fh "  \begin{tabular}{l r rrr rrr rrr}" _n
file write fh "    \hline\hline" _n
file write fh "    & & \multicolumn{3}{c}{ATE} & \multicolumn{3}{c}{APR ($\theta$)} & \multicolumn{3}{c}{R-APR ($\theta^{(r)}$)} \\" _n
file write fh "    & \$N\$ & Est. & SE & UCB & Est. & SE & UCB & Est. & SE & UCB \\ \hline" _n

local n_rows = rowsof(MAT_A)

forvalues r = 1/`n_rows' {
    local lbl "`label`r''"
    
    * Extract Sample Size (No decimals)
    local v_obs = string(MAT_A[`r', 1], "%9.0f")
    
    * Extract Estimates (2 decimal places)
    local v1 = string(MAT_A[`r', 2], "%9.2f")
    local v2 = string(MAT_A[`r', 3], "%9.2f")
    local v3 = string(MAT_A[`r', 4], "%9.2f")
    local v4 = string(MAT_A[`r', 5], "%9.2f")
    local v5 = string(MAT_A[`r', 6], "%9.2f")
    local v6 = string(MAT_A[`r', 7], "%9.2f")
    local v7 = string(MAT_A[`r', 8], "%9.2f")
    local v8 = string(MAT_A[`r', 9], "%9.2f")
    local v9 = string(MAT_A[`r', 10], "%9.2f")
    
    file write fh "    `lbl' & `v_obs' & `v1' & `v2' & `v3' & `v4' & `v5' & `v6' & `v7' & `v8' & `v9' \\" _n
}
file write fh "    \hline" _n
file write fh "  \end{tabular}" _n

file write fh _n "  \bigskip" _n

* ==============================================================================
* PANEL B
* ==============================================================================
file write fh _n "  % --- Panel B ---" _n
file write fh "  Panel B: Proportions of AP and NP (in Percentage)" _n
file write fh "  \medskip" _n
file write fh "  \begin{tabular}{lcccccccc}" _n
file write fh "    \hline\hline" _n
file write fh "    & \multicolumn{4}{c}{Already-Persuaded (AP)} & \multicolumn{4}{c}{Never-Persuadable (NP)} \\" _n
file write fh "    & CI-LB & LB & UB & CI-UB & CI-LB & LB & UB & CI-UB \\ \hline" _n

forvalues r = 1/`n_rows' {
    local lbl "`label`r''"
    
    * Extract values from Matrix B
    local v1 = string(MAT_B[`r', 1], "%9.2f")
    local v2 = string(MAT_B[`r', 2], "%9.2f")
    local v3 = string(MAT_B[`r', 3], "%9.2f")
    local v4 = string(MAT_B[`r', 4], "%9.2f")
    local v5 = string(MAT_B[`r', 5], "%9.2f")
    local v6 = string(MAT_B[`r', 6], "%9.2f")
    local v7 = string(MAT_B[`r', 7], "%9.2f")
    local v8 = string(MAT_B[`r', 8], "%9.2f")

    file write fh "    `lbl' & `v1' & `v2' & `v3' & `v4' & `v5' & `v6' & `v7' & `v8' \\" _n
}
file write fh "    \hline" _n
file write fh "  \end{tabular}" _n

* --- Notes & Footer ---
file write fh _n "  \medskip" _n
file write fh "  \begin{minipage}{0.9\textwidth}" _n
file write fh "    {\small \emph{Notes}: Panel A presents the upper bound estimates, standard errors (SE), and 95\% upper confidence bounds (UCB) for ATE, APR, and R-APR. Panel B reports lower and upper bounds (LB and UB, respectively) on the proportions of Already-Persuaded (AP) and Never-Persuadable (NP) types along with 95\% confidence lower and upper bounds (CI-LB and CI-UB, respectively). All figures are in percentages. Standard errors are clustered at the debate level.}" _n
file write fh "  \end{minipage}" _n
file write fh "\end{table}" _n

file close fh

di "Done! Table saved to: tv_debate_combined_final.tex"
