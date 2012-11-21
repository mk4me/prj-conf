# przygotowanie do szukania
FIND_INIT(QuaZip quazip)

# szukanie
FIND_SHARED(QuaZip "quazip" "quazip")

# skopiowanie
FIND_FINISH(QuaZip)

if (NOT QT_FOUND OR NOT ZLIB_FOUND)
	set(QuaZip_FOUND 0)
else()
	LIST(APPEND QuaZip_INCLUDE_DIR "${QT_INCLUDE_DIR}/QtCore")
	LIST(APPEND QuaZip_INCLUDE_DIR "${ZLIB_INCLUDE_DIR}")
endif()
