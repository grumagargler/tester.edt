// *****************************************
// *********** Group Form

&AtClient
Procedure VSCodeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFile ();
	
EndProcedure

&AtClient
Procedure chooseFile ()
	
	dialog = new FileDialog ( FileDialogMode.Open );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure SelectFile ( File, Params ) export
	
	if ( File = undefined ) then
		return;
	endif; 
	Object.VSCode = File [ 0 ];
	
EndProcedure 
