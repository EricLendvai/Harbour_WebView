//Copyright (c) 2021 Eric Lendvai MIT License

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapicdp.h"
#include "hbapierr.h"

#include "R:\Harbour_WebView\hb_webview\WebViewLib\hb_webview.h"

//=================================================================================================================
HB_FUNC( HB_WEBVIEW_TEST001 )
{
    int iReturn;
    iReturn = (int) add(1.0f,1.0f); //testwebview();
    hb_retni(iReturn);
}//=================================================================================================================

