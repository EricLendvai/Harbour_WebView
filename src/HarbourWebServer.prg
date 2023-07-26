
// IMPORTANT NOTE:

// This mini web server can provide static files as HTTP GET request only, with no sessions. It is used to work around the inability of most webview browsers to render images and get .css and .js files referred in a local folder.

// Harbour Multithreading info
// http://harbourlanguage.blogspot.com/2010/04/harbour-multi-thread.html

// The following code was created using the following as its base: https://github.com/harbour/core/tree/master/contrib/hbhttpd
// That code has the following: Copyright 2009 Mindaugas Kavaliauskas <dbtopas / at / dbtopas.lt>
// But was missing a license.  Since it was published on Github it had to follow its terms-of-service, which in the case of a lack of explicit license any user can fork the code and modify it.
//  https://docs.github.com/en/site-policy/github-terms/github-terms-of-service      	5. License Grant to Other Users

// Changes are Copyright (c) 2023 Eric Lendvai, Federal Way, WA, USA, MIT License

#include "hbclass.ch"
#include "hbthread.ch"
#include "error.ch"
#include "hbsocket.ch"

#define THREAD_COUNT_PREALLOC   3
#define THREAD_COUNT_MAX        50
#define SESSION_TIMEOUT         600

#define CR_LF Chr(13)+Chr(10)

static s_lWebServerStop
static s_pWebServerMutexQueue

memvar v_hServer
memvar t_cResult
memvar t_aHeader
memvar t_nStatusCode
memvar t_aSessionData

//=================================================================================================================
function WebServerThread(par_cIP,par_nPort,par_cWebSiteRootFolder)

local l_aThread
local l_nSocketHandle
local l_nThreadCounter
local l_hSocket
local l_nJobs
local l_nWorkers

?"Will Listening on IP: ",par_cIP," - port: ",alltrim(str(par_nPort))

l_nSocketHandle := hb_socketOpen()
if empty(l_nSocketHandle)
    ?"Failed to Open Socket - error: "+hb_socketErrorString()
else
    if !hb_socketBind(l_nSocketHandle,{HB_SOCKET_AF_INET,par_cIP,par_nPort})
        ?"Failed to Bind Socket - error: "+hb_socketErrorString()
        hb_socketClose(l_nSocketHandle)
    else
        if !hb_socketListen(l_nSocketHandle)
            ?"Failed to Listen Socker - error: "+hb_socketErrorString()
            hb_socketClose(l_nSocketHandle)
        else
            ?"OK"

            s_lWebServerStop       := .f.
            s_pWebServerMutexQueue := hb_mutexCreate()

            l_aThread := {}
            for l_nThreadCounter := 1 to THREAD_COUNT_PREALLOC
                // AAdd(l_aThread, hb_threadStart(HB_THREAD_INHERIT_PUBLIC,@ProcessConnection(),l_nThreadCounter))
                AAdd(l_aThread, hb_threadStart(@ProcessConnection(),par_cWebSiteRootFolder))
            endfor

            s_lWebServerStop := .f.

            do while .t.
                if Empty( l_hSocket := hb_socketAccept(l_nSocketHandle,, 1000 ) )   // Will happen at least onces a second
                    if hb_socketGetError() == HB_SOCKET_ERR_TIMEOUT
                        if hb_FileExists("stop.mrk")
                            s_lWebServerStop := .t.
                            FErase("stop.mrk")
                        endif

                        if s_lWebServerStop
                            exit
                        endif
                    else
                        ?"[error] Accept error: " + hb_socketErrorString()
                    endif
                else
                    IF hb_mutexQueueInfo( s_pWebServerMutexQueue, @l_nWorkers, @l_nJobs ) .AND. ;
                            Len( l_aThread ) < THREAD_COUNT_MAX .AND. ;
                            l_nJobs >= l_nWorkers
                        // AAdd( l_aThread, hb_threadStart( HB_THREAD_INHERIT_PUBLIC, @ProcessConnection(), Self ) )
                        AAdd( l_aThread, hb_threadStart(@ProcessConnection(),par_cWebSiteRootFolder) )
                    endif
                    hb_mutexNotify( s_pWebServerMutexQueue, l_hSocket )
                endif
            enddo

            hb_socketClose(l_nSocketHandle)

            /* End child threads */
            AEval( l_aThread, {|| hb_mutexNotify( s_pWebServerMutexQueue, NIL ) } )
            AEval( l_aThread, {| h | hb_threadJoin( h ) } )

        endif
    endif
