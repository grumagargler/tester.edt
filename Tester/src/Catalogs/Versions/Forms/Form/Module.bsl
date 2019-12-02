// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	restoreTemplate ( CurrentObject );
	
EndProcedure

&AtServer
Procedure restoreTemplate ( Scenario )
	
	TabDoc = Scenario.Template.Get ();
	entitleTemplate ();
	markAreas ();
	
EndProcedure 

&AtServer
Procedure entitleTemplate ()
	
	caption = Output.TemplateCaption ();
	if ( 0 < ( TabDoc.TableWidth + TabDoc.TableHeight ) ) then
		caption = caption + " *";
	endif; 
	Items.PageTemplate.Title = caption;
	
EndProcedure 

&AtServer
Procedure markAreas ()
	
	noline = new Line ( SpreadsheetDocumentCellLineType.None );
	redLine = new Line ( SpreadsheetDocumentCellLineType.LargeDashed, 3 );
	redColor = new Color ( 255, 0, 0 );
	for each item in Object.Areas do
		area = TabDoc.Area ( item.Name );
		area.TopBorder = noline;
		area.LeftBorder = noline;
		area.RightBorder = noline;
		area.BottomBorder = noline;
		area.Outline ( redLine, redLine, redLine, redLine );
		area.BorderColor = redColor;
	enddo; 
			
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	ScenariosPanel.Push ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageActivateError ()
		or EventName = Enum.MessageDebugger () ) then
		if ( Source = Object.Ref ) then
			activateEditor ();
			activateRow ( Parameter );
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure activateEditor () export
	
	CurrentItem = Items.Script;
	
EndProcedure 

&AtClient
Procedure activateRow ( Line )
	
	Items.Script.SetTextSelectionBounds ( Line, 1, Line, StrLen ( StrGetLine ( Object.Script, Line ) ) + 1 );
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	ScenariosPanel.Pop ( Object.Ref );
	
EndProcedure
