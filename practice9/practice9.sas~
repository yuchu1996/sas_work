*************************************************************************
************************    Practice 9            ***********************
************************    Chu Yu  UNI: cy2522   ***********************
************************************************************************;

ods rtf file = "/folders/myshortcuts/Myfolder/practice9/practice99.rtf"
    bodytitle startpage = yes;
ods noproctitle;
*Coronary Heart Disease (CHD);
*a) Import the dataset, name it ‘CHD’, and apply labels (SBP, LDL, BAI, Famhist, BMI, and CHD) and
formats (CHD) in DATA step;

proc import out = CHD
	datafile =  "/folders/myshortcuts/Myfolder/practice9/chd.xlsx"
	dbms=xlsx replace;
	getnames=yes;
run;

*labels and formats;
data chd1;
    set chd;
    label SBP = "Systolic blood pressure"
          LDL = "Low density lipoprotein cholesterol"
          BAI = "Body adiposity index"
          Famhist = "Family history of heart disease (Present, Absent)"
          BMI = "Body Mass Index"
          CHD = "Coronary heart disease";
run;

*format;
proc format;
    value chd      1 = "Case"
                   0 = "Control";
run; 

data chdnew;
   set chd1;
   format  CHD chd.;
run;

proc print data = chdnew (obs = 5) label;run;

*b) Descriptive statistics:;
*i. Cross-tabular frequency family history (rows) and CHD status (columns);
proc freq data = CHD;
    tables famhist*CHD;
run;

*ii. Distribution of systolic pressure;
*1) Descriptive statistics;
proc means data = chdnew n mean median std min max maxdec = 2;
  class CHD;
  var SBP;
run;

*2) Boxplots of systolic pressure for each level of CHD status;
proc sgplot data = chdnew;
   vbox SBP/ category=CHD group = CHD;
   xaxis label= "Systolic blood pressure";
run;

*3) Scatterplot and Pearson’s correlation coefficient of systolic blood pressure and tobacco
consumption for each level of CHD status;
proc sgplot data=chdnew;
	scatter  x=SBP y=tobacco;
	reg x=SBP y=tobacco;
	xaxis label="Systolic Pressure";
	yaxis label="Number of cigarettes per day";
run;

*pearson coefficient;
proc corr data = chdnew plots = scatter;
   var SBP Tobacco;
run;

*iii. Histograms of body adiposity index for those with and without family history, separately;
proc sgpanel data=CHDNEW;
	panelby Famhist / novarname; *give you the name of the panel;
	histogram BAI/binwidth=10 transparency=0.8 scale=count;
	density BAI;
	DENSITY BAI / type=kernel;
run;

*c) Macro: Create a macro program named ‘table’ that takes two numeric variables as inputs and produces
a table with CHD status and family history;
%macro table(datain, var1, var2);

proc tabulate data= &datain format=comma9.2;
	class CHD famhist;
	var &var1 &var2;
	table (CHD =' ' ALL)*(Famhist=' ' ALL), 
		  (&var1 &var2)*(N mean*f=6.1 std*f=6.2);
   keylabel ALL = 'Total' N = 'Freq' mean = 'Mean' std = 'Std Dev';
run;
%mend table;

%table(chdnew, Alcohol, Tobacco);

*d) Hypothesis testing:;
*i. Is the CHD status independent of family history?;
*Test of Independence ;
* H0: Variable CHD is not associated with Variable Famhist.  H1: associated;
proc freq data=chdnew;
	table CHD * Famhist / chisq exact; 
run;
*The Chi square < 0.0001 means that the two variables are associated;

*ii. Is there a difference in mean type-A personality score depending on family history?;
*two-sample independent test, H0:mu1 = mu2 , H1: not null ;
* Checking normality;
proc univariate data=chdnew normal;
	class famhist;
	var TypeA;
	qqplot TypeA;
	histogram TypeA / normal;
run;

*since the p-value < 0.05, the normality does not stand;
*But we have 302 controls / 160 CHD cases, so we still try two methods -- two-sample t test and sign test;
* Independent two-sample t-test;
proc ttest data=chdnew plots=(ALL);
	class famhist;
	var TypeA;
run;

* Independent two-sample t-test: Wilcoxon rank sum test;
proc npar1way data=chdnew wilcoxon;
	class famhist;
	var TypeA;
run;

*iii. Is the Pearson’s correlation coefficient of alcohol and tobacco consumption equal to 0?;
* H0: Rho=0 vs H1: Rho not equal to 0;
proc corr data=chdnew plots=matrix;
	var Alcohol Tobacco;
run;

* Estimated rho = 0.20081
* P-value < .0001 -> Reject H0;

*iv. Is the proportion of having family history greater than 40%?;
*H0: p = 40% vs H1: p < 40%;
* One-Sample Test for Binary Proportion;

proc freq data=chdnew;
	table Famhist / binomial(p=.40 level = 'Present'); * alpha: significance level;
run;
*p-value = 0.2471 > 0.05, We fail to reject the null and conclude that proportion of having family history equal 40%;

*e) Fitting a model;
proc genmod data=chd;
    class Famhist;
	model chd = SBP Tobacco LDL BAI Famhist TYPEA BMI ALCOHOL AGE / dist = bin link = logit;
run;

*check for colinearity;
proc reg data=chd;
	model chd = SBP Tobacco LDL BAI TYPEA BMI ALCOHOL AGE / vif;
run; quit;
*there is no colinearity found here;

*model selection;
proc logistic data=chd plots(only)=(roc effect) descending;
    class Famhist(ref = "Absent")/param=ref;
	model chd(ref = FIRST) = SBP Tobacco LDL BAI Famhist TYPEA BMI ALCOHOL AGE
			/ lackfit outroc = roc selection = stepwise; * Model selection;
run;
*From the stepwise model selection, we have Tobacco, LDL, Famhist TypeA, Age left in the model;

*Final model;
proc logistic data=chd plots(only)=(roc effect);
	class Famhist (ref="Absent") ;
	model CHD (ref = FIRST)= Tobacco LDL Famhist TypeA Age Alcohol/ lackfit outroc = roc;*we get a roc dataset;
run;

ods rtf close;