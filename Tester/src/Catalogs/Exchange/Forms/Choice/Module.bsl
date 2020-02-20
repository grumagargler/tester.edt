
&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure