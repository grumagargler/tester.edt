
#region Messages

&AtClient
Function MessageSaveAll () export
	
	return "1";
	
EndFunction 

&AtClient
Function MessageActivateError () export
	
	return "2";
	
EndFunction 

&AtClient
Function MessageMainScenarioChanged () export
	
	return "3";
	
EndFunction 

&AtClient
Function MessageUserGroupCreated () export
	
	return "4";
	
EndFunction 

&AtClient
Function MessageUserRightsChanged () export
	
	return "5";
	
EndFunction 

&AtClient
Function MessageUserGroupModified () export
	
	return "6";
	
EndFunction 

&AtClient
Function MessageSave () export
	
	return "7";
	
EndFunction 

&AtClient
Function MessageReload () export
	
	return "8";
	
EndFunction 

&AtClient
Function MessageLocked () export
	
	return "9";
	
EndFunction 

&AtClient
Function MessageStored () export
	
	return "10";
	
EndFunction 

&AtClient
Function MessageApplicationSettingsSaved () export
	
	return "11";
	
EndFunction 

&AtClient
Function MessageDebugger () export
	
	return "12";
	
EndFunction 

&AtClient
Function MessageApplicationChanged () export
	
	return "13";
	
EndFunction 

#endregion

#region Settings

&AtServer
Function SettingsShowSettingsButtonState () export
	
	return "ShowSettingsButtonState";
	
EndFunction 

Function SettingsWorkplaceFilter () export
	
	return "WorkplaceFilter";
	
EndFunction 

#endregion

#region Debugger

&AtClient
Function DebuggerStop () export
	
	return "DebuggerStop";
	
EndFunction 

&AtClient
Function DebuggerContinue () export
	
	return "DebuggerContinue";
	
EndFunction 

&AtClient
Function DebuggerStepInto () export
	
	return "DebuggerStepInto";
	
EndFunction 

&AtClient
Function DebuggerStepOver () export
	
	return "DebuggerStepOver";
	
EndFunction 

&AtClient
Function DebuggerOpenScenario () export
	
	return "DebuggerOpenScenario";
	
EndFunction 

&AtClient
Function DebuggerEval () export
	
	return "DebuggerEval";
	
EndFunction 

#endregion

#region ExternalRequests

&AtClient
Function ExternalRequestsSaveFile () export
	
	return "SaveFile";
	
EndFunction 

&AtClient
Function ExternalRequestsNewFile () export
	
	return "NewFile";
	
EndFunction 

&AtClient
Function ExternalRequestsRenaming () export
	
	return "Renaming";
	
EndFunction 

&AtClient
Function ExternalRequestsRemoving () export
	
	return "Removing";
	
EndFunction 

&AtClient
Function ExternalRequestsRun () export
	
	return "Run";
	
EndFunction 

&AtClient
Function ExternalRequestsCheckSyntax () export
	
	return "CheckSyntax";
	
EndFunction 

&AtClient
Function ExternalRequestsSaveBeforeCheckSyntax () export
	
	return "SaveBeforeCheckSyntax";
	
EndFunction 

&AtClient
Function ExternalRequestsSaveBeforeRun () export
	
	return "SaveBeforeRun";
	
EndFunction 

&AtClient
Function ExternalRequestsSetMain () export
	
	return "SetMain";
	
EndFunction 

&AtClient
Function ExternalRequestsSaveBeforeRunSelected () export
	
	return "SaveBeforeRunSelected";
	
EndFunction 

&AtClient
Function ExternalRequestsRunSelected () export
	
	return "RunSelected";
	
EndFunction 

&AtClient
Function ExternalRequestsSaveBeforeAssigning () export
	
	return "SaveBeforeAssigning";
	
EndFunction 

&AtClient
Function ExternalRequestsPickField () export
	
	return "PickField";
	
EndFunction 

&AtClient
Function ExternalRequestsPickScenario () export
	
	return "PickScenario";
	
EndFunction 

&AtClient
Function ExternalRequestsGenerateID () export
	
	return "GenerateID";
	
EndFunction 

#endregion

#region ExternalStatuses

&AtClient
Function ExternalStatusesCompleted () export
	
	return "Completed";
	
EndFunction 

#endregion

#region MessageTypes

&AtClient
Function MessageTypesInfo () export
	
	return "I";
	
EndFunction 

&AtClient
Function MessageTypesError () export
	
	return "E";
	
EndFunction 

&AtClient
Function MessageTypesWarning () export
	
	return "W";
	
EndFunction 

&AtClient
Function MessageTypesHint () export
	
	return "H";
	
EndFunction 

&AtClient
Function MessageTypesPopup () export
	
	return "P";
	
EndFunction 

&AtClient
Function MessageTypesPopupWarning () export
	
	return "PW";
	
EndFunction 

#endregion

#region Framework

&AtClient
Function FrameworkManagedForm () export
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		return "ManagedForm";
	else
		return "ClientApplicationForm";
	endif;
	
EndFunction

#endregion

#region Others

&AtServer
Function OthersVersionPrefix () export
	
	return "v.";
	
EndFunction

#endregion

#region ReportCommands

Function ReportCommandsOpenModule () export
	
	return "ReportCommandsOpenModule";
	
EndFunction

#endregion