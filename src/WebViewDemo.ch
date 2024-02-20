#define BUILDVERSION "1.01"

#define ALLOW_DEVELOPER_TOOLS 1    // Should be 0 for not, 1 for yes. Setting to 1 will enable the browsers developers tools, like inspect.

#define INTERNAL_WEBSERVER_LOCALHOST_PORT 8003

#include "hbdyn.ch"
#include "hbclass.ch"
#include "hbthread.ch"

#include "hb_orm.ch"
#include "hb_el.ch"

#include "hbmemory.ch"

#define BOOTSTRAP_SCRIPT_VERSION     "5_0_2"
#define JQUERYUI_SCRIPT_VERSION      "1_12_1_NoTooltip"
#define JQUERY_SCRIPT_VERSION        "3_6_0"

// #define CRLF chr(13)+chr(10)   //Already defined in hb_el.ch

memvar v_oQueue          //FIFO Queue of actions to be performed by main thread
memvar v_oWindowManager
memvar v_hConfig

#define POSITION_AND_SIZE_INDEX_TOP    1
#define POSITION_AND_SIZE_INDEX_LEFT   2
#define POSITION_AND_SIZE_INDEX_WIDTH  3
#define POSITION_AND_SIZE_INDEX_HEIGHT 4
