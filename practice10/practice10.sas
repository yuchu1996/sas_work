*************************************************************************
************************    Practice 10           ***********************
************************    Chu Yu  UNI: cy2522   ***********************
************************************************************************;
ods rtf file = "/folders/myshortcuts/Myfolder/practice10/practice10.rtf"
    bodytitle startpage = yes;
ods noproctitle;
* a)Import the dataset, name it ‘Meno’, and apply formats (Race, Education) in DATA step.;
proc format;
    value race_fm      0 = "white, non-Hispanic"
                    1 = "black, non-Hispanic"
                    2 = "other ethnicity";
    value education_fm  0 = "post-graduate"
                    1 = "college graduate"
                    2 = "some college"
                    3 = "high school or less";
run; 


data Meno;
   infile "/folders/myshortcuts/Myfolder/practice10/Menopause.dat" dsd dlm="	" lrecl=1024;
   input ID Intake_age Menopause_age Menopause Race Education;
   format Race race_fm. Education education_fm.;
run;

proc print data = Meno (obs = 5);run;

*b) Create a new variable ;
data menonew;
  set Meno;
  Time = Menopause_age-Intake_age;
run;

*c) Descriptive statistics;
*i. Frequency table of censoring status (i.e. Variable ‘Menopause’);
proc freq data = menonew;
   tables Menopause;
run;

*ii. Cross-tabular frequency table of censoring status and race;
proc freq data = menonew;
  tables Menopause*Race;
run;

*iii. Kaplan-Meier estimate of survival time ‘Time’: Survival function and cumulative hazard function;
proc lifetest data=menonew plots=(survival logsurv);
	time time*menopause(0);
run;

*d) Hypothesis test;
*i. Is the censoring status independent of race?;
*Test of Independence ;
* H0: Variable Menopause is not associated with Variable race.  H1: associated;
proc freq data=menonew;
	table  Menopause* Race / chisq exact; 
run;
*The Chi square = 0.0559 > 0.05, so we fail to reject the null and conclude that the two variables are not associated;

*ii. Is the mean intake age different depending on race? If so, which pair is significantly different?;
*1) Clarify the null and alternative hypotheses.  H0: mu1 = mu2 = mu3, H1: not null;
*2) Determine an appropriate statistical test: one-way ANOVA;
*3) Check the assumptions;
proc univariate data=menonew normal;
	class Race;
	var Intake_age;
	qqplot Intake_age;
	histogram Intake_age / normal;
run;

*p-value < .0001, the normality cannot stand, but the sample size is big enough, so we apply two methods;
*test;
proc glm data = menonew;
	class Race;
	model Intake_age = Race;
	means Race/ hovtest=bf;
run; quit;
*p-value = 0.6 > 0.05, we fail to reject the null and conclude that the mean intake age is not different depending on race;

proc npar1way data=menonew wilcoxon;
	class Race;
	var Intake_age;
run;
*p = 0.4264 > 0.05, We fail to reject the null and conclude that the mean intake age is not different depending on race;

*iii. For 3 different categories of race, are the survival functions equivalent? ;
*H0: The three survival functions of 3 races are equivalent vs H1: not null;
proc lifetest data=menonew plots=(survival);
	time time*menopause(0);
	strata Race / test=(all);
run;
*From the long rank stats, p = 0.0530 > 0.05, we fail to rej the null and conclude that three survival functions of 3 races are equivalent;

*e) Fitting a model;
*1) KM estimator;
proc lifetest data=menonew;
	time Time*Menopause(0);
run;

proc lifetest data=menonew notable;
	time Time*Menopause(0);
	strata Education;
run;

proc lifetest data=menonew notable;
	time Time*Menopause(0);
	strata race;
run;
*2);
* Model selection;
proc phreg data=menonew;
	class education(ref="post-graduate") race(ref="white, non-Hispanic");
	model time*menopause(0) = education intake_age race /rl selection=stepwise;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;
