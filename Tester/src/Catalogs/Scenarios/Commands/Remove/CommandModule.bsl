
&AtClient
Procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	deletion = not DF.Pick ( Scenarios [ 0 ], "DeletionMark" );
	if ( deletion ) then
		Output.MarkForDeletion ( ThisObject, Scenarios );
	else
		Output.UnmarkForDeletion ( ThisObject, Scenarios );
	endif;
	
EndProcedure

&AtClient
Procedure MarkForDeletion ( Answer, Scenarios ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	proceedDeletion ( true, Scenarios );
	
EndProcedure

&AtClient
Procedure proceedDeletion ( Delete, Scenarios )

	error = undefined;
	changes = setMark ( Delete, Scenarios, error );
	if ( error <> undefined ) then
		Output.ShowError ( , , new Structure ( "Error", error ) );
	endif;
	broadcast ( changes );
	RepositoryFiles.Sync ();

EndProcedure

&AtServer
Function setMark ( val Delete, val Scenarios, Error )
	
	list = new Array ();
	for each scenario in Scenarios do
		obj = scenario.GetObject ();
		alreadyDeleted = obj.DeletionMark;
		if ( Delete = alreadyDeleted ) then
			continue;
		endif;
		try
			obj.SetDeletionMark ( Delete );
		except
			Error = BriefErrorDescription ( ErrorInfo () );
			break;
		endtry;
		list.Add ( scenario );
	enddo;
	return list;
	
EndFunction

&AtClient
Procedure broadcast ( Scenarios )
	
	Notify ( Enum.MessageReload (), Scenarios );
	NotifyChanged ( Type ( "CatalogRef.Scenarios" ) );
	
EndProcedure 

&AtClient
Procedure UnmarkForDeletion ( Answer, Scenarios ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	proceedDeletion ( false, Scenarios );
	
EndProcedure
