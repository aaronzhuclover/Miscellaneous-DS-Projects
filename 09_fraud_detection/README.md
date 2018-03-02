<li>
<strong>“09_fraud_detection”</strong> demonstrates how created Dashboard using VBA and Tableau and predicted frauds in highly unbalanced data by training classifiers, including logistic regression, neural network and deep learning autoencoders   
</li>
<br>
  <img src="https://github.com/aaronzhuclover/master/blob/master/09_fraud_detection/fraud_dashboard.PNG" height="450"/>
<br>

<li> <strong>Overview of Deeping Learning Autoencoders</strong>
      <ul> 
       <li>Fraud data are usually mislabeled (pre-defined labels will be wrong for some of the transactions because they are using rule-based techniques) and highly unbalanced (fraud transactions are much less – 1%). Most of supervised learning techniques, such as logistic regression, random forest, SVM, are sensitive to unbalance in predictor class. They trend to predict 0% fraud rate, which is not useful to decision makers</li>
	   <li>[Method 1- solve unbalanceness] On the other hand, unsupervised learning techniques, such as, PCA and autocoders are able to remove noise and preserve the most important patterns in the data. They don’t require pre-defined labels or response variables. Using reduced representation of input data with supervised techniques</li>
       <li>[Method 2 – solve both mislabeling and unbalanceness] Deeping learning autoencoders apply backpropagation to lean identity function, where the output values are equal to the input. Since tiny portion of data are fraud, anomaly/ outliers are easier to be identified when computing errors between actual feature values and autoencoder representative (trained model are based data where most of observations are normal, therefore, error will be bigger for anomaly/outliers)</li>
      </ul>
</li>	  
	  
	  
	  
