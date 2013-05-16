###############################################################################
# Zbi�r makr pomagaj�cych szuka� bibliotek w ramach ustalonej struktury.
#
# Struktura bibliotek wygl�da nastepuj�co:
# root/
#		include/
#				libraryA/
#						 LibraryAHeaders
#				libraryB/
#						 LibraryBHeaders
#		lib/
#			platform/	[win32 | linux32 | win64 | linux64] aktualnie wspierane s� pierwsze 2
#					 build/ [debug | release]
#							LibraryA/
#									  LibraryAArtifacts [libs, dlls, so, a, plugins, exe]
#
# W taki spos�b generowane s� biblioteki na CI i dla takiej struktury mamy findery bibliotek zewn�trznych
# Dla takiej struktury generujemy r�wnie� findery naszych bibliotek oraz mechanizm instalacji
#
###############################################################################
# Zmienne jakie bior� udzia� w wyszukiwaniu bibliotek:
#
# Wyj�ciowe:
# _HEADERS_INCLUDE_DIR - g��wny katalog z includami dla biblioteki dla kt�rej przed chwil� wo�ano _FIND_INIT lub FIND_INIT2, w przeciwnym wypadku nie istnieje
# _INCLUDE_DIR - g��wny katalog z includami dla biblioteki dla kt�rej przed chwil� wo�ano _FIND_INIT lub FIND_INIT2, w przeciwnym wypadku nie istnieje
# ${library}_INCLUDE_DIR - g��wny katalog z includami dla danej biblioteki, patrz _INCLUDE_DIR
# ${library}_ADDITIONAL_INCLUDE_DIRS - dodatkowe katalogi z includami dla danej biblioteki.
# 										Mog� wynika� z zale�no�ci od innych bibliotek lub
#										realizacji danej biblioteki
# LIBRARY_${library}_FOUND - informacja czy znaleziono bibliotek�
# LIBRARY_${library}_LIBRARIES - zbi�r linkowanych statycznych (patrz uwaga poni�ej) bibliotek na potrzeby zadanej biblioteki z podzia�em na wersj� debug, release i og�lne
# LIBRARY_${library}_RELEASE_LIBS - zbi�r zmiennych przechowuj�cych �cie�ki do linkowanych bibliotek w wersji release
# LIBRARY_${library}_RELEASE_DLLS - zbi�r zmiennych przechowuj�cych �cie�ki do dynamicznych bibliotek w wersji release
# LIBRARY_${library}_RELEASE_DIRECTORIES - zbi�r zmiennych przechowuj�cych �cie�ki do katalog�w (np. plugin�w, innych resources) w wersji release
# LIBRARY_${library}_RELEASE_EXECUTABLES - zbi�r zmiennych przechowuj�cych �cie�ki do plik�w wykonywalnych w wersji release
# LIBRARY_${library}_DEBUG_LIBS - zbi�r zmiennych przechowuj�cych �cie�ki do linkowanych bibliotek w wersji debug
# LIBRARY_${library}_DEBUG_DLLS - zbi�r zmiennych przechowuj�cych �cie�ki do dynamicznych bibliotek w wersji debug
# LIBRARY_${library}_DEBUG_DIRECTORIES - zbi�r zmiennych przechowuj�cych �cie�ki do katalog�w (np. plugin�w, innych resources) w wersji debug
# LIBRARY_${library}_DEBUG_EXECUTABLES - zbi�r zmiennych przechowuj�cych �cie�ki do plik�w wykonywalnych w wersji debug
###############################################################################
#
#	Wa�na informacja na temat traktowania bibliotek - pod linux biblioteki dynamiczne
#	s� traktowane jak statyczne w przypadku kompilacji - musimy je linkowa�
#	aby do��czy� odpowiednie symbole. Tam nie ma podzia�u tak jak na windows na lib i dll!
# 	Niemniej w skryptach nadal wyst�puj� jako biblioteki dynamiczne, tylko jawnie dla linux
#	s� do�anczane na potrzeby linkowania do LIBRARY_${library}_LIBRARIES
#
###############################################################################
#
# Wej�ciowe:
# ${library}_LIBRARY_DIR_DEBUG - katalog z artefaktami w wersji debug
# ${library}_LIBRARY_DIR_RELEASE - katalog z artefaktami w wersji release
#
###############################################################################
#
# Modyfikowane zmienne globalne CMAKE:
# FIND_DEBUG_SUFFIXES - suffix dla bibliotek w wersji debug, u nas zawsze d na ko�cu nazwy artefaktu!
# CMAKE_FIND_LIBRARY_SUFFIXES - lista rozszerze� dla poszukiwanych bibliotek - sami ni� sterujemy na potrzeby szukania 
#								bibliotek statycznych i dynamicznych na r�nych platformach. Zawsze przywracamy jej oryginaln� warto��
#
###############################################################################
#
# Mechanizm wyszukiwania bibliotek:
# Wszystkie makra wyszukuj�ce zawarte pomi�dzy FIND_INIT i FIND_FINISH modyfikuj� wsp�lne zmienne informuj�c przy tym
# czy dany element uda�o si� znale�� czy nie. W ten spos�b w FIND_FINISH na bazie takiego iloczynu mo�na stwierdzi�
# czy dan� bibliotek� uda�o si� znale�� poprawnie w ca�o�ci czy nie i odpowiednio ustawi� zmienn� LIBRARY_${library}_FOUND.
#
# TODO:
# nale�y doda� mechanizm opcjonalnego wyszukiwania element�w, kt�re w przypadku nieznalezienia nie b�d� powodowa�y oznaczenia
# biblioteki jako nieznalezionej
#
###############################################################################
#
# Mechanizm obs�ugi zale�no�ci bibliotek mi�dzy sob�:
# Cz�sto pomi�dzy bibliotekami wystepuj� dodatkowe zale�no�ci jawne (includy + liby i dllki),
# oraz niejawne gdzie wymagane s� tylko wersje dynamiczne innych bibliotek (s� one ca�kowicie przykryte
# i ich nag��wki ani libki statyczne nie sa wymagane). Dlatego biblioteki zale�ne dzielimy na:
# DEPENDENCIES - jawne zale�no�ci mog�ce pojawia� si� w includach, wymagaj� wi�c znalezienia i do��czenia do
#				 zmiennej ${library}__ADDITIONAL_INCLUDE_DIR includ�w z bibliotek zale�nych, do zmiennej
#				 LIBRARY_${library}_LIBRARIES zaleznych bibliotek statycznych
# PREREQUISITES - niejawne zalezno�ci wymagaj�ce dostarczenia jedynie wersji bibliotek dynamicznych naszej zalezno�ci
#
###############################################################################
#
# Mechanizm realizacji zalezno�ci pomi�dzy bibliotekami dzia�a dwu-etapowo:
# 1. W momencie wyszukiwania biblioteki sprawdzamy czy jej dodatkowe zale�no�ci by�y ju� szukane
#    i odpowiednio modyfikujemy informacj� o tym czy bibliotek� znaleziono czy nie
# 2. Je�li w tym momencie zadane biblioteki nie by�y wyszukiwane zostaj� zapami�tane do ponownego wyszukiwania w p�niejszym czasie
#    (by� mo�e kto� inny wci�gnie je jawnie)
#
# W drugim przebiegu s� szukane te biblioteki kt�e by�y zg�oszone jako zale�no�ci innych.
# Je�li jeszcze do tej pory nie by�y szukane s� szukane w tym momencie. Je�li maj� dodatkowe zale�no�ci
# s� one dopisywane wg schematu ju� opisanego lub je�li nie by�y jeszcze szukane odk�adamy je do p�niejszego szukania
# Procedura ta jest powtarzana tak d�ugo a� dla wszystkich bibliotek wyczerpiemy szukanie ich zalezo�ci.
#
###############################################################################


