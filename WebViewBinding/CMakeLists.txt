cmake_minimum_required(VERSION 3.15)

project(
    hb_webview
    VERSION 0.0.3
    LANGUAGES CXX)

add_library(${PROJECT_NAME} SHARED)
target_sources(${PROJECT_NAME} PRIVATE src/hb_webview.cpp)

target_include_directories(${PROJECT_NAME} PUBLIC "${CMAKE_HOME_DIRECTORY}/microsoft.web.webview2.1.0.664.37/build/native/include/")
target_link_libraries(${PROJECT_NAME} "${CMAKE_HOME_DIRECTORY}/microsoft.web.webview2.1.0.664.37/build/native/x64/WebView2Loader.dll.lib")

IF(MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17 /EHsc")
ENDIF(MSVC)

include(GNUInstallDirs)

target_include_directories(
    ${PROJECT_NAME}
    PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/>
           $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

# sets the _EXPORT #define for the target (library)
# to ensure the functions are exported (visible)
target_compile_definitions(${PROJECT_NAME} PRIVATE -D_EXPORT)

set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

# specify the target to install (hb_webview library defined above)
# set the export name <name>-config (does not need to match target name)
# also specify where the .dylib/.so/.dll+.lib file should be installed

# install(
#     TARGETS ${PROJECT_NAME}
#     EXPORT ${PROJECT_NAME}-config
#     RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#     LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#     ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

# install(
#     EXPORT ${PROJECT_NAME}-config
#     NAMESPACE ${PROJECT_NAME}::
#     DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

# install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/include/${PROJECT_NAME}/
#         DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})

# install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/include/
#         DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})
