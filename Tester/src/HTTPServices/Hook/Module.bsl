
Function NotifyTester ( Request )

	create ( Request.GetBodyAsString () );
	response = new HTTPServiceResponse ( 200 );
	return response;

EndFunction

Procedure create ( Params )
	
	jobKey = "Webhook";
	if ( Jobs.GetBackground ( jobKey ) = undefined ) then
		p = new Array ();
		p.Add ( Params );
		BackgroundJobs.Execute ( "Webhook.Go", p, jobKey );
	endif;
	
EndProcedure
