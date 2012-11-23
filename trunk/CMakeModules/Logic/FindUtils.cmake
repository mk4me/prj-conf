###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(_FIND_INIT variable dirName)

	# g³ówne œcie¿ki
	if (NOT FIND_DISABLE_INCLUDES)
		set(${variable}_INCLUDE_DIR "${FIND_LIBRARIES_INCLUDE_ROOT}/${dirName}" CACHE PATH "Location of ${variable} headers.")
	endif()
	set(${variable}_LIBRARY_DIR_DEBUG "${FIND_LIBRARIES_ROOT_DEBUG}/${dirName}" CACHE PATH "Location of ${variable} debug libraries.")
	set(${variable}_LIBRARY_DIR_RELEASE "${FIND_LIBRARIES_ROOT_RELEASE}/${dirName}" CACHE PATH "Location of ${variable} libraries.")
	# lokalizacja bibliotek dla trybu debug
	set (FIND_DIR_DEBUG ${${variable}_LIBRARY_DIR_DEBUG})
	# lokalizacja bibliotek
	set (FIND_DIR_RELEASE ${${variable}_LIBRARY_DIR_RELEASE})
	# zerujemy listê wyszukanych bibliotek
	set (FIND_RESULTS)
	# mo¿liwy przyrostek dla bibliotek w wersji debug
	set (FIND_DEBUG_SUFFIXES "d")

	# wyzerowanie zmiennych logicznych
	set (FIND_RESULTS_LOGICAL_OR 0)
	set (FIND_RESULTS_LOGICAL_AND 1)

	FIND_NOTIFY(${variable} "FIND_INIT: include: ${${variable}_INCLUDE_DIR}; debug: ${${variable}_LIBRARY_DIR_DEBUG}; release: ${${variable}_LIBRARY_DIR_RELEASE}")

	# wyzerowanie listy plików
	set(FIND_ALL_DEBUG_FILES)
	set(FIND_ALL_RELEASE_FILES)
	set(${variable}_DIR_NAME ${dirName})
	list(APPEND FIND_ALL_RESULT ${variable})

endmacro(_FIND_INIT)


###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(FIND_INIT2 variable dirName includeDir libraryDirDebug libraryDirRelease)

	# g³ówne œcie¿ki
	if (NOT FIND_DISABLE_INCLUDES)
		set(${variable}_INCLUDE_DIR "${includeDir}" CACHE PATH "Location of ${variable} headers.")
	endif()
	set(${variable}_LIBRARY_DIR_DEBUG "${libraryDirDebug}" CACHE PATH "Location of ${variable} debug libraries.")
	set(${variable}_LIBRARY_DIR_RELEASE "${libraryDirRelease}" CACHE PATH "Location of ${variable} libraries.")
	# lokalizacja bibliotek dla trybu debug
	set (FIND_DIR_DEBUG ${${variable}_LIBRARY_DIR_DEBUG})
	# lokalizacja bibliotek
	set (FIND_DIR_RELEASE ${${variable}_LIBRARY_DIR_RELEASE})
	# zerujemy listê wyszukanych bibliotek
	set (FIND_RESULTS)
	# mo¿liwy przyrostek dla bibliotek w wersji debug
	set (FIND_DEBUG_SUFFIXES "d")

	# wyzerowanie zmiennych logicznych
	set (FIND_RESULTS_LOGICAL_OR 0)
	set (FIND_RESULTS_LOGICAL_AND 1)

	FIND_NOTIFY(${variable} "FIND_INIT: include: ${${variable}_INCLUDE_DIR}; debug: ${${variable}_LIBRARY_DIR_DEBUG}; release: ${${variable}_LIBRARY_DIR_RELEASE}")

	# wyzerowanie listy plików
	set(FIND_ALL_DEBUG_FILES)
	set(FIND_ALL_RELEASE_FILES)
	set(${variable}_DIR_NAME ${dirName})
	list(APPEND FIND_ALL_RESULT ${variable})
endmacro(FIND_INIT2)

###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(FIND_INIT variable dirName)
	FIND_INIT2(${variable} ${dirName} "${FIND_LIBRARIES_INCLUDE_ROOT}/${dirName}" "${FIND_LIBRARIES_ROOT_DEBUG}/${dirName}" "${FIND_LIBRARIES_ROOT_RELEASE}/${dirName}")
endmacro(FIND_INIT)

###############################################################################


macro(_FIND_INCLUDE_PLATFORM_HEADERS variable dirName)
	# okreœlamy œcie¿kê do katalogu z nag³ówkami konfiguracyjnymi
	set(${variable}_INCLUDE_CONFIG_DIR "${${variable}_INCLUDE_DIR}/../${FIND_PLATFORM}/${dirName}"
		CACHE PATH "Location of config headers")
	FIND_NOTIFY(${variable} "FIND_INIT: platform headers: ${${variable}_INCLUDE_CONFIG_DIR}")
endmacro(_FIND_INCLUDE_PLATFORM_HEADERS)
###############################################################################

macro(FIND_INCLUDE_PLATFORM_HEADERS2 variable dirName configDir)
	# okreœlamy œcie¿kê do katalogu z nag³ówkami konfiguracyjnymi
	set(${variable}_INCLUDE_CONFIG_DIR ${configDir} CACHE PATH "Location of config headers")
	FIND_NOTIFY(${variable} "FIND_INIT: platform headers: ${${variable}_INCLUDE_CONFIG_DIR}")
