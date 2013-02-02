###############################################################################

# Makro ustawiaj¹ce folder dla kolejnych projektów
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

# Makro tworz¹ce prawdziwe œcie¿ki plików
# Parametry
#	in Lista wejœciowa z nazwami plików do przetworzenia
#	out Lista wyjœciowa z œcie¿kami plików po przetworzeniu
#   path Œcie¿ka w której powinny znajdowaæ siê pliki wejsciowe
macro(GENERATE_FILE_PATHS in out path)

	set(${out} "")
	# ustalamy poprawn¹ œcie¿kê do pliku wzglêdem aktualnego katalogu
	foreach(value ${${in}})
		set(CANDIDATE_PATH "${path}/${value}")
		if(DEFINED FILE_PATH_${value})
			if(${CANDIDATE_PATH} STREQUAL FILE_PATH_${value})
				message(WARNING "Plik o nazwie ${value} by³ ju¿ dodany w projekcie. Nie ma potrzeby dodawaæ go ponownie - mo¿e to byæ przyczyn¹ b³êdnego przydzielenia pliku do grup. Pomijam plik.")
			else()
				message(SEND_ERROR "Plik o nazwie ${value} by³ ju¿ dodany w projekcie pod scie¿k¹ ${FILE_PATH_${value}}. Teraz ma byæ dodany pod œcie¿k¹ ${path}/${value}. Nazwy plików musz¹ byæ unikalne w projekcie")
			endif()
		else()
			list(APPEND ${out} "${CANDIDATE_PATH}")
			set(FILE_PATH_${value} "${CANDIDATE_PATH}")
		endif()
	endforeach()

endmacro(GENERATE_FILE_PATHS)

###############################################################################

# Makro tworz¹ce prawdziwe œcie¿ki plików po ich rejestracji
# Parametry
#	in Lista wejœciowa z nazwami plików do przetworzenia
#	out Lista wyjœciowa z œcie¿kami plików po przetworzeniu
macro(REGENERATE_FILE_PATHS in out)

	set(${out} "")
	# ustalamy poprawn¹ œcie¿kê do pliku wzglêdem aktualnego katalogu
	foreach(value ${${in}})
		if(DEFINED FILE_PATH_${value})
			list(APPEND ${out} "${FILE_PATH_${value}}")
		else()
			message(WARNING "Plik ${value} nie by³ wczeœniej rejestrowany. Nie mo¿na odtworzyæ jego œcie¿ki. Pomijam plik")
		endif()
	endforeach()

endmacro(REGENERATE_FILE_PATHS)

###############################################################################

# Makro dodaj¹ce projekt
# Parametry
#	name Nazwa projektu
#	dodatkowy parametr dependencies Lista zale¿noœci
#   dodatkowy parametr za dependencies to string ze œcie¿k¹ do projektu
#   dodatkowy parametr to info czy faktycznie projekt dodajemy czy nie
macro(ADD_PROJECT name)

	# sprawdzamy czy faktycznie robimy coœ z projektem
	set(PROCESS_PROJECT 1)
	if(${ARGC} GREATER 3)
		if(NOT ${ARGV3})
			set(PROCESS_PROJECT 0)
		endif()
	endif()
	
	if(${PROCESS_PROJECT})

		if(DEFINED PROJECT_ADD_FINISHED)
			if(${PROJECT_ADD_FINISHED} EQUAL 0)
				# b³¹d konfigurowania projektu - rozpoczêlismy ale nie by³o makra PROJECT_END()!!!
				message(SEND_ERROR "B³¹d konfiguracji: Rozpoczêto konfiguracjê projektu ${PROJECT_NAME} ale nie zakoñczono jej makrem END_PROJECT()")
			endif()
		else()
			# info ¿e rozpoczynamy dodawanie nowego projektu ale jeszcze go nie zamknêlismy makrem END_PROJECT()	
			set(PROJECT_ADD_FINISHED 0 PARENT_SCOPE)
		endif()

		# nazwa projektu
		project(${name})
		
		# œcie¿ka projektu - domyœlnie nazwa projektu
		set(PROJECT_NAME_${name} ${name})
		
		# jeœli dodatkowy parametr to traktujemy go jako œcie¿kê do projektu
		if(${ARGC} GREATER 2)		
			set(PROJECT_NAME_${name} ${ARGV2})
		endif()
		
		set(PROJECT_NAME_${name} ${PROJECT_NAME_${name}} CACHE INTERNAL "Globalna zmienna pomagajaca sprawdzic czy projekt o nazwie ${name} byl juz dodany, trzyma jego œcie¿kê")
		
		# czy dodawanie projektu zakoñczy³o siê b³êdem
		set(ADD_PROJECT_FAILED 0)
		# wiadomoœæ projektu
		set(ADD_PROJECT_MESSAGE "")	
		# resetujemy listê zale¿noœci
		set(dependencies)
		set(gain)
		# czy podano zale¿noœci
		if(${ARGC} GREATER 1)
			set(dependencies ${ARGV1})
			list(LENGTH dependencies depLength)
			if(${depLength} GREATER 0)				
				# szukamy wszystkich brakuj¹cych zale¿noœci
				foreach (value ${dependencies})
					if (NOT ${value}_FOUND)
						set(ADD_PROJECT_FAILED 1)
						set(ADD_PROJECT_MESSAGE ${value} ", " ${ADD_PROJECT_MESSAGE})
						TARGET_NOTIFY(${name} "${value} not found")
					endif()
					if (DEFINED ${value}_DEPENDENCIES)
						list(APPEND gain ${${value}_DEPENDENCIES})
					endif()
				endforeach()
				if (DEFINED gain)
					list(APPEND dependencies ${gain})
					list(REMOVE_DUPLICATES dependencies)
				endif()
			else()
				# resetujemy listê zale¿noœci
				set(dependencies)
			endif()
		endif()
		# sprawdzamy
		if (ADD_PROJECT_FAILED)
			# brakuje zale¿noœci - wyœwietlamy komunikat
			message(${name} " not included because dependencies are missing: " ${ADD_PROJECT_MESSAGE})
		else()
			set (DEFAULT_PROJECT_DEPENDENCIES "")
			if(DEFINED dependencies)
				# zachowujemy liste zaleznosci
				set (${name}_DEPENDENCIES ${dependencies} CACHE INTERNAL "")
				# wszystko ok - mo¿emy kontynuowaæ, zapamiêtujemy zale¿noœci projektu na dalszy u¿ytek
				set (DEFAULT_PROJECT_DEPENDENCIES ${dependencies})
			endif()
			
			# dalej konfigurujemy projekt
			if(DEFINED PROJECT_IS_TEST)
				add_subdirectory("${ORIGINAL_PROJECT_NAME_${name}}")
			else()
				add_subdirectory("${PROJECT_NAME_${name}}")
			endif()
		endif()
	else()
		message("Pomijam projekt ${name}")
	endif()
