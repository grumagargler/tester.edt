// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	setTemplates ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Everywhere = true;
	Variant1 = 1;
	
EndProcedure 

&AtServer
Procedure setTemplates ()
	
	text = Parameters.Text;
	Template1 = "{*}";
	words = StrSplit ( text, " ", false );
	Template2 = "{" + words [ 0 ] + " *}";
	if ( words.Count () > 1 ) then
		Template3 = "{" + words [ 0 ] + " " + words [ 1 ] + " *}";
	else
		Template3 = "{" + text + "}";
	endif; 
	Template4 = "{" + text + "}";
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Replace ( Command )
	
	p = new Structure ( "Template, Everywhere", getTemplate (), Everywhere );
	Close ( p );
	
EndProcedure

&AtClient
Function getTemplate ()
	
	if ( Variant1 = 1 ) then
		return Template1;
	elsif ( Variant2 = 1 ) then
		return Template2;
	elsif ( Variant3 = 1 ) then
		return Template3;
	else
		return Template4;
	endif; 
	
EndFunction 

&AtClient
Procedure Variant1OnChange ( Item )
	
	Variant2 = 0;
	Variant3 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
EndProcedure


&AtClient
Procedure Variant2OnChange ( Item )
	
	Variant1 = 0;
	Variant3 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure Variant3OnChange ( Item )
	
	Variant1 = 0;
	Variant2 = 0;
	Variant4 = 0;
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure Variant4OnChange ( Item )
	
	Variant1 = 0;
	Variant2 = 0;
	Variant3 = 0;
	Appearance.Apply ( ThisObject );
	
EndProcedure
