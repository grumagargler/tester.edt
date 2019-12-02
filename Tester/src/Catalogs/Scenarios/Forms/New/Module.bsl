// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		ScenarioForm.Init ( ThisObject );
	endif; 
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not ScenarioForm.SaveParents ( Object, undefined ) ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	ScenarioForm.RereadParents ( Object, undefined );
	ref = Object.Ref;
	if ( Main ) then
		Environment.ChangeScenario ( ref );
	endif;
	type = Object.Type;
	if ( type = PredefinedValue ( "Enum.Scenarios.Scenario" )
		or type = PredefinedValue ( "Enum.Scenarios.Method" ) ) then
		OpenForm ( "Catalog.Scenarios.ObjectForm", new Structure ( "Key", ref ) );
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	Object.Description = TrimAll ( Object.Description );
	
EndProcedure

&AtClient
Procedure TypeOnChange ( Item )
	
	applyType ();
	
EndProcedure

&AtClient
Procedure applyType ()
	
	type = Object.Type;
	if ( type = PredefinedValue ( "Enum.Scenarios.Scenario" )
		or type = PredefinedValue ( "Enum.Scenarios.Method" ) ) then
	else
		Object.Severity = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Type" );
	
EndProcedure
