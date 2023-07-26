
//From Harbour Repo, MIT license since on Github with no license  contrib\hbgd\tests\cgi.prg
//Updated by Eric Lendvai, Federal Way, WA, USA
//Copyright 2004-2005 Francesco Saverio Giudice <info@fsgiudice.com>

//
// Decoding URL
// Can return both a string or a number
//

FUNCTION URLDecode( cStr )
    LOCAL cRet := "", i, cCar
    FOR i := 1 TO Len( cStr )
        cCar := substr(cStr,i,1)
        DO CASE
        CASE cCar == "+"
            cRet += " "
        CASE cCar == "%"
            i++
            cRet += Chr( hb_HexToNum( SubStr( cStr, i, 2 ) ) )
            i++
        OTHERWISE
            cRet += cCar
        ENDCASE
    NEXT

    RETURN cRet



FUNCTION URLEncode( cStr )
    LOCAL cRet := "", i, nVal, cCar

    FOR i := 1 TO Len( cStr )
        cCar := substr(cStr,i,1)
        DO CASE
        CASE cCar == " "
            cRet += "+"
        CASE cCar >= "A" .AND. cCar <= "Z"
            cRet += cCar
        CASE cCar >= "a" .AND. cCar <= "z"
            cRet += cCar
        CASE cCar >= "0" .AND. cCar <= "9"
            cRet += cCar
        OTHERWISE
            nVal := Asc( cCar )
            cRet += "%" + hb_NumToHex( nVal )
        ENDCASE
    NEXT

    RETURN cRet


//Functions below are from https://github.com/EricLendvai/DataWharf 
//Copyright (c) 2023 Eric Lendvai, Federal Way, WA, USA, MIT License
//=================================================================================================================
function PrepFieldForValue( par_FieldValue ) 
// for now calling vfp_StrReplace, which is case insensitive ready version of hb_StrReplace
return vfp_StrReplace(par_FieldValue,{;
                                        [&lt;]  => [&amp;lt;] ,;
                                        [&gt;]  => [&amp;gt;] ,;
                                        ["]     => [&quot;]   ,;
                                        [<]     => [&lt;]     ,;
                                        [>]     => [&gt;]     ,;
                                        chr(9)  => [&#9;]     ,;
                                        chr(13) => [&#13;]    ,;
                                        chr(10) => [];
                                     },,1)
//=================================================================================================================
function UpdateSchema(par_o_SQLConnection,par_hSchema)
local l_LastError := ""
local l_nMigrateSchemaResult := 0

if el_AUnpack(par_o_SQLConnection:MigrateSchema(par_hSchema),@l_nMigrateSchemaResult,,@l_LastError) > 0
    if l_nMigrateSchemaResult == 1
    endif
else
    if !empty(l_LastError)
        MyOutputDebugString("[Harbour] Database Migration Failed - "+l_LastError)
    endif
endif

return nil
//=================================================================================================================
function GetConfirmationModalFormsDelete()
local l_cHtml := ""

l_cHtml += [<div class="modal fade" id="ConfirmDeleteModal" tabindex="-1" aria-labelledby="ConfirmDeleteModalLabel" aria-hidden="true">]
l_cHtml +=   [<div class="modal-dialog">]
l_cHtml +=     [<div class="modal-content">]
l_cHtml +=       [<div class="modal-header">]
l_cHtml +=         [<h5 class="modal-title" id="ConfirmDeleteModalLabel">Confirm Delete</h5>]
l_cHtml +=         [<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>]
l_cHtml +=       [</div>]
l_cHtml +=       [<div class="modal-body">]
l_cHtml +=         [This action cannot be undone]
l_cHtml +=       [</div>]
l_cHtml +=       [<div class="modal-footer">]
// l_cHtml +=         [<button type="button" class="btn btn-danger" onclick="CallHB('Delete');return false;">Yes</button>]
l_cHtml +=         [<button type="button" class="btn btn-danger" onclick="CallHB('Delete');return false;" data-bs-dismiss="modal">Yes</button>]
l_cHtml +=         [<button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>]
l_cHtml +=       [</div>]
l_cHtml +=     [</div>]
l_cHtml +=   [</div>]
l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
function SanitizeInput(par_text)
local l_result := AllTrim(vfp_StrReplace(par_text,{chr(9)=>" "}))
l_result = vfp_StrReplace(l_result,{"<"="",">"=""})
return l_result
//=================================================================================================================
function SanitizeInputAlphaNumeric(par_cText)
return SanitizeInputWithValidChars(par_cText,[_01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ])
//=================================================================================================================
function SanitizeInputWithValidChars(par_text,par_cValidChars)
local l_result := []
local l_nPos
local l_cChar
for l_nPos := 1 to len(par_text)
    l_cChar := substr(par_text,l_nPos,1)
    if l_cChar $ par_cValidChars
        l_result += l_cChar
    endif
endfor
return l_result
//=================================================================================================================
function MultiLineTrim(par_cText)
local l_nPos := len(par_cText)

do while l_nPos > 0 .and. vfp_inlist(Substr(par_cText,l_nPos,1),chr(13),chr(10),chr(9),chr(32))
    l_nPos -= 1
enddo

return left(par_cText,l_nPos)
//=================================================================================================================
function TextToHTML(par_SourceText)
local l_Text

if hb_IsNull(par_SourceText)
    l_Text := ""
else
    l_Text := par_SourceText

    l_Text := vfp_strtran(l_Text,[&amp;],[&],-1,-1,1)
    l_Text := vfp_strtran(l_Text,[&],[&amp;])
    l_Text := vfp_strtran(l_Text,[<],[&lt;])
    l_Text := vfp_strtran(l_Text,[>],[&gt;])
    l_Text := vfp_strtran(l_Text,[  ],[ &nbsp;])
    l_Text := vfp_strtran(l_Text,chr(10),[])
    l_Text := vfp_strtran(l_Text,chr(13),[<br>])
endif

return l_Text
//=================================================================================================================
function hb_buildinfo()
#include "BuildInfo.txt"
return l_cBuildInfo
//=================================================================================================================
