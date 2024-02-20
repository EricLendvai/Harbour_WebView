//Copyright (c) 2024 Eric Lendvai, Federal Way, WA, USA, MIT License

// IMPORTANT NOTE:
// Wherever the WebViewDemo.exe is generated, also place webview.dll (659 Kb) and WebView2Loader.dll (418 Kb) ? not really it seems Left

// Harbour Multithreading info
// http://harbourlanguage.blogspot.com/2010/04/harbour-multi-thread.html

//RND Notes:
//==========

// - Allow a dynamic list of Window Numbers.
// - Calling Hello World will crash. The problem is that we need the windowsnumber to be able to write to it, since we can not get the thread info
// It seems we can only call a JS in a Window inside its own tread. But we need threads to have more than one window.
// Debugger crashes when a window is closed using the close button, not if forcing a window close (right corner).

// Static variables only work in a single PRG. This was the reason to use private variables instead, see: hb_threadStart(HB_THREAD_INHERIT_PRIVATE ....
//=================================================================================================================

#include "WebViewDemo.ch"

Function Main()

local l_cInitialHtml
local l_aQueue
local l_cAction
local l_xCargo
local l_lContinue := .t.
local l_pWebServerThread
local l_nInternalWebServerPort := INTERNAL_WEBSERVER_LOCALHOST_PORT  // Any unused port will work.
local l_hLib
local l_aControlWindowPositionAndSize

private v_hConfig        := {=>}
private v_oQueue         := Queue()  //:init()
private v_oWindowManager

MyOutputDebugString("[Harbour] Starting Harbour WebServer")

v_hConfig["SitePath"] := "http://localhost:"+Alltrim(str(l_nInternalWebServerPort))+"/"

v_hConfig["HtmlMessageDiv"] := [<div id="MessageFromHarbour" class="m-3"></div>]

v_hConfig["ApplicationVersion"]    := BUILDVERSION
v_hConfig["ApplicationBuildInfo"]  := hb_buildinfo()
v_hConfig["SetupFolder"]           := hb_cwd()+"setup"+hb_ps()
v_hConfig["WebSiteRootFolder"]     := hb_cwd()+"files"+hb_ps()
v_hConfig["WindowTaxBarIcon"]      := hb_cwd()+"files"+hb_ps()+"favicon.ico"

v_hConfig["hb_webview_dll_Folder"] := hb_cwd()+"WebViewBinding\build\win64\msvc64\release\"    // Will need to be updated for distribution and Operating system

v_oWindowManager := WindowManager():new()  // Creating the object after some v_hConfig are set.

l_pWebServerThread := hb_threadStart(@WebServerThread(),"127.0.0.1",l_nInternalWebServerPort,v_hConfig["WebSiteRootFolder"])
//hb_threadWait(l_pWebServerThread)

MyOutputDebugString("[Harbour] Starting WebViewDemo")

// ?"hb_mtvm()",hb_mtvm()
// ?"Main Thread ID=" , hb_threadId( hb_threadSelf() )

set exact on
set century on
set delete on

l_hLib := hb_libLoad( v_hConfig["hb_webview_dll_Folder"]+"hb_webview.dll" )

if empty( l_hLib )
    ?"Failed to Load WebView Binding library"
    ? hb_libError(l_hLib)
