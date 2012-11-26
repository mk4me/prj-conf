###############################################################################

# Inicjuje konfiguracjê solucji
# Parametry:
	# [zewnêtrzne biblioteki potrzebne w solucji]
	# [dodatkowe katalogi dla CMakeModules poza CustomCMakeModules - ten jest automatycznie dodawany]
	# [dodatkowe definicje preprocesora dla ca³ej solucji]
	# [dodatkowe flagi kompilatora dla ca³ej solucji]
macro(INITIALIZE_SOLUTION)

	# grupowanie projektów w folderach
	SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)

	#---------------------------------------------------
	# opcje

	option(PROJECT_VERBOSE_CONFIG "Print verbose info?" OFF)
	set(FIND_VERBOSE ${PROJECT_VERBOSE_CONFIG})
	set(TARGET_VERBOSE ${PROJECT_VERBOSE_CONFIG})

	#---------------------------------------------------
	# dodatkowe modu³y CMake
	
	# u¿ywamy œcie¿ki wzglêdne
	set(CMAKE_USE_RELATIVE_PATHS TRUE)
	#zapamiêtujê oryginalne module path na potrzeby niektórych finderów (np. OpenGL) ¿ebym móg³ ich u¿yc w naszych nadpisanych finderach
	set(CMAKE_ORIGINAL_MODULE_PATH ${CMAKE_MODULE_PATH})
	# dodatkowe œcie¿ki dla modu³ów
	
	set(FINDERS_PATHS "CustomCMakeModules")
	
	if(${ARGC} GREATER 1)
		list(APPEND FINDERS_PATHS ${ARGV1})
	endif()
	
	list(APPEND CMAKE_MODULE_PATH ${FINDERS_PATHS})
	# dodatkowe modu³y pomagaj¹ce szukaæ biblioteki zewnêtrzne w naszej strukturze oraz konfigurowaæ projekty
	foreach(path ${FINDERS_PATHS})
		if(EXISTS "${CMAKE_SOURCE_DIR}/${path}")
		
			file(GLOB fu "${CMAKE_SOURCE_DIR}/${path}/Logic/*FindUtils.cmake")
			file(GLOB tu "${CMAKE_SOURCE_DIR}/${path}/Logic/*TargetUtils.cmake")
			file(GLOB pu "${CMAKE_SOURCE_DIR}/${path}/Logic/*ProjectUtils.cmake")
	
			foreach(fuFile ${fu})
				include(${fuFile})
			endforeach()
	
			foreach(tuFile ${tu})
				include(${tuFile})
			endforeach()
		
			foreach(puFile ${pu})
				include(${puFile})
			endforeach()
		
			list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${path}")
			
			if(EXISTS "${CMAKE_SOURCE_DIR}/${path}/Finders")
				list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${path}/Finders")
			endif()
		else()			
			message(STATUS "Additional CMAKE_MODULE_PATH ${path} does not exist as ancessor of ${CMAKE_SOURCE_DIR}. Skipping this additional CMakeModule path")
		endif()
	endforeach()
	
	# œcie¿ki do globalnych dodatkowych modu³ów
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../../CMakeModules;${CMAKE_SOURCE_DIR}/../../CMakeModules/Finders")
	include(Logic/Generators)
	include(Logic/FindUtils)
	include(Logic/TargetUtils)
	
	#---------------------------------------------------
	# blok definicji dla CMake'a
	# œcie¿ki do bibliotek zewnêtrznych

	set(PROJECT_LIBRARIES_ROOT "${CMAKE_SOURCE_DIR}/../.." CACHE PATH "Location of external libraries and includes.")

	set(PROJECT_LIBRARIES_DIR "${PROJECT_LIBRARIES_ROOT}/lib")
	set(PROJECT_LIBRARIES_INCLUDE_ROOT "${PROJECT_LIBRARIES_ROOT}/include")
	set(PROJECT_INCLUDE_ROOT "${CMAKE_SOURCE_DIR}/include" CACHE PATH "Location of includes.")
	set(PROJECT_ROOT "${CMAKE_SOURCE_DIR}")
	set(PROJECT_BUILD_ROOT "${PROJECT_BINARY_DIR}")

	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")

	# TODO : jak rozpoznac 32 / 64 bit na linux i windows?

	if(WIN32)
		set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
		set(PROJECT_LIBRARIES_PLATFORM "win32" CACHE STRING "Platform")
		add_definitions(-D__WIN32__)
		if (MSVC)
			add_definitions(/MP -D_SCL_SECURE_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS)
		endif()
	elseif(UNIX)
		set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
		set(PROJECT_LIBRARIES_PLATFORM "linux32" CACHE STRING "Platform")
		# TODO
		# podpi¹æ póŸniej pod wykrywanie wersji systemu 32 / 64
		set(PROJECT_LINKER_FLAGS "-m32" CACHE STRING "Flagi linkera")
		SET(PROJECT_CXX_FLAGS "-Os -std=c++0x -fpermissive -m32" CACHE STRING "Flagi kompilatora C++")
		SET(PROJECT_C_FLAGS "-Os -std=c++0x -fpermissive -m32" CACHE STRING "Flagi kompilatora C")

		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PROJECT_CXX_FLAGS}")
		SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g")
		SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PROJECT_C_FLAGS}")
		SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")
		SET(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} ${PROJECT_LINKER_FLAGS}")
		add_definitions(-D__UNIX__)
	else()
		message(FATAL_ERROR "Platform not supported.")
	endif()
	
	# dodatkowe definicje
	if(${ARGC} GREATER 2)
		add_definitions(${ARGV2})
	endif()
	
	# dodatkowe flagi
	if(${ARGC} GREATER 3)
		SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGV3}")
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGV3}")
	endif()

	#------------------------------------------------------------------------------
	# wyszukanie potrzebnych bibliotek

	set(PROJECT_LIBRARIES_DIR_DEBUG "${PROJECT_LIBRARIES_DIR}/${PROJECT_LIBRARIES_PLATFORM}/debug" CACHE PATH "Location of debug libraries" FORCE)
	set(PROJECT_LIBRARIES_DIR_RELEASE "${PROJECT_LIBRARIES_DIR}/${PROJECT_LIBRARIES_PLATFORM}/release" CACHE PATH "Location of release libraries" FORCE)

	# konfiguracja modu³u wyszukuj¹cego
	set(FIND_LIBRARIES_INCLUDE_ROOT ${PROJECT_LIBRARIES_INCLUDE_ROOT})
	set(FIND_LIBRARIES_ROOT ${PROJECT_LIBRARIES_DIR})
	set(FIND_LIBRARIES_ROOT_DEBUG ${PROJECT_LIBRARIES_DIR_DEBUG})
	set(FIND_LIBRARIES_ROOT_RELEASE ${PROJECT_LIBRARIES_DIR_RELEASE})
	set(FIND_PLATFORM ${PROJECT_LIBRARIES_PLATFORM})

	#------------------------------------------------------------------------------
	# Grupy plików w projektach pod IDE
	set(SOURCEGROUP_PRIVATE_HEADERS "Header files" CACHE STRING "Filter for private headers.")
	set(SOURCEGROUP_SOURCES "Source files" CACHE STRING "Filter for sources.")
	set(SOURCEGROUP_PUBLIC_HEADERS "Header files" CACHE STRING "Filter for public headers.")
	set(SOURCEGROUP_UI "UI" CACHE STRING "Filter for GUI specific files.")
	set(SOURCEGROUP_GENERATED_UI "Generated UI" CACHE STRING "Filter for GUI generated headers.")
	set(SOURCEGROUP_CONFIGURATION_TEMPLATE_FILES "Configuration templates" CACHE STRING "Configuration files templates edited by CMake during configuration process.")
	set(SOURCEGROUP_CONFIGURATION_INSTANCE_FILES "Configuration instance" CACHE STRING "Configuration files instances created by CMake during configuration process.")
	set(SOURCEGROUP_RESOURCES "Resource files" CACHE STRING "Filter for resource files e.g. bitmaps, textures, ssl certificates")

	#---------------------------------------------------
	# Szukamy bibliotek
	if(${ARGC} GREATER 0)
		set(PROJECT_DEPENDENCIES ${ARGV0})
	endif()
	
	option(GENERATE_TESTS "Czy do³¹czyæ testy do solucji?" OFF )
	option(GENERATE_EXAMPLES "Czy do³¹czyæ przyk³ady do solucji?" OFF)
	if (UNIX)
		# TODO : zamiast opcji dobrze byloby sprawdzac to automatycznie
		# niestety CMAKE_GENERATOR zwraca "Unix Makefiles"
		# jest jakis inny sposob?
		option (GENERATE_CODEBLOCKS_STARTER "Wygeneruje skrypt, ktory otworzy projekt w Code::Blocks wraz z poprawnymi bibliotekami" OFF)
	endif()
