&AtClient
Procedure Toggle ( On ) export
	
	Debug.Debugging = On;
	stopSteppingOver ();
	
EndProcedure 

&AtClient
Procedure stopSteppingOver ()
	
	Debug.SteppingOver = false;
	Debug.SteppingOverPoint = undefined;
	
EndProcedure 

Function Line ( Chronograph, DebugInfo, Module, Row, IsVersion, Scenario = undefined, Progress = undefined ) export
	
	Debugger.ShowProgress ( DebugInfo, Scenario, Progress );
	noerrors ( DebugInfo );
	logging ( Chronograph, DebugInfo, Module, Row, IsVersion );
	checkCancelation ( DebugInfo );
	#if ( ThinClient or ThickClientManagedApplication ) then
		UserInterruptProcessing ();
		if ( DebugInfo.Debugging
			and not DebugInfo.Running ) then
			command = debugging ( Module, Row, IsVersion );
			if ( command = Enum.DebuggerEval () ) then
				return command;
			endif;
		endif; 
	#endif
	stack = DebugInfo.Stack;
	level = DebugInfo.Level;
	if ( stack.Count () <= DebugInfo.Level ) then
		stack.Add ();
	endif;
	stack [ level ] = new Structure ( "Module, Row, IsVersion", Module, Row, IsVersion );
	#if ( ThinClient or ThickClientManagedApplication ) then
		delay ();
	#endif
	DebugInfo.Pointer = DebugInfo.Pointer + 1;
	return undefined;
	
EndFunction

Procedure ShowProgress ( DebugInfo, Scenario, Progress ) export
	
	// Do not exclude the procedure from server
	// because it is used in compilation module
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( Progress <> undefined
			and DebugInfo.ShowProgress ) then
			Status ( Scenario, Progress );
		endif;
	#endif
	
EndProcedure

Procedure noerrors ( DebugInfo )
	
	if ( DebugInfo.Error ) then
		DebugInfo.Error = false;
		DebugInfo.FallenScenario = undefined;
		DebugInfo.ErrorLog = undefined;
		DebugInfo.ErrorLine = undefined;
		DebugInfo.ApplicationStack = undefined;
	endif; 
	
EndProcedure 

Procedure logging ( Chronograph, DebugInfo, Module, Row, IsVersion )
	
	if ( not DebugInfo.Recording ) then
		return;
	endif;
	p = new Structure ( "Scenario, Module, Row, Screenshot, Pointer" );
	recordingContext ( Chronograph, Module, IsVersion );
	p.Scenario = Chronograph.Scenario;
	p.Module = Chronograph.Module;
	p.Row = Row;
	p.Pointer = DebugInfo.Pointer;
	#if ( ThinClient or ThickClientManagedApplication ) then
		p.Screenshot = Screenshot ();
	#endif
	RuntimeSrv.Recording ( p );
	
EndProcedure

Procedure recordingContext ( Chronograph, Module, IsVersion )
	
	if ( Chronograph.Scenario = undefined ) then
		data = RuntimeSrv.RecordingContext ( Module, IsVersion );
		value = data.Scenario;
		Chronograph.Scenario = value;
		Chronograph.Сценарий = value;
		value = data.Module;
		Chronograph.Module = value;
		Chronograph.Модуль = value;
	endif;
	
EndProcedure

Procedure checkCancelation ( DebugInfo )
	
	job = DebugInfo.Job;
	if ( job = undefined ) then
		return;
	endif;
	#if ( Server ) then
		now = CurrentSessionDate ();
	#else
		now = CurrentDate ();
	#endif
	if ( ( now - DebugInfo.CancelationCheck ) > 5 ) then
		if ( TesterAgent.Canceled ( job.Job ) ) then
			DebugInfo.JobCanceled = true;
			raise Output.JobCanceled ();
		endif;
		DebugInfo.CancelationCheck = now;
	endif;
	
EndProcedure

