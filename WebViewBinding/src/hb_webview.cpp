//Copyright (c) 2024 Eric Lendvai, Federal Way, WA, USA, MIT License

#define LIBRARYVERSION 128
#define MAXNUMBEROFWINDOWS 100

#include "hb_webview/webview.h"
#include "hb_webview/hb_webview.h"

#include <stdio.h>
// #include <stdlib.h>
#include <string.h>
#include <stdbool.h>


#if defined(_WIN32)
//#include <windows.h>
#include <winuser.h>
#endif

// typedef struct {
//   webview_t w;
//   unsigned int count;
// } context_t;

void wv_PingWebView(const char * par_x ,const char *par_y ,void * );
void wv_GetWebViewBindingVersion(const char * par_x ,const char *par_y ,void * );
void wv_CloseWebViewWindow(const char * par_x ,const char *par_y ,void * );
void wv_CallHB(const char * par_x ,const char *par_y ,void * );

int64_t FindWebViewHandleNumber(webview_t);

// Due to the fact that arrays in Harbour start at position 1, we will skip the first C array element to make it easier to read code.

webview_t *WebViewHandles[MAXNUMBEROFWINDOWS+1] = {NULL};  //nullptr

// int WindowsNumbers[] = {0,1,2,3,4,5,6,7,8,9,10};  //_M_ make this dynamic
int WindowsNumbers[MAXNUMBEROFWINDOWS+1] = {0};  // Actual values will be assigned when used

int TerminateMethod[MAXNUMBEROFWINDOWS+1] = {0};   // 0 = Non Explicit (like closing the window), 1 = Called Via webview_terminate

bool AvailableWindow[MAXNUMBEROFWINDOWS+1] = {false};

//NOTE   When using OutputDebugStringA()  end with \0   Harbour does not need this, but C / C++ does.

#if defined(_WIN32)
#include <windows.h>

extern "C" __declspec(dllexport)
BOOL APIENTRY DllMain (HINSTANCE hInst, DWORD reason, LPVOID lpReserved)
{
//	std::string text =
//		std::string("DLL Loaded into the process => PID = ")
//		+ std::to_string(::GetCurrentProcessId());
//	WindbgTrace(text);
//	DbgTrace(text);


//    // OutputDebugStringA("[Harbour] in DLLMain\0") ;
//    switch (reason)
//    {
//    case DLL_PROCESS_ATTACH:
//    //   OutputDebugStringA("[Harbour] in DLLMain PROCESS ATTACH\0") ;
//      break;
//    case DLL_PROCESS_DETACH:
//    //   OutputDebugStringA("[Harbour] in DLLMain PROCESS DETACH\0") ;
//      break;
//    case DLL_THREAD_ATTACH:
//        // OutputDebugStringA("[Harbour] in DLLMain THREAD ATTACH\0") ;
//        break;
//    case DLL_THREAD_DETACH:
//        // OutputDebugStringA("[Harbour] in DLLMain THREAD DETACH\0") ;
//      break;
//    }


  return TRUE;
}
#endif

static void (*function_JSToHarbour_pointer)(const char * , const char * , void * );

