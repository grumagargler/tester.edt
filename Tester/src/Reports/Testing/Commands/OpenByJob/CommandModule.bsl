
&AtClient
Procedure CommandProcessing ( Jobs, ExecuteParameters )
	
	openReport ( Jobs, ExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( Jobs, ExecuteParameters )
	
	parameter = Jobs [ 0 ];
	p = ReportsSystem.GetParams ( "Testing" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Job" );
	if ( Jobs.Count () = 1 ) then
		filter.ComparisonType = DataCompositionComparisonType.Equal;
		filter.RightValue = parameter;
	else
		filter.ComparisonType = DataCompositionComparisonType.InList;
		filter.RightValue = new ValueList ();
		filter.RightValue.LoadValues ( Jobs );
	endif; 
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );
	
EndProcedure 
