# przygotowanie do szukania
FIND_INIT(LIBTIFF libtiff)

# szukanie
FIND_SHARED(LIBTIFF "libtiff_i" "libtiff")

if(WIN32)
	FIND_PREREQUISITES(LIBTIFF "ZLIB")
elseif(UNIX)
	FIND_DEPENDENCIES(LIBTIFF "ZLIB")
endif()

# skopiowanie
FIND_FINISH(LIBTIFF)