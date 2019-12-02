Function MappedApplications () export
	
	table = getFolders ();
	result = new Structure ();
	result.Insert ( "Applications", table.UnloadColumn ( "Application" ) );
	result.Insert ( "Folders", table.UnloadColumn ( "Folder" ) );
	return result;
	
EndFunction

Function getFolders ()
	
	s = "
	|select allowed Repositories.Application as Application, Repositories.Folder as Folder
	|from InformationRegister.Repositories as Repositories
	|where Repositories.User = &User
	|and Repositories.Computer = &Computer
	|and Repositories.Mapping
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Computer", SessionData.Computer () );
	return q.Execute ().Unload ();
	
EndFunction

Function Update ( val Scenario, val Script ) export
	
	var errors;
	
	LockingForm.Lock ( wrapScenario ( Scenario ), undefined, errors );
	if ( errors = undefined ) then
		return updateScript ( Scenario, Script );
	endif;
	Output.LockError ( errors [ 0 ] );
	return false;
	
EndFunction

Function wrapScenario ( Scenario )
	
	table = new ValueTable ();
	table.Columns.Add ( "Ref", new TypeDescription ( "CatalogRef.Scenarios" ) );
	row = table.Add ();
	row.Ref = Scenario;
	return table;
	
EndFunction

Function updateScript ( Scenario, Script )
	
	obj = Scenario.GetObject ();
	if ( obj.Script = Script ) then
		return false;
	endif;
	obj.Script = Script;
	excludeMe ( obj );
	obj.Write ();
	return true;
		
EndFunction

Procedure excludeMe ( Object )
	
	Object.DataExchange.Sender = findMe ( Object );

EndProcedure

Function findMe ( Object )
	
	s = "
	|select Nodes.Ref as Ref
	|from ExchangePlan.Changes as Nodes
	|where not Nodes.DeletionMark
	|and Nodes.User = &User
	|and Nodes.Application = &Application
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Application", Object.Application );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
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
