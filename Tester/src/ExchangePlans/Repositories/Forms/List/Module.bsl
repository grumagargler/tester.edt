// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	if ( FixedUserFilter.IsEmpty () ) then
		setUser ();
	endif;
	filterByUser ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()

	FixedUserFilter = Parameters.User;
	UserFilter = FixedUserFilter; 
	
EndProcedure 

&AtServer
Procedure setUser ()
	
	UserFilter = SessionParameters.User;
	
EndProcedure

&AtServer
Procedure filterByUser ()
	
	filter = not UserFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Session.User", UserFilter, filter );
	DC.ChangeFilter ( Sources, "User", UserFilter, filter );
	DC.ChangeFilter ( Workspaces, "Owner", UserFilter, filter );
	Appearance.Apply ( ThisObject, "UserFilter" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
EndProcedure
