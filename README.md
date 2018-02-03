# This Github repository contains programs relevant to my resume.

<li>
“01_data_wrangling_ggplot2” demonstrates how I transformed un-structured data into structured data in R with dplyr package and visualize data using ggplot2
</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/source_readme/data.PNG" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/source_readme/Company_pro_cap.PNG" height="450"/>
<br>


<li>
“02_ggplot2” demonstrates how I extracted and manipulated multiple data sources in R with dplyr package and how to visualize data using ggplot2
</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/02_ggplot2/out/drug_int_mbs_byMfr.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/02_ggplot2/out/drug_shr_byVol.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/02_ggplot2/out/drug_size_byDol.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/02_ggplot2/out/drug_size_byVol.jpeg" height="450"/>
<br>


<li>
“03_feature_selection_mc_simulation” demonstrates how I implemented feature engineering, such as, forward selection method to select optimal linear regression models and used Monte Carlo simulation to cross validate a set of classifiers to get robust predictions
      <ul> 
       <li>Implemented parallel computing to increase efficiency of forward selection using utilizing multiple CPU cores</li>
	   <li>Expanded explanatory variable by creating lagged terms, quadratic terms and seasonal effects</li>
       <li>Applied forward selection to select optimal set of explanatory variables for linear regression model</li>
       <li>Performed PCA to solve multicollinearity issue in explanatory variables and applied forward selection to select optimal set of PC variables for linear regression model</li>
       <li>Used Monte Carlo simulations to cross validate two different regression models and performed prediction with robust models</li>
      </ul>
</li>
<br>

<li>
“04_bayesian_simulation_gibbs_sampling" demonstrate how I used FGLS to solve solve heteroskedasticity issue and successfully draw 10,000 posterior parameters using algorithms, including EM algorithm, MCMC and Gibbs sampling
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



<br>
<li>
“05_data_scraping_redfin" demonstrates how I automate data scrapping from REDFIN and other websites in rvest and visualize home price changes using ggplot2
</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/06_data_scraping_redfin/out/sf_home_price.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/06_data_scraping_redfin/out/sf_home_price_change.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/06_data_scraping_redfin/out/condo_home_price.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/06_data_scraping_redfin/out/condo_home_price_change.png" height="450"/>
<br>


<li>
“06_recommendation_system_music" demonstrates how I visualized a network of relationships among 285 artists based on users’ behavior and customized recommendation lists to users using item based collaborative filtering and user based recommendation methods. I also implemented parallel computing to increase recommendation efficiency by 90%
    <ul> 
       <li>Created a matrix of artists’ similarity using centered cosine similarity</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/07_recommendation_system_music/out/cosine.PNG" height="100"/>
	   <li>Accuracy of recommendation will be improved by including features of artists into similarity calculation and users’ preference will help with user based recommendation methods</li>
	</ul>   

</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/07_recommendation_system_music/out/wordcloud.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/07_recommendation_system_music/out/network.png" height="450"/>
<br>



<li>“07_titanic_machine_Learning" demonstrates how I used machine learning algorithms to predict survival on Titanic data
    <ul> 
       <li>Predict survival using decision tree</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/decision_tree.png" height="450"/>
	   <li>Confusion Matrix using decision tree</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_decision_tree.PNG" height="200"/>
	   <li>Confusion Matrix using decision tree with feature engineering</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_decision_tree_feature_engineering.PNG" height="200"/>
	   <li>Improved prediction using Random Forest</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_random_forestPNG.PNG" height="200"/>
	   <li>Improved prediction using AdaBoost</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_adaboost.PNG" height="200"/>
	   <li>Improved prediction using Logistic regression</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_logistic_regression.PNG" height="200"/>
	   <li>Improve prediction by stacking three methods using ensemble method</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/08_titanic_machine_Learning/out/fit_ensemble.PNG" height="100"/>   
    </ul>
</li>	