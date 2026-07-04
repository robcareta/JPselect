# Methodology: Just-Pope with Heckman correction

## The Just-Pope production function

Just and Pope (1978) decompose output into a deterministic mean plus a
stochastic component whose **magnitude itself depends on inputs**:

``` math
y_l = f(\mathbf{x}, \boldsymbol{\beta}_l) + h(\mathbf{x}, \boldsymbol{\xi}_l)\,\eta_l, \qquad \eta_l \sim N(0, 1).
```

- $`f(\cdot)`$ is the **mean function**, which maps inputs to expected
  output.
- $`h(\cdot)`$ is the **risk** (variance) **function**, which maps
  inputs to output variability. Negative coefficients in $`h`$ mean an
  input is *risk-decreasing*; positive ones mean *risk-increasing*.

The risk function is the headline output: it tells whether labour,
water, fertiliser, etc. *reduce* or *amplify* yield uncertainty.

## Why crop choice creates a selectivity problem

Producers choose among $`L`$ candidate crops by comparing expected
profits. Whether a farm specialises in vegetables vs. cereals depends
partly on observables (soil, climate, water access) and partly on
**unobservables** correlated with productivity. Estimating the
production function $`f`$ on the chosen sub-sample alone therefore
biases the estimates. This is a textbook Heckman problem.

## The Heckman correction

For each candidate crop, a probit predicts the choice indicator $`D_l`$:

``` math
D_l = \mathbf{1}\big[g(\mathbf{z}, \boldsymbol{\lambda}_l) + v_l > 0\big],
```

and the **Inverse Mills Ratio** is computed as

``` math
M_l = \frac{\phi(g(\mathbf{z}, \hat{\boldsymbol{\lambda}}_l))}{\Phi(g(\mathbf{z}, \hat{\boldsymbol{\lambda}}_l))},
```

where $`\phi`$ and $`\Phi`$ are the standard-normal pdf and cdf. Adding
$`M_l`$ as a regressor in the production function absorbs the average
unobserved “productivity” of the selected sample, making the remaining
coefficients consistent.

## The three estimation steps

