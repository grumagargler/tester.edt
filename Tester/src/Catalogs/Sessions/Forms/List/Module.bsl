// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
EndProcedure

&AtServer
Procedure init ()
	
	MySession = SessionParameters.Session;
	
EndProcedure