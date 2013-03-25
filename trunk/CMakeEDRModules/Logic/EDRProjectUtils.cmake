###############################################################################

# Inicjuje konfiguracjê solucji
# Parametry:
	# [zewnêtrzne biblioteki potrzebne w solucji]
	# [dodatkowe katalogi dla CMakeModules poza CustomCMakeModules - ten jest automatycznie dodawany]
	# [dodatkowe definicje preprocesora dla ca³ej solucji]
	# [dodatkowe flagi kompilatora dla ca³ej solucji]
macro(INITIALIZE_PLUGINS_SOLUTION)

include("CMakeEDRModules/Logic/Generators.cmake")
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/CustomCMakeModules;${CMAKE_SOURCE_DIR}/CMakeEDRModules;${CMAKE_MODULE_PATH}")

set (Arguments0)
set (Arguments1 "CMakeEDRModules")
set (Arguments2)
set (Arguments3)

if(${ARGC} GREATER 0)
	set(Arguments0 ${ARGV0})
endif()
	
if(${ARGC} GREATER 1)
	list(APPEND Arguments1 ${ARGV1})
endif()
	
if(${ARGC} GREATER 2)
	set(Arguments2 ${ARGV2})
endif()
	
if(${ARGC} GREATER 3)
	set(Arguments3 ${ARGV3})
endif()

INITIALIZE_SOLUTION("${Arguments0}" "${Arguments1}" "${Arguments2}" "${Arguments3}")
	
if (WIN32)
	GET_FILENAME_COMPONENT(PROGRAM_FILES_DIR_TMP  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\PJWSTK\\EDR;ProgramFilesPath]" ABSOLUTE CACHE)
	file(TO_NATIVE_PATH ${PROGRAM_FILES_DIR_TMP} PROGRAM_FILES_DIR)
	set(MDE_CORE_PATH ${PROGRAM_FILES_DIR}/bin CACHE PATH "Binary path.")
	set(MDE_CORE_EXE core.exe CACHE STRING "Executable name")
else()
	set(MDE_CORE_PATH ${PROJECT_BINARY_DIR}/../edr/bin CACHE PATH "Binary path.")
	set(MDE_CORE_EXE old_view CACHE STRING "Executable name")
endif()
endmacro(INITIALIZE_PLUGINS_SOLUTION)

#---------------------------------------------------
# makro koñcz¹ce konfiguracjê solucji
macro(FINALIZE_PLUGINS_SOLUTION)
	FINALIZE_SOLUTION()
	if (WIN32)
		set(temp_path ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
		GET_FILENAME_COMPONENT(PLUGINS_DEST  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\PJWSTK\\EDR;ApplicationDataPath]" ABSOLUTE CACHE)

		# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PLUGINS_DESTINATION_DIR_TMP}/plugins/libs")
		# #message ("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
		# FIND_HANDLE_MODULES(PROJECT_COPY_MODULES)
		# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${temp_path})
	endif()
endmacro(FINALIZE_PLUGINS_SOLUTION)