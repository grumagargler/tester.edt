
Procedure AssembleTemplate ( Data, Scenario ) export
	
	error = "";
	tabDoc = getSpreadsheet ( Data, error );
	if ( tabDoc = undefined ) then
		Output.ScenarioTemplateLoadingError ( new Structure ( "Scenario, Error", Scenario, Error ) );
		return;
	endif;
	anchor = Max ( 1, tabDoc.TableHeight - 1 );
	areas = Scenario.Areas;
	signature = tabDoc.Area ( anchor, 1, anchor, 1 ).Text;
	if ( signature = RepositoryFiles.Signature () ) then
		table = areas.UnloadColumns ();
		anchor = anchor + 1;
		set = Conversion.FromJSON ( tabDoc.Area ( anchor, 1, anchor, 1 ).Text );
		for each row in set do
			newRow = table.Add ();
			FillPropertyValues ( newRow, row );
		enddo; 
		areas.Load ( table );
		tabDoc = tabDoc.GetArea ( "R1:R" + Format ( anchor - 2, "NG=" ) );
	else
		areas.Clear ();
	endif;
	Scenario.Template = new ValueStorage ( tabDoc );
	Scenario.Spreadsheet = true;
	
EndProcedure

Function getSpreadsheet ( Data, Error )
	
	storage = ? ( TypeOf ( Data ) = Type ( "BinaryData" ), Data, GetFromTempStorage ( Data ) );
	stream = storage.OpenStreamForRead ();
	tabDoc = new SpreadsheetDocument ();
	try
		tabDoc.Read ( stream );
	except
		Error = ErrorDescription ();
		return undefined;
	endtry;
	stream.Close ();
	return tabDoc;
	
EndFunction 

Procedure ResetTemplate ( Scenario ) export
	
	Scenario.Template = new ValueStorage ( new SpreadsheetDocument () );
	Scenario.Areas.Clear ();
	Scenario.Spreadsheet = false;

EndProcedure

Procedure Properties ( Data, Scenario ) export
	
	params = Conversion.FromJSON ( Data );
	Scenario.Tree = params.Tree;
	Scenario.Creator = getCreator ( params.Creator );
	Scenario.LastCreator = getCreator ( params.LastCreator );
	Scenario.Tag = Catalogs.TagKeys.Pick ( params.Tags );
	Scenario.Type = Enums.Scenarios [ params.Type ];
	Scenario.Severity = ? ( params.Severity = "", undefined, Enums.Severity [ params.Severity ] );
	Scenario.Memo = params.Memo;
	
EndProcedure

Function getCreator ( User )
	
	ref = Catalogs.Users.FindByDescription ( User, true );
	if ( ref.IsEmpty () ) then
		obj = Catalogs.Users.CreateItem ();
		obj.Description = User;
		obj.AccessDenied = true;
		obj.DataExchange.Load = true;
		obj.Write ();
		ref = obj.Ref;
	endif;
	return ref;
	
EndFunction