//Copyright (c) 2023 Eric Lendvai, Federal Way, WA, USA, MIT License

#include "WebViewDemo.ch"

//=================================================================================================================
function CreateCompaniesWindow()
v_oWindowManager:CreateWindow(WindowHandlerCompanies(),"Harbour WebView Demo - Companies",30,10,900,400,v_hConfig["WindowTaxBarIcon"])
return nil
//=================================================================================================================
class WindowHandlerCompanies from WindowHandlers

exported:

data p_o_SQLConnection
data p_cMode           init "List"
data p_FieldValues     init {=>}

method Controller(par_cCallCounter,par_cAction,par_hNameValues)
method OnOpenWindow()
method BuildWindowContent()
method OnCloseWindow(par_nTerminationType)

method m_ListForm()
method m_AddEditForm()

endclass
//========================================================
method Controller(par_cCallCounter,par_cAction,par_hNameValues)
local l_cJS
local l_cName
local l_cDescription
local l_cWebSite
local l_oDB1
local l_cError
local l_iPk
local l_oData

do case
case par_cAction == 'NewCompany'
    l_cJS := [document.getElementById("EntireForm").innerHTML = ']+strtran(::m_AddEditForm(),"'","\'")+[';]
    l_cJS += [$('#TextName').focus();$('#TextDescription').resizable();]
    ::RunJS(l_cJS)
    hb_HClear(::p_FieldValues)
    ::p_cMode := "Edit"   // the ::p_FieldValues[pk] will not exists, meaning default to 0, therefore we will need to add a record

case par_cAction == 'Cancel'
    l_cJS := [document.getElementById("EntireForm").innerHTML = ']+strtran(::m_ListForm(),"'","\'")+[';]
    ::RunJS(l_cJS)
    ::p_cMode := "List"

case par_cAction == 'SaveChanges'
    l_iPk          := hb_HGetDef(::p_FieldValues,"pk",0)
    l_cName        := alltrim(par_hNameValues["TextName"])
    l_cDescription := MultiLineTrim(SanitizeInput(par_hNameValues["TextDescription"]))
    l_cWebSite     := alltrim(par_hNameValues["TextWebSite"])

    do case
    case empty(l_cName)
        l_cError := "Missing Name!"
    endcase

    if empty(l_cError)
        l_oDB1 := hb_SQLData(::p_o_SQLConnection)
        with object l_oDB1
            :Table("c8031356-ea5a-4025-99f8-e4c45f70a57d","Company")
            :Field("Company.name"        ,l_cName)
            :Field("Company.description" ,iif(empty(l_cDescription),NULL,l_cDescription))
            :Field("Company.website"     ,l_cWebSite)
            if empty(l_iPk)
                if !:Add()
                    l_cError := "Failed to add company."
                endif
            else
                if !:Update(l_iPk)
                    l_cError := "Failed to update company."
                endif
            endif
        endwith
    endif

    if empty(l_cError)
        hb_HClear(::p_FieldValues)
        l_cJS := [document.getElementById("EntireForm").innerHTML = ']+strtran(::m_ListForm(),"'","\'")+[';]
        ::RunJS(l_cJS)
        ::p_cMode := "List"
    else
        l_cJS := [document.getElementById("LastError").innerHTML = ']+l_cError+[';]
        ::RunJS(l_cJS)
    endif

case "Edit-" $ par_cAction
    l_iPk := val(strtran(par_cAction,"Edit-",""))

    if l_iPk > 0
        hb_HClear(::p_FieldValues)
        l_oDB1 := hb_SQLData(::p_o_SQLConnection)
        with object l_oDB1
            :Table("3e79e80d-2a63-4ab2-9edd-8c93d8c51948","company")
            :Column("company.name"       ,"company_name")
            :Column("company.description","company_description")
            :Column("company.website"    ,"company_website")
            l_oData := :Get(l_iPk)
            ::p_FieldValues["pk"]          := l_iPk
            ::p_FieldValues["name"]        := alltrim(l_oData:company_name)
            ::p_FieldValues["description"] := l_oData:company_description
            ::p_FieldValues["website"]     := alltrim(nvl(l_oData:company_website,""))
        endwith

        l_cJS := [document.getElementById("EntireForm").innerHTML = ']+strtran(::m_AddEditForm(),"'","\'")+[';]
        l_cJS += [$('#TextName').focus();$('#TextDescription').resizable();]
        ::RunJS(l_cJS)
        ::p_cMode := "Edit"
    endif

