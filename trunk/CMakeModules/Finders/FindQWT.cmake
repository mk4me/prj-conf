# przygotowanie do szukania
FIND_INIT(QWT qwt)

# szukanie
FIND_SHARED(QWT "qwt" "qwt")

set(QWT_COMPILER_DEFINITIONS QWT_DLL)

FIND_DEPENDENCIES(QWT "QT" "QT_INCLUDE_DIR;QtCore;QT_INCLUDE_DIR;Qt")

# skopiowanie
FIND_FINISH(QWT)
