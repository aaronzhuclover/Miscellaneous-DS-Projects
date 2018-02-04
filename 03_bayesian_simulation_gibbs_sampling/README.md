
<li>
<strong>“03_bayesian_simulation_gibbs_sampling"</strong> demonstrate how I used FGLS to solve solve heteroskedasticity issue and successfully draw 10,000 posterior parameters using algorithms, including EM algorithm, MCMC and Gibbs sampling
</li>
<br>

Key variables in clients’ data sets: 
-	Transaction price: dependent variable in linear regression model 
-	Date of transaction: monthly effect
-	Location of transaction: location effect
-	Customer type: retailer, whole seller,  contractor 
-	Product type: 1/2, 1/4, 3/8 inch 
-	Suppliers

Key explanatory variables (supply, demand, economic variables, these are third party data):
-	Raw gypsum price
-	Recyclable old corrugated containers
-	Electricity price
-	Natural gas price
-	Average hourly earnings in manufacturing 
-	Diesel fuel price
-	Housing units started
-	Existing home sales
-	Total construction spending 
-	US treasury bond interest rate
-	x1, x2, … , x10

Conspiracy indicator (c):
-	A dummy variable, which equals to 1 when transaction date is in conspiracy period 
-	Conspiracy period was pre-defined by attorney’s investigation 

Basic regression model:
-	 Pi =   β0 + β1x1 + β2x2 + … + β10x10 + β11 c  + ε  , ε ~ N(0, σ²)
-	Predicted competitive price = β0 + β1x1 + β2x2 + … + β10x10

Added systematic variation (interaction terms) for explanation variables 
-	[Xi] * [monthly dummies] 
-	[Xi] * [regional dummies] 
-	[Xi] * [customer type] 
-	[Xi] * [supplier] 
-	[Xi] * [product thickness] 

Found optimal interaction terms for each explanation variable using model selection methods with AIC/AICc
-	Theoretically, we need to search 5^10 = 9,765,625 combinations
-	Used iterative feature selection methods with 10-fold cross validation to find early stopping point, aiming to reducing running time of searching for the optimal model 

Applied FGLS in Presence of Heteroscedasticity
-	Heteroscedasticity is a problem because variance of residuals are not constant, which violates OLS regression’s homoscedasticity assumption. Heteroscedasticity could be observed in residuals vs fitted value plot.
-	In the presence of heteroscedasticity, OLS estimators are still unbiased, but it is no longer BLUE (best linear unbiased estimator). The variances of the OLS estimators are biased in this case. Thus, the usual OLS t statistic and confidence intervals are no longer valid for inference problem. This problem can lead you to conclude that a model term is statistically significant when it is actually not significant.
-	One remedy to heteroscedasticity is to use robust covariance matrix. Use of robust covariance matrix leaves the coefficient estimates intact but expands confidence intervals to account for the violated assumption of i.i.d. errors.

(See Theorem 10.1 in Greene (2003)) <br>
var(B̂) = var[B + (x'x)⁻¹x'e]  
       = var[(x'x)⁻¹x'e] 
       = (x'x)⁻¹x' cov(e) x (x'x)⁻¹ 
       = σ²(x'x)⁻¹x' Ω x (x'x)⁻¹
	   
-	Another remedy is to use Feasible GLS. We used covariance of residuals in OLS stage to estimate the error covariance structure and use residual standard deviation to reweight our data. Since we imposed model for σi², we should have smaller variance than OLS's (var(FGLS)<var(OLS)<var(Heteroskedasticity-Robust Estimators))

  <img src="https://github.com/aaronzhuclover/master/blob/master/03_bayesian_simulation_gibbs_sampling/bias_variance.PNG" height="400"/>
  <br>
Then we have <br>
var(εi/σi) = σi²/ σi² = 1 = var(εj/σj), where var(εi) ≠ var(εj) <br>
now we successful solve heteroscedasticity and turn regression into homoscedastic model. 

Posterior draws using Gibbs Sampling technique:  <br>
Under Bayesian framework, we have <br>
-	Mean(β) = B̂ = (x'x)⁻¹ x' y
-	Var(β) = ∑ = σ²(x'x)⁻¹
-	β ~ MVN (B̂, ∑)
-	σi² = ∑(pi - Xi B̂) ² / Ni
-	εi ~ Scale-inv  x ² (n, σi²)
-	cholesky decomposition: ∑ = L’L
-	simulated beta = B̂ + LZ, Z ~ MVN (0, 1)

Applied EM algorithm to find 10 starting points. Applied Gibbs sampling in heteroskedastic model. Gibbs sampler: sequentially drawing from each of the full conditional posteriors eg p(θ1 | θ2, y) and p(θ2 | θ1, y). MCMC was used to simulate a Markov Chain that converges to the posterior distribution. Used gibbs sampling iteratively to draw betas.



