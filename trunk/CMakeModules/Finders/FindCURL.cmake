# przygotowanie do szukania
FIND_INIT(CURL curl)

# szukanie
FIND_SHARED(CURL "libcurl<d,?><_imp,?>" "libcurl")

# skopiowanie
FIND_FINISH(CURL)

if(UNIX)
	include (CheckIncludeFiles)
	CHECK_INCLUDE_FILES("sys/socket.h" HAVE_SYS_SOCKET_H)
	if(NOT HAVE_SYS_SOCKET_H)
		set(LIBRARY_CURL_FOUND 0)
	endif()
endif()

if (LIBRARY_CURL_FOUND)
	if (WIN32)
		set(CURL_COMPILER_DEFINITIONS _WINSOCKAPI_)
		FIND_PREREQUISITES(CURL LIBRARY_CURL_FOUND "OPENSSL")
	elseif (UNIX)
		set(CURL_COMPILER_DEFINITIONS HAVE_SYS_SOCKET_H)
		FIND_DEPENDENCIES(CURL LIBRARY_CURL_FOUND "OPENSSL")
	endif()
 endif()
