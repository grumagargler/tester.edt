&AtClient
var TableRow export;
&AtClient
var ApplicationIndex;
&AtClient
var ApplicationLastIndex;
&AtClient
var FilesIndex;
&AtClient
var FilesLastIndex;
&AtClient
var FilesArray;
&AtClient
var CurrentFile;
&AtClient
var CurrentExtension;
&AtClient
var CurrentObjectName;
&AtClient
var ChangedRepositories;
&AtClient
var ChangedScenarios;
&AtClient
var PathBegins;
&AtClient
var FolderSuffix;
&AtClient
var Slash;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadRepositories ();
	
EndProcedure

&AtServer
Procedure loadRepositories ()
	
	s = "select allowed Repositories.Application as Application, Repositories.Folder as Folder,
	|	case when Settings.Application is null then false else true end as Use
	|from ExchangePlan.Repositories as Repositories
	|	//
	|	// Settings
	|	//
	|	left join InformationRegister.Applications as Settings
	|	on Settings.User = &User
	|	and Settings.Application = Repositories.Application
	|where Repositories.Session = &Session
	|and not Repositories.DeletionMark
	|order by Application";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Session", SessionParameters.Session );
	Object.Repositories.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	setConstants ();
	RepositoryForm.SetFocus ( ThisObject );
	LocalFiles.Prepare ();

EndProcedure

&AtClient
Procedure setConstants ()
	
	Slash = GetPathSeparator ();
	FolderSuffix = RepositoryFiles.FolderSuffix ();
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not RepositoryForm.CheckSelection ( Object ) ) then
		Cancel = true;
	endif; 
	if ( not RepositoryForm.CheckFolders ( Object ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Load ( Command )
	
	if ( CheckFilling () ) then
		init ();
		loadApplications ();
	endif; 
		
EndProcedure

&AtClient
Procedure init ()
	
	ApplicationIndex = -1;
	ApplicationLastIndex = Object.Repositories.Count () - 1;
	ChangedRepositories = new Array ();
	
EndProcedure 

&AtClient
Procedure loadApplications ()
	
	ApplicationIndex = ApplicationIndex + 1;
	if ( ApplicationIndex > ApplicationLastIndex ) then
		openChanges ();
		return;
	endif; 
	repo = Object.Repositories [ ApplicationIndex ];
	folder = repo.Folder;
	if ( repo.Use ) then
		ChangedScenarios = new Array ();
		PathBegins = StrLen ( folder ) + 2;
		ChangedRepositories.Add ( new Structure ( "Application, Changes", repo.Application, ChangedScenarios ) );
	else
		loadApplications ();
		return;
	endif; 
	BeginFindingFiles ( new NotifyDescription ( "FindingFiles", ThisObject ), folder, "*.*", true );
	
EndProcedure 

&AtClient
Procedure openChanges ()
	
	OpenForm ( "DataProcessor.Load.Form.Changes", new Structure ( "Changes", ChangedRepositories ), ThisObject, , , , new NotifyDescription ( "AfterApplyingChanges", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure AfterApplyingChanges ( Result, Params ) export
	
	if ( Result <> undefined
		and Result ) then
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure FindingFiles ( Files, Params ) export
	
	FilesIndex = -1;
	FilesLastIndex = Files.Count () - 1;
	FilesArray = Files;
	loadFiles ();
	
EndProcedure 

&AtClient
Procedure loadFiles ()
	
	while ( true ) do
		FilesIndex = FilesIndex + 1;
		if ( FilesIndex > FilesLastIndex ) then
			loadApplications ();
			return;
		endif; 
		CurrentFile = FilesArray [ FilesIndex ];
		CurrentExtension = CurrentFile.Extension;
		CurrentObjectName = RepositoryFiles.FileToName ( CurrentFile.Name );
		if ( validFile () ) then
			CurrentFile.BeginGettingModificationUniversalTime ( new NotifyDescription ( "GettingModificationUniversalTime", ThisObject ) );
			return;
		endif; 
	enddo;
	
EndProcedure 

&AtClient
Function validFile ()
	
	return CurrentExtension = RepositoryFiles.BSLFile ()
	or CurrentExtension = RepositoryFiles.MXLFile ()
	or CurrentExtension = RepositoryFiles.JSONFile ();
	
EndFunction 

&AtClient
Procedure GettingModificationUniversalTime ( Time, Params ) export
	
	enrollChanges ( Time );
	loadFiles ();
	
EndProcedure 

&AtClient
Procedure enrollChanges ( UTC )
	
	p = new Structure ();
	p.Insert ( "Path", RepositoryFiles.FileToPath ( CurrentFile.FullName, PathBegins ) );
	p.Insert ( "File", FileSystem.GetBaseName ( CurrentFile.FullName ) );
	p.Insert ( "Extension", CurrentExtension );
	p.Insert ( "UTC", UTC );
	ChangedScenarios.Add ( p );
	
EndProcedure 

// *****************************************
// *********** Table Repositories

&AtClient
Procedure MarkAll ( Command )
	
	checkbox ( true );
	
EndProcedure

&AtClient
Procedure checkbox ( Value )
	
	for each row in Object.Repositories do
		row.Use = Value;
	enddo; 
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( Command )
	
	checkbox ( false );
	
EndProcedure

&AtClient
Procedure RepositoriesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ReporitoriesFolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	RepositoryForm.ChooseFolder ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReporitoriesFolderOnChange ( Item )
	
	RepositoryForm.ApplyFolder ( ThisObject );
	
EndProcedure

&AtClient
Procedure RepositoriesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RepositoriesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
