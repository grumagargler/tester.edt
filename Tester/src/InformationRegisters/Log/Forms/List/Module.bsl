// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setFilter ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ScenarioFilter = Parameters.Scenario;
	JobFilter = Parameters.Job;
	
EndProcedure 

&AtServer
Procedure setFilter ()
	
	defaultFilter = true;
	if ( not JobFilter.IsEmpty () ) then
		defaultFilter = false;
		filterByJob ();
	endif;
	if ( ScenarioFilter <> undefined ) then
		defaultFilter = false;
		filterByScenario ();
	endif;
	if ( defaultFilter ) then
		UserFilter = SessionParameters.User;
		filterByUser ();
	endif;
	
EndProcedure 

&AtServer
Procedure filterByJob ()
	
	DC.ChangeFilter ( List, "Job", JobFilter, not JobFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure filterByUser ()
	
	DC.ChangeFilter ( List, "User", UserFilter, not UserFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure filterByScenario ()
	
	DC.ChangeFilter ( List, "Scenario", ScenarioFilter, ScenarioFilter <> undefined );
	Appearance.Apply ( ThisObject, "ScenarioFilter" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure UserFilterOnChange ( Item )
	
	applyUserFilter ();
	
EndProcedure

&AtServer
Procedure applyUserFilter ()
	
	if ( not UserFilter.IsEmpty () ) then
		JobFilter = undefined;
		filterByJob ();
		Appearance.Apply ( ThisObject, "JobFilter" );
	endif;
	filterByUser ();
	Appearance.Apply ( ThisObject, "UserFilter" );

EndProcedure

&AtClient
Procedure SeverityFilterOnChange ( Item )
	
	filterBySeverity ();
	
EndProcedure

&AtServer
Procedure filterBySeverity ()
	
	DC.ChangeFilter ( List, "Severity", SeverityFilter, not SeverityFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "SeverityFilter" );
	
EndProcedure 

&AtClient
Procedure AreaFilterOnChange ( Item )
	
	filterByArea ();
	
EndProcedure

&AtServer
Procedure filterByArea ()
	
	DC.ChangeFilter ( List, "Area", AreaFilter, not AreaFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "AreaFilter" );
	
EndProcedure 

&AtClient
Procedure ScenarioFilterOnChange ( Item )
	
	filterByScenario ();
	
EndProcedure

&AtClient
Procedure JobFilterOnChange ( Item )
	
	applyJobFilter ();
	
EndProcedure

&AtServer
Procedure applyJobFilter ()
	
	if ( not JobFilter.IsEmpty () ) then
		UserFilter = undefined;
		filterByUser ();
		Appearance.Apply ( ThisObject, "UserFilter" );
	endif;
	filterByJob ();
	Appearance.Apply ( ThisObject, "JobFilter" );

EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( openError ( Field )
		or showError ()
		or openJob ( Field ) ) then
		StandardProcessing = false;
	endif; 
	
EndProcedure

&AtClient
Function openError ( Field )
	
	if ( Field.Name = "Error" ) then
		ShowValue ( , Items.List.CurrentData.Error );
		return true;
	endif; 
	return false;
	
EndFunction 

&AtClient
Function showError ()
	
	error = Items.List.CurrentData.Error;
	if ( error.IsEmpty ()
		or not DF.Pick ( error, "ScreenshotExists" ) ) then
		return false;
	else
		p = new Structure ();
		p.Insert ( "Title", error );
		p.Insert ( "URL", GetURL ( error, "Screenshot" ) );
		OpenForm ( "CommonForm.Screenshot", p );
		return true;
	endif; 
	
EndFunction

&AtClient
Function openJob ( Field )
	
	if ( Field.Name = "Job" ) then
		ShowValue ( , Items.List.CurrentData.Job );
		return true;
	endif; 
	return false;
	
EndFunction 
