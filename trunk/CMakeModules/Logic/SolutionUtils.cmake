###############################################################################

# Inicjuje konfiguracj� solucji
# Parametry:
	# [dodatkowe katalogi dla CMakeModules poza CustomCMakeModules - ten jest automatycznie dodawany]
	# [dodatkowe definicje preprocesora dla ca�ej solucji]
	# [dodatkowe flagi kompilatora dla ca�ej solucji]
	# [dodatkowe zale�no�ci wszystkich projekt�w]
macro(INITIALIZE_SOLUTION projectName)

	# definiujemy root project
	project(${projectName})	
	
	# badamy wersje kompilatora - to prosty spos�b,
	# ale bardziej poprawny to kompilacja przyk��dowego programu z cechami,
	# jakich oczekujemy od kompilatora - try_compile()
	if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
		if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.7")
			message(FATAL_ERROR "Insufficient gcc version - 4.7 required while ${CMAKE_CXX_COMPILER_VERSION} detected")
		endif()
	elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")
		if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "16.0")
			message(FATAL_ERROR "Insufficient MSVC version - 16.0 required while ${CMAKE_CXX_COMPILER_VERSION} detected")
		endif()
	elseif(...)
		message(FATAL_ERROR "Unsupported compiler")
	endif()
	
	# teraz wci�gam wszystkie modu�y CMAKEa, bo p�niej modyfikuj� �cie�ki do CMAKE_MODULES
	include(CMakeDependentOption)
	
	# grupowanie projekt�w w folderach
	SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
	# zmiana nazwy defoultowych target�w Cmake : install, itp
	SET_PROPERTY(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMAKE")

	#---------------------------------------------------
	# dodatkowe modu�y CMake
	
	# u�ywamy �cie�ki wzgl�dne
	set(CMAKE_USE_RELATIVE_PATHS TRUE)
	#zapami�tuj� oryginalne module path na potrzeby niekt�rych finder�w (np. OpenGL) �ebym m�g� ich u�yc w naszych nadpisanych finderach
	set(CMAKE_ORIGINAL_MODULE_PATH ${CMAKE_MODULE_PATH})
	# dodatkowe �cie�ki dla modu��w
	
	set(SOLUTION_CMAKE_MODULES_PATHS "CustomCMakeModules")
	
	if(${ARGC} GREATER 1)
		list(APPEND SOLUTION_CMAKE_MODULES_PATHS ${ARGV1})
	endif()
	
	set(CMAKE_MODULE_PATH ${SOLUTION_CMAKE_MODULES_PATHS})
	# dodatkowe modu�y pomagaj�ce szuka� biblioteki zewn�trzne w naszej strukturze oraz konfigurowa� projekty
	foreach(path ${SOLUTION_CMAKE_MODULES_PATHS})
		if(EXISTS "${CMAKE_SOURCE_DIR}/${path}")
		
			file(GLOB vu "${CMAKE_SOURCE_DIR}/${path}/Logic/*VariablesUtils.cmake")
			file(GLOB cou "${CMAKE_SOURCE_DIR}/${path}/Logic/*ConfigurationOptionUtils.cmake")
			file(GLOB fu "${CMAKE_SOURCE_DIR}/${path}/Logic/*FindUtils.cmake")
			file(GLOB tu "${CMAKE_SOURCE_DIR}/${path}/Logic/*TargetUtils.cmake")
			file(GLOB pu "${CMAKE_SOURCE_DIR}/${path}/Logic/*ProjectUtils.cmake")
			file(GLOB iu "${CMAKE_SOURCE_DIR}/${path}/Logic/*InstallUtils.cmake")
			file(GLOB iiu "${CMAKE_SOURCE_DIR}/${path}/Logic/*InstallerUtils.cmake")		
	
			foreach(f ${vu})
				include(${f})
			endforeach()
	
			foreach(f ${cou})
				include(${f})
			endforeach()
	
			foreach(f ${fu})
				include(${f})
			endforeach()
		
			foreach(f ${tu})
				include(${f})
			endforeach()
			
			foreach(f ${pu})
				include(${f})
			endforeach()
			
			foreach(f ${iu})
				include(${f})
			endforeach()
			
			foreach(f ${iiu})
				include(${f})
			endforeach()
		
			list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${path}")
			
			if(EXISTS "${CMAKE_SOURCE_DIR}/${path}/Finders")
				list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${path}/Finders")
			endif()
		else()			
			VERBOSE_MESSAGE(CMAKE_MODULE_PATH ${path} "Additional CMAKE_MODULE_PATH ${path} does not exist as an ancessor of ${CMAKE_SOURCE_DIR}. Skipping this additional CMakeModule path")
		endif()
	endforeach()
	
	# �cie�ki do globalnych dodatkowych modu��w
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../../CMakeModules;${CMAKE_SOURCE_DIR}/../../CMakeModules/Finders")
	
	set(SOLUTION_ADDITIONAL_FINDERS_PATHS "" CACHE PATH "Paths to additional finders")
	
	list(APPEND CMAKE_MODULE_PATH ${SOLUTION_ADDITIONAL_FINDERS_PATHS})	
	
	include(Logic/VariablesUtils)
	include(Logic/ConfigurationOptionUtils)
	include(Logic/FindUtils)
	include(Logic/TargetUtils)
	include(Logic/InstallUtils)
	include(Logic/InstallerUtils)
	include(Logic/NSISInstallerUtils)
	
	#---------------------------------------------------
	# opcje

	CONFIG_OPTION(SOLUTION_VERBOSE "Print verbose info?" OFF)	
	set(FIND_VERBOSE ${CONFIG_SOLUTION_VERBOSE})
	set(TARGET_VERBOSE ${CONFIG_SOLUTION_VERBOSE})
	set(INSTALL_VERBOSE ${CONFIG_SOLUTION_VERBOSE})
	
	#---------------------------------------------------
	# blok definicji dla CMake'a
	# �cie�ki do bibliotek zewn�trznych

	set(SOLUTION_ROOT "${CMAKE_SOURCE_DIR}")
	set(SOLUTION_INSTALLERS_DIRECTORIES "${SOLUTION_ROOT}/installers")
	
	set(SOLUTION_LIBRARIES_ROOTS "${SOLUTION_ROOT}/../.." CACHE PATH "Location of external libraries and includes roots.")	
	set(SOLUTION_INCLUDE_ROOT "${SOLUTION_ROOT}/include" CACHE PATH "Location of project includes.")
	
	set(SOLUTION_BUILD_ROOT "${PROJECT_BINARY_DIR}")
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${SOLUTION_BUILD_ROOT}/bin")

	set(SOLUTION_DEFAULT_DEPENDENCIES "")
	
	# TODO : jak rozpoznac 32 / 64 bit na linux i windows?

	if(WIN32)
		set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${SOLUTION_BUILD_ROOT}/bin")
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${SOLUTION_BUILD_ROOT}/bin")
		set(SOLUTION_LIBRARIES_PLATFORM "win32" CACHE STRING "Platform")
		add_definitions(-D__WIN32__)
		if (MSVC)
			add_definitions(/MP -D_SCL_SECURE_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS)
		endif()
		
		SET(SOLUTION_CXX_FLAGS "/Zm200" CACHE STRING "Flagi kompilatora C++")
		SET(SOLUTION_C_FLAGS "/Zm200" CACHE STRING "Flagi kompilatora C")
		
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SOLUTION_CXX_FLAGS}")
		SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${SOLUTION_CXX_FLAGS}")
		SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SOLUTION_C_FLAGS}")
		SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${SOLUTION_C_FLAGS}")
		
	elseif(UNIX)
	
		list(APPEND SOLUTION_DEFAULT_DEPENDENCIES DL)
	
		set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${SOLUTION_BUILD_ROOT}/lib")
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${SOLUTION_BUILD_ROOT}/lib")
		set(SOLUTION_LIBRARIES_PLATFORM "linux32" CACHE STRING "Platform")
		# TODO
		# podpi�� p�niej pod wykrywanie wersji systemu 32 / 64
		set(SOLUTION_LINKER_FLAGS "-m32" CACHE STRING "Flagi linkera")
		SET(SOLUTION_CXX_FLAGS "-Os -std=c++11 -fpermissive -m32" CACHE STRING "Flagi kompilatora C++")
		SET(SOLUTION_C_FLAGS "-Os -std=c++11 -fpermissive -m32" CACHE STRING "Flagi kompilatora C")

		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SOLUTION_CXX_FLAGS}")
		SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${SOLUTION_CXX_FLAGS} -g")
		SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SOLUTION_C_FLAGS}")
		SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${SOLUTION_C_FLAGS} -g")
		SET(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} ${SOLUTION_LINKER_FLAGS}")
		add_definitions(-D__UNIX__)
	else()
		message(FATAL_ERROR "Platform not supported.")
	endif()
	
	set(TESTS_DEPENDENCIES "CPPUNIT")
	
	# dodatkowe definicje
	if(${ARGC} GREATER 2)
		add_definitions(${ARGV2})
	endif()
	
	# dodatkowe flagi
	if(${ARGC} GREATER 3)
		SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGV3}")
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGV3}")
	endif()
	
	#---------------------------------------------------
	# t�umaczenia
	set(SOLUTION_TRANSLATION_LANGUAGES "pl_PL;de_DE" CACHE STRING "Solution translation languages")	
	
	#---------------------------------------------------
	# Resetujemy szukane biblioteki
	set(SOLUTION_DEPENDENCIES "" CACHE INTERNAL "Solution all dependencies" FORCE )	
	# Resetujemy projekty solucji
	set(SOLUTION_PROJECTS "" CACHE INTERNAL "All projects to configure" FORCE )	
		
	# domy�lne zale�no�ci dla wszystkich projekt�w solucji
	if(${ARGC} GREATER 4)
		list(APPEND SOLUTION_DEFAULT_DEPENDENCIES "${ARGV4}")
	endif()
	
	#usuwam duplikaty z listy zale�no�ci
	list(REMOVE_DUPLICATES SOLUTION_DEFAULT_DEPENDENCIES)
	
	list(LENGTH SOLUTION_DEFAULT_DEPENDENCIES deps)
	if(${deps} GREATER 0)
		
		set(SOLUTION_DEPENDENCIES "${SOLUTION_DEFAULT_DEPENDENCIES}" CACHE INTERNAL "Solution all dependencies" FORCE )	
			
		# szukamy zale�no�ci
		FIND_SOLUTION_DEPENDECIES("${SOLUTION_DEFAULT_DEPENDENCIES}")
		# sprawdzamy czy wszystkie domy�lne zale�no�ci uda�o si� znale��
		set(SOLUTION_MESSAGE "")
		set(SOLUTION_DEFAULT_DEPS_FAIL 0)
		foreach(dep ${SOLUTION_DEFAULT_DEPENDENCIES})
			if(NOT LIBRARY_${dep}_FOUND)
				set(SOLUTION_DEFAULT_DEPS_FAIL 1)
				set(SOLUTION_MESSAGE ${SOLUTION_MESSAGE} ", " ${dep})
			endif()
		endforeach()
			
		if(SOLUTION_DEFAULT_DEPS_FAIL)
			message(FATAL_ERROR "Default solution dependencies missing: ${SOLUTION_MESSAGE}" )
		endif()
	endif()

	#------------------------------------------------------------------------------
	# wyszukanie potrzebnych bibliotek

	set(SOLUTION_LIBRARIES_DIR_DEBUG "${SOLUTION_LIBRARIES_DIR}/${SOLUTION_LIBRARIES_PLATFORM}/debug" CACHE PATH "Location of debug libraries" FORCE)
	set(SOLUTION_LIBRARIES_DIR_RELEASE "${SOLUTION_LIBRARIES_DIR}/${SOLUTION_LIBRARIES_PLATFORM}/release" CACHE PATH "Location of release libraries" FORCE)

	# konfiguracja modu�u wyszukuj�cego
	set(FIND_LIBRARIES_INCLUDE_ROOT ${SOLUTION_LIBRARIES_INCLUDE_ROOT})
	set(FIND_LIBRARIES_ROOT ${SOLUTION_LIBRARIES_DIR})
	set(FIND_LIBRARIES_ROOT_DEBUG ${SOLUTION_LIBRARIES_DIR_DEBUG})
	set(FIND_LIBRARIES_ROOT_RELEASE ${SOLUTION_LIBRARIES_DIR_RELEASE})
	set(FIND_PLATFORM ${SOLUTION_LIBRARIES_PLATFORM})

	#------------------------------------------------------------------------------
	# Grupy plik�w w projektach pod IDE
	set(SOURCEGROUP_PRIVATE_HEADERS "Header files" CACHE STRING "Filter for private headers." FORCE)
	set(SOURCEGROUP_SOURCES "Source files" CACHE STRING "Filter for sources." FORCE)
	set(SOURCEGROUP_PUBLIC_HEADERS "Header files" CACHE STRING "Filter for public headers." FORCE)
	set(SOURCEGROUP_UI "UI" CACHE STRING "Filter for GUI specific files." FORCE)
	set(SOURCEGROUP_GENERATED_UI "Generated UI" CACHE STRING "Filter for GUI generated headers." FORCE)
	set(SOURCEGROUP_CONFIGURATION_TEMPLATE_FILES "Configuration templates" CACHE STRING "Configuration files templates edited by CMake during configuration process." FORCE)
	set(SOURCEGROUP_CONFIGURATION_INSTANCE_FILES "Configuration instance" CACHE STRING "Configuration files instances created by CMake during configuration process." FORCE)
	set(SOURCEGROUP_RESOURCES "Resource files" CACHE STRING "Filter for resource files e.g. bitmaps, textures, ssl certificates" FORCE)
	set(SOURCEGROUP_TRANSLATIONS "Translation files" CACHE STRING "Filter for resource files e.g. bitmaps, textures, ssl certificates" FORCE)
	set(SOURCEGROUP_EMBEDDED_RESOURCES "Embedded resource files" CACHE STRING "Filter for resource files e.g. bitmaps, textures, ssl certificates" FORCE)
	set(SOURCEGROUP_DEPLOY_RESOURCES "Deploy resource files" CACHE STRING "Filter for resource files e.g. bitmaps, textures, ssl certificates" FORCE)
	
	# generowanie test�w
	CONFIG_OPTION(GENERATE_TESTS "Czy do��czy� testy do solucji?" OFF)	
	# generowanie przyk�ad�w
	CONFIG_OPTION(GENERATE_EXAMPLES "Czy do��czy� przyk�ady do solucji?" OFF)
	
	# generowanie finder�w
	set(SOLUTION_GENERATED_FINDERS_DESTINATION "${CMAKE_SOURCE_DIR}/CustomCMakeModules/Finders" CACHE STRING "�cie�ka dla generowanych finder�w")
	CONFIG_OPTION(GENERATE_FINDERS "Czy generowa� findery?" ON)
	
	# generowanie skrypt�w dla linuxa
	if (UNIX)
		# TODO : zamiast opcji dobrze byloby sprawdzac to automatycznie
		# niestety CMAKE_GENERATOR zwraca "Unix Makefiles"
		# jest jakis inny sposob?		
		CONFIG_OPTION(GENERATE_CODEBLOCKS_STARTER "Wygeneruje skrypt, ktory otworzy projekt w Code::Blocks wraz z poprawnymi bibliotekami" OFF)		
	endif()
	
	# Resetujemy list� aktualnie inicjowanych projekt�w
	set(PROJECTS_BEING_INITIALISED "" CACHE INTERNAL "Helper list with currently initialised projects" FORCE )	
	# Resetujemy list� zainicjowanych projekt�w
	set(INITIALISED_PROJECTS "" CACHE INTERNAL "Helper list with already initialised projects" FORCE )	

	set(PROJECT_ADD_FINISHED 1)
	
	set(INITIALISED_PROJECTS "" CACHE INTERNAL "Helper list with already initialised projects" FORCE )	
	
	_BEGIN_INSTALLATION()
	
	# wci�gamy podprojekty
	add_subdirectory(src)
	
	# do��czamy testy je�li tak skonfigurowano projekt
	if(GENERATE_TESTS)
		if(EXISTS "${CMAKE_SOURCE_DIR}/tests")
			set(PROJECT_ADD_FINISHED 1)
			enable_testing()
			SET_PROJECTS_GROUP("Tests")
			add_subdirectory(tests)
		else()
			VERBOSE_MESSAGE(GENERATE_TESTS "User requested to generate tests but tests folder does not exist")
		endif()		
	endif()
	
	# do��czamy przyk�ady je�li tak skonfigurowano projekt
	if(GENERATE_EXAMPLES)
		if(EXISTS "${CMAKE_SOURCE_DIR}/examples")
			set(PROJECT_ADD_FINISHED 1)
			SET_PROJECTS_GROUP("Examples")
			add_subdirectory(examples)
		else()
			VERBOSE_MESSAGE(GENERATE_EXAMPLES "User requested to generate examples but examples folder does not exist")
		endif()		
	endif()
	