endif

return nil
//=================================================================================================================
STATIC FUNCTION ProcessConnection(par_cWebSiteRootFolder)

   LOCAL l_hSocket, cRequest, aI, nLen, nErr, nTime, nReqLen, cBuf, aServer

//    ErrorBlock( {| o | UErrorHandler( o, oServer ) } )

   PRIVATE v_hServer
   PRIVATE t_cResult
   PRIVATE t_aHeader
   PRIVATE t_nStatusCode
   PRIVATE t_aSessionData


//    httpd := oServer

   /* main worker thread loop */
   DO WHILE .T.
      hb_mutexSubscribe( s_pWebServerMutexQueue,, @l_hSocket )
      IF l_hSocket == NIL
         EXIT
      ENDIF

      /* Prepare server variable and clone it for every query,
         because request handler script can ruin variable value */
      aServer := { => }
      IF ! Empty( aI := hb_socketGetPeerName( l_hSocket ) )
         aServer[ "REMOTE_ADDR" ] := aI[ 2 ]
         aServer[ "REMOTE_HOST" ] := aServer[ "REMOTE_ADDR" ] // no reverse DNS
         aServer[ "REMOTE_PORT" ] := aI[ 3 ]
      ENDIF
      IF ! Empty( aI := hb_socketGetSockName( l_hSocket ) )
         aServer[ "SERVER_ADDR" ] := aI[ 2 ]
         aServer[ "SERVER_PORT" ] := aI[ 3 ]
      ENDIF

      /* loop for processing connection */

      /* Set cRequest to empty string here. This enables request pipelining */
      cRequest := ""
      DO WHILE !s_lWebServerStop

         /* receive query header */
         nLen := 1
         nTime := hb_MilliSeconds()
         cBuf := Space( 4096 )
         DO WHILE At( CR_LF + CR_LF, cRequest ) == 0
            nLen := hb_socketRecv( l_hSocket, @cBuf,,, 1000 )
            IF nLen < 0
                nErr := hb_socketGetError()
            ENDIF

            IF nLen > 0
               cRequest += hb_BLeft( cBuf, nLen )
            ELSEIF nLen == 0
               /* connection closed */
               EXIT
            ELSE
               /* nLen == -1  socket error */
               IF nErr == HB_SOCKET_ERR_TIMEOUT
                  IF ( hb_MilliSeconds() - nTime ) > 1000 * 30 .OR. s_lWebServerStop
                    //  Eval( oServer:hConfig[ "Trace" ], "receive timeout", l_hSocket )
                     EXIT
                  ENDIF
               ELSE
                //   Eval( oServer:hConfig[ "Trace" ], "receive error:", nErr, hb_socketErrorString( nErr ) )
                  EXIT
               ENDIF
            ENDIF
         ENDDO

         IF nLen <= 0 .OR. s_lWebServerStop
            EXIT
         ENDIF

         v_hServer := hb_HClone( aServer )
        //  v_get    := { => }
        //  v_post   := { => }
        //  v_cookie := { => }

         t_cResult := ""
         t_aHeader := {}
         t_nStatusCode := 200
         t_aSessionData := NIL

        //  Eval( oServer:hConfig[ "Trace" ], Left( cRequest, At( CR_LF + CR_LF, cRequest ) + 1 ) )

         nReqLen := ParseRequestHeader( @cRequest )
         IF nReqLen == NIL
            USetStatusCode( 400 )
            UAddHeader( "Connection", "close" )
         ELSE

            /* receive query body */
            nLen := 1
            nTime := hb_MilliSeconds()
            cBuf := Space( 4096 )
            DO WHILE Len( cRequest ) < nReqLen
                nLen := hb_socketRecv( l_hSocket, @cBuf,,, 1000 )
                IF nLen < 0
                    nErr := hb_socketGetError()
                ENDIF

               IF nLen > 0
                  cRequest += hb_BLeft( cBuf, nLen )
               ELSEIF nLen == 0
                  /* connection closed */
                  EXIT
               ELSE
                  /* nLen == -1  socket error */
                  IF nErr == HB_SOCKET_ERR_TIMEOUT
                     IF ( hb_MilliSeconds() - nTime ) > 1000 * 120 .OR. s_lWebServerStop
                        // Eval( oServer:hConfig[ "Trace" ], "receive timeout", l_hSocket )
                        EXIT
                     ENDIF
                  ELSE
                    //  Eval( oServer:hConfig[ "Trace" ], "receive error:", nErr, hb_socketErrorString( nErr ) )
                     EXIT
                  ENDIF
               ENDIF
            ENDDO

            IF nLen <= 0 .OR. s_lWebServerStop
               EXIT
            ENDIF

            // Eval( oServer:hConfig[ "Trace" ], cRequest )
            // ParseRequestBody( Left( cRequest, nReqLen ) )
            cRequest := SubStr( cRequest, nReqLen + 1 )

            /* Deal with supported protocols and methods */
            IF !( Left( v_hServer[ "SERVER_PROTOCOL" ], 5 ) == "HTTP/" )
               USetStatusCode( 400 ) /* Bad request */
               UAddHeader( "Connection", "close" )
            ELSEIF ! SubStr( v_hServer[ "SERVER_PROTOCOL" ], 6 ) $ "1.0 1.1"
               USetStatusCode( 505 ) /* HTTP version not supported */
            ELSEIF ! v_hServer[ "REQUEST_METHOD" ] $ "GET"
               USetStatusCode( 501 ) /* Not implemented */
            ELSE
               IF v_hServer[ "SERVER_PROTOCOL" ] == "HTTP/1.1"
                  IF Lower( v_hServer[ "HTTP_CONNECTION" ] ) == "close"
                     UAddHeader( "Connection", "close" )
                  ELSE
                     UAddHeader( "Connection", "keep-alive" )
                  ENDIF
               ENDIF

               /* Do the job */
               ProcessRequest(par_cWebSiteRootFolder)
            ENDIF
         ENDIF /* request header ok */

         // Send response
         cBuf := MakeResponse()

         DO WHILE hb_BLen( cBuf ) > 0 .AND. ! s_lWebServerStop
            nLen := hb_socketSend( l_hSocket, cBuf,,, 1000 )
            IF nLen < 0
                nErr := hb_socketGetError()
            ENDIF

            IF nLen < 0
            //    Eval( oServer:hConfig[ "Trace" ], "send error:", nErr, hb_socketErrorString( nErr ) )
               EXIT
            ELSEIF nLen > 0
               cBuf := hb_BSubStr( cBuf, nLen + 1 )
            ENDIF
         ENDDO

         IF s_lWebServerStop
            EXIT
         ENDIF

         IF Lower( UGetHeader( "Connection" ) ) == "close" .OR. v_hServer[ "SERVER_PROTOCOL" ] == "HTTP/1.0"
            EXIT
         ENDIF
      ENDDO

    //   Eval( oServer:hConfig[ "Trace" ], "Close connection1", l_hSocket )
      hb_socketShutdown( l_hSocket )
      hb_socketClose( l_hSocket )
   ENDDO

   RETURN 0