endmacro(INITIALIZE_SOLUTION)

macro(VERBOSE_MESSAGE var msg)
	if (PROJECT_VERBOSE_CONFIG)
		message(STATUS "${msg}")
	endif()
endmacro(VERBOSE_MESSAGE)

#---------------------------------------------------
# makro koñcz¹ce konfiguracjê solucji
macro(FINALIZE_SOLUTION)

	if(DEFINED PROJECT_DEPENDENCIES)
		set(SECOND_PASS_FIND_DEPENDENCIES "" CACHE INTERNAL "Libraries to find in second pass" FORCE)
		set(SECOND_PASS_FIND_PREREQUISITIES "" CACHE INTERNAL "Prerequisities to find in second pass" FORCE)
		# zaczynamy od szukania bibliotek
		foreach(value ${PROJECT_DEPENDENCIES})
			message(STATUS "Szukam ${value}")
			find_package(${value})
		endforeach()
	endif()
	
		
	set(nextPassRequired 1)
	
	while(${nextPassRequired} GREATER 0)
		list(REMOVE_DUPLICATES SECOND_PASS_FIND_DEPENDENCIES)
		set(tmpSecondPassFindDependencies ${SECOND_PASS_FIND_DEPENDENCIES})
		# zerujemy dla kolejnych przebiegów
		set(SECOND_PASS_FIND_DEPENDENCIES "")
		# iteruje po bibliotekach, które maj¹ jeszcze jakieœ niespe³nione zale¿noœci
		foreach(library ${tmpSecondPassFindDependencies})
			# iteruje po niespe³nionych zale¿noœciach danej biblioteki
			set(LIB_DEPS_FOUND 1)
			foreach(dep ${${library}_SECOND_PASS_FIND_DEPENDENCIES})
				if(NOT DEFINED ${dep}_FOUND)
					message(STATUS "Szukam dodatkowej zale¿noœci ${dep} dla biblioteki ${library}")
					find_package(${dep})
					list(APPEND PROJECT_DEPENDENCIES ${dep})
				endif()

				if(${dep}_FOUND)
					list(APPEND ${library}_INCLUDE_DIR "${${dep}_INCLUDE_DIR}")
					if(DEFINED ${library}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE)
						set(additionalIncludes ${${dep}_SECOND_PASS_FIND_DEPENDENCIES_INCLUDE})
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
									list(APPEND ${library}_INCLUDE_DIR "${${variableName}}/${path}")
								else()
									message(STATUS "B³¹d podczas dodawania dodatkowych includów biblioteki ${library}. Zmienna ${variableName} nie istnieje, œcie¿ka ${variableName}/${path} nie mog³a byæ dodana.")
									set(LIB_DEPS_FOUND 0)
								endif()
								math(EXPR idx "${idx}+1")
								math(EXPR loopIDX "${loopIDX}+1")
								
							endwhile()				
						else()
							message(STATUS "B³¹d dodawania dodatkowych includów - d³ugoœæ listy jest nieparzysta (b³êdny format listy). Lista: ${additionalIncludes}")
							set(LIB_DEPS_FOUND 0)
						endif()
					endif()
					if(DEFINED ${dep}_LIBRARIES)
						list(APPEND ${library}_LIBRARIES "${${dep}_LIBRARIES}")
					endif()
				else()
					message("Nie znaleziono ${dep} dla ${library}")
					set(LIB_DEPS_FOUND 0)
				endif()			
			endforeach()
			
			if(NOT LIB_DEPS_FOUND)
				message(STATUS "Nie wszystkie zale¿noœci biblioteki ${library} zosta³y znalezione. Brakuje którejœ z bibliotek: ${${library}_SECOND_PASS_FIND_DEPENDENCIES}")
				set(${library}_FOUND 0)
			endif()
		endforeach()
		
		list(LENGTH SECOND_PASS_FIND_DEPENDENCIES nextPassRequired)
		
	endwhile()
	
	set(nextPassRequired 1)
	
	while(${nextPassRequired} GREATER 0)
		list(REMOVE_DUPLICATES SECOND_PASS_FIND_PREREQUISITIES)
		set(tmpSecondPassFindPrerequisities ${SECOND_PASS_FIND_PREREQUISITIES})
		# zerujemy dla kolejnych przebiegów
		set(SECOND_PASS_FIND_PREREQUISITIES "")
		# iteruje po bibliotekach, które maj¹ jeszcze jakieœ niespe³nione prerequisities
		foreach(library ${tmpSecondPassFindPrerequisities})
			# iteruje po niespe³nionych zale¿noœciach danej biblioteki
			set(LIB_PREREQ_FOUND 1)
			foreach(prereq ${${library}_SECOND_PASS_FIND_PREREQUISITIES})
				if(NOT DEFINED ${dep}_FOUND)
					message(STATUS "Szukam prerequisit ${prereq} dla biblioteki ${library}")
					find_package(${prereq})
					list(APPEND PROJECT_DEPENDENCIES ${prereq})
				endif()
				
				if(NOT ${${prereq}_FOUND})
					set(LIB_PREREQ_FOUND 0)
				endif()			
			endforeach()
			
			if(NOT LIB_PREREQ_FOUND)
				message(STATUS "Nie wszystkie prerequisities biblioteki ${library} zosta³y znalezione. Brakuje któregoœ z prerequisitów: ${${library}_SECOND_PASS_FIND_PREREQUISITIES}")
				set(${library}_FOUND 0)
			endif()
		endforeach()	
	
		list(LENGTH SECOND_PASS_FIND_PREREQUISITIES nextPassRequired)
		
	endwhile()
	
	# zmienna z wszystkimi nazwami bibliotek, uzywana do generowania skryptow uruchomieniowych pod Linuxa
	set(ALL_LIBRARIES ${PROJECT_DEPENDENCIES} CACHE INTERNAL "Variable used for generating Linux launch scripts" FORCE)

	# wci¹gamy podprojekty
	add_subdirectory(src)
	
	#---------------------------------------------------
	# obs³uga modu³ów (.dll/.so)
	option(PROJECT_COPY_MODULES "Copy runtime modules into bin folder?" ON)
	if(PROJECT_COPY_MODULES)
		message("Copying modules")
		FIND_HANDLE_MODULES(PROJECT_COPY_MODULES)
		message("Copying finished. You should turn off option PROJECT_COPY_MODULES.")
	endif()
	
	# do³¹czamy testy jeœli tak skonfigurowano projekt
	if(${GENERATE_TESTS})
		if(EXISTS "${CMAKE_SOURCE_DIR}/tests")
			if(NOT DEFINED CPPUNIT_FOUND)
				find_package("CPPUNIT")
				set(PROJECT_DEPENDENCIES ${PROJECT_DEPENDENCIES} "CPPUNIT")
				set(ALL_LIBRARIES ${PROJECT_DEPENDENCIES}  CACHE INTERNAL "Variable used for generating Linux launch scripts" FORCE)
			endif()			
			
			if(${CPPUNIT_FOUND} EQUAL 1)
				#TODO - trzeba to poprawic zmienna globalna - CACHE INTERNAL
				set(TESTS_DEPENDENCIES  "CPPUNIT")
				set(PROJECT_ADD_FINISHED)
				enable_testing()
				add_subdirectory(tests)
			elseif()
				message("User requested to generate tests but test helper library CPPUNIT was not found.")
			endif()
		else()
			message("User requested to generate tests but tests folder does not exist")
		endif()		
	endif()
	
	# do³¹czamy przyk³ady jeœli tak skonfigurowano projekt
	if(${GENERATE_EXAMPLES})
		if(EXISTS "${CMAKE_SOURCE_DIR}/examples")
				set(PROJECT_ADD_FINISHED)
				add_subdirectory(examples)
		else()
			message("User requested to generate examples but examples folder does not exist")
		endif()		
	endif()
	
	if (${GENERATE_CODEBLOCKS_STARTER}) 
		GENERATE_UNIX_SCRIPT(
			"${PROJECT_BINARY_DIR}/OPEN_${PROJECT_NAME}_IN_CODEBLOCKS.sh"
			"codeblocks ${PROJECT_NAME}.cbp"
		)
	endif()
	
	#---------------------------------------------------
	# dodanie uninstalla
	configure_file(
	  "${CMAKE_SOURCE_DIR}/../../CMakeModules/Templates/cmake_uninstall.cmake.in"
	  "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
	  IMMEDIATE @ONLY)

	add_custom_target(UNINSTALL
	  "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endmacro(FINALIZE_SOLUTION)
