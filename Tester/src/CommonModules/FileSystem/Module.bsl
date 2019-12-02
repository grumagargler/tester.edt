
&AtServer
Function SpreadsheetType ( TableType ) export
	
	if ( TableType = Enums.TableTypes.PDF ) then
		return SpreadsheetDocumentFileType.PDF;
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return SpreadsheetDocumentFileType.XLS;
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return SpreadsheetDocumentFileType.XLSX;
	elsif ( TableType = Enums.TableTypes.DOCX ) then
		return SpreadsheetDocumentFileType.DOCX;
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return SpreadsheetDocumentFileType.ODS;
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return SpreadsheetDocumentFileType.MXL;
	endif; 
	
EndFunction 

&AtServer
Function TableExtension ( TableType ) export
	
	if ( TableType = Enums.TableTypes.DOCX ) then
		return "docx";
	elsif ( TableType = Enums.TableTypes.PDF ) then
		return "pdf";
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return "xls";
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return "xlsx";
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return "mxl";
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return "ods";
	endif; 
	
EndFunction 

Function GetBaseName ( File ) export

	dot = StrFind ( File, ".", SearchDirection.FromEnd );
	return ? ( dot = 0, File, Mid ( File, 1, dot - 1 ) );

EndFunction

Function Extension ( File ) export

	pos = 0;
	ext = File;
	while ( true ) do
		pos = Find ( ext, "." );
		if ( not pos ) then
			break;
		else
			ext = Mid ( ext, pos + 1 );
		endif;
	enddo;
	return ?( ext = File, "", "." + Lower ( ext ) );

EndFunction

&AtClient
Function RemoveSlash ( Path ) export
	
	s = TrimAll ( Path );
	while ( StrEndsWith ( s, GetPathSeparator () ) ) do
		s = Left ( s, StrLen ( s ) - 1 );
	enddo; 
	return s;
	
EndFunction

&AtServer
Function GetParent ( Folder, Separator ) export
	
	i = StrFind ( Folder, Separator, SearchDirection.FromEnd );
	if ( i = 0 ) then
		return undefined;
	else
		return Left ( Folder, i - 1 );
	endif;

EndFunction