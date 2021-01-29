&AtClient
var IsNew;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	RightsRelations = RightsTree.FillRights ( ThisObject );
	RightsConfirmed = true;
	fillUsers ();
	
EndProcedure

&AtServer
Procedure fillUsers ()
	
	s = "
	|select UsersAndGroups.User as User
	|from InformationRegister.UsersAndGroups as UsersAndGroups
	|where UsersAndGroups.UserGroup = &Ref
	|order by UsersAndGroups.User.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Tables.Users.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		RightsRelations = RightsTree.FillRights ( ThisObject );
		RightsConfirmed = true;
	endif; 
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	IsNew = Object.Ref.IsEmpty ();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkRights () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkRights ()
	
	if ( not RightsConfirmed ) then
		Output.ConfirmAccessRights ( , "RightsChanges", , "" );
		return false;
	endif;	
	error = not RightsTree.FillCheck ( ThisObject );
	if ( error ) then
		Output.SelectAccessRights ( , "Rights", , "" );
	endif; 
	return not error;
	
EndFunction 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	getUsersTable ();
	setProperties ( CurrentObject );
	
EndProcedure

&AtServer
Procedure setProperties ( CurrentObject )
	
	CurrentObject.AdditionalProperties.Insert ( "SelectedUsers", getUsersTable () );
	
EndProcedure 

&AtServer
Function getUsersTable ()
	
	selectedUsers = Tables.Users.Unload ();
	selectedUsers.GroupBy ( "User" );
	return selectedUsers;
	
EndFunction

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( IsNew ) then
		Notify ( Enum.MessageUserGroupCreated () );
		IsNew = false;
	endif; 
	Notify ( Enum.MessageUserGroupModified () );
	
EndProcedure

// *****************************************
// *********** Group Rights

&AtClient
Procedure MarkAllRights ( Command )
	
	RightsTree.MarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure UnmarkAllRights ( Command )
	
	RightsTree.UnmarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure ConfirmRights ( Command )
	
	RightsConfirmed = true;
	RightsTree.HideConfirmation ( ThisObject );	
	
EndProcedure

&AtClient
Procedure RevertRights ( Command )	
	
	RightsConfirmed = true;
	RightsTree.RevertRights ( ThisObject );
	
EndProcedure

&AtClient
Procedure Help ( Command )
	
	Output.RightsConfirmation ();
	
EndProcedure

&AtClient
Procedure RightsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsUseOnChange ( Item )
	
	if ( RightsTree.UseChanged ( ThisObject ) ) then
		showChanges ();	
		RightsTree.Expand ( ThisObject );
	endif;
	
EndProcedure

&AtServer
Procedure showChanges ()
	
	RightsConfirmed = false;
	RightsTree.FillChanges ( ThisObject );
	RightsTree.ShowConfirmation ( ThisObject );
	
EndProcedure