*all of three are left after strpwise selection;

*3) Check proportionality assumption;
* plot: (SURVIVAL LOGSURV LOGLOGS);

* SURVIVAL (survival functions): If they cross, then hazard changes over time;
* LOGSURV (cumulative hazard functions H(t) = -logS(t))
* : If hazards are proportional, then larger cumulative hazard should be a multiple of smaller: HA = r HB;
* LOGLOGS (log (cumulative hazard) logH(t))
* : If hazards are proportional, then LOGLOGS plot will show parallel curves:
*   logHA = r +logHB;

* education;
proc lifetest data=menonew plots=(survival logsurv loglogs);
	time time*menopause(0);
	strata education / test=(all);
run;

* Race;
proc lifetest data=menonew plots=(survival logsurv loglogs);
	time time*menopause(0);
	strata race / test=(all);
run;


* Include interactions with time;
proc phreg data=menonew;
	class education(ref="post-graduate") race(ref="white, non-Hispanic");
	model time*menopause(0) = education intake_age race education_t intake_age_t race_t /rl;*'_t'proving them insignificant;
	education_t = education*log(time);
	intake_age_t=intake_age*log(time);
	race_t=race*log(time);
	assess ph/resample;*proportional hazard;
run;
* All interactions are non-significant - proportionality assumption met;

* Formal test of proportionality;
* Use ASSESS statement with option PH;
proc phreg data=menonew;
	class education(ref="post-graduate") race(ref="white, non-Hispanic");
	model time*menopause(0) = education intake_age race /rl;
	assess ph / resample seed=4; * Check PH;
run;

*expect a straight line near 0;
* ASSESS: Create a plot of the cumulative Martingale residuals  
* RESAMPLE: Compute the p-value of a Kolmogorov-type supremum test 
*           based on a sample of 1,000 simulated residual patterns.;

*4) Check the functional form of continuous predictors -- intake_age;
* Use ASSESS statement;
proc phreg data=menonew;
	class education(ref="post-graduate") race(ref="white, non-Hispanic");
	model time*menopause(0) = education intake_age race /rl;
	assess var=(intake_age)/ resample seed=1;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;*reject the null -- functionality is inappropriate;
* The supremum test generated a p-value = 0.03 < 0.05 
* indicating that age should not be fitted in linear form (first degree form);

*since the proportional assumption cannot be satisfied;

* Stratify the model by the non-proportional covariates. ;
Data menofit;
	set menonew;
	if intake_age > 50 then age_group = 1;
	if intake_age <= 50 then age_group = 0;
run;

* Model selection;
proc phreg data=menofit;
	class education(ref="post-graduate") race(ref="white, non-Hispanic") age_group(ref=first);
	model time*menopause(0) = education age_group race /rl selection=stepwise;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;
*only age_group is left after strpwise selection;

*model;
proc phreg data=menofit;
	class education(ref="post-graduate") race(ref="white, non-Hispanic") age_group(ref=first);
	model time*menopause(0) = education age_group race / rl;
run;

* Age_group;
proc lifetest data=menofit notable plots=(survival logsurv loglogs);
	time Time*Menopause(0);
 	strata age_group / test=all;
run;

*Include an interaction term with time (usually log(time)).;

* Include interactions with time;
proc phreg data=menofit;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic") age_group(ref=first);
	model time*Menopause(0) = Race Education age_group race_t education_t age_group_t/rl;
	race_t=race*log(Time);
	education_t=Education*log(Time);
	age_group_t=age_group*log(Time);
	assess ph/resample seed = 4;
run;

*5) Residual analysis;
* Martingale residuals;
proc sgplot data=outp;
	scatter x=xb y=mart;
	refline 0 / axis=y;
run;

* Deviance residuals;
proc sgplot data=outp;
	scatter x=xb y=dev;
	refline 0 / axis=y;
run;

ods rtf close;