'DVBViewer EPG Update Script
'http://www.dvbviewer.tv/forum/topic/41624-epg-update-script/
'
'Read readme.txt first.
'Do not change this script, use ini files instead.
'The change log can be found in changelog.txt.


Option Explicit
Const ScriptVersion="2015-01-17 23:30"


dim AdditionalEPGArray, AdditionalEPGArrayTemp, AdditionalEPGFinished, AdditionalEPGString, AdditionalEPGTransponders
dim AdditionalEPGType, ArgumentsValid, arrChannelIDChannelList, arrChannelIDFavoriteList(), arrChannelIDFavoriteListTemp, arrChannelIDFavoriteListTempTemp
dim arrtemp
dim BeginWaitforDVBV
dim ChannelFilteredOut, ChannelID, ChannelIsPartOfFavorites, ChannelNumberToTune
dim DicTransponder, DVBVEPGFilePath, DVBViewer, DVBViewerExecutablePath, DVBViewerExecutablePathTemp
dim DVBViewerExeFileObject, DVBVProcessCount, DynamicTuneTime
dim EPGLastChangeTime, EPGLastCount, ExcludeCat, ExcludeCatArray, ExcludeRoot, ExcludeRootArray, ExcludeSat
dim ExcludeSatArray
dim favCollection, favitem, filesys, fso, fsofile
dim GetValueFromIniFileTempString
dim HTTPPostParameter, HTTPPostURL
dim i, iChannelCount, IncludeArray, IncludeCat, IniFile, inifiledefault, inifileinfostring, IniFileObject, inifiletouse
dim intEqualPos, IsAdditionalEPGTransponder
dim KeepFromLine, KeyName
dim lActChannel, languagefile, LanguageFileDefault, LanguageFileObject, LanguageFileObjectFile, LanguageFileStringPos
dim LanguageInfoString, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3, LanguageReplaceVar4
dim LanguageReplaceVar5, LanguageReplaceVar6, LanguageReplaceVar7, LanguageTempString, LCIDcolOperatingSystems
dim LCIDDictionary, LCIDiOSLang, LCIDoOS, LCIDoWMI, LCIDsComputer, LCIDSplit, LCIDtoUse, Line, logarray, LogFile
dim LogMsgString, LogToFileOnly
dim MinimizeDVBV, MinTimeToNextRecord, MuteDVBV
dim n, NoUserInteraction, NoUserYes
dim objArgs, objFSO, objFSOini, objIniFile, objShellFindCommonPath, oExecWhoami, oHTTP, oOSInfo, OrbPosString
dim OriginalSetupValueFreeSatEPG, OriginalSetupValueMHWEPG, OriginalSetupValueSFIEPG, OS, oWhoamiOutput, oWMI
dim process
dim rc, rcb, RealTuneTime, ReceiveFreeSatEPG, ReceiveMHWEPG, ReceiveSFIEPG, RestartToApplyConfig
dim RunsFound, RunsFoundSearchText, RunsToKeep, RunsToKeepInLog
dim ScriptStartTime, sec, sectionname, service, ShutdownActionID, StartDVBV, sTranspID, strFilePath, StringToWrite, strinput
dim strKey, strLeftString, strLine, strSection, strWhoamiOutput
dim Tag, TargetVariableName, TargetVariableNameTemp, TempArgumentName, TempEPGArrayCount, tempstringx, tempstringy
dim TestRun, TimeToGetData, TimeToReceiveAdditionalEPG, TimeToStartDVBV, TotalTuneTime, TransponderChannelNames
dim TransponderData, TransponderDataStringFreq, TransponderDataStringType, tsInput
dim TuneChannelLastRunTime
dim UpdateFavoritesOnly, UseIniFile
dim vChannels
dim WaitBeforeStart, WasAlreadyRunning, WasInStandbyAtStartup, WasPlayingMediaAtStartup, wshshell
dim x
dim y, yy


'What language file should be used?
'   Script tries to auto detect language and looks for the appropriate file. 
'   If file does not exist, script tries to use "en.ini" hardcoded. If "en.ini" also does not exist, script ends with an error.
'Welche Sprachdatei soll verwendet werden?
'   Das Script versucht die Sprache selbst festzustellen und sucht eine entsprechende Sprachdatei.
'   Wenn die Datei nicht existiert, wird fix "en.ini" verwendet. Sollte "en.ini" auch nicht existieren, endet das Script mit einem Fehler.
'Example/Beispiel: "de.ini"
'Default/Standard: ""
LanguageFile=""

'Include only channels that are part of these channel list categories. Delimit categories with "|".
'   This list is not considered when UpdateFavoritesOnly=true.
'Nur Kanäle berücksichtigen, die in der Kanalliste einer der folgenden Kategorien zugeordnet sind. Kategorien sind mit "|" voneinander zu trennen.
'   Diese Liste wird nicht berücksichtigt wenn UpdateFavoritesOnly=true.
'Example/Beispiel: IncludeCat="_Favoriten|Sky HD"
'Default/Standard: ""
IncludeCat=""

'Exclude channels that are part of these channel list categories. Delimit categories by "|".
'   Excluded channels are stronger than included channels.
'   This list is not considered when UpdateFavoritesOnly=true.
'Kanäle nicht berücksichtigen, die in der Kanalliste einer der folgenden Kategorien zugeordnet sind. Kategorien sind mit "|" voneinander zu trennen.
'   Nicht zur berücksichtigende Kanäle sind stärker als zu berücksichtigende.
'   Diese Liste wird nicht berücksichtigt wenn UpdateFavoritesOnly=true.
'Example/Beispiel: ExcludeCat="Canal+|SES Astra"
'Default/Standard: ""
ExcludeCat=""

'Exclude channels that are part of these channellist root names. Delimit names by "|".
'   This list is not considered when UpdateFavoritesOnly=true.
'Kanäle nicht berücksichtigen, die folgenden Wurzeleinträgen in der Senderliste zugewiesen sind. Namen sind mit "|" voneinander zu trennen.
'   Diese Liste wird nicht berücksichtigt wenn UpdateFavoritesOnly=true.
'Example/Beispiel: "Hot Bird 13.0°E|Eutelsat W2 16.0°E"
'Default/Standard: ""
ExcludeRoot=""

'Exclude channels that are part of these orbital positions (satellites). Delimit items by "|".
'   "19,2°E" is the same as "192", "19,2°W" is the same as "3408" (3600-19,2*10).
'   This list is not considered when UpdateFavoritesOnly=true.
'Kanäle nicht berücksichtigen, die folgenden Orbitalpostionen (Satelliten) zugewiesen sind. Einträge sind mit "|" voneinander zu trennen.
'   "19,2°E" ist ident mit "192", "19,2°W" ist ident mit "3408" (3600-19,2*10).
'   Diese Liste wird nicht berücksichtigt wenn UpdateFavoritesOnly=true.
'Example/Beispiel: "13,0°E|19,2°W"
'Default/Standard: ""
ExcludeSat=""

'Only use channels that are in the favorites list?
'   When true, IncludeCat and ExcludeCat are not considered.
'Nur Kanäle aus der Favoritenliste berücksichtigen?
'   Wenn true, werden IncludeCat und ExcludeCat nicht berücksichtigt.
'true or/oder false.
'Default/Standard: false
UpdateFavoritesOnly=false

'Should there be user interaction or should be script work on itself?
'Soll das Script ohne Benutzerinteraktion funktionieren und selbst Entscheidungen treffen?
'true or/oder false.
'Default/Standard: true
NoUserInteraction=true

'If NoUserInteraction=true, should the script automatically apply "yes" to all questions?
'Wenn NoUserInteraction=true, soll das Script auf alle Fragen automatisch mit "ja" antworten?
'true or/oder false.
'Default: true
NoUserYes=true

'Should the script run in test mode where everything is calculated, but no channels are actually tuned?
'Soll das Script im Testmodus laufen, in dem alle berechnet aber keine Kanäle gewechselt werden?
'true or/oder false.
'Default/Standard: false
TestRun=false

'DynamicTuneTime
'false: Fixed tune time per channel (see TimeToGetData). true: Channel is tuned until count of EPG entries is stable for 5 seconds.
'false: Fixe Zeit pro Kanal (siehe TimeToGetData). true: Kanal bleibt aktiv bis die Anzahl der EPG-Einträge mindestens 5 Sekunden unverändert ist.
'true or/oder false.
'Default/Standard: true
DynamicTuneTime=true

'Path to dvbviewer.exe
'   If path is not set or the file is not found, the registry is used.
'Pfad zur dvbviewer.exe
'   Wenn der Pfad nicht angegeben wird oder ungültig ist, wird der Pfad aus der Registry ermittelt.
'Example/Beispiel: "C:\Program Files (x86)\DVBViewer"
'Default/Standard: ""
DVBViewerExecutablePath=""

'Time in seconds to wait after DVBViewer has been started.
'Wartezeit in Sekunden nach Start des DVBViewer
'Default/Standard: 10
TimeToStartDVBV=10

'Time in seconds that a channel should stay tuned when DynamicTuneTime=false.
'Zeit in Sekunden, die ein Kanal aktiv bleiben soll wenn DynamicTuneTime=false.
'Default/Standard: 20
TimeToGetData=20

'Time in seconds to the next recording.
'   If the next recording starts within this timeframe, the script exits.
'Zeit in Sekunden bis zur nächsten Aufnahme
'   Wenn die nächste Aufnahme innerhalb dieser Zeitspanne startet, beendet sich das Script.
'Default/Standard: 60
MinTimeToNextRecord=60

'Should DVBViewer be started automatically if it is not already running?
'Soll der DVBViewer automatisch gestartet werden, wenn er nicht schon läuft?
'true or/oder false.
'Default/Standard: true
StartDVBV=true

'How should DVBViewer be ended (Hibernate=12323, Standby=12324, Close DVBViewer=12326)?
'   Every command number from "actions.ini" in the DVBViewer installation folder can be used.
'   If DVBViewer is playing media at script start time (MP3/video/etc., but not live TV), DVBViewer is set into standby mode and ShutdownActionID is not used.
'   ShutdownActionID is only considered when
'      a) DVBViewer is not (!) running at script start
'      b) DVBViewer is running AND is in standby mode AND is not (!) playing any media at script start
'      c) DVBViewer is running AND live TV is being watched at script start
'Wie soll der DVBViewer beendet werden (Ruhezustand=12323, Schlafzustand=12324, DVBViewer beenden=12326)?
'   Jede Befehlsnummer aus der "actions.ini" im DVBViewer Installationverzeichnis kann benutzt werden.
'   Wenn der DVBViewer beim Scriptstart Medien wiedergibt (MP3/Video/etc., aber kein Live-TV), wird beim Scriptende der MOdus "Keine Wiedergabe" aktiviert und ShutdownActionID nicht berücksichtigt.
'   ShutdownActionID wird nur berücksichtigt wenn
'      a) DVBViewer läuft nicht (!) beim Scriptstart
'      b) DVBViewer läuft beim Scriptstart UND ist im Modus "Keine Wiedergabe" UND gibt keine (!) Medien wieder.
'      c) DVBViewer läuft beim Scriptstart UND Live-TV wird wiedergegeben
'Default/Standard: 12324
ShutdownActionID=12324

'Runs to keep in the logfile.
'   "-1": All entries are kept.
'   "0": Only the last run is kept in the log.
'   Values are rounded up to integer values. "-0,1" becomes "0" etc.
'   Invalid values are handled as "-1".
'Anzahl der Durchläufe, die in der Log-Datei aufbewahrt werden sollen.
'   "-1": Alle Durchläufe werden aufbewahrt.
'   "0": Nur der letzte Lauf wird aufbewahrt.
'   Werte werden auf Integer-Zahlen aufgerunden. "-0,1" wird "0" etc.
'   Ungültige Werte werden als "-1" behandelt.
'Default/Standard: 10
RunsToKeepInLog=10

