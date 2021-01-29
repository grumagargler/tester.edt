
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setResponsible ();
	endif; 
	initVersions ();
	filterVersions ();
	filterPorts ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initVersions ()
	
	Session = SessionParameters.Session;
	DC.SetParameter ( Versions, "User", SessionParameters.User );
	
EndProcedure 

&AtServer
Procedure filterVersions ()
	
	ref = Object.Ref;
	DC.SetFilter ( Versions, "Owner", ref );
	DC.SetParameter ( Versions, "Owner", ref );
	
EndProcedure 

&AtServer
Procedure filterPorts ()
	
	DC.SetFilter ( Ports, "Application", Object.Ref );
	
EndProcedure 

&AtServer
Procedure setResponsible ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	Object.Responsible = SessionParameters.User;
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not updateMeta () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtClient
Function updateMeta ()
	
	try
		Runtime.UpdateMeta ( Object.Metadata );
	except
		ShowMessageBox ( , ErrorDescription () );
		CurrentItem = Items.Metadata;
		return false;
	endtry;
	return true;
	
EndFunction 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterVersions ();
	filterPorts ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	Object.Code = Conversion.NameToCode ( Object.Description, 4 );
	
EndProcedure

&AtClient
Procedure DialogsTitleOnChange ( Item )
	
	setScreenshotsLocator ();
	
EndProcedure

&AtClient
Procedure setScreenshotsLocator ()
	
	s = Object.DialogsTitle;
	if ( s = "" ) then
		return;
	endif; 
	Object.ScreenshotsLocator = ".+" + s + ".+";
	
EndProcedure 
