###############################################################################

# Makro ustawiaj�ce folder dla kolejnych projekt�w
# Parametry
#	folder Nazwa folderu
macro(SET_PROJECTS_GROUP name)

	set(PROJECT_FOLDER ${name})
	string(LENGTH ${name} lStr)
	if(${lStr} EQUAL 0)
		set(PROJECT_FOLDER)
	endif()

endmacro(SET_PROJECTS_GROUP)


###############################################################################

# Makro tworz�ce prawdziwe �cie�ki plik�w
# Parametry
#	in Lista wej�ciowa z nazwami plik�w do przetworzenia
#	out Lista wyj�ciowa z �cie�kami plik�w po przetworzeniu
#   path �cie�ka w kt�rej powinny znajdowa� si� pliki wejsciowe
macro(GENERATE_FILE_PATHS in out path)

	set(${out} "")
	# ustalamy poprawn� �cie�k� do pliku wzgl�dem aktualnego katalogu
	foreach(value ${${in}})
		set(CANDIDATE_PATH "${path}/${value}")
		if(DEFINED FILE_PATH_${value})
			if(${CANDIDATE_PATH} STREQUAL FILE_PATH_${value})
				message(WARNING "Plik o nazwie ${value} by� ju� dodany w projekcie. Nie ma potrzeby dodawa� go ponownie - mo�e to by� przyczyn� b��dnego przydzielenia pliku do grup. Pomijam plik.")
			else()
				message(SEND_ERROR "Plik o nazwie ${value} by� ju� dodany w projekcie pod scie�k� ${FILE_PATH_${value}}. Teraz ma by� dodany pod �cie�k� ${path}/${value}. Nazwy plik�w musz� by� unikalne w projekcie")
			endif()
		else()
			list(APPEND ${out} "${CANDIDATE_PATH}")
			set(FILE_PATH_${value} "${CANDIDATE_PATH}")
		endif()
	endforeach()

endmacro(GENERATE_FILE_PATHS)

###############################################################################

# Makro tworz�ce prawdziwe �cie�ki plik�w po ich rejestracji
# Parametry
#	in Lista wej�ciowa z nazwami plik�w do przetworzenia
#	out Lista wyj�ciowa z �cie�kami plik�w po przetworzeniu
macro(REGENERATE_FILE_PATHS in out)

	set(${out} "")
	# ustalamy poprawn� �cie�k� do pliku wzgl�dem aktualnego katalogu
	foreach(value ${${in}})
		if(DEFINED FILE_PATH_${value})
			list(APPEND ${out} "${FILE_PATH_${value}}")
		else()
			message(WARNING "Plik ${value} nie by� wcze�niej rejestrowany. Nie mo�na odtworzy� jego �cie�ki. Pomijam plik")
		endif()
	endforeach()

endmacro(REGENERATE_FILE_PATHS)

###############################################################################

# Makro dodaj�ce projekt
# Parametry
#	name Nazwa projektu
#	dodatkowy parametr dependencies Lista zale�no�ci
#   dodatkowy parametr za dependencies to string ze �cie�k� do projektu
#   dodatkowy parametr to info czy faktycznie projekt dodajemy czy nie
macro(ADD_PROJECT name)

	# sprawdzamy czy faktycznie robimy co� z projektem
	set(PROCESS_PROJECT 1)
	if(${ARGC} GREATER 3)
		if(NOT ${ARGV3})
			set(PROCESS_PROJECT 0)
		endif()
	endif()
	
	# je�eli faktycznie przetwarzamy
	if(${PROCESS_PROJECT})
		# szukam czy nie ma ju� projektu o takiej nazwie!
		list(FIND SOLUTION_PROJECTS ${name} PROJECT_EXISTS)
		if(PROJECT_EXISTS GREATER -1)
			message("Project with name ${name} already exists! Project names must be unique! Skipping this project.")
		else()			
			# ustawiam projekt do p�niejszej konfiguracji
			set(SOLUTION_PROJECTS ${SOLUTION_PROJECTS} ${name} CACHE INTERNAL "All projects" FORCE )	
			# je�eli sa dodatkowe zale�no�ci
			set(PROJECT_DEPENDENCIES "")
			if(${ARGC} GREATER 1)
				list(APPEND PROJECT_DEPENDENCIES ${ARGV1})
				# ustawiam globalne zale�no�ci do szukania
				set(SOLUTION_DEPENDENCIES ${SOLUTION_DEPENDENCIES} ${ARGV1} CACHE INTERNAL "Solution all dependencies" FORCE )	
			endif()
			
			if(DEFINED SOLUTION_DEFAULT_DEPENDENCIES)
				list(APPEND PROJECT_DEPENDENCIES ${SOLUTION_DEFAULT_DEPENDENCIES})
			endif()
			
			# ustawiam zale�no�ci projektu
			set(PROJECT_${name}_DEPENDENCIES ${PROJECT_DEPENDENCIES} CACHE INTERNAL "Project ${name} dependencies" FORCE )
			
			set(PROJECT_${name}_PATH "${CMAKE_CURRENT_LIST_DIR}/${name}" CACHE INTERNAL "Project ${name} path" FORCE )
			
			# je�eli podano extra �cie�k� do projektu
			if(${ARGC} GREATER 2)
				# ustawiam �cie�k� do projektu
				set(PROJECT_${name}_PATH "${CMAKE_CURRENT_LIST_DIR}/${ARGV2}" CACHE INTERNAL "Project ${name} path" FORCE )
			endif()			
			
			set(PROJECT_${name}_GROUP "" CACHE INTERNAL "Project ${name} group name" FORCE )
			
			if(DEFINED PROJECT_FOLDER)
				set(PROJECT_${name}_GROUP ${PROJECT_FOLDER} CACHE INTERNAL "Project ${name} group name" FORCE )
			endif()
			
			# wst�pnie zak�adam �e nie uda�o mi si� skonfigurowa� projektu
			set(PROJECT_${name}_INITIALISED 0 CACHE INTERNAL "Helper telling if project was initialised properly" FORCE)
		endif()		
	else()
		message("Pomijam projekt ${name}")
	endif()
endmacro(ADD_PROJECT)

###############################################################################

# Makro inicjalizuj�ce dany projekt - szuka jego zale�no�ci, je�li wszystkie znajdzie to faktycznie konfuguruje projekt
# Wywo�uje si� rekurencyjnie dla naszych projekt�w aby poprawnie �ledzi�/ustawi� ich zale�no�ci i zagwarantowa� dobr� kolejno��
# ich inicjalizacji

