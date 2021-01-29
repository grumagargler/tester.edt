
#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function GetNodeData ( Node ) export

	p = new Structure ();
	p.Insert ( "MasterNode", ( ExchangePlans.MasterNode () = undefined ) );
	s = "
	|select
	|	Node.ThisNode as ThisNode, 
	|	ExchangeTransport as ExchangeTransport
	|from 
	|	Catalog.Exchange
	|where 
	|	Ref = &Node 
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );		
	result = q.Execute ();
	selection = result.Select ();
	selection.Next ();
	p.Insert ( "ExchangeTransport", selection.ExchangeTransport );
	p.Insert ( "ThisNode", selection.ThisNode );
	return p; 
	
EndFunction

Procedure WriteAttributes ( Ref, Attributes ) export
	
	object = Ref.GetObject ();
	for each item in Attributes do
		object [ item.Key ] = item.Value;
	enddo; 
	object.Write ();
	
EndProcedure 

#endif