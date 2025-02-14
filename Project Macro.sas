libname Project '~/Project';

%macro ModelSelect(library=Project, class=, quant=, dataset=, response=, inter=N, hier=Y, method=stepwise, select=aic, stop=aic, choose=aic, outputData=);
	
proc glmselect data=&library..&dataset;
	%if(&class ne ) %then %do;
		class &class;
	%end;
	model &response = %if(&class ne ) %then %sysfunc(tranwrd(&class,%str( ),|)) |;
																					 %sysfunc(tranwrd(&quant,%str( ),|)) 
				
										%if(%upcase(%substr(&inter,1,1)) eq Y) %then @2; 
											%else @1;/**If inter starts with y/Y, 2-way interactions are in, otherwise no interactions**/
			 /selection=&method(select=&select stop=&stop choose=&choose)
								%if(%upcase(%substr(&hier,1,1)) eq Y) %then hierarchy=single; /**If hier starts with y/Y, single is set for hierarchy
																																								otherwise it remains the default**/
			;
	ods output modelInfo=modelInfo
						NObs=Obs
						SelectionSummary=Selection
						ParameterEstimates=Estimates;				
run;
 
proc transpose data=modelInfo(where=(label1 in ('Selection Method','Select Criterion','Stop Criterion','Choose Criterion'))) 
		out=model(drop=_name_);
	var cValue1;
	id label1;
run;
 
proc sql;
	create table &outputData as
	select model.*, "&class" as class, "&quant" as quant, "%upcase(%substr(&inter,1,1))" as Interactions, "%upcase(%substr(&hier,1,1))" as Hierarchy,
		NObsRead, NObsUsed, Step, case when Parameter ne '' then Parameter else EffectEntered end as Parameter, CriterionValue,
		estimate, stdErr, StandardizedEst
	from model, obs(where=(label contains 'Read')),
		selection(rename=(SBC=CriterionValue)) left join estimates on EffectEntered eq scan(parameter,1,' ')
	order by 'Selection Method'n,'Stop Criterion'n,'Choose Criterion'n, Step, Parameter
	;
quit;
%mend;
 
options mprint;
ods exclude all;

%let quant=
Cohort
GrantRate
GrantAvg
PellRate
LoanRate
LoanAvg
InStateT
InStateF
OutStateT
OutStateTDiff
OutStateF
OutStateFDiff
ScaledHousingCap
roomamt
boardamt
AvgSalary
StuFacRatio
;
 
%let class=
iclevel
control
hloffer
locale
instcat
c21enprf
Housing
board
;

%let class2=
iclevel
control
;
 
/*%ModelSelect(dataset=standardized,response=rate,outputData=out1);
%ModelSelect(dataset=standardized,response=rate,choose=SBC,outputData=out2);
%ModelSelect(dataset=standardized,response=rate,choose=SBC,outputData=out3,inter=yes,hier=no);*/


%ModelSelect(dataset=standardized, response=rate, class=&class, quant=&quant, outputData=out1);
/*%ModelSelect(dataset=standardized, response=rate, class=&class, quant=&quant, choose=SBC, outputData=out2);
%ModelSelect(dataset=standardized, response=rate, class=&class2, quant=&quant, choose=SBC, outputData=out3, inter=yes, hier=no);*/

data modelresults;
	length class quant parameter $500;/**these could have different lengths, so we set something long prior to assembly**/
	set out1;
run;