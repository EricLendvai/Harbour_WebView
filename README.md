# Harbour WebView

Framework to create Desktop apps Using the WebView toolkit in Harbour.
Desktop apps created with this toolkit will use the user's local browser as the rendering UI engine.
From a Harbour app, you can create web pages including HTML/CSS/JavaScript and control a local instance of a browser.
Any JavaScript code can call Harbour user created functions. 
This demo also integrates jQuery, jQueryUI and Bootstrap.

Currently the project is only for under MS Windows. It requires the use of MSVC from Visual Studio 2022.
Future updates will bring this to Linux ...

Please refer to the following repo for more details about WebView: https://github.com/webview/webview

As mentioned on that repo, the WebView toolkit will:
"Create a common HTML5 UI abstraction layer for the most widely used platforms."
"Apps will use the user's local browser, Cocoa/WebKit on macOS, gtk-webkit2 on Linux and Edge on Windows 10."

## Videos:
Demo and code review video available at https://www.youtube.com/@EricLendvai

## Requirements:
- Also install the following repos and compile under MSVC in release and debug mode
  - https://github.com/EricLendvai/Harbour_EL
  - https://github.com/EricLendvai/Harbour_ORM
- Open the WebViewBinding VSCode Workspace Harbour_WebViewBinding_windows.code-workspace and follow its compilation instructions.


## Known Issues:
- Under Windows See: https://github.com/MicrosoftEdge/WebView2Feedback/issues/2290

