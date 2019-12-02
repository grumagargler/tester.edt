
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setFilter ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ScenarioFilter = Parameters.Scenario;
	
EndProcedure 

&AtServer
Procedure setFilter ()
	
	if ( ScenarioFilter = undefined ) then
		CreatorFilter = SessionParameters.User;
		filterByCreator ();
	else
		filterByScenario ();
	endif;
	
EndProcedure 

&AtServer
Procedure filterByCreator ()
	
	DC.ChangeFilter ( List, "Creator", CreatorFilter, not CreatorFilter.IsEmpty () );
	
EndProcedure

&AtServer
Procedure filterByScenario ()
	
	DC.ChangeFilter ( List, "Scenarios.Scenario", ScenarioFilter, not ScenarioFilter.IsEmpty () );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Refresh(Command)
	
	Items.List.Refresh ();
	Items.Agents.Refresh ();
	
EndProcedure

&AtClient
Procedure CreatorFilterOnChange ( Item )
	
	filterByCreator ();
	
EndProcedure

&AtClient
Procedure ScenarioFilterOnChange ( Item )
	
	filterByScenario ();
	
EndProcedure

&AtClient
Procedure AgentFilterOnChange ( Item )
	
	filterByAgent ();
	
EndProcedure

&AtServer
Procedure filterByAgent ()
	
	DC.ChangeFilter ( List, "Agent", AgentFilter, not AgentFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure ModeFilterOnChange ( Item )
	
	filterByMode ();
	
EndProcedure

&AtServer
Procedure filterByMode ()
	
	DC.ChangeFilter ( List, "Mode", ModeFilter, not ModeFilter.IsEmpty () );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "Job" ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.Job );
	endif;
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer ( ItemName, Settings, Rows )
	
	for each item in Rows do
		data = item.Value.Data;
		end = ? ( data.Status = Enums.JobStatuses.Running, CurrentUniversalDateInMilliseconds (), data.Finish );
		data.Duration = Conversion.PeriodToDuration ( data.Start, end );
	enddo;
	
EndProcedure
