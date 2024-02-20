//Copyright (c) 2024 Eric Lendvai, Federal Way, WA, USA, MIT License

#include "WebViewDemo.ch"

//=================================================================================================================
function CreateControlWindow()
local l_cHtml
local l_cInfo
local l_nWindowNumber

l_cHtml := GetWebPageHeader()

l_cHtml += [<body>]

l_cHtml += [<script>]
l_cHtml += [  $(document).ready(function(){]
l_cHtml += [      $("#jinfo").click(function(){]
l_cHtml += [        if (typeof jQuery != 'undefined') {]
l_cHtml += [          alert($().jquery+' and '+$.ui.version);]
l_cHtml += [        }]
l_cHtml += [      });]
l_cHtml += [  });]
l_cHtml += [</script>]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Control</span>]   //navbar-text

        l_cHtml += [<button onclick="$(this).css('background','red');CallHB('Quit');" class="btn btn-primary rounded ms-3">Quit</button>]
        l_cHtml += [<button onclick="CallHB('CreateWindowDataBaseSetup');"            class="btn btn-primary rounded ms-3">Database Setup</button>]
        l_cHtml += [<button onclick="CallHB('CreateWindowCompanies');"                class="btn btn-primary rounded ms-3">Companies</button>]
        l_cHtml += [<button onclick="CallHB('CreateWindowAbout');"                    class="btn btn-primary rounded ms-3">About</button>]
        // l_cHtml += [<button onclick="CallHB('HelloWorld');"                           class="btn btn-primary rounded ms-3">CallHB</button>]
        

        // l_cHtml += [<button onclick="CloseWebViewWindow();"                      class="btn btn-primary rounded ms-3">Close</button>]


    l_cHtml += [</div>]
    
    l_cHtml += [<div class="m-1"></div>]

    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Extra</span>]   //navbar-text

        l_cHtml += [<button onclick="CallHB('ChangeTitle');"                                           class="btn btn-primary rounded ms-3">Change Window Title</button>]

        l_cInfo := ['CPU: '+result.CPU+'\nMachine: '+result.Machine+'\nBase Directory: '+result.BaseDirectory+'\nCurrent Directory: '+result.CurDir]
        l_cHtml += [<button onclick="CallHB('GetComputerInfo').then(result => {alert(]+l_cInfo+[);});" class="btn btn-primary rounded ms-3">Get Computer Info</button>]

        l_cHtml += [<button onclick="CallHB('OpenNewWindowGoogle');"                                   class="btn btn-primary rounded ms-3">Open Google</button>]
        l_cHtml += [<button onclick="CallHB('CreateWindowShowAnImage');"                               class="btn btn-primary rounded ms-3">Show Image</button>]
        l_cHtml += [<button onclick="CallHB('GetWindowsInfo');"                                        class="btn btn-primary rounded ms-3">Get Windows Information</button>]
        l_cHtml += [<button onclick="CallHB('MoveToTop');"                                             class="btn btn-primary rounded ms-3">Move To Top</button>]

    l_cHtml += [</div>]
    
l_cHtml += [</nav>]

l_cHtml += [<div class="m-1"></div>]


// JavaScript Timers to call HArbour code. Two methods to update UI.

l_cHtml += [<div class="m-1"><span>Time Set By JavaScript Call from Harbour: <span><span id="JSTimer001"></span></div>]
l_cHtml += [<script>]
l_cHtml += [function Timer001() {]
l_cHtml += [  CallHB('Timer001');]
l_cHtml += [};]
l_cHtml += [setInterval(Timer001, 1000)]
l_cHtml += [</script>]

l_cHtml += [<div class="m-1"><span>Time Set By Return value from Harbour: <span><span id="JSTimer002"></span></div>]
l_cHtml += [<script>]
l_cHtml += [function Timer002() {]
l_cHtml += [  CallHB('Timer002').then(result => {document.getElementById("JSTimer002").innerHTML = result.info;});]
l_cHtml += [};]
l_cHtml += [setInterval(Timer002, 1000)]
l_cHtml += [</script>]


l_cHtml += [<div class="m-3"></div>]
l_cHtml += v_hConfig["HtmlMessageDiv"]

l_cHtml += [<div class="m-3"><button id='jinfo'>Get Jquery Info</button></div>]

l_cHtml += [</body></html>]
l_nWindowNumber := v_oWindowManager:CreateWindow(WindowHandlerControl(),"Harbour WebView Demo - Control",10,100,1100,420,v_hConfig["WindowTaxBarIcon"],"HTML",l_cHtml)

