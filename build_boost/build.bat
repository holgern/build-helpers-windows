@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Preparing workspace...

REM Setup path to helper bin
set ROOT_DIR=%~dp0
set RM="%~dp0..\bin\unxutils\rm.exe"
set CP="%~dp0..\bin\unxutils\cp.exe"
set MKDIR="%~dp0..\bin\unxutils\mkdir.exe"
set SEVEN_ZIP="%~dp0..\bin\7-zip\7za.exe"
set SED="%~dp0..\bin\unxutils\sed.exe"
set WGET="%~dp0..\bin\wget\wget.exe"
set XIDEL="%~dp0..\bin\xidel\xidel.exe"
set VSPC="%~dp0..\bin\vspc\vspc.exe"

SET arg[0]=%1
SET arg[1]=%2
SET arg[2]=%3
SET arg[3]=%4

REM Get download url.
echo Get download url...
cd %ROOT_DIR%
%XIDEL% "http://www.boost.org/" --follow "(//div[@id='downloads']/ul/li/div/a)[2]/@href" -e "//a[text()[contains(.,'7z')]]/@href" > tmp_url
set /p url=<tmp_url

if "!arg[0]!"=="" ( set LIBRARY_TYPE=all )else ( set LIBRARY_TYPE=!arg[0]!)

if "!arg[1]!"=="" ( set ADRESS_MODEL=64 )else ( set ADRESS_MODEL=!arg[1]!)
rem ... or use the DEFINED keyword now
rem if defined param1 ( set ADRESS_MODEL=%1 )
if "!arg[2]!"=="" ( set TOOL_SET=msvc )else ( set TOOL_SET=!arg[2]! )
rem ... or use the DEFINED keyword now
rem if defined param2 ( set TOOL_SET=%2 )
if "!arg[3]!"=="" ( set BOOST_URL=url )else ( set BOOST_URL=!arg[3]: =! )


echo Building with toolset=!TOOL_SET!, library-type=!LIBRARY_TYPE! and address-model=!ADRESS_MODEL! 
echo URL is !BOOST_URL!

Echo.!TOOL_SET! | findstr /C:"msvc">nul && (
    SET OUTPUT_FILE=libboost_vc%TOOL_SET:~5,2%_!ADRESS_MODEL!_!LIBRARY_TYPE!
) || (
    SET OUTPUT_FILE=libboost_!TOOL_SET!_!ADRESS_MODEL!_!LIBRARY_TYPE!
)

set OUTPUT_FILE=%OUTPUT_FILE: =%
set OUTPUT_FILE=%OUTPUT_FILE:.=%

if /i "!arg[3]!" == "--with-python" (
	if /i "!ADRESS_MODEL!" == "32" (
		SET USER_CONFIG=!ROOT_DIR!\user-config.jam
	) else (
		SET USER_CONFIG=!ROOT_DIR!\user-config64.jam
	)
)
call :housekeeping

call :printConfiguration

call :getboost

call :buildboost

call :packboost

call :cleanup

ENDLOCAL
exit /b


rem ========================================================================================================
:housekeeping
RD /S /Q %ROOT_DIR%\tmp_libboost >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1
RD /S /Q %ROOT_DIR%\tmp_libboost >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1

DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\boost.7z >nul 2>&1
GOTO :eof



rem ========================================================================================================
:getboost



REM Download latest curl and rename to fltk.tar.gz
echo Downloading latest stable boost...
%WGET% --no-check-certificate !BOOST_URL! -O boost.7z

IF NOT EXIST "boost.7z" (
	echo:
	CALL :exitB "ERROR: Could not download boost.7z. Aborting."
	GOTO :eof
)
echo Extracting boost.7z ... (Please wait, this may take a while)
!SEVEN_ZIP! x boost.7z -y -otmp_libboost
IF NOT EXIST "%ROOT_DIR%\tmp_libboost" (
	echo:
	CALL :exitB "ERROR: Could extract sources. Aborting."
	GOTO :eof
)
GOTO :eof
rem ========================================================================================================
:buildboost
cd %ROOT_DIR%\tmp_libboost\boost*
set BOOST_SRC_DIR="%CD%"

SET BOOST_JAM=!BOOST_SRC_DIR!\b2.exe

