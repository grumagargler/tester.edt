// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setDefaults ();
	
EndProcedure

&AtServer
Procedure setDefaults ()
	
	Mode = Enums.Recording.Tester;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	fixLang ();
	
EndProcedure

&AtClient
Procedure fixLang ()
	
	if ( Items.Lang.ChoiceList.FindByValue ( Lang ) = undefined ) then
		Lang = CurrentLanguage ();
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Convert ( Command )
	
	if ( CheckFilling () ) then
		Close ( getLog () );
	endif; 
	
EndProcedure

&AtClient
Function getLog ()
	
	return new Structure ( "Log, Lang, Mode", Log, Lang, Mode );
	
EndFunction

&AtClient
Procedure ModeClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure
 
