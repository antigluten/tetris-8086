@echo off 

set name=program

cls

ml /Zi /Fl /c %name%.asm
if errorlevel 1 goto error

link /codeview %name%.obj;

if errorlevel 1 goto error

IF "%1%"=="1" goto debug

goto run

:debug
cv %name%
goto end

:run
%name%

:error
:end
