// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	RightsTree.FillRights ( ThisObject );
	fillUserGroups ();
	fillActualRights ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillUserGroups ()
	
	s = "
	|select UserGroups.Ref as UserGroup,";
	if ( Object.Ref.IsEmpty () ) then
		s = s + "case when UserGroups.Ref = value ( Catalog.UserGroups.Users ) then true else false end as Use";
	else
		s = s + "case when SelectedGroups.UserGroup is null then false else true end as Use";
	endif; 
	s = s + "
	|from Catalog.UserGroups as UserGroups
	|	//
	|	// SelectedGroups
	|	//
	|	left join InformationRegister.UsersAndGroups as SelectedGroups
	|	on SelectedGroups.UserGroup = UserGroups.Ref
	|	and SelectedGroups.User = &Ref
	|where not UserGroups.DeletionMark
	|order by UserGroups.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Tables.UserGroups.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtServer
Procedure fillActualRights ()
	
	env = RightsTree.GetEnv ( ThisObject );
	RightsTree.PrepareRightsTable ( env );
	getSelectedRights ( env );
	addRolesToArray ( env );
	fillRightsByGroups ( env, Tables.UserGroups.Unload () );
	RightsTree.FillRightsTable ( env );
	RightsTree.SetCheckboxesForGroups ( Env.RightsTable.Rows );
	deleteUnusedRows ( Env.RightsTable.Rows );
	ValueToFormAttribute ( Env.RightsTable, "ActualAccess" );
	
EndProcedure

&AtServer
Procedure getSelectedRights ( Env )
	
	Env.Insert ( "SelectedRights", new Array () );
	
EndProcedure 

&AtServer
Procedure addRolesToArray ( Env )
	
	rightsValueTree = FormDataToValue ( Env.Form.Rights, Type ( "ValueTree" ) );
	list = Env.SelectedRights;
	for each groupRow in rightsValueTree.Rows do
		if ( groupRow.Use = 0 ) then
			continue;
		endif;
		for each row in groupRow.Rows do
			if ( row.Use = 1 ) then
				list.Add ( row.roleName );
			endif;
		enddo;
	enddo;	
		
EndProcedure

&AtServer
Procedure deleteUnusedRows ( Groups )
	
	count = Groups.Count();
	for i = 1 to count do
		row = Groups [ count - i ];
		if ( row.use = 0 ) then
			Groups.Delete ( row );
		else
			deleteUnusedRows ( row.rows );
		endif;
	enddo; 
	
EndProcedure

&AtServer
Procedure fillRightsByGroups ( Env, Groups );
	
	usedGroups = getUsedGroups ( Groups );
	groupRoles = getRolesByGroups ( usedGroups );
	list = Env.SelectedRights;
	for each role in groupRoles do
		if ( not RightsTree.InRole( Env, role ) ) then
			list.Add ( role );
		endif;
	enddo;
	
EndProcedure

&AtServer
Function getUsedGroups ( Groups )
	
	usedGroupsArray = new array;
	usedGroups = Groups.FindRows ( new Structure ( "Use", true ) );
	for each usedGroup in usedGroups do
		usedGroupsArray.Add ( usedGroup.UserGroup );
	enddo;
	return usedGroupsArray;
	
EndFunction

&AtServer
Function getRolesByGroups ( Groups )
	
	q = new Query ( "select RoleName as RoleName from Catalog.UserGroups.Rights where Ref in ( &Groups )" );
	q.SetParameter ( "Groups", Groups );
	return q.Execute ().Unload ().UnloadColumn ( "RoleName" );
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setAdministrator ();
	fillTimeZones ();
	if ( Object.Ref.IsEmpty () ) then
		setCurrentTimeZone ();
		fillUserGroups ();
		RightsTree.FillRights ( ThisObject );
		fillActualRights ();
	endif; 
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure setAdministrator ()
	
	Administrator = IsInRole ( "Administrator" );
	
EndProcedure 

&AtServer
Procedure fillTimeZones ()
	
	timeZones = GetAvailableTimeZones ();
	for each timeZone in timeZones do
		Items.TimeZone.ChoiceList.Add ( timeZone, timeZone + " (" + TimeZonePresentation ( timeZone ) + ")" );
	enddo; 
	
EndProcedure 

&AtServer
Procedure setCurrentTimeZone ()
	
	currentTimeZone = GetInfoBaseTimeZone ();
	Object.TimeZone = ? ( currentTimeZone = undefined, TimeZone (), currentTimeZone );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageUserGroupCreated () ) then
		fillAccess ();
		expandTree ();
	elsif (	EventName = Enum.MessageUserGroupModified () ) then
		fillActualRights ();
		expandTree ();
	elsif ( EventName = Enum.MessageUserRightsChanged () ) then
		updateRights ( Parameter );
		expandTree ();
	endif; 
	
EndProcedure

&AtServer
Procedure fillAccess ()
	
	fillUserGroups ();
	fillActualRights ();
	
EndProcedure

&AtServer
Procedure updateRights ( val Address ) export
	
	table = GetFromTempStorage ( Address );
	ValueToFormData ( table, Rights );
	RightsTree.FillChanges ( ThisObject );
	fillActualRights ();
	
