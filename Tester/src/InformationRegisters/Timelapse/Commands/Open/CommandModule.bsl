
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )
	
	if ( TypeOf ( Source ) = Type ( "CatalogRef.ErrorLog" ) ) then
		openByError ( Source, ExecuteParameters );
	else
		openByScenario ( Source, ExecuteParameters );
	endif;
	
EndProcedure

&AtClient
Procedure openByError ( Error, ExecuteParameters )
	
	p = new Structure ( "Error", Error );
	OpenForm ( "InformationRegister.Timelapse.Form.Form", p, executeParameters.Source, executeParameters.Uniqueness, executeParameters.Window, executeParameters.URL );
	
EndProcedure

&AtClient
Procedure openByScenario ( Source, ExecuteParameters )
	
	p = new Structure ( "Scenario", Source );
	callback = new NotifyDescription ( "SessionSelected", ThisObject, ExecuteParameters );
	OpenForm ( "InformationRegister.Timelapse.Form.Sessions", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL, callback );
	
EndProcedure

&AtClient
Procedure SessionSelected ( Value, Params ) export
	
	if ( Value = undefined ) then
		return;
	endif;
	p = new Structure ();
	p.Insert ( "Scenario", Value.Scenario );
	p.Insert ( "Session", Value.Session );
	p.Insert ( "Date", Value.Started );
	OpenForm ( "InformationRegister.Timelapse.Form.Form", p, Params.Source, Params.Uniqueness, Params.Window, Params.URL );
	
EndProcedure