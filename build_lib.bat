@echo off
setlocal EnableDelayedExpansion 

echo Preparing workspace...

REM Setup path to helper bin
set ROOT_DIR="%CD%"
set RM="%CD%\bin\unxutils\rm.exe"
set CP="%CD%\bin\unxutils\cp.exe"
set MKDIR="%CD%\bin\unxutils\mkdir.exe"
set SEVEN_ZIP="%CD%\bin\7-zip\7za.exe"
set SED="%CD%\bin\unxutils\sed.exe"
set WGET="%CD%\bin\unxutils\wget.exe"
set XIDEL="%CD%\bin\xidel\xidel.exe"
set VSPC="%CD%\bin\vspc\vspc.exe"

set "param1=%1"
set "param2=%2"
if "!param1!"=="" ( set ADRESSMODEL=64 )
rem ... or use the DEFINED keyword now
if defined param1 ( set ADRESSMODEL=%1 )
if "!param2!"=="" ( set TOOLSET=msvc )
rem ... or use the DEFINED keyword now
if defined param2 ( set TOOLSET=%2 )


REM Housekeeping

RD /S /Q %ROOT_DIR%\tmp_libboost >nul 2>&1
RD /S /Q %ROOT_DIR%\third-party >nul 2>&1
DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\boost.7z >nul 2>&1
DEL /Q %ROOT_DIR%\libboost.7z >nul 2>&1

REM Get download url.
echo Get download url...
%XIDEL% "http://www.boost.org/" --follow "(//div[@id='downloads']/ul/li/div/a)[3]/@href" -e "//a[text()[contains(.,'7z')]]/@href" > tmp_url

set /p url=<tmp_url

REM Download latest curl and rename to fltk.tar.gz
echo Downloading latest stable boost...
%WGET% "%url%" -O boost.7z

echo Extracting boost.7z ... (Please wait, this may take a while)
%SEVEN_ZIP% x boost.7z -y -otmp_libboost | FIND /V "ing  " | FIND /V "Igor Pavlov"

cd %ROOT_DIR%\tmp_libboost\boost*
CALL bootstrap.bat
b2 install toolset=%TOOLSET% variant=release,debug link=static threading=multi address-model=%ADRESSMODEL% --prefix=%ROOT_DIR%\third-party\libboost --without-python --stagedir=./stage

REM copy files
REM echo Copying output files...
REM cd %ROOT_DIR%\third-party\libboost\stage\lib
REM %MKDIR% -p lib-release lib-debug
REM move lib*-mt-gd* lib-debug
REM move lib* lib-release


cd %ROOT_DIR%\third-party\libboost\include\boost*
move boost ..\tmp
cd ..
%RM% -rf boost*
ren tmp boost

cd %ROOT_DIR%\third-party
%SEVEN_ZIP% a -t7z ../libboost.7z  libboost

REM Cleanup temporary file/folders
cd %ROOT_DIR%
RD /S /Q %ROOT_DIR%\tmp_libboost >nul 2>&1
DEL /Q %ROOT_DIR%\tmp_url >nul 2>&1
DEL /Q %ROOT_DIR%\boost.7z >nul 2>&1

exit /b
