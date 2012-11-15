###############################################################################
function(procedural_create_vcproj_userfile TARGETNAME WORKING_DIR EXE_FILENAME)
  if (MSVC)
	set(PROCEDURAL_TEMPLATES_DIR "${CMAKE_SOURCE_DIR}/../../CMakeModules/Templates")
	if (${MSVC_VERSION} EQUAL 1600)
	   configure_file(
	  ${PROCEDURAL_TEMPLATES_DIR}/VisualStudioUserFile.vcxproj.user.in
	  ${CMAKE_CURRENT_BINARY_DIR}/${TARGETNAME}.vcxproj.user
	  @ONLY
	)
	else()
	  configure_file(
	  ${PROCEDURAL_TEMPLATES_DIR}/VisualStudioUserFile.vcproj.user.in
	  ${CMAKE_CURRENT_BINARY_DIR}/${TARGETNAME}.vcproj.user
	  @ONLY
	)
	endif()
  endif ()
 endfunction(procedural_create_vcproj_userfile)
 
 
###############################################################################
# Makro generuje wykonywalny skrypt z ustawionymi sciezkami do bibliotek
macro(GENERATE_UNIX_EXECUTABLE_SCRIPT)
	if (UNIX)
		set (scriptT "\#!/bin/sh\nexport LD_LIBRARY_PATH=")
		  
		foreach(value ${ALL_LIBRARIES})
			set(dir "${${value}_LIBRARY_DIR_RELEASE}")
			set (scriptT "${scriptT}${dir}:")
		endforeach()

		set( scriptT "${scriptT}:$LD_LIBRARY_PATH\n")

		set( script_run "${scriptT}exec ./${TARGET_TARGETNAME} $*")
		set( filename_run "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/run_${TARGET_TARGETNAME}.sh")
		file (WRITE ${filename_run} "${script_run}")
		execute_process(COMMAND chmod a+x ${filename_run})

		set( script_debug "${scriptT}exec gdb ./${TARGET_TARGETNAME} $*")
		set( filename_debug "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/gdb_${TARGET_TARGETNAME}.sh")
		file (WRITE ${filename_debug} "${script_debug}")
		execute_process(COMMAND chmod a+x ${filename_debug})
	endif()
endmacro(GENERATE_UNIX_EXECUTABLE_SCRIPT)

###############################################################################
# Makro generuje wykonywalny skrypt z ustawionymi sciezkami do bibliotek
macro(GENERATE_UNIX_PlUGIN_STARTER_SCRIPT)
	if (UNIX)
		set (scriptT "\#!/bin/sh\nexport LD_LIBRARY_PATH=")
		  
		foreach(value ${DEFAULT_PROJECT_DEPENDENCIES})
			set(dir "${${value}_LIBRARY_DIR_RELEASE}")
			set (scriptT "${scriptT}${dir}:")
		endforeach()

		set( scriptT "${scriptT}:$LD_LIBRARY_PATH\n")

		#set( script_run "${scriptT}exec ./${TARGET_TARGETNAME} $*")
		set( script_run "${scriptT}exec ${PROCEDURAL_CORE_PATH}/${PROCEDURAL_CORE_EXE} --plugins ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../lib $*")
		set( filename_run "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/run_${TARGET_TARGETNAME}.sh")
		file (WRITE ${filename_run} "${script_run}")
		execute_process(COMMAND chmod a+x ${filename_run})

		#set( script_debug "${scriptT}exec gdb ./${TARGET_TARGETNAME} $*")
		#set( filename_debug "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/gdb_${TARGET_TARGETNAME}.sh")
		#file (WRITE ${filename_debug} "${script_debug}")
		#execute_process(COMMAND chmod a+x ${filename_debug})
	endif()
endmacro(GENERATE_UNIX_PlUGIN_STARTER_SCRIPT)

macro(GENERATE_PLUGIN_ARTIFACTS)
	if (WIN32)
		GET_FILENAME_COMPONENT(PLUGINS_DESTINATION_DIR_TMP  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\PJWSTK\\EDR;ApplicationDataPath]" ABSOLUTE CACHE)
		file(TO_NATIVE_PATH ${PLUGINS_DESTINATION_DIR_TMP} PLUGINS_DESTINATION_DIR_NATIVE)
		add_custom_command(  TARGET ${TARGET_TARGETNAME}
							 POST_BUILD 
							 COMMAND mkdir \"${4}\\plugins\" | mkdir \"${PLUGINS_DESTINATION_DIR_NATIVE}\\plugins\\${TARGET_TARGETNAME}\" | copy \"$(SolutionDir)bin\\$(Configuration)\\$(TargetName)$(TargetExt)\" \"${PLUGINS_DESTINATION_DIR_NATIVE}\\plugins\\${TARGET_TARGETNAME}\\$(TargetName)$(TargetExt)\" )
		procedural_create_vcproj_userfile(${TARGET_TARGETNAME} ${PROCEDURAL_CORE_PATH} ${PROCEDURAL_CORE_EXE})
	elseif(UNIX)
		GENERATE_UNIX_PlUGIN_STARTER_SCRIPT()
	endif()
endmacro(GENERATE_PLUGIN_ARTIFACTS)
