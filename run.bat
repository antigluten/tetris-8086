@echo off 

cls

ml /Zi /Fl /c program.asm
if errorlevel 1 goto error

link /codeview program.obj;

if errorlevel 1 goto error

program

:error

