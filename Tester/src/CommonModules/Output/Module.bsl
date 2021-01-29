
Function Sformat ( Str, Params ) export
	
	if ( Params = undefined
		or StrFind ( Str, "%" ) = 0 ) then
		return Str;
	endif; 
	result = Str;
	p = new Array ();
	for each parameter in Params do
		p.Add ( parameter.Key );
	enddo;
	indexOfMax = 0;
	while ( true ) do
		i = 0;
		max = 0;
		for each param in p do
			a = StrLen ( param );
			if ( a > max ) then
				max = a;
				indexOfMax = i;
			endif; 
			i = i + 1;
		enddo;
		k = p [ indexOfMax ];
		p.Delete ( indexOfMax );
		result = StrReplace ( result, "%" + k, Params [ k ] );
		if ( p.UBound () = -1 ) then
			break;
		endif; 
	enddo; 
	return result;
	
EndFunction

Procedure PutMessage ( Text, Params, Field, DataKey, DataPath, Form = undefined ) export
	
	msg = new UserMessage ();
	s = Output.Sformat ( Text, Params );
	interactive = ( Params = undefined  ) or not Params.Property ( "_Interactive" ) or Params._Interactive;
	if ( interactive ) then
		msg.DataPath = DataPath;
		msg.Field = Field;
		msg.DataKey = DataKey;
	else
		prefix = new Array ();
		if ( ValueIsFilled ( DataKey ) ) then
			prefix.Add ( String ( DataKey ) );
			table = getTable ( Field );
			if ( table <> undefined ) then
				name = DataKey.Metadata ().TabularSections [ table.Name ].Presentation ();
				prefix.Add ( Output.TableAndRow ( new Structure ( "Table, Row", name, table.Row ) ) );
			endif; 
		endif; 
		if ( prefix.Count () > 0 ) then
			s = StrConcat ( prefix, ", " ) + ": " + s;
		endif; 
	endif;
	if ( Form <> undefined ) then
		msg.TargetID = Form; 
	endif;
	msg.Text = s;
	msg.Message ();
	
EndProcedure

