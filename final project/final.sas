******************************************
* P6110: Statistical Computing with SAS  *
* Spring 2019                            *
* Chu Yu      Final Project              *
******************************************;
ods rtf file = "/folders/myshortcuts/Myfolder/final project/final.rtf"
    bodytitle startpage = yes;
ods noproctitle;
/*import the data*/
proc import out=hd1
	datafile="/folders/myshortcuts/Myfolder/final project/HD.xlsx"
	dbms=xlsx replace;
	sheet="US1";
run;

proc import out=hd2
	datafile="/folders/myshortcuts/Myfolder/final project/HD.xlsx"
	dbms=xlsx replace;
	sheet="US2";
run;

proc import out=hd3
	datafile="/folders/myshortcuts/Myfolder/final project/HD.xlsx"
	dbms=xlsx replace;
	sheet="EU1";
run;

proc import out=hd4
	datafile="/folders/myshortcuts/Myfolder/final project/HD.xlsx"
	dbms=xlsx replace;
	sheet="EU2";
run;

*The bonus part;
proc sql; 
   create table hd as 
   select * from hd1  
   union all 
   select * from hd2  
   union all 
   select * from hd3  
   union all 
   select * from hd4  
   ; 
quit;

*stack the four tables and add hopital variable and id for convenience;


*labelling and formating;
/*data hd;
    set hd;
    label trestbps = "Resting blood pressure"
          chol = "Serum cholestoral(mg/dl)"
          thalach = "Maximum heart rate achieved"
          oldpeak = "ST depression"
          cp = "Chest pain type" 
          fbs = "Fasting blood sugar"
          restecg = "Resting electrocardiographic results"
          exang = "Exercise induced angina" 
          slope = "Slope of the peak exercise ST segment"
          ca = "Number of major vessels (0-3) colored by flourosopy";
run;*/

proc format;
    value sex      1 = "Male"
                   0 = "Female";
    value      cp       1 = "Typical angina"
                   2 = "Atypical angina"
                   3 = "Non-anginal pain"
                   4 = "Asymptomatic";
    value      fbs      1 = "True"
                   0 = "False";
    value     restecg  0 = "Normal"
                   1 = "Having ST-T wave abnormality"
                   2= "Showing probable or definite";
    value       exang   1 = "yes"
                   0 = "no";
    value       slope   1 = "upsloping"
                   2 = "flat"
                   3 = "downsloping";
     value      thal    3 = "normal"
                   6 = "fixed defect"
                   7 = "reversable defect";
     value      diag    0 = "No presense of heart disease"
                   1 = "one of major vessels"
                   2 = "two of major vessels"
                   3 = "three of major vessels"
                   4 = "four of major vessels";
run; 

*for bonus;
proc sql;
  create table hdnew as
  select age,
         thal format = thal.,
         sex format = sex.,
         trestbps label = "Resting blood pressure",
         chol label = "Serum cholestoral(mg/dl)",
         thalach label = "Maximum heart rate achieved",
         oldpeak label = "ST depression",
         cp format = cp. label = "Chest pain type" ,
         fbs format = fbs. label= "Fasting blood sugar",
         restecg  format = restecg. label= "Resting electrocardiographic results",
         exang format = exang. label = "Exercise induced angina" ,
         slope format = slope. label = "Slope of the peak exercise ST segment",
         ca label= "Number of major vessels (0-3) colored by flourosopy",
         diag format = diag.
   from hd;
quit;
         
proc print data = hdnew(obs = 5) label;run; 
*use format and label via sql to make the table clearer;




*Handling missing values;
*we can know that age,trestbps, chol, thalach should not equal 0;
data hdnew;
  set hdnew;
  if age=0 then age = .;
  if trestbps = 0 then trestbps = .;
  if chol = 0 then chol = .;
  if thalach = 0 then thalach = .;
run;

proc sort data=hdnew out=hd_sort; 
	by diag;
run;

proc means data = hd_sort N nmiss median;
    var age trestbps chol thalach;
run;

*By checking the missing values, we can find that most missing values are in chol variable in EU hospitals.;
*but the number if missing values is smaller than 20%, deleting the variable chol may cause problem. 
And by literature review, high cholestoral can contribute to arteries narrowed, further introducing heart disease and high blood pressure.
To solve the missing values in chol var, we may replace the zero with median of chol to decrease the error;

