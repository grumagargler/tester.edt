var Params export;

Procedure OnCompose () export
	
	filterByStatus ();
	
EndProcedure

Procedure filterByStatus ()
	
	settings = Params.Settings;
	filter = DC.GetParameter ( settings, "Status" );
	if ( filter.Use ) then
		DC.ChangeFilter ( settings, "Status", filter.Value, true );
	endif; 
	
EndProcedure 