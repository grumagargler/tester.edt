// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setUser ();
	filterByUser ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setUser ()
	
	UserFilter = SessionParameters.User;
	
EndProcedure

&AtServer
Procedure filterByUser ()
	
	DC.ChangeFilter ( List, "User", UserFilter, not UserFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "UserFilter" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
EndProcedure
