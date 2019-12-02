// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
EndProcedure

&AtServer
Procedure init ()
	
	MySession = SessionParameters.Session;
	DC.SetParameter ( List, "Scenario", Parameters.Scenario );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure SessionFilterOnChange ( Item )
	
	filterBySession ();
	
EndProcedure

&AtServer
Procedure filterBySession ()
	
	DC.ChangeFilter ( List, "Session", SessionFilter, not SessionFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		StandardProcessing = false;
		Close ( Item.CurrentData );
	endif;

EndProcedure
