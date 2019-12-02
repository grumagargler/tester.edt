
&AtClient
Procedure Start ( Name ) export
	
	LocalFiles.Prepare ( new NotifyDescription ( "Download", ThisObject, Name ) );
	
EndProcedure

&AtClient
Procedure Download ( Result, Name ) export
	
	list = new Array ();
	list.Add ( new TransferableFileDescription ( Name + ".epf", DownloadTemplateSrv.GetLocation ( Name ) ) );
	BeginGettingFiles ( new NotifyDescription ( "Complete", ThisObject ), list, , true );
	
EndProcedure 

&AtClient
Procedure Complete ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Output.DownloadCompleted ();
	
EndProcedure 