endmacro(FIND_INCLUDE_PLATFORM_HEADERS2)
###############################################################################

macro(FIND_INCLUDE_PLATFORM_HEADERS variable dirName)
	FIND_INCLUDE_PLATFORM_HEADERS2(${variable} ${dirName} "${${variable}_INCLUDE_DIR}/../${FIND_PLATFORM}/${dirName}")
endmacro(FIND_INCLUDE_PLATFORM_HEADERS)
###############################################################################

# Koñczy proces wyszukiwania biblioteki.
macro(FIND_FINISH variable)

	# skopiowanie
	set (${variable}_LIBRARIES ${FIND_RESULTS})
	set (FIND_DISABLE_INCLUDES OFF)
	FIND_NOTIFY(${variable} "FIND_FINISH: found libraries ${FIND_RESULTS}")
	set(${variable}_ALL_RELEASE_FILES ${FIND_ALL_RELEASE_FILES})
	set(${variable}_ALL_DEBUG_FILES ${FIND_ALL_DEBUG_FILES})

endmacro(FIND_FINISH)

# Wyszukuje elementy edrutils dla edr
macro(FIND_INIT_CUSTOM_MODULE variable dirName moduleIncludeRoot moduleBuildRoot)

	#FIND_INIT2(${variable} ${dirName} "${moduleIncludeRoot}" "${moduleBuildRoot}/bin/Debug" "${moduleBuildRoot}/bin/Release")
	if (WIN32)
		FIND_INIT2(${variable} ${dirName} "${moduleIncludeRoot};${moduleBuildRoot}/src" "${moduleBuildRoot}/bin/Debug" "${moduleBuildRoot}/bin/Release")
	else ()
		# TODO : warto wyeliminowac ten brzydki ifdef 
		FIND_INIT2(${variable} ${dirName} "${moduleIncludeRoot};${moduleBuildRoot}/src" "${moduleBuildRoot}/lib" "${moduleBuildRoot}/lib")
	endif ()
	FIND_INCLUDE_PLATFORM_HEADERS2(${variable} ${dirName} "${moduleBuildRoot}")
	
endmacro(FIND_INIT_CUSTOM_MODULE)

###############################################################################

# Makro wyszukuje bibliotek statycznych lub plików lib dla wspó³dzielonych bibliotek (windows).
# Zak³ada, ¿e istniej¹ dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szukaæ bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szukaæ bibliotek w wersji release
# Wyjaœnienie: extension u¿ywany jest w sytuacji, gdy
# CMake nie potrafi wyszukaæ biblioteki bez rozszerzenia (np. biblioteki stayczne na Unixie)
# w 99% przypadków jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s¹ z suffixes.
# Rezultaty:
# 	${variable}_LIBRARY_DEBUG lokalizacja biblioteki w wersji debug
#   ${variable}_LIBRARY_RELEASE lokazliacja biblioteki w wersji release
macro(FIND_LIBS_PATTERN variable releasePattern debugPattern extensions)

	#message("find libs: ${variable} ${releasePattern} ${debugPattern}")
	set(suffixes_copy ${CMAKE_FIND_LIBRARY_SUFFIXES})
	string(LENGTH "${extensions}" length)
	if (NOT length EQUAL 0)
		set(CMAKE_FIND_LIBRARY_SUFFIXES ${extensions})
	endif()

	if (FIND_DISABLE_CUSTOM_DIRECTORY)
		FIND_NOTIFY(${variable} "FIND_LIBS: only system directories!")
	endif()

	# wyszukanie wersji debug
	set(_lib_names)
	CREATE_NAMES_LIST("<?,lib>${debugPattern}${extensions}" _lib_names)

	FIND_NOTIFY(${variable} "FIND_LIBS: debug pattern ${debugPattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# szukamy wersji release, najpierw w wyznaczonym miejscu
		find_library(${variable}_LIBRARY_DEBUG
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_DEBUG}
			DOC "Location of debug version of ${_lib_names}"
			NO_DEFAULT_PATH
		)
	endif()
	# potem w ca³ym systemie
	find_library(${variable}_LIBRARY_DEBUG
		NAMES ${_lib_names}
		DOC "Location of debug version of ${_lib_names}"
	)


	# wyszukanie wersji release
	set(_lib_names)
	CREATE_NAMES_LIST("<?,lib>${releasePattern}${extensions}" _lib_names)

	FIND_NOTIFY(${variable} "FIND_LIBS: release pattern ${releasePattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# szukamy wersji release, najpierw w wyznaczonym miejscu
		find_library(${variable}_LIBRARY_RELEASE
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of release version of ${_lib_names}"
			NO_DEFAULT_PATH
		)
	endif()
	# potem w ca³ym systemie
	find_library(${variable}_LIBRARY_RELEASE
		NAMES ${_lib_names}
		DOC "Location of release version of ${_lib_names}"
	)

	# przywracamy sufiksy
	set(CMAKE_FIND_LIBRARY_SUFFIXES ${suffixes_copy})

endmacro(FIND_LIBS_PATTERN)

###############################################################################

# Makro wyszukuje bibliotek statycznych lub plików lib dla wspó³dzielonych bibliotek (windows).
# Zak³ada, ¿e istniej¹ dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szukaæ bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szukaæ bibliotek w wersji release
# Wyjaœnienie: extension u¿ywany jest w sytuacji, gdy
# CMake nie potrafi wyszukaæ biblioteki bez rozszerzenia (np. biblioteki stayczne na Unixie)
# w 99% przypadków jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s¹ z suffixes.
# Rezultaty:
# 	${variable}_LIBRARY_DEBUG lokalizacja biblioteki w wersji debug
#   ${variable}_LIBRARY_RELEASE lokazliacja biblioteki w wersji release
macro(FIND_FILES_PATTERN variable releasePattern debugPattern)

	if (FIND_DISABLE_CUSTOM_DIRECTORY)
		FIND_NOTIFY(${variable} "FIND_DLLS: only system directories!")
	endif()
	#message("find dlls: ${variable} ${releasePattern} ${debugPattern}")
	# wyszukanie wersji debug
	set(_lib_names)
	CREATE_NAMES_LIST("${debugPattern}" _lib_names)
	# szukamy wersji debug
	FIND_NOTIFY(${variable} "FIND_DLLS: debug pattern ${debugPattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		find_file(${variable}_LIBRARY_DEBUG_DLL
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_DEBUG}
			DOC "Location of debug version of ${variable}"
			NO_DEFAULT_PATH
		)
	endif()
	find_file(${variable}_LIBRARY_DEBUG_DLL
		NAMES ${_lib_names}
		DOC "Location of debug version of ${variable}"
	)

	# wyszukanie wersji release
	set(_lib_names)
	CREATE_NAMES_LIST("${releasePattern}" _lib_names)
	# szukamy wersji release
	FIND_NOTIFY(${variable} "FIND_DLLS: release pattern ${releasePattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		find_file(${variable}_LIBRARY_RELEASE_DLL
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of release version of ${variable}"
			NO_DEFAULT_PATH
		)
	endif()
	find_file(${variable}_LIBRARY_RELEASE_DLL
		NAMES ${_lib_names}
		DOC "Location of release version of ${variable}"
	)

