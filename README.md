# Replication: Jun and Lee (2025)

## Overview

This folder contains files to replicate the empirical results from the following paper:

Sung Jae Jun and Sokbae Lee. "Bounding the Effect of Persuasion with Monotonicity Assumptions: Reassessing the Impact of TV Debates." _Review of Economics and Statistics_, forthcoming.

## Data

The dataset `LePennecPons2023.dta` is derived from the replication data of:

Caroline Le Pennec and Vincent Pons. "How do Campaigns Shape Vote Choice? Multicountry Evidence from 62 Elections and 56 TV Debates." _Quarterly Journal of Economics_, 138(2), 2023.

The original file name is `analysis_debate_indiv.dta`. Researchers should obtain the data directly from the following archive and rename the file to `LePennecPons2023.dta`:

Le Pennec, Caroline; Pons, Vincent, 2022, "Replication Data for: 'How Do Campaigns Shape Vote Choice? Multicountry Evidence from 62 Elections and 56 TV Debates'", https://doi.org/10.7910/DVN/XMDFQO, Harvard Dataverse, V1.

## Replication Folder Structure

```
Replication/
├── run.do                      # Master script — run this to replicate all results
├── table_results.do            # Produces Table: ATE, APR, R-APR, AP and NP bounds
├── balance_check.do            # Produces balance check table (joint F-test)
├── LePennecPons2023.dta        # Dataset (derived from Le Pennec and Pons, 2023)
└── README.md                   # This file
```

## Output Files

Running `run.do` produces the following files in the replication folder:

| Output file                    | Description                              | Paper reference        |
|-------------------------------|------------------------------------------|------------------------|
| `tv_debate_combined_final.tex` | Table: upper bounds on ATE, APR, R-APR, and proportions of AP and NP types | Table in Section 7     |
| `balance_test1.tex` `balance_test2.tex` | Covariate balance test across pre- and post-debate groups | Section 7 (p-value = 0.445) |

## Instructions

1. Obtain `LePennecPons2023.dta` from LP's replication package (see Data section above).
2. Open `run.do` and set the `workdir` global macro to the path of this replication folder.
3. Run `run.do` in Stata. This calls `table_results.do` and `balance_check.do` in sequence.

## Software and Dependencies

- **Stata** version 16 or higher
- **estout** package (used in `balance_check.do`). Install once by running:
  ```stata
  ssc install estout, replace
  ```
