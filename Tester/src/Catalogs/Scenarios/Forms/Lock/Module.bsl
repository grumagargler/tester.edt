&AtServer
var AllScenarios export;

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
	
	var locked, errors;
	
	lock ( locked, errors );
	broadcast ( locked );
	Close ( errors );
	
EndProcedure

&AtServer
Procedure lock ( LockedScenarios, ErrorsList )
	
	AllScenarios = LockingForm.FetchScenarios ( ThisObject );
	LockingForm.Lock ( AllScenarios, LockedScenarios, ErrorsList );
	
EndProcedure

&AtClient
Procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageLocked (), Scenarios );
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
