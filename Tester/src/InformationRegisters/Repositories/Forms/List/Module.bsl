// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedSettings ();
	if ( FixedUserFilter.IsEmpty () ) then
		setUser ();
		filterByUser ();
	endif;
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadFixedSettings ()
	
	Parameters.Filter.Property ( "User", FixedUserFilter );
	
EndProcedure 

&AtServer
Procedure setUser ()
	
	UserFilter = SessionParameters.User;
	
EndProcedure

&AtServer
Procedure filterByUser ()
	
	filter = not UserFilter.IsEmpty ();
	DC.ChangeFilter ( List, "User", UserFilter, filter );
	DC.ChangeFilter ( Sources, "User", UserFilter, filter );
	Appearance.Apply ( ThisObject, "UserFilter" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
EndProcedure
