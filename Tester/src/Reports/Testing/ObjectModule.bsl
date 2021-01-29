var Params export;

Procedure OnCompose () export
	
	adjustFilter ();
	hideStarter ();
	
EndProcedure

Procedure adjustFilter ()
	
	settings = Params.Settings;
	job = DC.FindFilter ( settings, "Job" );
	if ( job = undefined
		or not job.Use ) then
		return;
	endif;
	filter = DC.FindFilter ( settings, "User" );
	if ( filter.Use ) then
		filter.Use = false;
		DC.FindFilter ( Params.Composer, "User" ).Use = false;
	endif;
	filter = DC.FindParameter ( settings, "Period" );
	if ( filter.Use ) then
		filter.Use = false;
		DC.FindParameter ( Params.Composer, "Period" ).Use = false;
	endif;
	
EndProcedure

Procedure hideStarter ()
	
	settings = Params.Settings;
	group = DC.GetGroup ( settings, "Module" );
	if ( group = undefined ) then
		return;
	endif;
	filter = DC.FindFilter ( group, "ErrorLevel" );
	if ( filter = undefined ) then
		return;
	endif;
	group = DC.GetGroup ( settings, "Starter" );
	group.Use = not filter.Use;
	
EndProcedure

Procedure AfterOutput () export
	
	hideErrors ();

EndProcedure

Procedure hideErrors ()
	
	result = Params.Result;
	resultDetails = Params.Details.Items;
	DetailsType = Type ( "DataCompositionDetailsID" );
	level = 0;
	for i = 1 to result.TableHeight do
		details = result.Area ( i, 1 ).Details;
		if ( TypeOf ( details ) = DetailsType ) then
			set = resultDetails.Get ( details ).GetFields ();
			scenario = set.Find ( "Scenario" );
			if ( scenario <> undefined ) then
				level = level + 1;
				if ( not scenario.Hierarchy ) then
					break;
				endif;
			endif;
		endif;
	enddo;
	if ( level <> 0 ) then
		i = Result.RowGroupLevelCount ();
		while ( i > level ) do
			i = i - 1;
			Result.ShowRowGroupLevel ( i );
		enddo;
	endif;
	
EndProcedure
