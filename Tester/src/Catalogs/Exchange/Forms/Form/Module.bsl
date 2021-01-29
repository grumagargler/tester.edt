
&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	fillNodeData ( ThisObject, CurrentObject.Node );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	fillAttributes ();
	AppearanceSrv.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()	
	
	Object.ExchangeTransport = Enums.ExchangeTransport.NetworkDisk; 
	Object.UseAutomatic = true;
	Object.Periodicity = Enums.ExchangePeriodicity.Constant;
	Object.Update = false;
	Object.NumbersOfErrors = 3;
	Object.PrefixFileName = "";
	Object.ServerTimeOut = 10;
	Object.Protocol = Enums.Protocols.IMAP;
	Object.UseStandartFTPClient = true;
	Object.UseSSLIncoming = false;
	setPortIncoming ( Object );
	Object.UseSSLOutgoing = false;
	setPortOutgoing ( Object );
	
EndProcedure

&AtServer
Procedure fillAttributes ()
	
	TypeExchange = ? ( Object.UseAutomatic, 2, 1 );
	ThisNode = getThisNode ( Object.Node );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( ValueIsFilled ( CurrentObject.Node ) and CurrentObject.Ref.IsEmpty () ) then
		Cancel = checkNode ( CurrentObject.Node );
	endif;
	
EndProcedure

&AtServer
Function checkNode ( Node )
	
	s = "
	|select Ref as Ref
	|from Catalog.Exchange
	|where Node = &Node
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );		
	result = q.Execute ();
	if ( result.IsEmpty () ) then
		error = false
	else
		error = true;
		Output.ExchangeDataItemAlreadyExist ( new Structure ( "Code", Node.Code ) );
	endif;
	return error; 
		
EndFunction

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

EndProcedure

&AtClient
Procedure ExchangeTransportOnChange ( Item )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure TypeExchangeOnChange ( Item )
	
	Object.UseAutomatic = ? ( TypeExchange = 2, true, false );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure NodeOnChange ( Item )
	
	Object.Code = getCodeNode ( Object.Node );
	ThisNode = getThisNode ( Object.Node );
	if ( ThisNode ) then
		Output.SelectThisNode ();
	endif; 
	Appearance.Apply ( ThisObject );
	fillNodeData ( ThisObject, Object.Node ); 
	
EndProcedure

&AtServerNoContext
Function getCodeNode ( Node )
	
	if ( ValueIsFilled ( Node ) ) then
		code = Node.Code;
	else
		code = "";
	endif; 
	return code; 
	
EndFunction 

&AtClient
Procedure PathStartChoice ( Item, ChoiceData, StandardProcessing )
	
	selectDirectory ( Item.Name );
	
EndProcedure

&AtClient
Procedure selectDirectory ( Name )
	
	p = new Structure ( "Attribute", Name );
	LocalFiles.Prepare ( new NotifyDescription ( "OpenDialog", ThisObject, p ) );
	
EndProcedure 

&AtClient
Procedure OpenDialog ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Directory = getDirectory ( Params.Attribute );
	dialog.Show ( new NotifyDescription ( "SetAttribute", ThisObject, Params ) );
	
EndProcedure 

