*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Homework_10 4/20/2019                 *
* Jun Lu (Columbia University)          *
*****************************************;

ods pdf file= '/folders/myfolders/HW9/results.pdf';

* a) Import the dataset;

proc format;
	value race_fmt 0 = "white, non-Hispanic"
				   1 = "black, non-Hispanic"
				   2 = "other ethnicity";
	value education_fmt 0 = "post-graduate"
						1 = "college graduate"
						2 = "some college"
						3 = "high school or less";
run;


data Meno;
	infile "/folders/myfolders/HW10/Menopause.dat" dsd dlm="	"  lrecl=1024;
	input ID Intake_age Menopause_age Menopause Race Education;
	format Race race_fmt. Education education education_fmt.;
run;

data Meno;
	set Meno;
	format Race race_fmt. Education education education_fmt.;
run;

proc print data=Meno(obs=5);
run;

* b) Create a new variable;

data Meno;
	set Meno; 
	Time = 	Menopause_age - Intake_age;
run;

* c) Descriptive statistics;

* i)Frequency table of censoring status;
proc freq data=meno;
	table Menopause;
run;

* ii) Cross-tabular frequency table of censoring status and race;
proc freq data=meno;
	table Menopause * Race;
run;

* iii) Kaplan-Meier estimate of survival time ‘Time;
proc lifetest data=meno plots=(survival(cl) logsurv);
	time Time*Menopause(0);
run;

* d) Hypothesis test: 
i. Is the censoring status independent of race?

H0: Censoring status is independent of race
H1: Censoring status is not independent of race

-> Test of Independence (Chi-squared test);

proc freq data= meno;
	table Menopause * Race / norow nocol nopercent chisq;
run;

* Check assumptions

*a) No more than 1/5 of the cells have expected values <5.
*b) No cell has expected value <1;

* P-value = 0.0421 < 0.05 reject H0;
* We conclude that censoring status is associated with race significantly;


* ii. Is the mean intake age different depending on race? If so, 
which pair is significantly different?;

* H0: The mean intake age is not different depending on race
* H1: The mean intake age is different depending on race;

* -> ANOVA;
* Check the normality;

proc univariate data=meno normal;
	class Race;
	var Intake_age;
	histogram Intake_age;
	qqplot Intake_age;
run;


* Shapiro-Wilk p-value;
* (white, non-Hispanic) <0.0001 (black, non-Hispanic) 0.0328 （other ethnicity）0.0016
* -> Normality assumption for every type group is  not appropriate;
* And the sampe size of each group is not large enough
* But ANOVA is robust


* We try both ANOVA and Kruskal-Wallis test

* ANOVA;

proc glm data=meno;
	class Race;
	model Intake_age = Race;
	means Race / hovtest=bf; 
run; quit;

* Equality of variances (BF test) p-value = 0.7350 -> fail to reject H0;
* -> Assumption of equal variance is satisfied;

* ANOVA
* P-value 0.6000 > 0.05 fail to reject H0
* We conclude that we do not have enough evidence to prove that
the mean intake age is different depending on race;


* Kruskal-Wallis test;

proc npar1way data=meno wilcoxon;
	class Race;
	var Intake_age;
run;

* P-value <0.4264
* <<Median>> We conclude that we do not have enough evidence to prove 
that the median intake age is different depending on race;




* iii. For 3 different categories of race, are the survival functions
 equivalent?;
 
* H0: For 3 different categories of race, the survival functions
 are equivalent
* H1: For 3 different categories of race, the survival functions
 are not equivalent;


proc lifetest data=meno notable;
	time Time*Menopause(0);
	strata race / test = (all);
run;

* Use Log-Rank test;
* P-value = 0.0530 > 0.05 fail to reject H0;
* We conclude that we do not have enough evidence to prove for 3 different categories 
the survival functions are not equivalent;




*e) Fitting a model;



*1.Start by checking the K-M estimates;
proc lifetest data=meno;
	time Time*Menopause(0);
run;

proc lifetest data=meno notable;
	time Time*Menopause(0);
	strata Education;
run;

proc lifetest data=meno notable;
	time Time*Menopause(0);
	strata race;
run;



*2. Stepwise Selection and fit the Cox proportional hazard (PH) model and get the hazard ratio (HR);

proc phreg data=meno;
	class Race(ref="white, non-Hispanic") Education(ref="post-graduate");
	model Time*Menopause(0) = Race Education intake_age /rl selection=stepwise;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;

* The stepwise procedure chooses "Intake_age", "Race" and "Education";







*3. Test the proportionality assumption;

*i) Plot survival functions / cumulative hazard functions / log(cumulative hazard);
* Race;
proc lifetest data=meno notable plots=(survival logsurv loglogs);
	time Time*Menopause(0);
	strata Race / test=all;
run;

* Education;
proc lifetest data=meno notable plots=(survival logsurv loglogs);
	time Time*Menopause(0);
	strata Education / test=all;
run;


*ii) Include an interaction term with time (usually log(time)).;
* Include interactions with time;
proc phreg data=meno;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic");
	model time*Menopause(0) = Race Education Intake_age race_t education_t age_t /rl;
	race_t=race*log(Time);
	age_t=Intake_age*log(Time);
	education_t=Education*log(Time);
	assess ph/resample seed = 1;
run;

* All interactions are non-significant - proportionality assumption met;


*iii) Formal test of proportionality;

proc phreg data=meno;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic");
	model time*Menopause(0) = Race Education Intake_age /rl;
	assess ph / resample seed=1;
run;



*4. Check the functional form of continuous variables.;
proc phreg data=meno;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic");
	model time*Menopause(0) = Race Education Intake_age intake_age/rl;
	assess var=(intake_age) / resample seed=1;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;


*5. Look at the residuals

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







* Change the form of intake_age;

proc format;
	value age_fmt 0 = "<=50"
				   1 = ">50";
run;

Data meno2;
	set meno;
	if intake_age > 50 then age_group = 1;
	if intake_age <= 50 then age_group = 0;
	format age_group age_fmt.;
run;




* Fit the Cox proportional hazard (PH) model and get the hazard ratio (HR);
proc phreg data=meno2;
	class Race(ref="white, non-Hispanic") Education(ref="post-graduate")
	age_group(ref="<=50");
	model Time*Menopause(0) = Race Education age_group /rl;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;


* Test the proportionality assumption;
* Plot survival functions / cumulative hazard functions / log(cumulative hazard);

* Race and education have been plotted before

* Age_group;
proc lifetest data=meno2 notable plots=(survival logsurv loglogs);
	time Time*Menopause(0);
 	strata age_group / test=all;
run;

*Include an interaction term with time (usually log(time)).;
* Include interactions with time;
proc phreg data=meno2;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic") age_group(ref="<=50");
	model time*Menopause(0) = Race Education age_group race_t education_t age_group_t/rl;
	race_t=race*log(Time);
	education_t=Education*log(Time);
	age_group_t=age_group*log(Time);
	assess ph/resample seed = 1;
run;


*Formal test of proportionality;
proc phreg data=meno2;
	class Education(ref="post-graduate") Race(ref="white, non-Hispanic")
	age_group(ref="<=50");
	model time*Menopause(0) = Race Education age_group /rl;
	assess ph / resample seed=1;
	output out=outp xbeta=xb resmart=mart resdev=dev ressch=ressch;
run;


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

ods pdf close;
run;














		  
	