/*data hdnew;
   set hdnew;
   if chol = . then chol = 239.5;
   if trestbps = . then trestbps = 130;
run;*/

*chol;
* Histogram + Density curve;
proc sgplot data=hdnew;
	histogram chol / binwidth=10 transparency=0.8 showbins scale=count;
	xaxis label="Diastolic blood pressure";
	density chol;
	density chol / type=kernel; *it is the continual plot of the data;
run;
*we replace the missing value with median of chol to prevent loss of information, which increased the noise of data, and the plot show that the distribution of chol may be different from the kernel;
*Maybe for further improvement we can use imputation or also built a model between chol and other var to predict the value in the future;
*But this time we just delete the zero parts;
data hdnew;
   set hdnew;
   if chol = . then delete;
   if trestbps = . then trestbps = 130;
run;




/*descriptive data*/

*categorical var;
*sex and diag;
proc sgplot data=hdnew;
	vbar diag; 
	xaxis label="diagnosis";
run;
*From the bar chart, the frequency of 5 levels of diagnosis is like:
No heart disease > One major vessel narrowing > two major vessel narrowing > three major vessel narrowing > four major vessel narrowing;

%macro table(datain, var1);
proc freq data = &datain;
  tables &var1*diag;
run;

%mend table;

%table(hdnew, sex);
*From the table, male patients have a higher percentage of heart disease than females;

%table(hdnew, thal);
*For patients diagnosed as heart disease, they apparently have more reversable defect than people without major vessels narrowing, only a small proportion
of patients with heart disease have normal "thal";

%table(hdnew, exang);
*For most of the patients without heart disease, they don't have exercise induced angina, and the patients with heart disease is the opposite;

%table(hdnew, slope);
*For people without heart disease, most of them have upsloping slope of the peak exercise ST segment;
*While patients with heart disease are more likely to have flat slope of the peak exercise ST segment. Downsloping slope is the least in both two cases;

*chest pain type;
proc freq data = hdnew;
  tables sex*cp*diag;
run;
*From the table, we can see that Asymptomatic pain type is the most in patients with heart disease, 
while healthy people are more likely to have atypical angina chest pain;
*And males have a larger percentage of heart disease than females;

*thal;
proc freq data = hdnew;
  tables exang*thal*diag;
run;
 *from the frequency table we can see that most of the people has exercise induced angina;
 *Holding exang still, frequency:fixed defect < normal < reversable defect;
 
 
 
*continous var;
data hdb;
	set hdnew;
	if diag = 0 then pres = 0;
	else pres = 1;
run;

proc sort data=hdb out=hdb_sort; 
	by diag;
run;

proc means data = hd_sort n mean median max min nmiss maxdec = 2;
  by diag;
  var age trestbps chol thalach oldpeak ca;
run;

proc means data = hdb_sort n mean median max min nmiss maxdec = 2;
  by pres;
  var age trestbps chol thalach oldpeak ca;
run;
*the five variables age, trestpts, oldpeak, chol ca all tend to increase by increasing of number of major vessel narrowing, 
the five categories of age don't have specific skewness,
but resting blood pressure is right skewed in different diagnosis, after deleting the zero values of some variables, there are no missing value found;

*age;
proc sgplot data=hdnew;
	vbox age / category=diag group = diag; 
	xaxis label="age";
run;
*the finding shows that for mean age:
No heart disease < One major vessel narrowing < two major vessel narrowing < four major vessel narrowing < three major vessel narrowing 
we can infer that to some extent mean age has some relationship with number of major vessels narrowing, but the more severe situation may result from some other factors more;

proc sgplot data=hdnew;
	histogram age / binwidth=10 transparency=0.6 showbins scale=percent;
	xaxis label="age"; 
run;
*From the histogram we can see that most of the patients are aged between 45 and 75;

*oldpeak;
proc sgplot data=hdnew;
	vbox oldpeak / category=diag group = diag; 
	xaxis label="ST depression induced by exercise relative to rest";
run;
*from the boxplot we can see the positive relationship between oldpeak and diagnosis, and the 2 response has the largest range;

*pearson coefficient;
proc corr data = hdnew plots = scatter;
   var oldpeak trestbps;
run;
*The two variables have a correlation of 0.2151, and the p-value < .0001, which means that we reject the null and conclude that their correlation is significantly different from zero;


proc corr data=hdnew 
  plots(maxpoints=100000000)=matrix(nvar=7);  
  var age trestbps chol thalach oldpeak ; run; 