&AtClient
Function getDirectory ( Attribute )
	
	path = Object [ Attribute ];
	directory = "";
	if ( path = "" ) then
		return directory;
	endif; 
	c = StrLen ( path );
	while c > 0 do
		if ( Mid ( path, c, 1 ) = "\" ) then
			directory = Mid ( path, 1, ( c - 1 ) );
			break;
		endif; 
		c = c - 1;		
	enddo;
	return directory; 

EndFunction

&AtClient
Procedure SetAttribute ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Object [ Params.Attribute ] = Result [ 0 ];
	Modified = true;
	
EndProcedure

&AtClient
Procedure PrefixFileNameOnChange ( Item )
	
	Output.ChangePrefixFileName ();
	
EndProcedure

&AtClient
Procedure UseSSLOutgoingOnChange ( Item )
	
	setPortOutgoing ( Object );	
	
EndProcedure

&AtClientAtServerNoContext
Procedure setPortOutgoing ( Object )
	
	if ( Object.UseSSLOutgoing ) then
		Object.PortOutgoing = 465;
	else
		Object.PortOutgoing = 25;
	endif; 
	
EndProcedure

&AtClient
Procedure ProtocolOnChange ( Item )
	
	setPortIncoming ( Object );
	
EndProcedure

&AtClient
Procedure UseSSLIncomingOnChange ( Item )
	
	setPortIncoming ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setPortIncoming ( Object )
	
	if ( Object.Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		if ( Object.UseSSLIncoming ) then
			Object.PortIncoming = 993;
		else
			Object.PortIncoming = 143;
		endif; 
	elsif ( Object.Protocol = PredefinedValue ( "Enum.Protocols.POP3" ) ) then
		if ( Object.UseSSLIncoming ) then
			Object.PortIncoming = 995;
		else
			Object.PortIncoming = 110;
		endif; 
	endif;	
	
EndProcedure

&AtClient
Procedure TestConnectionCommand ( Command )
	
	testConnection ();
	
EndProcedure 

&AtClient
Procedure testConnection ()
	
	testConnectionSrv ();
	
EndProcedure

&AtServer
Procedure testConnectionSrv ()
	
	profile = getProfile ();
	email = new InternetMail ();
	protocol = getMailProtocol ( Object.Protocol );
	try
		email.Logon ( profile, protocol );
		Output.LogonSuccess ();
	except 
		Output.ErrorConnectEmailProfile ( new Structure ( "Error", ErrorDescription () ) );
	endtry;	
	
EndProcedure 

&AtServer
Function getProfile ()
	
	p = new InternetMailProfile ();
	p.User = TrimAll ( Object.UserEmail );
	p.Password = TrimAll ( Object.PasswordEmail );
	p.SMTPServerAddress = TrimAll ( Object.ServerOutgoing );
	p.SMTPUser = TrimAll ( Object.UserEmail );
	p.SMTPPassword = TrimAll ( Object.PasswordEmail );
	p.SMTPUseSSL = Object.UseSSLOutgoing;
	p.SMTPPort = Object.PortOutgoing;
	if ( Object.Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		p.IMAPUser = TrimAll ( Object.UserEmail );
		p.IMAPPassword = TrimAll ( Object.PasswordEmail );
		p.IMAPPort = Object.PortIncoming;
		p.IMAPServerAddress = TrimAll ( Object.ServerIncoming );
		p.IMAPUseSSL = Object.UseSSLIncoming;
	else
		p.POP3Port = Object.PortIncoming;
		p.POP3ServerAddress = TrimAll ( Object.ServerIncoming );
		p.POP3UseSSL = Object.UseSSLIncoming;
	endif; 
	return p;
	
EndFunction

&AtServer  
Function getMailProtocol ( Protocol )
	
	if ( Protocol = PredefinedValue ( "Enum.Protocols.POP3" ) ) then
		p = InternetMailProtocol.POP3;
	elsif ( Protocol = PredefinedValue ( "Enum.Protocols.IMAP" ) ) then
		p = InternetMailProtocol.IMAP;
	else
		p = InternetMailProtocol.POP3;
	endif;
	return p;
	
EndFunction 

&AtServerNoContext
Function getThisNode ( Node )
	
	if ( ValueIsFilled ( Node ) ) then
		ThisNode = Node.ThisNode; 
	else
		ThisNode = false;
	endif;
	return ThisNode; 
	
EndFunction 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( ThisNode ) then
		Output.SelectThisNode ();
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillNodeData ( Form, Node )
	
	data = getNodeData ( Node );
	Form.ReceivedNo = data.ReceivedNo;
	Form.SentNo = data.SentNo;
	
EndProcedure

&AtServerNoContext
Function getNodeData ( Node )
	
	p = new Structure ();
	p.Insert ( "ReceivedNo", 0 );
	p.Insert ( "SentNo", 0 );
	if ( ValueIsFilled ( Node ) ) then
		s = "
		|select
		|	ReceivedNo as ReceivedNo,
		|	SentNo as SentNo
		|from               
		|	ExchangePlan.Full
		|where
		|	Ref = &Ref 
		|";
		q = new Query ( s );
		q.SetParameter ( "Ref", Node );		
		result = q.Execute ();
		selection = result.Select ();
		selection.Next ();
		p.ReceivedNo = selection.ReceivedNo;
		p.SentNo = selection.SentNo;
	endif; 
	return p; 
	
EndFunction 