endmacro(INITIALIZE_SOLUTION)

#---------------------------------------------------
# makro pomagaj�ce logowa� stan konfiguracji

macro(VERBOSE_MESSAGE var msg)
	if (CONFIG_SOLUTION_VERBOSE)
		message(STATUS "${msg}")
	endif()
endmacro(VERBOSE_MESSAGE)

#---------------------------------------------------
# makro ko�cz�ce konfiguracj� solucji
macro(FINALIZE_SOLUTION)
	# doklejam ponownie standardowy katalog modu��w CMAKE
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_ORIGINAL_MODULE_PATH}")
	#usuwam duplikaty z listy zale�no�ci
	list(REMOVE_DUPLICATES SOLUTION_DEPENDENCIES)
	
	list(LENGTH SOLUTION_DEPENDENCIES deps)
	if(${deps} GREATER 0)
		# szukamy zale�no�ci
		FIND_SOLUTION_DEPENDECIES("${SOLUTION_DEPENDENCIES}")
	endif()	
	foreach(value ${SOLUTION_PROJECTS})
		if(NOT ${PROJECT_${value}_INITIALISED})
		__INITIALIZE_PROJECT(${value})
		endif()
	endforeach()
	# konczymy z instalacjami
	_END_INSTALLATION()
	# generujemy instalatory
	_GENERATE_INSTALLERS()
	#---------------------------------------------------
	# obs�uga modu��w (.dll/.so)
	CONFIG_OPTION(SOLUTION_COPY_SHARED "Copy shared libraries into bin folder?" ON)	
	if(SOLUTION_COPY_SHARED)
		VERBOSE_MESSAGE(SOLUTION_COPY_SHARED "Copying modules")
		HANDLE_SOLUTION_DEPENDENCIES(${SOLUTION_COPY_SHARED})
		VERBOSE_MESSAGE(SOLUTION_COPY_SHARED "Copying finished. You should turn off option SOLUTION_COPY_SHARED.")
	endif()
	if (GENERATE_CODEBLOCKS_STARTER) 
		GENERATE_UNIX_SCRIPT(
			"${PROJECT_BINARY_DIR}/OPEN_${PROJECT_NAME}_IN_CODEBLOCKS.sh"
			"codeblocks ${PROJECT_NAME}.cbp"
		)
	endif()
	
