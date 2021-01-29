// *****************************************
// *********** Form events

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageApplicationSettingsSaved () );
	
EndProcedure