&AtClient
Function debugging ( Module, Row, IsVersion )

	if ( Debug.SteppingOver ) then
		point = Debug.SteppingOverPoint;
		if ( point.Module = Module
			and point.Level = Debug.Level
			and point.IsVersion = IsVersion
			and point.Row < Row )
			or ( point.Level > Debug.Level ) then
			stopSteppingOver ();
		else
			return undefined;
		endif; 
	endif; 
	result = askUser ( Module, Row, IsVersion );
	Debug.Evaluate = result.Expression;
	command = result.Command;
	if ( command = undefined
		or command = Enum.DebuggerContinue () ) then
		Debugger.Toggle ( false );
	elsif ( command = Enum.DebuggerStepInto () ) then
	elsif ( command = Enum.DebuggerStepOver () ) then
		startSteppingOver ( Module, Row, IsVersion );
	elsif ( command = Enum.DebuggerStop () ) then
		stopDebugging ();
	elsif ( command = Enum.DebuggerOpenScenario () ) then
		openScenario ( result.Scenario );
		debugging ( Module, Row, IsVersion );
	elsif ( command = Enum.DebuggerEval () ) then
		Debug.Evaluate = result.Expression;
	endif; 
	return command;
	
EndFunction 

//@skip-warning
&AtClient
Function askUser ( Module, Row, IsVersion )
	
	#if ( not WebClient ) then
		p = new Structure ( "Module, Row, IsVersion", Module, Row, IsVersion );
		return OpenFormModal ( "CommonForm.Debugger", p );
	#endif
	
EndFunction 

&AtClient
Procedure startSteppingOver ( Module, Row, IsVersion )
	
	p = steppingPoint ();
	p.Level = Debug.Level;
	p.Module = Module;
	p.Row = Row;
	p.IsVersion = IsVersion;
	Debug.SteppingOverPoint = p;
	Debug.SteppingOver = true;
		
EndProcedure 

&AtClient
Procedure stopDebugging ()
	
	Debug.DebuggingStopped = true;
	raise Output.StopDebugging ();
		
EndProcedure 

&AtClient
Function steppingPoint ()
	
	p = new Structure ();
	p.Insert ( "Level" );
	p.Insert ( "Module" );
	p.Insert ( "Row" );
	p.Insert ( "IsVersion" );
	return p;
	
EndFunction 

&AtClient
Procedure openScenario ( Scenario )
	
	p = new Structure ( "Key", Scenario );
	if ( TypeOf ( Scenario ) = Type ( "CatalogRef.Versions" ) ) then
		OpenForm ( "Catalog.Versions.ObjectForm", p );
	else
		OpenForm ( "Catalog.Scenarios.ObjectForm", p );
	endif; 
	
EndProcedure 

&AtClient
Procedure delay ()
	
	delay = Debug.Delay;
	if ( delay = 0 ) then
		return;
	endif; 
	stop = CurrentUniversalDateInMilliseconds () + delay;
	while ( CurrentUniversalDateInMilliseconds () <= stop ) do
		UserInterruptProcessing ();
	enddo; 
	
EndProcedure 

Procedure ErrorCheck ( DebugInfo ) export
	
	if ( DebugInfo.JobCanceled ) then
		raise Output.JobCanceled ();
	endif;
	// If scenario code is here then no more errors.
	// For example: try-catch hooks errors. If we don't suppress error then
	// that old error will cause problems again
	noerrors ( DebugInfo );
	#if ( ThinClient or ThickClientManagedApplication ) then
		if ( IgnoreErrors
			or ИгнорироватьОшибки ) then
			return;
		endif;
		if ( not AppData.Connected ) then
			return;
		endif; 
		try // In case of TestedApplication timeout
			error = App.GetCurrentErrorInfo ();
		except
			error = undefined;
		endtry;
		if ( error = undefined ) then
			DebugInfo.PreviousError = undefined;
		else
			// In order to perevent raising the same error through the whole call stack,
			// we verify the message each time when error occurs. In addition, executed scenario
			// will be able to catch this error message using try-catch construction.
			description = error.Description;
			if ( DebugInfo.PreviousError = undefined
				or DebugInfo.PreviousError <> description ) then
				DebugInfo.PreviousError = description;
				DebugInfo.ApplicationStack = DetailErrorDescription ( error );
				// Pass this error on previous level
				Runtime.ThrowError ( description, DebugInfo );
			endif; 
		endif; 
	#endif
	
EndProcedure

&AtClient
Procedure Recording ( Start ) export
	
	Debug.Recording = Start;
	
EndProcedure

&AtClient
Procedure EnableProgress () export
	
	Debug.ShowProgress = true;
	
EndProcedure

&AtClient
Procedure DisableProgress () export
	
	Status ();
	Debug.ShowProgress = false;
	
EndProcedure
