# JPselection: Just-Pope Production Functions with Heckman Selectivity Correction

Reproduces the three-step estimation procedure of Koundouri & Nauges
(2005, JARE 30(3):597-608) for Just-Pope (1978, 1979) stochastic
production functions with crop-choice sample selection.

## Quick start

Use \[jp_fit()\] for the full pipeline. Print, summarise, and plot the
result with \[print.jpfit()\], \[summary.jpfit()\], and
\[plot.jpfit()\].

Individual steps are also exposed for finer-grained workflows:
\[estimate_selection()\] (Step 1), \[estimate_mean_function()\] (Step
2), \[estimate_risk_function()\] (Step 3).

A simulated farm dataset matching the structure of the Cyprus sample
used in the paper is available via \[simulate_kiti_data()\].

## References

Koundouri, P. and Nauges, C. (2005). On production function estimation
with selectivity and risk considerations. *Journal of Agricultural and
Resource Economics*, 30(3), 597-608.

Just, R. E. and Pope, R. D. (1978). Stochastic representation of
production functions and econometric implications. *Journal of
Econometrics*, 7, 67-86.

Heckman, J. (1979). Sample selection bias as a specification error.
*Econometrica*, 47, 153-161.

## See also

Useful links:

- <https://github.com/robcareta/JPselection>

- Report bugs at <https://github.com/robcareta/JPselection/issues>

## Author

**Maintainer**: Roberto Cardenas Retamal <roberto.cardenasret@gmail.com>
