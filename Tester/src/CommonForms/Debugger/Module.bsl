&AtClient
var Closing;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	IsVersion = Parameters.IsVersion;
	Row = Parameters.Row;
	code = Parameters.Module;
	Scenario = ? ( IsVersion, Catalogs.Versions.FindByCode ( code ), Catalogs.Scenarios.FindByCode ( code ) );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( ScenariosPanel.TryActivate ( Scenario ) ) then
		Notify ( Enum.MessageDebugger (), Row, Scenario );
		loadEvaluation ();
	else
		complete ( Enum.DebuggerOpenScenario () );
		return;
	endif;
	
EndProcedure

&AtClient
Procedure loadEvaluation ()
	
	EvaluationResult = Debug.EvaluationResult;
	Items.EvaluationResult.TextColor = ? ( Debug.EvaluationError, new Color ( 255, 0, 0 ), new Color ( 0, 128, 0 ) );
	
EndProcedure 

&AtClient
Procedure complete ( Command )
	
	if ( Closing ) then
		return;
	endif; 
	Closing = true;
	result = getResult ( Command );
	Close ( result );
	
EndProcedure 

&AtClient
Function getResult ( Command )
	
	p = new Structure ();
	p.Insert ( "Command", Command );
	p.Insert ( "Scenario", Scenario );
	p.Insert ( "Expression", Expression );
	return p;
	
EndFunction 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Closing ) then
		return;
	endif; 
	Cancel = true;
	complete ( Enum.DebuggerStop () );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Step ( Command )
	
	complete ( Enum.DebuggerStepInto () );
	
EndProcedure

&AtClient
Procedure StepOver ( Command )
	
	complete ( Enum.DebuggerStepOver () );
	
EndProcedure

&AtClient
Procedure StopScenario ( Command )
	
	complete ( Enum.DebuggerStop () );
	
EndProcedure

&AtClient
Procedure ContinueRunning ( Command )
	
	complete ( Enum.DebuggerContinue () );
	
EndProcedure

&AtClient
Procedure Evaluate ( Command )
	
	calcResult ();
	
EndProcedure

&AtClient
Procedure calcResult ()
	
	if ( Closing
		or IsBlankString ( Expression ) ) then
		return;
	endif; 
	complete ( Enum.DebuggerEval () );
	
EndProcedure 

&AtClient
Procedure ExpressionOnChange ( Item )
	
	calcResult ();
	
EndProcedure

// *****************************************
// *********** Variables Initialization

Closing = false;