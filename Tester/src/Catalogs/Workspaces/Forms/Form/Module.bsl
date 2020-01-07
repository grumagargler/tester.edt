// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		initNew ();		
	endif;
	
EndProcedure

&AtServer
Procedure initNew ()
	
	Object.Owner = SessionParameters.User;
	Object.Computer = DF.Pick ( SessionParameters.Session, "Computer" );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	LocalFiles.SetDocumentsFolder ();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	groupApplications ( CurrentObject );
	
EndProcedure

&AtServer
Procedure groupApplications ( CurrentObject )
	
	CurrentObject.Applications.GroupBy ( "Application" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( not Object.DeletionMark ) then
		WorkspaceForm.Create ( Object.Ref );
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure WorkspaceStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseFile ();
	
EndProcedure

&AtClient
Procedure chooseFile ()
	
	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Filter = Output.VSCodeWorkspace ( new Structure ( "Extension", RepositoryFiles.VSCodeWorkspace () ) );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure SelectFile ( File, Params ) export
	
	if ( File = undefined ) then
		return;
	endif;
	Modified = true;
	Object.Workspace = File [ 0 ];
	
EndProcedure

// *****************************************
// *********** Applications List

&AtClient
Procedure ApplicationsOnChange ( Item )
	
	updateFile ();
	
EndProcedure

&AtClient
Procedure updateFile ()
	
	list = new Array ();
	for each row in Object.Applications do
		list.Add ( row.Application );
	enddo;
	fileName = fileName ( list );
	Object.Description = fileName; 
	Object.Workspace = UserDocumentsFolder + fileName + RepositoryFiles.VSCodeWorkspace ();
	
EndProcedure

&AtServerNoContext
Function fileName ( val Applications )
	
	s = "select Applications.Code as Code
	|from Catalog.Applications as Applications
	|where Applications.Ref in ( &Applications )
	|order by Applications.Code";
	q = new Query ( s );
	q.SetParameter ( "Applications", Applications );
	return StrConcat ( q.Execute ().Unload ().UnloadColumn ( "Code" ), "-" );
	
EndFunction