endmacro(ADD_PROJECT)

###############################################################################

# Makro dodaj¹ce projekt testu
# Parametry
#	name Nazwa projektu
#	dependencies Lista zale¿noœci
#   dodatkowy parametr za dependencies to string ze œcie¿k¹ do projektu testu wzglêdem katalogu tests
#   dodatkowy parametr to info czy faktycznie projekt dodajemy czy nie
macro(ADD_TEST_PROJECT name dependencies)

	set(PROJECT_IS_TEST 1)
	set(newName "test_${name}")
	set(ORIGINAL_PROJECT_NAME_${newName} ${name} CACHE INTERNAL "")
	
	set(newDependecies ${dependencies})
	
	# rozszerzamy zale¿noœci o bilbioteki potrzebne dla testów
	if(DEFINED TESTS_DEPENDENCIES)
		list(LENGTH TESTS_DEPENDENCIES testLength)
		if(${testLength} GREATER 0)
			set(newDependecies ${newDependecies} ${TESTS_DEPENDENCIES})
		endif()
	endif()
	
	ADD_PROJECT(${newName} "${newDependecies}" ${ARGN})
	
endmacro(ADD_TEST_PROJECT)

###############################################################################

macro(ADD_PROJECTS name)

	add_subdirectory(${name})
	
endmacro(ADD_PROJECTS)

###############################################################################

# Makro weryfikuj¹ce typ projektu
# type Typ projektu:
# executable - plik wykonywalny
# static - biblioteka ³¹czona statycznie
# dynamic - biblioteka ³¹czona dynamicznie (z libk¹ do importu)
# module - biblioteka ³¹czona dynamicznie przez dll-open
macro(VERIFY_PROJECT_TYPE type)

	if(NOT (${type} STREQUAL "executable" OR ${type} STREQUAL "static" OR ${type} STREQUAL "dynamic" OR ${type} STREQUAL "module"))
		message(SEND_ERROR "Nieznany typ projektu dla ${PROJECT_NAME}. W³aœciwa wartoœæ to: executable, static, dynamic lub module")
	endif()

endmacro(VERIFY_PROJECT_TYPE)

###############################################################################

