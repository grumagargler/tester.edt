&AtServer
var AllScenarios export;
&AtServer
var WorkingScope export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	LockingForm.LoadScenarios ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	var changed, locked, alreadyLocked, errors;
	
	change ( changed, locked, alreadyLocked, errors );
	broadcast ( changed );
	RepositoryFiles.Sync ();
	Close ( new Structure ( "AlreadyLocked, Errors", alreadyLocked, errors ) );
	
EndProcedure

&AtServer
Procedure change ( Changed, Locked, AlreadyLocked, Errors )
	
	fetchScenarios ();
	LockingForm.Lock ( AllScenarios, Locked, AlreadyLocked );
	modify ( AlreadyLocked, Errors );
	Changed = WorkingScope;
	
EndProcedure

&AtServer
Procedure fetchScenarios ()
	
	data = LockingForm.FetchScenarios ( ThisObject );
	AllScenarios = data [ 0 ].Unload ();
	WorkingScope = data [ 1 ].Unload ().UnloadColumn ( "Ref" );
	
EndProcedure 

&AtServer
Procedure modify ( AlreadyLocked, Errors )
	
	errorsList = new Array ();
	notMine = notMine ( AlreadyLocked );
	for each row in AllScenarios do
		scenario = row.Ref;
		if ( notMine [ scenario ] <> undefined ) then
			continue;
		endif; 
		current = DF.Pick ( scenario, "Application" );
		if ( current = Application ) then
			continue;
		endif;
		obj = scenario.GetObject ();
		obj.Application = Application;
		try
			obj.Write ();
		except
			error = ErrorDescription ();
			errorsList.Add ( new Structure ( "Scenario, Error", scenario, error ) );
			continue;
		endtry;
	enddo; 
	Errors = ? ( errorsList.Count () = 0, undefined, errorsList );
	
EndProcedure

&AtServer
Function notMine ( AlreadyLocked )
	
	set = new Map ();
	if ( AlreadyLocked <> undefined ) then
		for each item in AlreadyLocked do
			set [ item.Scenario ] = true;
		enddo; 
	endif; 
	return set;
	
EndFunction 

&AtClient
Procedure broadcast ( Changed )
	
	Notify ( Enum.MessageApplicationChanged (), Changed );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
EndProcedure 

// *****************************************
// *********** Table List

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
