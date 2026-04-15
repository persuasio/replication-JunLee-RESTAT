//  REPLICATION MASTER SCRIPT
//  PAPER:       Bounding the Effect of Persuasion with Monotonicity Assumptions:
//               Reassessing the Impact of TV Debates
//  AUTHORS:     Sung Jae Jun and Sokbae Lee
//  JOURNAL:     Review of Economics and Statistics
//  DESCRIPTION: Runs all do-files to replicate the empirical results in the paper.

// ------------------------------------------------------------------------------
// USER SETTING: Set the path to the replication folder
// ------------------------------------------------------------------------------
global workdir "/path/to/replication/folder"   // <-- CHANGE THIS

cd "$workdir"

// ------------------------------------------------------------------------------
// DEPENDENCIES: Install required packages if not already installed
// ------------------------------------------------------------------------------
* ssc install estout, replace

// ------------------------------------------------------------------------------
// RUN REPLICATION SCRIPTS
// ------------------------------------------------------------------------------

// Table: Estimation results (Panel A: ATE, APR, R-APR; Panel B: AP and NP bounds)
// Output: tv_debate_combined_final.tex
do "table_results.do"

// Balance check: Covariate balance test (joint F-test)
// Output: balance_test.tex
do "balance_check.do"

di "Replication complete. Output files written to: $workdir"
