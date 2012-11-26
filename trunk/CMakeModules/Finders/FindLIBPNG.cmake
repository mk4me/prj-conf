# przygotowanie do szukania
FIND_INIT(LIBPNG libpng)

# szukanie
FIND_SHARED(LIBPNG "libpng15<lib,?>" "libpng15<lib,?>")

# skopiowanie
FIND_FINISH(LIBPNG)

if(LIBPNG_FOUND)
	if(WIN32)
		FIND_PREREQUISITES(LIBPNG LIBPNG_FOUND "ZLIB")
	elseif(UNIX)
		FIND_DEPENDENCIES(LIBPNG LIBPNG_FOUND "ZLIB")
	endif()
endif()