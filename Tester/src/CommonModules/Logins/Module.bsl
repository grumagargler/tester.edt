
Function AccessDenies () export
	
	SetPrivilegedMode ( true );
	return DF.Pick ( SessionParameters.User, "AccessDenied" );
	
EndFunction 

Procedure Init () export
	
	SetPrivilegedMode ( true );
	name = Output.UserAdmin ();
	user = Catalogs.Users.FindByDescription ( name );
	if ( user.IsEmpty () ) then
		user = Catalogs.Users.CreateItem ();
		user.Email = "user@domain.com";
		user.FirstName = name;
		user.Description = name;
		user.Code = "ADM";
		user.Language = CurrentLanguage ().Name;
		user.TimeZone = TimeZone ();
		user.ApplicationsAccess = Enums.Access.Undefined;
	else
		user = user.GetObject ();
	endif;
	if ( user.Rights.Find ( "Administrator", "RoleName" ) = undefined ) then
		right = user.Rights.Add ();
		right.RoleName = "Administrator";
	endif;
	user.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Function CanEditScenarios () export
	
	return AccessRight ( "Edit", Metadata.Catalogs.Scenarios );
	
EndFunction 
