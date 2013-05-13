# przygotowanie do szukania
FIND_INIT(QuaZip quazip)

# szukanie
FIND_SHARED(QuaZip "quazip" "quazip")

FIND_DEPENDENCIES(QuaZip "QT;ZLIB" "QT_INCLUDE_DIR;QtCore")

# skopiowanie
FIND_FINISH(QuaZip)