# przygotowanie do szukania
FIND_INIT(QWT qwt)

# szukanie
FIND_SHARED(QWT "qwt" "qwt")

set(QWT_COMPILER_DEFINITIONS QWT_DLL)

# skopiowanie
FIND_FINISH(QWT)

if(LIBRARY_QWT_FOUND)

	FIND_DEPENDENCIES(QWT LIBRARY_QWT_FOUND "QT" "QT_INCLUDE_DIR;Qt")
	
endif()