endmacro(FIND_FILES_PATTERN)

###############################################################################

macro(FIND_EXECUTABLE variable pattern)
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: begin: ${${variable}}")
	if (FIND_DISABLE_CUSTOM_DIRECTORY)
		FIND_NOTIFY(${variable} "FIND_EXECUTABLE: only system directories!")
	endif()

	set(_lib_names)
	CREATE_NAMES_LIST("${pattern}" _lib_names)
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: pattern ${pattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# najpierw przeszukiwany jest katalog release
		find_program(${variable}_EXECUTABLE
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of ${variable}"
			NO_DEFAULT_PATH
		)
		find_program(${variable}_EXECUTABLE
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_DEBUG}
			DOC "Location of ${variable}"
			NO_DEFAULT_PATH
		)
	endif()
	find_program(${variable}_EXECUTABLE
		NAMES ${_lib_names}
		DOC "Location of ${variable}"
	)

	if (NOT ${variable}_EXECUTABLE)
		FIND_MESSAGE("Static library ${variable} not found")
		FIND_NOTIFY_RESULT(0)
	else()
		list(APPEND FIND_ALL_RELEASE_FILES ${variable}_EXECUTABLE)
		set(${variable}_FOUND 1 CACHE INTERNAL "Czy znaleziono bibliotekê ${variable}" FORCE)
		FIND_NOTIFY_RESULT(1)
	endif()
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: end: ${${variable}_EXECUTABLE}")
endmacro(FIND_EXECUTABLE)

###############################################################################

# Makro wyszukuje biblioteki z pojedynczego pliku
# Zak³ada, ¿e istniej¹ dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szukaæ bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szukaæ bibliotek w wersji release
# Rezultaty:
# 	${variable} Zaimportowana biblioteka
#   ${variable}_FOUND Flaga okreœlaj¹ca, czy siê uda³o
#   ${variable}_LIBRARY_DEBUG Œcie¿ka do biblioteki w wersji DEBUG.
#   ${variable}_LIBRARY_RELEASE Œcie¿ka do biblioteki w wersji RELEASE.
macro(ADD_LIBRARY_SINGLE variable names debugNames static)
	# szukamy libów
	if(${static})
		if ( WIN32 )
			FIND_LIBS_PATTERN(${variable} ${names} ${debugNames} ".lib")
		else()
			FIND_LIBS_PATTERN(${variable} ${names} ${debugNames} ".a")
		endif()
	#	# message("${names} ${static}")
	#	FIND_LIBS(${variable} "${names}" ".a;.lib" "")
	#	if (NOT (${variable}_LIBRARY_DEBUG OR ${variable}_LIBRARY_RELEASE) AND NOT CMAKE_HOST_WIN32)
	#		# czasem na linuxie nie wiedziec czemu wyszukiwanie bibliotek czasem nie dziala gdy nie ma rozszerzen
	#		FIND_LIBS(${variable} "${names}" ".a" ".a")
	#	endif()
	else()
		if ( WIN32 )
			FIND_LIBS_PATTERN(${variable} ${names} ${debugNames} ".dll")
		else()
			FIND_LIBS_PATTERN(${variable} ${names} ${debugNames} ".so")
		endif()
	#	FIND_LIBS(${variable} ${names} ".so;.dll" "")
	#	if (NOT (${variable}_LIBRARY_DEBUG OR ${variable}_LIBRARY_RELEASE) AND NOT CMAKE_HOST_WIN32)
	#		# czasem na linuxie nie wiedziec czemu wyszukiwanie bibliotek czasem nie dziala gdy nie ma rozszerzen
	#		FIND_LIBS(${variable} "${names}" ".so" ".so")
	#	endif()
	endif()

	# czy uda³o siê cokolwiek?
	if (${variable}_LIBRARY_DEBUG OR ${variable}_LIBRARY_RELEASE)

		# czy uda³o siê znaleŸæ odpowiednie warianty?
		if ( ${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_RELEASE )
			set(${variable} optimized ${${variable}_LIBRARY_RELEASE} debug ${${variable}_LIBRARY_DEBUG})
			list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE)
			list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG)
		elseif ( ${variable}_LIBRARY_DEBUG )
			set(${variable} ${${variable}_LIBRARY_DEBUG})
			list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG)
			FIND_MESSAGE("Release version of ${variable} not found, using Debug version.")
		else()
			set(${variable} ${${variable}_LIBRARY_RELEASE})
			list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE)
			FIND_MESSAGE("Debug version of ${variable} not found, using Release version.")
		endif()

		#list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_RELEASE} )

		# znaleŸliœmy
		set(${variable}_FOUND 1 CACHE INTERNAL "Czy znaleziono bibliotekê ${variable}" FORCE)
		list( APPEND FIND_RESULTS ${variable})
		FIND_NOTIFY_RESULT(1)
	else()
		# nie znaleziono niczego
		if(${static})
			FIND_MESSAGE("Static library ${variable} not found")
		else()
			FIND_MESSAGE("Shared library ${variable} not found")
		endif()
		FIND_NOTIFY_RESULT(0)
	endif()

