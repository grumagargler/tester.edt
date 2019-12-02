&AtServer
var GenerateOnOpen;
&AtClient
var SelectedVariant;
&AtClient
var form;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not testParameters () ) then
		Cancel = true;
		return;
	endif; 
	applyParams ();
	initSettingsComposer ();
	if ( Parameters.Command = "OpenReport" ) then
		openReport ();
	elsif ( Parameters.Command = "DrillDown" ) then
		drillDown ();
	elsif ( Parameters.Command = "Detail" ) then
		detail ();
	elsif ( Parameters.Command = "NewWindow" ) then
		openReportForNewWindow ();
	endif; 
	showStatus ();
	restoreSettingsButton ();
	WindowOptionsKey = Parameters.ReportName;
	afterLoadSettings ();
	if ( GenerateOnOpen ) then
		makeReport ();
	endif; 
	ReporterForm.SetTitle ( ThisObject );
	setCurrentItem ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Function testParameters ()

	if ( not Parameters.Property ( "Command" ) ) then
		Output.CommonReportOpenError ();
		return false;
	endif; 
	return true;
	
EndFunction

&AtServer
Procedure applyParams ()
	
	Object.ReportName = Parameters.ReportName;
	class = Reports [ Parameters.ReportName ];
	if ( class.Events ().OnDetail ) then
		class.OnDetail ( ReportDetails, UseMainAction, DetailActions );
	endif; 
	meta = Metadata.Reports [ Object.ReportName ];
	ReportPresentation = ? ( meta.ExtendedPresentation = "", meta.Presentation (), meta.ExtendentPresentation );
	ReportRef = Catalogs.Metadata.Ref ( "Report." + Object.ReportName );
	Parameters.Property ( "VariantPresentation", VariantPresentation );
	Parameters.Property ( "ReportVariant", ReportVariant );
	Parameters.Property ( "ReportSettings", ReportSettings );
	Parameters.Property ( "GenerateOnOpen", GenerateOnOpen );
	if ( GenerateOnOpen = undefined ) then
		GenerateOnOpen = false;
	endif; 
	
EndProcedure

&AtServer
Procedure initSettingsComposer ()
	
	dataSchema = Reporter.GetSchema ( Object.ReportName );
	SchemaAddress = PutToTempStorage ( dataSchema, SchemaAddress );
	Object.SettingsComposer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	
EndProcedure 

&AtServer
Procedure openReport ()
	
	loadVariantServer ( ReportVariant, undefined );
	Reporter.ApplyFilters ( Object.SettingsComposer, Parameters );
	
EndProcedure