'Time in seconds to wait when /NoUserInteraction=true.
'   Gives time to wait for "DVB Task scheduler" to do his job and ensures that the system is fully available.
'Zeit in Sekunden die gewartet werden soll wenn /NoUserInteraction=true.
'   Wartet die angegebene Zeit, damit der "DVB Task Scheduler" seine Arbeit erledigen kann und damit das System voll verfügbar ist.
'Default/Standard: 30
WaitBeforeStart=30

'Time in seconds that a channel is tuned to receive additional EPG data (Mediahighway etc.).
'   Only used if DynamicTuneTime=false and DVBViewer is configured to receive additional EPG data.
'Zeit in Sekunden um zusätzliches EPG (Mediahighway etc.) zu empfangen.
'   Wird nur benutzt wenn DynamicTuneTime=false und der DVBViewer für den Empfang zusätzlicher EPG-Daten konfiguriert ist.
'Default/Standard: 600
TimeToReceiveAdditionalEPG=600

'LogFile, deactivated is "".
'Log-Datei, deaktiviert ist "".
'Default/Standard: "DVBViewer-EPG-Update.log"
LogFile="DVBViewer-EPG-Update.log"

'Should DVBViewer be minimized while the script runs?
'Soll der DVBViewer minimiert werden während das Script läuft?
'true or/oder false.
'Default/Standard: true
MinimizeDVBV=true

'Should DVBViewer be muted when the script runs?
'Soll der DVBViewer auf lautlos gestellt werden während das Script läuft?
'true or/oder false.
'Default/Standard: true
MuteDVBV=true

'Should DVBViewer be dynamically configured to receive a certain type of additional EPG data?
'   "" uses the setting defined in DVBViewer, true enables and false disables reception of additional EPG data.
'   Filters defined in ExcludeCat, ExcludeRoot and ExcludeSat are stronger and may exclude additional EPG channels.
'Soll DVBViewer dynamisch für den Empfang zusätzlicher EPG-Daten konfiguriert werden?
'   "" nutzt die Einstellung im DVBViewer, true aktiviert und false deaktiviert den Empfang zusätzlicher EPG-Daten.
'   In ExcludeCat, ExcludeRoot und ExcludeSat definierte Filter sind stärker und können für zusätzlichen EPG-Empfang konfigurierte Kanäle ausfiltern.
'True or/oder false or/oder ""
'Default/Standard: ""
ReceiveMHWEPG=""
ReceiveSFIEPG=""
ReceiveFreeSatEPG=""


Set objShellFindCommonPath = CreateObject("Shell.Application")
Set LCIDDictionary = CreateObject("Scripting.Dictionary")

SectionName="default"

Call FillLCIDDictionary


If "CSCRIPT.EXE" <> UCase(Right(WScript.Fullname, 11)) Then
	msgbox "Script must be started with cscript.exe, not with wscript.exe!"& vbcrlf & vbcrlf & "First, read the file ""readme.txt""," & vbcrlf & "then try ""cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini"".", vbOKOnly+vbCritical, "Error"
	wscript.quit 1
End If

select case weekday(now, 2)
	case 1
		Tag="Monday"
	case 2
		Tag="Tuesday"
	case 3
		Tag="Wednesday"
	case 4
		Tag="Thursday"
	case 5
		Tag="Friday"
	case 6
		Tag="Saturday"
	case 7
		Tag="Sunday"
end select

'Check arguments for ini file
Set iniFileObject = CreateObject("Scripting.FileSystemObject")
iniFile=""
iniFileToUse=""
Set objArgs = WScript.Arguments
For x = 0 to (objArgs.Count-1)
	if left(objArgs(x),2)="--" then
		TempArgumentName=right(objArgs(x),len(objArgs(x))-2)
	elseif left(objArgs(x),1)="/" or left(objArgs(x),1)="-" then
		TempArgumentName=right(objArgs(x),len(objArgs(x))-1)
	else
		TempArgumentName=objArgs(x)
	end if
	if lcase(left(lcase(tempargumentname), len("ini:")))=lcase("ini:") then
		arrtemp=split(TempArgumentName,":")
		if ubound(arrtemp)=1 then inifile=arrtemp(1)
		if ubound(arrtemp)=2 then inifile=arrtemp(1) & ":" & arrtemp(2)
		if ubound(arrtemp)>2 then
			inifile=""
			inifileInfoString="More than two "":"" passed in file path part of parameter /ini." & vbcrlf & "First, read the file ""readme.txt""," & vbcrlf & "then try ""cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini""."
		end if
	end if
	TempArgumentName=""
Next

if inifile="" then
	if inifileInfoString<>"" then
		wscript.echo inifileInfoString
	else
		wscript.echo "Ini file parameter has not been passed to the script or does not contain a file name, exiting." & vbcrlf & "First, read the file ""readme.txt""," & vbcrlf & "then try ""cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini""."
	end if
	wscript.quit 1
else
	if iniFileObject.FileExists(inifile) then
		iniFileToUse=iniFile
	else
		wscript.echo "Ini file not found, exiting." & vbcrlf & "First, read the file ""readme.txt""," & vbcrlf & "then try ""cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini""."
		wscript.quit 1
	end if
end if
inifile=inifiletouse

LogFile=GetValueFromIniFile("Logfile", LogFile)

'Language file
LCIDsComputer = "."
Set LCIDoWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & LCIDsComputer & "\root\cimv2")

Set LCIDcolOperatingSystems = LCIDoWMI.ExecQuery ("Select * from Win32_OperatingSystem")

For Each LCIDoOS in LCIDcolOperatingSystems
	LCIDiOSLang = LCIDoOS.OSLanguage
Next

LanguageFile=GetValueFromIniFile("LanguageFile", LanguageFile)
LanguageFileDefault="en.ini"

Set LanguageFileObject = CreateObject("Scripting.FileSystemObject")

