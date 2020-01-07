
Function FolderSuffix () export
	
	return ".dir";
	
EndFunction 

Function MXLFile () export
	
	return ".mxl";
	
EndFunction 

Function BSLFile () export
	
	return ".bsl";
	
EndFunction 

Function JSONFile () export
	
	return ".json";
	
EndFunction 

&AtClient
Function VSCodeWorkspace () export
	
	return ".code-workspace";
	
EndFunction 

&AtClient
Function Gitignore () export
	
	return ".gitignore";
	
EndFunction 

&AtClient
Function BSLServerSettings () export
	
	return ".bsl-language-server.json";
	
EndFunction 

&AtServer
Function Signature () export
	
	return "92b895ac-0620-4a28-a128-76e2bd1a5ca4";
	
EndFunction 

&AtClient
Function SystemFolder () export
	
	return ".tester";
	
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
		extension = RepositoryFiles.BSLFile ();
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
Function mapped ( Application = undefined )
	
	if ( FoldersWatchdog = undefined ) then
		return false;
	endif;
	if ( Application = undefined ) then
		return FoldersWatchdog.Count () > 0;
	else
		return FoldersWatchdog [ Application ] <> undefined;
	endif;

EndFunction

&AtClient
Function FileToPath ( File, PathBegins ) export

	slash = GetPathSeparator ();
	name = FileSystem.GetFileName(File);
	id = Mid ( name, 1, StrFind ( name, "." ) - 1 );
	isFolder = StrFind ( name, RepositoryFiles.FolderSuffix () ) > 0;
	path = FileSystem.GetParent ( File ) + ? ( isFolder, "", slash + id );
	path = StrReplace ( Mid ( path, PathBegins ), slash, "." );
	return path;
	
EndFunction

Function FileToName ( File ) export
	
	name = FileSystem.GetFileName ( File );
	i = StrFind ( name, "." );
	return ? ( i = 0, name, Left ( name, i - 1 ) );
	
EndFunction

&AtClient
Procedure Sync () export
	
	if ( mapped () ) then
		OpenForm ( "DataProcessor.Unload.Form", new Structure ( "Silent", true ) );
	endif;
	
EndProcedure