int64_t WebViewBindingVersion()
{
#if defined(_WIN32)
    char textBuffer[256];
    sprintf(textBuffer, "[Harbour] in WebViewBindingVersion %d \0", LIBRARYVERSION);
    OutputDebugStringA(textBuffer);
#endif
    return LIBRARYVERSION;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t GetWindowNumber()   // To find a iWindowNumber that is unused. Had to create its own array since relying on a value being set in WebViewHandles[] is not reliable in a multi threaded environment. Getting an iWindowNumber also reserves it.
{
    int64_t iPossibleWindowNumber;
    int64_t iWindowNumber = -1;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWindowNumber\0") ;
//  #endif

    for (iPossibleWindowNumber = 1; iPossibleWindowNumber <= MAXNUMBEROFWINDOWS; iPossibleWindowNumber++)
    {
        if (AvailableWindow[iPossibleWindowNumber] == false)
        {
            AvailableWindow[iPossibleWindowNumber] = true;
            iWindowNumber = iPossibleWindowNumber;
            break;
        }
    }
    
    return iWindowNumber;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t CreateWebViewWindow(int64_t par_iWindowNumber,int par_iAllowDeveloperTools)
{
    webview_t NewWebViewHandle;
    int64_t iWindowNumber;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in CreateWebViewWindow\0") ;
//  #endif

    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {

        NewWebViewHandle = webview_create(par_iAllowDeveloperTools, NULL);

        WebViewHandles[par_iWindowNumber] = (webview_t*) NewWebViewHandle;

        TerminateMethod[par_iWindowNumber] = 0;
        
        iWindowNumber = par_iWindowNumber;
    } else {
        iWindowNumber = 0;
    }

    return iWindowNumber;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t SetWindowTitle(int64_t par_iWindowNumber,char * par_cTite)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in SetWindowTitle\0") ;
//  #endif
    
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        webview_set_title(WebViewHandles[par_iWindowNumber],par_cTite);
    }

    return 1;
    
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t SetWindowSize(int64_t par_iWindowNumber,int64_t par_iWidth,int64_t par_iHeight)
{
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        webview_set_size(WebViewHandles[par_iWindowNumber], par_iWidth, par_iHeight, WEBVIEW_HINT_NONE);
    }

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t SetWindowPositionAndSize(int64_t par_iWindowNumber,int64_t par_iTop,int64_t par_iLeft,int64_t par_iWidth,int64_t par_iHeight)
{
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        //Due to x,y had to swap top,left to left, top
        webview_set_position_and_size(WebViewHandles[par_iWindowNumber], par_iLeft, par_iTop, par_iWidth, par_iHeight, WEBVIEW_HINT_NONE);
    }

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t Navigate(int64_t par_iWindowNumber,char * par_cURL)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in Navigate\0") ;
//  #endif
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        
        TerminateMethod[par_iWindowNumber] = 0;  //Needed in case Made more than one Run for a New Window

        // Still set in case a WebView aware web app, like DataWharf running inside of WharNet
        webview_bind(WebViewHandles[par_iWindowNumber],"PingWebView",wv_PingWebView,WebViewHandles[par_iWindowNumber]);
        // webview_bind(WebViewHandles[par_iWindowNumber],"GetWebViewBindingVersion",wv_GetWebViewBindingVersion,WebViewHandles[par_iWindowNumber]);
        webview_bind(WebViewHandles[par_iWindowNumber],"CloseWebViewWindow",wv_CloseWebViewWindow,WebViewHandles[par_iWindowNumber]);
        WindowsNumbers[par_iWindowNumber] = (int) par_iWindowNumber;  // The webview_bind function needed an address where a value is stored.
        webview_bind(WebViewHandles[par_iWindowNumber],"CallHB"            ,wv_CallHB            ,WindowsNumbers+par_iWindowNumber);   // Will be telling to send back the windows par_iWindowNumber, by using and array of handles WindowsNumbers

        webview_navigate(WebViewHandles[par_iWindowNumber], par_cURL);
    }

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t Run(int64_t par_iWindowNumber)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in Run\0") ;
//  #endif
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        webview_run(WebViewHandles[par_iWindowNumber]);
        return TerminateMethod[par_iWindowNumber];
    } else {
        return -1;
    }
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t Destroy(int64_t par_iWindowNumber)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in Destroy\0") ;
//  #endif
    
    if (par_iWindowNumber <= MAXNUMBEROFWINDOWS) {
        webview_destroy(WebViewHandles[par_iWindowNumber]);
        WebViewHandles[par_iWindowNumber] = nullptr;
        AvailableWindow[par_iWindowNumber] = false;
    }

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t Terminate(int64_t par_iWindowNumber)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in Terminate\0") ;
//  #endif
    webview_terminate(WebViewHandles[par_iWindowNumber]);
    TerminateMethod[par_iWindowNumber] = 1;
    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t SetCallBackFunctionToJSToHarbour(void (*par_ptr)(const char * , const char * , void * ))
{
    function_JSToHarbour_pointer = par_ptr;
    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
void wv_PingWebView(const char * par_szNumRequests,const char * par_y,void * par_t){
#if defined(_WIN32)
    char textBuffer[256];
    webview_t wv = *( webview_t *)par_t;

    sprintf(textBuffer,"[Harbour] in wv_PingWebView params:[%s],[%s],[%p]\0",par_szNumRequests,par_y,par_t);
    OutputDebugStringA(textBuffer);
#endif
// No return value since the purpose to see if we don't get an error.
}
//---------------------------------------------------------------------------------------------------------------------------------------
//I tried many ways to make this work, but for an unknown reason calling webview_return directly from the received entry point never works. Maybe this is a threading issue.
//left the code here in case in the future will find a solution.
void wv_GetWebViewBindingVersion(const char * par_szNumRequests,const char * par_y,void * par_t){

//     #if defined(_WIN32)
//         char textBuffer[256];
//     #endif
//         webview_t wv = *( webview_t *)par_t;
//     #if defined(_WIN32)
//         sprintf(textBuffer,"[Harbour] in wv_GetWebViewBindingVersion params:[%s],[%s],[%p]\0",par_szNumRequests,par_y,par_t);
//         OutputDebugStringA(textBuffer);
//     #endif
//     // webview_terminate(wv);
//     // webview_return(wv, par_szNumRequests, 0,"{\"Version\":\"007\"}\0");
//     // webview_return(wv, par_szNumRequests, 0,"{\"version\":\"salut\"}\0");
//     
//     // sprintf(textBuffer,"{\"version\":\"HelloWorld003\"}\0");
//     //webview_return(wv, par_szNumRequests, 0,textBuffer);
//     
//     //webview_return(wv, par_szNumRequests, 0,"{\"version\":\"HelloWorld003\"}\0");
//     webview_return(wv, par_szNumRequests, 0,"{\"version\":\"HelloWorld003\"}");

}
//---------------------------------------------------------------------------------------------------------------------------------------
void wv_CloseWebViewWindow(const char * par_x,const char * par_y,void * par_t){
#if defined(_WIN32)
    char textBuffer[256];
#endif
    webview_t wv = *( webview_t *)par_t;
//  #if defined(_WIN32)
//      sprintf(textBuffer,"[Harbour] in wv_CloseWebViewWindow params:[%s],[%s],[%p]\0",par_x,par_y,par_t);
//      OutputDebugStringA(textBuffer);
//  #endif
    TerminateMethod[FindWebViewHandleNumber(par_t)] = 1;
    webview_terminate(wv);
}
//---------------------------------------------------------------------------------------------------------------------------------------
void wv_CallHB( const char * par_szNumRequests, const char * par_szJson, void * par_p )
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in wv_CallHB\0") ;
//  #endif
    
    (*function_JSToHarbour_pointer)(par_szNumRequests,par_szJson,par_p);
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t FindWebViewHandleNumber(webview_t par_WebViewHandle)
{
    int64_t iWindowNumber = 0;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in FindWebViewHandleNumber\0") ;
//  #endif

    //Find an Unused WebViewHandle
    for (iWindowNumber = 1; iWindowNumber <= MAXNUMBEROFWINDOWS; iWindowNumber++)
    {
        if (WebViewHandles[iWindowNumber] == par_WebViewHandle)
        {
            break;
        }
    }

    return iWindowNumber;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t RunJS(int64_t par_iWindowNumber,char * par_cJS)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in RunJS\0") ;
//  #endif
    
    webview_eval(WebViewHandles[par_iWindowNumber], par_cJS);

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t SetHTML(int64_t par_iWindowNumber,char * par_cHTML)
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in SetHtml\0") ;
//  #endif
    
    webview_set_html(WebViewHandles[par_iWindowNumber], par_cHTML);

    webview_bind(WebViewHandles[par_iWindowNumber],"PingWebView",wv_PingWebView,WebViewHandles[par_iWindowNumber]);
    // webview_bind(WebViewHandles[par_iWindowNumber],"GetWebViewBindingVersion",wv_GetWebViewBindingVersion,WebViewHandles[par_iWindowNumber]);
    webview_bind(WebViewHandles[par_iWindowNumber],"CloseWebViewWindow",wv_CloseWebViewWindow,WebViewHandles[par_iWindowNumber]);
    WindowsNumbers[par_iWindowNumber] = (int) par_iWindowNumber;  // The webview_bind function needed an address where a value is stored.
    webview_bind(WebViewHandles[par_iWindowNumber],"CallHB"            ,wv_CallHB            ,WindowsNumbers+par_iWindowNumber);   // Will be telling to send back the windows par_iWindowNumber, by using and array of handles WindowsNumbers

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t InjectJavaScript(int64_t par_iWindowNumber,char * par_cJS)  // Was not able to confirm if this works yet.
{
//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in InjectJavaScript\0") ;
//  #endif
    
    webview_init(WebViewHandles[par_iWindowNumber], par_cJS);

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t BringWebViewWindowForeground(int64_t par_iWindowNumber)
{
    void * iWindowHandle;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in BringWebViewWindowForeground\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    BringWindowToTop( (HWND) iWindowHandle);
    
    return par_iWindowNumber;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t GetWebViewWindowPositionTop(int64_t par_iWindowNumber)
{
    int64_t iResult;
    void * iWindowHandle;
    RECT Rect;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWebViewWindowPositionTop\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    GetWindowRect((HWND) iWindowHandle, &Rect);

    iResult = Rect.top;
    
    return iResult;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t GetWebViewWindowPositionLeft(int64_t par_iWindowNumber)
{
    int64_t iResult;
    void * iWindowHandle;
    RECT Rect;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWebViewWindowPositionLeft\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    GetWindowRect((HWND) iWindowHandle, &Rect);

    iResult = Rect.left;
    
    return iResult;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t GetWebViewWindowSizeWidth(int64_t par_iWindowNumber)
{
    int64_t iResult;
    void * iWindowHandle;
    RECT Rect;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWebViewWindowSizeWidth\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    GetWindowRect((HWND) iWindowHandle, &Rect);

    iResult = Rect.right-Rect.left;
    
    return iResult;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t GetWebViewWindowSizeHeight(int64_t par_iWindowNumber)
{
    int64_t iResult;
    void * iWindowHandle;
    RECT Rect;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWebViewWindowSizeHeight\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    GetWindowRect((HWND) iWindowHandle, &Rect);

    iResult = Rect.bottom-Rect.top;
    
    return iResult;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t DisableWindowCloseOption(int64_t par_iWindowNumber)
{
    void * iWindowHandle;

#if defined(_WIN32)
    // OutputDebugStringA("[Harbour] in DisableWindowCloseOption\0") ;

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);
    EnableMenuItem(GetSystemMenu((HWND) iWindowHandle, FALSE), SC_CLOSE, MF_BYCOMMAND | MF_DISABLED | MF_GRAYED);

#endif
    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t MoveWebViewWindow(int64_t par_iWindowNumber,int64_t par_iTop,int64_t par_iLeft,int64_t par_iWidth,int64_t par_iHeight)
{
    int64_t iResult;
    void * iWindowHandle;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in GetWebViewWindowSizeHeight\0") ;
//  #endif

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);

    MoveWindow((HWND) iWindowHandle, par_iLeft,par_iTop,par_iWidth,par_iHeight,true);

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t AddWebViewWindowTaskBarIcon64(int64_t par_iWindowNumber,char * par_cPath)
{
    HICON hImg;
    void * iWindowHandle;

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in AddWebViewWindowTaskBarIcon\0") ;
//  #endif
    hImg = (HICON) LoadImage(NULL, par_cPath, IMAGE_ICON,64,64,LR_LOADFROMFILE);

    iWindowHandle = webview_get_window(WebViewHandles[par_iWindowNumber]);

    SendMessage ((HWND) iWindowHandle, WM_SETICON, ICON_SMALL, (LPARAM) hImg);

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
int64_t JSToHarbourReturn(int64_t par_iWindowNumber,char * par_cCallCounter,char * par_cJson)
{

//  #if defined(_WIN32)
//      OutputDebugStringA("[Harbour] in JSToHarbourReturn\0") ;
//  #endif

    webview_return(WebViewHandles[par_iWindowNumber], par_cCallCounter, 0,par_cJson);

    return 1;
}
//---------------------------------------------------------------------------------------------------------------------------------------
