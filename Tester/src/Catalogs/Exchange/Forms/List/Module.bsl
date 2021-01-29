
&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setViewSettings ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer                                                                                                        
Procedure setViewSettings ()
	
	ViewSettings = ( AccessRight ( "Edit", Metadata.Constants.Agent )
					and AccessRight ( "Edit", Metadata.Constants.CloudPassword )
					and AccessRight ( "Edit", Metadata.Constants.CloudUser )
					and AccessRight ( "Edit", Metadata.Constants.ClusterAdministrator )
					and AccessRight ( "Edit", Metadata.Constants.ClusterPassword )
					and AccessRight ( "Edit", Metadata.Constants.ServerAdministrator )
					and AccessRight ( "Edit", Metadata.Constants.ServerCode )
					and AccessRight ( "Edit", Metadata.Constants.ServerPassword ) );
					
EndProcedure 

&AtClient
Procedure OpenConstants ( Command )
	
	OpenForm ( "Catalog.Exchange.Form.Settings" );	
	
EndProcedure