| Step | What is estimated | Function |
|----|----|----|
| 1 | Probit on $`D_l`$, then compute $`M_l`$ | [`estimate_selection()`](https://robcareta.github.io/JPselect/reference/estimate_selection.md) |
| 2 | Mean fn: $`y_l = f(\mathbf{x},\boldsymbol{\beta}_l) + \sigma_l M_l + w_l`$ with $`f`$ linear-quadratic | [`estimate_mean_function()`](https://robcareta.github.io/JPselect/reference/estimate_mean_function.md) |
| 3 | Risk fn via $`\log\|\hat w_l\| = \xi_0 + \sum_j \xi_j \log x_j + \log\eta_l`$ (Cobb-Douglas $`h`$) | [`estimate_risk_function()`](https://robcareta.github.io/JPselect/reference/estimate_risk_function.md) |

Step 2 fits the **linear-quadratic mean function**

``` math
f(\mathbf{x}) = \beta_0 + \sum_j \beta_j x_j + \sum_j \beta_{2j} x_j^2 + \sum_{j < k} \beta_{jk} x_j x_k.
```

Step 3 fits the **Cobb-Douglas risk function** $`h(\mathbf{x}) = \xi_0
\prod_j x_j^{\xi_j}`$, so each coefficient $`\xi_j`$ is the **variance
elasticity** of input $`j`$: a 1% rise in the input changes output
variance by $`\xi_j`$%. Negative $`\xi_j`$ → risk-decreasing input;
positive $`\xi_j`$ → risk-increasing.

## Alternative mean-function forms

The default mean function is the **linear-quadratic** form used in
Koundouri & Nauges (2005). Two alternatives are available through
`jp_fit(..., mean_form = ...)`:

- `"linear_quadratic"` (default):
  $`\beta_0 + \sum \beta_j x_j + \sum \beta_{jj} x_j^2 + \sum_{j<k} \beta_{jk} x_j x_k`$.
- `"quadratic"`: drops the pairwise interaction terms. Useful when the
  sample is small relative to the number of inputs.
- `"cobb_douglas"`: log-log specification
  $`\log y = \beta_0 + \sum \beta_j \log x_j + \text{shifters} + \sigma M + w`$.
  Requires strictly positive output and inputs. Shankar & Nelson (1999)
  showed that this Cobb-Douglas mean + Cobb-Douglas variance pairing is
  robust to input endogeneity in the JP framework.

``` r

fit_q  <- jp_fit(..., mean_form = "quadratic")
fit_cd <- jp_fit(..., mean_form = "cobb_douglas")
```

## Alternative risk-function form: exponential

Some applications need to handle **zero-valued inputs** (e.g. farms that
report no pesticide use), which the Cobb-Douglas form cannot because it
requires $`\log(x_j)`$.
[`jp_fit()`](https://robcareta.github.io/JPselect/reference/jp_fit.md)
therefore accepts `risk_form = "exponential"`, fitting

``` math
h(\mathbf{x}) = \exp(\xi_0 + \sum_j \xi_j x_j),
```

estimated via $`\log|\hat w| = \xi_0 + \sum_j \xi_j x_j + \log\eta`$.
Coefficients are now **variance semi-elasticities** (a 1-unit rise in
input $`j`$ changes log output variance by $`\xi_j`$). This form appears
in Saha, Havenner & Talpaz (1997) and the Norwegian salmon applications
of Tveterås (1999, 2000). The default stays `risk_form = "cobb_douglas"`
to match Koundouri & Nauges (2005).

``` r

fit_exp <- jp_fit(..., risk_form = "exponential")
```

Translog and other forms with **multiplicative** interaction between the
mean and variance functions are deliberately not supported, because they
break the additive identification structure that Just-Pope requires
(Koundouri & Nauges, 2005, footnote 5). Passing `mean_form = "translog"`
or `risk_form = "translog"` raises an informative error.

## Comparing specifications side by side

Functional form is a research-design choice, not a property of the data.
To see how sensitive the conclusion is, use
[`jp_compare()`](https://robcareta.github.io/JPselect/reference/jp_compare.md):

``` r

cmp <- jp_compare(
  data = farms, selection_var = "vegetables", ...,
  mean_forms = c("linear_quadratic", "quadratic", "cobb_douglas"),
  risk_forms = c("cobb_douglas", "exponential")
)
cmp$summary        # adjusted R^2, IMR p-value, selection-bias flag per combo
cmp$coefficients   # long-format risk-function coefs with stars per combo
```

The summary table makes it easy to see whether selection bias is
detected under each specification and whether the risk-function
conclusions agree across forms.

## Why the with-vs-without comparison matters

If selectivity bias is present ($`\sigma_l \neq 0`$ in Step 2), the
Step-3 risk-function coefficients estimated **without** the Mill’s ratio
are biased. Koundouri & Nauges’ main finding is that ignoring
selectivity can flip the sign or kill the significance of risk-function
coefficients, exactly the gap that `print(fit)` and `plot(fit)` make
visible side by side. The Mill’s ratio coefficient $`\sigma_l`$ in Step
2 is itself a direct test for selection bias: if it’s significant, the
corrected column is the one you should report.

## Standard errors

Step 3 SEs come from a 500-replication nonparametric bootstrap that
resamples the **full pipeline** (probit, IMR, mean function, residuals,
risk function) on every replication, so upstream parameter uncertainty
propagates correctly. Set `bootstrap_reps` lower for quicker runs.

## References

- Heckman, J. (1979). Sample selection bias as a specification error.
  *Econometrica*, 47, 153-161.
- Just, R. E. and Pope, R. D. (1978). Stochastic representation of
  production functions and econometric implications. *Journal of
  Econometrics*, 7, 67-86.
- Koundouri, P. and Nauges, C. (2005). On Production Function Estimation
  with Selectivity and Risk Considerations. *Journal of Agricultural and
  Resource Economics*, 30(3), 597-608.
- Saha, A., Havenner, A. and Talpaz, H. (1997). Stochastic production
  function estimation: small sample properties of ML versus FGLS.
  *Applied Economics*, 29(4), 459-469.
- Shankar, B. and Nelson, C. H. (1999). Joint risk preference-technology
  estimation with a primal system: comment. *American Journal of
  Agricultural Economics*, 81(1), 241-244.
- Tveterås, R. (1999). Production risk and productivity growth: some
  findings for Norwegian salmon aquaculture. *Journal of Productivity
  Analysis*, 12(2), 161-179.
- Tveterås, R. (2000). Flexible panel data models for risky production
  technologies with an application to salmon aquaculture. *Econometric
  Reviews*, 19(3), 367-389.
