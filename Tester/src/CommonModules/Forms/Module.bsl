#if ( ThinClient or ThickClientManagedApplication ) then

Procedure CloseWindows () export
	
	stuck = false;
	rest = undefined;
	while ( true ) do
		windows = App.GetChildObjects ();
		count = windows.Count ();
		if ( rest = undefined
			or rest > count ) then
			rest = count;
			stuck = false;
		elsif ( stuck ) then
			break;
		else
			stuck = true;
		endif;
		for each window in windows do
			if ( not standard ( window ) ) then
				tryClose ( window );
			endif;
		enddo;
		if ( closingComplete ( windows ) ) then
			break;
		endif; 
		clickNo ();
	enddo; 
	CurrentSource = undefined;
	ТекущийОбъект = undefined;
	
EndProcedure 

Procedure clickNo ()
	
	fieldType = Type ( "TestedFormField" );
	labels = App.FindObjects ( fieldType, "*Сохранить изменения?" );
	if ( labels.Count () = 0 ) then
		labels = App.FindObjects ( fieldType, "*Do you want*?" );
	endif; 
	if ( labels.Count () = 0 ) then
		pressNo ( App.GetActiveWindow () );
	else
		for each label in labels do
			dialog = label.GetParent ();
			pressNo ( dialog );
		enddo; 
	endif;
	
EndProcedure 

Procedure pressNo ( Dialog )
	
	buttonType = Type ( "TestedFormButton" );
	button = Dialog.FindObject ( buttonType, "Нет" );
	if ( button = undefined ) then
		button = Dialog.FindObject ( buttonType, "No" );
	endif; 
	if ( button <> undefined ) then
		button.Click ();
	endif;
	
EndProcedure

Function standard ( Window )
	
	return Window.IsMain
	or Window.HomePage;
	
EndFunction 

Procedure tryClose ( Window )
	
	closeWindow ( Window );
	stillHere = App.GetChildObjects ().Find ( Window ) <> undefined;
	if ( stillHere ) then
		if ( cancelInput ( window ) ) then
			closeWindow ( Window );
		endif; 
	endif; 
	
EndProcedure 

Procedure closeWindow ( Window )
	
	try
		Window.Close ();
	except
	endtry;
	
EndProcedure 

Function cancelInput ( Window )
	
	try
		input = Window.GetObject ().GetCurrentItem ();
	except
		return false;
	endtry;
	type = TypeOf ( input );
	if ( type = Type ( "TestedFormField" ) ) then
		if ( input.Type = FormFieldType.InputField ) then
			try // Form could be locked by another Dialog
				input.CancelEdit ();
				return true;
			except
			endtry;
		endif; 
	elsif ( type = Type ( "TestedFormTable" ) ) then
		try // Form could be locked by another Dialog
			if ( input.CurrentModeIsEdit () ) then
				input.EndEditRow ( true );
				return true;
			endif; 
		except
		endtry;
	endif; 
	return false;
	
EndFunction

Function closingComplete ( Windows )
	
	currentWindows = new Array ( App.GetChildObjects () );
	if ( currentWindows.Count () > Windows.Count () ) then
		return false;
	endif; 
	oldWindows = new Array ( Windows );
	i = oldWindows.UBound ();
	while ( i >= 0 ) do
		window = oldWindows [ i ];
		if ( standard ( window )
			or currentWindows.Find ( window ) = undefined ) then
			oldWindows.Delete ( i );
		endif;
		i = i - 1;
	enddo; 
	if ( oldWindows.Count () > 0 ) then
		return false;
	endif; 
	for each window in currentWindows do
		if ( not standard ( window ) ) then
			return false;
		endif; 
	enddo; 
	return true;
	
EndFunction 

Function Get1C ( TimeOut = 0 ) export

	formType = Type ( "TestedForm" );
	try
		form = App.GetObject ( formType, "1?:*", , TimeOut );
	except
		form = undefined;
	endtry;
	return form;
	
EndFunction 

Function SetCurrent ( Source, Activate ) export
	
	target = ? ( Source = undefined, App.GetActiveWindow ().Caption, Source );
	if ( TypeOf ( target ) = Type ( "String" ) ) then
		window = App.FindObject ( Type ( "TestedClientApplicationWindow" ), target );
		if ( window = undefined ) then
			CurrentSource = App.FindObject ( Type ( "TestedForm" ), target );
			if ( CurrentSource = undefined ) then
				raise Output.SourceNotFound ();
			endif; 
		else
			CurrentSource = window.GetObject ();
		endif; 
	else
		CurrentSource = target;
	endif; 
	ТекущийОбъект = CurrentSource;
	if ( Activate
		and TypeOf ( CurrentSource ) = Type ( "TestedForm" ) ) then
		CurrentSource.Activate ();
	endif; 
	return CurrentSource;
	
