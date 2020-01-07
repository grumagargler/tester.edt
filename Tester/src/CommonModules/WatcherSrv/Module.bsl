Function MappedApplications () export
	
	table = getFolders ();
	result = new Structure ();
	result.Insert ( "Applications", table.UnloadColumn ( "Application" ) );
	result.Insert ( "Folders", table.UnloadColumn ( "Folder" ) );
	return result;
	
EndFunction

Function getFolders ()
	
	s = "select allowed Repositories.Application as Application, Repositories.Folder as Folder
	|from ExchangePlan.Repositories as Repositories
	|where Repositories.Session = &Session
	|and Repositories.Mapping";
	q = new Query ( s );
	q.SetParameter ( "Session", SessionParameters.Session );
	return q.Execute ().Unload ();
	
EndFunction

Function Update ( val Context, val Data, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario(Context);
	if (scenario = undefined) then
		Error = Output.UndefinedScenario(new Structure("File", Context.File));
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( scenario, false ), undefined, errors );
	if ( errors <> undefined ) then
		Error = Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	if ( updateScenario ( scenario, Data, Context, Error ) ) then
		return scenario;
	endif;
	
EndFunction

Function FindScenario ( val Context, val EvenRemoved = false ) export

	return RuntimeSrv.FindScenario ( Context.Path, Context.Application, undefined, undefined, true, EvenRemoved );

EndFunction

Function wrapScenario ( Scenario, Hierarchy )
	
	if ( Hierarchy ) then
		s = "select allowed Scenarios.Ref as Ref
		|from Catalog.Scenarios as Scenarios
		|where Scenarios.Ref in hierarchy ( &Scenario )
		|union all
		|select &Scenario";
		q = new Query ( s );
		q.SetParameter ( "Scenario", Scenario );
		table = q.Execute ().Unload ();
	else
		table = new ValueTable ();
		table.Columns.Add ( "Ref", new TypeDescription ( "CatalogRef.Scenarios" ) );
		row = table.Add ();
		row.Ref = Scenario;
	endif;
	return table;
	
EndFunction

Function updateScenario ( Scenario, Data, Context, Error )
	
	obj = Scenario.GetObject ();
	ext = Context.Extension;
	if ( ext = RepositoryFiles.MXLFile () ) then
		DataProcessors.Load.AssembleTemplate ( Data, obj );
	elsif ( ext = RepositoryFiles.JSONFile () ) then
		DataProcessors.Load.Properties ( Data, obj );
	else
		if ( obj.Script = Data ) then
			return false;
		endif;
		obj.Script = Data;
	endif;
	obj.Changed = Max ( Context.Changed, obj.Changed );
	excludeMe ( obj );
	try
		obj.Write ();
	except
		why = ErrorDescription ();
		Error = Output.WatcherUpdatingError ( new Structure ( "Error, Scenario", why, Scenario ) );
		return false;
	endtry;
	return true;
		
EndFunction

Procedure excludeMe ( Object )
	
	Object.AdditionalProperties.Insert ( "Loading", true );

EndProcedure

Function Create ( val Context, val IsFolder, Error ) export
	
	scenario = fetchScenario ( Context, Error );
	if ( Error <> undefined ) then
		return undefined;
	endif;
	parent = lockParent ( Context, Error );
	if ( Error <> undefined ) then
		return undefined;
	endif;
	if ( initScenario ( parent, scenario, Context, IsFolder, Error ) ) then
		if ( not IsFolder ) then
			changes = new Array ();
			if ( parent <> undefined ) then
				changes.Add ( parent );
			endif;
			changes.Add ( scenario );
			return changes;
		endif;
	endif;

EndFunction

Function fetchScenario ( Context, Error )

	var errors;
	
	scenario = WatcherSrv.FindScenario ( Context, true );
	if ( scenario <> undefined ) then
		LockingForm.Lock ( wrapScenario ( scenario, false ), undefined, errors );
		if ( errors <> undefined ) then
			Error = Output.LockingError ( errors [ 0 ] );
			return undefined;
		endif;
	endif;
	return scenario;

EndFunction

Function lockParent ( Context, Error )
	
	var errors;
	
	path = Left ( Context.Path, StrFind ( Context.Path, ".", SearchDirection.FromEnd ) - 1 );
	if ( path = "" ) then
		return undefined;
	endif;
	parent = RuntimeSrv.FindScenario ( path, Context.Application, undefined, undefined, true );
	if ( parent = undefined ) then
		Error = Output.WatcherParentNotFound ( new Structure ( "File", Context.File ) );
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( parent, false ), undefined, errors );
	if ( errors <> undefined ) then
		Error = Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	return parent;

EndFunction

