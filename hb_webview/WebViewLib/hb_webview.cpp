#include "hb_webview.h"

#include "webview.h"

//#include <iostream>

extern "C"
{
    float add(float a, float b)
    {
        return (a + b);
    }

    int testwebview()
    {
    webview::webview w(true, nullptr);
    w.set_title("Example 5");
    w.set_size(480, 320, WEBVIEW_HINT_NONE);
    w.set_size(180, 120, WEBVIEW_HINT_MIN);
    w.bind("noop", [](std::string s) -> std::string {
        //std::cout << s << std::endl;
        return s;
    });
    w.bind("add", [](std::string s) -> std::string {
        auto a = std::stoi(webview::json_parse(s, "", 0));
        auto b = std::stoi(webview::json_parse(s, "", 1));
        return std::to_string(a + b);
    });
    w.navigate(R"(data:text/html,
        <!doctype html>
        <html>
            <body>hello1</body>
            <script>
                window.onload = function() {
                document.body.innerText = `hello2, ${navigator.userAgent}`;
                noop('hello3').then(function(res) {
                    console.log('noop res', res);
                });
                add(1, 2).then(function(res) {
                    console.log('add res', res);
                });
                };
            </script>
        </html>
    )");
    w.run();
    return 0;
    }
}