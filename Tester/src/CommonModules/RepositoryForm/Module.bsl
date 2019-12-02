&AtClient
Procedure SetFocus ( Form ) export
	
	items = Form.Items;
	object = Form.Object;
	for each row in object.Repositories do
		if ( row.Use ) then
			items.Repositories.CurrentRow = row.GetID ();
			return;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function CheckSelection ( Object ) export
	
	found = Object.Repositories.FindRows ( new Structure ( "Use", true ) );
	if ( found.Count () = 0 ) then
		Output.RepositoryNotSelected ( , "Repositories" );
		return false;
	endif; 
	return true;

EndFunction 

&AtServer
Function CheckFolders ( Object ) export
	
	error = false;
	msg = new Structure ();
	msg.Insert ( "Field", Metadata.DataProcessors.Load.TabularSections.Repositories.Attributes.Folder.Presentation () );
	for each row in Object.Repositories do
		if ( row.Use
			and row.Folder = "" ) then
			Output.FieldIsEmpty ( msg, Output.Row ( "Repositories", row.LineNumber, "Folder" ) );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 

&AtClient
Procedure ChooseFolder ( Form ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject, Form ) );
	
EndProcedure 

&AtClient
Procedure SelectFolder ( Folder, Form ) export
	
	if ( Folder = undefined ) then
		return;
	endif; 
	Form.TableRow.Folder = Folder [ 0 ];
	Form.TableRow.Use = true;
	
EndProcedure 

&AtClient
Procedure ApplyFolder ( Form ) export
	
	adjustPath ( Form );
	markUsage ( Form );
	
EndProcedure 

&AtClient
Procedure adjustPath ( Form )
	
	row = Form.TableRow;
	row.Folder = FileSystem.RemoveSlash ( row.Folder );
	
EndProcedure 

&AtClient
Procedure markUsage ( Form )
	
	row = Form.TableRow;
	row.Use = row.Folder <> "";
	
EndProcedure 

&AtServer
Procedure SavePaths ( Object ) export
	
	BeginTransaction ();
	data = new Structure ( "User, Computer, Application", SessionParameters.User, SessionData.Computer () );
	for each row in Object.Repositories do
		if ( not row.Use ) then
			continue;
		endif; 
		r = InformationRegisters.Repositories.CreateRecordManager ();
		data.Application = row.Application;
		FillPropertyValues ( r, data );
		r.Read ();
		if ( r.Mapping ) then
			continue;
		elsif ( not r.Selected () ) then
			FillPropertyValues ( r, data );
		endif;
		r.Folder = row.Folder;
		r.Write ();
	enddo; 
	CommitTransaction ();
	
EndProcedure 
