# przygotowanie do szukania
FIND_INIT(OPENSSL openssl)

if(WIN)
	FIND_SHARED(OPENSSL_SSLEAY32 "ssleay32" "ssleay32")
	FIND_SHARED(OPENSSL_LIBEAY32 "libeay32" "libeay32")
elseif(UNIX)
	FIND_SHARED(OPENSSL_LIBSSL "libssl" "libssl")
	FIND_SHARED(OPENSSL_LIBCRYPTO "libcrypto" "libcrypto")
endif()

FIND_FINISH(OPENSSL)

if(WIN)

	if(OPENSSL_SSLEAY32 AND OPENSSL_LIBEAY32)
		set(OPENSSL_FOUND 1)
	else()
		set(OPENSSL_FOUND 0)
	endif()

elseif(UNIX)
	if(OPENSSL_LIBSSL AND OPENSSL_LIBCRYPTO)
		set(OPENSSL_FOUND 1)
	else()
		set(OPENSSL_FOUND 0)
	endif()
endif()
# sprawdzenie
if (OPENSSL_FOUND)
	if(WIN)
		FIND_PREREQUSITIES(LIBTIFF OPENSSL_FOUND "ZLIB")
	elseif(UNIX)
		FIND_DEPENDENCIES(LIBTIFF OPENSSL_FOUND "ZLIB")
	endif()
	
endif()
