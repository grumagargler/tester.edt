&AtClient
Procedure StartChoice ( Form, Setting, Item, StandardProcessing ) export
	
	//@skip-warning
	insertYourCode = true;	
	
EndProcedure

Function findValue ( Composer, Name )
	
	value = undefined;
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
		if ( item <> undefined
			and item.Use ) then
			value = item.Value;
		endif; 
	else
		if ( item.Use
			and item.ComparisonType = DataCompositionComparisonType.Equal ) then
			value = item.RightValue;
		endif;
	endif;
	return value;
	
EndFunction 

&AtClient
Procedure OnChange ( Form, Setting, Updated ) export
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	ReporterForm.ApplySetting ( report, composer, Setting );
	ReporterForm.SetTitle ( Form );
	if ( simpleReport ( report ) ) then
		Form.BuildReport ();
		Updated = true;
	else
		Updated = false;
	endif; 
	
EndProcedure

&AtClient
Function simpleReport ( Report )
	
	return Report = "Testing"
	or Report = "Protocol"
	or Report = "Scenarios";
		
EndFunction 

&AtClient
Procedure ApplySetting ( Report, Composer, Setting ) export

	//@skip-warning
	insertYourCode = true;	
	
EndProcedure 

Procedure SetTitle ( Form ) export
	
	object = Form.Object;
	composer = object.SettingsComposer;
	parts = new Array ();
	parts.Add ( Form.ReportPresentation );
	addPart ( parts, composer, "Period" );
	Form.Title = StrConcat ( parts, ", " );

EndProcedure 

Procedure addPart ( Parts, Composer, Fields )
	
	for each name in StrSplit ( Fields, ", " ) do
		value = findValue ( Composer, name );
		if ( ValueIsFilled ( value ) ) then
			Parts.Add ( value );
		endif; 
	enddo;
	
EndProcedure 

&AtServer
Procedure AfterLoadSettings ( Form ) export
	
	composer = Form.Object.SettingsComposer;
	filterByUser ( composer );
	if ( not Form.ShowSettings ) then
		Form.BuildFilter ();
	endif; 
	
EndProcedure 

&AtServer
Function findSetting ( Composer, Name )
	
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
	endif;
	return item;
	
EndFunction 

&AtServer
Procedure setValue ( Setting, Value )
	
	Setting.Use = true;
	if ( TypeOf ( Setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		Setting.Value = Value;
	else
		Setting.RightValue = Value;
	endif; 
	
EndProcedure 

&AtServer
Procedure filterByUser ( Composer )
	
	setting = findSetting ( Composer, "User" );
	if ( setting = undefined
		or setting.Use ) then
		return;
	endif; 
	setValue ( setting, SessionParameters.User );

EndProcedure 
