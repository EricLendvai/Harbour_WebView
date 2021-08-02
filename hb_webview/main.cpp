//Not Used. Switched to using main.c instead


#include <iostream>
#include <string>

#include "hb_webview.h"





int main(int argc, char** argv)
{
	std::cout << argv[0] << " Version 1" << '\n';


	std::cout << "using hb_webview lib:" << add(72.1f, 73.8f) << '\n';
	std::cout << "calling testwebview:" << testwebview() << '\n';



	return 0;
}