endmacro(FINALIZE_SOLUTION)

# Makro szukaj�ce biblioteki zale�nej we wszystkich zarejestrowanych rootach
# Parametry
	# dep - nazwa szukanej biblioteki
macro(FIND_SOLUTION_DEPENDECY dep)
	set(_rootIDX 0)
	list(LENGTH SOLUTION_LIBRARIES_ROOTS _rootsLength)
	while((${_rootsLength} GREATER ${_rootIDX}) AND (NOT DEFINED LIBRARY_${dep}_FOUND OR LIBRARY_${dep}_FOUND))
	
		list(GET SOLUTION_LIBRARIES_ROOTS ${_rootIDX} _root)
		VERBOSE_MESSAGE(SOLUTION_PROJECTS "Szukam ${dep} w root: ${_root}")
		_SETUP_FIND_ROOT("${_root}")
		find_package(${dep})
		math(EXPR _rootIDX "${_rootIDX}+1")
	endwhile()
endmacro()

# Makro szukaj�ce zale�nych bibliotek w 2 przej�ciach - wyszukuje r�wnie� zale�no�ci bibliotek zale�nych
# Parametry
	# deps - lista zale�no�ci do znalezienia, b�dzie sukcesywnie rozszerzana o dodatkowe je�li zajedzie taka potrzeba
