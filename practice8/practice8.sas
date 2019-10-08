*************************************************************************
************************    Practice 8            ***********************
************************    Chu Yu  UNI: cy2522   ***********************
************************************************************************;

ods rtf file = "/folders/myshortcuts/Myfolder/practice8/practice8.rtf"
    bodytitle startpage = yes;
ods noproctitle;

*a) Import the dataset and name it ‘Shock’. ;
proc import out = Shock
	datafile =  "/folders/myshortcuts/Myfolder/practice8/Shock.xlsx"
	dbms=xlsx replace;
	getnames=yes;
run;

*labels and formats;
data shock_label;
    set Shock;
    label HT = "Height in cm "
          SBP = "Systolic pressure (mm Hg)"
          MAP = "Mean arterial pressure (mm Hg)"
          HR = "Heart rate (beats / min) "
          DBP = "Diastolic pressure (mm Hg)"
          MCVP = "Mean central venous pressure (cm H20)"
          BSI = "Body surface index (m2) "
          CI = "Cardiac index (liters / min m2)"
          AT = "Appearance time (sec) "
          MCT = "Mean circulation time (sec) "
          UO = "Urinary output (ml / hr) "
          PVI = "Plasma volume index (ml / kg) "
          RCI = "Red cell index (ml / kg) "
          HG = "Hemoglobin (gm / 100 ml) "
          HCT = "Hematocrit (percent)";
run;

*format;
proc format;
    value sex      1 = "Male"
                   2 = "Female";
    value survival   1 = "Survived"
                   3 = "Died";
    value type   2 = "Non-shocked"
                   3 = "Hypovolemi"
                   4 = "Cardiogenic"
                   5 = "Bacterial" 
                   6 = "Neurogenic" 
                   7 = "Other";
run; 

data shock;
   set shock_label;
   format  sex sex. SURVIVE survival. TYPE type.;
run;

proc print data = shock (obs = 5) label;run;

*b) Descriptive statistics;
*i. Frequency table and bar chart of shock type;
proc freq data = shock;
  tables type;
run;

proc sgplot data = shock;
   vbar type / datalabel groupdisplay = cluster;
   xaxis label = 'Shock Type';
run;

*ii. Cross-tabular frequency table of sex and shock type ;
proc freq data = shock;
  tables sex*type;
run;

*iii. Scatterplot and Pearson’s correlation coefficient of systolic pressure and body surface index;
* Scatterplot;
proc sgplot data=shock;
	scatter  x=SBP y=BSI;
	xaxis label="Systolic Pressure";
	yaxis label="Body surface index";
run;

*pearson coefficient;
proc corr data = shock plots = scatter;
   var SBP BSI;
run;

*iv. Distribution of systolic pressure ;
*1) Descriptive statistics;
proc means data = shock n mean median std min max maxdec=2;
   class type;
   var SBP;
run;

*2) Boxplots of systolic pressure for each category of shock type ;
proc sgplot data = shock;
   vbox SBP / category=type group = type;
   xaxis label = "Systolic Pressure";
run;

*c) Hypothesis testing;
*i. Is the shock type independent of gender? ;
*Test of Independence ;
* H0: Variable TYPE is not associated with Variable SEX.  H1: associated;
proc freq data=shock;
	table type * sex / chisq exact; 
run;
*The Chi square < 0.0001 means that the two variables are associated;

*ii. Is the Pearson’s correlation coefficient of systolic pressure and body surface index equal to 0?;
title 'Calculation and Test of Correlations, 95% CI';
ods output FisherPearsonCorr=corr;

proc corr data=shock fisher ( rho0 = 0 );
 var SBP BSI;
run; 
*since the p-value is 0.012 < 0.05, so we have sufficient evidence to conclude that the Pearson’s correlation coefficient of systolic pressure and body surface index not equal to 0;

*iii. Is the mean systolic pressure different depending on shock type?;
*1) Clarify the null and alternative hypotheses.  H0: mu1 = mu2 = mu3 = mu4 = mu5 = mu6, H1: not null;
*2) Determine an appropriate statistical test: one-way ANOVA;
*3) Check the assumptions;
proc univariate data=shock normal;
	class type;
	var SBP;
	qqplot SBP;
	histogram SBP / normal;
run;

*the normality can stand;
*test;
proc glm data = shock;
	class type;
	model SBP = TYPE;
	means type/ hovtest=bf;
run; quit;

*p< 0.0001, We reject the null and conclude that the systolic pressure differs by shock type;
*Hypovolemi is most different from Non-shock;

*d) Linear regression model;
* First check the linear correlation;
proc corr data=shock plots(maxpoints=100000000)=matrix(nvar=7);
	var Age -- HCT;
run;
*the plot has a maximum of 10 rows;

proc reg data=shock;
	model SBP = Age HT Sex SURVIVE TYPE MAP HR DBP MCVP BSI CI AT MCT UO PVI RCI HG HCT / vif;
run; quit;

* Model selection -- stepwise;
* PROC GLM: Model selection;
proc glmselect data=shock;
    class type;
	model SBP = Age HT Sex SURVIVE TYPE HR MAP MCVP BSI CI AT MCT UO PVI RCI HG / selection=stepwise;
run; quit;

* Final model;
proc reg data=shock;
	model SBP = MAP HG;
	output out=regout p=yhat r=resid;
run; quit;



ods rtf close;

