*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Homework 8                            *
* Zixu Wang (ZW2541)                    *
*****************************************;

/* Shock Data */

ods rtf file = "/folders/myfolders/p6110_hw8/p6110_hw8_zw2541.rtf"
		bodytitle startpage=yes;
ods noproctitle;

/* a) Import the dataset, name it 'Shock', and apply labels and formats in DATA step. */

proc import out=Shock 
    datafile="/folders/myfolders/p6110_hw8/Shock.xlsx"
	dbms=xlsx replace;
	getnames=yes;
run; 

data Shock;
    set Shock;
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
	value gender 1 = "Male"
	             2 = "Female";
	value survive 1 = "Survived" 
	              3 = "Died";
	value shocktype 2 = "Non-shock"
	                3 = "Hypovolemic" 
	                4 = "Cardiogenic"
                    5 = "Bacterial" 
                    6 = "Neurogenic" 
                    7 = "Other";
run;

data Shock;
    set Shock;
    format Sex gender. SURVIVE survive. TYPE shocktype.;
run;

proc print data=Shock (obs=5) label; run;


/* b) Descriptive statistics */

* i. Frequency table and bar chart of shock type;

proc freq data=Shock;
    table TYPE;
run;

proc sgplot data=Shock;
    vbar TYPE;
run;

* ii. Cross-tabular frequency table of sex and shock type;
proc freq data=Shock;
    table Sex * TYPE;
run;

* iii. Scatterplot and Pearson’s correlation coefficient of systolic pressure and body surface index;

proc corr data=Shock plots=scatter(ellipse=NONE); 	
	var SBP BSI;
run;

* iv. Distribution of systolic pressure;
* 1) Descriptive statistics (n, mean, median, standard deviation, min, max) of systolic pressure for each category of shock type. Use two decimal points.;

proc means data=Shock n mean median std min max maxdec=2;
	class TYPE;
	var SBP;
run;

* 2) Boxplots of systolic pressure for each category of shock type;

proc sgplot data=Shock;
	vbox SBP / group=TYPE;
run;

/* c) Hypothesis testing */

* i. Is the shock type independent of gender?;

* Chi-squared test;
proc freq data=Shock;
	table TYPE * Sex / expected chisq exact;
run;

* ii. Is the Pearson’s correlation coefficient of systolic pressure and body surface index equal to 0?;

proc corr data=Shock;
	var SBP BSI;
run;

* iii. Is the mean systolic pressure different depending on shock type? If so, which shock type is significantly different compared to non-shock?;
* Check the normality;
proc univariate data=Shock normal;
	class TYPE;
	var SBP;
	histogram SBP;
	qqplot SBP;
run;

* ANOVA;
proc anova data=Shock;
	class TYPE;
	model SBP = TYPE;
	means TYPE / hovtest=bf dunnett("Non-shock");
run; quit;


/* d) Linear regression model */

* Model selection;
proc glmselect data=Shock;
	class Sex(ref="Male") SURVIVE(ref="Survived") TYPE(ref="Non-shock");
	model SBP = Age HT Sex SURVIVE TYPE MAP HR DBP MCVP BSI CI AT MCT UO PVI RCI HG HCT / selection=stepwise;
run; quit;

* check the linear correlation;
proc corr data=Shock plots=matrix;
	var SBP MAP DBP BSI;
run;

* Final model;
proc reg data=Shock;
	model SBP = MAP DBP BSI / spec; * SPEC: White test (Heteroscedasticity);
	output out=regout p=yhat r=resid;
run; quit;

* Residual: normality check;
proc univariate data=regout normal;
	var resid;
	histogram resid;
	qqplot resid;
run;

ods rtf close;











