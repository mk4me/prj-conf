# przygotowanie do szukania
FIND_INIT(QWT qwt)

# szukanie
FIND_SHARED(QWT "qwt" "qwt")

set(QWT_COMPILER_DEFINITIONS QWT_DLL)

# skopiowanie
FIND_FINISH(QWT)

if(QWT_FOUND)

	FIND_DEPENDENCIES(QWT QWT_FOUND "QT" "QT_INCLUDE_DIR;Qt")
	
endif()