macro(FIND_SOLUTION_DEPENDECIES deps)
	set(SECOND_PASS_FIND_DEPENDENCIES "" CACHE INTERNAL "Libraries to find in second pass" FORCE)
	set(SECOND_PASS_FIND_PREREQUISITES "" CACHE INTERNAL "Prerequisites to find in second pass" FORCE)
	# zaczynamy od szukania bibliotek
	foreach(value ${deps})
		list(FIND SOLUTION_PROJECTS ${value} IS_PROJECT)
		if(IS_PROJECT EQUAL -1)
			FIND_SOLUTION_DEPENDECY("${value}")
		endif()
	endforeach()
	set(nextPassRequired 1)
	while(${nextPassRequired} GREATER 0)
		list(REMOVE_DUPLICATES SECOND_PASS_FIND_DEPENDENCIES)
		set(tmpSecondPassFindDependencies ${SECOND_PASS_FIND_DEPENDENCIES})
		# zerujemy dla kolejnych przebieg�w
		set(SECOND_PASS_FIND_DEPENDENCIES "")
		# iteruje po bibliotekach, kt�re maj� jeszcze jakie� niespe�nione zale�no�ci
		foreach(library ${tmpSecondPassFindDependencies})
			# iteruje po niespe�nionych zale�no�ciach danej biblioteki
			set(LIB_DEPS_FOUND 1)
			foreach(dep ${${library}_SECOND_PASS_FIND_DEPENDENCIES})
				if(NOT DEFINED LIBRARY_${dep}_FOUND)
					VERBOSE_MESSAGE(SOLUTION_DEPENDENCIES "Szukam dodatkowej zale�no�ci ${dep} dla biblioteki ${library}")
					FIND_SOLUTION_DEPENDECY("${dep}")					
					list(APPEND SOLUTION_DEPENDENCIES ${dep})
				endif()

				if(LIBRARY_${dep}_FOUND)					
					list(APPEND ${library}_ADDITIONAL_INCLUDE_DIRS "${${dep}_INCLUDE_DIR}")

					if(DEFINED ${dep}_ADDITIONAL_INCLUDE_DIRS)
						list(APPEND ${library}_ADDITIONAL_INCLUDE_DIRS "${${dep}_ADDITIONAL_INCLUDE_DIRS}")
					endif()

					if(DEFINED LIBRARY_${dep}_LIBRARIES)
						list(APPEND LIBRARY_${library}_LIBRARIES "${LIBRARY_${dep}_LIBRARIES}")
					endif()

					if(DEFINED ${library}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE)
						set(additionalIncludes ${${library}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE})
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
									VERBOSE_MESSAGE(variableName "B��d podczas dodawania dodatkowych includ�w biblioteki ${library}. Zmienna ${variableName} nie istnieje, �cie�ka ${variableName}/${path} nie mog�a by� dodana.")
									set(LIB_DEPS_FOUND 0)
								endif()
								math(EXPR idx "${idx}+1")
								math(EXPR loopIDX "${loopIDX}+1")
								
							endwhile()				
						else()
							VERBOSE_MESSAGE(additionalIncludes "B��d dodawania dodatkowych includ�w - d�ugo�� listy jest nieparzysta (b��dny format listy). Lista: ${additionalIncludes}")
							set(LIB_DEPS_FOUND 0)
						endif()
					endif()
					if(DEFINED ${dep}_LIBRARIES)
						list(APPEND ${library}_LIBRARIES "${${dep}_LIBRARIES}")
					endif()
				else()
					VERBOSE_MESSAGE(dep "Nie znaleziono ${dep} dla ${library}")
					set(LIB_DEPS_FOUND 0)
				endif()			
			endforeach()
			
			if(NOT LIB_DEPS_FOUND)
				VERBOSE_MESSAGE(LIB_DEPS_FOUND "Nie wszystkie zale�no�ci biblioteki ${library} zosta�y znalezione. Brakuje kt�rej� z bibliotek: ${${library}_SECOND_PASS_FIND_DEPENDENCIES}")
				set(LIBRARY_${library}_FOUND 0)
			endif()
		endforeach()
		
		list(LENGTH SECOND_PASS_FIND_DEPENDENCIES nextPassRequired)
		
	endwhile()
	
	set(nextPassRequired 1)
	while(${nextPassRequired} GREATER 0)
		list(REMOVE_DUPLICATES SECOND_PASS_FIND_PREREQUISITES)
		set(tmpSecondPassFindPrerequisites ${SECOND_PASS_FIND_PREREQUISITES})
		# zerujemy dla kolejnych przebieg�w
		set(SECOND_PASS_FIND_PREREQUISITES "")
		# iteruje po bibliotekach, kt�re maj� jeszcze jakie� niespe�nione prerequisites
		foreach(library ${tmpSecondPassFindPrerequisites})
			# iteruje po niespe�nionych zale�no�ciach danej biblioteki
			set(LIB_PREREQ_FOUND 1)
			foreach(prereq ${${library}_SECOND_PASS_FIND_PREREQUISITES})				
				if(NOT DEFINED LIBRARY_${prereq}_FOUND)
					VERBOSE_MESSAGE(LIBRARY_${prereq}_FOUND "Szukam prerequisit ${prereq} dla biblioteki ${library}")
					FIND_SOLUTION_DEPENDECY("${prereq}")					
					list(APPEND SOLUTION_DEPENDENCIES ${prereq})
				endif()
				
				if(NOT ${LIBRARY_${prereq}_FOUND})
					set(LIB_PREREQ_FOUND 0)
				endif()			
			endforeach()
			
			if(NOT LIB_PREREQ_FOUND)
				VERBOSE_MESSAGE(LIB_PREREQ_FOUND "Nie wszystkie prerequisites biblioteki ${library} zosta�y znalezione. Brakuje kt�rego� z prerequisit�w: ${${library}_SECOND_PASS_FIND_PREREQUISITES}")
				set(LIBRARY_${library}_FOUND 0)
			endif()
		endforeach()	
	
		list(LENGTH SECOND_PASS_FIND_PREREQUISITES nextPassRequired)
		
	endwhile()
	
	# zmienna z wszystkimi nazwami bibliotek, uzywana do generowania skryptow uruchomieniowych pod Linuxa
	set(ALL_LIBRARIES ${SOLUTION_DEPENDENCIES} CACHE INTERNAL "Variable used for generating Linux launch scripts" FORCE)
