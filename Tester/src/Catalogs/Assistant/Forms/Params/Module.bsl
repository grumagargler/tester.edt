&AtServer
var NameDefined;
&AtClient
var NavigationComplete;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	applyParams ();
	buildExpression ( ThisObject );
	setFocus ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Picking = Parameters.Picking;
	Help = OnlineHelp.Href ( Parameters.Help );
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	Running = Picking;
	params = putMethod ();
	if ( params <> undefined ) then
		putParams ( params );
	endif; 
	if ( Picking ) then
		EnterKeyBehavior = EnterKeyBehaviorType.DefaultButton;
	endif; 

EndProcedure 

&AtServer
Function putMethod ()

	s = Parameters.Method;
	pattern = "(.+)\(";
	matches = Regexp.Select ( s, pattern );
	Method = TrimAll ( matches [ 1 ] );
	pattern = "\((.+)\)";
	matches = Regexp.Select ( s, pattern );
	if ( matches.Count () = 0 ) then
		return undefined;
	endif;
	params = StrSplit ( matches [ 1 ], "," );
	ParamsCount = params.Count ();
	return params;
	
EndFunction 

&AtServer
Procedure putParams ( Params )
	
	NameDefined = ( Parameters.ControlName = "" );
	pattern = "(.+)=(.+)";
	for i = 0 to ParamsCount - 1 do
		p = TrimAll ( Params [ i ] );
		matches = Regexp.Select ( p, pattern );
		if ( matches.Count () = 0 ) then
			label = p;
			mandatory = true;
		else
			label = TrimAll ( matches [ 1 ] );
			mandatory = false;
		endif; 
		field = "Param" + ( i + 1 );
		control = Items [ field ];
		control.Title = label;
		control.MarkIncomplete = mandatory;
		control.AutoChoiceIncomplete = mandatory;
		if ( not NameDefined ) then
			putName ( field, label );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure putName ( Field, Label )
	
	s = Lower ( label );
	if ( s = "name"
		or s = "имя"
		or s = "table"
		or s = "таблица" ) then
		ThisObject [ field ] = """" + Parameters.ControlName + """";
		NameDefined = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure setFocus ()
	
	if ( ParamsCount = 0 ) then
		CurrentItem = Items.Method;
	else
		CurrentItem = Items.Param1;
	endif; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	Appearance.Apply ( ThisObject, "Connected" );
	
EndProcedure

&AtClient
Procedure init ()
	
	Connected = AppData <> undefined and AppData.Connected;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	Close ( getResult () );
	
EndProcedure

&AtClient
Function getResult ()
	
	if ( Picking ) then
		return new Structure ( "Picking, Expression, Running", Picking, Expression, Picking and Running and Connected );
	else
		return Expression;
	endif; 
	
EndFunction 

&AtClient
Procedure ParamStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	ScenarioForm.Picking ( Item, true );
	
EndProcedure

&AtClient
Procedure ParamOnChange ( Item )
	
	if ( Quotes ) then
		quote ( Item.Name );
	endif; 
	buildExpression ( ThisObject );
	
EndProcedure

&AtClient
Procedure quote ( Parameter )
	
	q = """";
	field = ThisObject [ Parameter ];
	text = TrimAll ( field );
	if ( field = ""
		or field = "_"
		or field = "__"
		or Left ( text, 2 ) = "_."
		or Left ( text, 3 ) = "__."
		or ( Left ( text, 1 ) = q
			and Right ( text, 1 ) = q ) ) then
		return;
	endif;
	ThisObject [ Parameter ] = q + StrReplace ( field, q, q + q ) + q;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure buildExpression ( Form )
	
	params = buildParams ( Form );
	if ( params = "" ) then
		Form.Expression = Form.Method + " ();";
	else
		Form.Expression = Form.Method + " ( " + params + " );";
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Function buildParams ( Form )
	
	params = new Array ();
	for i = 0 to Form.ParamsCount - 1 do
		value = Form [ "Param" + ( i + 1 ) ];
		params.Add ( value );
	enddo; 
	i = i - 1;
	while ( i >= 0 ) do
		value = params [ i ];
		if ( ValueIsFilled ( value ) ) then
			break;
		else
			params.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	return StrConcat ( params, ", " );
	
EndFunction 

// *****************************************
// *********** Help

&AtClient
Procedure HelpDocumentComplete ( Item )
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return;
	endif;
	if ( NavigationComplete = undefined ) then
		NavigationComplete = true;
		Item.Document.location.hash = "#" + Parameters.Help;
	endif;

EndProcedure
