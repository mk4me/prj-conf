# przygotowanie do szukania
FIND_INIT(LIBTIFF libtiff)

# szukanie
FIND_SHARED(LIBTIFF "libtiff" "libtiff")

# skopiowanie
FIND_FINISH(LIBTIFF)

if(LIBTIFF_FOUND)
	if(WIN)
		FIND_PREREQUSITIES(LIBTIFF LIBTIFF_FOUND "ZLIB")
	elseif(UNIX)
		FIND_DEPENDENCIES(LIBTIFF LIBTIFF_FOUND "ZLIB")
	endif()
endif()