endmacro (ADD_LIBRARY_SINGLE)


###############################################################################

macro(FIND_STATIC_EXT variable names debugNames)
	FIND_NOTIFY(${variable} "FIND_STATIC_EXT: begin: ${${variable}}")
	ADD_LIBRARY_SINGLE(${variable} ${names} ${debugNames} 1)
	FIND_NOTIFY(${variable} "FIND_STATIC_EXT: libs: ${${variable}}")
endmacro(FIND_STATIC_EXT)

# Wyszukuje bibliotekê statyczn¹
# variable	Nazwa zmiennej
# shortname	Nazwa biblioteki (nazwa pliku)
# Odnoœnie rezulatów przeczytaj komentarz do makra ADD_LIBRARY_SINGLE
macro(FIND_STATIC variable names)
	FIND_STATIC_EXT(${variable} ${names} "${names}<d,?>")
endmacro(FIND_STATIC)

###############################################################################

macro (FIND_SHARED_EXT variable names debugNames dllNames dllDebugNames)
	FIND_NOTIFY(${variable} "FIND_SHARED_EXT: begin: ${${variable}}")
	if (NOT WIN32)
		# jeden plik
		ADD_LIBRARY_SINGLE(${variable} ${names} ${debugNames} 0)
	else()
		# bêdzie plik lib i dll...
		# szukamy libów
		FIND_LIBS_PATTERN(${variable} ${names} ${debugNames} ".lib")
		# szukamy dllek
		FIND_FILES_PATTERN(${variable} "${dllNames}.dll" "${dllDebugNames}.dll")
		set(MESSAGE_BODY "${variable} (${dllNames})")

		if ((${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL) OR (${variable}_LIBRARY_RELEASE AND ${variable}_LIBRARY_RELEASE_DLL))

			# ok, mamy co najmniej jedn¹ wersjê
			if ((${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL) AND
				(${variable}_LIBRARY_RELEASE AND ${variable}_LIBRARY_RELEASE_DLL))
				set(${variable} optimized ${${variable}_LIBRARY_RELEASE} debug ${${variable}_LIBRARY_DEBUG})
				list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG ${variable}_LIBRARY_DEBUG_DLL )
			elseif (${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL)
				set(${variable} ${${variable}_LIBRARY_DEBUG})
				set(${variable}_LIBRARY_RELEASE_DLL ${${variable}_LIBRARY_DEBUG_DLL})
				list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG ${variable}_LIBRARY_DEBUG_DLL )
				FIND_MESSAGE("Release version of ${MESSAGE_BODY} not found, using Debug version.")
			else()
				set(${variable} ${${variable}_LIBRARY_RELEASE})
				set(${variable}_LIBRARY_DEBUG_DLL ${${variable}_LIBRARY_RELEASE_DLL})
				list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE ${variable}_LIBRARY_RELEASE_DLL)
				FIND_MESSAGE("Debug version of ${MESSAGE_BODY} not found, using Release version.")
			endif()

			# znaleŸliœmy
			set(${variable}_FOUND 1 CACHE INTERNAL "Czy znaleziono bibliotekê ${variable}" FORCE)
			list( APPEND FIND_RESULTS ${variable})

			# dodajemy do list do skopiowania
			if (WIN32)
				list( APPEND FIND_MODULES_TO_COPY_DEBUG ${${variable}_LIBRARY_DEBUG_DLL} )
				list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_RELEASE_DLL} )
			else()
				#message ("DOPISYWANIE ${variable}_LIBRARY_RELEASE : ${${variable}_LIBRARY_RELEASE}")
				#list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_RELEASE} )
			endif()
			FIND_NOTIFY_RESULT(1)
		else()
			# nie znaleziono niczego
			FIND_MESSAGE("Shared library ${MESSAGE_BODY} was not found")
			FIND_NOTIFY_RESULT(0)
		endif()
	endif()
	FIND_NOTIFY(${variable} "FIND_SHARED_EXT: libs: ${${variable}}; debug dll: ${${variable}_LIBRARY_DEBUG}; release dll: ${${variable}_LIBRARY_RELEASE}")
