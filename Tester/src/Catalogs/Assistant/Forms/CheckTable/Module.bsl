&AtClient
var TableField;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	
EndProcedure

&AtServer
Procedure init ()
	
	Splitter = "|";
	Method = TrimR ( Left ( Parameters.Method, StrFind ( Parameters.Method, "(" ) - 1 ) );
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	try
		fill ();
	except
		raise Output.ErrorObtainingTableParameters ();
	endtry;
	
EndProcedure

&AtClient
Procedure fill ()
	
	With ( Parameters.Form );
	field = Type ( "TestedFormField" );
	TableField = Get ( Parameters.Table );
	for each column in TableField.GetChildObjects () do
		if ( TypeOf ( column ) <> field ) then
			continue;
		endif;
		row = TestingTable.Add ();
		row.Title = column.TitleText;
		name = column.Name;
		row.Name = name;
		try
			TableField.GetCellText ( name );
			available = true;
		except
			available = false;
		endtry;
		row.Check = available;
	enddo;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkColumns () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtServer
Function checkColumns ()
	
	for each row in TestingTable do
		if ( row.Check ) then
			return true;
		endif;
	enddo;
	Output.ColumnsNotSelected ();
	return false;
	
EndFunction

// *****************************************
// *********** TestingTable

&AtClient
Procedure OK ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	Close ( TableProcessor.CheckingScript ( Method, TableField, selectedColumns (), ByNames, Splitter ) );
		
EndProcedure

&AtClient
Function selectedColumns ()
	
	list = new Array ();	
	for each row in TestingTable do
		if ( row.Check ) then
			list.Add ( ? ( ByNames, row.Name, row.Title ) );
		endif;
	enddo;
	return list;
	
EndFunction

&AtClient
Procedure MarkAll ( Command )
	
	checkbox ( true );
	
EndProcedure

&AtClient
Procedure checkbox ( Value )
	
	for each row in TestingTable do
		row.Check = Value;
	enddo; 
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( Command )
	
	checkbox ( false );
	
EndProcedure

