# przygotowanie do szukania
FIND_INIT(QUAZIP quazip)

# szukanie
FIND_SHARED(QUAZIP "quazip" "quazip")

FIND_DEPENDENCIES(QUAZIP "QT;ZLIB" "QT_INCLUDE_DIR;QtCore")

# skopiowanie
FIND_FINISH(QUAZIP)
