// *****************************************
// *********** List

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	postSelection ();
	
EndProcedure

&AtClient
Procedure postSelection ()
	
	data = Items.List.CurrentData;
	NotifyChoice ( new Structure ( "Agent, Computer", data.Ref, data.Computer ) );
	
EndProcedure