###############################################################################
# Instalacje realizowane sa w oparciu o CPack i NSIS (windows) oraz dep (linux)
###############################################################################
# Zbiór makr u³atwiaj¹cych instalacjê projektów oraz generowanie instalatorów.
# Wyró¿niamy nastêpuj¹ce typy instalacji:
#	product - exe + dlls + resources + dependency
#	libraries_api - exe + dlls + resources + dependency + public headers + import libs [where phisible]
#
###############################################################################

###############################################################################
# Makro obs³uguj¹ce generowanie komunikatów diagnostycznych dla makr instalacji
# Parametry:
#		var - nazwa zmiennej
#		msg - wiadomoœæ
macro(INSTALLATION_NOTIFY var msg)
	if (INSTALLATION_VERBOSE)
		message(STATUS "INSTALLATION>${var}>${msg}")
	endif()
endmacro(INSTALLATION_NOTIFY)

# Makro rozpoczynaj¹ce blok generowania instalacji
macro(_BEGIN_INSTALLATION)

	# generowanie instalacji
	CONFIG_OPTION(CREATE_INSTALLATION "Czy konfigurowaæ instalacjê?" OFF)
	
	if(CREATE_INSTALLATION)		
		set(CMAKE_INSTALL_PREFIX "${SOLUTION_LIBRARIES_ROOT}" CACHE PATH "Solution installation path.")
		set(SOLUTION_INSTALLED_DEPENDENCIES "" CACHE INTERNAL "Already installed dependencies" FORCE)
	endif()

endmacro(_BEGIN_INSTALLATION)