if LanguageFile="" then
	'Detecting system language
	If LCIDDictionary.Exists(getlocale) then
		LCIDtoUse=LCIDiOSLang
		LCIDSplit=split(LCIDDictionary.Item(LCIDtoUse),";")
		LanguageInfoString="Locale ID (LCID): " & LCIDtoUse & " (" & LCIDSplit(0) & ", " & LCIDSplit(1) & ", " & LCIDSplit(2) & ")"
	else
		LCIDtoUse=1033
		LCIDSplit=split(LCIDDictionary.Item(LCIDtoUse),";")
		LanguageInfoString="Locale ID " & getlocale & " unknown. Defaulting to LCID 1033 (" & LCIDSplit(0) & ", " & LCIDSplit(1) & ", " & LCIDSplit(2) & ")"
	end if
	'Check files
	if LanguageFileObject.FileExists(lcidsplit(1)) then
		LanguageFile=lcidsplit(1)
	elseif LanguageFileObject.FileExists(lcidsplit(2)) then
		LanguageFile=lcidsplit(2)
	else
		LanguageFile=LanguageFileDefault
		if LanguageFileObject.FileExists(languagefiledefault) then
			LanguageFile=LanguageFileDefault
		else
			LogMsg("Default language file """ & languagefiledefault & """ not found, exiting.")
			wscript.quit 1
		end if
	end if
else
	if LanguageFileObject.FileExists(languagefile) then
		LanguageFile=LanguageFile
	else
		LanguageInfoString="File """ & languagefile & """ not found, setting language file to default value """ & LanguageFileDefault & """."
		if LanguageFileObject.FileExists(languagefiledefault) then
			LanguageFile=LanguageFileDefault
		else
			LogMsg(LanguageInfoString)
			LogMsg("Default language file """ & languagefiledefault & """ not found, exiting.")
			wscript.quit 1
		end if
	end if
end if


Set IniFileObject = CreateObject("Scripting.FileSystemObject")
Set DVBViewerExeFileObject = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

LogToFileOnly=false
WasAlreadyRunning=false
set DicTransponder=CreateObject("Scripting.Dictionary")
ArgumentsValid=true
UseIniFile=false
WasInStandbyAtStartup=false
WasPlayingMediaAtStartup=false

ScriptStartTime=now

LogMsg("***** " & LanguageGetLine0Var(003) & " *****")
logmsg(LanguageGetLine1Var(004, ScriptVersion))
logmsg(LanguageGetLine1Var(005, DatePart("yyyy",ScriptStartTime) & "-" & Right("0" & DatePart("m",ScriptStartTime), 2) & "-" & Right("0" & DatePart("d",ScriptStartTime), 2) & " " & Right("0" & DatePart("h",ScriptStartTime), 2) & ":" & Right("0" & DatePart("n",ScriptStartTime), 2) & ":" & Right("0" & DatePart("s",ScriptStartTime), 2)))


'Check arguments for validity
For x = 0 to (objArgs.Count-1)
	if left(objArgs(x),2)="--" then
		TempArgumentName=lcase(right(objArgs(x),len(objArgs(x))-2))
	elseif left(objArgs(x),1)="/" or left(objArgs(x),1)="-" then
		TempArgumentName=lcase(right(objArgs(x),len(objArgs(x))-1))
	else
		TempArgumentName=lcase(objArgs(x))
	end if
	if left(TempArgumentName,len("Ini:"))=lcase("Ini:") then
		LogMsg(LanguageGetLine1Var(006, objArgs(x)))
		UseIniFile=true
		If IniFile="" then
			logMsg(LanguageGetLine0Var(007))
			ArgumentsValid=false
		end if
		Set IniFileObject = nothing
		erase arrtemp
	else
		LogMsg(LanguageGetLine1Var(009, objArgs(x)))
		ArgumentsValid=false
	end if
	TempArgumentName=""
Next

if ArgumentsValid=false then
	LogMsg(LanguageGetLine0Var(010))
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	wscript.quit 1
end if


if LanguageInfoString<>"" then
	logmsg(LanguageInfoString)
end if

if inifileInfoString<>"" then
	logmsg(inifileInfoString)
end if

If CheckElevated=true then
	LogMsg(LanguageGetLine0Var(012))
else
	LogMsg(LanguageGetLine0Var(013))
end if


If UseIniFile=true then
	LogMsg(LanguageGetLine0Var(014))
	UpdateFavoritesOnly=GetValueFromIniFile("UpdateFavoritesOnly", UpdateFavoritesOnly)
	NoUserInteraction=GetValueFromIniFile("NoUserInteraction", NoUserInteraction)
	NoUserYes=GetValueFromIniFile("NoUserYes", NoUserYes)
	TestRun=GetValueFromIniFile("TestRun", TestRun)
	IncludeCat=GetValueFromIniFile("IncludeCat", IncludeCat)
	ExcludeCat=GetValueFromIniFile("ExcludeCat", ExcludeCat)
	ExcludeRoot=GetValueFromIniFile("ExcludeRoot", ExcludeRoot)
	ExcludeSat=GetValueFromIniFile("ExcludeSat", ExcludeSat)
	TimeToStartDVBV=cint(GetValueFromIniFile("TimeToStartDVBV", TimeToStartDVBV))
	TimeToGetData=cint(GetValueFromIniFile("TimeToGetData", TimeToGetData))
	MinTimeToNextRecord=cint(GetValueFromIniFile("MinTimeToNextRecord", MinTimeToNextRecord))
	StartDVBV=GetValueFromIniFile("StartDVBV", StartDVBV)
	ShutdownActionID=cint(GetValueFromIniFile("ShutdownActionID", ShutdownActionID))
	RunsToKeepInLog=cint(GetValueFromIniFile("RunsToKeepInLog", RunsToKeepInLog))
	WaitBeforeStart=cint(GetValueFromIniFile("WaitBeforeStart", WaitBeforeStart))
	TimeToReceiveAdditionalEPG=cint(GetValueFromIniFile("TimeToReceiveAdditionalEPG", TimeToReceiveAdditionalEPG))
	DVBViewerExecutablePath=GetValueFromIniFile("DVBViewerExecutablePath", DVBViewerExecutablePath)
	DynamicTuneTime=GetValueFromIniFile("DynamicTuneTime", DynamicTuneTime)
	LogFile=GetValueFromIniFile("Logfile", LogFile)
	MinimizeDVBV=GetValueFromIniFile("MinimizeDVBV", MinimizeDVBV)
	MuteDVBV=GetValueFromIniFile("MuteDVBV", MuteDVBV)
	ReceiveMHWEPG=GetValueFromIniFile("ReceiveMHWEPG", ReceiveMHWEPG)
	ReceiveSFIEPG=GetValueFromIniFile("ReceiveSFIEPG", ReceiveSFIEPG)
	ReceiveFreeSatEPG=GetValueFromIniFile("ReceiveFreeSatEPG", ReceiveFreeSatEPG)

end if

if left(DVBViewerExecutablePath, 1)=chr(34) then
	DVBViewerExecutablePath=right(DVBViewerExecutablePath, len(DVBViewerExecutablePath)-1)
end if

if right(DVBViewerExecutablePath, 1)=chr(34) then
	DVBViewerExecutablePath=left(DVBViewerExecutablePath, len(DVBViewerExecutablePath)-1)
end if

if len(DVBViewerExecutablePath)>0 then
	if right(DVBViewerExecutablePath, 13)="dvbviewer.exe" then
		'do nothing
	else
		if right(DVBViewerExecutablePath, 1)="\" then
			DVBViewerExecutablePath=DVBViewerExecutablePath & "dvbviewer.exe"
		else
			DVBViewerExecutablePath=DVBViewerExecutablePath & "\dvbviewer.exe"
		end if
	end if
	DVBViewerExecutablePathTemp=left(DVBViewerExecutablePath, len(DVBViewerExecutablePath)-13)
end if


'Check path to Executable
if not DVBViewerExecutablePath="" and not DVBViewerExeFileObject.FileExists(DVBViewerExecutablePath) then
	LogMsg(LanguageGetLine0Var(015))
end if

if DVBViewerExecutablePath="" then
	LogMsg(LanguageGetLine0Var(016))
end if

if DVBViewerExecutablePath="" or not DVBViewerExeFileObject.FileExists(DVBViewerExecutablePath) then
	on error resume next
	DVBViewerExecutablePathTemp=WshShell.RegRead("HKLM\software\wow6432node\microsoft\windows\currentversion\uninstall\dvbviewer pro_is1\inno setup: app path")

	if err.number <> 0 then
		err.clear
		DVBViewerExecutablePathTemp=WshShell.RegRead("HKCU\software\wow6432node\microsoft\windows\currentversion\uninstall\dvbviewer pro_is1\inno setup: app path")
	end if

	if err.number <> 0 then
		err.clear
		DVBViewerExecutablePathTemp=WshShell.RegRead("HKLM\software\microsoft\windows\currentversion\uninstall\dvbviewer pro_is1\inno setup: app path")
	end if

	if err.number <> 0 then
		err.clear
		DVBViewerExecutablePathTemp=WshShell.RegRead("HKCU\software\microsoft\windows\currentversion\uninstall\dvbviewer pro_is1\inno setup: app path")
	end if

	if err.number <>0 then DVBViewerExecutablePathTemp=""
	err.clear
	on error goto 0

	If DVBViewerExecutablePathTemp="" then
		LogMsg(LanguageGetLine0Var(017))
		LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
		wscript.quit 1
	else
		DVBViewerExecutablePath=DVBViewerExecutablePathTemp & "\dvbviewer.exe"
	end if
end if

select case readini(DVBViewerExecutablePathTemp & "\usermode.ini", "Mode", "UserMode")
	case 0
		'0: Configuration files are located in the DVBViewer directory (exe path)
		DVBVEPGFilePath=DVBViewerExecutablePathTemp & "\epg.dat"
	case 1
		'1: Configuration files are located in the application data folder
		DVBVEPGFilePath=objShellFindCommonPath.Namespace(&h1a).Self.Path & "\" & readini(DVBViewerExecutablePathTemp & "\usermode.ini", "Mode", "Root") & "\epg.dat"

	case 2
		'2: configuration files are located in the common application data folder
		DVBVEPGFilePath=objShellFindCommonPath.Namespace(&h23).Self.Path & "\" & readini(DVBViewerExecutablePathTemp & "\usermode.ini", "Mode", "Root") & "\epg.dat"
end select


'Display final settings
LogMsg(LanguageGetLine0Var(018))
LogMsg("  DVBViewerExecutablePath=""" & DVBViewerExecutablePath & """")
LogMsg("  DynamicTuneTime=" & DynamicTuneTime)
LogMsg("  ExcludeCat=" & ExcludeCat)
LogMsg("  ExcludeRoot=" & ExcludeRoot)
LogMsg("  ExcludeSat=" & ExcludeSat)
LogMsg("  IncludeCat=" & IncludeCat)
LogMsg("  IniFile=" & IniFile)
LogMsg("  LanguageFile=""" & LanguageFile & """")
LogMsg("  Logfile=" & Logfile)
LogMsg("  MinimizeDVBV=" & MinimizeDVBV)
LogMsg("  MinTimeToNextRecord=" & MinTimeToNextRecord)
LogMsg("  MuteDVBV=" & MuteDVBV)
LogMsg("  NoUserInteraction=" & NoUserInteraction)
LogMsg("  NoUserYes=" & NoUserYes)
LogMsg("  ReceiveFreeSatEPG=" & ReceiveFreeSatEPG)
LogMsg("  ReceiveMHWEPG=" & ReceiveMHWEPG)
LogMsg("  ReceiveSFIEPG=" & ReceiveSFIEPG)
LogMsg("  RunsToKeepInLog=" & RunsToKeepInLog)
LogMsg("  ShutdownActionID=" & ShutdownActionID)
LogMsg("  StartDVBV=" & StartDVBV)
LogMsg("  TestRun=" & TestRun)
LogMsg("  TimeToGetData=" & TimeToGetData)
LogMsg("  TimeToReceiveAdditionalEPG=" & TimeToReceiveAdditionalEPG)
LogMsg("  TimeToStartDVBV=" & TimeToStartDVBV)
LogMsg("  UpdateFavoritesOnly=" & UpdateFavoritesOnly)
LogMsg("  WaitBeforeStart=" & WaitBeforeStart)


call CleanLogfile()


ExcludeCatArray=split(ExcludeCat, "|")
IncludeArray=split(IncludeCat, "|")
ExcludeRootArray=split(ExcludeRoot, "|")
ExcludeSatArray=split(ExcludeSat, "|")

for x=0 to ubound(ExcludeSatArray)
	if lcase(right(ExcludeSatArray(x),2))=lcase("°E") then ExcludeSatArray(x)=cstr(cdbl(left(ExcludeSatArray(x),len(ExcludeSatArray(x))-2))*10)
	if lcase(right(ExcludeSatArray(x),2))=lcase("°W") then ExcludeSatArray(x)=cstr(3600-cdbl((left(ExcludeSatArray(x),len(ExcludeSatArray(x))-2)))*10)
next


'30 Sekunden warten (möglicherweise beendet der DVB Task Scheduler nach einem Hibernate den DVBViewer noch)
if NoUserInteraction=true then
	LogMsg(LanguageGetLine1Var(019, WaitBeforeStart))
	wscript.sleep(WaitBeforeStart*1000)
end if

'Wenn DVBViewer läuft, dann Script beenden mit Error Code 1
set service = GetObject ("winmgmts:")
for each Process in Service.InstancesOf ("Win32_Process")
	if Process.Name = "dvbviewer.exe" then
		if NoUserInteraction=true and NoUserYes=false then
			LogMsg(LanguageGetLine0Var(020))
			LogMsg(LanguageGetLine0Var(021))
			LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
			wscript.quit 1
		elseif NoUserInteraction=true and NoUserYes=true then
			LogMsg(LanguageGetLine0Var(022))
			LogMsg(LanguageGetLine0Var(023))
			WasAlreadyRunning=true
		else
			do until strinput=lcase(LanguageGetLine0Var(024)) or strinput=lcase(LanguageGetLine0Var(025))
				logmsg(LanguageGetLine2Var(026, LanguageGetLine0Var(024), LanguageGetLine0Var(025)))
				strinput = Wscript.StdIn.ReadLine
			loop
			Select Case lcase(strinput)
				Case lcase(LanguageGetLine0Var(024))
					'do nothing, go on
					logmsg(LanguageGetLine1Var(027, strinput))
					logmsg(LanguageGetLine0Var(028))
					WasAlreadyRunning=true
				Case lcase(LanguageGetLine0Var(025))
					logmsg(LanguageGetLine1Var(027, strinput))
					logmsg(LanguageGetLine0Var(029))
					LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
					wscript.quit 1
			End Select
		end if
	End If
next

'DVBViewer starten, falls er nicht schon läuft
If GetDVBVObject(DVBViewer) Then
	DVBViewer.applyconfig
	logmsg(LanguageGetLine0Var(030))
Else
	If WasAlreadyRunning=false Then
		If StartDVBV=true then
			logmsg(LanguageGetLine0Var(033))
			wshshell.run(chr(34) & DVBViewerExecutablePath & chr(34))
		End If
	end if
End If

Logmsg(LanguageGetLine1Var(034, TimeToStartDVBV))
BeginWaitforDVBV=now
do until datediff("s",BeginWaitforDVBV,now)>TimeToStartDVBV
	rc=3
	While rc>0
		If GetDVBVObject(DVBViewer) Then
			rc=0
			if MuteDVBV=true then DVBViewer.osd.setmute 1
		Else
			rc=rc+1
		End if
	wend
loop

'Wenn Fehler, schon eine Aufnahme läuft oder eine Aufnahme ansteht, dann beenden
If DVBViewer is nothing or IsRecordingTime() Then
	Logmsg(LanguageGetLine0Var(035))
	If CheckElevated=true then
		Logmsg(LanguageGetLine0Var(036))
	else
		Logmsg(LanguageGetLine0Var(037))
	end if
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	Set DVBViewer=Nothing
	WScript.Quit 1
End If

'Check Timeshift
if DVBViewer.GetSetupValue("General","Autotimeshift","")="1" _
AND DVBViewer.GetSetupValue("General","WarnTimeShift","")="1" then
	logmsg(LanguageGetLine0Var(031))
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	Set DVBViewer=Nothing
	WScript.Quit 1
end if

if DVBViewer.IsTimeshift _
AND DVBViewer.GetSetupValue("General","WarnTimeShift","")="1" then
	logmsg(LanguageGetLine0Var(032))
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	Set DVBViewer=Nothing
	WScript.Quit 1
end if


if DVBViewer.GetSetupValue("General","NoEPG","")="1" then
	logmsg(LanguageGetLine0Var(076))
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	Set DVBViewer=Nothing
	WScript.Quit 1
end if


rc=3
While rc>0
	If GetDVBVObject(DVBViewer) Then
		rc=0
		'Aktuell eingestellten Kanal merken
		if DVBViewer.CurrentChannelNr<0 and DVBViewer.IsMediaPlayback=false then WasInStandbyAtStartup=true
		if DVBViewer.IsMediaPlayback=true and DVBViewer.IsTimeshift=false then WasPlayingMediaAtStartup=true
		if WasInStandbyAtStartup=false and WasPlayingMediaAtStartup=false then
			lactchannel=DVBViewer.CurrentChannelNr
		else
			lactchannel=DVBViewer.LastChannel
		end if

		
		if MuteDVBV=true then DVBViewer.osd.setmute 1
		if DynamicTuneTime=true then
			logmsg(LanguageGetLine0Var(075))
			dvbviewer.sendcommand(16383)
			if testrun=false then
				if DVBViewer.GetSetupValue("Service","Enabled","")="1" AND _
				 DVBViewer.GetSetupValue("Service","Adress","")<>"" AND _
				 DVBViewer.GetSetupValue("Service","GetEPG","")="1" then
					HTTPPostURL = "http://" & DVBViewer.GetSetupValue("Service","Adress","") & "/index.html"
					HTTPPostParameter = "epg_clear=true"
				else
					HTTPPostURL = ""
					HTTPPostParameter = ""
				end if
			end if
			dvbviewer.sendcommand(12326)
			set DVBViewer=nothing
			DVBVProcessCount=1
			Do until DVBVProcessCount=0
				wscript.sleep(1000)
				DVBVProcessCount=1
				for each Process in Service.InstancesOf ("Win32_Process")
					if Process.Name = "dvbviewer.exe" then
						'still running, loop
						DVBVProcessCount=2
					end if
				next
				if DVBVProcessCount=1 then DVBVProcessCount=0
			loop
			if testrun=false then
				if HTTPPostURL <> "" and HTTPPostParameter <> "" then
					HTTPPost HTTPPostURL, HTTPPostParameter
					if err.number <> 0 then
						LogMsg(LanguageGetLine3Var(070, HTTPPostURL & "?" & HTTPPostParameter, err.number, err.description))
					end if
				end if
				wscript.sleep(5000)
				Set filesys = CreateObject("Scripting.FileSystemObject")
				If filesys.FileExists(DVBVEPGFilePath) Then
					filesys.DeleteFile DVBVEPGFilePath, true
				End If
			end if

			'Start DVBV in Standby mode
			wshshell.run(chr(34) & DVBViewerExecutablePath & chr(34) & " -c")
			BeginWaitforDVBV=now
			do until datediff("s",BeginWaitforDVBV,now)>TimeToStartDVBV
				rcb=3
				while rcb>0
					If GetDVBVObject(DVBViewer) Then
						rcb=0
						if MuteDVBV=true then DVBViewer.osd.setmute 1
					else
						rcb=rcb+1
					end if
				wend
			loop
		end if
	Else
		rc=rc+1
	End if
Wend

OriginalSetupValueMHWEPG=DVBViewer.GetSetupValue("General","MHWEPG","")
OriginalSetupValueSFIEPG=DVBViewer.GetSetupValue("General","SFIEPG","")
OriginalSetupValueFreeSatEPG=DVBViewer.GetSetupValue("General","AllowFreeSat","")


if not (ReceiveMHWEPG=true or ReceiveMHWEPG=false) then
	if DVBViewer.GetSetupValue("General","MHWEPG","")="1" then
		ReceiveMHWEPG=true
	else
		ReceiveMHWEPG=false
	end if
end if

if not (ReceiveSFIEPG=true or ReceiveSFIEPG=false) then
	if DVBViewer.GetSetupValue("General","SFIEPG","")="1" then
		ReceiveSFIEPG=true
	else
		ReceiveSFIEPG=false
	end if
end if

if not (ReceiveFreeSatEPG=true or ReceiveFreeSatEPG=false) then
	if DVBViewer.GetSetupValue("General","AllowFreeSat","")="1" then
		ReceiveFreeSatEPG=true
	else
		ReceiveFreeSatEPG=false
	end if
end if


AdditionalEPGString=DVBViewer.GetSetupValue("MHW","Frequencies","")
if AdditionalEPGString<>"" then
	AdditionalEPGArray=split(AdditionalEPGString,",")
	AdditionalEPGArrayTemp=split(AdditionalEPGString,",")

	for y=0 to ubound(AdditionalEPGArray)
		tempstringx=cstr(AdditionalEPGArray(y))
		if right(tempstringx,1)="0" then
			if instr(1, tempstringx,"h",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
			if instr(1, tempstringx,"v",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
		end if
		if right(tempstringx,1)="1" then
			if instr(1, tempstringx,"h",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
			if instr(1, tempstringx,"v",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
		end if
		if right(tempstringx,1)="2" then
			if instr(1, tempstringx,"h",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
			if instr(1, tempstringx,"v",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
		end if
		if right(tempstringx,1)="3" then
			if instr(1, tempstringx,"h",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
			if instr(1, tempstringx,"v",1)>0 then AdditionalEPGArray(y)="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
		end if
		tempstringx=""
	next
end if

if DVBViewer.GetSetupValue("OSD","ShowMsg","")="0" and DynamicTuneTime=true then
	LogMsg(LanguageGetLine0Var(073))
end if

LogMsg(LanguageGetLine0Var(018))
LogMsg("  AdditionalEPGString=" & AdditionalEPGString)
LogMsg("  DVBViewer Version=" & DVBViewer.osd.appversion)
LogMsg("  OriginalSetupValueFreeSatEPG=" & OriginalSetupValueFreeSatEPG)
LogMsg("  OriginalSetupValueMHWEPG=" & OriginalSetupValueMHWEPG)
LogMsg("  OriginalSetupValueSFIEPG=" & OriginalSetupValueSFIEPG)
LogMsg("  ReceiveFreeSatEPG=" & ReceiveFreeSatEPG)
LogMsg("  ReceiveMHWEPG=" & ReceiveMHWEPG)
LogMsg("  ReceiveSFIEPG=" & ReceiveSFIEPG)
LogMsg("  WasInStandbyAtStartup=" & WasInStandbyAtStartup)
LogMsg("  WasPlayingMediaAtStartup=" & WasPlayingMediaAtStartup)


if MuteDVBV=true then dvbviewer.osd.setmute 1
if MinimizeDVBV=true then dvbviewer.sendcommand(16382) 'minimize


Call ScanChannels
Call TuneChannels


if lactchannel<>"-1" then
	TransponderDataStringType=cstr(vchannels(lactchannel,4))

	if cdbl(vchannels(lactchannel,15))<=1800 and left(TransponderDataStringType,2)="1" then
		OrbPosString=cdbl(vchannels(lactchannel,15))/10 & "°E"
	elseif cdbl(vchannels(lactchannel,15))>1800 and left(TransponderDataStringType,2)="1" then
		OrbPosString=(3600-cdbl(vchannels(lactchannel,15)))/10 & "°W"
	else
		OrbPosString=cdbl(vchannels(lactchannel,15))
	end if
	
	Logmsg(LanguageGetLine3Var(041, lActChannel, vChannels(lActChannel,1), OrbPosString))
	DVBViewer.osd.showinfointvpic LanguageGetLine3Var(041, lActChannel, vChannels(lActChannel,1), orbposstring), 5000
	DVBViewer.CurrentChannelNr=lActChannel
end if

'Rebuild graph
Logmsg(LanguageGetLine0Var(043))
DVBViewer.SendCommand(53)

call UpdateAutoTimer

if MinimizeDVBV=true then dvbviewer.sendcommand(16397) 'restore
if MuteDVBV=true then dvbviewer.osd.setmute 0 'unmute

If IsRecordingTime=true Then
	Logmsg(LanguageGetLine0Var(044))
	LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
Else
	if WasInStandbyAtStartup=true and WasPlayingMediaAtStartup=false then
		'Stop Graph
		DVBViewer.SendCommand(16383)
		Logmsg(LanguageGetLine1Var(042, ShutdownActionID))
		Logmsg(LanguageGetLine0Var(044))
		LogMsg("***** " & LanguageGetLine0Var(11) & " *****")
		'DVBviewer beenden bzw. Rechner runterfahren
		if TestRun=false then DVBViewer.SendCommand(ShutdownActionID)
	elseif WasInStandbyAtStartup=false and WasPlayingMediaAtStartup=true then
		'Stop Graph
		DVBViewer.SendCommand(16383)
		Logmsg(LanguageGetLine0Var(068))
		Logmsg(LanguageGetLine0Var(044))
		LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
	else
		Logmsg(LanguageGetLine1Var(042, ShutdownActionID))
		Logmsg(LanguageGetLine0Var(044))
		LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
		'DVBViewer beenden bzw. Rechner runterfahren
		if TestRun=false then DVBViewer.SendCommand(ShutdownActionID)
	end if
End If


erase vChannels
Set DVBViewer=Nothing
WScript.Quit


'########################################################################################

Sub LogMsg(msg)
	LogMsgString=Right("0" & DatePart("h",time), 2) & ":" & Right("0" & DatePart("n",time), 2) & ":" & Right("0" & DatePart("s",time), 2) & " " & msg
	If "CSCRIPT.EXE" = UCase(Right(WScript.Fullname, 11)) Then
		if len(LogMsgString)>79 then
			wscript.echo left(LogMsgstring,76) & "..."
		else
			wscript.echo LogMsgstring
		end if
	end if
	If Len(LogFile)>0 Then
		set fso = CreateObject("Scripting.FileSystemObject")
		set fsofile = fso.OpenTextFile(LogFile, 8, true)
		fsofile.writeline DatePart("yyyy",Date) & "-" & Right("0" & DatePart("m",Date), 2) & "-" & Right("0" & DatePart("d",Date), 2) & " " & LogMsgString
		fsofile.close
		set fsofile = nothing
		Set fso = nothing
	End If
End Sub


Function IsRecordingTime()
	if getdvbvobject(dvbviewer) then
		'Prüfen ob eine Aufnahme ansteht
		if (DateDiff("s", Now, DVBViewer.TimerManager.NextRecordingTime)<MinTimeToNextRecord AND DateDiff("s", Now, DVBViewer.TimerManager.NextRecordingTime)>=0) _
		OR dvbviewer.timermanager.recording=true _
		OR dvbviewer.timermanager.isTimerAt(now())>=0 then
			IsRecordingTime=true
		Else
			IsRecordingTime=false
		End If
	else
		IsRecordingTime=false
	end if
End Function


Function GetDVBVObject(Obj)
	On Error Resume Next
	Err.Clear
	Set Obj=GetObject(, "DVBViewerServer.DVBViewer")
	If Err.Number<>0 Then
		Set Obj=Nothing
		GetDVBVObject=false
	Else
		GetDVBVObject=true
	End If
	Err.Clear
	on error goto 0
End Function

sub UpdateAutoTimer()
	if DVBViewer.GetSetupValue("Service","Enabled","")="1" AND _
	 DVBViewer.GetSetupValue("Service","Adress","")<>"" then
		LogMsg(LanguageGetLine1Var(069, DVBViewer.GetSetupValue("Service","Adress","")))
		HTTPPostURL = "http://" & DVBViewer.GetSetupValue("Service","Adress","") & "/tasks.html"
		HTTPPostParameter = "task=AutoTimer&aktion=tasks"
		HTTPPost HTTPPostURL, HTTPPostParameter
		if err.number <> 0 then
			LogMsg(LanguageGetLine3Var(070, HTTPPostURL & "?" & HTTPPostParameter, err.number, err.description))
		else
			Logmsg(LanguageGetLine0Var(071))
			wscript.sleep(35000)
		end if
	end if
end sub


Sub ScanChannels()
	iChannelCount=DVBViewer.ChannelManager.GetChannelList(vChannels)

	If UpdateFavoritesOnly=true then
		Logmsg(LanguageGetLine0Var(045))
		Set favCollection = DVBViewer.FavoritesManager.GetFavorites
		i=0
		Do While (i < favCollection.count)
			redim preserve arrChannelIDFavoriteList(i)
			Set favItem = favCollection.item(i)
			arrChannelIDFavoriteListTemp=split(favitem.channelid,"|")
			if dvbviewer.channelmanager.getnr(arrchannelidfavoritelisttemp(0)) <0 then
				arrChannelIDFavoriteList(i)="undefined"
				logmsg(languagegetline4var(080, favitem.nr, favitem.name, favitem.group, arrChannelIDFavoriteListTemp(0)))
			else
				arrChannelIDFavoriteListTempTemp=split(DVBViewer.ChannelManager.GetChannelbyTID(vChannels(dvbviewer.channelmanager.getnr(arrchannelidfavoritelisttemp(0)),26),vChannels(dvbviewer.channelmanager.getnr(arrchannelidfavoritelisttemp(0)),23)).channelid,"|")
				arrChannelIDFavoriteList(i)=arrChannelIDFavoriteListTempTemp(0)
			end if
			erase arrChannelIDFavoriteListTemp
			erase arrChannelIDFavoriteListTempTemp
			i = i + 1
		loop
	end if

	Logmsg(LanguageGetLine0Var(046))
	Logmsg(LanguageGetLine1Var(047, iChannelCount))
	if lactchannel<>"-1" then
		TransponderDataStringType=cstr(vchannels(lactchannel,4))

		if cdbl(vchannels(lactchannel,15))<=1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=cdbl(vchannels(lactchannel,15))/10 & "°E"
		elseif cdbl(vchannels(lactchannel,15))>1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=(3600-cdbl(vchannels(lactchannel,15)))/10 & "°W"
		else
			OrbPosString=cdbl(vchannels(lactchannel,15))
		end if
		Logmsg(LanguageGetLine3Var(040, lActChannel, vChannels(lactchannel,1), OrbPosString))
	end if
		
	TotalTuneTime=0
	AdditionalEPGTransponders=0

	ChannelFilteredOut=true

	For n=0 to iChannelCount-1
		TransponderDataStringType=cstr(vchannels(n,4))

		if cdbl(vchannels(n,15))<=1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=cdbl(vchannels(n,15))/10 & "°E"
		elseif cdbl(vchannels(n,15))>1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=(3600-cdbl(vchannels(n,15)))/10 & "°W"
		else
			OrbPosString=cdbl(vchannels(n,15))
		end if
		IsAdditionalEPGTransponder=false
		StringToWrite=LanguageGetLine3Var(048, n, vChannels(n,1), OrbPosString)
		if len(stringtowrite)>79 then stringtowrite=left(stringtowrite, 76)&"..."
		wscript.stdout.write chr(13) & string(79," ") & chr(13) & stringtowrite & chr(13)
		ChannelFilteredOut=true

		'Check for favorites
		If UpdateFavoritesOnly=true and ChannelFilteredOut=true then
			ChannelIsPartOfFavorites=false
			arrChannelIDChannelList=split(DVBViewer.ChannelManager.GetChannelbyTID(vChannels(n,26),vChannels(n,23)).channelid,"|")
			i=0
			do while i <= ubound(arrChannelIDFavoriteList)
				if arrChannelIDFavoriteList(i)=arrChannelIDChannelList(0) Then
					'ChannelID ist in den Favoriten und in der Senderliste
					ChannelFilteredOut=false
					ChannelIsPartOfFavorites=true
					exit do
				end if
				i=i+1
			loop
		end if

		'ReceiveAdditionalEPG
		if (ReceiveMHWEPG=true or ReceiveSFIEPG=true or ReceiveFreeSatEPG=true) and AdditionalEPGString<>"" then
			for y=0 to ubound(AdditionalEPGArray)
				sTranspID=FormatNumber(vChannels(n,4),0,-1,0,0)+","+FormatNumber(vChannels(n,5),0,-1,0,0)+","+FormatNumber(vChannels(n,14),0,-1,0,0)

				'Tuner type
				if cstr(vchannels(n,4))=cstr(left(AdditionalEPGArray(y),1)) then
					'Polarization
					if cstr(vchannels(n,14))=cstr(right(AdditionalEPGArray(y),1)) then
						'Frequency according to symbol rate
						if (cdbl(vchannels(n,6))<2000 AND abs(cdbl(vchannels(n,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))=0) OR _
						(cdbl(vchannels(n,6))>=2000 AND cdbl(vchannels(n,6))<=3000 AND abs(cdbl(vchannels(n,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))<=1) OR _
						(cdbl(vchannels(n,6))>3000 AND abs(cdbl(vchannels(n,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))<=2) then
							for yy=0 to ubound(AdditionalEPGArrayTemp)
								tempstringx=cstr(AdditionalEPGArrayTemp(yy))
								if instr(1, tempstringx,"h",1)>0 then tempstringy="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
								if instr(1, tempstringx,"v",1)>0 then tempstringy="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
								if right(tempstringx,1)="0" and AdditionalEPGArray(y)=tempstringy and ReceiveMHWEPG=true then
									ChannelFilteredOut=false
									IsAdditionalEPGTransponder=True
								end if
								if right(tempstringx,1)="1" and AdditionalEPGArray(y)=tempstringy and ReceiveMHWEPG=true then
									ChannelFilteredOut=false
									IsAdditionalEPGTransponder=True
								end if
								if right(tempstringx,1)="2" and AdditionalEPGArray(y)=tempstringy and ReceiveSFIEPG=true then
									ChannelFilteredOut=false
									IsAdditionalEPGTransponder=True
								end if
								if right(tempstringx,1)="3" and AdditionalEPGArray(y)=tempstringy and ReceiveFreeSatEPG=true then
									ChannelFilteredOut=false
									IsAdditionalEPGTransponder=True
								end if 
								tempstringx=""
								tempstringy=""
							next
						end if
					end if
				end if
			next
		end if

		'If all channels should be scanned without exception
		If ChannelFilteredOut=true and UpdateFavoritesOnly=false and ubound(includearray)<0 then ChannelFilteredOut=false
	
		'Check for included categories
		If ubound(includearray)>=0 and ChannelFilteredOut=true and UpdateFavoritesOnly=false then
			for y=0 to ubound(IncludeArray)
				if lcase(vChannels(n,2)) = lcase(IncludeArray(y)) then
					ChannelFilteredOut=false
				end if
			next
		end if
		
		'Check for excluded categories
		If ubound(excludecatarray)>=0 and ChannelFilteredOut=false and UpdateFavoritesOnly=false then
			for y=0 to ubound(ExcludeCatArray)
				if (lcase(vChannels(n,2)) = lcase(ExcludeCatArray(y))) then ChannelFilteredOut=true
			next
		end if
		
		'Check for excluded root names
		If ChannelFilteredOut=false and UpdateFavoritesOnly=false and ubound(excluderootarray)>=0 then
			for y=0 to ubound(ExcludeRootArray)
				if lcase(cstr(vChannels(n,0))) = lcase(cstr(ExcludeRootArray(y))) then ChannelFilteredOut=true
			next
		end if

		'Check for excluded orbital positions
		If ChannelFilteredOut=false and UpdateFavoritesOnly=false and ubound(excludesatarray)>=0 then
			for y=0 to ubound(ExcludeSatArray)
				if lcase(cstr(vChannels(n,15))) = lcase(cstr(ExcludeSatArray(y))) then ChannelFilteredOut=true
			next
		end if

		'Add to transponder array
		If ChannelFilteredOut=false then
			'Channel TunerType (4); Orbital Position (15); Frequency (5); Polarity (14)
			sTranspID=cstr(vChannels(n,4)) & ";" & cstr(vChannels(n,15)) & ";" & cstr(vChannels(n,5)) & ";" & cstr(vChannels(n,14))
			If DicTransponder.Exists(sTranspID) then
				'Combination already in array, do nothing
			else
				'Add channel to array
				DicTransponder.Add sTranspID, n
				If IsAdditionalEPGTransponder=True then
					TotalTuneTime=TotalTuneTime+TimeToReceiveAdditionalEPG+2
					AdditionalEPGTransponders=AdditionalEPGTransponders+1
				Else
					TotalTuneTime=TotalTuneTime+TimeToGetData+2
				End If
			End If
		End if
	Next
	wscript.stdout.write chr(13) & string(79," ") & chr(13)
	Logmsg(LanguageGetLine2Var(049, DicTransponder.Count, AdditionalEPGTransponders))
	if DynamicTuneTime=false then Logmsg(LanguageGetLine1Var(050, abs(int((TotalTuneTime/60)+1 mod 2))))
End Sub


Sub TuneChannels()
	Logmsg(LanguageGetLine0Var(051))
	if testrun=true and DynamicTuneTime=false then Logmsg(LanguageGetLine1Var(052, TimeToGetData))
	TransponderChannelNames = DicTransponder.Items
	TransponderData = DicTransponder.Keys
	
	for n=0 to ubound(TransponderData)
		ChannelNumberToTune=transponderchannelnames(n)
		RealTuneTime=TimeToGetData
		AdditionalEPGType=""
		AdditionalEPGFinished=false
		RestartToApplyConfig=false
		TransponderDataStringType=cstr(vchannels(ChannelNumberToTune,4))

		if cdbl(vchannels(n,15))<=1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=cdbl(vchannels(ChannelNumberToTune,15))/10 & "°E"
		elseif cdbl(vchannels(n,15))>1800 and left(TransponderDataStringType,2)="1" then
			OrbPosString=(3600-cdbl(vchannels(ChannelNumberToTune,15)))/10 & "°W"
		else
			OrbPosString=cdbl(vchannels(n,15))
		end if
		
		if left(TransponderDataStringType,2)="0" then transponderdatastringType="DVB-C"
		if left(TransponderDataStringType,2)="1" then transponderdatastringType="DVB-S"
		if left(TransponderDataStringType,2)="2" then transponderdatastringType="DVB-T"
		if left(TransponderDataStringType,2)="3" then transponderdatastringType="ATSC"
		if left(TransponderDataStringType,2)="4" then transponderdatastringType="DVB-IPTV"
			
		TransponderDataStringFreq=cstr(vchannels(channelnumbertotune,5))&","&cstr(vchannels(channelnumbertotune,14))
		if right(TransponderDataStringFreq,2)=",1" then TransponderDataStringFreq=left(TransponderDataStringFreq,len(TransponderDataStringFreq)-2) & "v"
		if right(TransponderDataStringFreq,2)=",0" then TransponderDataStringFreq=left(TransponderDataStringFreq,len(TransponderDataStringFreq)-2) & "h"

		if (ReceiveMHWEPG=true or ReceiveSFIEPG=true or ReceiveFreeSatEPG=true) and AdditionalEPGString<>"" then
			for y=0 to ubound(AdditionalEPGArray)
				'Tuner type
				if cstr(vchannels(ChannelNumberToTune,4))=cstr(left(AdditionalEPGArray(y),1)) then
					'Polarization
					if cstr(vchannels(channelnumbertotune,14))=cstr(right(AdditionalEPGArray(y),1)) then
						'Frequency according to symbol rate
						if (cdbl(vchannels(channelnumbertotune,6))<2000 AND abs(cdbl(vchannels(channelnumbertotune,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))=0) OR _
						(cdbl(vchannels(channelnumbertotune,6))>=2000 AND cdbl(vchannels(channelnumbertotune,6))<=3000 AND abs(cdbl(vchannels(channelnumbertotune,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))<=1) OR _
						(cdbl(vchannels(channelnumbertotune,6))>3000 AND abs(cdbl(vchannels(channelnumbertotune,5))-cdbl(right(left(AdditionalEPGArray(y),len(AdditionalEPGArray(y))-2),len(AdditionalEPGArray(y))-4)))<=2) then
							RealTuneTime=TimeToReceiveAdditionalEPG
							
							'AdditionalEPGArrayTemp=split(AdditionalEPGString,",")
							for yy=0 to ubound(AdditionalEPGArrayTemp)
								tempstringx=cstr(AdditionalEPGArrayTemp(yy))
								if instr(1, tempstringx,"h",1)>0 then tempstringy="1," & left(tempstringx,instr(1,tempstringx,"h",1)-1) & ",0"
								if instr(1, tempstringx,"v",1)>0 then tempstringy="1," & left(tempstringx,instr(1,tempstringx,"v",1)-1) & ",1"
								if right(tempstringx,1)="0" and AdditionalEPGArray(y)=tempstringy then
									AdditionalEPGType="MHWEPG"
									if ReceiveMHWEPG=false and DVBViewer.GetSetupValue("General","MHWEPG","")<>"0" then
										DVBViewer.setsetupvalue "General", "MHWEPG", "0"
										DVBViewer.applyconfig
										RestartToApplyConfig=true
									end if
									if ReceiveMHWEPG=true and DVBViewer.GetSetupValue("General","MHWEPG","")<>"1" then
											DVBViewer.setsetupvalue "General", "MHWEPG", "1"
											DVBViewer.applyconfig
											RestartToApplyConfig=true
									end if
								end if
								if right(tempstringx,1)="1" and AdditionalEPGArray(y)=tempstringy then
									AdditionalEPGType="MHWEPG"
									if ReceiveMHWEPG=false and DVBViewer.GetSetupValue("General","MHWEPG","")<>"0" then
										DVBViewer.setsetupvalue "General", "MHWEPG", "0"
										DVBViewer.applyconfig
										RestartToApplyConfig=true
									end if
									if ReceiveMHWEPG=true and DVBViewer.GetSetupValue("General","MHWEPG","")<>"1" then
											DVBViewer.setsetupvalue "General", "MHWEPG", "1"
											DVBViewer.applyconfig
											RestartToApplyConfig=true
									end if
								end if
								if right(tempstringx,1)="2" and AdditionalEPGArray(y)=tempstringy then
									AdditionalEPGType="SFIEPG"
									if ReceiveSFIEPG=false and DVBViewer.GetSetupValue("General","SFIEPG","")<>"0" then
										DVBViewer.setsetupvalue "General", "SFIEPG", "0"
										DVBViewer.applyconfig
										RestartToApplyConfig=true
									end if
									if ReceiveSFIEPG=true and DVBViewer.GetSetupValue("General","SFIEPG","")<>"1" then
											DVBViewer.setsetupvalue "General", "SFIEPG", "1"
											DVBViewer.applyconfig
											RestartToApplyConfig=true
									end if
								end if
								if right(tempstringx,1)="3" and AdditionalEPGArray(y)=tempstringy then
									AdditionalEPGType="FreeSatEPG"
									if ReceiveFreeSatEPG=false and DVBViewer.GetSetupValue("General","AllowFreeSat","")<>"0" then
										DVBViewer.setsetupvalue "General", "AllowFreeSat", "0"
										DVBViewer.applyconfig
										RestartToApplyConfig=true
									end if
									if ReceiveFreeSatEPG=true and DVBViewer.GetSetupValue("General","AllowFreeSat","")<>"1" then
											DVBViewer.setsetupvalue "General", "AllowFreeSat", "1"
											DVBViewer.applyconfig
											RestartToApplyConfig=true
									end if
								end if 
								tempstringx=""
								tempstringy=""
							next
							if DynamicTuneTime=false then Logmsg(LanguageGetLine1Var(053, AdditionalEPGType))
							if DynamicTuneTime=true then Logmsg(LanguageGetLine1Var(067, AdditionalEPGType))
							if RestartToApplyConfig=true then
								logmsg(LanguageGetLine0Var(078))
								call RestartDVBVInStandby
							end if
						end if
					end if
				end if
			next
		end if

		if TestRun=false then
			If IsRecordingTime() Then
				Logmsg(LanguageGetLine0Var(054))
				DVBViewer.osd.showinfointvpic LanguageGetLine0Var(054), 2000
				WScript.Sleep(2000)
				Exit For
			End If
		end if

		if testrun=false then
			LogMsg(LanguageGetLine7Var(055, right("00" & n+1,3), right("00" & DicTransponder.Count,3), TransponderDataStringType, OrbPosString, transponderdatastringfreq, vchannels(channelnumbertotune, 1), channelnumbertotune))
			If ChannelNumberToTune>-1 Then
				DVBViewer.osd.showinfointvpic LanguageGetLine7Var(055, right("00" & n+1,3), right("00" & DicTransponder.Count,3), TransponderDataStringType, OrbPosString, transponderdatastringfreq, vchannels(channelnumbertotune, 1), channelnumbertotune), 2000
				DVBViewer.CurrentChannelNr=ChannelNumberToTune
			End If

			TuneChannelLastRunTime=now
			EPGLastCount=0
			EPGLastChangeTime=now
			
			if DynamicTuneTime=true then
				'tune channel until epg entry count is stable
				do until ((datediff("s", EPGlastchangetime, now)>5) and (AdditionalEPGFinished=true)) OR (datediff("s", EPGlastchangetime, now)>TimeToReceiveAdditionalEPG) OR (datediff("s", TuneChannelLastRunTime, now)>TimeToReceiveAdditionalEPG*2)
					select case AdditionalEPGType
						case "MHWEPG"
							if receivemhwepg=false _
							OR (receivemhwepg=true and dvbviewer.datamanager.value("#Info")=readini(left(dvbviewerexecutablepath, len(dvbviewerexecutablepath)-13)&"language\"& DVBViewer.GetSetupValue("General","Language","") &".lng", "Display", "43")) _
							OR (receivemhwepg=true and DVBViewer.GetSetupValue("OSD","ShowMsg","")="0") then
								AdditionalEPGFinished=true
							end if
						case "SFIEPG"
							if receivesfiepg=false _
							OR (receivesfiepg=true and dvbviewer.datamanager.value("#Info")=readini(left(dvbviewerexecutablepath, len(dvbviewerexecutablepath)-13)&"language\"& DVBViewer.GetSetupValue("General","Language","") &".lng", "Display", "46")) _
							OR (receivesfiepg=true and DVBViewer.GetSetupValue("OSD","ShowMsg","")="0") then
								AdditionalEPGFinished=true
							end if
						case "FreeSatEPG"
							AdditionalEPGFinished=true
						case else
							AdditionalEPGFinished=true
					end select
					TempEPGArrayCount=dvbviewer.epgmanager.get(0,0,0,0).count
					if TempEPGArrayCount=EPGLastCount then
						'stable, do nothing
					else
						epglastcount=TempEPGArrayCount
						epglastchangetime=now
					end if
					StringToWrite=LanguageGetLine3Var(072, EPGLastCount, datediff("s", EPGlastchangetime, now), datediff("s", TuneChannelLastRunTime, now))
					DVBViewer.osd.showinfointvpic LanguageGetLine3Var(072, EPGLastCount, datediff("s", EPGlastchangetime, now), datediff("s", TuneChannelLastRunTime, now)), 5000
					if len(stringtowrite)>79 then stringtowrite=left(stringtowrite, 76)&"..."
					wscript.stdout.write chr(13) & string(79," ") & chr(13) & stringtowrite & chr(13)
					wscript.sleep(250)
					
					If DVBViewer.CurrentChannelNr=ChannelNumberToTune then
						'channel has not been manually changed, do nothing
					else
						'channel has been manually changed, someone is using DVBViewer or channel could not be tuned ("hardware not available", for example)
						'Log and exit script.
						if MuteDVBV=true then DVBViewer.osd.setmute 0
						DVBViewer.setsetupvalue "General", "MHWEPG", OriginalSetupValueMHWEPG
						DVBViewer.setsetupvalue "General","SFIEPG", OriginalSetupValueSFIEPG
						DVBViewer.setsetupvalue "General", "AllowFreeSat", OriginalSetupValueFreeSatEPG
						DVBViewer.applyconfig
						wscript.stdout.write chr(13) & string(79," ") & chr(13)
						LogMsg(LanguageGetLine2Var(057, ChannelNumberToTune, DVBViewer.CurrentChannelNr))
						DVBViewer.osd.showinfointvpic LanguageGetLine0Var(058), 5000
						LogMsg(LanguageGetLine0Var(058))
						call UpdateAutoTimer
						LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
						Set DVBViewer=Nothing
						wscript.quit 1
					end if
				loop
			else
				'tune channel for a certain time
				do until datediff("s", TuneChannelLastRunTime, now)=>RealTuneTime
					StringToWrite=LanguageGetLine1Var(056, RealTuneTime-datediff("s", TuneChannelLastRunTime, now))
					DVBViewer.osd.showinfointvpic LanguageGetLine1Var(056, RealTuneTime-datediff("s", TuneChannelLastRunTime, now)), 5000
					if len(stringtowrite)>79 then stringtowrite=left(stringtowrite, 76)&"..."
					wscript.stdout.write chr(13) &string(79," ") &chr(13) &stringtowrite & chr(13)
					wscript.sleep(750)

					If DVBViewer.CurrentChannelNr=ChannelNumberToTune then
						'channel has not been manually changed, do nothing
					else
						'channel has been manually changed, someone is using DVBViewer or channel could not be tuned ("hardware not available", for example)
						'Log and exit script.
						if MuteDVBV=true then DVBViewer.osd.setmute 0
						DVBViewer.setsetupvalue "General", "MHWEPG", OriginalSetupValueMHWEPG
						DVBViewer.setsetupvalue "General","SFIEPG", OriginalSetupValueSFIEPG
						DVBViewer.setsetupvalue "General", "AllowFreeSat", OriginalSetupValueFreeSatEPG
						DVBViewer.applyconfig
						wscript.stdout.write chr(13) & string(79," ") & chr(13)
						LogMsg(LanguageGetLine2Var(057, ChannelNumberToTune, DVBViewer.CurrentChannelNr))
						DVBViewer.osd.showinfointvpic LanguageGetLine0Var(058), 5000
						LogMsg(LanguageGetLine0Var(058))
						call UpdateAutoTimer
						LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
						Set DVBViewer=Nothing
						wscript.quit 1
					end if
				loop

			end if
			wscript.stdout.write chr(13) & string(79," ") & chr(13)
		else
			LogMsg(LanguageGetLine7Var(055, right("00" & n+1,3), right("00" & DicTransponder.Count,3), TransponderDataStringType, OrbPosString, transponderdatastringfreq, vchannels(ChannelNumberToTune,1), channelnumbertotune))
		end if
	next
	if 	OriginalSetupValueMHWEPG<>DVBViewer.GetSetupValue("General","MHWEPG","") or _
	OriginalSetupValueSFIEPG<>DVBViewer.GetSetupValue("General","SFIEPG","") or _
	OriginalSetupValueFreeSatEPG<>DVBViewer.GetSetupValue("General","AllowFreeSat","") then
		DVBViewer.setsetupvalue "General", "MHWEPG", OriginalSetupValueMHWEPG
		DVBViewer.setsetupvalue "General", "SFIEPG", OriginalSetupValueSFIEPG
		DVBViewer.setsetupvalue "General", "AllowFreeSat", OriginalSetupValueFreeSatEPG
		DVBViewer.applyconfig
		logmsg(LanguageGetLine0Var(078))
		call RestartDVBVInStandby
	end if
End Sub


Sub CleanLogfile()
	RunsToKeep=RunsToKeepInLog
	RunsFoundSearchText="***** " & LanguageGetLine0Var(003) & " *****"
	If IsNumeric(runstokeep) Then
		RunsToKeep=int(RunsToKeep) + abs((RunsToKeep - int(RunsToKeep)) <> 0)
		if runstokeep>0 then
			logmsg(LanguageGetLine1Var(059,RunsToKeep))
		elseif runstokeep=-1 then
			logmsg(LanguageGetLine0Var(060,RunsToKeep))
		else
			logmsg(LanguageGetLine1Var(061,RunsToKeep))
			logmsg(LanguageGetLine0Var(062))
			RunsToKeep=-1
		end if
	else
		logmsg(LanguageGetLine1Var(061,RunsToKeep))
		logmsg(LanguageGetLine0Var(062))
		RunsToKeep=-1
	end if

	If RunsToKeep>0 then
		set fso = CreateObject("Scripting.FileSystemObject")
		If FSO.FileExists(logFile) Then
			Set tsInput = FSO.OpenTextFile(logfile)
			logarray = Split(tsInput.ReadAll(), vbNewLine)
			tsInput.Close
			RunsFound=0
			For Line = UBound(logarray) To 0 Step -1
				strline = logarray(Line)
				if instr(1, strline, RunsFoundSearchText, vbTextCompare) then
					RunsFound=RunsFound+1
				end if
				if RunsFound=RunsToKeep then
					KeepFromLine=line
					exit for
				end if
			Next
			If KeepFromLine > 0 then
				'delete file
				fso.deletefile(logfile)
				'write new file
				set fso = CreateObject("Scripting.FileSystemObject")
				set fsofile = fso.OpenTextFile(LogFile, 8, true)

				for line=KeepFromLine to ubound(logarray)
					if line=ubound(logarray) then
						if logarray(line)<>"" then
							fsofile.writeline logarray(line)
						end if
					else
						fsofile.writeline logarray(line)
					end if
				next
				fsofile.close
				logmsg(LanguageGetLine1Var(063,keepfromline))
			else
				logmsg(LanguageGetLine1Var(064,runstokeep))
			end if
		End If
	else
		If FSO.FileExists(logFile) Then
			logmsg(LanguageGetLine0Var(065))
			fso.deletefile(logfile)
		else
			logmsg(LanguageGetLine0Var(066))
		end if
	end if
end sub


Function CheckElevated () 'test whether user has elevated token
	Set oWMI = GetObject("winmgmts:\\.\root\cimv2")
	Set oOSInfo = oWMI.ExecQuery("SELECT version FROM Win32_OperatingSystem")
	For Each os in oOSInfo
		If Int(Left(os.Version, 1)) >= 6 Then
			Set oExecWhoami = wshShell.Exec("whoami /groups")
			Set oWhoamiOutput = oExecWhoami.StdOut
			strWhoamiOutput = oWhoamiOutput.ReadAll
			If InStr(1, strWhoamiOutput, "S-1-16-12288", vbTextCompare) Then
				CheckElevated = true
			Else
				CheckElevated = false
			End If
		else
			CheckElevated=true
		end if
	next
End Function


Function HTTPPost(sUrl, sRequest)
	set oHTTP=WScript.CreateObject("MSXML2.ServerXMLHTTP") 
	oHTTP.open "Get", sUrl & "?" & sRequest ,false
	oHTTP.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
	on error resume next
	err.clear
	oHTTP.send
	if err.number<>0 then
		LogMsg(languagegetline3var(074, sURL, err.number, err.description))
		LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
		wscript.quit 1
	end if
	on error goto 0
	HTTPPost = oHTTP.responseText
End Function


Function ReadIni( myFilePath, mySection, myKey )
    ' This function returns a value read from an INI file
    '
    ' Arguments:
    ' myFilePath  [string]  the (path and) file name of the INI file
    ' mySection   [string]  the section in the INI file to be searched
    ' myKey       [string]  the key whose value is to be returned
    '
    ' Returns:
    ' the [string] value for the specified key in the specified section
    '
    ' CAVEAT:     Will return a space if key exists but value is blank
    '
    ' Written by Keith Lacelle
    ' Modified by Denis St-Pierre, Rob van der Woude, Markus Gruber

    Const ForReading   = 1
    Const ForWriting   = 2
    Const ForAppending = 8

    Set objFSOini = CreateObject( "Scripting.FileSystemObject" )

    ReadIni     = ""
    strFilePath = Trim( myFilePath )
    strSection  = Trim( mySection )
    strKey      = Trim( myKey )
	strLine		= ""

    If objFSOini.FileExists( strFilePath ) Then
        Set objIniFile = objFSOini.OpenTextFile( strFilePath, ForReading, False )
        Do While objIniFile.AtEndOfStream = False
            strLine = Trim( objIniFile.ReadLine )

            ' Check if section is found in the current line
            If LCase( strLine ) = "[" & LCase( strSection ) & "]" Then
                strLine = LTrim( objIniFile.ReadLine )

                ' Parse lines until the next section is reached
                Do While Left( strLine, 1 ) <> "["
                    ' Find position of equal sign in the line
                    intEqualPos = InStr( 1, strLine, "=", 1 )
                    If intEqualPos > 0 Then
                        strLeftString = Left( strLine, intEqualPos - 1 )
                        ' Check if item is found in the current line
                        If LCase( strLeftString ) = LCase( strKey ) Then
                            ReadIni = Mid( strLine, intEqualPos + 1 )
                             ' Abort loop when item is found
                            Exit Do
                        End If
                    End If

                    ' Abort if the end of the INI file is reached
                    If objIniFile.AtEndOfStream Then Exit Do

                    ' Continue with next line
                    strLine = LTrim( objIniFile.ReadLine )
                Loop
            Exit Do
            End If
        Loop
        objIniFile.Close
    Else
		LogMsg(LanguageGetLine1Var(077, strFilePath))
		LogMsg("***** " & LanguageGetLine0Var(011) & " *****")
        Wscript.Quit 1
    End If
End Function


Public Function LanguageGetLine0Var(LanguageLineNumber)
	LanguageGetLine0Var=replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)), "$CRLF$", vbcrlf,1,-1,1)
End Function


Public Function LanguageGetLine1Var(LanguageLineNumber, LanguageReplaceVar1)
	LanguageGetLine1Var=replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$CRLF$", vbcrlf, 1,-1 ,1)
End Function


Public Function LanguageGetLine2Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2)
	LanguageGetLine2Var=replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$CRLF$", vbcrlf,1,-1,1)
End Function


Public Function LanguageGetLine3Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3)
	LanguageGetLine3Var=replace(replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$3$", LanguageReplaceVar3), "$CRLF$", vbcrlf,1,-1,1)
End Function


Public Function LanguageGetLine4Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3, LanguageReplaceVar4)
	LanguageGetLine4Var=replace(replace(replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$3$", LanguageReplaceVar3), "$4$", LanguageReplaceVar4), "$CRLF$", vbcrlf,1,-1,1)
End Function


Public Function LanguageGetLine5Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3, LanguageReplaceVar4, LanguageReplaceVar5)
	LanguageGetLine5Var=replace(replace(replace(replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$3$", LanguageReplaceVar3), "$4$", LanguageReplaceVar4), "$5$", LanguageReplaceVar5), "$CRLF$", vbcrlf,1,-1,1)
End Function


Public Function LanguageGetLine6Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3, LanguageReplaceVar4, LanguageReplaceVar5, LanguageReplaceVar6)
	LanguageGetLine6Var=replace(replace(replace(replace(replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$3$", LanguageReplaceVar3), "$4$", LanguageReplaceVar4), "$5$", LanguageReplaceVar5), "$6$", LanguageReplaceVar6), "$CRLF$", vbcrlf,1,-1,1)
End Function

Public Function LanguageGetLine7Var(LanguageLineNumber, LanguageReplaceVar1, LanguageReplaceVar2, LanguageReplaceVar3, LanguageReplaceVar4, LanguageReplaceVar5, LanguageReplaceVar6, LanguageReplaceVar7)
	LanguageGetLine7Var=replace(replace(replace(replace(replace(replace(replace(replace(readini(languagefile, "default", right("000" & LanguageLineNumber, 3)),"$1$",LanguageReplaceVar1), "$2$", LanguageReplaceVar2), "$3$", LanguageReplaceVar3), "$4$", LanguageReplaceVar4), "$5$", LanguageReplaceVar5), "$6$", LanguageReplaceVar6), "$7$", LanguageReplaceVar7), "$CRLF$", vbcrlf,1,-1,1)
End Function


function GetValueFromIniFile(KeyName, TargetVariableName)
	if sectionname="default" then
		TargetVariableNameTemp=TargetVariableName
	end if
	do until sectionname=""
		GetValueFromIniFileTempString=readini(inifile, SectionName, KeyName)
		select case lcase(GetValueFromIniFileTempString)
			case ""
				'Key not found
				if TargetVariableNameTemp=true then
					GetValueFromIniFile=true
				elseif TargetVariableNameTemp=false then
					GetValueFromIniFile=false
				else
					GetValueFromIniFile=TargetVariableNameTemp
				end if
			case " "
				'Key found but empty
				if TargetVariableNameTemp=true then
					GetValueFromIniFile=true
				elseif TargetVariableNameTemp=false then
					GetValueFromIniFile=false
				else
					GetValueFromIniFile=TargetVariableNameTemp
				end if
			case "true"
				'correctly set boolean value
				GetValueFromIniFile=true
			case "false"
				'correctly set boolean value
				GetValueFromIniFile=false
			case else
				if left(GetValueFromIniFileTempString,1)="""" then GetValueFromIniFileTempString=right(GetValueFromIniFileTempString, len(GetValueFromIniFileTempString)-1)
				if right(GetValueFromIniFileTempString,1)="""" then GetValueFromIniFileTempString=left(GetValueFromIniFileTempString, len(GetValueFromIniFileTempString)-1)
				GetValueFromIniFile=GetValueFromIniFileTempString
		end select
		GetValueFromIniFileTempString=""
		if lcase(sectionname)="default" then
			sectionname=Tag
			TargetVariableNameTemp=GetValueFromIniFile
		else
			sectionname=""
		end if
	loop
	TargetVariableNameTemp=""
	sectionname="default"
end function

sub FillLCIDDictionary()
	LCIDDictionary.Add 1025, "Arabic - Saudi Arabia;ar-sa.ini;ar.ini"
	LCIDDictionary.Add 1026, "Bulgarian;bg.ini;bg.ini"
	LCIDDictionary.Add 1027, "Catalan;ca.ini;ca.ini"
	LCIDDictionary.Add 1028, "Chinese - Taiwan;zh-tw.ini;zh.ini"
	LCIDDictionary.Add 1029, "Czech;cs.ini;cs.ini"
	LCIDDictionary.Add 1030, "Danish;da.ini;da.ini"
	LCIDDictionary.Add 1031, "German - Germany;de-de.ini;de.ini"
	LCIDDictionary.Add 1032, "Greek;el.ini;el.ini"
	LCIDDictionary.Add 1033, "English - United States;en-us.ini;en.ini"
	LCIDDictionary.Add 1034, "Spanish - Spain;es-es.ini;es.ini"
	LCIDDictionary.Add 1035, "Finnish;fi.ini;fi.ini"
	LCIDDictionary.Add 1036, "French - France;fr-fr.ini;fr.ini"
	LCIDDictionary.Add 1037, "Hebrew;he.ini;he.ini"
	LCIDDictionary.Add 1038, "Hungarian;hu.ini;hu.ini"
	LCIDDictionary.Add 1039, "Icelandic;is.ini;is.ini"
	LCIDDictionary.Add 1040, "Italian - Italy;it-it.ini;it.ini"
	LCIDDictionary.Add 1041, "Japanese;ja.ini;ja.ini"
	LCIDDictionary.Add 1042, "Korean;ko.ini;ko.ini"
	LCIDDictionary.Add 1043, "Dutch - Netherlands;nl-nl.ini;nl.ini"
	LCIDDictionary.Add 1044, "Norwegian - Bokml;no-no.ini;no.ini"
	LCIDDictionary.Add 1045, "Polish;pl.ini;pl.ini"
	LCIDDictionary.Add 1046, "Portuguese - Brazil;pt-br.ini;pt.ini"
	LCIDDictionary.Add 1047, "Raeto-Romance;rm.ini;rm.ini"
	LCIDDictionary.Add 1048, "Romanian - Romania;ro.ini;ro.ini"
	LCIDDictionary.Add 1049, "Russian;ru.ini;ru.ini"
	LCIDDictionary.Add 1050, "Croatian;hr.ini;hr.ini"
	LCIDDictionary.Add 1051, "Slovak;sk.ini;sk.ini"
	LCIDDictionary.Add 1052, "Albanian;sq.ini;sq.ini"
	LCIDDictionary.Add 1053, "Swedish - Sweden;sv-se.ini;sv.ini"
	LCIDDictionary.Add 1054, "Thai;th.ini;th.ini"
	LCIDDictionary.Add 1055, "Turkish;tr.ini;tr.ini"
	LCIDDictionary.Add 1056, "Urdu;ur.ini;ur.ini"
	LCIDDictionary.Add 1057, "Indonesian;id.ini;id.ini"
	LCIDDictionary.Add 1058, "Ukrainian;uk.ini;uk.ini"
	LCIDDictionary.Add 1059, "Belarusian;be.ini;be.ini"
	LCIDDictionary.Add 1060, "Slovenian;sl.ini;sl.ini"
	LCIDDictionary.Add 1061, "Estonian;et.ini;et.ini"
	LCIDDictionary.Add 1062, "Latvian;lv.ini;lv.ini"
	LCIDDictionary.Add 1063, "Lithuanian;lt.ini;lt.ini"
	LCIDDictionary.Add 1065, "Farsi;fa.ini;fa.ini"
	LCIDDictionary.Add 1066, "Vietnamese;vi.ini;vi.ini"
	LCIDDictionary.Add 1067, "Armenian;hy.ini;hy.ini"
	LCIDDictionary.Add 1068, "Azeri - Latin;az-az.ini;az.ini"
	LCIDDictionary.Add 1069, "Basque;eu.ini;eu.ini"
	LCIDDictionary.Add 1070, "Sorbian;sb.ini;sb.ini"
	LCIDDictionary.Add 1071, "Macedonian (FYROM);mk.ini;mk.ini"
	LCIDDictionary.Add 1072, "Southern Sotho;st.ini;st.ini"
	LCIDDictionary.Add 1073, "Tsonga;ts.ini;ts.ini"
	LCIDDictionary.Add 1074, "Setsuana;tn.ini;tn.ini"
	LCIDDictionary.Add 1076, "Xhosa;xh.ini;xh.ini"
	LCIDDictionary.Add 1077, "Zulu;zu.ini;zu.ini"
	LCIDDictionary.Add 1078, "Afrikaans;af.ini;af.ini"
	LCIDDictionary.Add 1080, "Faroese;fo.ini;fo.ini"
	LCIDDictionary.Add 1081, "Hindi;hi.ini;hi.ini"
	LCIDDictionary.Add 1082, "Maltese;mt.ini;mt.ini"
	LCIDDictionary.Add 1084, "Gaelic - Scotland;gd.ini;gd.ini"
	LCIDDictionary.Add 1085, "Yiddish;yi.ini;yi.ini"
	LCIDDictionary.Add 1086, "Malay - Malaysia;ms-my.ini;ms.ini"
	LCIDDictionary.Add 1089, "Swahili;sw.ini;sw.ini"
	LCIDDictionary.Add 1091, "Uzbek – Latin;uz-uz.ini;uz.ini"
	LCIDDictionary.Add 1092, "Tatar;tt.ini;tt.ini"
	LCIDDictionary.Add 1097, "Tamil;ta.ini;ta.ini"
	LCIDDictionary.Add 1102, "Marathi;mr.ini;mr.ini"
	LCIDDictionary.Add 1103, "Sanskrit;sa.ini;sa.ini"
	LCIDDictionary.Add 2049, "Arabic - Iraq;ar-iq.ini;ar.ini"
	LCIDDictionary.Add 2052, "Chinese - China;zh-cn.ini;zh.ini"
	LCIDDictionary.Add 2055, "German - Switzerland;de-ch.ini;de.ini"
	LCIDDictionary.Add 2057, "English - United Kingdom;en-gb.ini;en.ini"
	LCIDDictionary.Add 2058, "Spanish - Mexico;es-mx.ini;es.ini"
	LCIDDictionary.Add 2060, "French - Belgium;fr-be.ini;fr.ini"
	LCIDDictionary.Add 2064, "Italian - Switzerland;it-ch.ini;it.ini"
	LCIDDictionary.Add 2067, "Dutch - Belgium;nl-be.ini;nl.ini"
	LCIDDictionary.Add 2068, "Norwegian - Nynorsk;no-no.ini;no.ini"
	LCIDDictionary.Add 2070, "Portuguese - Portugal;pt-pt.ini;pt.ini"
	LCIDDictionary.Add 2072, "Romanian - Moldova;ro-mo.ini;ro.ini"
	LCIDDictionary.Add 2073, "Russian - Moldova;ru-mo.ini;ru.ini"
	LCIDDictionary.Add 2074, "Serbian - Latin;sr-sp.ini;sr.ini"
	LCIDDictionary.Add 2077, "Swedish - Finland;sv-fi.ini;sv.ini"
	LCIDDictionary.Add 2092, "Azeri - Cyrillic;az-az.ini;az.ini"
	LCIDDictionary.Add 2108, "Gaelic - Ireland;gd-ie.ini;gd.ini"
	LCIDDictionary.Add 2110, "Malay – Brunei;ms-bn.ini;ms.ini"
	LCIDDictionary.Add 2115, "Uzbek - Cyrillic;uz-uz.ini;uz.ini"
	LCIDDictionary.Add 3073, "Arabic - Egypt;ar-eg.ini;ar.ini"
	LCIDDictionary.Add 3076, "Chinese - Hong Kong SAR;zh-hk.ini;zh.ini"
	LCIDDictionary.Add 3079, "German - Austria;de-at.ini;de.ini"
	LCIDDictionary.Add 3081, "English - Australia;en-au.ini;en.ini"
	LCIDDictionary.Add 3084, "French - Canada;fr-ca.ini;fr.ini"
	LCIDDictionary.Add 3098, "Serbian - Cyrillic;sr-sp.ini;sr.ini"
	LCIDDictionary.Add 4097, "Arabic - Libya;ar-ly.ini;ar.ini"
	LCIDDictionary.Add 4100, "Chinese - Singapore;zh-sg.ini;zh.ini"
	LCIDDictionary.Add 4103, "German - Luxembourg;de-lu.ini;de.ini"
	LCIDDictionary.Add 4105, "English - Canada;en-ca.ini;en.ini"
	LCIDDictionary.Add 4106, "Spanish - Guatemala;es-gt.ini;es.ini"
	LCIDDictionary.Add 4108, "French - Switzerland;fr-ch.ini;fr.ini"
	LCIDDictionary.Add 5121, "Arabic - Algeria;ar-dz.ini;ar.ini"
	LCIDDictionary.Add 5124, "Chinese - Macau SAR;zh-mo.ini;zh.ini"
	LCIDDictionary.Add 5127, "German - Liechtenstein;de-li.ini;de.ini"
	LCIDDictionary.Add 5129, "English - New Zealand;en-nz.ini;en.ini"
	LCIDDictionary.Add 5130, "Spanish - Costa Rica;es-cr.ini;es.ini"
	LCIDDictionary.Add 5132, "French - Luxembourg;fr-lu.ini;fr.ini"
	LCIDDictionary.Add 6145, "Arabic - Morocco;ar-ma.ini;ar.ini"
	LCIDDictionary.Add 6153, "English - Ireland;en-ie.ini;en.ini"
	LCIDDictionary.Add 6154, "Spanish - Panama;es-pa.ini;es.ini"
	LCIDDictionary.Add 7169, "Arabic - Tunisia;ar-tn.ini;ar.ini"
	LCIDDictionary.Add 7177, "English - South Africa;en-za.ini;en.ini"
	LCIDDictionary.Add 7178, "Spanish - Dominican Republic;es-do.ini;es.ini"
	LCIDDictionary.Add 8193, "Arabic - Oman;ar-om.ini;ar.ini"
	LCIDDictionary.Add 8201, "English - Jamaica;en-jm.ini;en.ini"
	LCIDDictionary.Add 8202, "Spanish - Venezuela;es-ve.ini;es.ini"
	LCIDDictionary.Add 9217, "Arabic - Yemen;ar-ye.ini;ar.ini"
	LCIDDictionary.Add 9225, "English - Caribbean;en-cb.ini;en.ini"
	LCIDDictionary.Add 9226, "Spanish - Colombia;es-co.ini;es.ini"
	LCIDDictionary.Add 10241, "Arabic - Syria;ar-sy.ini;ar.ini"
	LCIDDictionary.Add 10249, "English - Belize;en-bz.ini;en.ini"
	LCIDDictionary.Add 10250, "Spanish - Peru;es-pe.ini;es.ini"
	LCIDDictionary.Add 11265, "Arabic - Jordan;ar-jo.ini;ar.ini"
	LCIDDictionary.Add 11273, "English - Trinidad;en-tt.ini;en.ini"
	LCIDDictionary.Add 11274, "Spanish - Argentina;es-ar.ini;es.ini"
	LCIDDictionary.Add 12289, "Arabic - Lebanon;ar-lb.ini;ar.ini"
	LCIDDictionary.Add 12298, "Spanish - Ecuador;es-ec.ini;es.ini"
	LCIDDictionary.Add 13313, "Arabic - Kuwait;ar-kw.ini;ar.ini"
	LCIDDictionary.Add 13321, "English - Phillippines;en-ph.ini;en.ini"
	LCIDDictionary.Add 13322, "Spanish - Chile;es-cl.ini;es.ini"
	LCIDDictionary.Add 14337, "Arabic - United Arab Emirates;ar-ae.ini;ar.ini"
	LCIDDictionary.Add 14346, "Spanish - Uruguay;es-uy.ini;es.ini"
	LCIDDictionary.Add 15361, "Arabic - Bahrain;ar-bh.ini;ar.ini"
	LCIDDictionary.Add 15370, "Spanish - Paraguay;es-py.ini;es.ini"
	LCIDDictionary.Add 16385, "Arabic - Qatar;ar-qa.ini;ar.ini"
	LCIDDictionary.Add 16394, "Spanish - Bolivia;es-bo.ini;es.ini"
	LCIDDictionary.Add 17418, "Spanish - El Salvador;es-sv.ini;es.ini"
	LCIDDictionary.Add 18442, "Spanish - Honduras;es-hn.ini;es.ini"
	LCIDDictionary.Add 19466, "Spanish - Nicaragua;es-ni.ini;es.ini"
	LCIDDictionary.Add 20490, "Spanish - Puerto Rico;es-pr.ini;es.ini"
end sub

sub RestartDVBVInStandby()
	dvbviewer.sendcommand(12326)
	set DVBViewer=nothing
	DVBVProcessCount=1
	Do until DVBVProcessCount=0
		wscript.sleep(1000)
		DVBVProcessCount=1
		for each Process in Service.InstancesOf ("Win32_Process")
			if Process.Name = "dvbviewer.exe" then
				'still running, loop
				DVBVProcessCount=2
			end if
		next
		if DVBVProcessCount=1 then DVBVProcessCount=0
	loop
	'Start DVBV in Standby mode
	wshshell.run(chr(34) & DVBViewerExecutablePath & chr(34) & " -c")
	BeginWaitforDVBV=now
	do until datediff("s",BeginWaitforDVBV,now)>TimeToStartDVBV
		rcb=3
		while rcb>0
			If GetDVBVObject(DVBViewer) Then
				rcb=0
				if MuteDVBV=true then DVBViewer.osd.setmute 1
				if MinimizeDVBV=true then dvbviewer.sendcommand(16382) 'minimize
			else
				rcb=rcb+1
			end if
		wend
	loop
end sub