endmacro( FIND_SHARED_EXT )

#################################################################################################
# makro wyszukuje pliki biblioteki za pomoca wyrazen z tzw. wildcard (np. *Qt*.lib)
macro (FIND_GLOB variable releaseWild debugWild)

file(GLOB test_ ${FIND_DIR_RELEASE}/${releaseWild} )
list(LENGTH test_ LISTCOUNT)
if (LISTCOUNT)
	string(COMPARE EQUAL ${LISTCOUNT} "1" isOne)
	if (NOT isOne)
		message("Multiple files satify ${releaseWild}: ${test_}")
	endif()

	list(GET test_ 0 first)
	string(REPLACE "${FIND_DIR_RELEASE}/" "" first ${first})
	find_file(${variable}_LIBRARY_RELEASE
			NAMES ${first}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of release version of ${first}"
			NO_DEFAULT_PATH
		)

	# czy uda³o siê cokolwiek?
	if (${variable}_LIBRARY_DEBUG OR ${variable}_LIBRARY_RELEASE)

		# czy uda³o siê znaleŸæ odpowiednie warianty?
		if ( ${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_RELEASE )
			set(${variable} optimized ${${variable}_LIBRARY_RELEASE} debug ${${variable}_LIBRARY_DEBUG})
			list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE)
			list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG)
		elseif ( ${variable}_LIBRARY_DEBUG )
			set(${variable} ${${variable}_LIBRARY_DEBUG})
			list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG)
			FIND_MESSAGE("Release version of ${variable} not found, using Debug version.")
		else()
			set(${variable} ${${variable}_LIBRARY_RELEASE})
			list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE)
			FIND_MESSAGE("Debug version of ${variable} not found, using Release version.")
		endif()

		# znaleŸliœmy
		set(${variable}_FOUND 1 CACHE INTERNAL "Czy znaleziono bibliotekê ${variable}" FORCE)
		list( APPEND FIND_RESULTS ${variable})
		FIND_NOTIFY_RESULT(1)
	else()
		# nie znaleziono niczego
		if(${static})
			FIND_MESSAGE("Static library ${variable} not found")
		else()
			FIND_MESSAGE("Shared library ${variable} not found")
		endif()
		FIND_NOTIFY_RESULT(0)
	endif()


else()
	message("file wich satify: ${releaseWild} was not found in ${FIND_DIR_RELEASE}")
endif()
endmacro (FIND_GLOB)
#################################################################################################

# Wyszukuje bibliotekê statyczn¹
# variable	Nazwa zmiennej
# shortname	Nazwa biblioteki (nazwa pliku) .so dla Unixa lub .lib dla Windowsa
# ... Mo¿liwe nazwy biblioteki .dll dla Windowsa.
# Odnoœnie rezulatów przeczytaj komentarz do makra ADD_LIBRARY_SINGLE
macro (FIND_SHARED variable names dllNames)
	FIND_SHARED_EXT(${variable} ${names} "${names}<d,?>" ${dllNames} "${dllNames}<d,?>")
endmacro (FIND_SHARED)

###############################################################################

macro (FIND_MODULE_EXT variable isSystemModule names debugNames)
	FIND_NOTIFY(${variable} "FIND_MODULE_EXT: begin: ${${variable}}")
	# czy wyszukujemy tylko w œcie¿ce systemowej?
	if (${isSystemModule} STREQUAL "TRUE")
		set(FIND_DISABLE_CUSTOM_DIRECTORY ON)
	endif()

	# na Unixie po prostu dodajemy bibliotekê wspó³dzielon¹
	ADD_LIBRARY_SINGLE(${variable} "${names}" "${debugNames}" 0)
	# jezeli znaleziono to trzeba usunac z listy modulow
	if (${variable}_FOUND)
		list( REMOVE_ITEM FIND_RESULTS ${variable})
		# jeœli to nie modu³ systemowy dodajemy do listy
		if (${isSystemModule} STREQUAL "FALSE")
			FIND_NOTIFY(${variable} "FIND_MODULE_EXT: will copy; debug dll: ${${variable}_LIBRARY_DEBUG}; release dll: ${${variable}_LIBRARY_RELEASE}")
			if (${variable}_LIBRARY_DEBUG)
				list( APPEND FIND_MODULES_TO_COPY_DEBUG ${${variable}_LIBRARY_DEBUG} )
				list( APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG)
			else()
				list( APPEND FIND_MODULES_TO_COPY_DEBUG ${${variable}_LIBRARY_RELEASE} )
			endif()
			if (${variable}_LIBRARY_RELEASE)
				list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_RELEASE} )
				list( APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE)
			else()
				list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_DEBUG} )
			endif()
		else()
			FIND_NOTIFY(${variable} "FIND_MODULE_EXT: won't copy; debug dll: ${${variable}_LIBRARY_DEBUG}; release dll: ${${variable}_LIBRARY_RELEASE}")
		endif()
	endif()

	# czy wyszukujemy tylko w œcie¿ce systemowej?
	if (${isSystemModule} STREQUAL "TRUE")
		set(FIND_DISABLE_CUSTOM_DIRECTORY)
		unset(${variable}_LIBRARY_DEBUG CACHE )
		unset(${variable}_LIBRARY_RELEASE CACHE )
		unset(${variable}_LIBRARY_DEBUG_DLL CACHE )
		unset(${variable}_LIBRARY_RELEASE_DLL CACHE )
		unset(${variable}_LIBRARY_DIR_DEBUG CACHE )
	    unset(${variable}_LIBRARY_DIR_RELEASE CACHE )
	endif()
	FIND_NOTIFY(${variable} "FIND_MODULE_EXT: libs: ${${variable}}")
