 //Copyright (c) 2024 Eric Lendvai, Federal Way, WA, USA, MIT License
 
 #include "WebViewDemo.ch"

//=================================================================================================================
function CreateWindowAbout()
local l_cHtml
local l_aControlWindowPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(v_hConfig["ControlWindowNumber"])
l_cHtml := GetWebPageHeader()

l_cHtml += [<body>]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">About</span>]   //navbar-text

        l_cHtml += [<button onclick="CloseWebViewWindow()" class="btn btn-primary rounded ms-3">Close</button>]

    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]

    l_cHtml += [<div class="col-auto">]
     
        l_cHtml += [<table class="table table-sm table-bordered table-striped">]

        l_cHtml += [<tr><td>Based on and License</td>]       +[<td><a href="https://github.com/EricLendvai/Harbour_WebView" target="_blank">https://github.com/EricLendvai/Harbour_WebView</a></td></tr>]
        l_cHtml += [<tr><td>Localhost Port</td>]             +[<td>]+trans(INTERNAL_WEBSERVER_LOCALHOST_PORT)+[</td></tr>]

        l_cHtml += [<tr><td>Application Version</td>]        +[<td>]+v_hConfig["ApplicationVersion"]     +[</td></tr>]
        l_cHtml += [<tr><td>Application Build Info</td>]     +[<td>]+v_hConfig["ApplicationBuildInfo"]   +[</td></tr>]
        l_cHtml += [<tr><td>ORM Build Info</td>]             +[<td>]+hb_orm_buildinfo()                  +[</td></tr>]
        l_cHtml += [<tr><td>EL Build Info</td>]              +[<td>]+hb_el_buildinfo()                   +[</td></tr>]

        l_cHtml += [<tr><td>Application Executable</td>]     +[<td>]+hb_argv(0)                          +[</td></tr>]   //hb_DirBase()
        l_cHtml += [<tr><td>Current Application Folder</td>] +[<td>]+hb_cwd()                            +[</td></tr>]

        l_cHtml += [</table>]

    l_cHtml += [</div>]
l_cHtml += [</div>]
 
l_cHtml += [</body></html>]

v_oWindowManager:CreateWindow(,"Harbour WebView Demo - About",;
                               l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_TOP]+30,;
                               l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT]+30,;
                               900,500,v_hConfig["WindowTaxBarIcon"],"HTML",l_cHtml)

return nil
//=================================================================================================================
