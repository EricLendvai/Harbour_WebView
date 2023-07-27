//Copyright (c) 2023 Eric Lendvai, Federal Way, WA, USA, MIT License

#include "WebViewDemo.ch"

//=================================================================================================================
function CreateWindowShowAnImage()
local l_cHtml
local l_aControlWindowPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(v_hConfig["ControlWindowNumber"])

l_cHtml := GetWebPageHeader()

l_cHtml += [<body>]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Rainier and Sailboat</span>]   //navbar-text

        l_cHtml += [<button onclick="CloseWebViewWindow()" class="btn btn-primary rounded ms-3">Close</button>]

    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<style>]
l_cHtml += [  #RainierAndSailboat{]
l_cHtml += [    width: 100%;]
l_cHtml += [    height: 100%;]
l_cHtml += [   }]
l_cHtml += [</style>]

l_cHtml += [<div><img src="]+v_hConfig["SitePath"]+[Logo_RainierSailBoat.png" id="RainierAndSailboat"></div>]
 
l_cHtml += [</body></html>]

v_oWindowManager:CreateWindow(,;
                              "Harbour WebView Demo - Rainier and Sailboat",;
                              l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_TOP]+30,;
                              l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT]+30,;
                              800,;
                              700,;
                              v_hConfig["WindowTaxBarIcon"],"HTML",l_cHtml)

return nil
//=================================================================================================================
