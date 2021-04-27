
&AtClient
Procedure CommandProcessing ( References, ExecuteParameters )
	
	openReport ( References, ExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( References, ExecuteParameters )
	
	parameter = References [ 0 ];
	p = ReportsSystem.GetParams ( "JobsSummary" );
	filters = new Array ();
	if ( TypeOf ( parameter ) = Type ( "DocumentRef.Job" ) ) then
		filters.Add ( DC.CreateFilter ( "Job", References ) );
	else
		filter = DC.CreateFilter ( "Scenario" );
		if ( References.Count () = 1 ) then
			filter.ComparisonType = ? ( DF.Pick ( parameter, "Tree" ), DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.Equal );
			filter.RightValue = parameter;
		else
			filter.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			filter.RightValue = new ValueList ();
			filter.RightValue.LoadValues ( References );
		endif; 
		filters.Add ( filter );
	endif;
	p.Filters = filters;
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );
	
EndProcedure 