case "Delete" $ par_cAction
    l_iPk := hb_HGetDef(::p_FieldValues,"pk",0)
    l_oDB1 := hb_SQLData(::p_o_SQLConnection)
    l_oDB1:Delete("1917e4d4-aafd-4ab9-b8ee-45edb5a8ce24","company",l_iPk)

    l_cJS := [document.getElementById("EntireForm").innerHTML = ']+strtran(::m_ListForm(),"'","\'")+[';]
    ::RunJS(l_cJS)
    ::p_cMode := "List"

endcase

return nil
//=================================================================================================================
method m_ListForm()
local l_cHtml := ""
local l_nNumberOfCompany

local l_oDB_ListOfCompany := hb_SQLData(::p_o_SQLConnection)

with object l_oDB_ListOfCompany
    :Table("0dc7c791-4a8f-43b7-8cf8-a0fe1e6621a5","Company")
    :Column("Company.pk"         ,"pk")
    :Column("Company.Name"       ,"Company_Name")
    :Column("Company.Description","Company_Description")
    :Column("Company.Website"    ,"Company_WebSite")
    :Column("Upper(Company.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfCompany")
    l_nNumberOfCompany := :Tally
endwith

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Companies</span>]   //navbar-text
        l_cHtml += [<button onclick="CloseWebViewWindow();return false;" class="btn btn-primary rounded ms-3">Close</button>]
        l_cHtml += [<button onclick="CallHB('NewCompany');return false;" class="btn btn-primary rounded ms-3">New Company</button>]
    l_cHtml += [</div>]
    
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    if empty(l_nNumberOfCompany)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Company on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="4">Companies (]+Trans(l_nNumberOfCompany)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white"></th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Website</th>]
                l_cHtml += [</tr>]

                select ListOfCompany
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<button  onclick="CallHB('Edit-]+trans(ListOfCompany->pk)+[');return false;" class="btn btn-primary rounded">Edit</button>]
                        l_cHtml += [</td>]
                        
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfCompany->Company_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(nvl(ListOfCompany->Company_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfCompany->Company_WebSite)+[</a>]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]
 
return l_cHtml
//=================================================================================================================
method m_AddEditForm()
local l_cHtml := ""
local l_cTextName
local l_cDescription
local l_cTextWebSite

