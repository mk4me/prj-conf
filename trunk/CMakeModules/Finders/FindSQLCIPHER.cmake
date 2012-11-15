# przygotowanie do szukania
FIND_INIT(SQLCIPHER sqlcipher)

# szukanie
if (WIN32) 
FIND_SHARED(SQLCIPHER "sqlcipher" "sqlcipher")
elseif (UNIX)
FIND_SHARED(SQLCIPHER "sqlite3" "sqlite3")
endif()

set(SQLCIPHER_CUSTOM_COMPILER_DEFINITIONS SQLITE_HAS_CODEC)
# skopiowanie
FIND_FINISH(SQLCIPHER)
