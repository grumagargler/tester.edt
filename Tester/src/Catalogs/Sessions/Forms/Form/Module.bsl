// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setIP ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setIP ()
	
	IP = Object.Localhost;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	MySession = SessionParameters.Session = Object.Ref;
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( MySession ) then
		Test.ShutdownProxy ();
	endif;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	setLocalhost ();
	
EndProcedure

&AtClient
Procedure setLocalhost ()
	
	Object.Localhost = StrReplace ( IP, " ", "" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ProxyOnChange ( Item )
	
	applyProxy ();
	
EndProcedure

&AtClient
Procedure applyProxy ()
	
	if ( Object.Proxy ) then
		Object.Port = 1500;
		IP = "127.0.0.1";
	else
		Object.Port = 0;
		Object.Localhost = "";
		IP = "";
	endif;
	Appearance.Apply ( ThisObject, "Object.Proxy" );
	
EndProcedure