endmacro(FIND_MODULE_EXT)

# Wyszukuje bibliotekê statyczn¹
# variable	Nazwa zmiennej
# shortname	Nazwa biblioteki (nazwa pliku) .so dla Unixa lub .lib dla Windowsa
# ... Mo¿liwe nazwy biblioteki .dll dla Windowsa.
# Odnoœnie rezulatów przeczytaj komentarz do makra ADD_LIBRARY_SINGLE
macro (FIND_MODULE variable isSystemModule names)
	FIND_MODULE_EXT(${variable} ${isSystemModule} ${names} "${names}<d,?>")
endmacro (FIND_MODULE)
###############################################################################

macro(FIND_MESSAGE ...)
	if (NOT FIND_SUPRESS_MESSAGES)
		message(${ARGV})
	endif()
endmacro(FIND_MESSAGE)

###############################################################################

macro(FIND_NOTIFY_RESULT value)
	if ( ${value} )
		if ( NOT FIND_RESULTS_LOGICAL_OR )
			set(FIND_RESULTS_LOGICAL_OR 1)
		endif()
	else()
		if ( FIND_RESULTS_LOGICAL_AND )
			set(FIND_RESULTS_LOGICAL_AND 0)
		endif()
	endif()
endmacro(FIND_NOTIFY_RESULT)

###############################################################################

macro(FIND_COPY_AND_INSTALL_MODULES buildType subDir)

	# wybieramy odpowiednia liste
	string(TOUPPER "${buildType}" buildTypeUpper)
	if ("${buildTypeUpper}" STREQUAL "DEBUG")
		set(MODULES_LIST ${FIND_MODULES_TO_COPY_DEBUG})
	else()
		set(MODULES_LIST ${FIND_MODULES_TO_COPY_RELEASE})
	endif()

	# kopiujemy modul
	foreach (module ${MODULES_LIST})

		get_filename_component(moduleNameWE ${module} NAME_WE)
		get_filename_component(moduleName ${module} NAME)

		# czy zdefiniowano sufix dla tego modu³u?
		if (FIND_MODULE_PREFIX_${moduleNameWE})
			set(moduleName ${FIND_MODULE_PREFIX_${moduleNameWE}}${moduleName})
		endif()
		if ("${subDir}" STREQUAL "")
			configure_file(${module} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${moduleName} COPYONLY)
			message(STATUS "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${moduleName} <- ${module}")
		else()
			configure_file(${module} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}/${moduleName} COPYONLY ESCAPE_QUOTES)
			message(STATUS "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}/${moduleName} <- ${module}")
		endif()
		# instalacja pliku
		#install(FILES ${module} DESTINATION bin/${FIND_MODULE_PREFIX_${moduleNameWE}} CONFIGURATIONS ${buildType} COMPONENT core)
		#install(FILES ${module} DESTINATION bin/${moduleName} CONFIGURATIONS ${buildType} COMPONENT core)
		install(FILES ${module} DESTINATION bin CONFIGURATIONS ${buildType})
	endforeach()

endmacro(FIND_COPY_AND_INSTALL_MODULES)

###############################################################################

macro(FIND_HANDLE_MODULES doCopy)
	set(CMAKE_SKIP_BUILD_RPATH  TRUE)
	#if ( UNIX )
	#	# http://www.cmake.org/Wiki/CMake_RPATH_handling
	#	# use, i.e. don't skip the full RPATH for the build tree
	#	set(CMAKE_SKIP_BUILD_RPATH  FALSE)
	#	# when building, don't use the install RPATH already
	#	# (but later on when installing)
	#	set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
	#	# the RPATH to be used when installing
	#	set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
	#	# add the automatically determined parts of the RPATH
	#	# which point to directories outside the build tree to the install RPATH
	#	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
	#endif()

	if(${doCopy})

		# wybieramy listê konfiguracji
		if ( WIN32 )
			# lecimy po build typach
			foreach (buildType ${CMAKE_CONFIGURATION_TYPES})
				FIND_COPY_AND_INSTALL_MODULES(${buildType} ${buildType})
			endforeach()
		endif()

	endif()


endmacro(FIND_HANDLE_MODULES)

###############################################################################