###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(_FIND_INIT library dirName)

	set(_INCLUDE_DIR)
	set(_HEADERS_INCLUDE_DIR)
	# g��wne �cie�ki
	if (NOT FIND_DISABLE_INCLUDES)
		set(${library}_INCLUDE_DIR "${FIND_LIBRARIES_INCLUDE_ROOT}/${dirName}" CACHE PATH "Location of ${library} headers.")
		set(_INCLUDE_DIR ${${library}_INCLUDE_DIR})
		set(_HEADERS_INCLUDE_DIR "${_INCLUDE_DIR}/${dirName}")
	endif()
	set(${library}_LIBRARY_DIR_DEBUG "${FIND_LIBRARIES_ROOT_DEBUG}/${dirName}" CACHE PATH "Location of ${library} debug libraries.")
	set(${library}_LIBRARY_DIR_RELEASE "${FIND_LIBRARIES_ROOT_RELEASE}/${dirName}" CACHE PATH "Location of ${library} libraries.")
	# lokalizacja bibliotek dla trybu debug
	set (FIND_DIR_DEBUG ${${library}_LIBRARY_DIR_DEBUG})	
	# lokalizacja bibliotek
	set (FIND_DIR_RELEASE ${${library}_LIBRARY_DIR_RELEASE})
	# mo�liwy przyrostek dla bibliotek w wersji debug
	set (FIND_DEBUG_SUFFIXES "d")

	# wyzerowanie zmiennych logicznych
	set (FIND_RESULTS_LOGICAL_OR 0)
	set (FIND_RESULTS_LOGICAL_AND 1)

	FIND_NOTIFY(${library} "FIND_INIT: include: ${${library}_INCLUDE_DIR}; debug: ${${library}_LIBRARY_DIR_DEBUG}; release: ${${library}_LIBRARY_DIR_RELEASE}")

	# wyzerowanie listy plik�w
	set(_ALL_LIBS)
	# release
	# lista lib�w
	set(_ALL_RELEASE_LIBS)
	# lista dllek
	set(_ALL_RELEASE_DLLS)
	# lista dodatkowych katalog�w - np. pluginy dla qt czy osg
	set(_ALL_RELEASE_DIRECTORIES)
	# lista aplikacji
	set(_ALL_RELEASE_EXECUTABLES)
	#debug
	# lista lib�w
	set(_ALL_DEBUG_LIBS)
	# lista dllek
	set(_ALL_DEBUG_DLLS)
	# lista dodatkowych katalog�w - np. pluginy dla qt czy osg
	set(_ALL_DEBUG_DIRECTORIES)
	# lista aplikacji
	set(_ALL_DEBUG_EXECUTABLES)
	
endmacro(_FIND_INIT)


###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(FIND_INIT2 library dirName includeDir libraryDirDebug libraryDirRelease)

	set(_INCLUDE_DIR)
	set(_HEADERS_INCLUDE_DIR)
	# g��wne �cie�ki
	if (NOT FIND_DISABLE_INCLUDES)
		set(${library}_INCLUDE_DIR "${includeDir}" CACHE PATH "Location of ${library} headers.")
		set(_INCLUDE_DIR ${${library}_INCLUDE_DIR})
		set(_HEADERS_INCLUDE_DIR "${_INCLUDE_DIR}/${dirName}")
	endif()
	set(${library}_LIBRARY_DIR_DEBUG "${libraryDirDebug}" CACHE PATH "Location of ${library} debug libraries.")
	set(${library}_LIBRARY_DIR_RELEASE "${libraryDirRelease}" CACHE PATH "Location of ${library} libraries.")
	# lokalizacja bibliotek dla trybu debug
	set (FIND_DIR_DEBUG ${${library}_LIBRARY_DIR_DEBUG})	
	# lokalizacja bibliotek
	set (FIND_DIR_RELEASE ${${library}_LIBRARY_DIR_RELEASE})
	# mo�liwy przyrostek dla bibliotek w wersji debug
	set (FIND_DEBUG_SUFFIXES "d")

	# wyzerowanie zmiennych logicznych
	set (FIND_RESULTS_LOGICAL_OR 0)
	set (FIND_RESULTS_LOGICAL_AND 1)

	FIND_NOTIFY(${library} "FIND_INIT: include: ${${library}_INCLUDE_DIR}; debug: ${${library}_LIBRARY_DIR_DEBUG}; release: ${${library}_LIBRARY_DIR_RELEASE}")
	
		# wyzerowanie listy plik�w
	# release
	set(_ALL_LIBS)
	# lista lib�w
	set(_ALL_RELEASE_LIBS)
	# lista dllek
	set(_ALL_RELEASE_DLLS)
	# lista dodatkowych katalog�w - np. pluginy dla qt czy osg
	set(_ALL_RELEASE_DIRECTORIES)
	# lista aplikacji
	set(_ALL_RELEASE_EXECUTABLES)
	#debug
	# lista lib�w
	set(_ALL_DEBUG_LIBS)
	# lista dllek
	set(_ALL_DEBUG_DLLS)
	# lista dodatkowych katalog�w - np. pluginy dla qt czy osg
	set(_ALL_DEBUG_DIRECTORIES)
	# lista aplikacji
	set(_ALL_DEBUG_EXECUTABLES)
	
endmacro(FIND_INIT2)

