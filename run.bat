@echo off 

cls

ml /c program.asm
if errorlevel 1 goto error

link program.obj

if errorlevel 1 goto error

:error

