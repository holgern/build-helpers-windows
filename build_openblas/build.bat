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
set WGET="%~dp0..\bin\unxutils\wget.exe"
set XIDEL="%~dp0..\bin\xidel\xidel.exe"
set VSPC="%~dp0..\bin\vspc\vspc.exe"
SET CMAKE="%~dp0..\bin\cmake\bin\cmake.exe"

SET arg[0]=%1
SET arg[1]=%2
SET arg[2]=%3
SET arg[3]=%4

if "!arg[0]!"=="" ( set LIBRARY_TYPE=all )else ( set LIBRARY_TYPE=!arg[0]!)

if "!arg[1]!"=="" ( set ADRESS_MODEL=64 )else ( set ADRESS_MODEL=!arg[1]!)
rem ... or use the DEFINED keyword now
rem if defined param1 ( set ADRESS_MODEL=%1 )
if "!arg[2]!"=="" ( set TOOL_SET=msvc )else ( set TOOL_SET=!arg[2]! )
rem ... or use the DEFINED keyword now
rem if defined param2 ( set TOOL_SET=%2 )

echo Building with toolset=!TOOL_SET!, library-type=!LIBRARY_TYPE! and address-model=!ADRESS_MODEL! 

Echo.!TOOL_SET! | findstr /C:"msvc">nul && (
    SET OUTPUT_FILE=openblas_vc%TOOL_SET:~5,2%_!ADRESS_MODEL!_!LIBRARY_TYPE!
) || (
    SET OUTPUT_FILE=openblas_!TOOL_SET!_!ADRESS_MODEL!_!LIBRARY_TYPE!
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

rem call :printConfiguration

call :getopenblas

call :buildopenblas

rem call :packboost

rem call :cleanup

ENDLOCAL
exit /b


rem ========================================================================================================
:housekeeping
RD /S /Q %ROOT_DIR%\tmp_openblas >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1
RD /S /Q %ROOT_DIR%\tmp_openblas >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1

DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\openblas.zip >nul 2>&1
GOTO :eof

rem ========================================================================================================
:cleanup
REM Cleanup temporary file/folders
cd %ROOT_DIR%
RD /S /Q %ROOT_DIR%\tmp_openblas >nul 2>&1
DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\openblas.zip >nul 2>&1
GOTO :eof

rem ========================================================================================================
:getopenblas

REM Get download url.
echo Get download url...
cd %ROOT_DIR%
%XIDEL% "https://github.com/xianyi/OpenBLAS/releases"  -e  "//a[text()[contains(.,'zip')]]/@href"[1] > tmp_url

set /p url=<tmp_url

REM Download latest curl and rename to fltk.tar.gz
echo Downloading latest stable openblas...
%WGET% --no-check-certificate "https://github.com%url%" -O openblas.zip

IF NOT EXIST "openblas.zip" (
	echo:
	CALL :exitB "ERROR: Could not download openblas.zip. Aborting."
	GOTO :eof
)
echo Extracting openblas.zip ... (Please wait, this may take a while)
!SEVEN_ZIP! x openblas.zip -y -otmp_openblas
IF NOT EXIST "%ROOT_DIR%\tmp_openblas" (
	echo:
	CALL :exitB "ERROR: Could extract sources. Aborting."
	GOTO :eof
)
GOTO :eof
rem ========================================================================================================
:buildopenblas
cd %ROOT_DIR%\tmp_openblas\OpenBLAS-*
set OPENBLAS_SRC_DIR="%CD%"

echo  OPENBLAS_SRC_DIR: !OPENBLAS_SRC_DIR!
%MKDIR% -p build_release build_debug

cd %OPENBLAS_SRC_DIR%\build_release
!CMAKE! -G "MinGW Makefiles" -D "CMAKE_GNUtoMS=ON"  -DBUILD_WITHOUT_CBLAS=ON -DBUILD_DEBUG=OFF ..
mingw32-make.exe
cd %OPENBLAS_SRC_DIR%\build_debug
!CMAKE! -G "MinGW Makefiles" -D "CMAKE_GNUtoMS=ON" -DBUILD_WITHOUT_CBLAS=ON -DBUILD_DEBUG=ON ..
mingw32-make.exe

)
GOTO :eof
rem ========================================================================================================
:packopenblas
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