endmacro(FIND_SOLUTION_DEPENDECIES)


###############################################################################

macro(COPY_SHARED_LIBRARIES buildType subDir dependenciesList)

	# wybieramy odpowiednia liste
	string(TOUPPER "${buildType}" buildTypeUpper)
	if ("${buildTypeUpper}" STREQUAL "DEBUG")
		set(SHARED_SUFFIX "DEBUG")
		set(OTHER_SHARED_SUFFIX "RELEASE")
	else()
		set(SHARED_SUFFIX "RELEASE")
		set(OTHER_SHARED_SUFFIX "DEBUG")
	endif()	
	
	# kopiujemy biblioteki wsp�dzielone dla danej zale�no�ci
	foreach (dependency ${dependenciesList})		
		# czy zdefiniowano jakies biblioteki zale�ne dla zadanego typu builda?		
		if(DEFINED LIBRARY_${dependency}_${SHARED_SUFFIX}_DLLS)
			COPY_LIBRARY_SHARED_LIBRARIES("${dependency}" "LIBRARY_${dependency}_${SHARED_SUFFIX}_DLLS" "${subDir}")
		elseif(DEFINED LIBRARY_${dependency}_${OTHER_SHARED_SUFFIX}_DLLS)
			COPY_LIBRARY_SHARED_LIBRARIES("${dependency}" "LIBRARY_${dependency}_${OTHER_SHARED_SUFFIX}_DLLS" "${subDir}")
		else()
			VERBOSE_MESSAGE(dependency "For dependency ${dependency} there are no runtime artifacts to copy")
		endif()
		
		if(DEFINED LIBRARY_${dependency}_${SHARED_SUFFIX}_DIRECTORIES)
			# dla ka�dego katalogu kopiujemy
			COPY_LIBRARY_DIRECTORIES("${dependency}" "LIBRARY_${dependency}_${SHARED_SUFFIX}_DIRECTORIES" "${subDir}")
		elseif(DEFINED LIBRARY_${dependency}_${OTHER_SHARED_SUFFIX}_DIRECTORIES)
			COPY_LIBRARY_DIRECTORIES("${dependency}" "LIBRARY_${dependency}_${OTHER_SHARED_SUFFIX}_DIRECTORIES" "${subDir}")
		else()
			VERBOSE_MESSAGE(dependency "For dependency ${dependency} there are no additional folders to copy")
		endif()
		
	endforeach()