//=================================================================================================================
STATIC PROCEDURE ProcessRequest(par_cWebSiteRootFolder)

   LOCAL xRet
   local l_cFileName

     l_cFileName := v_hServer[ "SCRIPT_NAME" ]
    l_cFileName := substr(l_cFileName,2)

    // MyOutputDebugString('[Harbour] v_hServer[ "SCRIPT_NAME" ] = '+v_hServer[ "SCRIPT_NAME" ])
    MyOutputDebugString("[Harbour] File to show: "+par_cWebSiteRootFolder+l_cFileName)

    if hb_FileExists(par_cWebSiteRootFolder+l_cFileName)
         xRet := UProcFiles( par_cWebSiteRootFolder+l_cFileName, .F. )
         IF HB_ISSTRING( xRet )
            UWrite( xRet )
        //  ELSEIF HB_ISHASH( xRet )
        //     UWrite( UParse( xRet ) )
         ENDIF

   ELSE
      USetStatusCode( 404 )
   ENDIF
//    Eval( oServer:hConfig[ "Trace" ], "ProcessRequest time:", hb_ntos( hb_MilliSeconds() - nT ), "ms" )
   RETURN
//=================================================================================================================
STATIC PROCEDURE UProcFiles( cFileName, lIndex )

   LOCAL nI, cI, tDate, tHDate

   IF ! HB_ISLOGICAL( lIndex )
      lIndex := .F.
   ENDIF

   cFileName := StrTran( cFileName, "//", "/" )

   // Security
   IF "/../" $ cFileName
      USetStatusCode( 403 )
      RETURN
   ENDIF

   IF hb_FileExists( UOsFileName( cFileName ) )
      IF hb_HHasKey( v_hServer, "HTTP_IF_MODIFIED_SINCE" ) .AND. ;
            HttpDateUnformat( v_hServer[ "HTTP_IF_MODIFIED_SINCE" ], @tHDate ) .AND. ;
            hb_FGetDateTime( UOsFileName( cFileName ), @tDate ) .AND. ;
            tDate <= tHDate
         USetStatusCode( 304 )
      ELSEIF hb_HHasKey( v_hServer, "HTTP_IF_UNMODIFIED_SINCE" ) .AND. ;
            HttpDateUnformat( v_hServer[ "HTTP_IF_UNMODIFIED_SINCE" ], @tHDate ) .AND. ;
            hb_FGetDateTime( UOsFileName( cFileName ), @tDate ) .AND. ;
            tDate > tHDate
         USetStatusCode( 412 )
      ELSE
         IF ( nI := RAt( ".", cFileName ) ) > 0
            SWITCH Lower( SubStr( cFileName, nI + 1 ) )
            CASE "css";                                 cI := "text/css";  EXIT
            CASE "htm";   CASE "html";                  cI := "text/html";  EXIT
            CASE "txt";   CASE "text";  CASE "asc"
            CASE "c";     CASE "h";     CASE "cpp"
            CASE "hpp";   CASE "log";                   cI := "text/plain";  EXIT
            CASE "rtf";                                 cI := "text/rtf";  EXIT
            CASE "xml";                                 cI := "text/xml";  EXIT
            CASE "bmp";                                 cI := "image/bmp";  EXIT
            CASE "gif";                                 cI := "image/gif";  EXIT
            CASE "jpg";   CASE "jpe";   CASE "jpeg";    cI := "image/jpeg";  EXIT
            CASE "png";                                 cI := "image/png";   EXIT
            CASE "tif";   CASE "tiff";                  cI := "image/tiff";  EXIT
            CASE "djv";   CASE "djvu";                  cI := "image/vnd.djvu";  EXIT
            CASE "ico";                                 cI := "image/x-icon";  EXIT
            CASE "xls";                                 cI := "application/excel";  EXIT
            CASE "doc";                                 cI := "application/msword";  EXIT
            CASE "pdf";                                 cI := "application/pdf";  EXIT
            CASE "ps";    CASE "eps";                   cI := "application/postscript";  EXIT
            CASE "ppt";                                 cI := "application/powerpoint";  EXIT
            CASE "bz2";                                 cI := "application/x-bzip2";  EXIT
            CASE "gz";                                  cI := "application/x-gzip";  EXIT
            CASE "tgz";                                 cI := "application/x-gtar";  EXIT
            CASE "js";                                  cI := "application/x-javascript";  EXIT
            CASE "tar";                                 cI := "application/x-tar";  EXIT
            CASE "tex";                                 cI := "application/x-tex";  EXIT
            CASE "zip";                                 cI := "application/zip";  EXIT
            CASE "midi";                                cI := "audio/midi";  EXIT
            CASE "mp3";                                 cI := "audio/mpeg";  EXIT
            CASE "wav";                                 cI := "audio/x-wav";  EXIT
            CASE "qt";    CASE "mov";                   cI := "video/quicktime";  EXIT
            CASE "avi";                                 cI := "video/x-msvideo";  EXIT
            OTHERWISE
               cI := "application/octet-stream"
            ENDSWITCH
         ELSE
            cI := "application/octet-stream"
         ENDIF
         UAddHeader( "Content-Type", cI )

         IF hb_FGetDateTime( UOsFileName( cFileName ), @tDate )
            UAddHeader( "Last-Modified", HttpDateFormat( tDate ) )
         ENDIF

         UWrite( hb_MemoRead( UOsFileName( cFileName ) ) )
      ENDIF
   ELSE
      USetStatusCode( 404 )
   ENDIF

   RETURN
