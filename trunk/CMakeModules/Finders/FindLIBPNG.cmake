# przygotowanie do szukania
FIND_INIT(LIBPNG libpng)

# szukanie
FIND_SHARED(LIBPNG "libpng16<lib,?>" "libpng16<lib,?>")

# skopiowanie
FIND_FINISH(LIBPNG)

if(LIBRARY_LIBPNG_FOUND)
	if(WIN32)
		FIND_PREREQUISITES(LIBPNG LIBRARY_LIBPNG_FOUND "ZLIB")
	elseif(UNIX)
		FIND_DEPENDENCIES(LIBPNG LIBRARY_LIBPNG_FOUND "ZLIB")
	endif()
endif()