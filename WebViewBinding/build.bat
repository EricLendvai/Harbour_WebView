@echo off

call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_amd64

rem cmake --build build/debug --target install
rem cmake --build build/debug

rem cmake --build build/release --target install
rem cmake --build build/release

cmake --build build/win64/msvc64/release

echo Build completed
