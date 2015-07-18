macro(BEGIN_PYTHON_PROJECT)
	BEGIN_PROJECT("dynamic")
endmacro(BEGIN_PYTHON_PROJECT)

macro(END_PYTHON_PROJECT)
	END_PROJECT()
		if (WIN32)
		
		add_custom_command(  TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} 
							 PRE_BUILD 
							 COMMAND if exist \"$(SolutionDir)bin\\$(Configuration)\\$(TargetName).pyd\" erase \"$(SolutionDir)bin\\$(Configuration)\\$(TargetName).pyd\")
							 
		add_custom_command(  TARGET ${PROJECT_${CURRENT_PROJECT_NAME}_TARGETNAME} 
							 POST_BUILD 
							 COMMAND ren \"$(SolutionDir)bin\\$(Configuration)\\$(TargetName)$(TargetExt)\" \"$(TargetName).pyd\" )
	elseif(UNIX)
		
	endif()

endmacro(END_PYTHON_PROJECT)