###############################################################################
# Inicjuje proces wyszukiwania biblioteki.
macro(FIND_INIT library dirName)
	FIND_INIT2(${library} ${dirName} "${FIND_LIBRARIES_INCLUDE_ROOT}/${dirName}" "${FIND_LIBRARIES_ROOT_DEBUG}/${dirName}" "${FIND_LIBRARIES_ROOT_RELEASE}/${dirName}")
endmacro(FIND_INIT)

###############################################################################

# Ko�czy proces wyszukiwania biblioteki.
macro(FIND_FINISH library)

	set(LIBRARY_${library}_FOUND ${FIND_RESULTS_LOGICAL_AND})
	# skopiowanie
	set (FIND_DISABLE_INCLUDES OFF)
	FIND_NOTIFY(${library} "FIND_FINISH: found libraries ${FIND_RESULTS}")
	
	set(LIBRARY_${library}_LIBRARIES ${_ALL_LIBS})
	set(LIBRARY_${library}_RELEASE_LIBS ${_ALL_RELEASE_LIBS})
	set(LIBRARY_${library}_RELEASE_DLLS ${_ALL_RELEASE_DLLS})
	set(LIBRARY_${library}_RELEASE_DIRECTORIES ${_ALL_RELEASE_DIRECTORIES})
	set(LIBRARY_${library}_RELEASE_EXECUTABLES ${_ALL_RELEASE_EXECUTABLES})
	set(LIBRARY_${library}_DEBUG_LIBS ${_ALL_DEBUG_LIBS})
	set(LIBRARY_${library}_DEBUG_DLLS ${_ALL_DEBUG_DLLS})
	set(LIBRARY_${library}_DEBUG_DIRECTORIES ${_ALL_DEBUG_DIRECTORIES})
	set(LIBRARY_${library}_DEBUG_EXECUTABLES ${_ALL_DEBUG_EXECUTABLES})

endmacro(FIND_FINISH)

###############################################################################

