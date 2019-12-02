
&AtClient
Procedure CommandProcessing ( Scenario, ExecuteParameters )
	
	runStudio ( Scenario );
	
EndProcedure

&AtClient
Procedure runStudio ( Scenario )
	
	error = "";
	file = RepositoryFiles.ScenarioToFile ( Scenario, error );
	if ( file = undefined ) then
		Message ( error );
	else
		RepositoryFiles.Sync ( DF.Pick ( Scenario, "Application" ) );
		repo = repoData ( Scenario, GetPathSeparator () );
		cmd = ? ( repo.VSCode = "", """C:\Program Files\Microsoft VS Code\Code.exe""", repo.VSCode ) + " """ + repo.Folder + """ """ + file + """";
		#if ( ThinClient ) then
			BeginRunningApplication ( new NotifyDescription ( "stub", ThisObject ), cmd );
		#endif
	endif;
	
EndProcedure

&AtServer
Function repoData ( val Scenario, val Separator )
	
	table = getFolders ();
	application = DF.Pick ( Scenario, "Application" );
	row = table.Find ( application, "Application" );
	folder = row.Folder;
	parent = folder;
	vscode = row.VSCode;
	table.Delete ( row );
	looking = ( table.Count () > 0 );
	while ( looking ) do
		parent = FileSystem.GetParent ( parent, Separator );
		if ( parent = undefined ) then
			break;
		endif;
		for each row in table do
			if ( StrStartsWith ( row.Folder, parent ) ) then
				looking = false;
				break;
			endif;
		enddo;
	enddo;
	return new Structure ( "Folder, VSCode", ? ( parent = undefined, folder, parent ), vscode );
	
EndFunction

&AtServer
Function getFolders ()
	
	s = "
	|select allowed Repositories.Folder as Folder, Repositories.Application as Application,
	|	Repositories.Computer.VSCode as VSCode
	|from InformationRegister.Repositories as Repositories
	|where Repositories.Computer = &Computer
	|and Repositories.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	return q.Execute ().Unload ();
	
EndFunction

&AtClient
Procedure stub ( Result, Params ) export
	
	//@skip-warning
	noerrors = true;
	
EndProcedure
