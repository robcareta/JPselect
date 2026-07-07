# JPselection

**Just-Pope production functions with Heckman selectivity correction.**

`JPselection` is an R package that implements the three-step estimation
procedure of Koundouri & Nauges (2005, *Journal of Agricultural and
Resource Economics* 30(3):597-608) for Just-Pope (1978, 1979)
stochastic production functions with sample-selection bias from crop
choice.

The package returns the corrected **and** uncorrected specifications
side by side, so the bias in risk-function coefficients, the headline
finding of the paper, is visible directly.

## Installation

```r
# install.packages("remotes")
remotes::install_github("robcareta/JPselection")
```

## Where to go next

- **[Get started](articles/getting-started.html)** — a runnable example
  from simulated data to final tables, with sample `print()`,
  `summary()`, and `plot()` output.
- **[Methodology](articles/methodology.html)** — the Just-Pope
  framework, the Heckman correction, the three estimation steps, and
  alternative mean and risk functional forms.
- **[Function reference](reference/index.html)** — every exported
  function grouped by role (full pipeline, S3 methods, individual
  stages, export, example data).

## Citation

If you use `JPselection` in published work, please cite the underlying
paper together with the package:

> Koundouri, P. and Nauges, C. (2005). On Production Function
> Estimation with Selectivity and Risk Considerations.
> *Journal of Agricultural and Resource Economics*, 30(3), 597-608.
>
> Cardenas Retamal, R. (2026). *JPselection: Just-Pope Production
> Functions with Heckman Selectivity Correction.* R package version 0.2.0.
> <https://github.com/robcareta/JPselection>

In R, the canonical citation is also available via `citation("JPselection")`.

## References

- Heckman, J. (1979). Sample selection bias as a specification error.
  *Econometrica*, 47, 153-161.
- Just, R. E. and Pope, R. D. (1978). Stochastic representation of
  production functions and econometric implications.
  *Journal of Econometrics*, 7, 67-86.
- Koundouri, P. and Nauges, C. (2005). On Production Function
  Estimation with Selectivity and Risk Considerations.
  *Journal of Agricultural and Resource Economics*, 30(3), 597-608.

## License

MIT © 2026 Roberto Cardenas Retamal
