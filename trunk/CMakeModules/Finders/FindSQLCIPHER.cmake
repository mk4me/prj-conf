# przygotowanie do szukania
FIND_INIT(SQLCIPHER sqlcipher)

# szukanie
if (WIN32) 
FIND_SHARED(SQLCIPHER "sqlcipher" "sqlcipher")
elseif (UNIX)
FIND_SHARED(SQLCIPHER "sqlite3" "sqlite3")
endif()

set(SQLCIPHER_COMPILER_DEFINITIONS SQLITE_HAS_CODEC)
# skopiowanie
FIND_FINISH(SQLCIPHER)

if(LIBRARY_SQLCIPHER_FOUND)
	if(WIN32)
		FIND_DEPENDENCIES(SQLCIPHER LIBRARY_SQLCIPHER_FOUND "OPENSSL")
	elseif(UNIX)
		FIND_PREREQUISITES(SQLCIPHER LIBRARY_SQLCIPHER_FOUND "OPENSSL")
	endif()
endif()
