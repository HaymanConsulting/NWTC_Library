@ECHO OFF

@SET ARCHROOT=NWTC_Lib
@SET PROGNAME=NWTC_Library

@SET WINZIP="C:\Program Files (x86)\WinZip\WZZip"
@SET WINZIPSE="C:\Program Files (x86)\WinZip Self-Extractor\wzipse32.exe"

@IF NOT "%1"==""  GOTO DeleteOld

@ECHO 
@ECHO  The syntax for creating an archive is "Archive_Win7 <version>"
@ECHO.
@ECHO  Example:  "Archive_Win7 1.01.00"

@GOTO Done


:DeleteOld
@IF EXIST %TEMP%\ARCHTMP.zip DEL %TEMP%\ARCHTMP.zip
@IF EXIST %ARCHNAME%.exe DEL %ARCHNAME%.exe


:DoIt
@ECHO.
@ECHO ------------------------------------------
@ECHO Archiving %PROGNAME% for general distribution.
@ECHO ------------------------------------------
@ECHO.
@%WINZIP% -a -o -P %TEMP%\ARCHTMP @ArcFiles.txt
@%WINZIPSE% %TEMP%\ARCHTMP.zip -d. -y -win32 -le -overwrite -st"Unzipping %PROGNAME%" -m Disclaimer.txt
@COPY %TEMP%\ARCHTMP.exe Archive\%ARCHROOT%_v%1.exe
@DEL %TEMP%\ARCHTMP.zip, %TEMP%\ARCHTMP.exe

@ECHO.
@ECHO ---------------------------------
@ECHO Archiving %PROGNAME% for maintenance.
@ECHO ---------------------------------
@ECHO.
@%WINZIP% -a -o -P %TEMP%\ARCHTMP @ArcFiles.txt @ArcMaint.txt
@%WINZIPSE% %TEMP%\ARCHTMP.zip -d. -y -win32 -le -overwrite -st"Unzipping %PROGNAME%" -m Disclaimer.txt
@COPY %TEMP%\ARCHTMP.exe Archive\%ARCHROOT%_v%1_Maint.exe
@DEL %TEMP%\ARCHTMP.zip, %TEMP%\ARCHTMP.exe


:Done
@SET ARCHROOT=
@SET PROGNAME=
@SET WINZIP=
@SET WINZIPSE=