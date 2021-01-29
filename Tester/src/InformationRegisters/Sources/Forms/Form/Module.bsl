// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		fillNew ();
	endif;
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	Record.Computer = SessionData.Computer ();
	if ( Record.User.IsEmpty () ) then
		Record.User = SessionParameters.User;
	endif;
	if ( Record.Application.IsEmpty () ) then
		Record.Application = EnvironmentSrv.GetApplication ();
	endif;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkFolder () ) then
		Cancel = true;
		return;
	endif;
	
EndProcedure

&AtServer
Function checkFolder ()
	
	if ( IsBlankString ( Record.Designer )
		and IsBlankString ( Record.EDT ) ) then
		Output.SourcesFolderError ( , "Designer", , "Record" );
		return false;
	endif;
	return true;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure FolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFolder ( Item );
	
EndProcedure

&AtClient
Procedure chooseFolder ( Item )
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "selectFolder", ThisObject, Item ) );
	
EndProcedure 

&AtClient
Procedure selectFolder ( Folder, Item ) export
	
	if ( Folder = undefined ) then
		return;
	endif; 
	Record [ Item.Name ] = Folder [ 0 ];
	
EndProcedure 

&AtClient
Procedure FolderOnChange ( Item )
	
	adjustPath ( Item );
	
EndProcedure

&AtClient
Procedure adjustPath ( Item )
	
	Record [ Item.Name ] = FileSystem.RemoveSlash ( Item.Name );
	
EndProcedure 
