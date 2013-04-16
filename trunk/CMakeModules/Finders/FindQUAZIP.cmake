# przygotowanie do szukania
FIND_INIT(QuaZip quazip)

# szukanie
FIND_SHARED(QuaZip "quazip" "quazip")

# skopiowanie
FIND_FINISH(QuaZip)

if(LIBRARY_QuaZip_FOUND)
	FIND_DEPENDENCIES(QuaZip LIBRARY_QuaZip_FOUND "QT;ZLIB" "QT_INCLUDE_DIR;QtCore")
endif()