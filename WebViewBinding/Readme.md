## WebViewBinding

### Goal
This workspace will create a 64 bit DLL to be used from Harbour programs, that will include the webview library from https://github.com/webview/webview and functions to be called from Harbour PRGs.

### Current Status
- Currently only functional under MS Windows.

### Requirements
- MSVC (C and CPP) and cmake from Visual Studio 2022.

### Build Instructions
- Execute the "Configure Build Folder" task (configure.bat) initially (will create the build folder), then execute "Compile Release" task (build.bat).
