# This Github repository contains programs relevant to my resume.

<li>
<strong>“01_data_wrangling_ggplot2”</strong> demonstrates how I extracted and manipulated multiple data sources and transformed un-structured data into structured data in R with dplyr package and visualize data using ggplot2
</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/source_readme/data.PNG" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/source_readme/Company_pro_cap.PNG" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/out/drug_int_mbs_byMfr.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/out/drug_shr_byVol.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/out/drug_size_byDol.jpeg" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/01_data_wrangling_ggplot2/out/drug_size_byVol.jpeg" height="450"/>
<br>


<li>
<strong>“02_feature_selection_mc_simulation”</strong> demonstrates how I implemented feature engineering, such as, forward selection method to select optimal linear regression models and used Monte Carlo simulation to cross validate a set of classifiers to get robust predictions
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
<br>
<br>
Posterior draws using Gibbs Sampling technique:  <br>
(See Chapter 12 of Bayesian Data Analysis by Andrew Gelman (2014)) <br>

Under Bayesian framework, we have 
-	Mean(β) = B̂ = (x'x)⁻¹ x' y
-	Var(β) = ∑ = σ²(x'x)⁻¹
-	β ~ MVN (B̂, ∑)
-	s² = ∑(pi - Xi B̂)² / N
-	σ² ~ Scale-inv x² (n, s²)
-	cholesky decomposition: ∑ = L’L
-	simulated beta = B̂ + LZ, Z ~ MVN (0, 1)

Applied EM algorithm to find 10 starting points. Applied Gibbs sampling in heteroskedastic model. Gibbs sampler: sequentially drawing from each of the full conditional posteriors eg p(θ1 | θ2, y) and p(θ2 | θ1, y). MCMC was used to simulate a Markov Chain that converges to the posterior distribution. Used gibbs sampling iteratively to draw betas.





<br>
<li>
<strong>“04_data_scraping_redfin"</strong> demonstrates how I automate data scrapping from REDFIN and other websites in rvest and visualize home price changes using ggplot2
</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/04_data_scraping_redfin/out/sf_home_price.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/04_data_scraping_redfin/out/sf_home_price_change.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/04_data_scraping_redfin/out/condo_home_price.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/04_data_scraping_redfin/out/condo_home_price_change.png" height="450"/>
<br>


<li>
<strong>“05_recommendation_system_music"</strong> demonstrates how I used machine learning algorithm, <strong>collaborative filtering</strong> to make music recommendation to users.
<ul>
       <li>visualized a network of relationships among 285 artists based on users’ behavior and customized recommendation lists to users using item based <strong>collaborative filtering</strong> and user based recommendation methods. I also implemented parallel computing to increase recommendation efficiency by 90%</li>
       <li>Created a matrix of artists’ similarity using centered cosine similarity</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/05_recommendation_system_music/out/cosine.PNG" height="100"/>
	   <li>Accuracy of recommendation will be improved by including features of artists into similarity calculation and users’ preference will help with user based recommendation methods</li>
	</ul>   

</li>

<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/05_recommendation_system_music/out/wordcloud.png" height="450"/>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/05_recommendation_system_music/out/network.png" height="450"/>
<br>



<li><strong>“06_titanic_machine_Learning"</strong> demonstrates how I used machine learning algorithms, including decision tree, random forest, AdaBoost and Logistic regression to predict survival on Titanic data
    <ul> 
       <li>Predict survival using decision tree</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/decision_tree_readme.PNG" height="450"/>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/overfit.PNG" height="400"/>
	   <li>Confusion Matrix using decision tree</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_decision_tree.PNG" height="200"/>
	   <li>Confusion Matrix using decision tree with feature engineering</li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_decision_tree_feature_engineering.PNG" height="200"/>
	   <li>Improved prediction using <strong>Random Forest</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_random_forestPNG.PNG" height="200"/>
	   <li>Improved prediction using <strong>AdaBoost</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_adaboost.PNG" height="200"/>
	   <li>Improved prediction using <strong>Logistic regression</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_logistic_regression.PNG" height="200"/>
	   <li>Improve prediction by stacking three methods using <strong>ensemble method</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/06_titanic_machine_Learning/out/fit_ensemble.PNG" height="100"/>   
    </ul>
</li>	


<li><strong>“07_twitter_sentiment_analysis"</strong> demonstrates how I used machine learning algorithms, including Logistic regression, Naive Bayes and SVM to predict sentiments (negative and positive) of twitter messages
    <ul> 
	   <li>Confusion Matrix using <strong>Logistic regression</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/07_twitter_sentiment_analysis/out/pred_logistic.PNG" height="100"/>
	   <li>Confusion Matrix using <strong>Naive Bayes</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/07_twitter_sentiment_analysis/out/pred_naive_bayes.PNG" height="100"/> 
	   <li>Confusion Matrix using <strong>SVM</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/07_twitter_sentiment_analysis/out/pred_svm.PNG" height="100"/>
       <li>Confusion Matrix using <strong>Ensemble Method</strong></li>
	   <img src="https://github.com/aaronzhuclover/master/blob/master/07_twitter_sentiment_analysis/out/pred_ensemble.PNG" height="100"/>
    </ul>
</li>



<div class='tableauPlaceholder' id='viz1519879411396' style='position: relative'><noscript><a href='#'><img alt='profit dashboard ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;52&#47;52G4JBFHG&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='path' value='shared&#47;52G4JBFHG' /> <param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;52&#47;52G4JBFHG&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /></object></div>                <script type='text/javascript'>                    var divElement = document.getElementById('viz1519879411396');                    var vizElement = divElement.getElementsByTagName('object')[0];                    vizElement.style.width='1366px';vizElement.style.height='795px';                    var scriptElement = document.createElement('script');                    scriptElement.src = 'https://public.tableau.com/javascripts/api/viz_v1.js';                    vizElement.parentNode.insertBefore(scriptElement, vizElement);                </script>