//=================================================================================================================
STATIC PROCEDURE UWrite( cString )

   t_cResult += cString

   RETURN
//=================================================================================================================
STATIC FUNCTION UOsFileName( cFileName )

   IF ! hb_ps() == "/"
      RETURN StrTran( cFileName, "/", hb_ps() )
   ENDIF

   RETURN cFileName
//=================================================================================================================
STATIC PROCEDURE USetStatusCode( nStatusCode )

   t_nStatusCode := nStatusCode

   RETURN
//=================================================================================================================
STATIC PROCEDURE UAddHeader( cType, cValue )

   LOCAL nI

   IF ( nI := AScan( t_aHeader, {| x | Upper( x[ 1 ] ) == Upper( cType ) } ) ) > 0
      t_aHeader[ nI ][ 2 ] := cValue
   ELSE
      AAdd( t_aHeader, { cType, cValue } )
   ENDIF

   RETURN
//=================================================================================================================
STATIC FUNCTION MakeResponse()

   LOCAL cRet, cStatus

   IF UGetHeader( "Content-Type" ) == NIL
      UAddHeader( "Content-Type", "text/html" )
   ENDIF
   UAddHeader( "Date", HttpDateFormat( hb_DateTime() ) )

   cRet := iif( v_hServer[ "SERVER_PROTOCOL" ] == "HTTP/1.0", "HTTP/1.0 ", "HTTP/1.1 " )
   SWITCH t_nStatusCode
   CASE 100 ; cStatus := "100 Continue"                        ;  EXIT
   CASE 101 ; cStatus := "101 Switching Protocols"             ;  EXIT
   CASE 200 ; cStatus := "200 OK"                              ;  EXIT
   CASE 201 ; cStatus := "201 Created"                         ;  EXIT
   CASE 202 ; cStatus := "202 Accepted"                        ;  EXIT
   CASE 203 ; cStatus := "203 Non-Authoritative Information"   ;  EXIT
   CASE 204 ; cStatus := "204 No Content"                      ;  EXIT
   CASE 205 ; cStatus := "205 Reset Content"                   ;  EXIT
   CASE 206 ; cStatus := "206 Partial Content"                 ;  EXIT
   CASE 300 ; cStatus := "300 Multiple Choices"                ;  EXIT
   CASE 301 ; cStatus := "301 Moved Permanently"               ;  EXIT
   CASE 302 ; cStatus := "302 Found"                           ;  EXIT
   CASE 303 ; cStatus := "303 See Other"                       ;  EXIT
   CASE 304 ; cStatus := "304 Not Modified"                    ;  EXIT
   CASE 305 ; cStatus := "305 Use Proxy"                       ;  EXIT
   CASE 307 ; cStatus := "307 Temporary Redirect"              ;  EXIT
   CASE 400 ; cStatus := "400 Bad Request"                     ;  EXIT
   CASE 401 ; cStatus := "401 Unauthorized"                    ;  EXIT
   CASE 402 ; cStatus := "402 Payment Required"                ;  EXIT
   CASE 403 ; cStatus := "403 Forbidden"                       ;  EXIT
   CASE 404 ; cStatus := "404 Not Found"                       ;  EXIT
   CASE 405 ; cStatus := "405 Method Not Allowed"              ;  EXIT
   CASE 406 ; cStatus := "406 Not Acceptable"                  ;  EXIT
   CASE 407 ; cStatus := "407 Proxy Authentication Required"   ;  EXIT
   CASE 408 ; cStatus := "408 Request Timeout"                 ;  EXIT
   CASE 409 ; cStatus := "409 Conflict"                        ;  EXIT
   CASE 410 ; cStatus := "410 Gone"                            ;  EXIT
   CASE 411 ; cStatus := "411 Length Required"                 ;  EXIT
   CASE 412 ; cStatus := "412 Precondition Failed"             ;  EXIT
   CASE 413 ; cStatus := "413 Request Entity Too Large"        ;  EXIT
   CASE 414 ; cStatus := "414 Request-URI Too Long"            ;  EXIT
   CASE 415 ; cStatus := "415 Unsupprted Media Type"           ;  EXIT
   CASE 416 ; cStatus := "416 Requested Range Not Satisfiable" ;  EXIT
   CASE 417 ; cStatus := "417 Expectation Failed"              ;  EXIT
   CASE 500 ; cStatus := "500 Internal Server Error"           ;  EXIT
   CASE 501 ; cStatus := "501 Not Implemented"                 ;  EXIT
   CASE 502 ; cStatus := "502 Bad Gateway"                     ;  EXIT
   CASE 503 ; cStatus := "503 Service Unavailable"             ;  EXIT
   CASE 504 ; cStatus := "504 Gateway Timeout"                 ;  EXIT
   CASE 505 ; cStatus := "505 HTTP Version Not Supported"      ;  EXIT
   OTHERWISE; cStatus := "500 Internal Server Error"
   ENDSWITCH

   cRet += cStatus + CR_LF
   IF t_nStatusCode != 200
      t_cResult := "<html><body><h1>" + cStatus + "</h1></body></html>"
   ENDIF
   UAddHeader( "Content-Length", hb_ntos( Len( t_cResult ) ) )
   AEval( t_aHeader, {| x | cRet += x[ 1 ] + ": " + x[ 2 ] + CR_LF } )
   cRet += CR_LF