EndFunction

Procedure ClickMenu ( Path ) export
	
	commands = MainWindow.GetCommandInterface ();
	place = commands;
	parts = Conversion.StringToArray ( Path, "/" );
	buttonIndex = parts.UBound ();
	groupType = Type ( "TestedCommandInterfaceGroup" );
	buttonType = Type ( "TestedCommandInterfaceButton" );
	for i = 0 to buttonIndex do
		part = parts [ i ];
		if ( i = buttonIndex ) then
			place = place.GetObject ( buttonType, part );
		else
			item = place.FindObject ( groupType, part );				
			if ( item = undefined ) then
				// Try to open short-path variant.
				// For instance: Purchases / Vendor Invoices
				place.GetObject ( buttonType, part ).Click ();
				item = commands;
			endif;
			place = item;
		endif;
	enddo; 
	place.Click ();

EndProcedure 

Function GetFrame ( Form = undefined ) export
	
	windowType = Type ( "TestedClientApplicationWindow" );
	if ( Form = undefined ) then
		target = CurrentSource;
	else
		if ( TypeOf ( Form ) = Type ( "String" ) ) then
			target = App.GetObject ( windowType, Form, , 3 ).GetObject ();
		else
			target = Form;
		endif; 
	endif; 
	if ( TypeOf ( target ) = windowType ) then
		return target;
	endif; 
	windows = App.GetChildObjects ();
	list = new Array ();
	for each window in windows do
		if ( window.IsMain ) then
			continue;
		endif;
		object = window.GetObject ();
		if ( target = object ) then
			return window;
		endif;
		list.Add ( new Structure ( "Window, Name", window, object.FormName ) );
	enddo;
	target = target.FormName;
	for each item in list do
		if ( target = item.Name ) then
			return item.window;
		endif;
	enddo;
	return undefined;
	
EndFunction

Function SearchForm ( Name ) export
	
	window = App.FindObject ( Type ( "TestedClientApplicationWindow" ), Name );
	if ( window = undefined ) then
		return App.GetObject ( Type ( "TestedForm" ), Name );
	else
		return window.GetObject ();
	endif; 
	
EndFunction 

Function Wait ( Name, Timeout, Type ) export
	
	target = ? ( Type = undefined, Type ( "TestedForm" ), Type );
	sign = Left ( Name, 1 );
	if ( sign = "#"
		or sign = "!" ) then
		id = Mid ( Name, 2 );
		title = undefined;
	else
		title = Name;
		id = undefined;
	endif;
	return App.WaitForObjectDisplayed ( target, title, id, Timeout );
	
EndFunction 

Procedure DoCommand ( Action ) export
	
	MainWindow.ExecuteCommand ( Action );
	
EndProcedure 

Function Shoot ( Pattern, Compressed ) export
	
	if ( ExternalLibrary = undefined ) then
		return undefined;
	else
		title = ? ( Pattern = "", ScreenshotsLocator, Pattern );
		if ( title = "" ) then
			return undefined;
		else
			quality = ? ( Compressed = undefined, ScreenshotsCompressed, Compressed );
			return ExternalLibrary.Shoot ( title, quality );
		endif; 
	endif; 
	
EndFunction 

Procedure BroadcastMessage ( Text ) export
	
	Message ( Text );
	if ( TesterServerMode ) then
		Watcher.AddMessage ( Text, Enum.MessageTypesHint () );
	endif;
	
EndProcedure

Function FindSource ( Source ) export
	
	if ( TypeOf ( Source ) = Type ( "String" ) ) then
		return FindForm ( Source );
	else
		return Source;
	endif; 
	
EndFunction

Procedure ToggleWindow ( Pattern, Maximize ) export
	
	if ( ExternalLibrary = undefined ) then
		return;
	else
		title = ? ( Pattern = "", ScreenshotsLocator, Pattern );
		if ( title = "" ) then
			return;
		else
			if ( Maximize ) then
				ExternalLibrary.Maximize ( title );
			else
				ExternalLibrary.Minimize ( title );
			endif;
		endif; 
	endif;
	 
EndProcedure

#endif 
