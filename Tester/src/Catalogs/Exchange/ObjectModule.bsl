
Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	trimAllAttributes ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	
EndProcedure

Procedure BeforeDelete ( Cancel )
	
	UseAutomatic = false;	
	
EndProcedure

Procedure trimAllAttributes ()
	
	attributes = getAttributes ();
	for each attribute in attributes do
		ThisObject [ attribute ] = TrimAll ( ThisObject [ attribute ] );
	enddo; 
		
EndProcedure

Function getAttributes ()
	
	a = new Array ();
	a.Add ( "Code" );
	a.Add ( "EMailLoad" );
	a.Add ( "EMailUnLoad" );
	a.Add ( "FolderDiskLoadHandle" );
	a.Add ( "FolderDiskLoadJob" );
	a.Add ( "FolderDiskUnLoadHandle" );
	a.Add ( "FolderDiskUnLoadJob" );
	a.Add ( "FolderFTPLoad" );
	a.Add ( "FolderFTPUnLoad" );
	a.Add ( "PrefixFileName" );
	a.Add ( "ServerFTPLoad" );
	a.Add ( "ServerFTPUnLoad" );
	a.Add ( "ServerIncoming" );
	a.Add ( "ServerOutgoing" );
	a.Add ( "UserEmail" );
	a.Add ( "UserFTPLoad" );
	a.Add ( "UserFTPUnLoad" );
	a.Add ( "UserWebService" );
	a.Add ( "WebService" );
	return a; 
	
EndFunction 