*we can see from the correlation plot that age and thalach, age and trestbps, age and oldpeak, trestbps and oldpeak, thalach and oldpeak are significantly correlated with p-value < .0001 ;
*the result can also provide us some idea about interaction terms;





*Hypothesis testing;
*i. Is the restecg independent of sex? ;
*Test of Independence ;
* H0: Variable restecg is not associated with Variable sex.  H1: associated;
/*Check assumption:
a) No more than 1/5 of the cells have expected values <5.
b) No cell has expected value <1.
*/
proc freq data=hdnew;
	tables restecg * sex / chisq exact; 
run;
*The Chi square = 0.4238 > 0.05, so we fail to reject the null hypothesis and conclude that the two variables are not associated;

*ii. Is the mean trestbps different depending on fbs?;
*1) Clarify the null and alternative hypotheses.  H0: mu1 = mu2, H1: not null;
*2) Determine an appropriate statistical test: independent two sample t test;
*3) Check the assumptions;
* Checking normality;
proc univariate data=hdnew normal;
	class fbs;
	var trestbps;
	qqplot trestbps;
	histogram trestbps / normal;
run;

*the normality cannot stand, but sample size is big enough, so we tried two methods;

* Independent two-sample t-test;
proc ttest data=hdnew plots=(ALL);
	class fbs;
	var trestbps;
run;
*p-value = .0001, so we reject the null and conclude that the two varibles are associated;

* Independent two-sample t-test: Wilcoxon rank sum test;
proc npar1way data=hdnew wilcoxon;
	class fbs;
	var trestbps;
run;
*p-value < .0001, so we reject the null and conclude that the two varibles are associated;

*iii. Is the Pearson’s correlation coefficient of chol and  trestbps equal to 0?;
* H0: Rho=0 vs H1: Rho not equal to 0;
proc corr data=hdnew plots=matrix;
	var chol trestbps;
run;

* Estimated rho = 0.08772
* P-value = 0.0165 <0.05 -> Reject H0, conclude that rho is not 0;





/*model fitting -- a*/
*Ordinal model;

*model selection;
*We add some possible interaction terms;

proc logistic data=hdnew;
	class sex(ref = "Female") cp(ref = "Typical angina") fbs(ref = "False") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model diag (descending)= age trestbps chol thalach oldpeak thal sex cp fbs restecg exang slope ca trestbps|fbs thal|cp thalach|trestbps restecg|slope age|thalach age|restecg 
           / lackfit  selection = stepwise; 
run;

*cp, thal, ca, exang, sex, age and slope are left in the model;
*so there is no interaction term left in model;

*final model;
proc logistic data=hdnew;
	class sex(ref = "Female") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model diag (descending)= cp thal ca exang sex age slope chol
           / lackfit  iplots; 
run;
*The ordinal model did not pass the score test, with p-value < .0001;
*so the assumption did not stand;
*First, check the assumption: 1. score test have p-value < .0001, the test of the proportional odds assumption here is significant, indicating that proportional odds does not hold 
and suggesting that separate parameters are needed across the logits for at least one predictor;
*2. patients are independent,  3. the sample size is large enough for ordinal model 4. model convergency satisfied;
*and the Hosmer and Lemeshow Goodness-of-Fit Test gets p-value < .05, meaning we reject the null and conclude that the model is not a good fit;



*try multinomial model;

proc logistic data=hdnew;
	class diag (ref = "No presense of heart disease") sex(ref = "Female") cp(ref = "Typical angina") fbs(ref = "False") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model diag = age trestbps chol thalach oldpeak thal sex cp fbs restecg exang slope ca trestbps|fbs thal|cp thalach|trestbps restecg|slope age|thalach age|restecg 
           / lackfit  link=glogit selection = stepwise; 
run;

*cp, thal, ca, exang, sex, oldpeak trestbps thalach are left in the model;
*so there is no interaction term left in model;

*final model;
proc logistic data=hdnew;
	class diag (ref = "No presense of heart disease") sex(ref = "Female") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model diag = cp thal ca exang sex thalach oldpeak trestbps
           / lackfit  iplots link = glogit; 
run;

*model convergence satisfied here;
*according to Hosmer and Lemeshow Goodness-of-Fit Test, p-value = 0.8599, we fail to reject the null and conclude that the model is a good fit;
*AIC = 1374.463 for intercept and all covariates ;



/*b) Dichotomize the ordinal variable */

