
&AtClient
Procedure CommandProcessing ( User, ExecuteParameters )

	OpenForm ( "ExchangePlan.Repositories.ListForm", new Structure ( "User", User ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL);

EndProcedure
