
Procedure ChangePassword ( NewPassword ) export
	
	SetPrivilegedMode ( true );
	name = UserName ();
	user = InfoBaseUsers.FindByName ( name );
	user.Password = NewPassword;
	user.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure SetRights ( User ) export
	
	roles = getUserRoles ( User.Name );
	assingRoles ( User, roles );
	
EndProcedure 

Function getUserRoles ( UserName )
	
	s = "
	|select Rights.RoleName as RoleName
	|from Catalog.Users.Rights as Rights
	|where Rights.Ref = &User
	|union
	|select Rights.RoleName
	|from Catalog.UserGroups.Rights as Rights
	|	//
	|	// UsersAndGroups
	|	//
	|	join InformationRegister.UsersAndGroups as UsersAndGroups
	|	on UsersAndGroups.User = &User
	|	and UsersAndGroups.UserGroup = Rights.Ref
	|where not Rights.Ref.DeletionMark
	|";
	q = new Query ( s );
	user = Catalogs.Users.FindByDescription ( UserName, true );
	q.SetParameter ( "User", user );
	return q.Execute ().Unload ().UnloadColumn ( "RoleName" );
	
EndFunction 

Procedure assingRoles ( User, Roles )
	
	userRoles = User.Roles;
	userRoles.Clear ();
	userRoles.Add ( Metadata.Roles.User );
	for each roleName in Roles do
		role = Metadata.Roles.Find ( roleName );
		if ( role <> undefined ) then
			userRoles.Add ( role );
		endif; 
	enddo; 
	
EndProcedure 

Procedure Remove ( UserName ) export
	
	user = InfoBaseUsers.FindByName ( UserName );
	if ( user = undefined ) then
		return;
	endif; 
	user.Delete ();
	
EndProcedure 

Function LastAdministrator () export
	
	if ( findAdmin () ) then
		return false;
	endif;
	Output.AdministratorNotFound ();
	return true;
	
EndFunction 

Function findAdmin ()
	
	s = "
	|select top 1 1
	|from Catalog.Users.Rights as Rights
	|where Rights.RoleName = ""Administrator""
	|and not Rights.Ref.DeletionMark
	|and not Rights.Ref.AccessDenied
	|union
	|select top 1 1
	|from Catalog.UserGroups.Rights as Rights
	|	//
	|	// UsersAndGroups
	|	//
	|	join InformationRegister.UsersAndGroups as UsersAndGroups
	|	on UsersAndGroups.UserGroup = Rights.Ref
	|	and not UsersAndGroups.User.DeletionMark
	|	and not UsersAndGroups.User.AccessDenied
	|where Rights.RoleName = ""Administrator""
	|and not Rights.Ref.DeletionMark
	|";
	q = new Query ( s );
	found = not q.Execute ().IsEmpty ();
	return found;
	
EndFunction

Procedure SaveSettings ( ObjectKey, SettingsKey = undefined, Settings ) export
	
	if ( AccessRight ( "SaveUserData", Metadata ) ) then
		CommonSettingsStorage.Save ( ObjectKey, SettingsKey, Settings );
	endif; 
	
EndProcedure
