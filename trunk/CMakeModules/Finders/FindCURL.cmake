# przygotowanie do szukania
FIND_INIT(CURL curl)

# szukanie
FIND_SHARED(CURL_LIBCURL "libcurl<d,?><_imp,?>" "libcurl")

# skopiowanie
FIND_FINISH(CURL)

if (CURL_LIBCURL_FOUND)
	set(CURL_FOUND 1)
	if (WIN32)
		set(CURL_COMPILER_DEFINITIONS _WINSOCKAPI_)
	elseif (UNIX)
		#include (CheckIncludeFile)
		#include (CheckIncludeFiles)
		#CHECK_INCLUDE_FILES("sys/socket.h" HAVE_SYS_SOCKET_H)
		set(CURL_COMPILER_DEFINITIONS HAVE_SYS_SOCKET_H)
	endif()
 endif()