else
    v_hConfig["hLib"] := l_hLib

    //? "WebView Binding Version: ",hb_DynCall( { "WebViewBindingVersion", l_hLib, HB_DYN_CTYPE_LONG} )

    hb_DynCall( { "SetCallBackFunctionToJSToHarbour", l_hLib, HB_DYN_CTYPE_LONG},Get_wv_JSToHarbour_As_Pointer() )

    v_hConfig["ControlWindowNumber"] := CreateControlWindow()

    // v_oWindowManager:ListAll()

    // Created a messaging system to deal with the lack of threading on threads using webviews
    // It seems only the main thread can create windows when WebViews are being used.

    do while l_lContinue
        hb_IdleSleep(0.5)
        do while .t.
            l_aQueue := v_oQueue:pop()
            if hb_IsNil(l_aQueue)
                exit
            else
                l_cAction := l_aQueue[1]
                l_xCargo  := l_aQueue[2]

                do case
                case l_cAction == "CallFunction"
                    l_xCargo:Exec()

                case l_cAction == "CreateWindow"
                    do case
                    case l_xCargo == "OpenGoogle"
                        l_aControlWindowPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(v_hConfig["ControlWindowNumber"])
                        v_oWindowManager:CreateWindow(,;
                                                      "Google",;
                                                      l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_TOP]+30,;
                                                      l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT]+30,;
                                                      800,;
                                                      600,;
                                                      v_hConfig["WindowTaxBarIcon"],"URL",,"https://www.google.com")
                    endcase 
                case l_cAction == "Quit"
                    l_lContinue := .f.
                    MyOutputDebugString("[Harbour] Requested to Quit")
                    exit
                    // MyOutputDebugString("[Harbour] Requested to Quit Step 1")
                    //                 hb_threadTerminateAll()
                    // MyOutputDebugString("[Harbour] Requested to Quit Step 2")
                endcase
            endif

        enddo
        if __vmCountThreads() == 1  //Only main thread exists
            exit
        endif
    enddo

    // if l_lContinue
    //     v_oWindowManager:ListAll()
    //     inkey(5)
    // endif

    hb_libFree( l_hLib )
endif

hb_threadQuitRequest(l_pWebServerThread)

MyOutputDebugString("[Harbour] Completed WebViewDemo")

return nil
//=================================================================================================================
function JSToHarbour( par_cCallCounter, par_cJSParameter ,par_nWindowNumber)
local l_nPos
local l_cAction
local l_hNameValues
local l_cEntryValue
local l_cNameValue
local l_cName
local l_cValue

local l_oController
local l_hLib := v_hConfig["hLib"]

// MyOutputDebugString("[Harbour] From JSToHarbour, nThID -> "+AllTrim(Str(hb_threadId( hb_threadSelf() ))))

l_oController := v_oWindowManager:GetController(par_nWindowNumber)

do case
case "Quit" $ par_cJSParameter
    v_oQueue:push("Quit",nil)

case !hb_IsNil(l_oController)
    l_oController:nWindowNumber := par_nWindowNumber

    l_nPos := at("^",par_cJSParameter)
    if l_nPos > 0
        l_cAction     := substr(par_cJSParameter,3,l_nPos-3)
        l_cEntryValue := substr(par_cJSParameter,l_nPos+1,len(par_cJSParameter)-l_nPos-2)
    else
        l_cAction     := substr(par_cJSParameter,3,len(par_cJSParameter)-4)
        l_cEntryValue := ""
    endif

    l_hNameValues := {=>}

    for each l_cNameValue in hb_ATokens(l_cEntryValue,"&")
        // MyOutputDebugString("[Harbour] l_cNameValue: ~"+l_cNameValue+"~")
        l_nPos := at("=",l_cNameValue)
        if l_nPos > 0
            l_cName  := left(l_cNameValue,l_nPos-1)
            l_cValue := URLDecode(substr(l_cNameValue,l_nPos+1))
            l_hNameValues[l_cName] := l_cValue

        endif
    endfor

    l_oController:Controller(par_cCallCounter,l_cAction,l_hNameValues)

endcase

return nil
//=================================================================================================================
function GetWebPageHeader(par_cExtraHtml)  // Generic header used by all windows to ensure jQuery, jQuery UI and Bootstrap are running.
local l_cHtml

