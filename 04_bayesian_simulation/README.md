<li>
“04_bayesian_simulation” and "05_gibbs_sampling" demonstrate how I used FGLS to solve solve heteroskedasticity issue and successfully draw 10,000 posterior parameters using algorithms, including EM algorithm, MCMC and Gibbs sampling
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

Add systematic variation (interaction terms) for explanation variables 
-	[Xi] * [monthly dummies] 
-	[Xi] * [regional dummies] 
-	[Xi] * [customer type] 
-	[Xi] * [supplier] 
-	[Xi] * [product thickness] 

Find optimal interaction terms for each explanation variable using model selection methods with AIC/AICc
-	Theoretically, we need to search 5^10 = 9,765,625 combinations
-	Used iterative feature selection methods with 10-fold cross validation to find early stopping point, aiming to reducing running time of searching for the optimal model 

Bayesian simulation on regression parameters 
-	Mean(β) =  B̂ = (x'x)⁻¹ x' y
-	Var(β) = ∑ = σ²(x'x)⁻¹
-	β ~ MVN (B̂, ∑)
-	ε ~ Scale-inv x ² (n, σ²)
-	cholesky decomposition: ∑ = L’L
-	simulated beta = B̂ + LZ,    Z ~ MVN (0, 1)

Apply Gibbs sampling in heteroskedastic model. Gibbs sampler: sequentially drawing from each of the full conditional posteriors eg p(θ1 | θ2, y) and p(θ2 | θ1, y). MCMC is used to simulate a Markov Chain that converges to the posterior distribution 
-	Applied EM algorithm to find 10 starting points
-	ε ~ N(0, σ²) is violated; σ² might NOT be constant 
-	Used FGLS to reweight the data to convert it into homoscedastic model
-	We don't know the joint distribution for σA² and σB², but we know σA² and σB² individually 
-	σA² = ∑(pA - XAB) ² / NA
-	σA² = ∑(pB - XBB) ² / NB
-	Used gibbs sampling iteratively to draw betas 


