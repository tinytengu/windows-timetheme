@echo off
setlocal
title Time Theme Changer

goto main


:parse_time
set _time=%~1
set %~2=%_time:~0,2%
set %~3=%_time:~3,2%
set %~4=%_time:~6,2%
exit /B 0


:is_time_bigger
set _t1=%~1
set _t2=%~2
set _tequ=%~4
if "%_tequ"=="" set _tequ=0

CALL :parse_time %_t1% _h1 _m1 _s1
CALL :parse_time %_t2% _h2 _m2 _s2

rem Compare hour
if %_h1% lss %_h2% (
	set %~3=0
	exit /B 0
)
if %_h1% gtr %_h2% (
	set %~3=1
	exit /B 0
)
rem Compare minutes
if %_m1% lss %_m2% (
	set %~3=0
	exit /B 0
)
if %_m1% gtr %_m2% (
	set %~3=1
	exit /B 0
)
rem Compare seconds
if %_s1% lss %_s2% (
	set %~3=0
	exit /B 0
)
if %_s1% gtr %_s2% (
	set %~3=1
	exit /B 0
)
rem If 4th argument is 1, return 1 if time is equal
if "%_tequ%" equ "1" (
	set %~3=1
) else (
	set %~3=0
)
exit /B 0


:time_fix
set _time=%~1
if "%_time:~0,1%"==" " set %~2=0%_time:~1%
if "%_time:~1,1%"==":" set %~2=0%_time%
if "%~3"=="1" set %~2=0%_time:~0,7%
exit /B 0


:killproc
set _kpwait=%~2
if "%_kpwait%"=="" set _kpwait=0
:killproc_loop
tasklist /fi "imagename eq %~1" |find ":" > nul
if %errorlevel% neq 1 (
	if %_kpwait% equ 1 goto killproc_loop
	exit /B 0
)
taskkill /f /im %~1 > nul
exit /B 0


:halt
call :__SetErrorLevel %1
call :__ErrorExit 2> nul
goto :eof


:__ErrorExit
() 
goto :eof


:__SetErrorLevel
exit /b %time:~-2%
goto :eof


:apply_theme
if "%theme%"=="%~1" exit /B 0
set theme=%~1
set _themepath=%~2
if "%~3" equ "rel" set _themepath=C:\Windows\Resources\Themes\%~2
if not exist %_themepath% (
	echo Invalid theme path: %_themepath%
	goto halt
)
%_themepath%
CALL :time_fix %time% time_fixed 1
echo [%time_fixed%] Theme "%~1" applied
CALL :killproc systemsettings.exe 1
exit /B 0


:main
if "%1"=="/?" (
	echo Changes the Windows theme according to the current time
	echo.
	echo ttc [-lt] [-dt] [-lp] [-dp] [-path] [-delay]
	echo.
	echo Options:
	echo     -lt    Light theme time ^(HH:MM:SS^)
	echo            Default value: 08:00:00
	echo.
	echo     -dt    Dark theme time ^(HH:MM:SS^)
	echo            Default value: 16:00:00
	echo.
	echo     -lp    Light theme path
	echo            Default value: themeC.theme
	echo.
	echo     -dp    Dark theme path
	echo            Default value: dark.theme
	echo.
	echo     -path  Theme path type ^(rel or abs^)
	echo            'rel' stands for relative theme file path to 'C:\Windows\Resources\Themes' folder
	echo            so 'ttc -dp dark.theme -path rel' will point to 'C:\Windows\Resources\Themes\dark.theme'
	echo            and 'ttc -dp dark.theme -path abs' ^(or leave -path unset^) will point to '.\dark.theme'
	echo.
	echo     -delay Theme check delay ^(sec^)
	echo            Default value: 2
	echo.
	echo Example: ttc -lt 08:00:00 -dt 16:00:00
	exit /B 0
)

:args_loop
if "%1"=="-lt" set light_time=%2
if "%1"=="-dt" set dark_time=%2
if "%1"=="-lp" set light_theme=%2
if "%1"=="-dp" set dark_theme=%2
if "%1"=="-path" set path_type=%2
if "%1"=="-delay" set delay=%2

shift /1
shift /1
if not "%1"=="" goto args_loop

if "%light_time%"=="" set light_time=08:00:00
if "%dark_time%"=="" set dark_time=16:00:00
if "%light_theme%"=="" set light_theme=themeC.theme
if "%dark_theme%"=="" set dark_theme=dark.theme
if "%path_type%"=="" set path_type=rel
if "%delay%"=="" set /a delay=2

set theme=""

:main_loop
CALL :time_fix %time% time_fixed

CALL :is_time_bigger %time_fixed% %light_time% res
if %res% equ 0 (
	rem echo Less than light
	CALL :apply_theme "Dark" %dark_theme% %path_type%
	goto endtheme
)

CALL :is_time_bigger %time_fixed% %dark_time% res2 1
if %res2% equ 0 (
	rem echo Less than dark
	CALL :apply_theme "Light" %light_theme% %path_type%
	goto endtheme
)

CALL :is_time_bigger %time_fixed% %dark_time% res3 1
if "%res3%" equ "1" (
	rem echo Bigger than dark
	CALL :apply_theme "Dark" %dark_theme% %path_type%
	goto endtheme
)

:endtheme
ping 127.0.0.1 -n %delay% > nul
goto main_loop

exit /B 0
