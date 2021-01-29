
&AtClient
Procedure CommandProcessing ( Scenarios, ExecuteParameters )
	
	p = new NotifyDescription ( "TargetSelected", ThisObject, Scenarios );
	OpenForm ( "Catalog.Scenarios.ChoiceForm", , , , , , p );
	
EndProcedure

&AtClient
Procedure TargetSelected ( Target, Scenarios ) export
	
	if ( Target = undefined ) then
		return;
	endif;
	if ( not Target.IsEmpty () ) then
		ScenariosPanel.Save ( Target );
	endif;
	ScenarioForm.CopyMove ( Scenarios, Target, true );
	
EndProcedure
