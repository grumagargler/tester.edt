// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		ScenarioForm.Init ( ThisObject );
	endif; 
	
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
	RepositoryFiles.Sync ();
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
