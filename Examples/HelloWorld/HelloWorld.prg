//Copyright (c) 2021 Eric Lendvai MIT License

//#include "hb_fcgi.ch"

//=================================================================================================================
Function Main()

?"Hello World"
?hb_buildinfo()
//SendToDebugView("Starting app")

return nil
//=================================================================================================================
function hb_buildinfo()
#include "BuildInfo.txt"
return l_cBuildInfo
//=================================================================================================================

