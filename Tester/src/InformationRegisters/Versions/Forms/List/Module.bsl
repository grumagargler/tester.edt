&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	displayCaption ();
	filterByScenario ();
	
EndProcedure

&AtServer
Procedure displayCaption ()
	
	Title = Parameters.Scenario;
	
EndProcedure 

&AtServer
Procedure filterByScenario ()
	
	DC.ChangeFilter ( List, "Scenario", Parameters.Scenario, true );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	AttachIdleHandler ( "showCode", 0.1, true );
	
EndProcedure

&AtClient
Procedure showCode () export
	
	if ( TableRow = undefined ) then
		Script = "";
		return;
	endif; 
	if ( TableRow.Version = OldVersion ) then
		return;
	endif; 
	OldVersion = TableRow.Version;
	Script = DF.Pick ( OldVersion, "Script" );
	
EndProcedure 

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	ShowValue ( , TableRow.Version );
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	ShowValue ( , TableRow.Version );
	
EndProcedure
