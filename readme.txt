DVBViewer EPG Update Script
http://www.dvbviewer.tv/forum/topic/41624-epg-update-script/

[Deutsch]
Der DVBViewer Pro bietet von sich aus keine Möglichkeit, um das EPG aller Sender
automatisch zu aktualisieren. Das Recording Service bietet eine solche
Funktion, diese ist aber nur rudimentär konfigurier- und steuerbar.

Das Script ist über ini-Dateien konfigurierbar und erlaubt auch unterschiedliche
Einstellungen auf Basis des Wochentags - dies kann beispielsweise genutzt werden,
um an Arbeitstagen nur das EPG der favorisierten Sender zu aktualisieren und zum
Wochenende das EPG aller empfangbaren Sender.

Die Standardeinstellungen sind so gewählt, dass das EPG aller Sender aktualisiert
wird und dass die dafür benötigte Zeit möglichst kurz ist. Da das EPG nicht pro
Sender sondern pro Transponder (Frequenz) übertragen wird, wird pro Transponder
auch nur ein Sender aktiviert.

Das Script unterstützt den Empfang zusätzlicher EPG-Daten (MediaHighway etc.)
und die Aktualisierung des Recording Service EPG, sofern dies im DVBViewer
konfiguriert ist. Wenn eine Aufnahme ansteht oder ein manueller Sender-
wechsel erkannt wird, beendet sich das Script von selbst.

Details zu den Konfigurationsmöglichkeiten finden sich in der Datei "sample.ini".

Das Script wird von der Eingabeaufforderung aus gestartet und erwartet die Angabe
einer ini-Datei: "cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini".

Standardmässig werden alle Meldungen des Script in der Datei
"DVBViewer-EPG-Update.log" protokolliert.

Es ist möglich, dass das Script pro Satellit mehr Transponder durchschaltet,
als es dort eigentlich gibt. Es handelt sich dabei nicht um einen Fehler des Scripts,
tatsächlich werden die Abweichungen von LNBs, Multischaltern, Receivern, Import von
vorbereiteten Transponder- und Senderlisten und manchmal auch Sendersuchläufen mit
speziellen Optionen (zB Blindscan oder detaillierte Suche) verursacht.



[English]
DVBViewer Pro does not offer a way to automatically update the EPG of all
channels. The Recording Service has such an option, but this is hardly configur-
and steerable.

The script is configurable via ini files and allows for different configurations
based on the weekday the script is run - for example, this can be used to update
the EPG of only your favourite channels during workdays and for all channels at
the weekend.

The default settings are chosen so that the EPG of all channels is updated while
keeping the time needed for this process as short as possible. As EPG data is not
sent per channel but per transponder (frequency), only one channel per transponder
is tuned.

The script supports receiving additional EPG data (MediaHighway etc.) and
updating the Recording Service EPG if this is configured in DVBViewer. When a
recording is about to start or a channel is changed manually, the script ends
automatically.

Details regarding the configuration options can be found in the file "sample.ini".

The script is started via the command prompt and expects the path to an ini file
as parameter: "cscript.exe DVBViewer-EPG-Update.vbs /ini:sample.ini".

Per default, all script messages are logged in the file "DVBViewer-EPG-Update.log".

It is possible that the script tunes more transponders per satellite as should exist
there. This is not a problem within the script, the deviances are caused by LNBs,
multiswitches, receivers, import of prepared transponder and channel lists and some-
times also because of channel scans with special options (e.g. blind scan or detailed
search).