&AtClient
Procedure openMessageBox ( Text, Params, ProcName, Module, CallbackParams, Timeout, Title )
	
	if ( Module = undefined ) then
		handler = undefined;
	else
		handler = new NotifyDescription ( ProcName, Module, CallbackParams );
	endif; 
	if ( handler = undefined ) then // Bug workaround 8.3.3.658 for WebClient: it doesn't understand "Undefined" in first paramer
		ShowMessageBox ( , Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	else
		ShowMessageBox ( handler, Output.Sformat ( Text, Params ), Timeout, ? ( Title = "", MetadataPresentation (), Title ) );
	endif; 
	
EndProcedure

&AtClient
Procedure openQueryBox ( Text, Params, ProcName, Module, CallbackParams, Buttons, Timeout, DefaultButton, Title )
	
	ShowQueryBox ( new NotifyDescription ( ProcName, Module, CallbackParams ), Output.Sformat ( Text, Params ), Buttons, Timeout, DefaultButton, ? ( Title = "", MetadataPresentation (), Title ) );
	
EndProcedure

&AtClient
Procedure putUserNotification ( Text, Params, NavigationLink, Explanation, Picture )
	
	ShowUserNotification ( Output.SFormat ( Text, Params ), NavigationLink, Output.SFormat ( Explanation, Params ), Picture );
	
EndProcedure

Function Row ( Table, LineNumber, Field ) export
	
	return Table + "[" + Format ( LineNumber - 1, "NG=;NZ=" ) + "]." + Field;
	
EndFunction 

Function TableAndRow ( Params ) export

	text = NStr ( "en='table %Table [%Row]';ru='таблица %Table [%Row]'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function MetadataPresentation () export

	text = NStr ( "en='Tester';ru='Тестер'" );
	return text;

EndFunction

Function getTable ( Field )
	
	i = StrFind ( Field, "[" );
	j = StrFind ( Field, "]", , i );
	if ( i = 0 or j = 0 ) then
		return undefined;
	endif; 
	name = TrimAll ( Left ( Field, i - 1 ) );
	row = 1 + Number ( Mid ( Field, i + 1, j - i - 1 ) );
	return new Structure ( "Name, Row", name, row );
	
EndFunction 

#region ExchangeData

&AtClient
Procedure MasterNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Main node selected. Data exchange must be made from subordinate nodes!';ru='Выбран главный узел. Обмен данными должен производиться из подчиненных узлов!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ExchangeDataItemAlreadyExist ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Element with node code: %Code already exists! To modify or add node data, you must open an existing directory item.';ru='Элемент с кодом узла: %Code уже существует! Для изменения или добавления данных узла необходимо открыть уже существующий элемент справочника.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure ChangePrefixFileName ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The prefix of the data exchange file name has been changed! This operation must be performed carefully! For further correct work of data exchange, it is necessary to make similar changes in the corresponding nodes of the distributed information base.';ru='Был изменён префикс имени файла обмена данными! Данную операцию необходимо выполнять осмотрительно! Для дальнейшей корректной работы обмена данными, необходимо произвести подобные изменения в соответствующих узлах распределённой информационной базы.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure AlreadyRunExchangeFull ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Background job ""Exchange"" is currently running. Please try again later.';ru='Фоновое задание ""Exchange"" в данный момент запущено. Повторите попытку позже.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure LoadingCompleteNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Load data';ru='Загрузка данных'" );
	explanation = NStr ( "en = 'Loading is complete!'; ru = 'Загрузка завершена!'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Exchange );
	
EndProcedure

&AtClient
Procedure UnloadingCompleteNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Unload data';ru='Выгрузка данных'" );
	explanation = NStr ( "en = 'Unloading is complete!'; ru = 'Выгрузка завершена!'" );
	putUserNotification ( text, Params, NavigationLink, explanation, PictureLib.Exchange );
	
EndProcedure

&AtServer
Function NotDefineThisNode () export
	
	p = new Structure ();
	p.Insert ( "Node", ExchangePlans.Full.ThisNode () );
	s = NStr ( "en = 'No setting created for exchange data for node - ""%Node"".'; ru = 'Не создана настройка обмена данными для узла - ""%Node"".'" );
	return Sformat ( s, p );
	
EndFunction

&AtServer
Procedure WritingChanges ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en='... write data to file.';ru='... запись данных в файл.'" );
	putMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WritingChangesComplete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data successfully written to file.';ru='... данные успешно записаны в файл.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ConnectToWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='... connecting to a web service';ru='... подключение к веб-сервису'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReadWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... receiving data through a web service';ru='... получение данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WriteWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data recording via web service';ru='... запись данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CheckPreviousFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Search for an existing exchange file.';ru='Поиск существующего файла обмена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ItWasFoundFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='An unread exchange file was found for the %Node node (the file name is %File). Node will not be unloaded for %Node.';ru='Для узла %Node был обнаружен непрочитанный файл обмена (имя файла - %File). Для узла %Node не будет произведена выгрузка.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FTPConnectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='There were errors connecting to the FTP server! Error description - ""%Error"".';ru='Возникли ошибки при соединении с FTP сервером! Описание ошибки - ""%Error"".'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure WillBeRunRereadFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The exchange file will be read again after updating the configuration.';ru='Файл обмена будет прочитан повторно, после обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ExchangeReceivedFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange data from host ""%Node "" accepted!';ru='Данные обмена от узла ""%Node"" приняты!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ErrorReceivingData ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Error getting exchange data! %Error. Exchange file %FileXml..';ru='Ошибка при получении данных обмена! %Error. Файл обмена %FileXml.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LockBase ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Infobase locked for configuration update.';ru='Информационная база заблокирована для обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnlockBase ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The base lock is removed. Time - %Date.';ru='Снята блокировка базы. Время - %Date.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FinishedRereadFileExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Finishing reading the exchange file after updating the configuration.';ru='Завершение дочитывания файла обмена после обновления конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadDataFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Retrieving data from node ""%Node"" ...';ru='Получение данных от узла ""%Node"" ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnloadBegin ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data for node ""%Node"" ...';ru='Выгрузка данных для узла ""%Node"" ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnloadFinish ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... unload data for node ""%Node"" completed.';ru='... выгрузка данных для узла ""%Node"" завершена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadDataFromNodeOver ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... receiving data from node ""%Node"" completed.';ru='... получение данных от узла ""%Node"" завершено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadFromEmail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load from email ...';ru='Загрузка данных из электронной почты ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadFromFTP ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load from ftp ...';ru='Загрузка данных с ftp ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadFromWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Load data from web service ...';ru='Загрузка данных через веб-сервис ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnLoadToEmail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to email ...';ru='Выгрузка данных на электронную почту ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnLoadToFTP ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to ftp ...';ru='Выгрузка данных на ftp ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnloadToDisk ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unload data to disk ...';ru='Выгрузка данных на диск ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnloadToWebService ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Unload data through web service ...';ru='Выгрузка данных через веб-сервис ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LogonToServerMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Connection to the mail server ...';ru='Соединение с почтовым сервером ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

Procedure LogonSuccess ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... connection to the server is established.';ru='... соединение с сервером установлено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

Procedure ErrorConnectEmailProfile ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Error connecting to mail profile! Exchange failed! Error Description:%Error';ru='Ошибка при подключении к почтовому профилю! Обмен не выполнен! Описание ошибки: %Error'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure MailReceived ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Message is received.';ru='Сообщение получено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SendingMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Sending email ...';ru='Отправка эл. почты ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure MessageSent ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange message for node ""%Node"" sent successfully';ru='Сообщение обмена для узла ""%Node"" успешно отправлено.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure NoNewExchangeFiles ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='No new messages!';ru='Отсутствуют новые сообщения!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ErrorLogonInternetMail ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Error connecting to internet mail. Error description - %ErrorDescription.';ru='Ошибка при подключении к интернет-почте. Описание ошибки - %ErrorDescription.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure FileDeletionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Error deleting file (%File)! %Error';ru='Ошибка при удалении файла (%File)! %Error'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure UnLoadFromWS ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... started uploading data through a web service';ru='... стартовала выгрузка данных через веб-сервис'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure LoadFromNetworkDisk ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... started loading data from a network drive';ru='... стартовала загрузка данных с сетевого диска'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReadingChanges ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='... reading data from file.';ru='... чтение данных из файла.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReadingChangesComplete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='... data from node ""%Node"" was successfully read from the file.';ru='... данные от узла ""%Node"" успешно прочитаны из файла.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReceivedFromNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Exchange data from host ""%Node"" accepted!';ru='Данные обмена от узла ""%Node"" приняты!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReadChangesConfiguration ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ("en='Changes that contain configuration changes were read. The configuration will be updated.';ru='Были прочитаны изменения, которые содержат изменения в конфигурации. Конфигурация будет обновлена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function SubjectErrorReport ( Params ) export

	s = NStr ("en='Errors while loading data from exchange node ""%Node"". The data load date is %CurrentDate.';ru='Ошибки при загрузке данных от узла-обмена ""%Node"". Дата загрузки данных - %CurrentDate.'" );
	return Sformat ( s, Params );

EndFunction

&AtServer
Function TextMessageEmailErrorReport ( Params ) export 

	s = NStr ( "en='Exchange data with node ""%Node""."
	"Exceeded the maximum number of errors while loading data from the file-sharing."
	"The number of allowed errors is %MaximumErrors."
	"The date of the last failed download is %CurrentDate."
	"Error Description - %Error."
	"You need to resolve the cause of the error for further successful data exchange.';ru='Обмен данными с узлом ""%Node""."
	"Превышено максимальное количество ошибок при загрузке данных из файла-обмена."
	"Количество допустимых ошибок - %MaximumErrors."
	"Дата последней неудачной загрузки - %CurrentDate."
	"Описание ошибки - %Error."
	"Необходимо устранить причину ошибку для дальнейшего успешного обмена данными.'" );
	return Sformat ( s, Params );

EndFunction

&AtServer
Function TextMessageEmailErrorReportNoNewExchangeFiles ( Params ) export

	s = NStr ( "en='Exchange data with node ""%Node""."
	"Exceeded the maximum number of errors while loading data from the file-sharing."
	"The number of allowed errors is %MaximumErrors."
	"The date of the last failed download is %CurrentDate."
	"The cause of the problem is the lack of file-sharing."
	"The cause of the error must be eliminated for further successful data exchange.';ru='Обмен данными с узлом ""%Node""."
	"Превышено максимальное количество ошибок при загрузке данных из файла-обмена."
	"Количество допустимых ошибок - %MaximumErrors."
	"Дата последней неудачной загрузки - %CurrentDate."
	"Причина проблемы - отсутствие файлов-обмена."
	"Необходимо устранить причину ошибку для дальнейшего успешного обмена данными.'" );
	return Sformat ( s, Params );

EndFunction

&AtClient
Procedure ThisNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='The data exchange node corresponding to this information base has been selected. You must select a node to exchange data.';ru='Выбран узел обмена данными, соответствующей данной информационной базе. Необходимо выбрать узел для обмена данными.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure IncorrectRecipients ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Exchange with the node - ""%Node"". Failed to send email mail ""%EMailUnLoad""! Error - ""%Error""!';ru='Обмен с узлом - ""%Node"". Не удалось отправить письмо на эл. почту ""%EMailUnLoad""! Описание ошибки - ""%Error""!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure IncorrectReportRecipients ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Send error report. Failed to send email mail ""%EMailUnLoad""! Error - ""%Error""!';ru='Отправка уведомления об ошибках обмена. Не удалось отправить письмо на эл. почту ""%EMailUnLoad""! Описание ошибки - ""%Error""!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtClient
Procedure SelectThisNode ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	s = NStr ( "en='This node is selected. Settings for this node are not specified.';ru='Выбран этот узел. Настройки для этого узла не указываются.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function ExchangeReadDataError ( Params ) export

	s = NStr ( "en='User %User does not have permissions to exchange data.';ru='У пользователя %User нет прав на обмен данными.'" );
	return Sformat ( s, Params );

EndFunction

&AtServer
Function UnknownNode ( Params ) export

	s = NStr ( "en='No node found. Node Code - %Code.';ru='Не найден узел. Код узла - %Code.'" );
	return Sformat ( s, Params );

EndFunction

&AtServer
Procedure StartUpdateScriptProcedure ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Start procedure for updating the configuration';ru='Старт процедуры по обновлению конфигурации.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure NotFoundExecuteFile1C ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The executable file 1cv8.exe was not found!';ru='Не найден исполняемый файл 1cv8.exe!'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Function InfobaseUpdateMessage ( Params ) export

	s = NStr ( "en='The infobase was blocked for %Period min starting with %Date.';ru='Информационная база была заблокирована на %Period мин начиная с %Date.'" );
	return Sformat ( s, Params );

EndFunction

&AtServer
Procedure StartReReadData ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Processing reading file.';ru='Стартовала процедура дочитывания файла обмена.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ExchangeLoadingAgain ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='The exchange data will be read again from the %Node node (ID = %ID).';ru='Будет произведено повторное чтение данных обмена из узла %Node (ID = %ID).'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReReadLoad ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Data loading started after update.';ru='Началась загрузка данных после обновления.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure ReReadUnLoad ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Unloading of data after updating has begun.';ru='Началась выгрузка данных после обновления.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure CloseCurrentSession ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Ending the current session (processing reading data after update) ...';ru='Завершение текущего сеанса (дочитывание данных после обновления конфигурации) ...'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure SaveRereadExchange ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='Saved file processing read file exchange. The file is %File.';ru='Сохранили файл обработки дочитывания файла обмена. Файл - %File.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

&AtServer
Procedure NotDefineLanguageForUser ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	s = NStr ( "en='For user %User is not set to the default language.';ru='Для пользователя %User не установлен язык по умолчанию.'" );
	putMessage ( s, Params, Field, DataKey, DataPath );

EndProcedure

#endregion

&AtServer
Function RuntimeMessage ( Params = undefined ) export

	text = NStr ( "en='%Message {%Stack}';ru='%Message {%Stack}'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function RuntimeMessagePrefix ( Params = undefined ) export

	text = "%Line: ";
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function RuntimeMessageCutPrefix () export

	text = "...";
	return text;

EndFunction

&AtClient
Function CheckError ( Params ) export

	text = NStr ( "en='%Form: %Title. Field ""%Field"" <> ""%Value"". The actual value is ""%Result""';ru='%Form: %Title. Поле ""%Field"" <> ""%Value"". Текущее значение ""%Result""'" );
	return Output.Sformat ( text, Params );

EndFunction

Function ScenarioError () export

	text = NStr ( "en='Scenario error';ru='Ошибка сценария'" );
	return text;

EndFunction

Function CallError ( Params ) export

	text = NStr ( "en='Scenario ""%Scenario"" not found';ru='Сценарий ""%Scenario"" не найден'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Procedure TestComlete ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = Output.TestComleteMessage ();
	PutMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function TestComleteMessage () export
	
	text = NStr ( "en='Test complete!';ru='Тест завершен!'" );
	return text;
	
EndFunction

Function CompilationError () export

	text = NStr ( "en='Compilation error';ru='Ошибка компиляции'" );
	return text;

EndFunction

&AtClient
Function CheckAppearanceIncorrect ( Params ) export

	text = NStr ( "en='CheckAppearance error: Status ""%Value"" is unknown';ru='CheckAppearance ошибка: Статус ""%Value"" не определен'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function FieldNotFound ( Params ) export

	text = NStr ( "en='Field ""%Field"" is not found';ru='Поле ""%Field"" не найдено'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function ManyPlaces ( Params ) export

	text = NStr ( "en='Field ""%Field"" found many times: %Places';ru='Поле ""%Field"" найдено в нескольких местах: %Places'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function StopMessage () export

	text = NStr ( "en='Scenario stopped';ru='Сценарий остановлен'" );
	return text;

EndFunction

&AtClient
Function NewScenario () export

	text = NStr ( "en='New Scenario';ru='Новый сценарий'" );
	return text;

EndFunction

&AtClient
Function TemplateEmpty () export

	text = NStr ( "en='Template is empty';ru='Шаблон пустой'" );
	return text;

EndFunction

&AtClient
Function AreaComparisonError ( Params ) export

	text = NStr ( "en='Cell [%Area] correct value [%Original] is not equal actual value [%Actual]';ru='Ячейка [%Area] правильное значение [%Original] не соответствует текущему значению [%Actual]'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TemplateCaption () export

	text = NStr ( "en='Template';ru='Шаблон'" );
	return text;

EndFunction

&AtClient
Procedure MainScenarioUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "MainScenarioUndefined" ) export
	
	text = NStr ( "en='Main Scenario is not yet defined';ru='Основной сценарий еще не определен'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Procedure UserNameAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Duplicate user name detected';ru='Такое имя пользователя уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure SelectAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Check the boxes to set access rights';ru='Отметьте флажками права доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ConfirmAccessRights ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Confirm or revert changes in access rights';ru='Принять или отменить изменения в правах доступа'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure SelectUsersGroup ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Assign user to the group or assign individual rights';ru='Назначить пользователю группу или индивидуальные права'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure RightsConfirmation ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "BPNotFound" ) export
	
	text = NStr ( "en='Selected right has dependencies on other system rights."
"They should be added or removed as well."
"Please review changes, then Accept or Cancel them';ru='Выбранное право имеет зависимости от других прав системы."
"Они должны быть добавлены или удалены соответственно."
"Пожалуйста, просмотрите изменения и примите или отмените их'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure ClearLogConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ClearLogConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove all records?';ru='Удалить все записи?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Procedure AdministratorNotFound ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='No users with administrative rights left in the system. You need to have at least one user with administrative rights in the database for service efficiency';ru='В системе не осталось пользователей с административными правами. Для работы сервиса требуется как минимум один администратор приложения'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure AccessDenied ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AccessDenied" ) export
	
	text = NStr ( "en='Access denied';ru='Доступ запрещен'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function ApplicationNotFound ( Params ) export

	text = NStr ( "en='""%Name"" application is not found';ru='""%Name"" приложение не найдено'" );
	return Sformat ( text, Params );

EndFunction

Function ScenarioNotFound ( Params ) export

	text = NStr ( "en='""%Name"" scenario is not found';ru='""%Name"" сценарий не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Procedure DownloadCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "DownloadCompleted" ) export
	
	text = NStr ( "en='Download completed!';ru='Загрузка завершена!'" );
	title = NStr ( "en=''; ru=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function ParametersCountError ( Params ) export

	text = NStr ( "en='%Name (): Count of parameters cannot be more than %Limit';ru='%Name (): Количество параметров не может быть больше %Limit'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure ScenarioAlreadyExists ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '""%Name"" scenario is already exists'; ru = '""%Name"" сценарий уже существует'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

Procedure LockError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = Output.LockingError ();
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

Function LockingError ( Params = undefined ) export

	text = NStr ( "en='Scenario ""%Scenario"" has already been locked by %User';ru='Сценарий ""%Scenario"" уже захватил %User'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure ScenarioNotLocked ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ""%Scenario"" has not been locked'; ru = 'Сценарий ""%Scenario"" не захвачен для редактирования'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure UnlockConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UnlockConfirmation" ) export
	
	text = NStr ( "en = 'Selected scenarios will be replaced on the previous versions!
                  |Do you want to continue?'; ru = 'Выбранные сценарии будут заменены на предыдущие версии!
                  |Продолжить операцию?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtClient
Procedure EnrollmentError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentError" ) export
	
	text = NStr ( "ru='Центральный узел не может быть использован';en='The main node cannot be used'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure EnrollNode ( Module, CallbackParams = undefined, Params = undefined, ProcName = "EnrollNode" ) export
	
	text = NStr ( "en = 'For this User, all scenarios will be marked as changed!
                   |Would you like to continue?'; ru = 'Для данного пользователя все сценарии будут помечены как измененные!
                   |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtClient
Procedure EnrollmentCompleted ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "EnrollmentCompleted" ) export
	
	text = NStr ( "ru='Регистрация завершена!';en='Enrollment is completed!'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Procedure ColumnIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Не заполнена колонка ""%Column"" в строке %LineNumber списка ""%Table""';en='Row ""%Column"" in line %LineNumber of list ""%Table"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure FieldIsEmpty ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "ru='Поле ""%Field"" не заполнено';en='Field ""%Field"" is empty'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ScenariosProcessed ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ScenariosProcessed" ) export
	
	text = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Procedure ScenariosProcessedNotification ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Unloading scenarios';ru='Выгрузка сценариев'" );
	explanation = NStr ( "en = 'Operation completed!
                   |Scenarios Processed: %Counter'; ru = 'Операция завершена!
                   |Обработано сценариев: %Counter'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
EndProcedure

Function CommonApplicationName () export

	text = NStr ( "en='<Common>';ru='<Общее>'" );
	return text;

EndFunction

&AtServer
Function CommonApplicationCode () export

	text = NStr ( "en='COMM';ru='ОБЩЕ'" );
	return text;

EndFunction

&AtServer
Procedure RepositoryNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Select at least one repository for processing'; ru = 'Выберите хотя бы один репозиторий для обработки'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ScenarioIDError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Scenario ID should not contain special characters'; ru = 'ID сценария не должен содержать специальные символы'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function UserAdmin () export

	text = NStr ( "en='Administrator';ru='Администратор'" );
	return text;

EndFunction

&AtClient
Procedure SetupMainScenario ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetupMainScenario" ) export
	
	text = NStr ( "en = 'Main Scenario is not yet defined.
                  |Would you like to install current scenario as main?'; ru = 'Основной сценарий еще не определен.
                  |Установить запускаемый сценарий как основной?'" );
	title = NStr ( "en=''; ru=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure UndefinedMainScenario ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "UndefinedMainScenario" ) export
	
	title = NStr ( "en=''; ru=''" );
	text = NStr ( "en = 'Main scenario is undefined'; ru = 'Основной сценарий не определен'" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtServer
Function LoadingProcessVersionMemo () export

	text = NStr ( "en = 'Automatically created scenario version during files loading process'; ru = 'Автоматически созданная версия перед загрузкой сценария из файла'" );
	return text;

EndFunction

&AtClient
Procedure AssistantBuiltin ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "AssistantBuiltin" ) export
	
	text = NStr ( "en = 'Built-in functions cannot be changed'; ru = 'Встроенные функции не могут быть изменены'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function RecordingSenario () export

	text = NStr ( "en = 'Recording...'; ru = 'Идет запись...'" );
	return text;

EndFunction

&AtClient
Function PauseScenario () export

	text = NStr ( "en = 'Pause'; ru = 'Пауза'" );
	return text;

EndFunction

Function RecordSenario () export

	text = NStr ( "en = 'Record: no connection'; ru = 'Запись: нет подключения'" );
	return text;

EndFunction

&AtClient
Function WrongFieldValue () export

	text = NStr ( "en = 'Wrong field value'; ru = 'Неверное значение поля'" );
	return text;

EndFunction

&AtServer
Procedure CommonReportOpenError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='This report is an official report and it cannot be opened interactively ';ru='Данный отчет является служебным и не предназначен для интерактивного открытия'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function ClickGenerateReport () export
	
	text = NStr ( "en='Press the button ""Generate"" to create a report';ru='Нажмите кнопку Сформировать для формирования отчета'" );
	return text;
	
EndFunction

&AtClient
Procedure ReportVariantModified2 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified2" ) export
	
	text = NStr ( "en='Current report version was modified."
"Would you like to save changes?';ru='Текущий вариант отчета модифицирован."
"Сохранить изменения?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Procedure ReportSchedulingIncorrectPeriod ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Selection by period is set to specific date. You cannot use the schedule because you set strict selection mode and the report will be delivered with the same data all the time. Try to set predefined value as a selection, not a specific date.';ru='Отбор по периоду установлен на конкретную дату. Использовать расписание нельзя, так как вы установили строгий отбор и будете каждый раз получать этот отчет с одними и теме же данными. Попробуйте указать в качестве отбора, не конкретную дату(ы), а предопределенное значение'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ReportVariantModified1 ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportVariantModified1" ) export
	
	text = NStr ( "en='Current report version has been modified."
"Would you like to save current changes before loading the new version?';ru='Текущий вариант отчета модифицирован."
"Перед загрузкой нового варианта отчета, произвести сохранение текущих изменений?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Function LoadReportSettings () export
	
	text = NStr ( "en='Report settings';ru='Настройки отчета'" );
	return text;
	
EndFunction

&AtServer
Function LoadReportVariant () export
	
	text = NStr ( "en='Report variants';ru='Варианты отчета'" );
	return text;
	
EndFunction

&AtClient
Procedure ReplaceReportVariant ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReplaceReportVariant" ) export
	
	text = NStr ( "en='Overwrite the existing report settings?';ru='Перезаписать существующие настройки отчета?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtServer
Procedure SendingReportsByScheduleAddingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Scheduled reports can be created and sent from specific form. Interactive access denied';ru='Создание графиков отправки осуществляется из форм конкретных отчетов. Интерактивное добавление недоступно'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure ScheduleDateError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Start the schedule from the date greater than current date';ru='Начните расписание с даты большей, чем текущая дата'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WeekDaySelectionError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en='Please select at least one week day';ru='Выберите хотя бы один день недели'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure ReportScheduleRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ReportScheduleRemovingConfirmation" ) export
	
	text = NStr ( "en='Are you sure you want to delete the schedule?';ru='Удалить расписание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Function ReportByEmailBody ( Params ) export
	
	text = NStr ( "en='Hello,"
"You received scheduled report %ReportPresentation. Report is attached to this e-mail."
""
"To change the schedule you can go to:"
"%ScheduleSettingsURL"
""
"Sincerely,"
"%Website';ru='Доброго времени суток!"
"Вы получили по расписанию отчет %ReportPresentation. Отчет во вложении к письму."
""
"Для изменения расписания, вы можете перейти по ссылке:"
"%ScheduleSettingsURL"
""
"С уважением, команда специалистов %Website'" );
	return Output.Sformat ( text, Params );
	
EndFunction

&AtServer
Function PageFooter () export
	
	text = NStr ( "en='[&PageNumber] from [&PagesTotal]';ru='[&PageNumber] from [&PagesTotal]'" );
	return text;
	
EndFunction

&AtClient
Procedure SetCurrentVersion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "SetCurrentVersion" ) export
	
	text = NStr ( "en = 'Selected version %Version will be used as current application version for your profile.
                  |Would you like to continue?'; ru = 'Для вашего профиля, версия %Version будет установлена как текущая.
                  |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtServer
Function ExpressionError () export
	
	text = NStr ( "en = 'Expression error'; ru = 'Ошибка в выражении'" );
	return text;
	
EndFunction

&AtServer
Function CurrentVersionUndefined () export
	
	text = NStr ( "en = 'Current version is not defined'; ru = 'Текущая версия не определена'" );
	return text;
	
EndFunction

&AtServer
Function VersionNotFound ( Params ) export
	
	text = NStr ( "en = 'Version <%Version> is not found'; ru = 'Версия <%Version> не найдена'" );
	return Output.Sformat ( text, Params );
	
EndFunction

&AtClient
Function StopDebugging () export

	text = NStr ( "en = 'Debugging stopped'; ru = 'Отладка остановлена'" );
	return text;

EndFunction

&AtClient
Procedure ApplicationChangingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Application changing error. Scenario: %Scenario, Error: %Error'; ru = 'Не удалось изменить приложение для сценария %Scenario. Ошибка: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

Function OptionsLabelShow () export

	text = NStr ( "en = 'Options'; ru = 'Опции'" );
	return text;

EndFunction

Function OptionsLabelHide () export

	text = NStr ( "en = 'Hide'; ru = 'Скрыть'" );
	return text;

EndFunction

Function FilterLabelShow () export

	text = NStr ( "en = 'Filter: '; ru = 'Отбор: '" );
	return text;

EndFunction

Function LockedLabel () export

	text = NStr ( "en = 'Filtered by Locked'; ru = 'Отобраны захваченные'" );
	return text;

EndFunction

Function UnlockedLabel () export

	text = NStr ( "en = 'Filtered by Unlocked'; ru = 'Отобраны незахваченные'" );
	return text;

EndFunction

Function TagsFilter () export

	text = NStr ( "en = 'Tags'; ru = 'Теги'" );
	return text;

EndFunction

&AtClient
Function SourceNotFound () export

	text = NStr ( "en = 'Source not found '; ru = 'Источник не найден'" );
	return text;

EndFunction

&AtServer
Function NewTag () export

	text = NStr ( "en = 'New Tag'; ru = 'Новый тег'" );
	return text;

EndFunction

&AtServer
Procedure ObjectNotOriginal ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Value already exists!'; ru = '%Value уже существует!'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Procedure TagRemovingConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "TagRemovingConfirmation" ) export
	
	text = NStr ( "en='Do you want to remove the tag?';ru='Удалить тег?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure TagsListEmpty ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "TagsListEmpty" ) export
	
	text = NStr ( "en = 'Tags list is empty. For creating new tags please contact your administrator'; ru = 'Список тегов не задан. Для создания новых тегов, обратитесь к администратору за получением соответствующих прав доступа'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function UndefinedExternalRequest () export

	text = NStr ( "en = 'Undefined request'; ru = 'Неопознанный запрос'" );
	return text;

EndFunction

&AtClient
Function FileReadingError ( Params ) export

	text = NStr ( "en = 'File reading timeout error: %File'; ru = 'Превышен таймаут ожидания для чтения файла: %File'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtClient
Function ErrorsNotFound () export

	text = NStr ( "en = 'No syntax errors found!'; ru = 'Синтаксических ошибок не обнаружено!'" );
	return text;

EndFunction

Function UndefinedScenario ( Params ) export

	text = NStr ( "en = 'Cannot find scenario by file: %File'; ru = 'Не удалось найти сценарий согласно файла: %File'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function ScenarioApplicationUnmapped ( Params ) export

	text = NStr ( "en = 'Scenario <%Path> is not mapped to the folder of the file system'; ru = 'Сценарий <%Path> не синхронизирован с папкой файловой системы'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure WrongRepoFolder1 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'One folder cannot be specified twice'; ru = 'Одна папка не может использоваться дважды'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure WrongRepoFolder2 ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Repository folders cannot be inside of each other: %Folder1 <-> %Folder2. Use another folder path'; ru = 'Папки репозиториев не могут включать друг друга: %Folder1 <-> %Folder2. Укажите другой путь к папке'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Procedure AgentAccessDenied ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Creator cannot delegate tasks for the Agent: Access Denied'; ru = '%Creator не может делегировать задачи для этого агента: Отказано в доступе'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function OpenErrorsLog () export

	text = NStr ( "en = 'Open Errors Log'; ru = 'Открыть журнал ошибок'" );
	return text;

EndFunction

&AtClient
Function OpenError () export

	text = NStr ( "en = 'Error: '; ru = 'Ошибка: '" );
	return text;

EndFunction

&AtClient
Function OpenLog () export

	text = NStr ( "en = 'Open Execution Log'; ru = 'Открыть журнал запуска'" );
	return text;

EndFunction

&AtClient
Function OpenScenario () export

	text = NStr ( "en = 'Open Scenario'; ru = 'Открыть сценарий'" );
	return text;

EndFunction

&AtClient
Procedure DeleteJob ( Module, CallbackParams = undefined, Params = undefined, ProcName = "DeleteJob" ) export
	
	text = NStr ( "en = 'Would you like to remove this job?'; ru = 'Удалить задание?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

Function JobCanceled () export

	text = NStr ( "en = 'Job canceled'; ru = 'Задание отменено'" );
	return text;

EndFunction

&AtClient
Function TestedApplicationOffline () export

	text = NStr ( "en = 'Tested application is offline'; ru = 'Нет подключения к тестируемому приложению'" );
	return text;

EndFunction

&AtServer
Function AgentNotFound ( Params ) export

	text = NStr ( "en = 'Agent ""%Agent"" not found'; ru = 'Агент ""%Agent"" не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function ComputerNotFound ( Params ) export

	text = NStr ( "en = 'Computer ""%Computer"" not found'; ru = 'Компьютер ""%Computer"" не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function OSNotSupported () export
	
	text = NStr ( "en = 'The extended functions library supports Windows OS only. Other operating systems are not currently supported'; ru = 'Библиотека расширенных функций поддерживает работу в операционной системе Windows. Другие операционные системы в настоящий момент не поддерживаются'" );
	return text;
	
EndFunction

&AtServer
Procedure SourcesFolderError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'At least one folder should be defined'; ru = 'Как минимум одна папка должна быть определена'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function UnableToClick ( Params ) export

	text = NStr ( "en = 'Unable to click %Field'; ru = 'Не удалось нажать на %Field'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function CheckAppearanceError ( Params ) export

	text = NStr ( "en='Field ""%Field"" state ""%Value"" should be ""%Flag"". Actual state is ""%State""';ru='У поля ""%Field"" состояние ""%Value"" должно быть ""%Flag"", а реальное состояние ""%State""'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Function ShouldBe () export
	
	text = NStr ( "en = 'should be'; ru = 'должно быть'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotBe () export
	
	text = NStr ( "en = 'should not be'; ru = 'не должно быть'");
	return text;
	
EndFunction

&AtServer
Function Filled () export
	
	text = NStr ( "en = 'filled'; ru = 'заполненным'");
	return text;
	
EndFunction

&AtServer
Function Empty () export
	
	text = NStr ( "en = 'empty'; ru = 'пустым'");
	return text;
	
EndFunction

&AtServer
Function Existed () export
	
	text = NStr ( "en = 'existed'; ru = 'существующим'");
	return text;
	
EndFunction

&AtServer
Function Between ( Params ) export
	
	text = NStr ( "en = 'between %Start and %Finish'; ru = 'между %Start и %Finish'");
	return Output.Sformat ( text, Params );
	
EndFunction

&AtServer
Function ShouldContain () export
	
	text = NStr ( "en = 'should contain'; ru = 'должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotContain () export
	
	text = NStr ( "en = 'should not contain'; ru = 'не должно содержать'");
	return text;
	
EndFunction

&AtServer
Function ShouldHave () export
	
	text = NStr ( "en = 'should have size'; ru = 'должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function ShouldNotHave () export
	
	text = NStr ( "en = 'should not have size'; ru = 'не должно иметь размер'");
	return text;
	
EndFunction

&AtServer
Function Value () export
	
	text = NStr ( "en = 'Value'; ru = 'Значение'");
	return text;
	
EndFunction

&AtServer
Function YesNo () export
	
	text = NStr ( "en = 'BF=False; BT=True'; ru = 'BF=Ложь; BT=Истина'");
	return text;
	
EndFunction

&AtClient
Procedure NoStepsInChronograph ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Chronograph';ru='Хронограф'" );
	explanation = NStr ( "en = 'There are no steps for the selected direction'; ru = 'Нет шагов для перехода в указанном направлении'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
EndProcedure

&AtServer
Function SessionAccessError () export
	
	text = NStr ( "en = 'You don’t have access to the tested session'; ru = 'Нет доступа к тестируемой сессии'");
	return text;
	
EndFunction

&AtServer
Function ScenarioNotFilmed () export
	
	text = NStr ( "en = 'Scenario wasn’t filmed'; ru = 'Сценарий не записывался в хронограф'");
	return text;
	
EndFunction

&AtClient
Procedure WrongFolder ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'The folder is referencing to itself'; ru = 'Папка ссылается на саму себя'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function CopyingError () export
	
	text = NStr ( "en = 'Selected item causes levels looping!'; ru = 'Выбранный элемент приводит к зацикливанию уровней!'" );
	return text;
	
EndFunction

&AtClient
Procedure CopyMoveConfirmation ( Module, CallbackParams = undefined, Params = undefined, ProcName = "CopyMoveConfirmation" ) export
	
	text = NStr ( "en = 'During the process system will change applications of transferred scenarios to %Application'; ru = 'При помещении сценариев в выбранную папку будет произведена замена приложения помещаемых сценариев на %Application'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure ErrorNotLocated ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ErrorNotLocated" ) export
	
	text = NStr ( "en = 'Selected error has not been found in the list. Check filters in the list which can prevent locating the error'; ru = 'Не удалось перейти к строке с ошибкой. Проверьте установленные отборы, возможно они не позволяют найти выбранную в списке ошибку'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function WebClientDoesNotSupport () export
	
	text = NStr ( "en = 'Web client does not support this functionality'; ru = 'Веб-клиент не поддерживает данную функциональность'" );
	return text;
	
EndFunction

&AtClient
Function ClientDoesNotSupport () export
	
	text = NStr ( "en = 'This application does not support this functionality'; ru = 'Это приложение не поддерживает данную функциональность'" );
	return text;
	
EndFunction

&AtServer
Function WatcherRenamingError ( Params ) export

	text = NStr ( "en = 'Scenario renaming error: %Scenario (%File). %Error'; ru = 'Ошибка переименования сценария: %Scenario (%File). %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherRenamingChildrenError ( Params ) export

	text = NStr ( "en = 'Error on changing the path of subordinate scenarios for the %Scenario';ru = 'Ошибка при изменении пути подчиненных сценариев для %Scenario'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherDeletingChildrenError ( Params ) export

	text = NStr ( "en = 'Error on deleting subordinate scripts in %Scenario group';ru = 'Ошибка при изменении пути подчиненных сценариев для %Scenario'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherUpdatingError ( Params ) export

	text = NStr ( "en = 'Scenario updating error: %Scenario. %Error'; ru = 'Ошибка обновления сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherParentNotFound ( Params ) export

	text = NStr ( "en = 'Parent scenario for the %File is not found'; ru = 'Родительский сценарий для %File не найден'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherCreatingError ( Params ) export

	text = NStr ( "en = 'Scenario creating error. Folder: %Parent (%File). %Error'; ru = 'Ошибка создания сценария. Папка: %Parent (%File). %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherRestorationError ( Params ) export

	text = NStr ( "en = 'Restoration of %Scenario (%File) caused an error: %Error'; ru = 'Ошибка восстановления сценария %Scenario (%File). %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario removing error: %Scenario. %Error'; ru = 'Ошибка удаления сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherTemplateRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario template removing error: %Scenario. %Error'; ru = 'Ошибка удаления шаблона сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtServer
Function WatcherScriptRemovingError ( Params ) export

	text = NStr ( "en = 'Scenario script removing error: %Scenario. %Error'; ru = 'Ошибка удаления программного кода сценария: %Scenario. %Error'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function WatcherRenamingFolderError ( Params ) export

	text = NStr ( "en = 'You renamed the file (%File) responsible for the current folder which can cause synchronization issues. Please, use Tester for renaming folders and test-libraries';ru = 'Вы переименовали файл (%File) ответственный за именование текущей папки. Это может привести к ошибкам синхронизации. Пожалуйста, используйте Тестер для переименования папок и библиотек с тестами'" );
	return Sformat ( text, Params );

EndFunction

Function WatcherFileNameError ( Params = undefined ) export
	
	text = NStr ( "en = 'File (%File) should not contain special characters'; ru = 'Файл (%File) не должен содержать специальные символы'" );
	return Sformat ( text, Params );
	
EndFunction

&AtClient
Procedure SyntaxError ( Form, Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = '%Error'; ru = '%Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath, Form );
	
EndProcedure

&AtClient
Procedure ContinueStoring ( Module, CallbackParams = undefined, Params = undefined, ProcName = "ContinueStoring" ) export
	
	text = NStr ( "en = 'Syntax errors have been found!
				  |Would you like to continue?';ru = 'Обнаружены синтаксические ошибки!
				  |Продолжить?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.No, title );
	
EndProcedure

&AtClient
Function VSCodeWorkspace ( Params ) export

	text = NStr ( "en = 'Visual Studio Code Workspace (*%Extension)|*%Extension';ru = 'Рабочая область Visual Studio Code (*%Extension)|*%Extension'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function SelectWorkspace () export

	text = NStr ( "en = 'Select Workspace';ru = 'Выберите рабочую область'" );
	return text;

EndFunction

&AtClient
Procedure VSCodeWorkspaceUndefined ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "VSCodeWorkspaceUndefined" ) export
	
	text = NStr ( "en = 'Workspace is not defined!
				  |Please, open Repositories and specify Visual Studio Code workspace
				  |for application %Application';ru = 'Рабочая область не задана!
				  |Откройте пожалуйста Репозитории и задайте
				  |для приложения %Application
				  |рабочую область Visual Studio Code'" );
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

&AtClient
Function WatcherListeningEvents () export

	text = NStr ( "en = 'Listening repository changes...';ru = 'Получение событий от репозитория...'" );
	return text;

EndFunction

&AtClient
Function WatcherSyncingMessage () export

	text = NStr ( "en = 'Syncing with repository';ru = 'Синхронизация с репозиторием'" );
	return text;

EndFunction

&AtClient
Procedure WorkspaceCreated ( Params = undefined, NavigationLink = undefined, Picture = undefined ) export
	
	text = NStr ( "en='Tester';ru='Тестер'" );
	explanation = NStr ( "en = 'Workspace has been created: %Path'; ru = 'Создана рабочая область: %Path'" );
	putUserNotification ( text, Params, NavigationLink, explanation, Picture );
	
EndProcedure

&AtClient
Procedure MarkForDeletion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "MarkForDeletion" ) export
	
	text = NStr ( "en = 'Mark for deletion?';ru = 'Пометить на удаление?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure UnmarkForDeletion ( Module, CallbackParams = undefined, Params = undefined, ProcName = "UnmarkForDeletion" ) export
	
	text = NStr ( "en = 'Do you want to remove the deletion mark for selected elements?';ru = 'Снять пометку на удаление?'" );
	title = NStr ( "ru='';en=''" );
	openQueryBox ( text, Params, ProcName, Module, CallbackParams, QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes, title );
	
EndProcedure

&AtClient
Procedure ShowError ( Module = undefined, CallbackParams = undefined, Params = undefined, ProcName = "ShowError" ) export
	
	text = "%Error";
	title = NStr ( "ru='';en=''" );
	openMessageBox ( text, Params, ProcName, Module, CallbackParams, 0, title );
	
EndProcedure

Function SpreadsheedTotalCount ( Params ) export

	text = NStr ( "en='Count: %Count'; ru='Кол-во: %Count'" );
	return Sformat ( text, Params );

EndFunction

Function SpreadsheedTotal ( Params ) export

	text = NStr ( "en='Avg: %Average   Count: %Count   Sum: %Sum'; ru='Среднее: %Average   Кол-во: %Count   Сумма: %Sum'" );
	return Sformat ( text, Params );

EndFunction

&AtClient
Function CalculationAreaTooBig () export

	text = NStr ( "en='The selected area is too large. Click on the button on the right for manual calculation'; ru='Выделена большая область. Нажмите кнопку справа для расчета'" );
	return text;

EndFunction

Function SpreadsheedAreaNotSelected () export

	text = NStr ( "en='Area not defined'; ru='Область не задана'" );
	return text;

EndFunction

&AtServer
Function DataSetColumnNotFound ( Params ) export

	text = "Field not found, DataPath: %Path. Might be the field no longer exists in the source report or Mobile application (or mobile reports) is not up to date";
	return Sformat ( text, Params );

EndFunction

&AtServer
Procedure SyncingBackRequred ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Common scenario <%Folder> has been changed. Syncing back is required for the following applications: %Apps';ru = 'Был изменен общий сценарий <%Folder>, требуется обратная синхронизация изменений для приложений: %Apps'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtServer
Function LoadingError () export

	text = NStr ( "en = 'Data loading error occurred';ru = 'Произошла ошибка во время загрузки данных'" );
	return text;

EndFunction

Function TableValuesDifferent ( Params ) export

	text = NStr ( "en = 'In the row %Row of %Table table, in the %Column column, the value should be ""%Standard"", not ""%Tested""'; ru = 'В строке %Row таблицы %Table, в колонке %Column должно быть ""%Standard"", а не ""%Tested""'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableFormatErrorStandard () export

	text = NStr ( "en = 'Standard Table'; ru = 'Эталонная таблица'" );
	return text;

EndFunction

Function TableFormatErrorTesting () export

	text = NStr ( "en = 'Testing Table'; ru = 'Тестируемая таблица'" );
	return text;

EndFunction

Function TableFormatErrorFormatting () export

	text = NStr ( "en = 'Formatting Table'; ru = 'Форматируемая таблица'" );
	return text;

EndFunction

Function TableFormatErrorColumns ( Params ) export

	text = NStr ( "en = '%Table Format Error: incorrect number of colums in the row #%Row'; ru = 'Ошибка формата, %Table: неверное количество колонок в строке #%Row'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableFormatErrorName ( Params ) export

	text = NStr ( "en = '%Table Format Error: table name is not defined'; ru = 'Ошибка формата, %Table: не определено имя таблицы'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableFormatErrorHeader ( Params ) export

	text = NStr ( "en = '%Table Format Error: table columns are not defined'; ru = 'Ошибка формата, %Table: не заданы колонки'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableColumnNotFound ( Params ) export

	text = NStr ( "en = 'There''s no <%Column> column in the %Table table, but the standard has'; ru = 'В таблице %Table нет колонки <%Column>, а в эталоне есть'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableHasManyColumns ( Params ) export

	text = NStr ( "en = '%Table table has more columns than standard'; ru = 'В таблице %Table больше колонок чем в эталоне'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableHasFewerColumns ( Params ) export

	text = NStr ( "en = '%Table table has fewer columns than standard'; ru = 'В таблице %Table меньше колонок чем в эталоне'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableHasManyRows ( Params ) export

	text = NStr ( "en = '%Table table has more rows than standard (%TestedRows > %StandardRows)'; ru = 'В таблице %Table больше строк чем в эталоне (%TestedRows > %StandardRows)'" );
	return Output.Sformat ( text, Params );

EndFunction

Function TableHasFewerRows ( Params ) export

	text = NStr ( "en = '%Table table has fewer rows than standard (%TestedRows < %StandardRows)'; ru = 'В таблице %Table меньше строк чем в эталоне (%TestedRows < %StandardRows)'" );
	return Output.Sformat ( text, Params );

EndFunction

&AtServer
Procedure ColumnsNotSelected ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export
	
	text = NStr ( "en = 'Select testing columns please'; ru = 'Выберите пожалуйста тестируемые колонки'" );
	putMessage ( text, Params, Field, DataKey, DataPath );
	
EndProcedure

&AtClient
Function ErrorObtainingTableParameters () export

	text = NStr ( "en = 'An error occurred in obtaining the table parameters';ru = 'Произошла ошибка получения параметров таблицы'" );
	return text;

EndFunction

&AtClient
Function Standard () export

	text = NStr ( "en = 'standard';ru = 'эталон'" );
	return text;

EndFunction

&AtClient
Function TableDefinitionNotFound () export

	text = NStr ( "en = 'Table Definition Not Found';ru = 'Не удалось найти определение таблицы'" );
	return text;

EndFunction

&AtServer
Procedure ScenarioTemplateLoadingError ( Params = undefined, Field = "", DataKey = undefined, DataPath = "Object" ) export

	text = NStr ( "en = 'Scenario template loading error: %Error. Scenario: %Scenario';ru = 'Произошла системная ошибка при загрузке шаблона сценария %Scenario: %Error'" );
	putMessage ( text, Params, Field, DataKey, DataPath );

EndProcedure
