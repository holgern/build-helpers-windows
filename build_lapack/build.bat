@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Preparing workspace...

REM Setup path to helper bin
set ROOT_DIR="%~dp0"
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

if "!arg[0]!"=="" ( GOTO :usage )else ( set COMPILER_ROOT_DIR=!arg[0]!)

set PATH=!COMPILER_ROOT_DIR!;%PATH%;

SET OUTPUT_FILE=liblapack.7z


set OUTPUT_FILE=%OUTPUT_FILE: =%
set OUTPUT_FILE=%OUTPUT_FILE:.=%


call :housekeeping

call :printConfiguration

call :getlapack

call :buildlapack

rem call :packboost

rem call :cleanup

ENDLOCAL
exit /b


rem ========================================================================================================
:housekeeping
RD /S /Q %ROOT_DIR%\tmp_liblapack >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1
RD /S /Q %ROOT_DIR%\tmp_liblapack >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1


DEL /Q %ROOT_DIR%\lapack.tgz >nul 2>&1
DEL /Q %ROOT_DIR%\lapack.tar >nul 2>&1
GOTO :eof

rem ========================================================================================================
:cleanup
REM Cleanup temporary file/folders
cd %ROOT_DIR%
RD /S /Q %ROOT_DIR%\tmp_liblapack >nul 2>&1
DEL /Q %ROOT_DIR%\lapack.tgz >nul 2>&1
DEL /Q %ROOT_DIR%\lapack.tar >nul 2>&1
GOTO :eof

rem ========================================================================================================
:getlapack

REM Get download url.
echo Get download url...
cd %ROOT_DIR%

REM Download latest curl and rename to fltk.tar.gz
echo Downloading latest stable lapack...
%WGET% --no-check-certificate "http://netlib.org/lapack/lapack.tgz" -O lapack.tgz

IF NOT EXIST "lapack.tgz" (
	echo:
	CALL :exitB "ERROR: Could not download lapack.tgz Aborting."
	GOTO :eof
)
echo Extracting lapack.tgz ... (Please wait, this may take a while)
!SEVEN_ZIP! x lapack.tgz -y -o./
!SEVEN_ZIP! x lapack.tar -y -otmp_liblapack
IF NOT EXIST "%ROOT_DIR%\tmp_liblapack" (
	echo:
	CALL :exitB "ERROR: Could extract sources. Aborting."
	GOTO :eof
)
GOTO :eof
rem ========================================================================================================
:buildlapack
cd %ROOT_DIR%\tmp_liblapack\lapack*
set LAPACK_SRC_DIR="%CD%"
echo  LAPACK_SRC_DIR: !LAPACK_SRC_DIR!
%MKDIR% -p build_release build_debug

cd %LAPACK_SRC_DIR%\build_release
!CMAKE! -G "MinGW Makefiles" -D "CMAKE_GNUtoMS=ON" -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Relase ..
mingw32-make.exe
cd %LAPACK_SRC_DIR%\build_debug
!CMAKE! -G "MinGW Makefiles" -D "CMAKE_GNUtoMS=ON" -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Debug ..
mingw32-make.exe
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

cd %ROOT_DIR%\third-party\libboost\include\boost*
move boost ..\tmp
cd ..
%RM% -rf boost*
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
ECHO     build path_to_gcc.exe
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
echo:
echo        CMAKE: !CMAKE!
ENDLOCAL
goto :eof

rem ========================================================================================================

:: %1 an error message
:exitB
echo:
echo Error: %1
echo:
@exit /B 0
