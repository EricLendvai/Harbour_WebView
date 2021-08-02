set( CMAKE_VERBOSE_MAKEFILE on )

add_library(hb_webview hb_webview.cpp hb_webview.h)

target_include_directories(HB_WEBVIEW_EXAMPLE PUBLIC "${CMAKE_HOME_DIRECTORY}/hb_webview/WebViewLib/microsoft.web.webview2.1.0.664.37/build/native/include/")
target_link_libraries(HB_WEBVIEW_EXAMPLE "${CMAKE_HOME_DIRECTORY}/WebViewLib/microsoft.web.webview2.1.0.664.37/build/native/x64/WebView2Loader.dll.lib")

IF(MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17 /EHsc")
ENDIF(MSVC)