l_cTextName    := hb_HGetDef(::p_FieldValues,"name","")
l_cDescription := nvl(hb_HGetDef(::p_FieldValues,"description",""),"")
l_cTextWebSite := hb_HGetDef(::p_FieldValues,"website","")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Companies</span>]   //navbar-text
        
        l_cHtml += [<button onclick="CallHB('Cancel');return false;"                             class="btn btn-primary rounded ms-3">Cancel</button>]
        l_cHtml += [<button onclick="CallHB('SaveChanges^'+$('form').serialize());return false;" class="btn btn-primary rounded ms-3">Save</button>]
        l_cHtml += [<button onclick="return false;"                                              class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]

    l_cHtml += [</div>]
    
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3" id="LastError"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+PrepFieldForValue(l_cTextName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="4" cols="80">]+PrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Website</td>]
            l_cHtml += [<td class="pb-3"><input type="url" name="TextWebSite" id="TextWebSite" value="]+PrepFieldForValue(l_cTextWebSite)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]


    l_cHtml += [</table>]

l_cHtml += [</div>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
method OnOpenWindow()
local l_nBackendType
local l_cBackendType
local l_cServer
local l_cODBCDriver
local l_nPort
local l_cUser
local l_nPasswordStorage
local l_cPasswordConfigKey
local l_cPasswordEnvVarName
local l_cDatabase
local l_cPassword
local l_hSchema

l_nBackendType        := val(v_oWindowManager:GetAppConfig("BackendType"))
l_cServer             := v_oWindowManager:GetAppConfig("Server")
l_cODBCDriver         := v_oWindowManager:GetAppConfig("ODBCDriver")
l_nPort               := val(v_oWindowManager:GetAppConfig("Port"))
l_cUser               := v_oWindowManager:GetAppConfig("User")
l_nPasswordStorage    := val(v_oWindowManager:GetAppConfig("PasswordStorage"))
l_cPasswordConfigKey  := v_oWindowManager:GetAppConfig("PasswordConfigKey")
l_cPasswordEnvVarName := v_oWindowManager:GetAppConfig("PasswordEnvVarName")
l_cDatabase           := v_oWindowManager:GetAppConfig("Database")

do case
case l_nPasswordStorage == 1  //In config.txt
    l_cPassword := l_cPasswordConfigKey
case l_nPasswordStorage == 2  //In Environment Variable
    l_cPassword := hb_GetEnv(l_cPasswordEnvVarName,"")
otherwise
    l_cPassword := ""
endcase

do case
case l_nBackendType == 1
    l_cBackendType := "MariaDB"
    if empty(l_cODBCDriver)
        l_cODBCDriver := "MariaDB ODBC 3.1 Driver"
    endif

case l_nBackendType == 2
    l_cBackendType := "MySQL"
    if empty(l_cODBCDriver)
        l_cODBCDriver := "MySQL ODBC 8.0 Unicode Driver"
    endif

case l_nBackendType == 3
    l_cBackendType := "PostgreSQL"
    if empty(l_cODBCDriver)
        l_cODBCDriver := "PostgreSQL ODBC Driver(UNICODE)"  // Under Windows this should be the default driver name
    endif

otherwise
    l_cODBCDriver  := ""
    l_cBackendType := ""

endcase

if empty(l_nPort)
    l_nPort := nil
endif

::p_o_SQLConnection := hb_SQLConnect(l_cBackendType,;
                                    l_cODBCDriver,;
                                    l_cServer,;
                                    l_nPort,;
                                    l_cUser,;
                                    l_cPassword,;
                                    l_cDatabase,;
                                    "public";
                                    )

with object ::p_o_SQLConnection
    :PostgreSQLHBORMSchemaName  := "ORM"
    :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
    :SetPrimaryKeyFieldName("pk")
    if :Connect() >= 0

        l_hSchema := ;
{"public.company"=>{;   //Field Definition
   {"pk"         =>{,  "I",   0,  0,"N+"};
   ,"name"       =>{, "CV", 200,  0,};
   ,"description"=>{,  "M",   0,  0,"N"};
   ,"website"    =>{, "CV", 200,  0,"N"}};
   ,;   //Index Definition
   NIL};
}

        UpdateSchema(::p_o_SQLConnection,l_hSchema)
    else
        MyOutputDebugString("[Harbour] Failed to Connect to database - "+:GetErrorMessage())
        ::p_o_SQLConnection := NIL
    endif
endwith

return nil
//=================================================================================================================
method BuildWindowContent()
local l_cHtml
l_cHtml := GetWebPageHeader()

l_cHtml += [<body><form id="EntireForm">]

do case
case hb_IsNil(::p_o_SQLConnection)
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">Companies</span>]   //navbar-text
            l_cHtml += [<button onclick="CloseWebViewWindow();" class="btn btn-primary rounded ms-3">Close</button>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    l_cHtml += [<div class="m-3"><h2>Not connected to database</h2></div>]
        
case ::p_cMode == "List"
    l_cHtml += ::m_ListForm()

endcase

l_cHtml += [</form></body></html>]

::BuildWindowContentHTML := l_cHtml

return nil
//=================================================================================================================
method OnCloseWindow(par_nTerminationType)
if !IsNull(::p_o_SQLConnection)
    ::p_o_SQLConnection:Disconnect()
endif
return nil
//=================================================================================================================
