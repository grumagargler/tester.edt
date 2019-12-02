Procedure Init () export
	
	OpenedScenarios = new Map ();
	
EndProcedure 

Procedure Push ( Form ) export
	
	ref = Form.Object.Ref;
	if ( ref.IsEmpty () ) then
		return;
	endif; 
	OpenedScenarios [ ref ] = Form;
	
EndProcedure 

Procedure Pop ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form = undefined ) then
		return;
	endif; 
	OpenedScenarios.Delete ( Scenario );
	
EndProcedure 

Function TryActivate ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form = undefined ) then
		return false;
	endif;
	form.Activate ();
	return true;
	
EndFunction 

Procedure Save ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form <> undefined
		and form.Modified ) then
		form.Write ();
	endif;
	
EndProcedure

Procedure Reread ( Scenario ) export
	
	form = OpenedScenarios [ Scenario ];
	if ( form <> undefined
		and not form.Modified ) then
		form.Reread ();
	endif;
	
EndProcedure