&AtServer
Procedure drillDown ()
	
	detailsProcess = new DataCompositionDetailsProcess ( GetFromTempStorage ( Parameters.DetailsDescription.Data ), new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	usedSettings = detailsProcess.ApplySettings ( Parameters.DetailsDescription.ID, Parameters.DetailsDescription.UsedSettings );
	if ( TypeOf ( usedSettings ) = Type ( "DataCompositionSettings" ) ) then
		Object.SettingsComposer.LoadSettings ( usedSettings );
	elsif ( TypeOf ( usedSettings ) = Type ( "DataCompositionUserSettings" ) ) then
		loadVariantServer ( ReportVariant, ReportSettings );
		Object.SettingsComposer.LoadUserSettings ( usedSettings );
	endif;
	
EndProcedure

&AtServer
Procedure detail ()
	
	loadVariantServer ( "#Default", undefined );
	Reports [ Object.ReportName ].ApplyDetails ( Object.SettingsComposer, Parameters );
	
EndProcedure

&AtServer
Procedure openReportForNewWindow ()
	
	Object.SettingsComposer.LoadSettings ( Parameters.Variant );
	Object.SettingsComposer.LoadUserSettings ( Parameters.UserSettings );
	disableActualState ( Items.Result );
	
EndProcedure 

&AtServer
Procedure showStatus ()
	
	Items.Result.StatePresentation.Text = Output.ClickGenerateReport ();
	
EndProcedure

&AtServer
Procedure restoreSettingsButton ()
	
	ShowSettings = CommonSettingsStorage.Load ( "Report.Common", Enum.SettingsShowSettingsButtonState () );
	
EndProcedure 

&AtServer
Procedure setCurrentItem ()
	
	if ( GenerateOnOpen ) then
		setResultCurrentItem ( ThisObject );
		CurrentItem = Items.Result;
	else
		activateSettings ();
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setResultCurrentItem ( Form )
	
	items = Form.Items;
	Form.CurrentItem = items.Result;
	
EndProcedure 

&AtServer
Procedure activateSettings ()
	
	if ( ShowSettings ) then
		CurrentItem = Items.UserSettings;
	else
		if ( Items.GroupQuickSettings.ChildItems.Count () > 0 ) then
			CurrentItem = Items.GroupQuickSettings.ChildItems [ 0 ];
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Procedure makeReport ()
	
	report = prepareReport ();
	p = report.Params;
	if ( p.Events.OnCheck ) then
		cancel = false;
		report.OnCheck ( cancel );
		if ( cancel ) then
			return;
		endif; 
	endif; 
	p.Settings = p.Composer.GetSettings ();
	Reporter.ComposeResult ( report );
	storeDetailsData ( p );
	enableActualState ();
	
EndProcedure

&AtServer
Function prepareReport ()
 	
	report = Reporter.Prepare ( Object.ReportName );
	p = report.Params;
	p.GenerateOnOpen = ( GenerateOnOpen <> undefined ) and GenerateOnOpen;
	p.Variant = ReportVariant;
	p.Schema = GetFromTempStorage ( SchemaAddress );
	p.Result = Result;
	p.Composer = Object.SettingsComposer;
	return report;
	
EndFunction 

&AtServer
Procedure storeDetailsData ( Params )
	
	if ( IsTempStorageURL ( DetailsAddress ) ) then
		DeleteFromTempStorage ( DetailsAddress );
		DetailsAddress = "";
	endif; 
	DetailsAddress = PutToTempStorage ( Params.Details, DetailsAddress );
	
EndProcedure 

&AtServer
Procedure enableActualState ()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	Items.Result.StatePresentation.Visible = false;
	
EndProcedure

&AtServer
Procedure afterLoadSettings ()
	
	ReporterForm.AfterLoadSettings ( ThisObject );
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		Cancel = true;
		return;
	endif; 
	if ( VariantModified ) then
		Cancel = true;
		Output.ReportVariantModified2 ( ThisObject, , , "SaveVariantBeforeClose" );
	endif
	
EndProcedure

&AtClient
Procedure SaveVariantBeforeClose ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		saveReportVariant ( "closeAfterSavingVariant" );
	elsif ( Answer = DialogReturnCode.No ) then
		VariantModified = false;
		Close ();
	endif; 

EndProcedure

&AtClient
Procedure closeAfterSavingVariant ( SavedSettings, IsSettings ) export
	
	if ( CommonSaveSettings ( SavedSettings, IsSettings ) ) then
		Close ();
	endif;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Make ( Command )
	
	makeReport ();
	setResultCurrentItem ( ThisObject );
	
EndProcedure

&AtClient
Procedure SendReportBySchedule ( Command )
	
	if ( not checkScheduling () ) then
		return;
	endif; 
	organizeSendingBySchedule ();
	
EndProcedure

&AtServer
Function checkScheduling ()
	
	class = Reports [ Object.ReportName ];
	events = class.Events ();
	standardProcessing = true;
	cancel = false;
	if ( events.OnScheduling ) then
		class.OnScheduling ( Object.SettingsComposer, cancel, standardProcessing );
	endif; 
	if ( not cancel
		and standardProcessing ) then
		cancel = not checkPeriod ( Object.SettingsComposer, "Period" );
		if ( not cancel ) then
			cancel = not checkPeriod ( Object.SettingsComposer, "Asof" );
		endif; 
	endif; 
	return not cancel;
	
EndFunction 

&AtServer
Function checkPeriod ( Composer, Name )
	
	period = DC.FindParameter ( Composer, Name );
	if ( period <> undefined
		and period.Use
		and period.Value.Variant = StandardPeriodVariant.Custom ) then
		Output.ReportSchedulingIncorrectPeriod ();
		return false;
	endif; 
	return true;
	
EndFunction 

&AtClient
Procedure organizeSendingBySchedule ()
	
	values = new Structure ();
	values.Insert ( "Report", ReportRef );
	values.Insert ( "Variant", ReportVariant );
	values.Insert ( "SettingsAddress", PutToTempStorage ( Object.SettingsComposer.UserSettings, UUID ) );
	p = new Structure ( "FillingValues", values );
	OpenForm ( "InformationRegister.ScheduledReports.RecordForm", p );
	
EndProcedure 

&AtClient
Procedure LoadVariant ( Command )
	
	loadReportVariant ();
	
EndProcedure

&AtClient
Procedure LoadSettings ( Command )
	
	loadUserSettings ();
	
EndProcedure

&AtClient
Procedure loadReportVariant ()
	
	openAndLoadVariantOrSettings ( false );
	
EndProcedure
 
&AtClient
Procedure loadUserSettings ()
	
	openAndLoadVariantOrSettings ( true );
	
EndProcedure

&AtClient
Procedure openAndLoadVariantOrSettings ( IsSettings )
	
	p = new Structure ( "ReportName, IsSettings, ReportVariant", Object.ReportName, IsSettings, ReportVariant ); 
	if ( IsSettings ) then
		p.Insert ( "CurrentSettings", ReportSettings );
	endif; 
	OpenForm ( "Report.Common.Form.LoadSettings", p, , , , , new NotifyDescription ( "CommonLoadSettings", ThisObject, IsSettings ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Procedure CommonLoadSettings ( SelectedItem, IsSettings ) export
	
	if ( SelectedItem = undefined ) then
		return;
	endif; 
	if ( TypeOf ( SelectedItem ) = Type ( "String" ) ) then
		if ( IsSettings ) then
			applySettings ( SelectedItem );
		else
			if ( VariantModified ) then
				SelectedVariant = SelectedItem;
				Output.ReportVariantModified1 ( ThisObject, , , "LoadConfirmedVariant" );
			else
				applyVariant ( SelectedItem );
			endif; 
		endif;
	endif;
	
EndProcedure 

&AtServer
Procedure applySettings ( val Setting )
	
	loadSettingsServer ( Setting );
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure loadSettingsServer ( Code )
	
	if ( IsTempStorageURL ( Code ) ) then
		settingsReport = GetFromTempStorage ( Code );
	else
		if ( TypeOf ( Code ) = Type ( "CatalogRef.ReportSettings" ) ) then
			settings = Code;
		else
			settings = Catalogs.ReportSettings.FindByCode ( Code );
		endif;
		settingsReport = settings.Storage.Get ();
		ReportSettings = settings;
	endif; 
	if ( settingsReport <> undefined ) then
		Object.SettingsComposer.LoadUserSettings ( settingsReport );
		disableActualState ( Items.Result );
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure disableActualState ( Result )
	
	Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Result.StatePresentation.Visible = true;
	
EndProcedure

&AtServer
Procedure applyVariant ( val Setting )
	
	loadVariantServer ( Setting, undefined );
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure loadVariantServer ( Variant, SettingsCode )
	
	if ( Variant = undefined ) then
		code = undefined;
	elsif ( TypeOf ( Variant ) = Type ( "CatalogRef.ReportSettings" ) ) then
		code = DF.Pick ( Variant, "Code" );
	else
		code = Variant;
	endif; 
	if ( code = undefined ) then
		loadDefaultSettings ();
		return;
	endif;
	if ( Left ( code, 1 ) = "#" ) then
		loadPredefinedVariant ( code );
	else
		loadUserVariant ( code );
	endif; 
	if ( ValueIsFilled ( SettingsCode ) ) then
		loadSettingsServer ( SettingsCode );
	else
		resetReportSettings ();
	endif; 
	disableActualState ( Items.Result );

EndProcedure

&AtServer
Procedure loadDefaultSettings ()
	
	settingsReport = InformationRegisters.UsersReportSettings.Get ( new Structure ( "User, Report", SessionParameters.User, ReportRef ) );
	if ( ValueIsFilled ( settingsReport.Variant ) ) then
		variantCode = ? ( TypeOf ( settingsReport.Variant ) = Type ( "CatalogRef.ReportSettings" ), settingsReport.Variant.Code, settingsReport.Variant );
		loadVariantServer ( variantCode, settingsReport.Settings );
	else
		loadVariantServer ( "#Default", undefined );
	endif; 
	
EndProcedure

&AtServer
Procedure loadPredefinedVariant ( Code )
	
	ReportVariant = Code;
	variantName = Mid ( Code, 2 );
	dataSchema = Reporter.GetSchema ( Object.ReportName );
	variantReport = dataSchema.SettingVariants [ variantName ].Settings;
	VariantPresentation = dataSchema.SettingVariants [ variantName ].Presentation;
	Object.SettingsComposer.LoadSettings ( variantReport );
	Object.SettingsComposer.Refresh ();
	
EndProcedure

&AtServer
Procedure loadUserVariant ( Code )
	
	ReportVariant = Catalogs.ReportSettings.FindByCode ( Code );
	variantReport = ReportVariant.Storage.Get ();
	VariantPresentation = "" + ReportVariant;
	Object.SettingsComposer.LoadSettings ( variantReport );
	Object.SettingsComposer.Refresh ();
	
EndProcedure

&AtServer
Procedure resetReportSettings ()
	
	ReportSettings = undefined;
	resetUserSettings ();
	
EndProcedure 

&AtClient
Procedure LoadConfirmedVariant ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		saveReportVariant ( "loadVariantAfterSavePrevious" );
	elsif ( Answer = DialogReturnCode.No ) then
		VariantModified = false;
		applyVariant ( SelectedVariant );
	endif; 

EndProcedure

&AtClient
Procedure loadVariantAfterSavePrevious ( SavedSettings, IsSettings ) export
	
	if ( CommonSaveSettings ( SavedSettings, IsSettings ) ) then
		applyVariant ( SelectedVariant );
	endif; 
	
EndProcedure 

&AtClient
Procedure SaveVariant ( Command )
	
	saveReportVariant ( "CommonSaveSettings" );
	
EndProcedure

&AtClient
Procedure SaveSettings ( Command )
	
	userSettingsSave ();
	
EndProcedure

&AtClient
Procedure saveReportVariant ( ProcAfterSave )
	
	openAndSaveVariantOrSettings ( false, ProcAfterSave );
	
EndProcedure

&AtClient
Procedure userSettingsSave ()
	
	openAndSaveVariantOrSettings ( true, "CommonSaveSettings" );
	
EndProcedure

&AtClient
Procedure openAndSaveVariantOrSettings ( IsSettings, ProcAfterSave )
	
	p = new Structure ();
	address = PutToTempStorage ( ? ( IsSettings, Object.SettingsComposer.UserSettings, Object.SettingsComposer.Settings ), UUID );
	p.Insert ( "SettingsAddress", address );
	p.Insert ( "ReportName", Object.ReportName );
	p.Insert ( "IsSettings", IsSettings );
	if ( IsSettings ) then
		p.Insert ( "ReportVariant", ReportVariant );
	endif; 
	OpenForm ( "Report.Common.Form.SaveSettings", p, , , , , new NotifyDescription ( ProcAfterSave, ThisObject, IsSettings ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Function CommonSaveSettings ( SavedSettings, IsSettings ) export
	
	if ( TypeOf ( SavedSettings ) = Type ( "CatalogRef.ReportSettings" ) ) then
		if ( IsSettings ) then
			ReportSettings = SavedSettings;
		else
			ReportVariant = SavedSettings;
			VariantModified = false;
		endif; 
		return true;
	endif;
	return false;
	
EndFunction

&AtClient
Procedure OpenSettings ( Command )
	
	toggleSettings ();
	
EndProcedure

&AtServer
Procedure toggleSettings ()
	
	if ( ShowSettings ) then
		BuildFilter ();
		ShowSettings = false;
	else
		ShowSettings = true;
	endif; 
	Appearance.Apply ( ThisObject, "ShowSettings" );
	activateSettings ();
	saveSettingsState ();
	
EndProcedure 

&AtServer
Procedure BuildFilter () export
	
	clearFilter ();
	settings = Object.SettingsComposer.Settings;
	userSettings = Object.SettingsComposer.UserSettings.Items;
	p = settings.DataParameters.Items;
	availParams = settings.DataParameters.AvailableParameters;
	filters = settings.Filter.Items;
	availFilters = settings.Filter.FilterAvailableFields;
	parameterType = Type (  "DataCompositionSettingsParameterValue" );
	filterType = Type (  "DataCompositionFilterItem" );
	quick = DataCompositionSettingsItemViewMode.QuickAccess;
	for i = 0 to userSettings.Count () - 1 do
		item = userSettings [ i ];
		add = false;
		id = item.UserSettingID;
		itemType = TypeOf ( item );
		if ( itemType = parameterType ) then
			for each param in p do
				if ( param.UserSettingID = id
					and param.ViewMode = quick ) then
					label = availParams.FindParameter ( param.Parameter ).Title;
					add = true;
					break;
				endif;
			enddo; 
		elsif ( itemType = filterType ) then
			for each filter in filters do
				if ( filter.UserSettingID = id
					and filter.ViewMode = quick ) then
					label = filter.UserSettingPresentation;
					if ( label = "" ) then
						availItem = availFilters.FindField ( filter.LeftValue );
						if ( availItem = undefined ) then
							label = filter.LeftValue;
						else
							label = availItem.Title;
						endif; 
					endif; 
					add = true;
					break;
				endif; 
			enddo; 
		endif; 
		if ( add ) then
			adjustFilter ( item, itemType );
			drawFilter ( i, label );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure clearFilter ()
	
	fields = Items.GroupQuickSettings.ChildItems;
	i = fields.Count () - 1;
	while ( i >= 0 ) do
		Items.Delete ( fields.Get ( i ) );
		i = i - 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure adjustFilter ( Item, Type )
	
	if ( Item.Use ) then
		return;
	endif; 
	if ( Type = Type ( "DataCompositionFilterItem" ) ) then
		if ( ValueIsFilled ( Item.RightValue ) ) then
			Item.RightValue = undefined;
		endif; 
	elsif ( Type = Type ( "DataCompositionSettingsParameterValue" ) ) then
		if ( ValueIsFilled ( Item.Value ) ) then
			Item.Value = undefined;
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Procedure drawFilter ( Index, Label )
	
	i = Format ( Index, "NZ=" );
	field = Items.Add ( "_" + i, Type ( "FormField" ), Items.GroupQuickSettings );
	field.DataPath = "Object.SettingsComposer.UserSettings[" + i + "].Value";
	field.Type = FormFieldType.InputField;
	field.Title = Label;
	field.Enabled = true;
	field.Visible = true;
	field.OpenButton = false;
	field.ClearButton = true;
	field.SetAction ( "OnChange", "FilterOnChange" );
	field.SetAction ( "StartChoice", "FilterStartChoice" );
	
EndProcedure 

&AtServer
Procedure saveSettingsState ()
	
	LoginsSrv.SaveSettings ( "Report.Common", Enum.SettingsShowSettingsButtonState (), ShowSettings );
	
EndProcedure 

&AtClient
Procedure ChangeVariant ( Command )
	
	changeReportVariant ();

EndProcedure

&AtClient
Procedure changeReportVariant ()
	
	p = new Structure ();
	p.Insert ( "Variant", Object.SettingsComposer.Settings );
	p.Insert ( "UserSettings", Object.SettingsComposer.UserSettings );
	p.Insert ( "VariantPresentation", VariantPresentation );
	form = GetForm ( "Report." + Object.ReportName + ".VariantForm", p, , true );
	form.OnCloseNotifyDescription = new NotifyDescription ( "LoadChangedVariant", ThisObject, form );
	form.WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm ( form );
	
EndProcedure

&AtClient
Procedure LoadChangedVariant ( Result, Params ) export
	
	if ( Result = true ) then
		// The expression "Settings" + "Composer" prevents EDT1.15 "Property is not writable" error
		Object [ "Settings" + "Composer" ] = form.Report.SettingsComposer;
		#if ( not WebClient ) then
			disableActualState ( Items.Result );
		#endif
		VariantModified = true;
		afterLoadSettings ();
	endif; 
	
EndProcedure

&AtClient
Procedure ResetSettings ( Command )
	
	initSettings ();
	
EndProcedure

&AtServer
Procedure initSettings ()
	
	resetUserSettings ();
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure resetUserSettings ()
	
	Object.SettingsComposer.LoadUserSettings ( new DataCompositionUserSettings () );
	disableActualState ( Items.Result );
	
EndProcedure

&AtClient
Procedure NewWindow ( Command )
	
	openReportInNewWindow ();
	
EndProcedure

&AtClient
Procedure openReportInNewWindow ()
	
	p = getParametersForNewWindow ();
	p.Insert ( "Command", "NewWindow" );
	p.Insert ( "Variant", Object.SettingsComposer.Settings );
	p.Insert ( "UserSettings", Object.SettingsComposer.UserSettings );
	OpenForm ( "Report.Common.Form", p, , true );
	
EndProcedure

&AtClient
Function getParametersForNewWindow ()
	
	p = new Structure ();
	p.Insert ( "ReportName", Object.ReportName );
	p.Insert ( "ReportVariant", ReportVariant );
	p.Insert ( "ReportSettings", ReportSettings );
	p.Insert ( "VariantPresentation", VariantPresentation );
	return p;
	
EndFunction

&AtClient
Procedure SetVariantAsDefault ( Command )
	
	setReportVariantAsDefault ();
	
EndProcedure

&AtClient
Procedure setReportVariantAsDefault ()
	
	setUserSettings ( false );
	
EndProcedure

&AtClient
Procedure SetSettingsAsDefault ( Command )
	
	setUserVariantAndSettingsAsDefault ();
	
EndProcedure

&AtServer
Procedure setUserVariantAndSettingsAsDefault ()
	
	setUserSettings ( false );
	setUserSettings ( true );
	
EndProcedure

&AtServer
Procedure setUserSettings ( IsSettings )
	
	record = InformationRegisters.UsersReportSettings.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.Report = ReportRef;
	record.Read ();
	record.User = SessionParameters.User;
	record.Report = ReportRef;
	if ( IsSettings ) then
		record.Settings = ReportSettings;
	else
		record.Variant = ReportVariant;
	endif; 
	record.Write ();

EndProcedure

&AtClient
Procedure SelectReportVariant ( Command )
	
	loadReportVariant ();
	
EndProcedure

&AtClient
Procedure UserSettingsOnChange ( Item )
	
	applyUserSetting ( Object.SettingsComposer.UserSettings.GetObjectByID ( Items.UserSettings.CurrentRow ) );
	
EndProcedure

&AtClient
Procedure applyUserSetting ( Setting )
	
	#if ( not WebClient ) then
		disableActualState ( Items.Result );
	#endif
	ReporterForm.OnChange ( ThisObject, Setting );
	
EndProcedure 

&AtClient
Procedure UserSettingsValueStartChoice ( Item, ChoiceData, StandardProcessing )
	
	ReporterForm.StartChoice ( ThisObject, Object.SettingsComposer.UserSettings.GetObjectByID ( Items.UserSettings.CurrentRow ), Item, StandardProcessing );

EndProcedure

&AtClient
Procedure FilterOnChange ( Item )
	
	setting = getSetting ( Item );
	applyUserSetting ( setting );
	
EndProcedure

&AtClient
Function getSetting ( Item )
	
	i = Number ( Mid ( Item.Name, 2 ) );
	setting = Object.SettingsComposer.UserSettings.Items [ i ];
	if ( TypeOf ( setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		setting.Use = ValueIsFilled ( setting.Value );
	else
		setting.Use = ValueIsFilled ( setting.RightValue );
	endif; 
	return setting;
	
EndFunction

&AtClient
Procedure FilterStartChoice ( Item, ChoiceData, StandardProcessing )
	
	ReporterForm.StartChoice ( ThisObject, getSetting ( Item ), Item, StandardProcessing );
	
EndProcedure

&AtClient
Procedure Help ( Command )
	
	OpenHelp ( DF.Pick ( ReportRef, "Description" ) );
	
EndProcedure

// *****************************************
// *********** Result

&AtClient
Procedure ResultDetailProcessing ( Item, Details, StandardProcessing )
	
	StandardProcessing = false;
	doDetailProcessing ( Details, Item );
	
EndProcedure

&AtClient
Procedure doDetailProcessing ( Details, Item )
	
	#if ( WebClient ) then
		// Bug workaround 8.3.10.1877: web-client does not recognize ReportDetails
		subreports = ReportDetails.Count ();
		if ( subreports = 0 ) then
			showMenu ( Details );
		else
			if ( subreports = 1 ) then
				ApplySelectedActionWeb ( ReportDetails [ 0 ], Details );
			else
				ShowChooseFromMenu ( new NotifyDescription ( "ApplySelectedActionWeb", ThisObject, Details ), ReportDetails );
			endif; 
		endif; 
	#else
		showMenu ( Details );
	#endif
	
EndProcedure

&AtClient
Procedure showMenu ( Details )
	
	actions = ? ( DetailActions = undefined, new Array (), new Array ( DetailActions ) );
	detailsObject = new DataCompositionDetailsProcess ( DetailsAddress, new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	// Bug workaround 8.3.10.1877: try to fix utterly wrong behaviour of system
	if ( DetailActions = undefined
		and ReportDetails.Count () = 0
		and UseMainAction ) then
		actions.Add ( DataCompositionDetailsProcessingAction.OpenValue );
	endif; 
	detailsObject.ShowActionChoice ( new NotifyDescription ( "ApplySelectedAction", ThisObject, Details ), Details, ? ( actions.Count () = 0 and ReportDetails.Count () = 0, undefined, actions ), ReportDetails, UseMainAction );
	
EndProcedure 

&AtClient
Procedure ApplySelectedActionWeb ( Report, Details ) export
	
	if ( Report = undefined ) then
		return;
	endif; 
	p = ReportsSystem.GetParams ( Report.Value );
	p.GenerateOnOpen = true;
	p.Command = "Detail";
	p.Parent = Object.ReportName;
	p.Filters = getFilters ( SchemaAddress, Details, DetailsAddress );
	OpenForm ( "Report.Common.Form", p, , true );
	
EndProcedure
	
&AtClient
Procedure ApplySelectedAction ( SelectedAction, SelectedActionParameters, Details ) export
	
	if ( SelectedAction = undefined
		or SelectedAction = DataCompositionDetailsProcessingAction.None ) then
		return;
	elsif ( SelectedAction = DataCompositionDetailsProcessingAction.OpenValue ) then
		ShowValue ( , SelectedActionParameters );
	elsif ( TypeOf ( SelectedAction ) = Type ( "String" ) ) then
		p = ReportsSystem.GetParams ( SelectedAction );
		p.GenerateOnOpen = true;
		p.Command = "Detail";
		p.Parent = Object.ReportName;
		p.Filters = getFilters ( SchemaAddress, Details, DetailsAddress );
		OpenForm ( "Report.Common.Form", p, , true );
	else
		p = getParametersForNewWindow ();
		p.Insert ( "Command", "DrillDown" );
		p.Insert ( "GenerateOnOpen", true );
		p.Insert ( "DetailsDescription", new DataCompositionDetailsProcessDescription ( DetailsAddress, Details, SelectedActionParameters ) );
		OpenForm ( "Report.Common.Form", p, , true );
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getFilters ( val Schema, val Details, val Address )
	
	settings = GetFromTempStorage ( Address );
	composer = new DataCompositionSettingsComposer ();
	composer.LoadSettings ( settings.Settings );
	composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
	return retrieveFilters ( composer, Details, settings );
	
EndFunction 

&AtServerNoContext
Function retrieveFilters ( Composer, Details, Settings )
	
	filters = new Array ();
	addDetails ( Settings.Items [ Details ], Composer, filters );
	clean ( filters );
	addFilters ( filters, Composer );
	return PutToTempStorage ( filters );
	
EndFunction

&AtServerNoContext
Procedure addDetails ( Item, Composer, Filters )
	
	if ( TypeOf ( Item ) = Type ( "DataCompositionFieldDetailsItem" ) ) then
		for each field in Item.GetFields () do
			allowedField = getAllowedField ( new DataCompositionField ( field.field ), Composer );
			if ( allowedField = undefined
				or allowedField.Resource ) then
				continue;
			endif;
			Filters.Add ( formalize ( field.Field, true, false, false, field ) );
		enddo;
	endif;
	for each parent in Item.GetParents() do
		addDetails ( parent, Composer, Filters );
	enddo;
	
EndProcedure

&AtServerNoContext
Function formalize ( Name, Field, Filter, Parameter, Item )
	
	data = new Structure ( "Name, Field, Filter, Parameter, Item, StandardProcessing, Comparison", Name, Field, Filter, Parameter, Item, true );
	if ( Field and Item.Hierarchy ) then
		data.Comparison = DataCompositionComparisonType.InHierarchy;
	endif; 
	return data;
	
EndFunction 

&AtServerNoContext
Function getAllowedField ( Field, Composer )
	
	if ( TypeOf ( Field ) = Type ( "String" ) ) then
		search = new DataCompositionField ( Field );
	else
		search = Field;
	endif;
	composerType = TypeOf ( Composer );
	if ( composerType = Type ( "DataCompositionSettingsComposer" )
	 or composerType = Type ( "DataCompositionDetailsData" )
	 or composerType = Type ( "DataCompositionNestedObjectSettings" ) ) then
		return Composer.Settings.SelectionAvailableFields.FindField ( search );
	else
		return Composer.FindField ( search );
	endif;
	
EndFunction

&AtServerNoContext
Procedure clean ( Filters )
	
	i = Filters.Count () - 1;
	while ( i >= 0 ) do
		name = Filters [ i ].Name;
		for j = 0 to i - 1 do
			if ( Filters [ j ].Name = name ) then
				Filters.Delete ( i );
				break;
			endif;
		enddo;
		k = 1;
		childKilled = false;
		while ( true ) do
			a = StrFind ( name, ".", , k );
			if ( a = 0 ) then
				break;
			endif; 
			parent = Left ( name, a - 1 );
			for j = 0 to Filters.Count () - 1 do
				if ( Filters [ j ].Name = parent ) then
					Filters.Delete ( i );
					childKilled = false;
					break;
				endif;
			enddo; 
			if ( childKilled ) then
				break;
			endif; 
			k = a + 1;
		enddo; 
		i = i - 1;
	enddo;
	
EndProcedure 

&AtServerNoContext
Procedure addFilters ( Filters, Composer )

	for each item in Composer.Settings.Filter.Items do
		if ( item.Use ) then
			Filters.Add ( formalize ( undefined, false, true, false, item ) );
		endif;
	enddo;
	for each item in Composer.Settings.DataParameters.Items do
		if ( item.Use ) then
			Filters.Add ( formalize ( String ( item.Parameter ), false, false, true, item ) );
		endif;
	enddo;

EndProcedure 
