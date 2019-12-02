// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
EndProcedure

Procedure init ()
	
	DC.SetParameter ( List, "User", SessionParameters.User );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ApplicationFilterOnChange ( Item )
	
	filterByApplication ();
	
EndProcedure

&AtServer
Procedure filterByApplication ()
	
	if ( ApplicationFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, "Application", undefined, false );
	else
		filter = new Array ();
		filter.Add ( Catalogs.Applications.EmptyRef () );
		filter.Add ( ApplicationFilter );
		DC.ChangeFilter ( List, "Application", filter, true, DataCompositionComparisonType.InList );
	endif; 
	
EndProcedure 