l_cHtml := [<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">]

// l_cHtml += [<link rel="icon" href="]+v_hConfig["SitePath"]+[favicon_Blocks_002.ico" type="image/x-icon">]
l_cHtml += [<link rel="stylesheet" type="text/css" href="]+v_hConfig["SitePath"]+[Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/css/bootstrap.min.css">]
l_cHtml += [<link rel="stylesheet" type="text/css" href="]+v_hConfig["SitePath"]+[Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/icons/font/bootstrap-icons.css">]
l_cHtml += [<link rel="stylesheet" type="text/css" href="]+v_hConfig["SitePath"]+[jQueryUI_]+JQUERYUI_SCRIPT_VERSION+[/Themes/smoothness/jQueryUI.css">]
l_cHtml += [<script language="javascript" type="text/javascript" src="]+v_hConfig["SitePath"]+[jQuery_]+JQUERY_SCRIPT_VERSION+[/jquery.min.js"></script>]
l_cHtml += [<script language="javascript" type="text/javascript" src="]+v_hConfig["SitePath"]+[Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/js/bootstrap.bundle.min.js"></script>]
l_cHtml += [<script language="javascript" type="text/javascript" src="]+v_hConfig["SitePath"]+[jQueryUI_]+JQUERYUI_SCRIPT_VERSION+[/jquery-ui.min.js"></script>]

if pcount() >= 1 .and. !hb_IsNil(par_cExtraHtml)
    l_cHtml += par_cExtraHtml
endif

l_cHtml += [</head>]

return l_cHtml
//=================================================================================================================
class Queue

hidden:
data aQueue init {}

exported:

SYNC method push(par_cAction,par_xCargo)
SYNC method pop()

endclass 
//========================================================
method push(par_cAction,par_xCargo) class Queue
return AAdd( ::aQueue, {par_cAction,par_xCargo} ) 
//========================================================
method pop() class Queue
local l_xValue := nil

if Len(::aQueue) > 0 
    l_xValue := ::aQueue[1] 
    ADel ( ::aQueue, 1 ) 
    ASize( ::aQueue, Len(::aQueue)-1 ) 
endif

return l_xValue 
//=================================================================================================================
class WindowManager
hidden:

data AppConfig init {=>}   // Will be set to case insensitive keys
data hWindows  init {=>}   // :hWindows[<nWindowNumber>] := {par_pThId,par_oController,par_cTitle}
data hThreads  init {=>}   // :hThreads[<nThreadID>]     := <nWindowNumber>

exported:
method new() constructor
SYNC method CreateWindow(par_oController,par_cTitle,par_nTop,par_nLeft,par_nWidth,par_nHeight,par_cIconPath,par_cMode,par_cHtml,par_cURL,par_cJS)
SYNC method TerminateWindow(par_nWindowNumber)
SYNC method ChangeTitle(par_nWindowNumber,par_cTitle)
SYNC method Get(par_nWindowNumber,par_pThId,par_cTitle)
SYNC method GetWindowNumberByWindowTitle(par_cTitle)
SYNC method GetWindowNumberByThreadID(par_pThId)
SYNC method ListAll()   // Used while developing Harbour Binding.
SYNC method GetWindowList()
method GetWindowPositionAndSize(par_nWindowNumber)   // Returns an array {top,left,width,height}

method MoveWindow(par_nWindowNumber,par_nTop,par_nLeft,par_nWidth,par_nHeight)
method RunJS(par_nWindowNumber,par_cJS)

SYNC method RegisterWindow(par_nWindowNumber,par_pThId,par_oController,par_cTitle)   // Used Internally From the newly created threads
SYNC method UnRegisterWindow(par_nWindowNumber)  // User Internal
method GetController(par_nWindowNumber)   // Used Internally

method LoadAppConfig()
method GetAppConfig(par_cName)
method SetAppConfig(par_cName,par_cValue)
method SaveAppConfig()

endclass
//========================================================
method new() class WindowManager
hb_HCaseMatch(::AppConfig,.f.)
::LoadAppConfig()
return self
//========================================================
//========================================================
method LoadAppConfig() class WindowManager
local l_cConfigText
local l_cLine
local l_nPos
local l_cName
local l_cValue
local l_iNumberOfConfigs := 0
local l_cPathBackend := v_hConfig["SetupFolder"]
//The configuration file is purposely not with a .txt extension to block users from accessing it.
l_cConfigText := hb_MemoRead(l_cPathBackend+"config.txt")
l_cConfigText := StrTran(StrTran(l_cConfigText,chr(13)+chr(10),chr(10)),chr(13),chr(10))
for each l_cLine in hb_ATokens(l_cConfigText,chr(10),.f.,.f.)
    l_nPos := at("=",l_cLine)
    if l_nPos > 1  //Name may not be empty
        l_cName := left(l_cLine,l_nPos-1)
        l_cLine := substr(l_cLine,l_nPos+1)
        l_nPos := rat(" //",l_cLine)    // To ensure the "//" comment marker is not part of a config value, it must be preceded with at least one blank.
        if empty(l_nPos)
            l_cValue := allt(l_cLine)
        else
            l_cValue := allt(left(l_cLine,l_nPos-1))
        endif
        if left(l_cValue,2) == "${" .and. right(l_cValue,1) == "}" // The value is making a reference to an environment variable
            l_cValue := hb_GetEnv(substr(l_cValue,3,len(l_cValue)-3),"")
        endif
        ::AppConfig[l_cName] := l_cValue
        l_iNumberOfConfigs++
    endif
endfor
return l_iNumberOfConfigs
//========================================================
method GetAppConfig(par_cName) class WindowManager
return alltrim(hb_HGetDef(::AppConfig, par_cName, ""))
//========================================================
method SetAppConfig(par_cName,par_cValue) class WindowManager
::AppConfig[par_cName] := alltrim(par_cValue)
return nil
//========================================================
//========================================================
method SaveAppConfig() class WindowManager
local l_cConfigText
local l_cValue
local l_cName
local l_cPathBackend := v_hConfig["SetupFolder"]
//The configuration file is purposely not with a .txt extension to block users from accessing it.

l_cConfigText := ""

for each l_cValue in ::AppConfig
    l_cName := l_cValue:__enumkey
    l_cConfigText += l_cName+[=]+l_cValue+CRLF
endfor

hb_MemoWrit(l_cPathBackend+"config.txt",l_cConfigText)

return nil
//========================================================
method CreateWindow(par_oController,par_cTitle,par_nTop,par_nLeft,par_nWidth,par_nHeight,par_cIconPath,par_cMode,par_cHtml,par_cURL,par_cJS) class WindowManager   // par_cMode = "HTML" or "URL"
// static l_nWindowNumber := 0
local l_nWindowNumber
local l_hLib := v_hConfig["hLib"]

//Check if window is not already existing and switch to it instead
l_nWindowNumber := v_oWindowManager:GetWindowNumberByWindowTitle(par_cTitle)

if l_nWindowNumber == -1  // Window does not exists yet, we will create it.
    l_nWindowNumber := hb_DynCall( { "GetWindowNumber", l_hLib, HB_DYN_CTYPE_LONG} )

    if l_nWindowNumber > 0
        if !hb_IsNil(par_oController)
            par_oController:nWindowNumber := l_nWindowNumber
        endif
        hb_threadStart(HB_THREAD_INHERIT_PRIVATE,@CreateWebViewWindowAndThread(),l_nWindowNumber,par_oController,par_cTitle,par_nTop,par_nLeft,par_nWidth,par_nHeight,par_cIconPath,par_cMode,par_cHtml,par_cURL,par_cJS)
    else
        MyOutputDebugString("[Harbour] No available WindowNumber")
    endif
else
    hb_DynCall( { "BringWebViewWindowForeground", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber )
endif

return l_nWindowNumber
//========================================================
method TerminateWindow(par_nWindowNumber) class WindowManager
local l_hLib := v_hConfig["hLib"]
hb_DynCall( { "Terminate", l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber )
return nil
//========================================================
method RegisterWindow(par_nWindowNumber,par_pThId,par_oController,par_cTitle) class WindowManager
local l_nThreadID

l_nThreadID := hb_threadId(par_pThId)
::hThreads[l_nThreadID] := par_nWindowNumber
::hWindows[par_nWindowNumber] := {par_pThId,par_oController,par_cTitle}

return {par_pThId,par_cTitle}
//========================================================
method ChangeTitle(par_nWindowNumber,par_cTitle) class WindowManager  // Use the Windows Number or Thread ID
local l_hLib := v_hConfig["hLib"]
local l_nWindowNumber
local l_aWindowInfo
local l_lResult

l_aWindowInfo := hb_HGetDef(::hWindows,par_nWindowNumber,{})
if len(l_aWindowInfo) > 0
    l_aWindowInfo[3] := par_cTitle
    ::hWindows[par_nWindowNumber] := AClone(l_aWindowInfo)
    hb_DynCall( { "SetWindowTitle", l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber,par_cTitle )
    l_lResult := .t.
else
    l_lResult := .f.
endif

return l_lResult
//========================================================
method UnRegisterWindow(par_nWindowNumber) class WindowManager
local l_aWindowInfo
local l_nThreadID

if !hb_IsNil(par_nWindowNumber)

    l_aWindowInfo := ::hWindows[par_nWindowNumber]
    l_nThreadID   := hb_threadId(l_aWindowInfo[1])
    hb_HDel(::hWindows,par_nWindowNumber)
    hb_HDel(::hThreads,l_nThreadID)

endif

return nil
//========================================================
method GetController(par_nWindowNumber) class WindowManager
local l_oController := nil
local l_aWindowInfo

if par_nWindowNumber >= 0
    l_aWindowInfo := ::hWindows[par_nWindowNumber]
    l_oController := l_aWindowInfo[2]
endif

return l_oController
//========================================================
method Get(par_nWindowNumber,par_pThId,par_cTitle) class WindowManager
local l_xReturn := nil
local l_nWindowNumber
local l_nThreadID
local l_aWindowInfo

//Find the l_nWindowNumber
do case
case !hb_IsNil(par_nWindowNumber)
    l_nWindowNumber := par_nWindowNumber

case !hb_IsNil(par_pThId)
    l_nThreadID      := hb_threadId(par_pThId)
    l_nWindowNumber  := ::hThreads[l_nThreadID]

case !hb_IsNil(par_cTitle)
    l_nWindowNumber := -1
    for each l_aWindowInfo in ::hWindows
        if l_aWindowInfo[2] == par_cTitle
            l_nWindowNumber := l_aWindowInfo:__enumkey
            exit
        endif
    endfor

endcase

if l_nWindowNumber >= 0 //.and. l_nWindowNumber <= len(::hWindows)
    l_aWindowInfo := ::hWindows[l_nWindowNumber]
    l_xReturn := AClone(l_aWindowInfo)
endif

return l_xReturn
//========================================================
method GetWindowNumberByWindowTitle(par_cTitle) class WindowManager
local l_nWindowNumber := -1
local l_aWindowInfo

for each l_aWindowInfo in ::hWindows
    if l_aWindowInfo[3] == par_cTitle
        l_nWindowNumber := l_aWindowInfo:__enumkey
        exit
    endif
endfor

return l_nWindowNumber
//========================================================
method GetWindowNumberByThreadID(par_pThId) class WindowManager
local l_nWindowNumber
local l_nThreadID

if !hb_IsNil(par_pThId)
    l_nThreadID      := hb_threadId(par_pThId)
    l_nWindowNumber  := ::hThreads[l_nThreadID]
else
    l_nWindowNumber := -1
endif

return l_nWindowNumber
//========================================================
method ListAll() class WindowManager
local l_aWindowInfo
local l_nWindowNumber

for each l_aWindowInfo in ::hWindows
    l_nWindowNumber := l_aWindowInfo:__enumkey
    ?l_nWindowNumber,l_aWindowInfo[1],l_aWindowInfo[2]
endfor

return nil
//========================================================
method GetWindowList() class WindowManager
local l_xReturn
local l_aWindowInfo
local l_nWindowNumber

l_xReturn := {}
for each l_aWindowInfo in ::hWindows
    l_nWindowNumber := l_aWindowInfo:__enumkey
    AAdd(l_xReturn,{l_nWindowNumber,l_aWindowInfo[1],l_aWindowInfo[3]})
endfor

return l_xReturn
//========================================================
method MoveWindow(par_nWindowNumber,par_nTop,par_nLeft,par_nWidth,par_nHeight) class WindowManager
hb_DynCall( { "MoveWebViewWindow", v_hConfig["hLib"], HB_DYN_CTYPE_LONG},par_nWindowNumber,par_nTop,par_nLeft,par_nWidth,par_nHeight )
return nil
//========================================================
method RunJS(par_nWindowNumber,par_cJS) class WindowManager
hb_DynCall( { "RunJS", v_hConfig["hLib"], HB_DYN_CTYPE_LONG},par_nWindowNumber,par_cJS )   // Due to threads I suppose, can not run JS code in a windows not owned by the thread.
return nil
//========================================================
method GetWindowPositionAndSize(par_nWindowNumber) class WindowManager
local l_hLib := v_hConfig["hLib"]
local l_nTop    := -1
local l_nLeft   := -1
local l_nWidth  := -1
local l_nHeight := -1

l_nTop    := hb_DynCall( { "GetWebViewWindowPositionTop" , l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber )
l_nLeft   := hb_DynCall( { "GetWebViewWindowPositionLeft", l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber )
l_nWidth  := hb_DynCall( { "GetWebViewWindowSizeWidth"   , l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber )
l_nHeight := hb_DynCall( { "GetWebViewWindowSizeHeight"  , l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber )

return {l_nTop,l_nLeft,l_nWidth,l_nHeight}
//========================================================
//=================================================================================================================
static function CreateWebViewWindowAndThread(par_nWindowNumber,par_oController,par_cTitle,par_nTop,par_nLeft,par_nWidth,par_nHeight,par_cIconPath,par_cMode,par_cHtml,par_cURL,par_cJS)
local l_hLib := v_hConfig["hLib"]
local l_nWindowNumber
local l_nTerminationType

l_nWindowNumber := hb_DynCall( { "CreateWebViewWindow", l_hLib, HB_DYN_CTYPE_LONG},par_nWindowNumber, ALLOW_DEVELOPER_TOOLS )   // Last Parameter should be 0 or 1 (par_iAllowDeveloperTools)

// ?"CreateWebViewWindowAndThread l_nWindowNumber = ",alltrim(str(l_nWindowNumber))

if l_nWindowNumber == par_nWindowNumber
    // ? "Window Number=",par_nWindowNumber,"  Thread ID=" , hb_threadId( hb_threadSelf() ),"  Thread pID=",hb_threadSelf()

    if !hb_IsNil(par_oController)
        par_oController:OnOpenWindow()
        if hb_IsNil(par_cMode)
            par_oController:BuildWindowContent()
            par_cMode := par_oController:BuildWindowContentMode
            par_cHtml := par_oController:BuildWindowContentHTML
            par_cURL  := par_oController:BuildWindowContentURL
            par_cJS   := par_oController:BuildWindowContentJS

        endif
    endif

    hb_DynCall( { "SetWindowTitle", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_cTitle )

    v_oWindowManager:RegisterWindow(par_nWindowNumber,hb_threadSelf(),par_oController,par_cTitle)

    hb_DynCall( { "SetWindowPositionAndSize", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_nTop,par_nLeft,par_nWidth,par_nHeight )

    if !hb_IsNil(par_cIconPath) .and. hb_FileExists(par_cIconPath)
        //AddWebViewWindowTaskBarIcon64
        hb_DynCall( { "AddWebViewWindowTaskBarIcon64", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_cIconPath)
    endif

    do case
    case par_cMode == "HTML"
        hb_DynCall({"SetHTML" ,l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_cHtml)
        // hb_DynCall({"Navigate",l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,"data:text/html,"+par_cHtml)
        
        if !hb_IsNil(par_cJS)  // To be tested
            hb_DynCall({"InjectJavaScript" ,l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_cJS)
        endif

    case par_cMode == "URL"
        hb_DynCall({"Navigate",l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber,par_cURL)

    endcase

    do while .t.
        l_nTerminationType := hb_DynCall( { "Run", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber )

        do case
        case l_nTerminationType == 0  //Window Close
            exit
        case l_nTerminationType == 1  //Explicit Close
            //hb_idleSleep(10)  // Will Block all thread.
            exit
        otherwise
            exit
        endcase

    enddo

    hb_DynCall( { "Destroy", l_hLib, HB_DYN_CTYPE_LONG},l_nWindowNumber )

    if !hb_IsNil(par_oController)
        par_oController:OnCloseWindow(l_nTerminationType)
    endif

    v_oWindowManager:UnRegisterWindow(l_nWindowNumber)

endif

return nil
//=================================================================================================================
function GetZuluTimeStampForFileNameSuffix()   // Can be used later to help postfix file names
local l_cTimeStamp := hb_TSToStr(hb_TSToUTC(hb_DateTime()))
l_cTimeStamp := left(l_cTimeStamp,len(l_cTimeStamp)-4)
return hb_StrReplace( l_cTimeStamp , {" "=>"-",":"=>"-"})+"-Zulu"
//=================================================================================================================
//=================================================================================================================
class WindowHandlers  // Used as parent class for Window specific classes. This will allow to add default methods.

exported:
data nWindowNumber init 0

//Following Can be set by BuildWindowContent() method
data BuildWindowContentMode init "HTML"
data BuildWindowContentHTML init ""
data BuildWindowContentURL  init ""
data BuildWindowContentJS   init ""

method Controller(par_cCallCounter,par_cAction,par_hNameValues) //Since more than one CallBack could happen at the same time from the Window, like a JS timer and multiple click events, had to send the parameter along instead of extra class properties.
method ReturnHash(par_cCallCounter,par_hResult)
method RunJS(par_cJS)  // Similar to the v_oWindowManager:RunJS but is already aware of the current ::nWindowNumber
method TerminateWindow()

method OnOpenWindow()
method OnCloseWindow(par_nTerminationType)   //Place Holder method that could be used for actions to be done when closing the window
method BuildWindowContent()

endclass
//========================================================
method Controller(par_cCallCounter,par_cAction,par_hNameValues) class WindowHandlers
return nil
//========================================================
method ReturnHash(par_cCallCounter,par_hResult) class WindowHandlers
local l_hLib := v_hConfig["hLib"]
hb_DynCall( { "JSToHarbourReturn", l_hLib, HB_DYN_CTYPE_LONG},::nWindowNumber,par_cCallCounter,hb_jsonEncode(par_hResult) )
return nil
//========================================================
method RunJS(par_cJS) class WindowHandlers
hb_DynCall( { "RunJS", v_hConfig["hLib"], HB_DYN_CTYPE_LONG},::nWindowNumber,par_cJS )   // Due to threads I suppose, can not run JS code in a windows not owned by the thread.
return nil
//========================================================
method TerminateWindow() class WindowHandlers
v_oWindowManager:TerminateWindow(::nWindowNumber)
return nil
//========================================================
method OnOpenWindow() class WindowHandlers
return nil
//========================================================
method OnCloseWindow(par_nTerminationType) class WindowHandlers
return nil
//========================================================
method BuildWindowContent() class WindowHandlers
return nil
//========================================================
//=================================================================================================================
//=================================================================================================================
#pragma BEGINDUMP

#include <windows.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hbapiitm.h"

HB_FUNC( MYOUTPUTDEBUGSTRING )
{
   OutputDebugString( hb_parc(1) );
}

void wv_JSToHarbour( const char * szNumRequests, const char * szJson, void * p )
{
    int WindowNumber = *((int*)p);   // _M_ Later should allow to be an entire string instead.

    hb_vmPushSymbol( hb_dynsymGetSymbol( "JSToHarbour" ) );
    hb_vmPushNil();
    hb_vmPushString( szNumRequests, strlen( szNumRequests ) );
    hb_vmPushString( szJson, strlen( szJson ) );
    hb_vmPushInteger(WindowNumber);
    hb_vmFunction( 3 );  //The parameter is the number of parameters on the calling stack
}

HB_FUNC( GET_WV_JSTOHARBOUR_AS_POINTER )
{
    void (*ptr)() = &wv_JSToHarbour;
    hb_retptr( ptr );
}

#pragma ENDDUMP