proc logistic data=hdb;
	class pres (ref = FIRST) sex(ref = "Female") cp(ref = "Typical angina") fbs(ref = "False") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model  pres = age trestbps chol thalach oldpeak thal sex cp fbs restecg exang slope ca chol|trestbps trestbps|fbs thal|cp thalach|trestbps restecg|slope age|trestbps age|chol 
           /  lackfit outroc = roc selection = stepwise; 
run; quit;
*cp ca thal exang sex oldpeak slope age are left;

*take interaction into consideration, no interaction terms left;

*final model;
proc logistic data=hdb;
	class pres (ref = FIRST) sex(ref = "Female") cp(ref = "Typical angina") fbs(ref = "False") restecg(ref = "Normal") exang(ref= "no") slope(ref = "upsloping") thal(ref = "normal") /param=ref;
	model  pres = cp ca thal exang sex oldpeak slope age /lackfit iplots; 
run; quit;
*convergence test satisfied;
*AIC = 505.824 < AIC(model a);
*The numbers of covariates of multinomial model and model b are the same;

*so the second model is better;

*Goodness of fit:
H0: the final model is a good fit vs H1: the final model is not a good fit
Hosmer and Lemeshow Goodness-of-Fit Test: p-value = 0.2625, fail to reject the null so we conclude that the model is a good fit.


hat(Intercept) = -5.8769	 with p-value < 0.0001(Significant)
The odds of being diagnosed as heart disease increases by exp(-5.8769) = 0.0028 times with zero cp ca thal exang sex oldpeak slope age;

* hat(cp-Asymptomatic) = 1.2532  with p-value =0.0046 < 0.05 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(1.2532) = 3.5015 times between Asymptomatic chest pain and typical angina adjusted for ca thal exang sex oldpeak slope age;

* hat(cp-Atypical angina) = -0.4193  with p-value =0.4043 > 0.05 (insignificant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(-0.4193) = 0.6575 times between atypical angina chest pain and typical angina adjusted for ca thal exang sex oldpeak slope age;

* hat(cp-Non-anginal pain) = -0.1448  with p-value =0.7556 > 0.05 (insignificant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(-0.1448) = 0.8652 times between Non-anginal pain and typical angina adjusted for ca thal exang sex oldpeak slope age;

* hat(ca) = 0.8716  with p-value  < 0.0001 (Significant);
* -> For one unit increase in Number of major vessels colored by flourosopy, the odds of being diagnosed as heart disease  increases 
  by exp(0.8716) = 2.3907 times adjusted for cp thal exang sex oldpeak slope age;

* hat(thal-fixed defect) = 1.0555  with p-value =0.0105 < 0.05 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(1.0555) = 2.8734 times between fixed defect and normal adjusted for ca cp exang sex oldpeak slope age;

* hat(thal-reversable defect) = 1.8537  with p-value < .0001 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(1.8537) = 6.3834 times between reversable defect and normal adjusted for ca cp exang sex oldpeak slope age;

* hat(exang) = 1.0084  with p-value = .0001 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(1.0084) = 2.7412 times between with and without exercise induced angina adjusted for ca cp thal sex oldpeak slope age;

* hat(sex) =1.1197 with p-value = .0002 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(1.1197) = 3.0639 times between male and female adjusted for ca cp exang thal oldpeak slope age;

* hat(oldpeak) = 0.5489  with p-value  < 0.0001 (Significant);
* -> For one unit increase in ST depression induced by exercise relative to rest, the odds of being diagnosed as heart disease increases 
  by exp(0.5489) = 1.7313 times adjusted for cp thal exang sex ca slope age;

* hat(slope - downsloping) =0.5951 with p-value = .1880 > .05 (insignificant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(0.5951) = 1.8132 times between downsloping and upslowing of the peak exercise ST segment adjusted for ca cp exang thal oldpeak sex age;

* hat(slope - flat) =0.7757 with p-value = .0028 < .05 (Significant);
* -> The odds of being diagnosed as heart disease increases 
  by exp(0.7757) = 2.1721 times between flat and upslowing of the peak exercise ST segment adjusted for ca cp exang thal oldpeak sex age;

* hat(age) = 0.0320	  with p-value  =0.01 (Significant);
* -> For one unit increase in age, the odds of being diagnosed as heart disease increases 
  by exp(0.0320	) = 1.0325 times adjusted for cp thal exang sex ca slope oldpeak;

ods rtf close;