# Makro rozpoczynaj¹ce konfiguracjê konkretnego projektu - powinno byæ wywo³ywane jako pierwsza komenda po ADD_PROJECT zaraz na pocz¹tku pliku konfiguracujnego projektu
# type Patrz makro VERIFY_PROJECT_TYPE
# opcjonalny argument to nazwa wyjœciowa naszego artefaktu [dla release, dla debug dodajemy automatycznie d na koniec], domyœlnie jest to nazwa projektu
macro(BEGIN_PROJECT type)
	# weryfikujemy typ projektu
	VERIFY_PROJECT_TYPE(${type})
	# zapamiêtujemy typ projektu
	set(PROJECT_TYPE ${type})
	#zapamietuje globalnie typ projektu aby pozniej go nie dodawaæ jako zale¿nego w przypadku execow
	set(PROJECT_TYPE_${PROJECT_NAME} ${type} PARENT_SCOPE)

	# je¿eli chemy plik wykonywalny i jesteœmy na platformie windows to mo¿emy wybraæ czy ma to byæ aplikacja z konsol¹ czy bez
	if(${type} STREQUAL "executable" AND WIN32)
		option(PROJECT_${PROJECT_NAME}_WIN32_ENABLE_CONSOLE "Enable console on Win32 for project ${PROJECT_NAME} on artifact ${TARGET_TARGETNAME}?" ON)
	endif()

	# ostrze¿enie jeœli nasz projekt jest testowy a nie jest aplikacj¹
	if(DEFINED PROJECT_IS_TEST AND NOT ${type} STREQUAL "executable")
		message(STATUS "Projekt ${ORIGINAL_PROJECT_NAME_${PROJECT_NAME}} jest projektem testowym. Powinien byæ kompilowany do pliku wykonywalnego (typ executable) a nie byæ typu ${type}")
	endif()

	# wstepna nazwa artefaktu - bedzie zmieniona jesli podano wlasna
	set(TARGET_TARGETNAME ${PROJECT_NAME})
	
	# jeœli dodatkowy parametr to traktujemy go potencjalnie jako nazwê naszego artefaktu
	if(${ARGC} GREATER 1)
		# sprawdzam czy nazwa taka mo¿e byæ - czy nie jest pusta i czy nie mam ju¿ takiego artefaktu
		string(STRIP ${ARGV1} targetName)
		set(targetNameLength 0)
		string(LENGTH ${targetName} targetNameLength)

		if(${targetNameLength} EQUAL 0)
			# pusta nazwa artefaktu - przywracamy domyslna nazwe projektu
			message(STATUS "Uwaga - podano pust¹ nazwê artefaktu dla projektu ${PROJECT_NAME}. Nazwa artefaktu zostaje ustawiona na nazwê projektu: ${TARGET_TARGETNAME}")
		elseif(DEFINED TARGET_NAME_${targetName})
			# zdefiniowano ju¿ tak¹ nazwê artefaktu - potencjalny problem, informuje o tym ale to nie jest krytyczne
			message(STATUS "Uwaga - arterfakt o podanej nazwie: ${targetName} zosta³ ju¿ zdefiniowany dla projektu ${TARGET_NAME_${targetName}}. Mo¿e to powodowaæ b³êdy przy budowie (nadpisywanie artefaktów ró¿nych projektów) i byæ myl¹ce. Zaleca siê stosowanie unikalnych nazw artefaktów.")
		else()
			# nazwa artefaktu wyglada ok
			message(STATUS "W³asna nazwa artefaktu: ${targetName} pomyœlnie przesz³a weryfikacjê")
			# aktualizujemy ja
			set(TARGET_TARGETNAME ${targetName})
		endif()
		
	endif()
	
	# zapamiêtujemy ¿e taki target name ju¿ mamy
	set(TARGET_NAME_${TARGET_TARGETNAME} ${TARGET_TARGETNAME} PARENT_SCOPE)
	set(${PROJECT_NAME}_TARGET_NAME ${TARGET_TARGETNAME} CACHE INTERNAL "Zmienna globalna pomagaj¹ca wyci¹gn¹æ nazwê artefaktu projektu")

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
	
	set(CONFIGURE_PRIVATE_HEADER_FILES "")
	set(CONFIGURE_PUBLIC_HEADER_FILES "")

	# flagi kompilacji tego projektu
	set(PROJECT_COMPILE_FLAGS)
	
	string(REPLACE "${PROJECT_ROOT}/src" ${PROJECT_INCLUDE_ROOT} PROJECT_PUBLIC_HEADER_PATH ${CMAKE_CURRENT_SOURCE_DIR})
	
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

# Ustawiamy publiczne pliki nag³ówkowe
macro(SET_PUBLIC_HEADERS)

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Powinien kompilowaæ siê do pliku wykonywalnego i raczej nie powinien posiadaæ nag³ówków publicznych.")
	endif()
	
	if(DEFINED PUBLIC_HEADERS_SET)
		message(WARNING "Publiczne nag³ówki projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_PUBLIC_HEADERS mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam nag³ówki ${ARGN}")
	else()
		# zapamiêtujemy ¿e ju¿ by³a wo³ana ta metoda podczas konfiguracji aktualnego projektu
		set(PUBLIC_HEADERS_SET 1)
		# nag³ówki publiczne
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES PUBLIC_H ${PROJECT_PUBLIC_HEADER_PATH})
		
		source_group("${SOURCEGROUP_PUBLIC_HEADERS}" FILES ${PUBLIC_H})
	endif()

endmacro(SET_PUBLIC_HEADERS)

###############################################################################

# Ustawiamy prywatne pliki nag³ówkowe
macro(SET_PRIVATE_HEADERS)

	if(DEFINED PRIVATE_HEADERS_SET)
		message(WARNING "Prywatne nag³ówki projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_PRIVATE_HEADERS mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam nag³ówki ${ARGN}")
	else()
		# zapamiêtujemy ¿e ju¿ by³a wo³ana ta metoda podczas konfiguracji aktualnego projektu
		set(PRIVATE_HEADERS_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES PRIVATE_H "${PROJECT_SOURCE_FILES_PATH}")
		
		source_group("${SOURCEGROUP_PRIVATE_HEADERS}" FILES ${PRIVATE_H})
	endif()

endmacro(SET_PRIVATE_HEADERS)

###############################################################################