# Parametry
#	name Nazwa projektu
macro(__INITIALIZE_PROJECT name)
	if(DEFINED PROJECT_ADD_FINISHED)
		if(${PROJECT_ADD_FINISHED} EQUAL 0)
			# b��d konfigurowania projektu - rozpocz�lismy ale nie by�o makra PROJECT_END()!!!
			message(SEND_ERROR "B��d konfiguracji: Rozpocz�to konfiguracj� projektu ${PROJECT_NAME} ale nie zako�czono jej makrem END_PROJECT()")
		endif()
	else()
		# info �e rozpoczynamy dodawanie nowego projektu ale jeszcze go nie zamkn�lismy makrem END_PROJECT()	
		set(PROJECT_ADD_FINISHED 0)
	endif()
	
	set(ADD_PROJECT_${name}_FAILED 0)
	set(ADD_PROJECT_${name}_MESSAGE)
	
	# publiczne includy	
	set(PROJECT_${name}_INCLUDE_DIRS "" CACHE INTERNAL "�cie�ka do includ�w projektu ${name}" FORCE)
	# definy tego projektu i projekt�w + bibliotek od kt�rych jest zale�ny
	set(PROJECT_${name}_COMPILER_DEFINITIONS "" CACHE INTERNAL "Definicje kompilatora projektu ${name}" FORCE)
	# resetujemy typ projektu
	set(PROJECT_${name}_TYPE "" CACHE INTERNAL "Typ projektu ${name}" FORCE )
	# nazwa artefaktu projektu
	set(PROJECT_${name}_TARGETNAME ${name} CACHE INTERNAL "Nazwa artefaktu projektu ${name}" FORCE )
	
	# aktualizujemy liste aktualnie przetwarzanych projekt�w
	list(APPEND PROJECTS_BEING_INITIALISED ${name})
	
	# czy dodawanie projektu zako�czy�o si� b��dem
	set(PROJECT_${name}_FAILED 0)
	# wiadomo�� projektu
	set(PROJECT_${name}_MESSAGE "")	
	# resetujemy list� zale�no�ci
	set(tmp_${name}_dependencies ${PROJECT_${name}_DEPENDENCIES})
	list(REMOVE_DUPLICATES tmp_${name}_dependencies)
	set(${name}_gain)
	# czy podano zale�no�ci
	list(LENGTH tmp_${name}_dependencies depLength)
	if(${depLength} GREATER 0)				
		# szukamy wszystkich brakuj�cych zale�no�ci
		foreach (value ${tmp_${name}_dependencies})
			# sprawdzamy czy przypadkiem zale�no�� nie jest naszym projektem!				
			list(FIND SOLUTION_PROJECTS ${value} DEPENDENCY_IS_PROJECT)
			if(DEPENDENCY_IS_PROJECT GREATER -1)
				# jest naszym projektem wi�c sprawdzam czy czasem z jego powodu si� nie inicjujemy
				# je�li tak to mamy cykliczn� zale�no�c projekt�w co jest niedopuszczalne
				list(FIND PROJECTS_BEING_INITIALISED ${value} PROJECT_IS_BEING_INITIALISED)
				if(${PROJECT_IS_BEING_INITIALISED} GREATER -1)
					# b��d konfigurowania projektu - rekurencyjne zale�no�ci pomi�dzy projektami!!!
					
					# TODO - zdecydowa� czy dopuszczamy rekurencyjne zale�no�ci projekt�w (z�a praktyka!!)
					# set(ADD_PROJECT_FAILED 1)
					# set(PROJECT_${name}_MESSAGE "Project ${value} has circular dependency with project ${name}, " ${PROJECT_${name}_MESSAGE})
										
					message(WARNING "Projects ${name} and ${value} have circular dependency! Think about refactoring")
				else()
					# jest naszym projektem wi�c sprawdzam czy byl ju� inicjowany, je�li tak to ok
					list(FIND INITIALISED_PROJECTS ${value} PROJECT_IS_INITIALISED)
					if(${PROJECT_IS_INITIALISED} EQUAL -1)
						# projekt nie by� jeszcze inicjowany
						# inicjujemy go teraz
						__INITIALIZE_PROJECT(${value})
					endif()
					# czy projekt uda�o sie poprawnie zainicjowa�?
					if(PROJECT_${value}_INITIALISED EQUAL 0)
						set(ADD_PROJECT_${name}_FAILED 1)
						set(ADD_PROJECT_${name}_MESSAGE ${value} ", " ${ADD_PROJECT_${name}_MESSAGE})
					endif()
				endif()
			elseif(NOT LIBRARY_${value}_FOUND)
				# jest to zale�no�� ale jej nie znaleziono
				set(ADD_PROJECT_${name}_FAILED 1)
				set(ADD_PROJECT_${name}_MESSAGE ${value} ", " ${ADD_PROJECT_${name}_MESSAGE})
				TARGET_NOTIFY(${name} "${value} not found")
			endif()
		endforeach()
		
		list(APPEND tmp_${name}_dependencies ${${name}_gain})
		list(REMOVE_DUPLICATES tmp_${name}_dependencies)
		
		# nadpisujemy ze wzgl�du na wszytkie zale�no�ci - podane jawnie i ich niejawne zale�no�ci wynikaj�ce z finder�w
		set(PROJECT_${name}_DEPENDENCIES ${tmp_${name}_dependencies} CACHE INTERNAL "Project ${name} dependencies" FORCE )
	endif()
	
	# usuwam projekt z aktualnie inicjowanych
	list(REMOVE_ITEM PROJECTS_BEING_INITIALISED ${name})	
	
	# zapami�tuj� �e projekt ju� by� inicjowany
	set(INITIALISED_PROJECTS ${INITIALISED_PROJECTS} ${name} CACHE INTERNAL "Helper list with already initialised projects" FORCE )
	
	# sprawdzamy
	if (ADD_PROJECT_${name}_FAILED)
		# brakuje zale�no�ci - wy�wietlamy komunikat
		message(${name} " not included because dependencies are missing: " ${ADD_PROJECT_${name}_MESSAGE})
	else()
	
		# faktycznie probujemy dodawac projekt - znale�lismy wszystkie zale�no�ci
		# dalej konfigurujemy projekt
		set(CURRENT_PROJECT_NAME ${name})
		add_subdirectory("${PROJECT_${name}_PATH}")
		
		# uda�o nam si� poprawnie skonfigurowa� projekt
		set(PROJECT_${value}_INITIALISED 1 CACHE INTERNAL "Helper telling if project was initialised properly" FORCE)
	endif()

endmacro(__INITIALIZE_PROJECT)

###############################################################################

# Makro dodaj�ce projekt testu
# Parametry
#	name Nazwa projektu
#	dependencies Lista zale�no�ci
#   dodatkowy parametr za dependencies to string ze �cie�k� do projektu testu wzgl�dem katalogu tests
#   dodatkowy parametr to info czy faktycznie projekt dodajemy czy nie
macro(ADD_TEST_PROJECT name dependencies)
	
	set(newDependecies ${dependencies})
	
	# rozszerzamy zale�no�ci o bilbioteki potrzebne dla test�w
	if(DEFINED TESTS_DEPENDENCIES)
		set(newDependecies ${newDependecies} ${TESTS_DEPENDENCIES})		
	endif()
	
	set(PROJECT_IS_TEST 1)
	
	ADD_PROJECT(${name} "${newDependecies}" ${ARGN})
	
