@echo off

:: Requires
:: https://repo.msys2.org/distrib/x86_64/msys2-x86_64-20250221.exe

windres resource.rc -O coff -o resource.o
g++ main.cpp resource.o -o devbox.exe -mwindows
