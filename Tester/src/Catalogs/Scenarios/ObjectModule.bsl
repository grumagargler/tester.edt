var IsNew export;
var OldParent;
var OldApplication export;
var OldDeletionMark;
var OldTree;
var OldPath;
var NewPath;
var NewParent;
var ReplaceApplication export;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkAccess ( CheckedAttributes );
	
EndProcedure

Procedure checkAccess ( CheckedAttributes )
	
	if ( Access ) then
		CheckedAttributes.Add ( "Users" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	IsNew = IsNew ();
	if ( not canEdit () ) then
		Cancel = true;
		return;
	endif; 
	stamp ();
	fixApplication ();
	setPath ( ThisObject );
	setTree ();
	fixType ();
	if ( not checkDoubles () ) then
		Cancel = true;
		return;
	endif; 
	getLastProps ();
	NewPath = OldPath <> Path;
	if ( not IsNew ) then
		if ( NewPath
			or ( OldTree <> Tree )
			or ( OldApplication <> Application ) ) then
			removeFromRepo ( OldApplication, OldPath, OldTree, option ( "AlreadyRemoved" ) );
		endif; 
	endif; 
	markChanges ();
	setSorting ();
	if ( DeletionMark ) then
		removeAsMain ();
	endif; 
	
EndProcedure

Function canEdit ()
	
	if ( IsNew ) then
		return true;
	endif; 
	user = InformationRegisters.Editing.Get ( new Structure ( "Scenario", Ref ) ).User;
	if ( user = SessionParameters.User ) then
		return true;
	elsif ( user.IsEmpty () ) then
		Output.ScenarioNotLocked ( new Structure ( "Scenario", Ref ), , Ref );
	else
		Output.LockError ( new Structure ( "Scenario, User", Ref, user ), , Ref );
	endif; 
	return false;
	
EndFunction 

Function option ( Name )
	
	return AdditionalProperties.Property ( Name )
		and AdditionalProperties [ Name ];
	
EndFunction 

Procedure stamp ()
	
	if ( option ( "Restored" )
		or option ( "Loading" ) ) then
		return;
	endif; 
	Changed = CurrentUniversalDate ();
	LastCreator = SessionParameters.User;
	
EndProcedure

Procedure fixApplication ()
	
	if ( Parent.IsEmpty () ) then
		return;
	endif;
	parentApp = DF.Pick ( Parent, "Application" );
	if ( parentApp.IsEmpty ()
		or parentApp = Application ) then
		return;
	endif; 
	Application = parentApp;
	
EndProcedure 

Procedure setPath ( Object )
	
	ancestor = Object.Parent;
	if ( ancestor.IsEmpty () ) then
		Object.Path = Object.Description;
	else
		Object.Path = DF.Pick ( ancestor, "Path" ) + "." + Object.Description;
	endif; 
	
EndProcedure 

Procedure setTree ()
	
	if ( option ( "Loading" ) ) then
		return;
	endif;
	Tree = isFolder ( ThisObject ) or ( not IsNew and findChind ( Ref ) );
	
EndProcedure 

Procedure fixType ()
	
	if ( Tree
		and Type = Enums.Scenarios.Scenario ) then
		Type = Enums.Scenarios.Folder;
	endif; 
	
EndProcedure 

Function checkDoubles ()
	
	if ( doubleExists () ) then
		Output.ScenarioAlreadyExists ( new Structure ( "Name", Path ), "Description", Ref );
		return false;
	else
		return true;
	endif; 
	
EndFunction 

Function doubleExists ()
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref <> &Ref
	|and Scenarios.Application in ( &Application, value ( Catalog.Applications.EmptyRef ) )
	|and Scenarios.Path = &Path
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Application", Application );
	q.SetParameter ( "Path", Path );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

Procedure getLastProps ()
	
	OldParent = Ref.Parent;
	OldApplication = Ref.Application;
	OldDeletionMark = Ref.DeletionMark;
	OldTree = Ref.Tree;
	OldPath = Ref.Path;
	
EndProcedure 

Procedure removeFromRepo ( TargetApplication, TargetPath, TargetTree, AlreadyRemoved )
	
	SetPrivilegedMode ( true );
	uid = Ref.UUID ();
	for each repo in getRepos ( TargetApplication, AlreadyRemoved ) do
		r = InformationRegisters.Removing.CreateRecordManager ();
		r.Repository = repo;
		r.ID = uid;
		r.Path = TargetPath;
		r.Tree = TargetTree;
		r.Write ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getRepos ( Application, ExceptLocal )
	
	s = "
	|select Repositories.Ref as Ref
	|from ExchangePlan.Repositories as Repositories
	|where not Repositories.DeletionMark
	|and not Repositories.ThisNode
	|and Repositories.Application = &Application";
	if ( ExceptLocal ) then
		s = s + "
		|and Repositories.Session <> &Session
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Session", SessionParameters.Session );
	q.SetParameter ( "Application", Application );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

Procedure markChanges ()
	
	ExchangePlans.Repositories.Mark ( ThisObject, option ( "Loading" ) );
	
EndProcedure 

Procedure setSorting ()
	
	if ( Type = Enums.Scenarios.Library ) then
		Sorting = 0;
	elsif ( Type = Enums.Scenarios.Folder ) then
		Sorting = 1;
	elsif ( Type = Enums.Scenarios.Scenario ) then
		Sorting = 2;
	elsif ( Type = Enums.Scenarios.Method ) then
		Sorting = 3;
	endif;
	
EndProcedure 

Procedure removeAsMain ()
	
	SetPrivilegedMode ( true );
	for each user in getScenarioUsers () do
		r = InformationRegisters.Scenarios.CreateRecordManager ();
		r.User = user;
		r.Delete ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getScenarioUsers ()
	
	s = "
	|select Scenarios.User as User
	|from InformationRegister.Scenarios as Scenarios
	|where Scenarios.Scenario = &Scenario
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenario", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "User" );
	
EndFunction 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( IsNew ) then
		InformationRegisters.Editing.Lock ( SessionParameters.User, Ref );
	elsif ( DeletionMark <> OldDeletionMark ) then
		markVersions ( DeletionMark );
	endif; 
	NewParent = OldParent <> Parent;
	ReplaceApplication = ( OldApplication <> Application ) and not Application.IsEmpty ();
	setupLibraries ();
	moveHierarchy ();
	
EndProcedure

Procedure markVersions ( Delete )
	
	selection = Catalogs.Versions.Select ( , , new Structure ( "Scenario", Ref ) );
	while ( selection.Next () ) do
		obj = selection.GetObject ();
		obj.SetDeletionMark ( Delete );
	enddo; 
	
EndProcedure 

Procedure setupLibraries ()
	
	if ( not NewParent ) then
		return;
	endif;
	if ( not OldParent.IsEmpty () ) then
		refreshTree ( OldParent );
	endif; 
	if ( not Parent.IsEmpty () ) then
		refreshTree ( Parent );
	endif; 
	
EndProcedure 

Procedure refreshTree ( Reference )
	
	actual = isFolder ( Reference ) or findChind ( Reference );
	if ( actual <> Reference.Tree ) then
		obj = Reference.GetObject ();
		obj.Tree = actual;
		if ( option ( "Loading" ) ) then
			obj.AdditionalProperties.Insert ( "Loading", true );
		endif;
		obj.Write ();
	endif; 
	
EndProcedure 

Function isFolder ( Object )
	
	return Object.Type = Enums.Scenarios.Folder;
	
EndFunction 

Function findChind ( Ancestor )
	
	s = "
	|select top 1 1
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Parent = &Ancestor
	|and not Scenarios.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ancestor", Ancestor );
	SetPrivilegedMode ( true );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

Procedure moveHierarchy ()
	
	changePath = NewParent or NewPath;
	if ( changePath
		or ReplaceApplication ) then
	else
		return;
	endif;
	children = getChildren ();
	for each child in children do
		obj = child.GetObject ();
		if ( ReplaceApplication
			and not obj.Application.IsEmpty () ) then
			obj.Application = Application;
		endif; 
		if ( changePath ) then
			setPath ( obj );
		endif; 
		obj.Write ();
	enddo; 

EndProcedure 

Function getChildren ()
	
	s = "
	|select Scenarios.Ref as Child, Scenarios.Application as Application
	|from Catalog.Scenarios as Scenarios
	|where Scenarios.Ref in hierarchy ( &Scenario )
	|and Scenarios.Ref <> &Scenario
	|order by Child hierarchy
	|";
	q = new Query ( s );
	q.SetParameter ( "Scenario", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Child" );
	
EndFunction 

Procedure BeforeDelete ( Cancel )
	
	removeFromRepo ( Application, Path, Tree, true );
	
EndProcedure