EndProcedure

&AtClient
Procedure expandTree ()
	
	RightsTree.Expand ( ThisObject, "ActualAccess" );

EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkUsersName () ) then
		Cancel = true;
	endif; 
	if ( not checkRights () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkUsersName ()
	
	user = Catalogs.Users.FindByDescription ( Object.Description );
	error = not user.IsEmpty () and ( user <> Object.Ref );
	if ( error ) then
		Output.UserNameAlreadyExists ( , "Description" );
	endif; 
	return not error;
	
EndFunction 

&AtServer
Function checkRights ()
	
	groupsSelected = Tables.UserGroups.FindRows ( new Structure ( "Use", true ) ).Count () > 0;
	if ( groupsSelected ) then
		return true;	
	else
		error = not RightsTree.FillCheck ( ThisObject );
		if ( error ) then
			if ( Tables.UserGroups.Count () = 0 ) then
				Output.SelectAccessRights ( , "Rights", , "" );
			else
				Output.SelectUsersGroup ( , "Tables.UserGroups", , "" );
			endif; 
		endif; 
		return not error;
	endif;
	
EndFunction 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	setProperties ( CurrentObject );
	serializeRights ( CurrentObject );
	
EndProcedure

&AtServer
Procedure setProperties ( CurrentObject )
	
	p = CurrentObject.AdditionalProperties;
	if ( SetNewPassword ) then
		p.Insert ( "Password", Password );
	endif; 
	p.Insert ( "UserGroups", Tables.UserGroups.Unload () );
	
EndProcedure 

&AtServer
Procedure serializeRights ( CurrentObject )
	
	RightsAugmented = false;
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	if ( Object.Agent ) then
		role = Metadata.Roles.JobsUse.Name;
		table = CurrentObject.Rights;
		if ( table.Find ( role ) = undefined ) then
			RightsAugmented = true;
			row = table.Add ();
			row.RoleName = role;
		endif;
	endif;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( RightsAugmented ) then
		RightsTree.FillRights ( ThisObject );
		fillActualRights ();
	endif;
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( RightsAugmented ) then
		expandTree ();
	endif;
	
EndProcedure

// *****************************************
// *********** Page User

&AtClient
Procedure DescriptionOnChange ( Item )
	
	adjustLogin ();
	setFirstName ();
	Object.Code = Conversion.NameToCode ( Object.Description, 3 );
	
EndProcedure

&AtClient
Procedure adjustLogin ()
	
	Object.Description = TrimAll ( Object.Description );
	
EndProcedure 

&AtClient
Procedure setFirstName ()
	
	Object.FirstName = Object.Description;
	
EndProcedure 

&AtClient
Procedure SetNewPasswordOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "SetNewPassword" );
	
EndProcedure

// *****************************************
// *********** Page Rights

&AtClient
Procedure MarkAllGroups ( Command )
	
	markRows ( true );
	fillActualRights ();
	expandTree ();
	
EndProcedure

Procedure markRows ( Check )
	
	for each item in Tables.UserGroups do
		item.Use = Check;
	enddo; 
	
EndProcedure

&AtClient
Procedure UnmarkAllGroups ( Command )
	
	markRows ( false );
	fillActualRights ();
	expandTree ();
	
EndProcedure

&AtClient
Procedure UsersGroupsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure UsersGroupsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure UsersGroupsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openSeletedUserGroup ( Item );
	
EndProcedure

&AtClient
Procedure openSeletedUserGroup ( Item )
	
	ShowValue ( , Item.CurrentData.UserGroup );
	
EndProcedure 

&AtClient
Procedure EditRights ( Command )
	
	openEditor ();
	
EndProcedure

&AtClient
Procedure openEditor ()
	
	p = new Structure ();
	p.Insert ( "UserRights", storeRights () );
	OpenForm ( "Catalog.Users.Form.Rights", p, ThisObject );
	
EndProcedure 

&AtServer
Function storeRights ()
	
	return PutToTempStorage ( FormDataToValue ( Rights, Type ( "ValueTree" ) ) );

EndFunction
	
&AtClient
Procedure UsersGroupsUseOnChange ( Item )
	
	fillActualRights ();
	expandTree ();
	
EndProcedure

// *****************************************
// *********** Page Applications

&AtClient
Procedure ApplicationAccessOnChange ( Item )
	
	adjustAccess ( "Applications" );
	Appearance.Apply ( ThisObject, "Object.ApplicationsAccess" );
	
EndProcedure

&AtClient
Procedure adjustAccess ( Class )
	
	if ( Class = "Applications" ) then
		access = Object.ApplicationsAccess;
		table = Object.Applications;
	endif; 
	if ( access = PredefinedValue ( "Enum.Access.Undefined" ) ) then
		table.Clear ();
	endif;
	
EndProcedure 

// *****************************************
// *********** Page Agent

&AtClient
Procedure AgentOnChange ( Item )
	
	applyAgent ();
	
EndProcedure

&AtClient
Procedure applyAgent ()
	
	if ( not Object.Agent ) then
		Object.Managers.Clear ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.Agent" );
	
EndProcedure 
