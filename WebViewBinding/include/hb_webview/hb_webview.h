#pragma once

#include <stdint.h>
#include "exporting.h"

//webview_t DLLIMPORT WindowHandles;

extern "C"
{
    DLL_API int64_t WebViewBindingVersion();
    DLL_API int64_t SetCallBackFunctionToJSToHarbour(void (*par_ptr)(const char * , const char * , void * )); 
    
    DLL_API int64_t GetWindowNumber();
    DLL_API int64_t CreateWebViewWindow(int64_t par_iWindowNumber,int par_AllowDeveloperTools);
    DLL_API int64_t SetWindowTitle(int64_t par_iWindowNumber,char * par_cTite);
    DLL_API int64_t SetWindowSize(int64_t par_iWindowNumber,int64_t par_iWidth,int64_t par_iHeight);
    DLL_API int64_t SetWindowPositionAndSize(int64_t par_iWindowNumber,int64_t par_iTop,int64_t par_iLeft,int64_t par_iWidth,int64_t par_iHeight);
    DLL_API int64_t Navigate(int64_t par_iWindowNumber,char * par_cURL);
    DLL_API int64_t Run(int64_t par_iWindowNumber);
    DLL_API int64_t Destroy(int64_t par_iWindowNumber);
    DLL_API int64_t Terminate(int64_t par_iWindowNumber);
    DLL_API int64_t RunJS(int64_t par_iWindowNumber,char * par_cJS);
    DLL_API int64_t SetHTML(int64_t par_iWindowNumber,char * par_cHTML);
    DLL_API int64_t InjectJavaScript(int64_t par_iWindowNumber,char * par_cJS);
    DLL_API int64_t BringWebViewWindowForeground(int64_t par_iWindowNumber);
    DLL_API int64_t GetWebViewWindowPositionTop(int64_t par_iWindowNumber);
    DLL_API int64_t GetWebViewWindowPositionLeft(int64_t par_iWindowNumber);
    DLL_API int64_t GetWebViewWindowSizeWidth(int64_t par_iWindowNumber);
    DLL_API int64_t GetWebViewWindowSizeHeight(int64_t par_iWindowNumber);
    DLL_API int64_t DisableWindowCloseOption(int64_t par_iWindowNumber);
    DLL_API int64_t MoveWebViewWindow(int64_t par_iWindowNumber,int64_t par_iTop,int64_t par_iLeft,int64_t par_iWidth,int64_t par_iHeight);
    DLL_API int64_t AddWebViewWindowTaskBarIcon64(int64_t par_iWindowNumber,char * par_cPath);

    DLL_API int64_t JSToHarbourReturn(int64_t par_iWindowNumber,char * par_cCallCounter,char * par_cJson);

}
