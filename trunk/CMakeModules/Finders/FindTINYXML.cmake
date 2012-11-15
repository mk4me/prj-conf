# przygotowanie do szukania
FIND_INIT(TINYXML tinyxml)

# szukanie
if (WIN32)
	FIND_STATIC(TINYXML "tinyxmlSTL")
elseif (UNIX)
	FIND_GLOB(TINYXML "*.*" "libtinyxml.so.?.*")
endif()
# koniec
FIND_FINISH(TINYXML)

set(TINYXML_COMPILER_DEFINITIONS TIXML_USE_STL)
