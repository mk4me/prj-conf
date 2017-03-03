# przygotowanie do szukania
FIND_INIT(OPENSSL openssl)

if(WIN32)
	FIND_SHARED(OPENSSL_SSLEAY32 "libssl" "libssl-1_1-x64")
	FIND_SHARED(OPENSSL_LIBEAY32 "libcrypto" "libcrypto-1_1-x64")
	FIND_PREREQUISITES(OPENSSL "ZLIB")
elseif(UNIX)
	FIND_SHARED(OPENSSL_LIBSSL "libssl" "libssl")
	FIND_SHARED(OPENSSL_LIBCRYPTO "libcrypto" "libcrypto")
	FIND_DEPENDENCIES(OPENSSL "ZLIB")
endif()

FIND_FINISH(OPENSSL)