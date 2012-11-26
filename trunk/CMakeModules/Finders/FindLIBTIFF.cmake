# przygotowanie do szukania
FIND_INIT(LIBTIFF libtiff)

# szukanie
FIND_SHARED(LIBTIFF "libtiff" "libtiff")

# skopiowanie
FIND_FINISH(LIBTIFF)

if(LIBTIFF_FOUND)
	if(WIN32)
		FIND_PREREQUISITES(LIBTIFF LIBTIFF_FOUND "ZLIB")
	elseif(UNIX)
		FIND_DEPENDENCIES(LIBTIFF LIBTIFF_FOUND "ZLIB")
	endif()
endif()