endmacro(COPY_SHARED_LIBRARIES)

###############################################################################

macro(COPY_LIBRARY_SHARED_LIBRARIES dependency libsList subDir)
	foreach(pathVar ${${libsList}})
		# czy faktycznie �cie�ka pe�na, absolutna
		set(path ${${pathVar}})
		if(IS_ABSOLUTE ${path})
			# czy przypadkiem nie katalog!
			if(IS_DIRECTORY ${path})
				
				VERBOSE_MESSAGE(path "For dependency ${dependency} defined path ${path} as dll which aparently is a directory - skiping. Add directory directly.")
				
			else()

				get_filename_component(fileNameWE ${path} NAME_WE)
				get_filename_component(fileName ${path} NAME)
				
				# czy zdefiniowano sufix dla tego modu�u?
				if (FIND_MODULE_PREFIX_${fileNameWE})
					set(fileName ${FIND_MODULE_PREFIX_${fileNameWE}}${fileName})
				endif()
				if ("${subDir}" STREQUAL "")
					configure_file(${path} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${fileName} COPYONLY)
					VERBOSE_MESSAGE(path "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${fileName} <- ${path}")
				else()
					configure_file(${path} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}/${fileName} COPYONLY ESCAPE_QUOTES)
					VERBOSE_MESSAGE(path "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}/${fileName} <- ${path}")
				endif()
			endif()
		else()
			VERBOSE_MESSAGE(path "Path ${path} is not an absolute path! Skipping its copying")
		endif()
	endforeach()