//    Eval( hConfig[ "Trace" ], cRet )
   cRet += t_cResult

   RETURN cRet
//=================================================================================================================
STATIC FUNCTION UGetHeader( cType )

   LOCAL nI

   IF ( nI := AScan( t_aHeader, {| x | Upper( x[ 1 ] ) == Upper( cType ) } ) ) > 0
      RETURN t_aHeader[ nI ][ 2 ]
   ENDIF

   RETURN NIL
//=================================================================================================================
STATIC FUNCTION ParseRequestHeader( cRequest )

   LOCAL aRequest, aLine, nI, nJ, cI, nContentLength := 0   //, nK

   nI := At( CR_LF + CR_LF, cRequest )
   aRequest := hb_ATokens( Left( cRequest, nI - 1 ), CR_LF )
   cRequest := SubStr( cRequest, nI + 4 )

   aLine := hb_ATokens( aRequest[ 1 ], " " )

   v_hServer[ "REQUEST_ALL" ] := aRequest[ 1 ]
   IF Len( aLine ) == 3 .AND. Left( aLine[ 3 ], 5 ) == "HTTP/"
      v_hServer[ "REQUEST_METHOD" ] := aLine[ 1 ]
      v_hServer[ "REQUEST_URI" ] := aLine[ 2 ]
      v_hServer[ "SERVER_PROTOCOL" ] := aLine[ 3 ]
   ELSE
      v_hServer[ "REQUEST_METHOD" ] := aLine[ 1 ]
      v_hServer[ "REQUEST_URI" ] := iif( Len( aLine ) >= 2, aLine[ 2 ], "" )
      v_hServer[ "SERVER_PROTOCOL" ] := iif( Len( aLine ) >= 3, aLine[ 3 ], "" )
      RETURN NIL
   ENDIF

   // Fix invalid queries: bind to root
   IF !( Left( v_hServer[ "REQUEST_URI" ], 1 ) == "/" )
      v_hServer[ "REQUEST_URI" ] := "/" + v_hServer[ "REQUEST_URI" ]
   ENDIF

   IF ( nI := At( "?", v_hServer[ "REQUEST_URI" ] ) ) > 0
      v_hServer[ "SCRIPT_NAME" ] := Left( v_hServer[ "REQUEST_URI" ], nI - 1 )
      v_hServer[ "QUERY_STRING" ] := SubStr( v_hServer[ "REQUEST_URI" ], nI + 1 )
   ELSE
      v_hServer[ "SCRIPT_NAME" ] := v_hServer[ "REQUEST_URI" ]
      v_hServer[ "QUERY_STRING" ] := ""
   ENDIF

   v_hServer[ "HTTP_ACCEPT" ] := ""
   v_hServer[ "HTTP_ACCEPT_CHARSET" ] := ""
   v_hServer[ "HTTP_ACCEPT_ENCODING" ] := ""
   v_hServer[ "HTTP_ACCEPT_LANGUAGE" ] := ""
   v_hServer[ "HTTP_CONNECTION" ] := ""
   v_hServer[ "HTTP_HOST" ] := ""
   v_hServer[ "HTTP_KEEP_ALIVE" ] := ""
   v_hServer[ "HTTP_REFERER" ] := ""
   v_hServer[ "HTTP_USER_AGENT" ] := ""

   FOR nI := 2 TO Len( aRequest )
      IF aRequest[ nI ] == ""
         EXIT
      ELSEIF ( nJ := At( ":", aRequest[ nI ] ) ) > 0
         cI := AllTrim( SubStr( aRequest[ nI ], nJ + 1 ) )
         SWITCH Upper( Left( aRequest[ nI ], nJ - 1 ) )
         CASE "COOKIE"
            // v_hServer[ "HTTP_COOKIE" ] := cI
            // IF ( nK := At( ";", cI ) ) == 0
            //    nK := Len( RTrim( cI ) )
            // ENDIF
            // cI := Left( cI, nK )
            // IF ( nK := At( "=", cI ) ) > 0
            //    /* cookie names are case insensitive, uppercase it */
            //    v_cookie[ Upper( Left( cI, nK - 1 ) ) ] := SubStr( cI, nK + 1 )
            // ENDIF
            EXIT
         CASE "CONTENT-LENGTH"
            nContentLength := Val( cI )
            EXIT
         CASE "CONTENT-TYPE"
            v_hServer[ "CONTENT_TYPE" ] := cI
            EXIT
         OTHERWISE
            v_hServer[ "HTTP_" + StrTran( Upper( Left( aRequest[ nI ], nJ - 1 ) ), "-", "_" ) ] := cI
            EXIT
         ENDSWITCH
      ENDIF
   NEXT