Function initScenario ( Parent, Scenario, Context, IsFolder, Error )
	
	if ( Scenario = undefined ) then
		obj = Catalogs.Scenarios.CreateItem ();
		obj.Description = RepositoryFiles.FileToName ( Context.File );
		obj.Parent = Parent;
		obj.Script = "";
		obj.Application = Context.Application;
		obj.Creator = SessionParameters.User;
		obj.Users.Clear ();
		DataProcessors.Load.ResetTemplate ( obj );
		if ( IsFolder ) then
			obj.Type = Enums.Scenarios.Folder;
			obj.Tree = true;
		else
			obj.Type = Enums.Scenarios.Scenario;
		endif;
		obj.Changed = Context.Changed;
		excludeMe ( obj );
		try
			obj.Write ();
		except
			why = ErrorDescription ();
			Error = Output.WatcherCreatingError ( new Structure ( "Error, Parent, File", why, Parent, Context.File ) );
			return false;
		endtry;
	else
		if ( DF.Pick ( Scenario, "DeletionMark" ) ) then
			obj = Scenario.GetObject ();
			excludeMe ( obj );
			try
				obj.SetDeletionMark ( false );
				obj.Changed = Context.Changed;
				obj.Write ();
			except
				why = ErrorDescription ();
				Error = Output.WatcherRestorationError ( new Structure ( "Error, Scenario, File", why, scenario, Context.File ) );
				return false;
			endtry;
		endif;
	endif;
	return true;
	
EndFunction

Function GetMethods ( val Starting ) export
	
	table = getScenarios ( Starting );
	result = new Array ();
	for each row in table do
		result.Add ( new Structure ( "Path, Application", row.Path, row.Application ) );
	enddo;
	return result;
	
EndFunction

Function getScenarios ( Starting )
	
	q = new Query ();
	s = "
	|select allowed Scenarios.Path as Path,
	|	isnull ( Scenarios.Application.Description, &Common ) as Application
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Type = value ( Enum.Scenarios.Method )
	|";
	if ( Starting <> undefined ) then
		s = s + "
		|and Scenarios.Parent in hierarchy ( &Folder )";
		q.SetParameter ( "Folder", DF.Pick ( Starting, "Parent" ) );
	endif;
	s = s + "
	|order by Path, Application
	|";
	q.Text = s;
	q.SetParameter ( "Common", Output.CommonApplicationName () );
	return q.Execute ().Unload ();
	
EndFunction

Function Rename ( val Context, val NewFile, val NewPath, val IsFolder, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario(Context);
	if (scenario = undefined) then
		scenario = RuntimeSrv.FindScenario ( NewPath, Context.Application, undefined, undefined, true );
		alreadyRenamed = scenario <> undefined; 
		if ( alreadyRenamed ) then
			return scenario;
		else
			Error = Output.UndefinedScenario(new Structure("File", Context.File));
			return undefined;
		endif;
	endif;
	LockingForm.Lock ( wrapScenario ( Scenario, true ), undefined, errors );
	if ( errors <> undefined ) then
		Output.LockingError ( errors [ 0 ] );
		return undefined;
	endif;
	if ( renameScenario ( scenario, NewFile, IsFolder, Error ) ) then
		return scenario;
	endif;

EndFunction

Function renameScenario ( Scenario, NewFile, IsFolder, Error )
	
	obj = Scenario.GetObject ();
	obj.AdditionalProperties.Insert ( "AlreadyRemoved", true );
	obj.Description = RepositoryFiles.FileToName ( NewFile );
	excludeMe ( obj );
	try
		obj.Write ();
	except
		why = ErrorDescription ();
		Error = Output.WatcherRenamingError ( new Structure ( "Error, Scenario, File", why, Scenario, NewFile ) );
		return false;
	endtry;
	return true;
		
EndFunction

Function Remove ( val Context, Error ) export
	
	var errors;
	
	scenario = WatcherSrv.FindScenario ( Context, true );
	if ( scenario = undefined ) then
		if ( Context.Extension = RepositoryFiles.JSONFile () ) then
			Error = Output.UndefinedScenario ( new Structure ( "File", Context.File ) );
		endif;
		return undefined;
	endif;
	LockingForm.Lock ( wrapScenario ( scenario, true ), undefined, errors );
	if ( errors <> undefined ) then
		Output.LockingError ( errors [ 0 ] );
		return undefined;		
	endif;
	if ( removeScenario ( scenario, Context, Error ) ) then
		return scenario;
	endif;
	
EndFunction

Function removeScenario ( Scenario, Context, Error )
	
	obj = Scenario.GetObject ();
	obj.AdditionalProperties.Insert ( "AlreadyRemoved", true );
	excludeMe ( obj );
	extension = Context.Extension;
	if ( extension = RepositoryFiles.MXLFile () ) then
		DataProcessors.Load.ResetTemplate ( obj );
		try
			obj.Write ();
		except
			why = ErrorDescription ();
			Error = Output.WatcherTemplateRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
			return false;
		endtry;
	elsif ( extension = RepositoryFiles.BSLFile () ) then
		obj.Script = "";
		try
			obj.Write ();
		except
			why = ErrorDescription ();
			Error = Output.WatcherScriptRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
			return false;
		endtry;
	elsif ( not obj.DeletionMark ) then
		try
			obj.SetDeletionMark ( true );
		except
			why = ErrorDescription ();
			Error = Output.WatcherRemovingError ( new Structure ( "Error, Scenario", why, Scenario ) );
			return false;
		endtry;
	endif;
	return true;
		
EndFunction