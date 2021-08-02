cmake_minimum_required(VERSION 3.13.4)

set( CMAKE_VERBOSE_MAKEFILE on )

project(HB_WEBVIEW_EXAMPLE)

add_executable(${PROJECT_NAME} main.c)

add_subdirectory(WebViewLib)

target_include_directories(HB_WEBVIEW_EXAMPLE PUBLIC WebViewLib)

target_link_directories(${PROJECT_NAME} PRIVATE WebViewLib)

target_link_libraries(HB_WEBVIEW_EXAMPLE hb_webview)

#IF(MSVC)
#    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17 /EHsc")
#ENDIF(MSVC)

