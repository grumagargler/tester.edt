
Function FolderSuffix () export
	
	return ".dir";
	
EndFunction 

Function ScriptFile () export
	
	return ".1c";
	
EndFunction 

Function MethodFile () export
	
	return ".1cm";
	
EndFunction 

Function LibFile () export
	
	return ".1cl";
	
EndFunction 

Function MXLFile () export
	
	return ".mxl";
	
EndFunction 

Function BSLFile () export
	
	return ".bsl";
	
EndFunction 

&AtServer
Function Signature () export
	
	return "92b895ac-0620-4a28-a128-76e2bd1a5ca4";
	
EndFunction 

&AtClient
Function SystemFolder () export
	
	return ".tester";
	
EndFunction

Function TypeToExtension ( Type ) export
	
	if ( Type = PredefinedValue ( "Enum.Scenarios.Library" ) ) then
		suffix = RepositoryFiles.LibFile ();
	elsif ( Type = PredefinedValue ( "Enum.Scenarios.Method" ) ) then
		suffix = RepositoryFiles.MethodFile ();
	else
		suffix = RepositoryFiles.ScriptFile ();
	endif; 
	return suffix + RepositoryFiles.BSLFile ();
	
EndFunction 

&AtClient
Function ScenarioToFile ( Scenario, Error = undefined ) export
	
	if ( Scenario.IsEmpty () ) then
		return undefined;
	endif;
	data = DF.Values ( Scenario, "Application, Path, Type, Tree" );
	application = data.Application;
	if ( mapped ( application ) ) then
		slash = GetPathSeparator ();
		path = StrReplace ( data.Path, ".", slash );
		parts = StrSplit ( path, slash );
		name = parts [ parts.UBound() ];
		root = FoldersWatchdog [ application ].Folder;
		extension = RepositoryFiles.TypeToExtension ( data.Type );
		if ( data.Tree ) then
			return root + slash + path + slash + name + RepositoryFiles.FolderSuffix () + extension;
		else
			return root + slash + path + extension;
		endif;
	else
		Error = Output.ScenarioApplicationUnmapped ( new Structure ( "Path", data.Path ) );
	endif;
	
EndFunction

&AtClient
Function mapped ( Application )
	
	return FoldersWatchdog <> undefined
	and FoldersWatchdog [ Application ] <> undefined;

EndFunction

&AtClient
Procedure Sync ( Application ) export
	
	if ( mapped ( Application ) ) then
		OpenForm ( "DataProcessor.Unload.Form", new Structure ( "Application", Application ) );
	endif;
	
EndProcedure
