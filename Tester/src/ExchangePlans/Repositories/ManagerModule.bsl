Procedure Reset ( Node ) export
	
	SetPrivilegedMode ( true );
	set = Metadata.FindByType ( TypeOf ( Node ) ).Content;
	for each item in set do
		ExchangePlans.RecordChanges ( Node, item.Metadata );
	enddo;
	SetPrivilegedMode ( false );
	
EndProcedure 

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
	|select Repositories.Ref as Ref
	|from ExchangePlan.Repositories as Repositories
	|where not Repositories.DeletionMark
	|and Repositories.Application in ( &Applications )
	|and not Repositories.ThisNode
	|";
	if ( ExceptMe ) then
		s = s + "
		|and Repositories.Session <> &Session
		|";
	endif; 
	q = new Query ( s );
	applications = new Array ();
	application = Scenario.Application;
	applications.Add ( application );
	oldApplication = Scenario.OldApplication;
	if ( not Scenario.IsNew and ( application <> oldApplication ) ) then
		applications.Add ( oldApplication );
	endif;
	q.SetParameter ( "Applications", applications );
	q.SetParameter ( "Session", SessionParameters.Session );
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
	|from ExchangePlan.Repositories as Nodes
	|where not Nodes.DeletionMark
	|and Nodes.Session.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", User );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 
