&AtClient
var ControlPosition;
&AtClient
var FieldsMap;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	applyParams ();
	initList ();
	ScenarioForm.InitPort ( Items.Port );
	filterByMetadata ();
	setRetrieving ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	MetadataFilter = Catalogs.Metadata.Ref ( Parameters.Form );
	
EndProcedure 

&AtServer
Procedure applyParams ()
	
	if ( Parameters.SelectOnly ) then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		Items.GroupScript.Visible = false;
	endif; 
	
EndProcedure 

&AtServer
Procedure initList ()
	
	DC.SetParameter ( List, "User", SessionParameters.User );
	DC.SetParameter ( List, "Application", Parameters.Application );
	
EndProcedure 

&AtServer
Procedure filterByMetadata ()
	
	DC.ChangeFilter ( List, "Metadata", MetadataFilter, not MetadataFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure setRetrieving ()
	
	s = "
	|select top 1 1
	|from InformationRegister.Controls as Controls
	|where Controls.User = &User
	|and Controls.Application = &Application
	|and Controls.Metadata = &Metadata
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Application", Parameters.Application );
	q.SetParameter ( "Metadata", MetadataFilter );
	RetrieveControls = q.Execute ().IsEmpty ();

EndProcedure 

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	filterByType ();
	
EndProcedure

&AtServer
Procedure filterByType ()
	
	DC.ChangeFilter ( List, "Type", TypeFilter, not TypeFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	if ( RetrieveControls ) then
		fill ();
	else
		withActiveForm ();
	endif;
	
EndProcedure

&AtClient
Procedure init ()
	
	Port = AppData.Port;
	flagConnected ();
	
EndProcedure

&AtClient
Procedure flagConnected ()
	
	Connected = AppData.Connected;
	Appearance.Apply ( ThisObject, "Connected" );
	
EndProcedure

&AtClient
Procedure withActiveForm ()
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( not Connected ) then
			return;
		endif;
		search = Controls.FindRows ( new Structure ( "Type", PredefinedValue ( "Enum.Controls.Form" ) ) );
		if ( search.Count () = 0 ) then
			name = Parameters.FormTitle;
		else
			name = search [ 0 ].TitleText;
		endif; 
		With ( name );
	#endif
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure SelectForm ( Command )
	
	if ( not Connected ) then
		if ( not attach ( Port, true ) ) then
			return;
		endif; 
	endif;
	ShowChooseFromMenu ( new NotifyDescription ( "FormSelected", ThisObject ), findForms (), Items.ListCommands );
	
EndProcedure

&AtClient
Function attach ( ToPort = undefined, Silently )
	
	if ( Silently ) then
		try
			Test.Attach ( ToPort );
			attached = true;
		except
			attached = false;
		endtry;
	else
		Test.Attach ( ToPort );
		attached = true;
	endif;
	flagConnected ();
	return attached;
	
EndFunction

&AtClient
Function findForms ()

	set = new ValueList ();
	objects = App.FindObjects ( Type ( "TestedForm" ) );
	for each form in objects do
		set.Add ( form, form.TitleText );
	enddo; 
	return set;
	
EndFunction 

&AtClient
Procedure FormSelected ( Form, Params ) export
	
	if ( Form <> undefined ) then
		fill ( form.Value );
	endif; 
	
EndProcedure 

&AtClient
Procedure TypeFilterOnChange ( Item )
	
	filterByType ();
	activateList ();
	
EndProcedure

&AtClient
Procedure activateList ()
	
	CurrentItem = Items.List;
	
EndProcedure 

&AtClient
Procedure UpdateList ( Command )
	
	fill ();
	
EndProcedure

&AtClient
Procedure fill ( Form = undefined )
	
	if ( not Connected ) then
		if ( not attach ( Port, true ) ) then
			return;
		endif; 
	endif;
	fillControls ( Form );
	store ();
	withActiveForm ();

EndProcedure 

&AtClient
Procedure fillControls ( Form )
	
	Controls.Clear ();
	ControlPosition = 0;
	FieldsMap = new Map ();
	if ( Form = undefined ) then
		objects = App.GetActiveWindow ().FindObjects ();
	else
		objects = Form.FindObjects ();
		addControl ( Form );
	endif; 
	for each field in objects do
		addControl ( field );
	enddo; 
	
EndProcedure 

&AtClient
Procedure addControl ( Field )
	
	row = Controls.Add ();
	FillPropertyValues ( row, Field );
	row.Position = ControlPosition;
	type = ScenarioForm.FieldType ( Field );
	row.Type = type;
	if ( row.Name = "" ) then
		row.Name = "<" + ? ( row.FormName = "", type, row.FormName ) + ">";
	endif;
	if ( type = PredefinedValue ( "Enum.Controls.Form" )
		and row.FormName = "" ) then
		row.FormName = "SystemDialog_" + row.TitleText;
	endif; 
	FieldsMap [ ControlPosition ] = Field; // TestedField cannot be used as a key
	ControlPosition = ControlPosition + 1;
	
EndProcedure 

&AtServer
Procedure store ()
	
	MetadataFilter = storeMetadata ();
	filterByMetadata ();
	
EndProcedure 

&AtServer
Function storeMetadata ()
	
	user = SessionParameters.User;
	application = Parameters.Application;
	currentMeta = undefined;
	currentForm = "";
	recordset = undefined;
	for each row in Controls do
		name = row.FormName;
		if ( name <> currentForm ) then
			if ( name <> "" ) then
				currentForm = name;
				currentMeta = Catalogs.Metadata.Ref ( name );
				commitRecordset ( recordset );
				recordset = newRecordset ( currentMeta );
			endif; 
		endif; 
		if ( currentMeta = undefined ) then
			continue;
		endif; 
		r = recordset.Add ();
		r.User = user;
		r.Application = application;
		r.Metadata = currentMeta;
		r.TitleText = row.TitleText;
		r.Type = row.Type;
		r.Name = row.Name;
		r.FormName = name;
		r.Position = row.Position;
	enddo; 
	commitRecordset ( recordset );
	return currentMeta;
	
EndFunction

&AtServer
Procedure commitRecordset ( Recordset )
	
	if ( Recordset <> undefined ) then
		Recordset.Write ();
	endif; 
				
EndProcedure 

&AtServer
Function newRecordset ( Meta )
	
	r = InformationRegisters.Controls.CreateRecordSet ();
	r.Filter.User.Set ( SessionParameters.User );
	r.Filter.Application.Set ( Parameters.Application );
	r.Filter.Metadata.Set ( Meta );
	return r;
	
EndFunction

&AtClient
Procedure CompleteSelection ( Command )
	
	completePicking ();
	
EndProcedure

&AtClient
Procedure completePicking ()
	
	if ( Parameters.SelectOnly ) then
		NotifyChoice ( selectedID () );
	else
		NotifyChoice ( ? ( Script = "", selectedID (), Script ) );
	endif;
		
EndProcedure 

&AtClient
Function selectedID ()
	
	if ( tableRow () = undefined ) then
		return undefined;
	else
		name = ScenarioForm.ControlName ( Items.List, Items.ListName );
		return Conversion.Wrap ( name );
	endif;
	
EndFunction 

&AtClient
Function tableRow ()
	
	return Items.List.CurrentData;
	
EndFunction 

&AtClient
Procedure Sync ( Command )
	
	syncItem ();
	
EndProcedure

&AtClient
Procedure syncItem ()
	
	if ( FieldsMap = undefined ) then
		fill ();
	endif; 
	try
		item = CurrentSource.GetCurrentItem ();
	except
		return;
	endtry;
	for each field in FieldsMap do
		if ( field.Value = item ) then
			//@skip-warning
			Items.List.CurrentRow = positionKey ( field.Key, SessionApplication, MetadataFilter );
			break;
		endif; 
	enddo; 
	
EndProcedure 

&AtServerNoContext
Function positionKey ( val Position, val Application, val Meta )
	
	p = new Structure ( "User, Application, Metadata, Position" );
	p.User = SessionParameters.User;
	p.Application = Application;
	p.Metadata = Meta;
	p.Position = Position;
	return InformationRegisters.Controls.CreateRecordKey ( p );
	
EndFunction 

&AtClient
Procedure ConnectClient ( Command )
	
	attach ( Port, false );
	fill ();
	activateList ();
	
EndProcedure

&AtClient
Procedure DisconnectClient ( Command )
	
	Test.DisconnectClient ();
	flagConnected ();
	activateList ();
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	if ( Parameters.SelectOnly ) then
		completePicking ();
	else
		ScenarioForm.OpenAssistant ( Items.List, Items.ListName, true );
	endif; 
	
EndProcedure

&AtClient
Procedure ListChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	applyAction ( SelectedValue );
	
EndProcedure

&AtClient
Procedure applyAction ( Action )
	
	error = not ScenarioForm.ApplyAction ( Action );
	if ( error ) then
		Script = Script + "//";
	endif; 
	Script = Script + Action.Expression + Chars.LF;
	
EndProcedure 
