/* Macro for running multiple model selection procedures */

%macro GradRateAnalysis(data=regmodel, response=rate, selection=stepwise, 
		select_crit=aic, stop_crit=aic, choose_crit=aic);
	ods listing close;
	ods output
	ModelInfo=work._ModelInfo
	NObs=work._NObs
	SelectionSummary=work._Selection
	ParameterEstimates=work._Estimates
	FitStatistics=work._FitStats;

	/*model selection */
	proc glmselect data=&data;
		class iclevel control hloffer locale instcat c21enprf board;
		model &response=cohort InStateT InStateF InDistrictT InDistrictF
		OutStateT OutStateF Housing board boardamt
		GrantRate GrantAvg PellRate LoanRate LoanAvg
		AvgSalary StuFacRatio ScaledHousingCap / 
			selection=&selection(select=&select_crit
			stop=&stop_crit
			choose=&choose_crit);
	run;

	ods output close;
	ods listing;

	/*summary tables */
	proc sql;
		/* Model summary */
		create table ModelSummary as
		select
		"&selection" as Selection_Method, "&select_crit" as Selection_Criterion, 
			"&stop_crit" as Stop_Criterion, "&choose_crit" as Choose_Criterion, Step, 
			EffectEntered, case
			when "&select_crit"='aic' then AIC
			when "&select_crit"='sbc' then SBC
			else .
			end as CriterionValue
			from work._Selection
			where EffectEntered is not missing
			order by Step;

		/* Parameter estimates */
		create table FinalEstimates as
		select
		Effect as Parameter, Estimate, StdErr, tValue, Probt, StandardizedEst
		from work._Estimates
		where Effect is not missing
		order by Parameter;
	quit;

	proc datasets library=work nolist;
		delete _ModelInfo _NObs _Selection _Estimates _FitStats;
	run;

	quit;
%mend GradRateAnalysis;

/* Run the analysis with different criteria */
%GradRateAnalysis(data=regmodel, response=rate, selection=stepwise, 
	select_crit=aic, stop_crit=aic, choose_crit=aic);
%GradRateAnalysis(data=regmodel, response=rate, selection=stepwise, 
	select_crit=aic, stop_crit=aic, choose_crit=sbc);