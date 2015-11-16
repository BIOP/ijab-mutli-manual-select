@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

REM Set name of ActionBar
set actionBarName=BIOP_MultiManual_Select
set biopPath=C:\Fiji.app\plugins\BIOP\

copy C:\Fiji.app\plugins\ActionBar\%actionBarName%.ijm


ECHO Packing ActionBar: "%actionBarName%"

set finalName=%actionBarName%.jar

echo Final Name: "%finalName%"

REM Create JAR File
ECHO Creating JAR File
jar cf %finalName% plugins.config icons *.ijm
ECHO Done.

REM Copy Back
copy %finalName% %biopPath%%finalName%

PAUSE