IF NOT EXIST "!BOOST_JAM!" (
	
	pushd !BOOST_SRC_DIR!
		echo:
		call bootstrap.bat
		echo:
	popd
	
	IF NOT EXIST "!BOOST_JAM!" (
		call :exitB "Failed to build Boost Jam (!BOOST_JAM!). Aborting."
	) else (
		echo:
		echo Build Boost Jam: !BOOST_JAM!
		echo:
	)
) else (
	echo:
	echo Using Boost Jam: !BOOST_JAM!
	echo:
)
%MKDIR% -p !ROOT_DIR!\third-party
%MKDIR% -p !ROOT_DIR!\third-party\libboost

if /i "!arg[3]!" == "--with-python" (
	if /i "%LIBRARY_TYPE%" == "all" (
		!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=static,shared threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost ---user-config=%USER_CONFIG% --with-python --abbreviate-paths --stagedir=./stage

	) else if /i "%LIBRARY_TYPE%" == "static" (
		!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=static threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost --user-config=%USER_CONFIG% --with-python --abbreviate-paths --stagedir=./stage

	) else if /i "%LIBRARY_TYPE%" == "shared" (
		!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=shared threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost --user-config=%USER_CONFIG% --with-python --abbreviate-paths --stagedir=./stage

	) else (
		goto usage
	)
) else (
	if /i "%LIBRARY_TYPE%" == "all" (
			!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=static,shared threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost --without-python --abbreviate-paths --stagedir=./stage

	) else if /i "%LIBRARY_TYPE%" == "static" (
			!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=static threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost --without-python --abbreviate-paths --stagedir=./stage

	) else if /i "%LIBRARY_TYPE%" == "shared" (
			!BOOST_JAM! install toolset=%TOOL_SET% variant=release,debug link=shared threading=multi address-model=%ADRESS_MODEL% --prefix=!ROOT_DIR!\third-party\libboost --without-python --abbreviate-paths --stagedir=./stage

	) else (
		goto usage
	)
) 
GOTO :eof
rem ========================================================================================================
:packboost
REM copy files
echo Copying output files...

if /i "%LIBRARY_TYPE%" == "all" (
	cd %ROOT_DIR%\third-party\libboost\stage\lib
	%MKDIR% -p lib-release lib-debug dll-release dll-debug
	move lib*-mt-gd* lib-debug
	move lib* lib-release
	move *-mt-gd* dll-debug
	move *-mt-* dll-release
)
IF NOT EXIST "%ROOT_DIR%\third-party\libboost\include" (
	echo:
	CALL :exitB "ERROR: %ROOT_DIR%\third-party\libboost\include does not exists . Aborting."
	GOTO :eof
)

cd %ROOT_DIR%\third-party\libboost\include\boost*
IF NOT EXIST "%CD%\boost" (
	echo:
	CALL :exitB "ERROR: %CD%\boost does not exists . Aborting."
	GOTO :eof
)
move boost ..\tmp
cd ..

SET p=%CD%
SET a=boost
for /D %%x in (%a%*) do if not defined f set "f=%%x"
SET pa=%p%\%f%
echo %pa%
RMDIR %pa% /S /Q
rem %RM% -rf  boost*
ren tmp boost

cd %ROOT_DIR%\third-party
!SEVEN_ZIP! a -t7z ../../!OUTPUT_FILE!  libboost
GOTO :eof
rem ========================================================================================================
:cleanup
REM Cleanup temporary file/folders
cd %ROOT_DIR%
RD /S /Q %ROOT_DIR%\tmp_libboost >nul 2>&1
DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\boost.7z >nul 2>&1
GOTO :eof
rem ========================================================================================================
:usage
rem call :printConfiguration
ECHO: 
ECHO Error in script usage. The correct usage is:
ECHO:
ECHO     build [all^|shared^|static] - build 32 bit with msvc without python
ECHO     build [all^|shared^|static] [32^|64] compiler - build boost without python
ECHO     build [all^|shared^|static] [32^|64] compiler --with-python - build boost with python
ECHO:    
GOTO :eof
rem ========================================================================================================
:printConfiguration
SETLOCAL EnableExtensions EnableDelayedExpansion

echo:
echo                    ROOT_DIR: !ROOT_DIR!
echo:

echo              OUTPUT_FILE: !OUTPUT_FILE!
echo:
echo        SEVEN_ZIP: !SEVEN_ZIP!
echo:
echo           WGET: !WGET!
ENDLOCAL
goto :eof

rem ========================================================================================================

:: %1 an error message
:exitB
echo:
echo Error: %1
echo:
@exit /B 0