//    IF ! v_hServer[ "QUERY_STRING" ] == ""
//       FOR EACH cI IN hb_ATokens( v_hServer[ "QUERY_STRING" ], "&" )
//          IF ( nI := At( "=", cI ) ) > 0
//             v_get[ UUrlDecode( Left( cI, nI - 1 ) ) ] := UUrlDecode( SubStr( cI, nI + 1 ) )
//          ELSE
//             v_get[ UUrlDecode( cI ) ] := NIL
//          ENDIF
//       NEXT
//    ENDIF

   RETURN nContentLength
//=================================================================================================================
STATIC FUNCTION HttpDateUnformat( cDate, tDate )

   LOCAL nMonth, tI

   // TODO: support outdated compatibility format RFC2616
   IF Len( cDate ) == 29 .AND. Right( cDate, 4 ) == " GMT" .AND. SubStr( cDate, 4, 2 ) == ", "
      nMonth := AScan( { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", ;
         "Oct", "Nov", "Dec" }, SubStr( cDate, 9, 3 ) )
      IF nMonth > 0
         tI := hb_SToT( SubStr( cDate, 13, 4 ) + PadL( nMonth, 2, "0" ) + SubStr( cDate, 6, 2 ) + StrTran( SubStr( cDate, 18, 8 ), ":" ) )
         IF ! Empty( tI )
            tDate := tI + hb_UTCOffset() / ( 3600 * 24 )
            RETURN .T.
         ENDIF
      ENDIF
   ENDIF

   RETURN .F.
//=================================================================================================================
STATIC FUNCTION HttpDateFormat( tDate )

   tDate -= hb_UTCOffset() / ( 3600 * 24 )

   RETURN ;
      { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }[ DoW( tDate ) ] + ", " + ;
      PadL( Day( tDate ), 2, "0" ) + " " + ;
      { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }[ Month( tDate ) ] + ;
      " " + PadL( Year( tDate ), 4, "0" ) + " " + hb_TToC( tDate, "", "HH:MM:SS" ) + " GMT" // FIXME: time zone
//=================================================================================================================
STATIC FUNCTION UUrlDecode( cString )

   LOCAL nI

   cString := StrTran( cString, "+", " " )
   nI := 1
   DO WHILE nI <= Len( cString )
      nI := hb_At( "%", cString, nI )
      IF nI == 0
         EXIT
      ENDIF
      IF Upper( SubStr( cString, nI + 1, 1 ) ) $ "0123456789ABCDEF" .AND. ;
            Upper( SubStr( cString, nI + 2, 1 ) ) $ "0123456789ABCDEF"
         cString := Stuff( cString, nI, 3, hb_HexToStr( SubStr( cString, nI + 1, 2 ) ) )
      ENDIF
      nI++
   ENDDO

   RETURN cString
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
