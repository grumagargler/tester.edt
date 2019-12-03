
Function NotifyTester ( Request )

	create ( Request );
	response = new HTTPServiceResponse ( 200 );
	return response;

EndFunction

Procedure create ( Request )
	
	params = new Structure ( "Headers, Body", Request.Headers, Request.GetBodyAsString () );
	jobKey = "Webhook";
	if ( Jobs.GetBackground ( jobKey ) = undefined ) then
		p = new Array ();
		p.Add ( params );
		BackgroundJobs.Execute ( "Webhook.Go", p, jobKey );
	endif;
	
EndProcedure
