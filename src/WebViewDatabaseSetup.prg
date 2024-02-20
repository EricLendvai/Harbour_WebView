//Copyright (c) 2024 Eric Lendvai, Federal Way, WA, USA, MIT License

#include "WebViewDemo.ch"

//=================================================================================================================
function CreateWindowDataBaseSetup()
local l_cHtml

local l_nBackendType
local l_cServer
local l_cODBCDriver
local l_nPort
local l_cUser
local l_nPasswordStorage
local l_cPasswordConfigKey
local l_cPasswordEnvVarName
local l_cDatabase
local l_aControlWindowPositionAndSize := v_oWindowManager:GetWindowPositionAndSize(v_hConfig["ControlWindowNumber"])

l_cHtml := GetWebPageHeader()

l_cHtml += [<body><form>]   // <form> is required to fetch entry values

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Database Setup</span>]   //navbar-text
        l_cHtml += [<button onclick="CloseWebViewWindow()" class="btn btn-primary rounded ms-3">Cancel</button>]
        l_cHtml += [<button onclick="CallHB('SaveChanges^'+$('form').serialize());return false;" class="btn btn-primary rounded ms-3">Save Changes</button>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

v_oWindowManager:LoadAppConfig()  // To ensure we have the latest values

l_nBackendType        := val(v_oWindowManager:GetAppConfig("BackendType"))
l_cODBCDriver         := v_oWindowManager:GetAppConfig("ODBCDriver")
l_cServer             := v_oWindowManager:GetAppConfig("Server")
l_nPort               := val(v_oWindowManager:GetAppConfig("Port"))
l_cUser               := v_oWindowManager:GetAppConfig("User")
l_nPasswordStorage    := val(v_oWindowManager:GetAppConfig("PasswordStorage"))
l_cPasswordConfigKey  := v_oWindowManager:GetAppConfig("PasswordConfigKey")
l_cPasswordEnvVarName := v_oWindowManager:GetAppConfig("PasswordEnvVarName")
l_cDatabase           := v_oWindowManager:GetAppConfig("Database")

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Server Type</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select name="ComboBackendType" id="ComboBackendType">]
                l_cHtml += [<option value="0"]+iif(l_nBackendType==0,[ selected],[])+[></option>]
                l_cHtml += [<option value="1"]+iif(l_nBackendType==1,[ selected],[])+[>MariaDB</option>]
                l_cHtml += [<option value="2"]+iif(l_nBackendType==2,[ selected],[])+[>MySQL</option>]
                l_cHtml += [<option value="3"]+iif(l_nBackendType==3,[ selected],[])+[>PostgreSQL</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Server Address/IP</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextServer" id="TextServer" value="]+PrepFieldForValue(l_cServer)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Alternate ODBC Driver</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextODBCDriver" id="TextODBCDriver" value="]+PrepFieldForValue(l_cODBCDriver)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Port (If not default)</td>]
            l_cHtml += [<td class="pb-3"><input type="number" name="TextPort" id="TextPort" value="]+iif(empty(l_nPort),"",Trans(l_nPort))+[" maxlength="10" size="10"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">User Name</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextUser" id="TextUser" value="]+PrepFieldForValue(l_cUser)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Password</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<span class="pe-5">]
                    l_cHtml += [<select name="ComboPasswordStorage" id="ComboPasswordStorage" onchange='OnChangePasswordStorage(this.value);'>]
                    l_cHtml += [<option value="0"]+iif(l_nPasswordStorage==0,[ selected],[])+[></option>]
                    l_cHtml += [<option value="1"]+iif(l_nPasswordStorage==1,[ selected],[])+[>In config.txt</option>]
                    l_cHtml += [<option value="2"]+iif(l_nPasswordStorage==2,[ selected],[])+[>In Environment Variable</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanPasswordConfigKey" style="display: none;">]
                    l_cHtml += [<span class="pe-1">Config Key</span>]
                    l_cHtml += [<input type="text" name="TextPasswordConfigKey" id="TextPasswordConfigKey" value="]+PrepFieldForValue(l_cPasswordConfigKey)+[" size="20" maxlength="200">]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanPasswordEnvVarName" style="display: none;">]
                    l_cHtml += [<span class="pe-1">Environment Variable</span>]
                    l_cHtml += [<input type="text" name="TextPasswordEnvVarName" id="TextPasswordEnvVarName" value="]+PrepFieldForValue(l_cPasswordEnvVarName)+[" size="20" maxlength="200">]
                l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Database</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextDatabase" id="TextDatabase" value="]+PrepFieldForValue(l_cDatabase)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]
       
    l_cHtml += [</table>]

l_cHtml += [</div>]

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangePasswordStorage(par_Value) {]

l_cHtml += [switch(par_Value) {]
l_cHtml += [  case '1':]
l_cHtml += [  $('#SpanPasswordConfigKey').show();]
l_cHtml += [  $('#SpanPasswordEnvVarName').hide();]
l_cHtml += [    break;]
l_cHtml += [  case '2':]
l_cHtml += [  $('#SpanPasswordConfigKey').hide();]
l_cHtml += [  $('#SpanPasswordEnvVarName').show();]
l_cHtml += [    break;]
l_cHtml += [  default:]
l_cHtml += [  $('#SpanPasswordConfigKey').hide();]
l_cHtml += [  $('#SpanPasswordEnvVarName').hide();]
l_cHtml += [};]

l_cHtml += [};]

l_cHtml += [OnChangePasswordStorage($("#ComboPasswordStorage").val());]

l_cHtml += [</script>] 

l_cHtml += [</form></body></html>]

v_oWindowManager:CreateWindow(WindowHandlerDatabaseSetup(),;
                              "Harbour WebView Demo - Database Setup",;
                              l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_TOP]+30,;
                              l_aControlWindowPositionAndSize[POSITION_AND_SIZE_INDEX_LEFT]+30,;
                              850,;
                              550,;
                              v_hConfig["WindowTaxBarIcon"],"HTML",l_cHtml)

return nil
//=================================================================================================================
//=================================================================================================================
class WindowHandlerDatabaseSetup from WindowHandlers
exported:
method Controller(par_cCallCounter,par_cAction,par_hNameValues)
endclass
//========================================================
method Controller(par_cCallCounter,par_cAction,par_hNameValues) class WindowHandlerDatabaseSetup
// local l_hLib := v_hConfig["hLib"]

do case
case par_cAction == "SaveChanges"
    v_oWindowManager:SetAppConfig("BackendType"       ,par_hNameValues["ComboBackendType"])
    v_oWindowManager:SetAppConfig("Server"            ,par_hNameValues["TextServer"])
    v_oWindowManager:SetAppConfig("ODBCDriver"        ,par_hNameValues["TextODBCDriver"])
    v_oWindowManager:SetAppConfig("Port"              ,par_hNameValues["TextPort"])
    v_oWindowManager:SetAppConfig("User"              ,par_hNameValues["TextUser"])
    v_oWindowManager:SetAppConfig("PasswordStorage"   ,par_hNameValues["ComboPasswordStorage"])
    v_oWindowManager:SetAppConfig("PasswordConfigKey" ,par_hNameValues["TextPasswordConfigKey"])
    v_oWindowManager:SetAppConfig("PasswordEnvVarName",par_hNameValues["TextPasswordEnvVarName"])
    v_oWindowManager:SetAppConfig("Database"          ,par_hNameValues["TextDatabase"])

    v_oWindowManager:SaveAppConfig()

    ::TerminateWindow()

endcase

return nil
//=================================================================================================================