###############################################################################
# Makro koñcz¹ce blok generowania instalacji
macro(_END_INSTALLATION)

	if(CREATE_INSTALLATION)
		#---------------------------------------------------
		# dodanie uninstalla
		configure_file(
		  "${CMAKE_SOURCE_DIR}/../../CMakeModules/Templates/cmake_uninstall.cmake.in"
		  "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
		  IMMEDIATE @ONLY)
		  
		add_custom_target(UNINSTALL
		  "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
		  
		GET_PROPERTY(defaultTargets GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER)
	  
		SET_PROPERTY(TARGET "UNINSTALL" PROPERTY FOLDER "${defaultTargets}")
	
	endif()

endmacro(_END_INSTALLATION)


###############################################################################
# Makro generujace instalacjê zadanego projektu
# Parametry:
#		projectName Nazwa projektu dla którego generujemy instalacje
macro(_INSTALL_PROJECT projectName)
	
	_INSTALL_PROJECT_DEV(${projectName})
	_INSTALL_PROJECT_PRODUCT(${projectName})

endmacro(_INSTALL_PROJECT)

###############################################################################
# Makro generujace nazwe komponentu
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		projectName Nazwa projektu dla którego generujemy nazwe komponentu
#		type		Typ komponentu: dev | product
macro(_COMPONENT_NAME variable name type)
	
	list(FIND SOLUTION_PROJECTS "${name}" _solutionIDX)
	
	if(_solutionIDX GREATER -1)
		_PROJECT_COMPONENT_NAME("${variable}" "${name}" "${type}")
	else()
		_LIBRARY_COMPONENT_NAME("${variable}" "${name}" "${type}")
	endif()

endmacro(_COMPONENT_NAME)


###############################################################################
# Makro generujace nazwe komponentu
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		projectName Nazwa projektu dla którego generujemy nazwe komponentu
#		type		Typ komponentu: dev | product
macro(_PROJECT_COMPONENT_NAME variable projectName type)
	
	if("${type}" STREQUAL "dev")
			
		string(TOUPPER "PROJECT_${projectName}_DEV" ${variable})
		
	elseif("${type}" STREQUAL "product")
	
		string(TOUPPER "PROJECT_${projectName}_PRODUCT" ${variable})
	
	else()
	
		INSTALLATION_NOTIFY(${variable} "Unknown project component type: '${type}'.")
	
	endif()	

endmacro(_PROJECT_COMPONENT_NAME)

###############################################################################
# Makro generujace nazwe komponentu
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		projectName Nazwa projektu dla którego generujemy nazwe komponentu
#		type		Typ komponentu: dev | product
macro(_LIBRARY_COMPONENT_NAME variable libraryName type)
	
	if("${type}" STREQUAL "dev")
		
		string(TOUPPER "LIBRARY_${libraryName}_DEV" ${variable})
	
	elseif("${type}" STREQUAL "product")
	
		string(TOUPPER "LIBRARY_${libraryName}_PRODUCT" ${variable})		
	
	else()
	
		INSTALLATION_NOTIFY(variable "Unknown library component type: '${type}'.")
	
	endif()	

endmacro(_LIBRARY_COMPONENT_NAME)


###############################################################################
# Makro generujace instalacjê zadanego projektu w wersji dla developerów - rozwój aplikacji
# Parametry:
#		projectName Nazwa projektu dla którego generujemy instalacje developersk¹
macro(_INSTALL_PROJECT_DEV projectName)

	_PROJECT_COMPONENT_NAME(PROJECT_COMPONENT "${projectName}" "dev")
	
	# sprawdzam typ instalacji
	set(ARTIFACTS_DEBUG_DESTINATION "lib/${SOLUTION_LIBRARIES_PLATFORM}/debug/${PROJECT_${projectName}_RELATIVE_PATH}")
	set(ARTIFACTS_RELEASE_DESTINATION "lib/${SOLUTION_LIBRARIES_PLATFORM}/release/${PROJECT_${projectName}_RELATIVE_PATH}")
	
	# publiczne headery, biblioteki dynamiczne + statyczne, aplikacje
	# faktycznie ustawiam typ projektu
	if(${PROJECT_${projectName}_TYPE} STREQUAL "executable")
		
		# plik wykonywalny
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT})
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT})		

	elseif(${PROJECT_${projectName}_TYPE} STREQUAL "static")
		
		# biblioteka statyczna
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} ARCHIVE DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT})
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} ARCHIVE DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT})			

	elseif(${PROJECT_${projectName}_TYPE} STREQUAL "dynamic")
		
		if(WIN32)
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug ARCHIVE DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT})
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release ARCHIVE DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT})
		elseif(UNIX)
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT})
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT})
		endif()
		
	else()
	
		# biblioteka dynamiczna
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT})
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT})
		
	endif()
	
	# instalujemy nag³ówki - raczej powinny byc ale zawsze sprawdzamy
	
	list(LENGTH PROJECT_${projectName}_PUBLIC_HEADERS _publicHeadersSize)
	
	if(_publicHeadersSize GREATER 0)
			
		file(TO_CMAKE_PATH "${PROJECT_${projectName}_RELATIVE_PATH}" HEADER_INSTALL_PATH)
		string(FIND "${HEADER_INSTALL_PATH}" "/" _firstIDX)
		if(_firstIDX EQUAL -1)
			set(HEADER_INSTALL_PATH "${HEADER_INSTALL_PATH}/${HEADER_INSTALL_PATH}")
		else()
			string(SUBSTRING "${HEADER_INSTALL_PATH}" 0 ${_firstIDX} _first)
			set(HEADER_INSTALL_PATH "${_first}/${HEADER_INSTALL_PATH}")
		endif()
	
		foreach(f ${PROJECT_${projectName}_PUBLIC_HEADERS})
			#musze odbudowaæ œcie¿kê w jakiej znajdzie siê ten plik
			file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_HEADER_PATH}" "${f}")
			get_filename_component(_f "${_relPath}" PATH)
			
			install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
		endforeach()
		
		foreach(f ${PROJECT_${projectName}_CONFIGURABLE_PUBLIC_HEADERS})
			#musze odbudowaæ œcie¿kê w jakiej znajdzie siê ten plik
			file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${projectName}" "${f}")
			get_filename_component(_f "${_relPath}" PATH)
			
			install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
		endforeach()
	endif()

