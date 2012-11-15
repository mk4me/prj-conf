# przygotowanie do szukania
FIND_INIT(QWT qwt)

# szukanie
FIND_SHARED(QWT "qwt" "qwt")

set(QWT_COMPILER_DEFINITIONS QWT_DLL)

# skopiowanie
FIND_FINISH(QWT)

if (NOT QT_FOUND)
	set(QWT_FOUND 0)
else()
	LIST(APPEND QWT_INCLUDE_DIR "${QT_INCLUDE_DIR}/Qt")
endif()
