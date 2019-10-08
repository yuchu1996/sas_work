
*********************************************
* P6110: Statistical Computing with SAS     *
* Spring 2019                               *
* In-Class Practice 8 (Due: April 11, 2019) *
* Jihui Lee (Columbia University)           *
*********************************************;

* a) Import labels and formats;
proc import out=shock
	datafile="C:\Users\Jihui\Desktop\P6110\Practice\Practice 8\Shock.xlsx"
	dbms=xlsx replace;
	sheet="SHOCK";
	label HT = "Height"
		  SBP = "Systolic pressure"
		  MAP = "Mean arterial pressure"
		  HR = "Heart rate"
		  DBP = "Diastolic pressure"
		  MCVP = "Mean central venous pressure"
		  BSI = "Body surface index"
		  CI = "Cardiac index"
		  AT = "Appearance time"
		  MCT = "Mean circulation time"
		  UO = "Urinary output"
		  PVI = "Plasma volume index"
		  RCI = "Red cell index"
		  HG = "Hemoglobin"
		  HCT = "Hematocrit";
run;

proc format;
	value sexfmt 1 = "Male"
				 2 = "Female";
	value survivefmt 1 = "Survived"
					 3 = "Died";
	value typefmt 2 = "Non-shock"
				  3 = "Hypovolemic" 
				  4 = "Cardiogenic"
				  5 = "Bacterial"
				  6 = "Neurogenic"
				  7 = "Other";
run;

data shock;
	set shock;
	format sex sexfmt. survive survivefmt. type typefmt.;
run;


proc print data=shock (obs=5) label; run;


* b) Descriptive statistics;

* b)-1. Frequency table and bar chart of shock type;
proc freq data=shock;
	table type;
run;

proc sgplot data=shock;
	vbar type;
run;


* b)-2. Cross-tabular frequency table of sex and shock type;
proc freq data=shock;
	table sex * type;
run;


* b)-3. Scatterplot and Pearson’s correlation coefficient 
* of systolic pressure and body surface index;
proc corr data=shock plots=matrix;
	var sbp bsi;
run;

proc sgplot data=shock;
	scatter x=sbp y=bsi;
run;


* b)-4. Distribution of systolic pressure;
* 1) Descriptive statistics (n, mean, median, standard deviation, min, max);
proc means data=shock n mean median std min max maxdec=2;
	class type;
	var sbp;
run;

* 2) Boxplots of systolic pressure for each level of shock type;
proc sgplot data=shock;
	vbox sbp / category=type;
run;


* c) Hypothesis testing;

* c)-1. Is shock type independent of gender?;
* H0: Independent vs H1: Associated;
* Chi-squared test;
proc freq data=shock;
	table sex * type / chisq fisher;
run;

* (Chi-squared) 0.4089 (Fisher) 0.4175;
* -> Fail to reject H0;


* c)-2. Is the Pearson’s correlation coefficient of 
* systolic pressure and body surface index equal to 0?;
* H0: Rho=0 vs H1: Rho not equal to 0;
proc corr data=shock plots=matrix;
	var sbp bsi;
run;

* Estimated rho = 0.23610 
* P-value = 0.0122 -> Reject H0;


* c)-3. Is the mean systolic pressure different depending on shock type? 
* If so, which shock type is significantly different compared to non-shock?;
* H0: mu_Non-shock = mu_Hypovolemic = mu_Cardiogenic 
		= mu_Bacterial = mu_Neurogenic = mu_Other vs H1: Not H0;
* -> ANOVA;

* Check normality;
proc univariate data=shock normal;
	class type;
	var sbp;
	histogram sbp;
	qqplot sbp;
run;

* Shapiro-Wilk p-value
* (Non-shock) 0.6554 (Hypovolemic) 0.8763 (Cardiogenic) 0.2913
* (Bacterial) 0.9799 (Neurogenic) 0.8445 (Other) 0.4809;
* -> Normality assumption is appropriate;
* Note: Relatively small sample size;


* ANOVA;
proc anova data=shock;
	class type;
	model sbp = type;
	means type / hovtest =bf dunnett("Non-shock");
run; quit;


* Equality of variances (BF test) p-value = 0.1083: Fail to reject H0;
* -> Assumption of equal variance is satisfied;

* ANOVA p-value <.0001: Reject H0;
* Depending on shock type, the mean systolic pressure is significantly different;
* i.e. There exists at least one pair of shock type with different mean systolic pressure;

* Multiple comparison (Dunnett with "Non-shock" as reference);
* -> Every type except "Other" compared to "Non-shock" is significantly different;



