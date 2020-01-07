var CurrentName;
var IsNew;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	checkApplicationsAccess ( CheckedAttributes );
	checkUsers ( CheckedAttributes );
	
EndProcedure

Procedure checkApplicationsAccess ( CheckedAttributes )
	
	if ( ApplicationsAccess = Enums.Access.Allow
		or ApplicationsAccess = Enums.Access.Forbid ) then
		CheckedAttributes.Add ( "Applications" );
	endif; 
	
EndProcedure 

Procedure checkUsers ( CheckedAttributes )
	
	if ( Agent ) then
		CheckedAttributes.Add ( "Users" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( IsFolder ) then
		return;
	endif; 
	IsNew = IsNew ();
	getCurrentName ();
	setFullName ();
	if ( DeletionMark ) then
		ExchangePlans.Repositories.MarkDeletion ( Ref );
	endif; 
	
EndProcedure

Procedure getCurrentName ()
	
	if ( IsNew ) then
		CurrentName = Description;
	else
		CurrentName = DF.Pick ( Ref, "Description" );
	endif; 
	
EndProcedure 

Procedure setFullName ()
	
	FullName = FirstName + ? ( IsBlankString ( LastName ), "", " " + LastName );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( IsFolder ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( DeletionMark ) then
		LoginsSrv.Remove ( CurrentName );
	else
		makeAccess ();
		makeProfile ();
	endif;
	if ( LoginsSrv.LastAdministrator () ) then
		Cancel = true;
		return;
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure makeAccess ()
	
	usersGroups = undefined;
	if ( not AdditionalProperties.Property ( "UserGroups", usersGroups ) ) then
		return;
	endif; 
	recordset = InformationRegisters.UsersAndGroups.CreateRecordSet ();
	recordset.Filter.User.Set ( Ref );
	for each row in usersGroups do
		if ( not row.Use ) then
			continue;
		endif; 
		movement = recordset.Add ();
		movement.UserGroup = row.UserGroup;
		movement.User = Ref;
	enddo; 
	recordset.Write ();
	
EndProcedure 

Procedure makeProfile ()
	
	user = getIBUser ();
	setProfile ( user );
	LoginsSrv.SetRights ( user );
	user.Write ();
	
EndProcedure 

Function getIBUser ()
	
	user = InfoBaseUsers.FindByName ( CurrentName );
	if ( user = undefined ) then
		user = InfoBaseUsers.CreateUser ();
	endif;
	return user;
	
EndFunction

Procedure setProfile ( User )
	
	User.Name = Description;
	User.FullName = FullName;
	User.Language = Metadata.Languages.Find ( Language );
	password = undefined;
	if ( AdditionalProperties.Property ( "Password", password ) ) then
		User.Password = password;
	endif; 
	
EndProcedure 