# Makro wyszukuje bibliotek statycznych lub plik�w lib dla wsp�dzielonych bibliotek (windows).
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� bibliotek w wersji release
# releaseOutputSufix - sufix dla zmiennej trzymaj�cej �cie�k� do znalezionej biblioteki w wersji release
# Wygl�da nastepuj�co: ${variable}_${releaseOutputSufix}
# debugOutputSufix - patrz opis wy�ej dla releaseOutputSufix
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� biblioteki bez rozszerzenia (np. biblioteki stayczne na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_${debugOutputSufix} lokalizacja biblioteki w wersji debug
#   ${variable}_${releaseOutputSufix} lokazliacja biblioteki w wersji release
macro(FIND_LIB_FILES_PATTERN variable releasePattern debugPattern releaseOutputSufix debugOutputSufix msgHeader extensions)

	set(suffixes_copy ${CMAKE_FIND_LIBRARY_SUFFIXES})
	string(LENGTH "${extensions}" length)
	if (NOT length EQUAL 0)
		set(CMAKE_FIND_LIBRARY_SUFFIXES ${extensions})
	endif()

	if (FIND_DISABLE_CUSTOM_DIRECTORY)
		FIND_NOTIFY(${variable} "${msgHeader}: only system directories!")
	endif()

	# wyszukanie wersji debug
	set(_lib_names)
	CREATE_NAMES_LIST("<?,lib>${debugPattern}${extensions}" _lib_names)	
	
	FIND_NOTIFY(${variable} "${msgHeader}: debug pattern ${debugPattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# szukamy wersji release, najpierw w wyznaczonym miejscu
		find_library(${variable}_${debugOutputSufix}
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_DEBUG}
			DOC "Location of debug version of ${_lib_names}"
			NO_DEFAULT_PATH
		)
		
	endif()
	
	# potem w ca�ym systemie
	find_library(${variable}_${debugOutputSufix}
		NAMES ${_lib_names}
		DOC "Location of debug version of ${_lib_names}"
	)

	# wyszukanie wersji release
	set(_lib_names)
	CREATE_NAMES_LIST("<?,lib>${releasePattern}${extensions}" _lib_names)

	FIND_NOTIFY(${variable} "${msgHeader}: release pattern ${releasePattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# szukamy wersji release, najpierw w wyznaczonym miejscu
		find_library(${variable}_${releaseOutputSufix}
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of release version of ${_lib_names}"
			NO_DEFAULT_PATH
		)
	endif()
	# potem w ca�ym systemie
	find_library(${variable}_${releaseOutputSufix}
		NAMES ${_lib_names}
		DOC "Location of release version of ${_lib_names}"
	)

	# przywracamy sufiksy
	set(CMAKE_FIND_LIBRARY_SUFFIXES ${suffixes_copy})

endmacro(FIND_LIB_FILES_PATTERN)

###############################################################################

# Makro wyszukuje bibliotek statycznych lub plik�w lib dla wsp�dzielonych bibliotek (windows).
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� bibliotek w wersji release
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� biblioteki bez rozszerzenia (np. biblioteki stayczne na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_LIBRARY_DEBUG lokalizacja biblioteki w wersji debug
#   ${variable}_LIBRARY_RELEASE lokazliacja biblioteki w wersji release
macro(FIND_LIBS_PATTERN variable releasePattern debugPattern extensions)

	FIND_LIB_FILES_PATTERN(${variable} "${releasePattern}" "${debugPattern}" "LIBRARY_RELEASE" "LIBRARY_DEBUG" "FIND_LIBS_PATTERN" "${extensions}")

endmacro(FIND_LIBS_PATTERN)

###############################################################################

# Makro wyszukuje bibliotek dynamicznych.
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� bibliotek w wersji release
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� biblioteki bez rozszerzenia (np. biblioteki stayczne na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_LIBRARY_DEBUG_DLL lokalizacja biblioteki w wersji debug
#   ${variable}_LIBRARY_RELEASE_DLL lokazliacja biblioteki w wersji release
macro(FIND_SHARED_PATTERN variable releasePattern debugPattern extensions)

	FIND_LIB_FILES_PATTERN(${variable} "${releasePattern}" "${debugPattern}" "LIBRARY_RELEASE_DLL" "LIBRARY_DEBUG_DLL" "FIND_SHARED_PATTERN" "${extensions}")

endmacro(FIND_SHARED_PATTERN)

###############################################################################

# Makro wyszukuje plik�w wykonywalnych.
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� aplikacji w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� aplikacji w wersji release
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� aplikacji bez rozszerzenia (np. na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_EXECUTABLE_DEBUG lokalizacja aplikacji w wersji debug
#   ${variable}_EXECUTABLE_RELEASE lokazliacja aplikacji w wersji release

macro(FIND_EXECUTABLE_PATTERN variable releasePattern debugPattern)
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: begin: ${${variable}}")
	if (FIND_DISABLE_CUSTOM_DIRECTORY)
		FIND_NOTIFY(${variable} "FIND_EXECUTABLE: only system directories!")
	endif()

	set(_lib_names)
	CREATE_NAMES_LIST("${releasePattern}" _lib_names)
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: release pattern ${releasePattern} unrolled to ${_lib_names}")
	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# najpierw przeszukiwany jest katalog release
		find_program(${variable}_EXECUTABLE_RELEASE
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of ${variable}"
			NO_DEFAULT_PATH
		)
	endif()
	# potem w ca�ym systemie
	find_program(${variable}_EXECUTABLE_RELEASE
		NAMES ${_lib_names}
		DOC "Location of ${variable}"
	)
	
	set(_lib_names)
	CREATE_NAMES_LIST("${debugPattern}" _lib_names)
	FIND_NOTIFY(${variable} "FIND_EXECUTABLE: debug pattern ${debugPattern} unrolled to ${_lib_names}")

	if (NOT FIND_DISABLE_CUSTOM_DIRECTORY)
		# najpierw przeszukiwany jest katalog debug
		find_program(${variable}_EXECUTABLE_DEBUG
			NAMES ${_lib_names}
			PATHS ${FIND_DIR_RELEASE}
			DOC "Location of ${variable}"
			NO_DEFAULT_PATH
		)
	endif()
	# potem w ca�ym systemie
	find_program(${variable}_EXECUTABLE_DEBUG
		NAMES ${_lib_names}
		DOC "Location of ${variable}"
	)
	
endmacro(FIND_EXECUTABLE_PATTERN)

###############################################################################

# Makro wyszukuje plik�w wykonywalnych.
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� aplikacji w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� aplikacji w wersji release
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� aplikacji bez rozszerzenia (np. na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_EXECUTABLE_DEBUG lokalizacja aplikacji w wersji debug
#   ${variable}_EXECUTABLE_RELEASE lokazliacja aplikacji w wersji release

macro(FIND_EXECUTABLE variable names)
	
	FIND_EXECUTABLE_EXT(${variable} ${names} "${names}<d,?>")
	
endmacro(FIND_EXECUTABLE)

###############################################################################

# Makro wyszukuje plik�w wykonywalnych.
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� aplikacji w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� aplikacji w wersji release
# Wyja�nienie: extension u�ywany jest w sytuacji, gdy
# CMake nie potrafi wyszuka� aplikacji bez rozszerzenia (np. na Unixie)
# w 99% przypadk�w jednak nic nie zawiera i w tych wypadkach rozszerzenia brane s� z suffixes.
# Rezultaty:
# 	${variable}_EXECUTABLE_DEBUG lokalizacja aplikacji w wersji debug
#   ${variable}_EXECUTABLE_RELEASE lokazliacja aplikacji w wersji release

macro(FIND_EXECUTABLE_EXT variable namesRelease namesDebug)
	
	FIND_EXECUTABLE_PATTERN(${variable} ${namesRelease} "${namesDebug}")
	
	set(EXECUTABLE_${variable}_FOUND)
	
	# czy uda�o si� cokolwiek?
	if (${variable}_EXECUTABLE_DEBUG OR ${variable}_EXECUTABLE_RELEASE)

		# czy uda�o si� znale�� odpowiednie warianty?
		if ( ${variable}_EXECUTABLE_DEBUG AND ${variable}_EXECUTABLE_RELEASE )
			list(APPEND _ALL_RELEASE_EXECUTABLES ${variable}_EXECUTABLE_RELEASE)
			list(APPEND _ALL_DEBUG_EXECUTABLES ${variable}_EXECUTABLE_DEBUG)
		elseif ( ${variable}_LIBRARY_DEBUG )
			list(APPEND _ALL_RELEASE_EXECUTABLES ${variable}_EXECUTABLE_DEBUG)
			list(APPEND _ALL_DEBUG_EXECUTABLES ${variable}_EXECUTABLE_DEBUG)
			FIND_MESSAGE("Release version of ${variable} executable not found, using Debug version.")
		else()
			list(APPEND _ALL_RELEASE_EXECUTABLES ${variable}_EXECUTABLE_RELEASE)
			list(APPEND _ALL_DEBUG_EXECUTABLES ${variable}_EXECUTABLE_RELEASE)
			FIND_MESSAGE("Debug version of ${variable} executable not found, using Release version.")
		endif()

		# znale�li�my
		set(EXECUTABLE_${variable}_FOUND 1)
		FIND_NOTIFY_RESULT(1)
	else()
		FIND_NOTIFY_RESULT(0)
	endif()
	
endmacro(FIND_EXECUTABLE_EXT)

###############################################################################

# Makro wyszukuje biblioteki z pojedynczego pliku
# Zak�ada, �e istniej� dwie zmienne:
# FIND_DIR_DEBUG Miejsca gdzie szuka� bibliotek w wersji debug
# FIND_DIR_RELEASE Miejsca gdzie szuka� bibliotek w wersji release
# Rezultaty:
# 	${variable} Zaimportowana biblioteka
#   LIBRARY_${variable}_FOUND Flaga okre�laj�ca, czy si� uda�o
#   ${variable}_LIBRARY_DEBUG �cie�ka do biblioteki w wersji DEBUG.
#   ${variable}_LIBRARY_RELEASE �cie�ka do biblioteki w wersji RELEASE.
macro(ADD_LIBRARY_SINGLE variable names debugNames static)

	set(LIBRARY_${variable}_FOUND 0)

	# szukamy lib�w
	if(${static})
		if ( WIN32 )
			FIND_LIBS_PATTERN(${variable} "${names}" "${debugNames}" ".lib")
		else()
			FIND_LIBS_PATTERN(${variable} "${names}" "${debugNames}" ".a")
		endif()
		
		# czy uda�o si� cokolwiek?
		if (${variable}_LIBRARY_DEBUG OR ${variable}_LIBRARY_RELEASE)

			# czy uda�o si� znale�� odpowiednie warianty?
			if ( ${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_RELEASE )
				list(APPEND _ALL_RELEASE_LIBS ${variable}_LIBRARY_RELEASE)
				list(APPEND _ALL_DEBUG_LIBS ${variable}_LIBRARY_DEBUG)
				list(APPEND _ALL_LIBS optimized "${${variable}_LIBRARY_RELEASE}" debug "${${variable}_LIBRARY_DEBUG}")
			elseif ( ${variable}_LIBRARY_DEBUG )
				list(APPEND _ALL_DEBUG_LIBS ${variable}_LIBRARY_DEBUG)
				list(APPEND _ALL_LIBS "${${variable}_LIBRARY_DEBUG}")
				FIND_MESSAGE("Release version of ${variable} not found, using Debug version.")
			else()
				list(APPEND _ALL_RELEASE_LIBS ${variable}_LIBRARY_RELEASE)
				list(APPEND _ALL_LIBS "${${variable}_LIBRARY_RELEASE}")
				FIND_MESSAGE("Debug version of ${variable} not found, using Release version.")
			endif()

			# znale�li�my
			set(LIBRARY_${variable}_FOUND 1)
			FIND_NOTIFY_RESULT(1)
			
		endif()
		
	else()
	
		if ( WIN32 )
			FIND_SHARED_PATTERN(${variable} "${names}" "${debugNames}" ".dll")
		else()
			FIND_SHARED_PATTERN(${variable} "${names}" "${debugNames}" ".so")
		endif()	

		# czy uda�o si� cokolwiek?
		if (${variable}_LIBRARY_DEBUG_DLL OR ${variable}_LIBRARY_RELEASE_DLL)

			# czy uda�o si� znale�� odpowiednie warianty?
			if ( ${variable}_LIBRARY_DEBUG_DLL AND ${variable}_LIBRARY_RELEASE_DLL )
				list(APPEND _ALL_RELEASE_DLLS ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND _ALL_DEBUG_DLLS ${variable}_LIBRARY_DEBUG_DLL)
				if(NOT WIN32)
					list(APPEND _ALL_LIBS optimized "${${variable}_LIBRARY_RELEASE_DLL}" debug "${${variable}_LIBRARY_DEBUG_DLL}")
				endif()
			elseif ( ${variable}_LIBRARY_DEBUG_DLL )
				list(APPEND _ALL_DEBUG_DLLS ${variable}_LIBRARY_DEBUG_DLL)
				if(NOT WIN32)
					list(APPEND _ALL_LIBS "${${variable}_LIBRARY_DEBUG_DLL}")
				endif()
				FIND_MESSAGE("Release version of ${variable} not found, using Debug version.")
			else()
				list(APPEND _ALL_RELEASE_DLLS ${variable}_LIBRARY_RELEASE_DLL)
				if(NOT WIN32)
					list(APPEND _ALL_LIBS "${${variable}_LIBRARY_RELEASE_DLL}")
				endif()
				FIND_MESSAGE("Debug version of ${variable} not found, using Release version.")
			endif()

			# znale�li�my
			set(LIBRARY_${variable}_FOUND 1)
			FIND_NOTIFY_RESULT(1)
		endif()
	endif()
	
	if( NOT LIBRARY_${variable}_FOUND )
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

# Wyszukuje bibliotek� statyczn�
# variable	Nazwa zmiennej
# shortname	Nazwa biblioteki (nazwa pliku)
# Odno�nie rezulat�w przeczytaj komentarz do makra ADD_LIBRARY_SINGLE
macro(FIND_STATIC variable names)
	FIND_STATIC_EXT(${variable} ${names} "${names}<d,?>")
endmacro(FIND_STATIC)

###############################################################################

macro (FIND_SHARED_EXT variable names debugNames dllNames dllDebugNames)
	FIND_NOTIFY(${variable} "FIND_SHARED_EXT: begin: ${${variable}}")
	if (NOT WIN32)
		# jeden plik
		ADD_LIBRARY_SINGLE(${variable} "${names}" "${debugNames}" 0)
	else()
		
		set(LIBRARY_${variable}_FOUND 0)
	
		# b�dzie plik lib i dll...
		# szukamy lib�w
		FIND_LIBS_PATTERN(${variable} "${names}" "${debugNames}" ".lib")
		# szukamy dllek
		FIND_SHARED_PATTERN(${variable} "${dllNames}" "${dllDebugNames}" ".dll")
		set(MESSAGE_BODY "${variable} (${dllNames})")
		if ((${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL) OR (${variable}_LIBRARY_RELEASE AND ${variable}_LIBRARY_RELEASE_DLL))
			# ok, mamy co najmniej jedn� wersj�
			if ((${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL) AND
				(${variable}_LIBRARY_RELEASE AND ${variable}_LIBRARY_RELEASE_DLL))
				list(APPEND _ALL_RELEASE_DLLS ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND _ALL_DEBUG_DLLS ${variable}_LIBRARY_DEBUG_DLL)
				list(APPEND _ALL_RELEASE_LIBS ${variable}_LIBRARY_RELEASE)
				list(APPEND _ALL_DEBUG_LIBS ${variable}_LIBRARY_DEBUG)
				
				list(APPEND _ALL_LIBS optimized "${${variable}_LIBRARY_RELEASE}" debug "${${variable}_LIBRARY_DEBUG}")
				
			elseif (${variable}_LIBRARY_DEBUG AND ${variable}_LIBRARY_DEBUG_DLL)
				list(APPEND _ALL_DEBUG_DLLS ${variable}_LIBRARY_DEBUG_DLL)
				list(APPEND _ALL_DEBUG_LIBS ${variable}_LIBRARY_DEBUG)
				
				list(APPEND _ALL_LIBS "${${variable}_LIBRARY_DEBUG}")
				
				FIND_MESSAGE("Release version of ${MESSAGE_BODY} not found, using Debug version.")
			else()
				list(APPEND _ALL_RELEASE_DLLS ${variable}_LIBRARY_RELEASE_DLL)
				list(APPEND _ALL_RELEASE_LIBS ${variable}_LIBRARY_RELEASE)
				
				list(APPEND _ALL_LIBS "${${variable}_LIBRARY_RELEASE}")
				
				FIND_MESSAGE("Debug version of ${MESSAGE_BODY} not found, using Release version.")
			endif()

			# znale�li�my
			set(LIBRARY_${variable}_FOUND 1)
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

# Wyszukuje bibliotek� wsp�dzielon�
# variable	Nazwa zmiennej
# names	Nazwa biblioteki (nazwa pliku) .so dla Unixa lub .lib dla Windowsa
# dllNames Mo�liwe nazwy biblioteki .dll dla Windowsa.
# Odno�nie rezulat�w przeczytaj komentarz do makra ADD_LIBRARY_SINGLE
macro (FIND_SHARED variable names dllNames)
	FIND_SHARED_EXT(${variable} ${names} "${names}<d,?>" ${dllNames} "${dllNames}<d,?>")
endmacro (FIND_SHARED)

###############################################################################

# Wyszukuje katalog wymagany dla biblioteki
# Parametry:
#	variable	Nazwa zmiennej
#	pathRelease	Wzgl�dna �cie�ka katalogu dla release
#	pathDebug	Wzgl�dna �cie�ka katalogu dla debug
macro (_FIND_LIBRARY_ADDITIONAL_DIRECTORY_EXT variable pathRelease pathDebug)
	
	set(${variable}_DIRECTORY_RELEASE)
	
	if(IS_DIRECTORY "${FIND_DIR_RELEASE}/${pathRelease}")
		set(${variable}_DIRECTORY_RELEASE "${FIND_DIR_RELEASE}/${pathRelease}")
	endif()
	
	set(${variable}_DIRECTORY_DEBUG)
	
	if(IS_DIRECTORY "${FIND_DIR_DEBUG}/${pathDebug}")
		set(${variable}_DIRECTORY_DEBUG "${FIND_DIR_DEBUG}/${pathDebug}")
	endif()
	
endmacro(_FIND_LIBRARY_ADDITIONAL_DIRECTORY_EXT)

###############################################################################

# Wyszukuje katalog wymagany dla biblioteki
# Parametry:
#	variable	Nazwa zmiennej
#	pathRelease	Wzgl�dna �cie�ka katalogu dla release
#	pathDebug	Wzgl�dna �cie�ka katalogu dla debug
macro(FIND_DIRECTORY variable path)
	
	FIND_DIRECTORY_EXT(${variable} ${path} ${path})
	
endmacro(FIND_DIRECTORY)

###############################################################################

# Wyszukuje katalog wymagany dla biblioteki
# Parametry:
#	variable	Nazwa zmiennej
#	pathRelease	Wzgl�dna �cie�ka katalogu dla release
#	pathDebug	Wzgl�dna �cie�ka katalogu dla debug
macro(FIND_DIRECTORY_EXT variable pathRelease pathDebug)
	
	_FIND_LIBRARY_ADDITIONAL_DIRECTORY_EXT(${variable} ${pathRelease} ${pathDebug})
	set(DIRECTORY_${variable}_FOUND)
	set(MESSAGE_BODY "${variable} (${pathRelease}, (${pathDebug})")
	
	# czy uda�o si� cokolwiek?
	if (${variable}_DIRECTORY_DEBUG OR ${variable}_DIRECTORY_RELEASE)

		# czy uda�o si� znale�� odpowiednie warianty?
		if ( ${variable}_DIRECTORY_DEBUG AND ${variable}_DIRECTORY_RELEASE )
			list(APPEND _ALL_RELEASE_DIRECTORIES ${variable}_DIRECTORY_RELEASE)
			list(APPEND _ALL_DEBUG_DIRECTORIES ${variable}_DIRECTORY_DEBUG)
		elseif ( ${variable}_DIRECTORY_DEBUG )
			list(APPEND _ALL_RELEASE_DIRECTORIES ${variable}_DIRECTORY_DEBUG)
			list(APPEND _ALL_DEBUG_DIRECTORIES ${variable}_DIRECTORY_DEBUG)
			FIND_MESSAGE("Release version of ${variable} directory not found, using Debug version.")
		else()
			list(APPEND _ALL_RELEASE_DIRECTORIES ${variable}_DIRECTORY_RELEASE)
			list(APPEND _ALL_DEBUG_DIRECTORIES ${variable}_DIRECTORY_RELEASE)
			FIND_MESSAGE("Debug version of ${variable} direcotry not found, using Release version.")
		endif()

		# znale�li�my
		set(DIRECTORY_${variable}_FOUND 1)
		FIND_NOTIFY_RESULT(1)
	else()
		FIND_MESSAGE("Directory ${MESSAGE_BODY} was not found")
		FIND_NOTIFY_RESULT(0)
	endif()
	
endmacro(FIND_DIRECTORY_EXT)

###############################################################################

macro(FIND_MESSAGE)
	if (NOT FIND_SUPRESS_MESSAGES)
		message(${ARGV})
	endif()
endmacro(FIND_MESSAGE)

###############################################################################

macro(FIND_NOTIFY_RESULT value)
	if ( ${value} )
		set(FIND_RESULTS_LOGICAL_OR 1)
	else()
		if ( FIND_RESULTS_LOGICAL_AND )
			set(FIND_RESULTS_LOGICAL_AND 0)
		endif()
	endif()
endmacro(FIND_NOTIFY_RESULT)

###############################################################################

# Tworzy list� nazw na podstawie wzoru; miejsca podmiany musz� by� w ostrych
# nawiasach, natomiast warto�ci oddzielone przecinkiem; znak "?" to specjalna
# warto�� oznaczaj�ca pusty �a�cuch
# nie mog� powtarza� si� identyczne miejsca podmiany! (u�omno�� CMake)
# przyk�ad: pattern = bib<1,2,3>v<?,_d>
#			result = bib1v;bib1v_d;bib2v;bib2v_d;bib3v;bib3v_d
macro(CREATE_NAMES_LIST pattern result)
	set(_names ${pattern})
	set(_pattern ${pattern})
	foreach( id RANGE 5 )
		# pobranie opcji
		string(REGEX MATCH "<([^<]*)>" _toReplace ${_pattern})
		if( _toReplace )
			# konwersja na list�
			if (NOT CMAKE_MATCH_1 STREQUAL "")
				string(REPLACE "," ";" _options ${CMAKE_MATCH_1})
			else()
				set(_options "?")
			endif()
			# usuni�cie opcji z �a�cucha
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
		endif()
	endforeach()
	set(${result} ${_names})
endmacro(CREATE_NAMES_LIST)

###############################################################################

macro(FIND_NOTIFY var msg)
	if (FIND_VERBOSE)
		message(STATUS "FIND>${var}>${msg}")
	endif()
endmacro(FIND_NOTIFY)

###############################################################################
# Makro szuka pojedynszej biblioteki dynamicznej dla kt�rej nie ma �adnej libki i nag��wk�w
# Makro przeznaczone do szukania np. plugin�w innych, wi�kszych bibliotek
# Parametry:
#	variable - nazwa zmiennej dla biblioteki kt�r� szukamy, na jej podstawie powstanie
#				zmienna LIBRARY_${variable}_FOUND zawieraj�ca info czy uda�o si� znale�� bibliotek�
#	release - nazwa biblioteki dla release
#	debug - nazwa biblioteki dla debug
macro(FIND_DLL_EXT variable release debug)

	# szukamy samych, go�ych dllek - np. plugin�w innych bibliotek jak OpenCV i FFMPEG
	FIND_LIB_FILES_PATTERN(${variable} "${release}" "${debug}" "LIBRARY_RELEASE_DLL" "LIBRARY_DEBUG_DLL" "FIND_DLL" ".dll")
		
endmacro(FIND_DLL_EXT)

###############################################################################
# Makro szuka pojedynszej biblioteki dynamicznej dla kt�rej nie ma �adnej libki i nag��wk�w
# Makro przeznaczone do szukania np. plugin�w innych, wi�kszych bibliotek
# Parametry:
#	variable - nazwa zmiennej dla biblioteki kt�r� szukamy, na jej podstawie powstanie
#				zmienna LIBRARY_${variable}_FOUND zawieraj�ca info czy uda�o si� znale�� bibliotek�
#	name - nazwa biblioteki
macro(FIND_DLL variable name)

	# szukamy samych, go�ych dllek - np. plugin�w innych bibliotek jak OpenCV i FFMPEG
	FIND_DLL_EXT(${variable} "${name}" "${name}<d,?>")
		
endmacro(FIND_DLL)

###############################################################################

# Makro szukaj�ce dodatkowych zale�no�ci bibliotek zale�nych
# Parametry:
#	library - biblioteka dla kt�rej szukamy dodatkowych zale�no�ci
#	depsList - lista bibliotek zale�nych
#	[dodatkowe nag��wki do wci�gni�cia] - opcjonalny parametr, lista par -> biblioteka + reszta �cie�ki wzgl�dem jej includ�w
macro (FIND_DEPENDENCIES library depsList)

	set(_DEPENDENCY_FIND_RESULT 1)
	set(${library}_SECOND_PASS_FIND_DEPENDENCIES "")
	
	if(NOT DEFINED ${library}_ADDITIONAL_INCLUDE_DIRS)
		set(${library}_ADDITIONAL_INCLUDE_DIRS "")
	endif()
	
	foreach(dep ${depsList})
		if(DEFINED LIBRARY_${dep}_FOUND)
			# szukano juz tej biblioteki - sprawdzamy czy znaleziono
			if(NOT ${LIBRARY_${dep}_FOUND})
				# nie znaleziono
				set(_DEPENDENCY_FIND_RESULT 0)
			else()
				# znaleziono - musz� sobie dopi�� includy i liby
				list(APPEND ${library}_ADDITIONAL_INCLUDE_DIRS "${${dep}_INCLUDE_DIR}")
				
				if(DEFINED ${dep}_ADDITIONAL_INCLUDE_DIRS)
					list(APPEND ${library}_ADDITIONAL_INCLUDE_DIRS "${${dep}_ADDITIONAL_INCLUDE_DIRS}")
				endif()
				
				if(DEFINED ${dep}_LIBRARIES)
					list(APPEND ${library}_LIBRARIES "${${dep}_LIBRARIES}")
				endif()
			endif()
		else()
			# nie szukano jeszcze tego - dodaje do listy przysz�ych poszukiwa� dependency
			list(APPEND SECOND_PASS_FIND_DEPENDENCIES ${library})
			list(APPEND ${library}_SECOND_PASS_FIND_DEPENDENCIES ${dep})
		endif()
	endforeach()

	# dodatkowe includy na p�niej
	if(${ARGC} GREATER 2)
		list(LENGTH ${library}_SECOND_PASS_FIND_DEPENDENCIES depLength)
		if(${depLength} GREATER 0)
			# musz� je prze�o�y� na potem bo zale�no�� b�dzie szukana w drugim przebiegu
			set(${library}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE ${ARGV2})
		else()
			# mog� je teraz tutaj doda� bo wszystko ju� mam
			set(additionalIncludes ${ARGV2})
			list(LENGTH additionalIncludes incLength)
			math(EXPR incMod "${incLength} % 2")
			if(${incMod} EQUAL 0)
				math(EXPR incLength "${incLength} / 2")
				
				set(loopIDX 0)
				set(idx 0)
				while(${incLength} GREATER ${loopIDX})
				
					list(GET additionalIncludes ${idx} variableName)
					math(EXPR idx "${idx}+1")
					list(GET additionalIncludes ${idx} path)
					
					if(DEFINED ${variableName})
						list(APPEND ${library}_ADDITIONAL_INCLUDE_DIRS "${${variableName}}/${path}")
					else()
						FIND_NOTIFY(variableName "B��d podczas dodawania dodatkowych includ�w biblioteki ${library}. Zmienna ${variableName} nie istnieje, �cie�ka ${variableName}/${path} nie mog�a by� dodana.")
						set(_DEPENDENCY_FIND_RESULT 0)
					endif()
					math(EXPR idx "${idx}+1")
					math(EXPR loopIDX "${loopIDX}+1")
					
				endwhile()
			else()
				FIND_NOTIFY(additionalIncludes "B��d dodawania dodatkowych includ�w - d�ugo�� listy jest nieparzysta (b��dny format listy). Lista: ${additionalIncludes}")
				set(_DEPENDENCY_FIND_RESULT 0)
			endif()
		endif()
	endif()
	
	FIND_NOTIFY_RESULT(${_DEPENDENCY_FIND_RESULT})

endmacro(FIND_DEPENDENCIES)

###############################################################################

# Makro szukaj�ce dodatkowych zale�no�ci bibliotek na podstawie warunk�w
# Parametry:
#	library - biblioteka dla kt�rej szukamy dodatkowych zale�no�ci
#	variables - zmienne kt�re decyduj� jakie biblioteki podpi��
#	depsON - lista bibliotek zale�nych podpinanych gdy wszystkie zmienne s� ustawione
#	depsOFF - lista bibliotek zale�nych podpinanych gdy conajmniej jedna zmienna nie ustawiona
macro (FIND_CONDITIONAL_DEPENDENCIES_EXT library variables depsON depsOFF)

	set(_USE_ON 1)

	foreach(var ${variables})
	
		if(NOT ${${var}})
			set(_USE_ON 0)
		endif()
	
	endforeach()
	
	if(_USE_ON)
		FIND_DEPENDENCIES(${library} "${depsON}")
	else()
		FIND_DEPENDENCIES(${library} "${depsOFF}")
	endif()

endmacro(FIND_CONDITIONAL_DEPENDENCIES_EXT)

###############################################################################

# Makro szukaj�ce dodatkowych zale�no�ci bibliotek na podstawie warunk�w
# Parametry:
#	library - biblioteka dla kt�rej szukamy dodatkowych zale�no�ci
#	variables - zmienne kt�re decyduj� jakie biblioteki podpi��
#	deps - lista bibliotek zale�nych podpinanych gdy wszystkie zmienne s� ustawione
macro (FIND_CONDITIONAL_DEPENDENCIES library variables deps)

	FIND_CONDITIONAL_DEPENDENCIES_EXT(${library} "${variables}" "${deps}" "")

endmacro(FIND_CONDITIONAL_DEPENDENCIES)

###############################################################################

# Makro szukaj�ce dodatkowych zale�no�ci bibliotek na podstawie warunk�w
# Parametry:
#	library - biblioteka dla kt�rej szukamy dodatkowych zale�no�ci
#	variables - zmienne kt�re decyduj� jakie biblioteki podpi��
#	prereqsON - lista bibliotek zale�nych podpinanych gdy wszystkie zmienne s� ustawione
#	prereqsOFF - lista bibliotek zale�nych podpinanych gdy conajmniej jedna zmienna nie ustawiona
macro (FIND_CONDITIONAL_PREREQUISITES_EXT library variables prereqsON prereqsOFF)

	set(_USE_ON 1)

	foreach(var ${variables})
	
		if(NOT ${${var}})
			set(_USE_ON 0)
		endif()
	
	endforeach()
	
	if(_USE_ON)
		FIND_PREREQUISITES(${library} "${prereqsON}")
	else()
		FIND_PREREQUISITES(${library} "${prereqsOFF}")
	endif()

endmacro(FIND_CONDITIONAL_PREREQUISITES_EXT)

###############################################################################

# Makro szukaj�ce dodatkowych zale�no�ci bibliotek na podstawie warunk�w
# Parametry:
#	library - biblioteka dla kt�rej szukamy dodatkowych zale�no�ci
#	variables - zmienne kt�re decyduj� jakie biblioteki podpi��
#	deps - lista bibliotek zale�nych podpinanych gdy wszystkie zmienne s� ustawione
macro (FIND_CONDITIONAL_PREREQUISITES library variables prereqs)

	FIND_CONDITIONAL_PREREQUISITES_EXT(${library} "${variables}" "${prereqs}" "")

endmacro(FIND_CONDITIONAL_PREREQUISITES)

###############################################################################

# Makro pozwalaj�ce dodawa� prerequisites dla bibliotek zaleznych
# Parametry:
#	library - biblioteka dla kt�rej prerequisites szukamy
#	result - zmienna kt�a zostanie zaktualizowana czy znaleziono wszystkie prerequisites czy jakiego� brakuje
#	prereqList - lista dodatkowych zale�no�ci
macro (FIND_PREREQUISITES library prereqList)
	
	set(_PREREQUISIT_FIND_RESULT 1)
	set(${library}_SECOND_PASS_FIND_PREREQUISITES "")
	foreach(prereq ${prereqList})
		if(DEFINED LIBRARY_${prereq}_FOUND)
			# szukano juz tej biblioteki - sprawdzamy czy znaleziono
			if(NOT ${LIBRARY_${prereq}_FOUND})
				# nie znaleziono
				set(_PREREQUISIT_FIND_RESULT 0)
			endif()
		else()
			# nie szukano jeszcze tego - dodaje do listy przysz�ych poszukiwa� prerequisites
			list(APPEND SECOND_PASS_FIND_PREREQUISITES ${library})
			list(APPEND ${library}_SECOND_PASS_FIND_PREREQUISITES ${prereq})
		endif()
	endforeach()
	
	FIND_NOTIFY_RESULT(${_PREREQUISIT_FIND_RESULT})

endmacro(FIND_PREREQUISITES)

###############################################################################
# Funkcja wykrywaj�ce czy dana definicja wyst�puje w zadanej zawartosci pliku
# Parametry:
#	fileContent Zawarto�� pliku do przejrzenia
#	preprocesorDefine Define kt�rego szukamy
# Warto�c zwracana:
# 	zmienne ${preprocesorDefine}_FOUND ustawiona na 0 je�li nie znaleziono i na 1 je�li znaleziono
function(FIND_PREPROCESOR_DEFINE fileContent preprocesorDefine)
	# pr�ba odczytania wersji z pliku
	string(REGEX MATCH ".*#define .*${preprocesorDefine}" DEFINE_${preprocesorDefine}_FOUND ${fileContent})
	if(NOT DEFINE_${preprocesorDefine}_FOUND STREQUAL "Unknown")
		set(DEFINE_${preprocesorDefine}_FOUND 0)
	else()
		set(DEFINE_${preprocesorDefine}_FOUND 1)
	endif()
endfunction(FIND_PREPROCESOR_DEFINE)

###############################################################################
# Makro szuka defin�w w pliku,
# kt�re potem staj� si� cz�ci� logiki do�anczania nowych bibliotek do prerequisites
# lub dependencies
# Parametry:
#	srcFile - nag��wek publiczny kt�ry badamy, �cie�ka wzgl�dna wg schematu bibliotk
#	defines - lista defin�w kt�rych szukamy
# Na bazie defin�w powstan� odpowiednie zmienne m�wi�ce nam czy define zosta� znaleziony
# czy nie
macro(FIND_SOURCE_FILE_DEFINE_CONDITIONS srcFile defines)

	FIND_SOURCE_FILE_DEFINE_CONDITIONS_EXT("${_HEADERS_INCLUDE_DIR}/${srcFile}" "${defines}")

endmacro(FIND_SOURCE_FILE_DEFINE_CONDITIONS)

###############################################################################
# Makro szuka defin�w w pliku,
# kt�re potem staj� si� cz�ci� logiki do�anczania nowych bibliotek do prerequisites
# lub dependencies
# Parametry:
#	srcFile - nag��wek publiczny kt�ry badamy - �cie�ka bezwzgl�dna
#	defines - lista defin�w kt�rych szukamy
# Na bazie defin�w powstan� odpowiednie zmienne m�wi�ce nam czy define zosta� znaleziony
# czy nie
macro(FIND_SOURCE_FILE_DEFINE_CONDITIONS_EXT srcFile defines)

	if(IS_ABSOLUTE "${srcFile}")
		if(EXISTS "${srcFile}")
			file(READ "${srcFile}" _fileContent)
			foreach(def ${defines})
				FIND_PREPROCESOR_DEFINE("${_fileContent}" "${def}")
			endforeach()
			FIND_NOTIFY_RESULT(1)
		else()
			FIND_NOTIFY(srcFile "File with conditional defines for dependencies and PREREQUISITES not exist")
			FIND_NOTIFY_RESULT(0)
		endif()
	else()
		FIND_NOTIFY(srcFile "Given file path is not absolute - could not read required defines for conditional dependencies and prerequsites")
		FIND_NOTIFY_RESULT(0)
	endif()
endmacro(FIND_SOURCE_FILE_DEFINE_CONDITIONS_EXT)