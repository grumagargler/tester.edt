Procedure Reset ( Node ) export
	
	SetPrivilegedMode ( true );
	set = Metadata.FindByType ( TypeOf ( Node ) ).Content;
	for each item in set do
		ExchangePlans.RecordChanges ( Node, item.Metadata );
	enddo;
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure EnrollUser ( User ) export
	
	SetPrivilegedMode ( true );
	code = User.Code;
	description = User.Description;
	ref = User.Ref;
	for each application in getApplications () do
		name = application.Name;
		node = ExchangePlans.Changes.CreateNode ();
		node.Code = nodeCode ( code, application.Code );
		node.Description = nodeName ( description, name );
		node.User = ref;
		node.Application = application.Ref;
		node.Write ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getApplications ()
	
	s = "
	|select Applications.Ref as Ref, Applications.Description as Name, Applications.Code as Code
	|from Catalog.Applications as Applications
	|where not Applications.DeletionMark
	|and not Applications.IsFolder
	|union all
	|select value ( Catalog.Applications.EmptyRef ), &Name, &Code
	|";
	q = new Query ( s );
	q.SetParameter ( "Name", Output.CommonApplicationName () );
	q.SetParameter ( "Code", Output.CommonApplicationCode () );
	return q.Execute ().Unload ();
	
EndFunction 

Function nodeCode ( UserCode, ApplicationCode )
	
	return TrimAll ( UserCode ) + TrimAll ( ApplicationCode );
	
EndFunction 

Function nodeName ( User, Application )
	
	return User + ": " + Application;
	
EndFunction 

Procedure EnrollApplication ( Application ) export
	
	SetPrivilegedMode ( true );
	code = Application.Code;
	description = Application.Description;
	ref = Application.Ref;
	for each user in getUsers () do
		node = ExchangePlans.Changes.CreateNode ();
		node.Code = nodeCode ( user.Code, code );
		node.Description = nodeName ( user.Name, description );
		node.User = user.Ref;
		node.Application = ref;
		node.Write ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getUsers ()
	
	s = "
	|select Users.Ref as Ref, Users.Description as Name, Users.Code as Code
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and not Users.IsFolder
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure Mark ( Scenario, ExceptMe ) export
	
	SetPrivilegedMode ( true );
	destination = Scenario.DataExchange.Recipients;
	for each node in applicationNodes ( Scenario, ExceptMe ) do
		destination.Add ( node );
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function applicationNodes ( Scenario, ExceptMe )
	
	s = "
	|select Nodes.Ref as Ref
	|from ExchangePlan.Changes as Nodes
	|where not Nodes.DeletionMark
	|and Nodes.User <> value ( Catalog.Users.EmptyRef )
	|and Nodes.Application = &Application
	|and not Nodes.ThisNode
	|";
	if ( ExceptMe ) then
		s = s + "
		|and Nodes.User <> &User
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Application", Scenario.Application );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

Procedure MarkDeletion ( User ) export
	
	SetPrivilegedMode ( true );
	for each node in userNodes ( User ) do
		node.GetObject ().SetDeletionMark ( true );
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function userNodes ( User )
	
	s = "
	|select Nodes.Ref as Ref
	|from ExchangePlan.Changes as Nodes
	|where not Nodes.DeletionMark
	|and Nodes.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", User );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 
