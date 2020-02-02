
Procedure SessionParametersSetting ( Params )
	
	if ( Params = undefined ) then
		return;
	endif; 
	for each parameter in Params do
		if ( parameter = "User" ) then
			setUser ();
		elsif ( parameter = "Session" ) then
			setSession ();
		elsif ( parameter = "Connection" ) then
			setConnection ();
		elsif ( parameter = "ApplicationsAccess" ) then
			setApplicationsAccess ();
		elsif ( parameter = "ApplicationsList" ) then
			setApplicationsList ();
		endif;
	enddo; 
	
EndProcedure

Procedure setUser ()
	
	currentUser = Catalogs.Users.FindByDescription ( UserName () );
	SessionParameters.User = currentUser;
	
EndProcedure 

Procedure setSession ()
	
	EnvironmentSrv.SetSession ( ComputerName () );
	
EndProcedure 

Procedure setConnection ()
	
	EnvironmentSrv.SetConnection ( false, false, false, false );
	
EndProcedure 

Procedure setApplicationsAccess ()
	
	SessionParameters.ApplicationsAccess = DF.Pick ( SessionParameters.User, "ApplicationsAccess" );
	
EndProcedure 

Procedure setApplicationsList ()
	
	s = "
	|select distinct Access.Application as Application
	|from Catalog.Users.Applications as Access
	|where Access.Ref = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	SessionParameters.ApplicationsList = new FixedArray ( q.Execute ().Unload ().UnloadColumn ( "Application" ) );
	
EndProcedure 