macro(FIND_REBUILD_DEPENDENCIES dst)

	foreach( variable ${FIND_ALL_RESULT} )
		if (${variable}_FOUND)

			if ( DEFINED ${variable}_INCLUDE_DIR )
				#file(COPY "${${variable}_INCLUDE_DIR} DESTINATION "${dst}/${${variable}_DIR_NAME}")
				message(STATUS "${${variable}_INCLUDE_DIR} -> ${dst}/include/${${variable}_DIR_NAME}")
				execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${${variable}_INCLUDE_DIR}" "${dst}/include/${${variable}_DIR_NAME}")
			else()
				#message("${variable} dosent have inlcude dir")
			endif()

			if ( DEFINED ${variable}_INCLUDE_CONFIG_DIR )
				#file(COPY ${${variable}_INCLUDE_CONFIG_DIR} DESTINATION "${dst}/${FIND_PLATFORM}/${${variable}_DIR_NAME}")
				message(STATUS "${${variable}_INCLUDE_CONFIG_DIR} -> ${dst}/include/${FIND_PLATFORM}/${${variable}_DIR_NAME}")
				execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${${variable}_INCLUDE_CONFIG_DIR}" "${dst}/include/${FIND_PLATFORM}/${${variable}_DIR_NAME}")
			else()
				#message("${variable} dosent have inlcude config dir")
			endif()

			if ( DEFINED ${variable}_LIBRARIES )
				__FIND_REBUILD_DEPENDENCIES_COPY_FILES( ${variable}_ALL_DEBUG_FILES 	"${dst}/lib/${FIND_PLATFORM}/debug/${${variable}_DIR_NAME}")
				__FIND_REBUILD_DEPENDENCIES_COPY_FILES( ${variable}_ALL_RELEASE_FILES 	"${dst}/lib/${FIND_PLATFORM}/release/${${variable}_DIR_NAME}")
				#foreach (library ${${variable}_LIBRARIES})
				#	#message(${library})
				#	__FIND_REBUILD_DEPENDENCIES_COPY_LIBRARY( ${library}_LIBRARY_DEBUG "debug/${${variable}_DIR_NAME}")
				#	__FIND_REBUILD_DEPENDENCIES_COPY_LIBRARY( ${library}_LIBRARY_DEBUG_DLL "debug/${${variable}_DIR_NAME}")
				#	__FIND_REBUILD_DEPENDENCIES_COPY_LIBRARY( ${library}_LIBRARY_RELEASE "release/${${variable}_DIR_NAME}")
				#	__FIND_REBUILD_DEPENDENCIES_COPY_LIBRARY( ${library}_LIBRARY_RELEASE_DLL "release/${${variable}_DIR_NAME}")
				#endforeach()
			else()
				#message("${variable} dosent have libraries")
			endif()
		endif()
	endforeach()

endmacro(FIND_REBUILD_DEPENDENCIES)

###############################################################################

macro(__FIND_REBUILD_DEPENDENCIES_COPY_FILES files path)

	foreach(fl ${${files}})
		get_filename_component(_fileName ${${fl}} NAME)
		get_filename_component(_fileNameWE ${${fl}} NAME_WE)
		set(_sufix)
		if (FIND_MODULE_PREFIX_${_fileNameWE})
			set(_sufix "${FIND_MODULE_PREFIX_${_fileNameWE}}")
		endif()
		set(_dst "${path}/${_sufix}")
		message(STATUS "${${fl}} -> ${_dst}${_fileName}")
		file(COPY ${${fl}} DESTINATION ${_dst})
	endforeach()

endmacro(__FIND_REBUILD_DEPENDENCIES_COPY_FILES)

###############################################################################

# Tworzy listê nazw na podstawie wzoru; miejsca podmiany musz¹ byæ w ostrych
# nawiasach, natomiast wartoœci oddzielone przecinkiem; znak "?" to specjalna
# wartoœæ oznaczaj¹ca pusty ³añcuch
# nie mog¹ powtarzaæ siê identyczne miejsca podmiany! (u³omnoœæ CMake)
# przyk³ad: pattern = bib<1,2,3>v<?,_d>
#			result = bib1v;bib1v_d;bib2v;bib2v_d;bib3v;bib3v_d
macro (CREATE_NAMES_LIST pattern result)
	set(_names ${pattern})
	set(_pattern ${pattern})
	foreach( id RANGE 5 )
		# pobranie opcji
		string(REGEX MATCH "<([^<]*)>" _toReplace ${_pattern})
		if( _toReplace )
			# konwersja na listê
			if (NOT CMAKE_MATCH_1 STREQUAL "")
				string(REPLACE "," ";" _options ${CMAKE_MATCH_1})
			else()
				set(_options "?")
			endif()
			# usuniêcie opcji z ³añcucha
			string(REPLACE ${_toReplace} "X" _replaced ${_pattern})
			set(_pattern ${_replaced})
			# podmiana klucza
			set(_newNames)
			foreach( comb ${_names} )
				foreach (opt ${_options})
					# znak zapytania traktowany jako pusty znak
					if (opt STREQUAL "?")
						string(REPLACE ${_toReplace} "" _temp ${comb})
					else()
						string(REPLACE ${_toReplace} ${opt} _temp ${comb})
					endif()
					list(APPEND _newNames ${_temp})
				endforeach()
			endforeach()
			set(_names ${_newNames})
			#message("iter ${id}: ${_newNames}")
		endif()
	endforeach()
	set(${result} ${_names})
endmacro (CREATE_NAMES_LIST)

###############################################################################

macro(FIND_NOTIFY var msg)
	if (FIND_VERBOSE)
		message(STATUS "FIND>${var}>${msg}")
	endif()
endmacro(FIND_NOTIFY)

###############################################################################