endmacro(ADD_TEST_PROJECT)

###############################################################################

macro(ADD_PROJECTS name)

	add_subdirectory(${name})
	
endmacro(ADD_PROJECTS)

###############################################################################

# Makro weryfikuj�ce typ projektu
# type Typ projektu:
# executable - plik wykonywalny
# static - biblioteka ��czona statycznie
# dynamic - biblioteka ��czona dynamicznie (z libk� do importu)
# module - biblioteka ��czona dynamicznie przez dll-open
macro(__VERIFY_PROJECT_TYPE type)

	if(NOT (${type} STREQUAL "executable" OR ${type} STREQUAL "static" OR ${type} STREQUAL "dynamic" OR ${type} STREQUAL "module"))
		message(SEND_ERROR "Nieznany typ projektu dla ${PROJECT_NAME}. W�a�ciwa warto�� to: executable, static, dynamic lub module")
	endif()

endmacro(__VERIFY_PROJECT_TYPE)

###############################################################################

# Makro rozpoczynaj�ce konfiguracj� konkretnego projektu - powinno by� wywo�ywane jako pierwsza komenda po ADD_PROJECT zaraz na pocz�tku pliku konfiguracujnego projektu
# type Patrz makro VERIFY_PROJECT_TYPE
# opcjonalny argument to nazwa wyj�ciowa naszego artefaktu [dla release, dla debug dodajemy automatycznie d na koniec], domy�lnie jest to nazwa projektu
macro(BEGIN_PROJECT type)
	# weryfikujemy typ projektu
	__VERIFY_PROJECT_TYPE(${type})	
	#zapamietuje globalnie typ projektu aby pozniej go nie dodawa� jako zale�nego w przypadku execow
	set(PROJECT_${CURRENT_PROJECT_NAME}_TYPE ${type} CACHE INTERNAL "Typ projektu ${CURRENT_PROJECT_NAME}" FORCE )
	
	# je�li dodatkowy parametr to traktujemy go potencjalnie jako nazw� naszego artefaktu
	if(${ARGC} GREATER 1)
		# sprawdzam czy nazwa taka mo�e by� - czy nie jest pusta i czy nie mam ju� takiego artefaktu
		string(STRIP ${ARGV1} targetName)
		string(LENGTH ${targetName} targetNameLength)

		if(${targetNameLength} EQUAL 0)
			# pusta nazwa artefaktu - przywracamy domyslna nazwe projektu
			message(STATUS "Uwaga - podano pust� nazw� artefaktu dla projektu ${CURRENT_PROJECT_NAME}. Nazwa artefaktu zostaje ustawiona na nazw� projektu: ${TARGET_TARGETNAME}")
		elseif(DEFINED TARGET_NAME_${targetName})
			# zdefiniowano ju� tak� nazw� artefaktu - potencjalny problem, informuje o tym ale to nie jest krytyczne
			message(STATUS "Uwaga - arterfakt o podanej nazwie: ${targetName} zosta� ju� zdefiniowany dla projektu ${TARGET_NAME_${targetName}}. Mo�e to powodowa� b��dy przy budowie (nadpisywanie artefakt�w r�nych projekt�w) i by� myl�ce. Zaleca si� stosowanie unikalnych nazw artefakt�w.")
		else()
			# nazwa artefaktu wyglada ok
			message(STATUS "W�asna nazwa artefaktu: ${targetName} pomy�lnie przesz�a weryfikacj�")
			# aktualizujemy ja			
			set(PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME ${targetName} CACHE INTERNAL "Nazwa artefaktu projektu ${CURRENT_PROJECT_NAME}" FORCE )	
		endif()
		
	endif()

	# je�eli chemy plik wykonywalny i jeste�my na platformie windows to mo�emy wybra� czy ma to by� aplikacja z konsol� czy bez
	if(${type} STREQUAL "executable" AND WIN32)
		option(PROJECT_${CURRENT_PROJECT_NAME}_WIN32_ENABLE_CONSOLE "Enable console on Win32 for project ${CURRENT_PROJECT_NAME} on artifact ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME}?" ON)
	endif()

	# ostrze�enie je�li nasz projekt jest testowy a nie jest aplikacj�
	if(DEFINED PROJECT_IS_TEST AND NOT ${type} STREQUAL "executable")
		message(STATUS "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien by� kompilowany do pliku wykonywalnego (typ executable) a nie by� typu ${type}")
	endif()

	# resetujemy pliki projektowe
	set(PUBLIC_H)
	set(PRIVATE_H)
	set(SOURCE_FILES)
	set(CONFIG_FILES)
	set(UI_FILES)
	set(MOC_FILES)
	set(RC_FILES)
	set(RESOURCE_FILES)
	set(PRECOMPILED_H)
	set(PRECOMPILED_SRC)
	
	set(CONFIGURE_PRIVATE_HEADER_FILES)
	set(CONFIGURE_PUBLIC_HEADER_FILES)
	set(PROJECT_PUBLIC_HEADER_PATH)
	
	string(REPLACE "${SOLUTION_ROOT}/src" ${SOLUTION_INCLUDE_ROOT} PROJECT_PUBLIC_HEADER_PATH ${CMAKE_CURRENT_SOURCE_DIR})
	
	set(PROJECT_SOURCE_FILES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src")
	set(PROJECT_UI_FILES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/ui")
	set(PROJECT_CONFIGURATION_FILES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/configuration")
	set(PROJECT_RESOURCES_FILES_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources")
	set(PROJECT_DEPLOY_RESOURCES_FILES_PATH "${PROJECT_RESOURCES_FILES_PATH}/deploy")
	set(PROJECT_EMBEDDED_RESOURCES_FILES_PATH "${PROJECT_RESOURCES_FILES_PATH}/embedded")
	
	set(PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH "${CMAKE_CURRENT_BINARY_DIR}/public_configure_include")
	set(PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH "${CMAKE_CURRENT_BINARY_DIR}/private_configure_include")

endmacro(BEGIN_PROJECT)

###############################################################################

# Ustawiamy publiczne pliki nag��wkowe
macro(SET_PUBLIC_HEADERS)	

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien kompilowa� si� do pliku wykonywalnego i raczej nie powinien posiada� nag��wk�w publicznych.")
	endif()
	
	if(DEFINED PUBLIC_HEADERS_SET)
		message(WARNING "Publiczne nag��wki projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_PUBLIC_HEADERS mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam nag��wki ${ARGN}")
	else()
		# zapami�tujemy �e ju� by�a wo�ana ta metoda podczas konfiguracji aktualnego projektu
		set(PUBLIC_HEADERS_SET 1)
		# nag��wki publiczne
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES PUBLIC_H ${PROJECT_PUBLIC_HEADER_PATH})
		
		source_group("${SOURCEGROUP_PUBLIC_HEADERS}" FILES ${PUBLIC_H})
	endif()

endmacro(SET_PUBLIC_HEADERS)

###############################################################################

# Ustawiamy prywatne pliki nag��wkowe
macro(SET_PRIVATE_HEADERS)

	if(DEFINED PRIVATE_HEADERS_SET)
		message(WARNING "Prywatne nag��wki projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_PRIVATE_HEADERS mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam nag��wki ${ARGN}")
	else()
		# zapami�tujemy �e ju� by�a wo�ana ta metoda podczas konfiguracji aktualnego projektu
		set(PRIVATE_HEADERS_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES PRIVATE_H "${PROJECT_SOURCE_FILES_PATH}")
		
		source_group("${SOURCEGROUP_PRIVATE_HEADERS}" FILES ${PRIVATE_H})
	endif()

endmacro(SET_PRIVATE_HEADERS)

###############################################################################

# Ustawiamy pliki �r�d�owe
macro(SET_SOURCE_FILES)

	if(DEFINED SOURCE_FILES_SET)
		message(WARNING "Pliki �r�d�owe projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_SOURCE_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(SOURCE_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES SOURCE_FILES "${PROJECT_SOURCE_FILES_PATH}")
		source_group("${SOURCEGROUP_SOURCES}" FILES ${SOURCE_FILES})
	endif()

endmacro(SET_SOURCE_FILES)

###############################################################################

# Ustawiamy pliki UI
macro(SET_UI_FILES)

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien kompilowa� si� do pliku wykonywalnego konsolowego i raczej nie powinien posiada� UI")
	endif()

	if(DEFINED UI_FILES_SET)
		message(WARNING "Pliki UI projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_UI_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(UI_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES UI_FILES "${PROJECT_UI_FILES_PATH}")
		
		source_group("${SOURCEGROUP_UI}" FILES ${UI_FILES})
	endif()

endmacro(SET_UI_FILES)

###############################################################################

# Ustawiamy pliki MOC
macro(SET_MOC_FILES)	

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien kompilowa� si� do pliku wykonywalnego konsolowego i raczej nie powinien posiada� UI")
	endif()

	if(DEFINED MOC_FILES_SET)
		message(WARNING "Pliki MOC projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_MOC_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(MOC_FILES_SET 1)
		
		# pliki te musz� si� znale�� w kt�rej�� z wersji nag��wk�w prywatnych, publicznych, �r�d�ach lub konfiguracyjnych po konfiguracji
		set(MOC_FILES "")
		foreach(value ${ARGN})
			if(NOT DEFINED FILE_PATH_${value})
				message(WARNING "Plik ${value} nie zosta� zarejestrowany w projekcie ${CURRENT_PROJECT_NAME} a ma by� przetwarzany przez MOC z QT. Zarejestruj plik do jednej z podstawowych grup: PUBLIC_HEADERS, PRIVATE_HEADERS, SOURCES, plikach po konfiguracji. Pomijam plik")
			else()
				list(APPEND MOC_FILES "${FILE_PATH_${value}}")
			endif()
		endforeach()		
	endif()

endmacro(SET_MOC_FILES)

###############################################################################

# Ustawiamy pliki RC
macro(SET_RC_FILES)

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien kompilowa� si� do pliku wykonywalnego konsolowego i raczej nie powinien posiada� UI")
	endif()

	if(DEFINED RC_FILES_SET)
		message(WARNING "Pliki RC projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_RC_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(RC_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES RC_FILES "${PROJECT_UI_FILES_PATH}")
		
		source_group("${SOURCEGROUP_UI}" FILES ${RC_FILES})
	endif()

endmacro(SET_RC_FILES)

###############################################################################

# Ustawiamy pliki t�umacze�
macro(SET_TRANSLATION_FILES)

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest projektem testowym. Powinien kompilowa� si� do pliku wykonywalnego konsolowego i raczej nie powinien posiada� UI")
	endif()

	if(DEFINED TRANSLATION_FILES_SET)
		message(WARNING "Pliki translacji projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_TRANSLATION_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(TRANSLATION_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES TRANSLATION_FILES "${PROJECT_UI_FILES_PATH}")

		if(NOT EXISTS "${PROJECT_UI_FILES_PATH}")
			message(WARNING "Katalog ${PROJECT_UI_FILES_PATH} nie istnieje cho� wskazano pliki t�umacze� ${ARGN}. Tworz� podany katalog.")
			file(MAKE_DIRECTORY "${PROJECT_UI_FILES_PATH}")
		endif()
		
		source_group("${SOURCEGROUP_UI}" FILES ${TRANSLATION_FILES})
	endif()

endmacro(SET_TRANSLATION_FILES)

###############################################################################

# Ustawiamy pliki konfiguracyjne (niekoniecznie CMake musi je potem przetwarzac, ale inne nie b�d� mogly byc przetwarzane)
macro(SET_CONFIGURATION_INPUT_FILES)

	if(DEFINED CONFIGURATION_INPUT_FILES_SET)
		message(WARNING "Pliki konfiguracyjne projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_CONFIGURATION_INPUT_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(CONFIGURATION_INPUT_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES CONFIGURATION_INPUT_FILES "${PROJECT_CONFIGURATION_FILES_PATH}")
		source_group("${SOURCEGROUP_CONFIGURATION_TEMPLATE_FILES}" FILES ${CONFIGURATION_INPUT_FILES})
	endif()

endmacro(SET_CONFIGURATION_INPUT_FILES)

###############################################################################

# Ustawiamy pliki konfiguracyjne (niekoniecznie CMake musi je potem przetwarzac, ale inne nie b�d� mogly byc przetwarzane)
macro(SET_CONFIGURATION_OUTPUT_FILES)

	if(DEFINED CONFIGURATION_OUTPUT_FILES_SET)
		message(WARNING "Pliki konfiguracyjne projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_CONFIGURATION_OUTPUT_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(CONFIGURATION_OUTPUT_FILES_SET 1)
		set(CONFIGURATION_OUTPUT_FILES ${ARGN})
		source_group("${SOURCEGROUP_CONFIGURATION_INSTANCE_FILES}" FILES ${CONFIGURATION_OUTPUT_FILES})
	endif()

endmacro(SET_CONFIGURATION_OUTPUT_FILES)

###############################################################################

# Ustawiamy pliki resources
macro(SET_DEPLOY_RESOURCES_FILES)

	if(DEFINED DEPLOY_RESOURCES_FILES_SET)
		message(WARNING "Pliki resources projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_DEPLOY_RESOURCES_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(DEPLOY_RESOURCES_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES DEPLOY_RESOURCES_FILES "${PROJECT_DEPLOY_RESOURCES_FILES_PATH}")
		source_group("${SOURCEGROUP_RESOURCES_FILES}/deploy" FILES ${DEPLOY_RESOURCES_FILES})
	endif()

endmacro(SET_DEPLOY_RESOURCES_FILES)

###############################################################################

# Ustawiamy pliki resources
macro(SET_EMBEDDED_RESOURCES_FILES)

	if(DEFINED EMBEDDED_RESOURCES_FILES_SET)
		message(WARNING "Pliki resources projektu ${CURRENT_PROJECT_NAME} zosta�y ju� ustawione. Makro SET_EMBEDDED_RESOURCES_FILES mo�e by� u�yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(EMBEDDED_RESOURCES_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES EMBEDDED_RESOURCES_FILES "${PROJECT_EMBEDDED_RESOURCES_FILES_PATH}")
		source_group("${SOURCEGROUP_RESOURCES_FILES}/embedded" FILES ${EMBEDDED_RESOURCES_FILES})
	endif()

endmacro(SET_EMBEDDED_RESOURCES_FILES)

###############################################################################

# Konfigurujemy publiczne pliki
macro(CONFIGURE_PUBLIC_HEADER inFile outFile)

	set(P_NAME ${CURRENT_PROJECT_NAME})

	if(DEFINED PROJECT_IS_TEST)
		set(P_NAME ${ORIGINAL_PROJECT_NAME_${CURRENT_PROJECT_NAME}})
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Nie powinien posiadac plik�w nag��wkowych publicznych tylko kompilowa� si� do pliku wykonywalnego")
	endif()
	
	if(NOT DEFINED FILE_PATH_${inFile})
		message(WARNING "Plik ${inFile} nie zosta� zarejestrowany w projekcie ${CURRENT_PROJECT_NAME} a ma by� konfigurowany przez CMake. Zarejestruj plik wsr�d plik�w konfiguracyjnych. Pomijam plik")
	else()
		set(CONFIG_FOUND 0)
		list(FIND CONFIGURATION_INPUT_FILES ${inFile} CONFIG_FOUND)
		if(${CONFIG_FOUND})		
			configure_file("${FILE_PATH_${inFile}}" "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${P_NAME}/${outFile}")
			list(APPEND CONFIGURE_PUBLIC_HEADER_FILES "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${P_NAME}/${outFile}")
		else()
			message(WARNING "Plik ${inFile} nie zosta� zarejestrowany w projekcie ${P_NAME} jako typ pliku konfiguracyjnego a ma by� konfigurowany przez CMake. Zarejestruj plik wsr�d plik�w konfiguracyjnych makrem SET_CONFIGURATION_FILES. Pomijam plik")
		endif()
	endif()

endmacro(CONFIGURE_PUBLIC_HEADER)

###############################################################################

# Konfigurujemy prywatne pliki
macro(CONFIGURE_PRIVATE_HEADER inFile outFile)
	if(NOT DEFINED FILE_PATH_${inFile})
		message(WARNING "Plik ${inFile} nie zosta� zarejestrowany w projekcie ${CURRENT_PROJECT_NAME} a ma by� konfigurowany przez CMake. Zarejestruj plik wsr�d plik�w konfiguracyjnych. Pomijam plik")
	else()		
		set(CONFIG_FOUND 0)
		list(FIND CONFIGURATION_INPUT_FILES ${inFile} CONFIG_FOUND)
		if(${CONFIG_FOUND})
			configure_file("${FILE_PATH_${inFile}}" "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}/${outFile}")
			list(APPEND CONFIGURE_PRIVATE_HEADER_FILES "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}/${outFile}")
		else()
			message(WARNING "Plik ${inFile} nie zosta� zarejestrowany w projekcie ${CURRENT_PROJECT_NAME} jako typ pliku konfiguracyjnego a ma by� konfigurowany przez CMake. Zarejestruj plik wsr�d plik�w konfiguracyjnych makrem SET_CONFIGURATION_FILES. Pomijam plik")
		endif()
		
	endif()

endmacro(CONFIGURE_PRIVATE_HEADER)

###############################################################################

# Makro ustawiajace naglowki prekompilowane
# Parametry:
	# header Nag��wek precompilowany
	# source Plik �r�d�owy na kt�rym kompilujemy nag��wek
	
MACRO(SET_PRECOMPILED_HEADER header source)

	set(PRECOMPILED_FOUND 1)

	if(NOT DEFINED FILE_PATH_${header})
		message(WARNING "Proba dodania pliku ${header} niezarejestrowanego w projekcie ${CURRENT_PROJECT_NAME} jako nag�owka prekompilowanego. Zarejestruj plik w projekcie do jednej z podstawowych grup a potem ustaw go jako nag�owek prekompilowany. Pomijam prekompilowane nag�owki.")
		set(PRECOMPILED_FOUND 0)
	endif()
	
	if(NOT DEFINED FILE_PATH_${source})
		message(WARNING "Proba dodania pliku ${source} niezarejestrowanego w projekcie ${CURRENT_PROJECT_NAME} jako nag�owka prekompilowanego. Zarejestruj plik w projekcie do jednej z podstawowych grup a potem ustaw go jako nag�owek prekompilowany. Pomijam prekompilowane nag�owki.")
		set(PRECOMPILED_FOUND 0)
	endif()
	
	if(${PRECOMPILED_FOUND} EQUAL 1)
		set(PRECOMPILED_H ${header})
		set(PRECOMPILED_SRC ${source})
	endif()
ENDMACRO(SET_PRECOMPILED_HEADER)

# ###############################################################################

# Ko�czymy dodawanie projektu
macro(END_PROJECT)

	set(TARGET_MOC_SRC)
	set(TARGET_UI_H)
	set(TARGET_RC_SRC)
	set(QM_OUTPUTS)
	set(PROJECT_PUBLIC_INCLUDES)
	set(PROJECT_PRIVATE_INCLUDES)
	
	# wszystkie pliki nag��wkowe
	set(TARGET_H ${PUBLIC_H} ${PRIVATE_H})
	
	if(DEFINED CONFIGURATION_INPUT_FILES)
		list(APPEND TARGET_H ${CONFIGURATION_INPUT_FILES})
		
		if(DEFINED CONFIGURATION_OUTPUT_FILES)
			list(APPEND TARGET_H ${CONFIGURATION_OUTPUT_FILES})
		endif()
		
		if(DEFINED CONFIGURE_PRIVATE_HEADER_FILES)
			list(APPEND TARGET_H ${CONFIGURE_PRIVATE_HEADER_FILES})
			source_group("${SOURCEGROUP_PRIVATE_HEADERS}" FILES ${CONFIGURE_PRIVATE_HEADER_FILES})
		endif()
		
		if(DEFINED CONFIGURE_PUBLIC_HEADER_FILES)
			list(APPEND TARGET_H ${CONFIGURE_PUBLIC_HEADER_FILES})
			source_group("${SOURCEGROUP_PUBLIC_HEADERS}" FILES ${CONFIGURE_PUBLIC_HEADER_FILES})
		endif()
		
	endif()
	
	set(TARGET_SRC ${SOURCE_FILES})
	
	# nag�owki prekompilowane
	if(DEFINED PRECOMPILED_H AND DEFINED PRECOMPILED_SRC)
		if(MSVC)
			list(REMOVE_ITEM TARGET_SRC "${FILE_PATH_${PRECOMPILED_SRC}}")
			get_filename_component(_basename ${PRECOMPILED_H} NAME_WE)
			set(_binary "${CMAKE_CURRENT_BINARY_DIR}/${_basename}.pch")
			set_source_files_properties(${FILE_PATH_${PRECOMPILED_SRC}}
				PROPERTIES COMPILE_FLAGS "/Yc\"${PRECOMPILED_H}\" /Fp\"${_binary}\""
				OBJECT_OUTPUTS "${_binary}")
			set_source_files_properties(${TARGET_SRC}
				PROPERTIES COMPILE_FLAGS "/Yu\"${_binary}\" /FI\"${_binary}\" /Fp\"${_binary}\""
				OBJECT_DEPENDS "${_binary}")
			set( TARGET_SRC ${TARGET_SRC} "${FILE_PATH_${PRECOMPILED_SRC}}")
		else()
			list(APPEND PROJECT_${CURRENT_PROJECT_NAME}_COMPILER_DEFINITIONS DISABLE_PRECOMPILED_HEADERS)
		endif()
	endif()
	
	# generujemy pliki specyficzne dla QT
	# tutaj Qt jest traktowane specjalnie - poniewa� u�ywam jego makr wie musze zagwarnatowa� �e go tutaj szukam je�li to konieczne i �e go tu znajduj�!
	if(DEFINED UI_FILES OR DEFINED MOC_FILES OR DEFINED RC_FILES OR DEFINED TRANSLATION_FILES)
		
		if(NOT DEFINED LIBRARY_QT_FOUND)
			find_package(QT)
		endif()
		
		if(NOT LIBRARY_QT_FOUND)
			message(FATAL_ERROR "Projekt jest zale�ny od biblioteki Qt, kt�rej nie znaleziono. Wska� bibliotek� Qt i przekonfiguruj solucj� CMake.")
		endif()
		
	endif()
	
	# UI
	if(DEFINED UI_FILES)
		list(LENGTH UI_FILES uiLength)
		if(${uiLength} GREATER 0)
			QT4_WRAP_UI(TARGET_UI_H ${UI_FILES})
			source_group("${SOURCEGROUP_GENERATED_UI}" FILES ${TARGET_UI_H})
			list(APPEND TARGET_H ${TARGET_UI_H})
			#TODO
			#jak tu wyci�ga� �cie�k� do generowanych plik�w ui_*.h? czy nie powinno tego robi� makro QT4_WRAP_UI
			#powinni�my rozr�nia� widgety publiczne i prywatne aby odpowiednio generowa� pliki ui_*.h i instalowa� tylko publiczne
			#to wp�ynie r�wnie� na spos�b includowania takich plik�w - publiczne b�d� widziane jak publiczne nag��wki, a prywatne tak jak prywatne nag��wki
			list(APPEND PROJECT_PUBLIC_INCLUDES "${CMAKE_CURRENT_BINARY_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}")
		endif()
	endif()
	
	# MOC
	if(DEFINED MOC_FILES)
		list(LENGTH MOC_FILES mocLength)
		if(${mocLength} GREATER 0)			
			QT4_WRAP_CPP(TARGET_MOC_SRC ${MOC_FILES})			
			source_group("${SOURCEGROUP_GENERATED_UI}" FILES ${TARGET_MOC_SRC})
			list(APPEND TARGET_SRC ${TARGET_MOC_SRC})
		endif()
	endif()
	
	# RC
	if(DEFINED RC_FILES)
		list(LENGTH RC_FILES rcLength)
		if(${rcLength} GREATER 0)
			QT4_ADD_RESOURCES(TARGET_RC_SRC ${RC_FILES})
			source_group("${SOURCEGROUP_GENERATED_UI}" FILES ${TARGET_RC_SRC})
			list(APPEND TARGET_SRC ${TARGET_RC_SRC})
		endif()
	endif()
	
	# ustawiam wszystkie pliki projektu
	set(ALL_SOURCES ${TARGET_SRC} ${TARGET_H})
		
	# faktycznie ustawiam typ projektu
	if(${PROJECT_${CURRENT_PROJECT_NAME}_TYPE} STREQUAL "executable")
		# plik wykonywalny
		if(WIN32)
			# tutaj mo�emy mie� aplikacj� z konsol� lub bez
			if(PROJECT_${CURRENT_PROJECT_NAME}_WIN32_ENABLE_CONSOLE)
				# konsola
				add_executable(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} ${ALL_SOURCES})
			else()
				# bez konsoli
				add_executable(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} WIN32 ${ALL_SOURCES})
			endif()
		else()
			# dodajemy zwykly plik wykonywalny dla innych platform
			add_executable(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} ${ALL_SOURCES})
			# instalacja skrypt�w uruchomieniowych dla linux
			if(UNIX)
				GENERATE_UNIX_EXECUTABLE_SCRIPT()
			endif()
		endif()
		
		if(NOT DEFINED PROJECT_IS_TEST)
			# instalacja
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME})
		endif()
	elseif(${PROJECT_${CURRENT_PROJECT_NAME}_TYPE} STREQUAL "static")
		# biblioteka statyczna
		add_library(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} STATIC ${ALL_SOURCES})
		# instalacja		
		install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} ARCHIVE DESTINATION lib COMPONENT ${CURRENT_PROJECT_NAME}_dev)
	else(${PROJECT_${CURRENT_PROJECT_NAME}_TYPE} STREQUAL "dynamic")
		# biblioteka dynamiczna
		add_library(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} SHARED ${ALL_SOURCES})
		
		# instalacja
		if(WIN32)
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME})
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} RUNTIME DESTINATION bin ARCHIVE DESTINATION lib COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		elseif(UNIX)
			set_target_properties(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME})
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		endif()
	else()
		# biblioteka dynamiczna
		add_library(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} MODULE ${ALL_SOURCES})
		# instalacja
		if(WIN32)
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME})
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		elseif(UNIX)
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME})
			install(TARGETS ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		endif()		
	endif()
	
	if(NOT DEFINED PROJECT_IS_TEST)
	
		#instalacja publicznych naglowkow - zachowujemy strukture
		foreach(f ${PUBLIC_H})
			get_filename_component(FPATH ${f} PATH)
			string(REPLACE ${SOLUTION_INCLUDE_ROOT} "" RELPATH ${FPATH})
			install(FILES ${f} DESTINATION include/${RELPATH} COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		endforeach()
		
		#instalacja konfigurowanych publicznych naglowkow
		foreach(f ${CONFIGURE_PUBLIC_HEADER_FILES})
			get_filename_component(FPATH ${f} PATH)
			string(REPLACE "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}" "" RELPATH ${FPATH})
			install(FILES ${f} DESTINATION include/${RELPATH} COMPONENT ${CURRENT_PROJECT_NAME}_dev)
		endforeach()
		
	endif()
	
	# t�umczenia
	if(DEFINED TRANSLATION_FILES)
	
		list(LENGTH TRANSLATION_FILES langLength)
		if(${langLength} GREATER 0)
	
			set(DEBUG_LANG_OUTPUT "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/resources/lang")
			set(RELEASE_LANG_OUTPUT "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release/resources/lang")
	
			foreach(lang ${TRANSLATION_FILES})
				GET_FILENAME_COMPONENT(lang_name ${lang} NAME_WE)
				list(APPEND QM_OUTPUTS "${CMAKE_CURRENT_BINARY_DIR}/${lang_name}.qm")
				
				add_custom_command(TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PRE_BUILD
					# Debug
					COMMAND ${CMAKE_COMMAND} -E remove "${DEBUG_LANG_OUTPUT}/${lang_name}.qm"
					# Release
					COMMAND ${CMAKE_COMMAND} -E remove "${RELEASE_LANG_OUTPUT}/${lang_name}.qm"
					VERBATIM
				)
				
			endforeach()
			
			add_custom_command(TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} POST_BUILD
				# TS
				COMMAND ${QT_LUPDATE_EXECUTABLE} ${TARGET_H} ${TARGET_SRC} -ts ${TRANSLATION_FILES}
				VERBATIM
			)
			
			foreach(lang ${QM_OUTPUTS})
				add_custom_command(TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} POST_BUILD
					# QM
					COMMAND ${QT_LRELEASE_EXECUTABLE} ${TRANSLATION_FILES} -qm ${lang}
					# kopiowanie do odpowiednich katalog�w
					COMMAND ${CMAKE_COMMAND} -E copy ${lang} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/resources/lang"
					COMMAND ${CMAKE_COMMAND} -E copy ${lang} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release/resources/lang"
					VERBATIM
				)
			endforeach()
			
			install(FILES ${QM_OUTPUTS} DESTINATION bin/resources/lang/ COMPONENT ${CURRENT_PROJECT_NAME})
		endif()
	endif()
	
	# ustawiamy nazwe dla artefaktow wersji debug tak aby do nazwy na koniec by�o doklejane d, dla release bez zmian
	set_target_properties(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTIES DEBUG_POSTFIX "d")
	
	# TODO
	# resources - kopiowanie
	# resources instalowanie
	
	# ustawiamy includy projektu
	# wszystkie includy projektu - publiczne, prywatne + konfigi
	#TODO
	#wymagana reorganizacja includ�w w strukturze, tak by wymusza� podawanie zale�no�ci pomi�dzy bibliotekami w celu udost�pniania publicznych nag��wk�w
	#struktura includ�w powinna wygl�da� tak: include/dirName/dirName/tu_sa_wlasciwe_includy
	#wtedy dany projekt ma dost�p do swojego: include/dirName
	#a je�li chce u�y� innych to musi by� od nich jawnie uzale�niony
	#aktualnie ka�dy ma dost�p do publicznych nag��k�w ka�dego innego projektu	
	list(APPEND PROJECT_PRIVATE_INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}/src" "${SOLUTION_INCLUDE_ROOT}")

	# prywatne i publiczne includy po konfiguracji
	list(LENGTH CONFIGURE_PRIVATE_HEADER_FILES APPEND_PRIVATE)
	if(${APPEND_PRIVATE} GREATER 0)
		if(EXISTS "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}")
			list(APPEND PROJECT_PRIVATE_INCLUDES "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}")
		else()
			message(SEND_ERROR "Zarejestrowano pliki konfiguracyjne prywatne, ale ich katalog docelowy nie istnieje. Nie mo�na do��czy� tych plik�w jako includy")
		endif()
	endif()
	
	list(LENGTH CONFIGURE_PUBLIC_HEADER_FILES APPEND_PUBLIC)
	if(${APPEND_PUBLIC} GREATER 0)
		if(EXISTS "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}")
			list(APPEND PROJECT_PUBLIC_INCLUDES "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}")
		else()
			message(SEND_ERROR "Zarejestrowano pliki konfiguracyjne publiczne, ale ich katalog docelowy nie istnieje. Nie mo�na do��czy� tych plik�w jako includy")
		endif()
	endif()
	
	# ustawiamy grup� projektu je�li by�a podana
	string(LENGTH ${PROJECT_${CURRENT_PROJECT_NAME}_GROUP} PROJECT_GROUP_LENGTH)
	if(PROJECT_GROUP_LENGTH GREATER 0)
		SET_PROPERTY(TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTY FOLDER "${PROJECT_${CURRENT_PROJECT_NAME}_GROUP}")
	endif()
	
	# ustawiam zale�no�ci
	set(USED_DEPENDECIES "")
	set(PROJECT_LIBRARIES "")
	set(PROJECT_COMPILER_DEFINITIONS ${PROJECT_${CURRENT_PROJECT_NAME}_COMPILER_DEFINITIONS})
	set(PROJECT_COMPILER_FLAGS ${PROJECT_${CURRENT_PROJECT_NAME}_COMPILER_FLAGS})
	
	foreach(value ${PROJECT_${CURRENT_PROJECT_NAME}_DEPENDENCIES})
		TARGET_NOTIFY(${CURRENT_PROJECT_NAME} "RAW DEPENDENCY ${value} libraries: ${${value}_LIBRARIES}")
		
		if(${value} STREQUAL ${CURRENT_PROJECT_NAME} AND NOT DEFINED SELF_DEPENDENCY)
			message(WARNING "Projekt ${CURRENT_PROJECT_NAME} nie moze by� rekurencyjnie zalezny od samego siebie. Pomijam zale�no��...")
			set(SELF_DEPENDENCY 1)
		else()			
			#szukam czy zadana zale�no�� nie by�a ju� dodana
			list(FIND USED_DEPENDECIES ${value} DEPENDENCY_USED)
			if(${DEPENDENCY_USED} GREATER -1 AND NOT DEFINED ${value}_DUPLICATED_DEPENDENCY)
				set(${value}_DUPLICATED_DEPENDENCY 1)
				message(WARNING "Dla projektu ${CURRENT_PROJECT_NAME} zale�no�� ${value} ju� zosta�a dodana i powtarza si�. Zostanie ona teraz pomini�ta.")
			else()
				# zapami�tuj� �e zale�no�c ju� zosta�a u�yta
				list(APPEND USED_DEPENDECIES ${value})
				# czy to nasz projekt czy zale�no��?
				list(FIND SOLUTION_PROJECTS ${value} IS_PROJECT)
				
				if(IS_PROJECT GREATER -1)
					#nasz projekt
					if(PROJECT_${value}_TYPE STREQUAL "executable")
						message(WARNING "Projekt ${CURRENT_PROJECT_NAME} jest zale�ny od projektu ${value} kt�ry jest plikiem wykonywalnym. Pomijam ten projekt w zale�no�ciach")
					else()					
						add_dependencies(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} ${PROJECT_${value}_TARGETNAME})
						list(APPEND PROJECT_LIBRARIES ${PROJECT_${value}_TARGETNAME})
						list(APPEND PROJECT_LIBRARIES ${PROJECT_${value}_LIBRARIES})
						list(APPEND PROJECT_PUBLIC_INCLUDES ${PROJECT_${value}_INCLUDE_DIRS})
						list(APPEND PROJECT_COMPILER_DEFINITIONS ${PROJECT_${value}_COMPILER_DEFINITIONS})
						list(APPEND PROJECT_COMPILER_FLAGS ${PROJECT_${value}_COMPILER_FLAGS})
					endif()
				else()
				
					# biblioteki zale�ne
					foreach(value2 ${${value}_LIBRARIES})
						list(APPEND PROJECT_LIBRARIES ${${value2}})
					endforeach()
					
					# dodatkowe definicje wynikaj�ce z bibliotek zale�nych
					if(DEFINED ${value}_COMPILER_DEFINITIONS)						
						list(APPEND PROJECT_COMPILER_DEFINITIONS ${${value}_COMPILER_DEFINITIONS})
					endif()
					
					# dodatkowe flagi kompilacji wynikaj�ce z bibliotek zale�nych (np. OpenMP)
					if(DEFINED ${value}_COMPILER_FLAGS)
						message("Compiler flags ${value} : ${${value}_COMPILER_FLAGS}")						
						list(APPEND PROJECT_COMPILER_FLAGS ${${value}_COMPILER_FLAGS})
					endif()
					
					# includy bibliotek zaleznych
					if(DEFINED ${value}_INCLUDE_DIR)
						list(APPEND PROJECT_PUBLIC_INCLUDES ${${value}_INCLUDE_DIR})
					endif()
					
					# includy bibliotek zaleznych
					if(DEFINED ${value}_INCLUDE_CONFIG_DIR)					
						list(APPEND PROJECT_PUBLIC_INCLUDES ${${value}_INCLUDE_CONFIG_DIR})
					endif()
				endif()
			endif()
		endif()
	endforeach()	
	
	list(REMOVE_DUPLICATES PROJECT_PUBLIC_INCLUDES)
	set(PROJECT_${CURRENT_PROJECT_NAME}_INCLUDE_DIRS ${PROJECT_PUBLIC_INCLUDES} CACHE INTERNAL "�cie�ka do includ�w projektu ${CURRENT_PROJECT_NAME}" FORCE)
	
	set(PROJECT_${CURRENT_PROJECT_NAME}_LIBRARIES "${PROJECT_LIBRARIES}" CACHE INTERNAL "Definicje kompilatora dla projektu ${CURRENT_PROJECT_NAME}" FORCE )
	
	# ustawiamy definicje kompilacji projektu wynikaj�ce z jego zale�no�ci
	list(REMOVE_DUPLICATES PROJECT_COMPILER_DEFINITIONS)
	list(LENGTH PROJECT_COMPILER_DEFINITIONS DEF_COUNT)
	if(${DEF_COUNT} GREATER 0)
		list(REMOVE_DUPLICATES PROJECT_COMPILER_DEFINITIONS)
		set_target_properties(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTIES COMPILE_DEFINITIONS "${PROJECT_COMPILER_DEFINITIONS}")
		set(PROJECT_${CURRENT_PROJECT_NAME}_COMPILER_DEFINITIONS ${PROJECT_COMPILER_DEFINITIONS} CACHE INTERNAL "Definicje kompilatora dla projektu ${CURRENT_PROJECT_NAME}" FORCE )
	endif()
	
	# ustawiamy flagi kompilacji dla projektu
	if(DEFINED PROJECT_COMPILER_FLAGS)
		list(LENGTH PROJECT_COMPILER_FLAGS flagsLength)
		if(${flagsLength} GREATER 0)
			list(REMOVE_DUPLICATES PROJECT_COMPILER_FLAGS)
			set_target_properties(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTIES COMPILE_FLAGS "${PROJECT_COMPILER_FLAGS}")			
		endif()
	endif()
	
	set(PROJECT_ALL_INCLUDES ${PROJECT_PUBLIC_INCLUDES})
	list(APPEND PROJECT_ALL_INCLUDES ${PROJECT_PRIVATE_INCLUDES})
	
	# includy
	set_target_properties(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} PROPERTIES INCLUDE_DIRECTORIES "${PROJECT_ALL_INCLUDES}")
	
	# biblioteki do linkowania
	#hack - podw�jnie �eby dobrze wyznaczy� zale�no�ci pomi�dzy projektami i bibliotekami zale�nymi (kolejno�� linkowania)
	target_link_libraries(${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} ${PROJECT_LIBRARIES})
	
	# info ze poprawnie zakonczylismy dodawanie projektu
	set(PROJECT_ADD_FINISHED 1 PARENT_SCOPE)
	
	if(DEFINED PROJECT_IS_TEST)
		add_test(NAME ${CURRENT_PROJECT_NAME} COMMAND ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME})
		set(PROJECT_IS_TEST)
	endif()	
	
endmacro(END_PROJECT)

###############################################################################

# Makro ustawiaj�ce pewn� opcj� konfiguracji.
# Parametry:
#	name	Nazwa makra.
#	info	Tekstowa informacja o opcji.
#	default	ON / OFF
macro(CONFIG_OPTION name info default)
	option(CONFIG_${name} ${info} ${default})
	if (CONFIG_${name})
		set(${name} ${name})
	endif()
endmacro(CONFIG_OPTION)

###############################################################################

macro(TARGET_NOTIFY var msg)
	if (TARGET_VERBOSE)
		message(STATUS "TARGET>${var}>${msg}")
	endif()
endmacro()
