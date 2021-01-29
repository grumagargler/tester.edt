&AtClient
var ListRow;

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
	if ( Parameters.CurrentRow <> undefined ) then
		defaultFilter = false;
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
	
	filter = ScenarioFilter <> undefined;
	if ( filter ) then
		DC.SetParameter ( List, "Scenario", ScenarioFilter, ScenarioFilter <> undefined );
	else
		DC.SetParameter ( List, "Scenario", undefined, false );
	endif;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ClearLog ( Command )
	
	Output.ClearLogConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure ClearLogConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	clearErrors ();
	Items.List.Refresh ();
	
EndProcedure 

&AtServer
Procedure clearErrors ()
	
	data = getRecords ();
	SetPrivilegedMode ( true );
	BeginTransaction ();
	selection = data.Log.Select ();
	while ( selection.Next () ) do
		r = InformationRegisters.Log.CreateRecordManager ();
		FillPropertyValues ( r, selection );
		r.Delete ();
	enddo; 
	selection = data.ErrorLog.Select ();
	while ( selection.Next () ) do
		selection.Ref.GetObject ().Delete ();
	enddo; 
	CommitTransaction ();
	
EndProcedure 

&AtServer
Function getRecords ()
	
	s = "
	|select allowed ErrorLog.Ref as Ref
	|into ErrorLog
	|from Catalog.ErrorLog as ErrorLog
	|;
	|select ErrorLog.Ref as Ref
	|from ErrorLog as ErrorLog
	|;
	|select Log.Period as Period, Log.Session as Session, Log.Scenario as Scenario
	|from InformationRegister.Log as Log
	|where Log.Error in ( select Ref from ErrorLog )
	|";
	q = new Query ( s );
	data = q.ExecuteBatch ();
	result = new Structure ();
	result.Insert ( "ErrorLog", data [ 1 ] );
	result.Insert ( "Log", data [ 2 ] );
	return result;
	
EndFunction 

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

// *****************************************
// *********** List

&AtClient
Procedure ListOnActivateRow ( Item )
	
	ListRow = Item.CurrentData;
	AttachIdleHandler ( "fill", 0.1, true );
	
EndProcedure

&AtClient
Procedure fill () export
	
	if ( ListRow = undefined ) then
		Screenshot = "";
		Stack.Clear ();
	else
		if ( ListRow.Ref = OldRecord ) then
			return;
		endif; 
		OldRecord = ListRow.Ref;
		updateInfo ();
	endif; 
	displayInfo ();
	
EndProcedure 

&AtServer
Procedure updateInfo ()
	
	ErrorLogForm.UpdateStack ( OldRecord, Stack );
	updateScreenshot ();
	
EndProcedure 

&AtServer
Procedure updateScreenshot ()
	
	if ( DF.Pick ( OldRecord, "ScreenshotExists" ) ) then
		Screenshot = GetURL ( OldRecord, "Screenshot" );
	else
		Screenshot = "";
	endif; 

EndProcedure 

&AtClient
Procedure displayInfo ()
	
	if ( Screenshot = "" ) then
		if ( ListRow = undefined ) then
			Items.Pages.CurrentPage = Items.UndefinedPage;
		else
			Items.Pages.CurrentPage = Items.InfoPage;
		endif; 
	else
		Items.Pages.CurrentPage = Items.ScreenshotPage;
	endif; 
	
EndProcedure 

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	if ( Field.Name = "Job" ) then
		ShowValue ( , ListRow.Job );
	else
		ShowValue ( , ListRow.Ref );
	endif;
	
EndProcedure

// *****************************************
// *********** Table Stack

&AtClient
Procedure StackSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	data = Item.CurrentData;
	ScenarioForm.GotoLine ( data.Ref, data.Row, ListRow.Ref );
	
EndProcedure

// *****************************************
// *********** Screenshot Field

&AtClient
Procedure ScreenshotClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	showPicture ();
	
EndProcedure

&AtClient
Procedure showPicture ()
	
	if ( Screenshot = "" ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Title", OldRecord );
	p.Insert ( "URL", Screenshot );
	OpenForm ( "CommonForm.Screenshot", p );
	
EndProcedure 