endmacro(_INSTALL_PROJECT_DEV)


###############################################################################
# Makro generujace instalacjê zadanego projektu w wersji produktu - dla uzytkowników
# Parametry:
#		projectName Nazwa projektu dla którego generujemy instalacje produktu
macro(_INSTALL_PROJECT_PRODUCT projectName)

	_PROJECT_COMPONENT_NAME(PROJECT_COMPONENT "${projectName}" "product")	

	# wersja release
	# tylko runtime + resources + dependencies
	
	# t³umaczenia
	if(DEFINED PROJECT_${projectName}_TRANSLATIONS)
		install(FILES ${PROJECT_${projectName}_TRANSLATIONS} DESTINATION "bin/resources/lang" COMPONENT ${PROJECT_COMPONENT})
	endif()
	
	#zasoby do deployowania
	if(DEFINED DEPLOY_RESOURCES_FILES)
	
		# dla pewnoœci usuwamy pliki ts dla t³umaczeñ
	
		if(DEFINED TRANSLATION_FILES)
		
			foreach(t ${TRANSLATION_FILES})
			
				list(REMOVE_ITEM DEPLOY_RESOURCES_FILES "${t}")
			
			endforeach()
		
		endif()		
	
		if(DEFINED DEPLOY_MODIFIABLE_RESOURCES_FILES)			
			set(_tmp_modifiable_deploy "${DEPLOY_MODIFIABLE_RESOURCES_FILES}")				
			set(_new_tmp_modifyable_deploy "")
			foreach(f ${_tmp_modifiable_deploy})
			
				set(_path "${PROJECT_DEPLOY_RESOURCES_FILES_PATH}/${f}")				
				list(FIND DEPLOY_RESOURCES_FILES "${_path}" _d_idx)
				
				if(_d_idx GREATER -1)					
					list(REMOVE_AT DEPLOY_RESOURCES_FILES ${_d_idx})
					list(APPEND _new_tmp_modifyable_deploy "${_path}")
				endif()
		
			endforeach()			
			
			set(DEPLOY_MODIFIABLE_RESOURCES_FILES "${_new_tmp_modifyable_deploy}")
			set(PROJECT_${projectName}_DEPLOY_MODIFIABLE_RESOURCES ${DEPLOY_MODIFIABLE_RESOURCES_FILES})
		endif()
				
		# Deploy modyfikowalnych zasobów tutaj nie isntalujemy bo s¹ obslugiwane przez instalatory		
		
		foreach(f ${DEPLOY_RESOURCES_FILES})
			# musze najpierw do sciezki aboslutnej zeby dobrze wyznacza³ wzglêdn¹
			get_filename_component(_f "${f}" ABSOLUTE)
			#musze odbudowaæ œcie¿kê w jakiej znajdzie siê ten plik
			file(RELATIVE_PATH _relPath "${PROJECT_DEPLOY_RESOURCES_FILES_PATH}" "${_f}")
			get_filename_component(_f "${_relPath}" PATH)				
			
			install(FILES ${f} DESTINATION "bin/resources/${_f}" COMPONENT ${PROJECT_COMPONENT})
		endforeach()
		
	endif()
	
	if(${PROJECT_${projectName}_TYPE} STREQUAL "executable")
		
		# plik wykonywalny
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_COMPONENT})

	elseif(${PROJECT_${projectName}_TYPE} STREQUAL "dynamic")
		
		if(WIN32)
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} RUNTIME DESTINATION bin COMPONENT ${PROJECT_COMPONENT})						
		elseif(UNIX)
			install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_COMPONENT})						
		endif()
		
	elseif(${PROJECT_${projectName}_TYPE} STREQUAL "module")
		
		# biblioteka dynamiczna
		install(TARGETS ${PROJECT_${projectName}_TARGETNAME} LIBRARY DESTINATION bin COMPONENT ${PROJECT_COMPONENT})					
		
	endif()
			
	set(LIBRARIES_TO_CHECK "")		
	
	# teraz instalujê dependencies jeœli jeszcze nie by³y instalowane
	foreach(dep ${PROJECT_${projectName}_DEPENDENCIES})
	
		# sprawdzam czy zale¿noœæ nie jest projektem - jesli jest to pomija bo itak j¹ bêde instalowa³

		list(FIND SOLUTION_PROJECTS ${dep} _projectIDX)
		if(_projectIDX EQUAL -1)
			list(APPEND LIBRARIES_TO_CHECK ${dep})
		endif()
		
	endforeach()

	set(LIBRARIES_TO_INSTALL "")
	
	list(LENGTH LIBRARIES_TO_CHECK _CHECK_DEEPER)
			
	while(_CHECK_DEEPER GREATER 0)
	
		list(GET LIBRARIES_TO_CHECK 0 DEP_ITEM)
		
		list(FIND SOLUTION_INSTALLED_DEPENDENCIES ${DEP_ITEM} _depIDX)
		list(FIND LIBRARIES_TO_INSTALL ${DEP_ITEM} _instIDX)
		if(_depIDX EQUAL -1 AND _instIDX EQUAL -1)
		
			if(DEFINED LIBRARY_${DEP_ITEM}_PREREQUISITES)
			
				list(APPEND LIBRARIES_TO_CHECK ${LIBRARY_${DEP_ITEM}_PREREQUISITES})
			
			endif()
			
			if(DEFINED LIBRARY_${DEP_ITEM}_DEPENDENCIES)
				
				list(APPEND LIBRARIES_TO_CHECK ${LIBRARY_${DEP_ITEM}_DEPENDENCIES})
				
			endif()
			
			list(REMOVE_DUPLICATES LIBRARIES_TO_CHECK)
			list(APPEND LIBRARIES_TO_INSTALL ${DEP_ITEM})
			
		endif()
		
		list(REMOVE_AT LIBRARIES_TO_CHECK 0)					
		list(LENGTH LIBRARIES_TO_CHECK _CHECK_DEEPER)
	
	endwhile()
		
	foreach(l ${LIBRARIES_TO_INSTALL})

		_LIBRARY_COMPONENT_NAME(LIBRARY_COMPONENT "${l}" "product")
	
		foreach(lib ${LIBRARY_${l}_RELEASE_DLLS})
			install(FILES ${${lib}} DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
		endforeach()
		
		foreach(lib ${LIBRARY_${l}_DEBUG_DLLS})
			install(FILES ${${lib}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
		endforeach()
		
		foreach(dir ${LIBRARY_${l}_RELEASE_DIRECTORIES})
			install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
		endforeach()
		
		foreach(dir ${LIBRARY_${l}_DEBUG_DIRECTORIES})
			install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
		endforeach()
		
		#TODO - pliki wykonywalne s¹ nam niepotrzebne, praktycznie tylko aplikacje z QT siê pod to ³api¹
		
		if(UNIX)
			foreach(app ${LIBRARY_${l}_RELEASE_EXECUTABLES})
				install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
		
			foreach(app ${LIBRARY_${l}_DEBUG_EXECUTABLES})
				install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
		endif()
		
		install(FILES ${LIBRARY_${l}_RELEASE_TRANSLATIONS} DESTINATION "bin/resources/lang" CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
		
		install(FILES ${LIBRARY_${l}_DEBUG_TRANSLATIONS} DESTINATION "bin/resources/lang" CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
	
	endforeach()
	
	_APPEND_INTERNAL_CACHE_VALUE("${LIBRARIES_TO_INSTALL}" SOLUTION_INSTALLED_DEPENDENCIES "Already installed dependencies")

endmacro(_INSTALL_PROJECT_PRODUCT)