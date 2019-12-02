
Function AccessDenies () export
	
	SetPrivilegedMode ( true );
	return DF.Pick ( SessionParameters.User, "AccessDenied" );
	
EndFunction 

Procedure Init () export
	
	SetPrivilegedMode ( true );
	user = Catalogs.Users.CreateItem ();
	user.Email = "user@domain.com";
	name = Output.UserAdmin ();
	user.FirstName = name;
	user.Description = name;
	user.Code = "ADM";
	user.Language = CurrentLanguage ().Name;
	user.TimeZone = TimeZone ();
	user.ApplicationsAccess = Enums.Access.Undefined;
	right = user.Rights.Add ();
	right.RoleName = "Administrator";
	user.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Function CanEditScenarios () export
	
	return AccessRight ( "Edit", Metadata.Catalogs.Scenarios );
	
EndFunction 