* d) Linear regression model;

* First check the linear correlation;

* Only the first 10 variables will be displayed in the matrix plot;
proc corr data=shock plots(maxpoints=100000000)=matrix(nvar=10);
	var SBP Age HT MAP HR DBP MCVP BSI CI AT;
run;

proc corr data=shock plots(maxpoints=100000000)=matrix(nvar=10);
	var SBP MCT UO PVI RCI HG HCT sex survive type;
run;

* NOTE (Correlation & Scatter plot)
* 1. MAP is a function of SBP (correlated by definition);
* 2. (HG and HCT) and (MAP and DBP) are highly correlated (Caution! Problem of Multicollinearity);

* Full model;
proc glm data=shock;
	class sex(ref="Female") survive(ref="Died") type(ref="Non-shock");
	model sbp = Age sex survive type HT HR DBP MCVP BSI CI AT MCT UO PVI RCI HG HCT / solution;
run; quit;

* FYI, check VIF of full model (without type -- categorical variable);
proc reg data=shock;
	model sbp = Age sex survive HT HR DBP MCVP BSI CI AT MCT UO PVI RCI HG HCT / vif;
run; quit;

* HG and HCT: VIF > 18 -> Delete 1;

* PROC GLMSELECT: Model selection;
proc glmselect data=shock;
	class sex(ref="Female") survive(ref="Died") type(ref="Non-shock");
	model sbp = Age sex survive type HT HR DBP MCVP BSI CI AT MCT UO PVI RCI HG;
run; quit;

* Final model;
proc glm data=shock;
	class type(ref="Non-shock");
	model sbp = type dbp hg / solution;
	output out=regout p=yhat r=resid;
run; quit;

* (Global) F-test:
H0: The fit of the intercept-only model and your model are equal.
H1: The fit of the intercept-only model is significantly worse compared to your model.
* F-test p-value <.0001 (Overall significance);

* R^2 = 0.762530 -> 76% variability of the data is explained by the model;

* hat(Intercept) = 65.93257795 with p-value <.0001;
* -> We would expect an average systolic pressure of 65.93 mm Hg
* when DBP = HG = 0 & non-shock (No practical meaning);

* hat(Bacterial) = -17.51650403 with p-value = 0.0005 (Significant);
* -> Systolic pressure is expected to be lower by 17.52 mm Hg on average
* when shock type is bacterial compared to non-shock adjusted for DBP and HG;

* hat(DBP) = 1.35438796 with p-value <.0001 (Significant);
* -> Systolic pressure is expected to increase by 1.35 mm Hg on average
* when there is a unit (1) increase in DBP adjusted for shock type and HG;

* hat(HG) = -2.51705536 with p-value = 0.0005 (Significant);
* -> Systolic pressure is expected to decrease by 2.52 mm Hg on average
* when there is a unit (1) increase in BSI adjusted for shock type and DBP;


* Residual: normality check;
proc univariate data=regout normal;
	var resid;
	histogram resid;
	qqplot resid;
run;

* (Shapiro-Wilk) 0.0064 (Kolmogorov-Smirnov) 0.0558;
* Histogram and qqplot do not look a bit skewed;

* Normality assumption is not satisfied;

/* Variable transformation */
data shock2;
	set shock;
	sbp2 = log(sbp);
run;

* Only the first 10 variables will be displayed in the matrix plot;
proc corr data=shock plots(maxpoints=100000000)=matrix(nvar=10);
	var SBP2 Age HT MAP HR DBP MCVP BSI CI AT;
run;

proc corr data=shock plots(maxpoints=100000000)=matrix(nvar=10);
	var SBP2 MCT UO PVI RCI HG HCT sex survive type;
run;


* PROC GLMSELECT: Model selection;
proc glmselect data=shock2;
	class sex(ref="Female") survive(ref="Died") type(ref="Non-shock");
	model sbp2 = Age sex survive type HT HR DBP MCVP BSI CI AT MCT UO PVI RCI HG;
run; quit;

* Final model;
proc reg data=shock2;
	model sbp2 = dbp ci / spec; * SPEC: White test (Heteroscedasticity);
	output out=regout2 p=yhat r=resid;
run; quit;


* Residual: normality check;
proc univariate data=regout2 normal;
	var resid;
	histogram resid;
	qqplot resid;
run;

* With respect to normality, this transformation works better;
* (Shapiro-Wilk) 0.0022 (Kolmogorov-Smirnov) >0.1500;