endmacro(COPY_LIBRARY_SHARED_LIBRARIES)

###############################################################################

macro(COPY_LIBRARY_DIRECTORIES dependency libsList subDir)
	foreach(directoryVar ${${libsList}})
		# czy faktycznie �cie�ka pe�na, absolutna
		set(directory ${${directoryVar}})
		if(IS_ABSOLUTE ${directory})
			# czy katalog
			if(IS_DIRECTORY ${directory})
				
				if ("${subDir}" STREQUAL "")
					#TODO
					# zostawi� tak jak jest teraz - kopiowa� wszystko, albo ustawia� rozszerzenia w zale�no�ci od platformy: linux, windows
					#file(COPY ${directory} DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" FILES_MATCHING PATTERN "*.dll")
					file(COPY ${directory} DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
					VERBOSE_MESSAGE(directory "${CMAKE_RUNTIME_OUTPUT_DIRECTORY} <- ${directory}")
				else()
					#TODO
					# zostawi� tak jak jest teraz - kopiowa� wszystko, albo ustawia� rozszerzenia w zale�no�ci od platformy: linux, windows
					#file(COPY ${directory} DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}" FILES_MATCHING PATTERN "*.dll")						
					file(COPY ${directory} DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir}")
					VERBOSE_MESSAGE(directory "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${subDir} <- ${directory}")
				endif()
				
			else()

				VERBOSE_MESSAGE(directory "For dependency ${dependency} defined path ${directory} as directory which aparently is a file - skiping. Search for file/library directly")
				
			endif()
		else()
			VERBOSE_MESSAGE(directory "Path ${directory} is not an absolute path! Skipping its copying")
		endif()
	endforeach()
endmacro(COPY_LIBRARY_DIRECTORIES)

###############################################################################

macro(HANDLE_SOLUTION_DEPENDENCIES doCopy)
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

		# wybieramy list� konfiguracji
		if ( WIN32 )
			# lecimy po build typach
			foreach (buildType ${CMAKE_CONFIGURATION_TYPES})
				COPY_SHARED_LIBRARIES(${buildType} ${buildType} "${SOLUTION_DEPENDENCIES}")
			endforeach()
		endif()

	endif()

endmacro(HANDLE_SOLUTION_DEPENDENCIES)

###############################################################################
# Makro pomagaj�ce dodawa� findery zewn�trznych projekt�w wg naszej struktury
# Parametry:
# 		path - scie�ka do finder�w
macro(ADD_EXTERNAL_SOLUTION_FINDERS_PATH path)
	if(EXISTS "${path}")
		list(APPEND CMAKE_MODULE_PATH "${path}")
	elseif(...)
		message(WARNING "Unable to find external finders for path: ${path}")
	endif()
endmacro(ADD_EXTERNAL_SOLUTION_FINDERS_PATH)

###############################################################################
# Makro pomagaj�ce dodawa� findery zewn�trznych projekt�w wg naszej struktury
# Parametry:
# 		solutionName - nazwa solucji jak w strukturze kodu
macro(ADD_EXTERNAL_SOLUTION_FINDERS solutionName)
	
	set(_candidateFindersPath "${CMAKE_SOURCE_DIR}/../${solutionName}/CustomCMakeModules/Finders")
	ADD_EXTERNAL_SOLUTION_FINDERS_PATH(${_candidateFindersPath})
endmacro(ADD_EXTERNAL_SOLUTION_FINDERS)