# Ustawiamy pliki Ÿród³owe
macro(SET_SOURCE_FILES)

	if(DEFINED SOURCE_FILES_SET)
		message(WARNING "Pliki Ÿród³owe projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_SOURCE_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
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
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Powinien kompilowaæ siê do pliku wykonywalnego konsolowego i raczej nie powinien posiadaæ UI")
	endif()

	if(DEFINED UI_FILES_SET)
		message(WARNING "Pliki UI projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_UI_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
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
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Powinien kompilowaæ siê do pliku wykonywalnego konsolowego i raczej nie powinien posiadaæ UI")
	endif()

	if(DEFINED MOC_FILES_SET)
		message(WARNING "Pliki MOC projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_MOC_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(MOC_FILES_SET 1)
		
		# pliki te musz¹ siê znaleŸæ w którejœæ z wersji nag³ówków prywatnych, publicznych, Ÿród³ach lub konfiguracyjnych po konfiguracji
		set(MOC_FILES "")
		foreach(value ${ARGN})
			if(NOT DEFINED FILE_PATH_${value})
				message(WARNING "Plik ${value} nie zosta³ zarejestrowany w projekcie ${PROJECT_NAME} a ma byæ przetwarzany przez MOC z QT. Zarejestruj plik do jednej z podstawowych grup: PUBLIC_HEADERS, PRIVATE_HEADERS, SOURCES, plikach po konfiguracji. Pomijam plik")
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
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Powinien kompilowaæ siê do pliku wykonywalnego konsolowego i raczej nie powinien posiadaæ UI")
	endif()

	if(DEFINED RC_FILES_SET)
		message(WARNING "Pliki RC projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_RC_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(RC_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES RC_FILES "${PROJECT_UI_FILES_PATH}")
		
		source_group("${SOURCEGROUP_UI}" FILES ${RC_FILES})
	endif()

endmacro(SET_RC_FILES)

###############################################################################

# Ustawiamy pliki t³umaczeñ
macro(SET_TRANSLATION_FILES)

	if(DEFINED PROJECT_IS_TEST)
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Powinien kompilowaæ siê do pliku wykonywalnego konsolowego i raczej nie powinien posiadaæ UI")
	endif()

	if(DEFINED TRANSLATION_FILES_SET)
		message(WARNING "Pliki translacji projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_TRANSLATION_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(TRANSLATION_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES TRANSLATION_FILES "${PROJECT_UI_FILES_PATH}")

		if(NOT EXISTS "${PROJECT_UI_FILES_PATH}")
			message(WARNING "Katalog ${PROJECT_UI_FILES_PATH} nie istnieje choæ wskazano pliki t³umaczeñ ${ARGN}. Tworzê podany katalog.")
			file(MAKE_DIRECTORY "${PROJECT_UI_FILES_PATH}")
		endif()
		
		source_group("${SOURCEGROUP_UI}" FILES ${TRANSLATION_FILES})
	endif()

endmacro(SET_TRANSLATION_FILES)

###############################################################################

# Ustawiamy pliki konfiguracyjne (niekoniecznie CMake musi je potem przetwarzac, ale inne nie bêd¹ mogly byc przetwarzane)
macro(SET_CONFIGURATION_INPUT_FILES)

	if(DEFINED CONFIGURATION_INPUT_FILES_SET)
		message(WARNING "Pliki konfiguracyjne projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_CONFIGURATION_INPUT_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
	else()
		set(CONFIGURATION_INPUT_FILES_SET 1)
		set(INPUT_FILES ${ARGN})
		GENERATE_FILE_PATHS(INPUT_FILES CONFIGURATION_INPUT_FILES "${PROJECT_CONFIGURATION_FILES_PATH}")
		source_group("${SOURCEGROUP_CONFIGURATION_TEMPLATE_FILES}" FILES ${CONFIGURATION_INPUT_FILES})
	endif()

endmacro(SET_CONFIGURATION_INPUT_FILES)

###############################################################################

# Ustawiamy pliki konfiguracyjne (niekoniecznie CMake musi je potem przetwarzac, ale inne nie bêd¹ mogly byc przetwarzane)
macro(SET_CONFIGURATION_OUTPUT_FILES)

	if(DEFINED CONFIGURATION_OUTPUT_FILES_SET)
		message(WARNING "Pliki konfiguracyjne projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_CONFIGURATION_OUTPUT_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
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
		message(WARNING "Pliki resources projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_DEPLOY_RESOURCES_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
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
		message(WARNING "Pliki resources projektu ${PROJECT_NAME} zosta³y ju¿ ustawione. Makro SET_EMBEDDED_RESOURCES_FILES mo¿e byæ u¿yte tylko raz podczas konfiguracji projektu. Pomijam pliki ${ARGN}")
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

	set(P_NAME ${PROJECT_NAME})

	if(DEFINED PROJECT_IS_TEST)
		set(P_NAME ${ORIGINAL_PROJECT_NAME_${PROJECT_NAME}})
		message(WARNING "Projekt ${ORIGINAL_PROJECT_NAME} jest projektem testowym. Nie powinien posiadac plików nag³ówkowych publicznych tylko kompilowaæ siê do pliku wykonywalnego")
	endif()
	
	if(NOT DEFINED FILE_PATH_${inFile})
		message(WARNING "Plik ${inFile} nie zosta³ zarejestrowany w projekcie ${PROJECT_NAME} a ma byæ konfigurowany przez CMake. Zarejestruj plik wsród plików konfiguracyjnych. Pomijam plik")
	else()
		set(CONFIG_FOUND 0)
		list(FIND CONFIGURATION_INPUT_FILES ${inFile} CONFIG_FOUND)
		if(${CONFIG_FOUND})		
			configure_file("${FILE_PATH_${inFile}}" "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${P_NAME}/${outFile}")
			list(APPEND CONFIGURE_PUBLIC_HEADER_FILES "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${P_NAME}/${outFile}")
		else()
			message(WARNING "Plik ${inFile} nie zosta³ zarejestrowany w projekcie ${P_NAME} jako typ pliku konfiguracyjnego a ma byæ konfigurowany przez CMake. Zarejestruj plik wsród plików konfiguracyjnych makrem SET_CONFIGURATION_FILES. Pomijam plik")
		endif()
	endif()

endmacro(CONFIGURE_PUBLIC_HEADER)

###############################################################################

# Konfigurujemy prywatne pliki
macro(CONFIGURE_PRIVATE_HEADER inFile outFile)
	if(NOT DEFINED FILE_PATH_${inFile})
		message(WARNING "Plik ${inFile} nie zosta³ zarejestrowany w projekcie ${PROJECT_NAME} a ma byæ konfigurowany przez CMake. Zarejestruj plik wsród plików konfiguracyjnych. Pomijam plik")
	else()		
		set(CONFIG_FOUND 0)
		list(FIND CONFIGURATION_INPUT_FILES ${inFile} CONFIG_FOUND)
		if(${CONFIG_FOUND})
			configure_file("${FILE_PATH_${inFile}}" "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}/${outFile}")
			list(APPEND CONFIGURE_PRIVATE_HEADER_FILES "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}/${outFile}")
		else()
			message(WARNING "Plik ${inFile} nie zosta³ zarejestrowany w projekcie ${PROJECT_NAME} jako typ pliku konfiguracyjnego a ma byæ konfigurowany przez CMake. Zarejestruj plik wsród plików konfiguracyjnych makrem SET_CONFIGURATION_FILES. Pomijam plik")
		endif()
		
	endif()

endmacro(CONFIGURE_PRIVATE_HEADER)

###############################################################################

# Makro ustawiajace naglowki prekompilowane
# Parametry:
	# header Nag³ówek precompilowany
	# source Plik Ÿród³owy na którym kompilujemy nag³ówek
	
MACRO(SET_PRECOMPILED_HEADER header source)

	set(PRECOMPILED_FOUND 1)

	if(NOT DEFINED FILE_PATH_${header})
		message(WARNING "Proba dodania pliku ${header} niezarejestrowanego w projekcie ${PROJECT_NAME} jako nag³owka prekompilowanego. Zarejestruj plik w projekcie do jednej z podstawowych grup a potem ustaw go jako nag³owek prekompilowany. Pomijam prekompilowane nag³owki.")
		set(PRECOMPILED_FOUND 0)
	endif()
	
	if(NOT DEFINED FILE_PATH_${source})
		message(WARNING "Proba dodania pliku ${source} niezarejestrowanego w projekcie ${PROJECT_NAME} jako nag³owka prekompilowanego. Zarejestruj plik w projekcie do jednej z podstawowych grup a potem ustaw go jako nag³owek prekompilowany. Pomijam prekompilowane nag³owki.")
		set(PRECOMPILED_FOUND 0)
	endif()
	
	if(${PRECOMPILED_FOUND} EQUAL 1)
		set(PRECOMPILED_H ${header})
		set(PRECOMPILED_SRC ${source})
	endif()
ENDMACRO(SET_PRECOMPILED_HEADER)

# ###############################################################################

# Koñczymy dodawanie projektu
macro(END_PROJECT)

	# flaga aby mozna bylo uzyc projektu w makrach
	set(${PROJECT_NAME}_FOUND 1 CACHE INTERNAL "Czy znaleziono projekt ${PROJECT_NAME}")
	# publiczne includy
	#set(${PROJECT_NAME}_INCLUDE_DIR "" CACHE INTERNAL "Œcie¿ka do includów projektu ${PROJECT_NAME}")
	set(${PROJECT_NAME}_INCLUDE_DIR "")
	# definy tego projektu i projektów + bibliotek od których jest zale¿ny
	set(${PROJECT_NAME}_COMPILER_DEFINITIONS "" PARENT_SCOPE)
	# biblioteki od których uzale¿niony jest projekt + biblioteka tego projektu
	set(${PROJECT_NAME}_LIBRARIES "" PARENT_SCOPE)
	# tymczasowa lista dla ${PROJECT_NAME}_LIBRARIES
	set(DEFAULT_PROJECT_LIBRARIES)
	
	# wszystkie pliki nag³ówkowe
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
	
	# nag³owki prekompilowane
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
			list(APPEND ${PROJECT_NAME}_COMPILER_DEFINITIONS DISABLE_PRECOMPILED_HEADERS)
		endif()
	endif()
	
	# generujemy pliki specyficzne dla QT
	
	# UI
	if(DEFINED UI_FILES)
		list(LENGTH UI_FILES uiLength)
		if(${uiLength} GREATER 0)
			QT4_WRAP_UI(TARGET_UI_H ${UI_FILES})
			source_group("${SOURCEGROUP_GENERATED_UI}" FILES ${TARGET_UI_H})
			list(APPEND TARGET_H ${TARGET_UI_H})
			#TODO
			#jak tu wyci¹gaæ œcie¿kê do generowanych plików ui_*.h? czy nie powinno tego robiæ makro QT4_WRAP_UI
			#powinniœmy rozró¿niaæ widgety publiczne i prywatne aby odpowiednio generowaæ pliki ui_*.h i instalowaæ tylko publiczne
			#to wp³ynie równie¿ na sposób includowania takich plików - publiczne bêd¹ widziane jak publiczne nag³ówki, a prywatne tak jak prywatne nag³ówki
			include_directories("${CMAKE_CURRENT_BINARY_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}")
			list(APPEND ${PROJECT_NAME}_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/.." "${CMAKE_CURRENT_BINARY_DIR}")
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
	if(${PROJECT_TYPE} STREQUAL "executable")
		# plik wykonywalny
		if(WIN32)
			# tutaj mo¿emy mieæ aplikacjê z konsol¹ lub bez
			if(PROJECT_${PROJECT_NAME}_WIN32_ENABLE_CONSOLE)
				# konsola
				add_executable(${TARGET_TARGETNAME} ${ALL_SOURCES})
			else()
				# bez konsoli
				add_executable(${TARGET_TARGETNAME} WIN32 ${ALL_SOURCES})
			endif()
		else()
			# dodajemy zwykly plik wykonywalny dla innych platform
			add_executable(${TARGET_TARGETNAME} ${ALL_SOURCES})
			# instalacja skryptów uruchomieniowych dla linux
			if(UNIX)
				GENERATE_UNIX_EXECUTABLE_SCRIPT()
			endif()
		endif()
		
		if(NOT DEFINED PROJECT_IS_TEST)
			# instalacja
			install(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_NAME})
		endif()
	elseif(${PROJECT_TYPE} STREQUAL "static")
		# biblioteka statyczna
		add_library(${TARGET_TARGETNAME} STATIC ${ALL_SOURCES})
		# instalacja		
		install(TARGETS ${TARGET_TARGETNAME} ARCHIVE DESTINATION lib COMPONENT ${PROJECT_NAME}_dev)
	else(${PROJECT_TYPE} STREQUAL "dynamic")
		# biblioteka dynamiczna
		add_library(${TARGET_TARGETNAME} SHARED ${ALL_SOURCES})
		
		# instalacja
		if(WIN32)
			install(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_NAME})
			install(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin ARCHIVE DESTINATION lib COMPONENT ${PROJECT_NAME}_dev)
		elseif(UNIX)
			set_target_properties(${TARGET_TARGETNAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
			install(TARGETS ${TARGET_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_NAME})
			install(TARGETS ${TARGET_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_NAME}_dev)
		endif()
	else()
		# biblioteka dynamiczna
		add_library(${TARGET_TARGETNAME} MODULE ${ALL_SOURCES})
		# instalacja
		if(WIN32)
			install(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_NAME})
			install(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_NAME}_dev)
		elseif(UNIX)
			install(TARGETS ${TARGET_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_NAME})
			install(TARGETS ${TARGET_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_NAME}_dev)
		endif()		
	endif()
	
	if(NOT DEFINED PROJECT_IS_TEST)
	
		#instalacja publicznych naglowkow - zachowujemy strukture
		foreach(f ${PUBLIC_H})
			get_filename_component(FPATH ${f} PATH)
			string(REPLACE ${PROJECT_INCLUDE_ROOT} "" RELPATH ${FPATH})
			install(FILES ${f} DESTINATION include/${RELPATH} COMPONENT ${PROJECT_NAME}_dev)
		endforeach()
		
		#instalacja konfigurowanych publicznych naglowkow
		foreach(f ${CONFIGURE_PUBLIC_HEADER_FILES})
			get_filename_component(FPATH ${f} PATH)
			string(REPLACE "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}" "" RELPATH ${FPATH})
			install(FILES ${f} DESTINATION include/${RELPATH} COMPONENT ${PROJECT_NAME}_dev)
		endforeach()
		
	endif()
	
	
	if(DEFINED PROJECT_FOLDER)
		SET_PROPERTY(TARGET ${TARGET_TARGETNAME} PROPERTY FOLDER "${PROJECT_FOLDER}")
	endif()
	
	# t³umczenia
	if(DEFINED TRANSLATION_FILES)
	
		list(LENGTH TRANSLATION_FILES langLength)
		if(${langLength} GREATER 0)
	
			set(DEBUG_LANG_OUTPUT "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/resources/lang")
			set(RELEASE_LANG_OUTPUT "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release/resources/lang")
	
			foreach(lang ${TRANSLATION_FILES})
				GET_FILENAME_COMPONENT(lang_name ${lang} NAME_WE)
				list(APPEND QM_OUTPUTS "${CMAKE_CURRENT_BINARY_DIR}/${lang_name}.qm")
				
				add_custom_command(TARGET ${TARGET_TARGETNAME} PRE_BUILD
					# Debug
					COMMAND ${CMAKE_COMMAND} -E remove "${DEBUG_LANG_OUTPUT}/${lang_name}.qm"
					# Release
					COMMAND ${CMAKE_COMMAND} -E remove "${RELEASE_LANG_OUTPUT}/${lang_name}.qm"
					VERBATIM
				)
				
			endforeach()
			
			add_custom_command(TARGET ${TARGET_TARGETNAME} POST_BUILD
				# TS
				COMMAND ${QT_LUPDATE_EXECUTABLE} ${TARGET_H} ${TARGET_SRC} -ts ${TRANSLATION_FILES}
				VERBATIM
			)
			
			foreach(lang ${QM_OUTPUTS})
				add_custom_command(TARGET ${TARGET_TARGETNAME} POST_BUILD
					# QM
					COMMAND ${QT_LRELEASE_EXECUTABLE} ${TRANSLATION_FILES} -qm ${lang}
					# kopiowanie do odpowiednich katalogów
					COMMAND ${CMAKE_COMMAND} -E copy ${lang} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/resources/lang"
					COMMAND ${CMAKE_COMMAND} -E copy ${lang} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release/resources/lang"
					VERBATIM
				)
			endforeach()
			
			install(FILES ${QM_OUTPUTS} DESTINATION bin/resources/lang/ COMPONENT ${PROJECT_NAME})
		endif()
	endif()
	
	# ustawiamy nazwe dla artefaktow wersji debug tak aby do nazwy na koniec by³o doklejane d, dla release bez zmian
	set_target_properties(${TARGET_TARGETNAME} PROPERTIES DEBUG_POSTFIX "d")
	
	set(USED_DEPENDECIES "")
	
	foreach(value ${DEFAULT_PROJECT_DEPENDENCIES})
		TARGET_NOTIFY(${PROJECT_NAME} "RAW DEPENDENCY ${value} libraries: ${${value}_LIBRARIES}")
		
		if(${value} STREQUAL ${PROJECT_NAME} AND NOT DEFINED SELF_DEPENDENCY)
			message(WARNING "Projekt ${PROJECT_NAME} nie moze byæ rekurencyjnie zalezny od samego siebie. Pomijam zale¿noœæ...")
			set(SELF_DEPENDENCY 1)
		else()
		
			#szukam czy zadana zale¿noœæ nie by³a ju¿ dodana
			set(DEPENDENCY_USED 0)
			list(FIND USED_DEPENDECIES ${value} DEPENDENCY_USED)
			if(${DEPENDENCY_USED} GREATER -1 AND NOT DEFINED ${value}_DUPLICATED_DEPENDENCY)
				set(${value}_DUPLICATED_DEPENDENCY 1)
				message(WARNING "Dla projektu ${PROJECT_NAME} zale¿noœæ ${value} ju¿ zosta³a dodana i powtarza siê. Zostanie ona teraz pominiêta.")
			else()
				# zapamiêtujê ¿e zale¿noœc ju¿ zosta³a u¿yta
				list(APPEND USED_DEPENDECIES ${value})
				
				# jeœli to projekt testowy to musze nazwy nieco inne sprawdzaæ
				if(DEFINED PROJECT_ORIGINAL_NAME_${value})
					set(tmpValue ${value})
					set(value "test_${value}")
				endif()
				
				# biblioteki zale¿ne				
				foreach(value2 ${${value}_LIBRARIES})
					list(APPEND DEFAULT_PROJECT_LIBRARIES ${${value2}})
				endforeach()
				
				# dodatkowe definicje wynikaj¹ce z bibliotek zale¿nych
				if(DEFINED ${value}_COMPILER_DEFINITIONS)
					list(APPEND ${PROJECT_NAME}_COMPILER_DEFINITIONS ${${value}_COMPILER_DEFINITIONS})
				endif()
				
				# dodatkowe flagi kompilacji wynikaj¹ce z bibliotek zale¿nych (np. OpenMP)
				if(DEFINED ${value}_COMPILER_FLAGS)
					list(APPEND PROJECT_COMPILER_FLAGS ${${value}_COMPILER_FLAGS})
				endif()
				
				# includy bibliotek zaleznych
				if(DEFINED ${value}_INCLUDE_DIR)
					list(APPEND ${PROJECT_NAME}_INCLUDE_DIR ${${value}_INCLUDE_DIR})
				endif()
				
				# includy bibliotek zaleznych
				if(DEFINED ${value}_INCLUDE_CONFIG_DIR)
					list(APPEND ${PROJECT_NAME}_INCLUDE_DIR ${${value}_INCLUDE_CONFIG_DIR})
				endif()
				
				# sprawdzam czy zale¿noœæ nie jest projektem!!
				# jeœli jest to doklejam jej target_name ¿eby projekt poprawnie ustawi³ zale¿noœci miêdzy bibliotekami
				if(DEFINED PROJECT_NAME_${value})
					if(PROJECT_TYPE_${value} STREQUAL "executable")
						if(DEFINED tmpValue)
							message(WARNING "Projekt ${PROJECT_NAME} jest zale¿ny od projektu ${tmpValue} który jest plikiem wykonywalnym. Pomijam ten projekt w zale¿noœciach")
						else()
							message(WARNING "Projekt ${PROJECT_NAME} jest zale¿ny od projektu ${value} który jest plikiem wykonywalnym. Pomijam ten projekt w zale¿noœciach")
						endif()
					else()
						if(DEFINED ${value}_TARGET_NAME)
							list(APPEND DEFAULT_PROJECT_LIBRARIES ${${value}_TARGET_NAME})
						else()
							if(DEFINED tmpValue)
								message(WARNING "Znaleziono zale¿noœæ od projektu ${tmpValue} ale nie zdefiniowano dla niego ¿adnego targetu")
							else()
								message(WARNING "Znaleziono zale¿noœæ od projektu ${value} ale nie zdefiniowano dla niego ¿adnego targetu")
							endif()							
						endif()
					endif()
				endif()
			endif()
		endif()
	endforeach()	
	
	# ustawiamy definicje kompilacji projektu wynikaj¹ce z jego zale¿noœci
	list(LENGTH ${PROJECT_NAME}_COMPILER_DEFINITIONS DEF_COUNT)
	if(${DEF_COUNT} GREATER 0)
		list(REMOVE_DUPLICATES ${PROJECT_NAME}_COMPILER_DEFINITIONS)
		set_target_properties(${TARGET_TARGETNAME} PROPERTIES COMPILE_DEFINITIONS "${${PROJECT_NAME}_COMPILER_DEFINITIONS}")
	endif()
	
	# ustawiamy flagi kompilacji dla projektu
	if(DEFINED PROJECT_COMPILER_FLAGS)
		list(LENGTH PROJECT_COMPILER_FLAGS flagsLength)
		if(${flagsLength} GREATER 0)
			list(REMOVE_DUPLICATES PROJECT_COMPILER_FLAGS)
			set_target_properties(${TARGET_TARGETNAME} PROPERTIES COMPILE_FLAGS "${PROJECT_COMPILER_FLAGS}")
		endif()
	endif()
	
	# TODO
	# resources - kopiowanie
	# resources instalowanie
	
	# ustawiamy includy projektu
	# wszystkie includy projektu - publiczne, prywatne + konfigi
	#TODO
	#wymagana reorganizacja includów w strukturze, tak by wymuszaæ podawanie zale¿noœci pomiêdzy bibliotekami w celu udostêpniania publicznych nag³ówków
	#struktura includów powinna wygl¹daæ tak: include/dirName/dirName/tu_sa_wlasciwe_includy
	#wtedy dany projekt ma dostêp do swojego: include/dirName
	#a jeœli chce u¿yæ innych to musi byæ od nich jawnie uzale¿niony
	#aktualnie ka¿dy ma dostêp do publicznych nag³óków ka¿dego innego projektu
	include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src" "${PROJECT_INCLUDE_ROOT}")

	foreach(value ${${PROJECT_NAME}_INCLUDE_DIR})
		include_directories("${value}")
	endforeach()
		

	# prywatne i publiczne includy po konfiguracji
	set(APPEND_PRIVATE 0)
	list(LENGTH CONFIGURE_PRIVATE_HEADER_FILES APPEND_PRIVATE)
	if(${APPEND_PRIVATE} GREATER 0)
		if(EXISTS "${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}")
			include_directories("${PROJECT_PRIVATE_CONFIGURATION_INCLUDES_PATH}")
		else()
			message(SEND_ERROR "Zarejestrowano pliki konfiguracyjne prywatne, ale ich katalog docelowy nie istnieje. Nie mo¿na do³¹czyæ tych plików jako includy")
		endif()
	endif()
	
	set(APPEND_PUBLIC 0)
	list(LENGTH CONFIGURE_PUBLIC_HEADER_FILES APPEND_PUBLIC)
	if(${APPEND_PUBLIC} GREATER 0)
		if(EXISTS "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}")
			include_directories("${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}")
			list(APPEND ${PROJECT_NAME}_INCLUDE_DIR "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}")
		else()
			message(SEND_ERROR "Zarejestrowano pliki konfiguracyjne publiczne, ale ich katalog docelowy nie istnieje. Nie mo¿na do³¹czyæ tych plików jako includy")
		endif()
	endif()
	
	set(${PROJECT_NAME}_LIBRARIES ${DEFAULT_PROJECT_LIBRARIES})
	# biblioteki do linkowania
	#hack
	target_link_libraries(${TARGET_TARGETNAME} ${${PROJECT_NAME}_LIBRARIES} ${${PROJECT_NAME}_LIBRARIES})
	# info ze poprawnie zakonczylismy dodawanie projektu
	set(PROJECT_ADD_FINISHED 1 PARENT_SCOPE)
	
	if(DEFINED PROJECT_IS_TEST)
		add_test(NAME ${ORIGINAL_PROJECT_NAME_${PROJECT_NAME}} COMMAND ${TARGET_TARGETNAME})
		set(PROJECT_IS_TEST)
	endif()
	
	set(${PROJECT_NAME}_INCLUDE_DIR "${${PROJECT_NAME}_INCLUDE_DIR}" CACHE INTERNAL "Œcie¿ki do includów projektu ${PROJECT_NAME}")
	
endmacro(END_PROJECT)

###############################################################################

# Makro ustawiaj¹ce pewn¹ opcjê konfiguracji.
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

