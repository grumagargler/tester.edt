// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
EndProcedure

&AtServer
Procedure init ()
	
	User = SessionParameters.User;
	
EndProcedure