macro (FIND_DLL variable release debug)
# szukamy dllek
		FIND_FILES_PATTERN(${variable} "${release}.dll" "${debug}.dll")
		if (${variable}_LIBRARY_DEBUG_DLL OR ${variable}_LIBRARY_RELEASE_DLL)
			
			# ok, mamy co najmniej jedn¹ wersjê
			if (${variable}_LIBRARY_DEBUG_DLL AND ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG_DLL )
			elseif (OPENCV_FFMPEG_LIBRARY_DEBUG_DLL)				
				list(APPEND FIND_ALL_DEBUG_FILES ${variable}_LIBRARY_DEBUG_DLL )
				FIND_MESSAGE("Release version of ${variable} not found, using Debug version.")
			else()				
				list(APPEND FIND_ALL_RELEASE_FILES ${variable}_LIBRARY_RELEASE_DLL)
				FIND_MESSAGE("Debug version of ${variable} not found, using Release version.")
			endif()
		
			# znaleŸliœmy
			set("${variable}_FOUND" 1)
			list( APPEND FIND_RESULTS ${variable})
			
			# dodajemy do list do skopiowania
			list( APPEND FIND_MODULES_TO_COPY_DEBUG ${${variable}_LIBRARY_DEBUG_DLL} )
			list( APPEND FIND_MODULES_TO_COPY_RELEASE ${${variable}_LIBRARY_RELEASE_DLL} )
			FIND_NOTIFY_RESULT(1)
		else()
			# nie znaleziono niczego
			FIND_MESSAGE("Shared library ${MESSAGE_BODY} was not found")
			FIND_NOTIFY_RESULT(0)
		endif()
endmacro (FIND_DLL)

###############################################################################


macro (FIND_DEPENDENCIES library result depsList)

	set(${result} 1)
	set(${library}_SECOND_PASS_FIND_DEPENDENCIES "" CACHE INTERNAL "Libraries to find in second pass for library ${library}" FORCE)
	foreach(dep ${depsList})
		if(DEFINED ${dep}_FOUND)
			# szukano juz tej biblioteki - sprawdzamy czy znaleziono
			if(NOT ${${dep}_FOUND})
				# nie znaleziono
				set(${result} 0)
			else()
				# znaleziono - muszê sobie dopi¹æ includy i liby
				list(APPEND ${library}_INCLUDE_DIR "${${dep}_INCLUDE_DIR}")
				if(DEFINED ${dep}_LIBRARIES)
					list(APPEND ${library}_LIBRARIES "${${dep}_LIBRARIES}")
				else()
				# TODO - czy trzeba te¿ dodawaæ je do instalacji? w koñcu ktoœ ich szuka³ wiêc ju¿ s¹ dodane
				endif()
			endif()
		else()
			# nie szukano jeszcze tego - dodaje do listy przysz³ych poszukiwañ dependency
			list(APPEND SECOND_PASS_FIND_DEPENDENCIES ${library})
			list(APPEND ${library}_SECOND_PASS_FIND_DEPENDENCIES ${dep})
		endif()
	endforeach()

	# dodatkowe includy na póŸniej
	if(${ARGC} GREATER 3)
		if(EXISTS ${library}_SECOND_PASS_FIND_DEPENDENCIES)
			# muszê je prze³o¿yæ na potem bo zale¿noœæ bêdzie szukana w drugim przebiegu
			set(${library}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE ${ARGV3} CACHE INTERNAL "Additional include to add in third pass for library ${library}" FORCE)
		else()
			# mogê je teraz tutaj dodaæ bo wszystko ju¿ mam
			set(additionalIncludes ${ARGV3})
			list(LENGTH additionalIncludes incLength)
			math(EXPR incMod "${incLength} % 2")
			if(${incMode} EQUAL 0)
				math(EXPR incLength "${incLength} / 2")
				
				set(loopIDX 0)
				set(idx 0)
			
				while(${incLength} GREATER ${loopIDX})
				
					list(GET additionalIncludes idx variableName)
					math(EXPR idx "${idx}+1")
					list(GET additionalIncludes idx path)
					if(EXISTS ${variableName})
						list(APPEND ${library}_INCLUDE_DIR "${${variableName}}/${path}")
					else()
						message(STATUS "B³¹d podczas dodawania dodatkowych includów biblioteki ${library}. Zmienna ${variableName} nie istnieje, œcie¿ka ${variableName}/${path} nie mog³a byæ dodana.")
						set(${result} 0)
					endif()
					math(EXPR idx "${idx}+1")
					math(EXPR loopIDX "${loopIDX}+1")
					
				endwhile()				
			else()
				message(STATUS "B³¹d dodawania dodatkowych includów - d³ugoœæ listy jest nieparzysta (b³êdny format listy). Lista: ${additionalIncludes}")
				set(${result} 0)
			endif()
		endif()
	endif()

endmacro(FIND_DEPENDENCIES)

###############################################################################


macro (FIND_PREREQUSITIES library result prereqList)

	set(${result} 1)
	set(${library}_SECOND_PASS_FIND_PREREQUISITIES "" CACHE INTERNAL "Prerequisities to find in second pass for library ${library}" FORCE)
	foreach(prereq ${prereqList})
		if(DEFINED ${prereq}_FOUND)
			# szukano juz tej biblioteki - sprawdzamy czy znaleziono
			if(NOT ${${prereq}_FOUND})
				# nie znaleziono
				set(${result} 0)
			endif()
		else()
			# nie szukano jeszcze tego - dodaje do listy przysz³ych poszukiwañ prereqisities
			list( APPEND SECOND_PASS_FIND_PREREQUISITIES ${library})
			list(APPEND ${library}_SECOND_PASS_FIND_PREREQUISITIES ${prereq})
		endif()
	endforeach()

endmacro(FIND_PREREQUSITIES)