return l_nWindowNumber
//=================================================================================================================
class WindowHandlerControl from WindowHandlers
exported:
method Controller(par_cCallCounter,par_cAction,par_hNameValues)
endclass
//========================================================
method Controller(par_cCallCounter,par_cAction,par_hNameValues) class WindowHandlerControl
local l_aWindows
local l_aWindowInfo
local l_cHTML
local l_cJS
local l_hLib := v_hConfig["hLib"]
local l_aPositionAndSize

do case
case par_cAction == 'Timer001'
    l_cJS := [document.getElementById("JSTimer001").innerHTML = "]+GetZuluTimeStampForFileNameSuffix()+[";]
    ::RunJS(l_cJS)

case par_cAction == 'Timer002'
    ::ReturnHash(par_cCallCounter,{"info" => GetZuluTimeStampForFileNameSuffix()+" - Memory Used: "+trans(memory(HB_MEM_USED))+" Kb - Callback Number: "+par_cCallCounter})

case par_cAction == "CreateWindowShowAnImage"
    v_oQueue:push("CallFunction",@CreateWindowShowAnImage())

case par_cAction == "CreateWindowAbout"
    v_oQueue:push("CallFunction",@CreateWindowAbout())

case par_cAction == "CreateWindowDataBaseSetup"
    v_oQueue:push("CallFunction",@CreateWindowDataBaseSetup())

case par_cAction == "CreateWindowCompanies"
    v_oQueue:push("CallFunction",@CreateCompaniesWindow())

case par_cAction == "OpenNewWindowGoogle"
    v_oQueue:push("CreateWindow","OpenGoogle")

case par_cAction == "GetWindowsInfo"
    l_aWindows := v_oWindowManager:GetWindowList()
    l_cHTML := [<table class='table table-striped'>]
    l_cHTML += [<thead><tr>]
    l_cHTML += [<th scope='col'>Number</td>]
    l_cHTML += [<th scope='col'>Title</td>]
    l_cHTML += [<th scope='col'>Top</td>]
    l_cHTML += [<th scope='col'>Left</td>]
    l_cHTML += [<th scope='col'>Width</td>]
    l_cHTML += [<th scope='col'>Height</td>]
    l_cHTML += [</tr></thead>]

    for each l_aWindowInfo in l_aWindows
        l_cHTML += [<tr>]
        l_cHTML += [<td>]+alltrim(str(l_aWindowInfo[1]))+[</td>]
        l_cHTML += [<td>]+alltrim(l_aWindowInfo[3])+[</td>]

        l_aPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(l_aWindowInfo[1])
        l_cHTML += [<td>]+alltrim(str(l_aPositionAndSize[POSITION_AND_SIZE_INDEX_TOP]))   +[</td>]
        l_cHTML += [<td>]+alltrim(str(l_aPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT]))  +[</td>]
        l_cHTML += [<td>]+alltrim(str(l_aPositionAndSize[POSITION_AND_SIZE_INDEX_WIDTH])) +[</td>]
        l_cHTML += [<td>]+alltrim(str(l_aPositionAndSize[POSITION_AND_SIZE_INDEX_HEIGHT]))+[</td>]

        l_cHTML += [</tr>]
    endfor

    l_cHTML += [</table>]

    l_cJS := [document.getElementById("MessageFromHarbour").innerHTML = "]+strtran(l_cHTML,["],[&quot;])+[";]
    ::RunJS(l_cJS)

case par_cAction == "MoveToTop"
    l_aPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(::nWindowNumber)

    v_oWindowManager:MoveWindow(::nWindowNumber,;
                                0,;
                                l_aPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT],;
                                l_aPositionAndSize[POSITION_AND_SIZE_INDEX_WIDTH],;
                                l_aPositionAndSize[POSITION_AND_SIZE_INDEX_HEIGHT])

case par_cAction == "ChangeTitle"
    v_oWindowManager:ChangeTitle(::nWindowNumber,"Harbour WebView Demo - Control - Call Counter: "+par_cCallCounter)

case par_cAction == "GetComputerInfo"
    ::ReturnHash(par_cCallCounter,{"CPU"           => hb_osCPU(),;
                                   "Machine"       => NetName(),;
                                   "BaseDirectory" => hb_DirBase(),;
                                   "CurDir"        => hb_cwd() })      // CurDir()

endcase

return nil
//=================================================================================================================
