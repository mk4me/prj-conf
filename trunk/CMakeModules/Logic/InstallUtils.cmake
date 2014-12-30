# inicjalizacja logowania wiadomosci modulu install
INIT_VERBOSE_OPTION(INSTALL "Print install verbose info?")	

###############################################################################
# Automatyczne generowanie warningu kiedy instalujemy do �cie�ek bezwzgl�dnych!!
###############################################################################

set(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION ON)

###############################################################################
# Instalacje realizowane sa w oparciu o CPack i NSIS (windows) oraz dep (linux)
###############################################################################
# Zbi�r makr u�atwiaj�cych instalacj� projekt�w oraz generowanie instalator�w.
# Wyr�niamy nast�puj�ce typy instalacji:
#	product - exe + dlls + resources + dependency
#	libraries_api - exe + dlls + resources + dependency + public headers + import libs [where phisible]
#
###############################################################################

###############################################################################
# Makro obs�uguj�ce generowanie komunikat�w diagnostycznych dla makr instalacji
# Parametry:
#		var - nazwa zmiennej
#		msg - wiadomo��
macro(INSTALLATION_NOTIFY var msg)
	if (INSTALLATION_VERBOSE)
		message(STATUS "INSTALLATION>${var}>${msg}")
	endif()
endmacro(INSTALLATION_NOTIFY)

# Makro rozpoczynaj�ce blok generowania instalacji
macro(_BEGIN_INSTALLATION)

	# generowanie instalacji
	CONFIG_OPTION(CREATE_INSTALLATION "Czy konfigurowa� instalacj�?" OFF)
	
	if(CREATE_INSTALLATION)		
		set(CMAKE_INSTALL_PREFIX "${SOLUTION_LIBRARIES_ROOT}" CACHE PATH "Solution installation path.")
		set(SOLUTION_INSTALLED_DEPENDENCIES "" CACHE INTERNAL "Already installed dependencies" FORCE)
	endif()

endmacro(_BEGIN_INSTALLATION)

###############################################################################
# Makro ko�cz�ce blok generowania instalacji
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
# Makro generujace instalacj� zadanego projektu
# Parametry:
#		projectName Nazwa projektu dla kt�rego generujemy instalacje
macro(_INSTALL_PROJECT projectName)
	
	_INSTALL_PROJECT_DEV(${projectName})
	_INSTALL_PROJECT_PRODUCT(${projectName})

endmacro(_INSTALL_PROJECT)

###############################################################################
# Makro generujace nazwe komponentu
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		name Nazwa projektu dla kt�rego generujemy nazwe komponentu
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
#		projectName Nazwa projektu dla kt�rego generujemy nazwe komponentu
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
# Makro generujace nazwe komponentu translacji
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		projectName Nazwa projektu dla kt�rego generujemy nazwe komponentu
#		type		Typ komponentu: dev | product
macro(_PROJECT_TRANSLATION_COMPONENT_NAME variable projectName type)

	set(_variable "")
	_PROJECT_COMPONENT_NAME(_variable "${projectName}" "${type}")
	set("${variable}" "${_variable}_TRANSLATIONS")	

endmacro(_PROJECT_TRANSLATION_COMPONENT_NAME)

###############################################################################
# Makro generujace nazwe komponentu
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		projectName Nazwa projektu dla kt�rego generujemy nazwe komponentu
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
# Makro generujace nazwe komponentu translacji
# Parametry:
#		variable	Zmienna do ktorej trafi nazwa komponentu
#		libraryName Nazwa biblioteki dla kt�rej generujemy nazwe komponentu
#		type		Typ komponentu: dev | product
macro(_LIBRARY_TRANSLATION_COMPONENT_NAME variable libraryName type)

	set(_variable "")
	_LIBRARY_COMPONENT_NAME(_variable "${libraryName}" "${type}")
	set("${variable}" "${_variable}_TRANSLATIONS")	

endmacro(_LIBRARY_TRANSLATION_COMPONENT_NAME)


###############################################################################
# Makro generujace instalacj� zadanego projektu w wersji dla developer�w - rozw�j aplikacji
# Parametry:
#		projectName Nazwa projektu dla kt�rego generujemy instalacje developersk�
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
	
	if(DEFINED PROJECT_${projectName}_ADDITIONAL_INSTALLS)
		list(LENGTH PROJECT_${projectName}_ADDITIONAL_INSTALLS _additionalInstalsLength)
		if(${_additionalInstalsLength} EQUAL 1)
			get_target_property(_dTargerName ${PROJECT_${projectName}_TARGETNAME} LOCATION_DEBUG)
			get_target_property(_rTargerName ${PROJECT_${projectName}_TARGETNAME} LOCATION_RELEASE)			
			list(GET PROJECT_${projectName}_ADDITIONAL_INSTALLS 0 _name)
			install(FILES "${_dTargerName}" DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT} RENAME "${_name}")			
			install(FILES "${_rTargerName}" DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT} RENAME "${_name}")			
		elseif(${_additionalInstalsLength} EQUAL 2)
			get_target_property(_dTargerName ${PROJECT_${projectName}_TARGETNAME} LOCATION_DEBUG)
			get_target_property(_rTargerName ${PROJECT_${projectName}_TARGETNAME} LOCATION_RELEASE)
			list(GET PROJECT_${projectName}_ADDITIONAL_INSTALLS 0 _rName)
			list(GET PROJECT_${projectName}_ADDITIONAL_INSTALLS 1 _dName)			
			
			install(FILES "${_dTargerName}" DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}" CONFIGURATIONS Debug COMPONENT ${PROJECT_COMPONENT} RENAME "${_dName}")			
			install(FILES "${_rTargerName}" DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}" CONFIGURATIONS Release COMPONENT ${PROJECT_COMPONENT} RENAME "${_rName}")			
		else()
			INSTALLATION_NOTIFY(PROJECT_${projectName}_ADDITIONAL_INSTALLS "Inproper arguments for additional instals - 1 argument is a name for additional both debug and release installations, 2 arguments are release and debug additional installation names respectively. ${_additionalInstalsLength} arguments given.")
		endif()
	endif()
	
	# instalujemy nag��wki - raczej powinny byc ale zawsze sprawdzamy
	
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
			#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
			file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_HEADER_PATH}" "${f}")
			get_filename_component(_f "${_relPath}" PATH)
			
			install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
		endforeach()
		
		foreach(f ${PROJECT_${projectName}_CONFIGURABLE_PUBLIC_HEADERS})
			#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
			file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${projectName}" "${f}")
			get_filename_component(_f "${_relPath}" PATH)
			
			install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
		endforeach()
	endif()
	
	# TODO
	# pozosta�e resourcy projektu
	
	# t�umaczenia
	#if(DEFINED PROJECT_${projectName}_TRANSLATIONS)
	#	list(LENGTH PROJECT_${projectName}_TRANSLATIONS _tl)
	#	if(${_tl} GREATER 0)
	#		_SETUP_INTERNAL_CACHE_VALUE(PROJECT_${projectName}_TRANSLATIONS "${PROJECT_${projectName}_TRANSLATIONS}" "T�umaczenia projektu")
	#		_PROJECT_TRANSLATION_COMPONENT_NAME(PROJECT_TRANSLATION_COMPONENT "${projectName}" "product")			
	#		install(FILES ${PROJECT_${projectName}_TRANSLATIONS} DESTINATION "${ARTIFACTS_DEBUG_DESTINATION}/resources/lang" CONFIGURATIONS Debug COMPONENT ${PROJECT_TRANSLATION_COMPONENT})
	#		install(FILES ${PROJECT_${projectName}_TRANSLATIONS} DESTINATION "${ARTIFACTS_RELEASE_DESTINATION}/resources/lang" CONFIGURATIONS Release COMPONENT ${PROJECT_TRANSLATION_COMPONENT})
	#	endif()
	#endif()

endmacro(_INSTALL_PROJECT_DEV)

###############################################################################
# Makro instaluje faktyczne pliki a nie linki symboliczne czy dowi�zania
# Parametry:
#		projectName Nazwa projektu dla kt�rego generujemy instalacje produktu
macro(_INSTALL_FILES files destination configuration component)	

	set(_locFilesToInstall "")

	foreach(f ${files})
	
		list(APPEND _locFilesToInstall "${f}")
			
		if(IS_SYMLINK "${f}")
			get_filename_component(_resolvedFile "${f}" REALPATH)
			list(APPEND _locFilesToInstall "${_resolvedFile}")			
		endif()

	endforeach()

	list(REMOVE_DUPLICATES _locFilesToInstall)	

	install(FILES ${_locFilesToInstall} DESTINATION "${destination}" CONFIGURATIONS "${configuration}" COMPONENT "${component}")

endmacro(_INSTALL_FILES)

###############################################################################
# Makro generujace instalacj� zadanego projektu w wersji produktu - dla uzytkownik�w
# Parametry:
#		projectName Nazwa projektu dla kt�rego generujemy instalacje produktu
macro(_INSTALL_PROJECT_PRODUCT projectName)

	_PROJECT_COMPONENT_NAME(PROJECT_COMPONENT "${projectName}" "product")	

	# wersja release
	# tylko runtime + resources + dependencies
	
	# t�umaczenia
	if(DEFINED PROJECT_${projectName}_TRANSLATIONS)
		list(LENGTH PROJECT_${projectName}_TRANSLATIONS _tl)
		if(${_tl} GREATER 0)
			_SETUP_INTERNAL_CACHE_VALUE(PROJECT_${projectName}_TRANSLATIONS "${PROJECT_${projectName}_TRANSLATIONS}" "T�umaczenia projektu")
			_PROJECT_TRANSLATION_COMPONENT_NAME(PROJECT_TRANSLATION_COMPONENT "${projectName}" "product")			
			install(FILES ${PROJECT_${projectName}_TRANSLATIONS} DESTINATION "bin/resources/lang" COMPONENT ${PROJECT_TRANSLATION_COMPONENT})
		endif()
	endif()
	
	#zasoby do deployowania
	if(DEFINED DEPLOY_RESOURCES_FILES)
	
		# dla pewno�ci usuwamy pliki ts dla t�umacze�
	
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
				
		# Deploy modyfikowalnych zasob�w tutaj nie isntalujemy bo s� obslugiwane przez instalatory		
		
		foreach(f ${DEPLOY_RESOURCES_FILES})
			# musze najpierw do sciezki aboslutnej zeby dobrze wyznacza� wzgl�dn�
			get_filename_component(_f "${f}" ABSOLUTE)
			#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
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
	
	# teraz instaluj� dependencies je�li jeszcze nie by�y instalowane
	foreach(dep ${PROJECT_${projectName}_DEPENDENCIES})
	
		# sprawdzam czy zale�no�� nie jest projektem - jesli jest to pomija bo itak j� b�de instalowa�

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
		list(LENGTH LIBRARY_${l}_RELEASE_DLLS _rLength)
		list(LENGTH LIBRARY_${l}_DEBUG_DLLS _dLength)
		
		if(${_rLength} GREATER 0 AND ${_dLength} GREATER 0)
		
			foreach(lib ${LIBRARY_${l}_RELEASE_DLLS})
				_INSTALL_FILES("${${lib}}" bin Release "${LIBRARY_COMPONENT}")
				#install(FILES  DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
			
			foreach(lib ${LIBRARY_${l}_DEBUG_DLLS})
				_INSTALL_FILES("${${lib}}" bin Debug "${LIBRARY_COMPONENT}")
				#install(FILES ${${lib}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
		
		elseif(${_rLength} GREATER 0)
		
			foreach(lib ${LIBRARY_${l}_RELEASE_DLLS})
				_INSTALL_FILES("${${lib}}" bin "" "${LIBRARY_COMPONENT}")
				#install(FILES ${${lib}} DESTINATION bin COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
			
		elseif(${_dLength} GREATER 0)
		
			foreach(lib ${LIBRARY_${l}_DEBUG_DLLS})
				_INSTALL_FILES("${${lib}}" bin "" "${LIBRARY_COMPONENT}")
				#install(FILES ${${lib}} DESTINATION bin COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
		
		else()
		
			INSTALLATION_NOTIFY(l "Library ${l} has no distributable artifacts to install")
			
		endif()
		
		list(LENGTH LIBRARY_${l}_RELEASE_DIRECTORIES _rLength)
		list(LENGTH LIBRARY_${l}_DEBUG_DIRECTORIES _dLength)
		
		if(${_rLength} GREATER 0 AND ${_dLength} GREATER 0)
		
			foreach(dir ${LIBRARY_${l}_RELEASE_DIRECTORIES})
				install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
			
			foreach(dir ${LIBRARY_${l}_DEBUG_DIRECTORIES})
				install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
		
		elseif(${_rLength} GREATER 0)
		
			foreach(dir ${LIBRARY_${l}_RELEASE_DIRECTORIES})
				install(DIRECTORY ${${dir}} DESTINATION bin COMPONENT "${LIBRARY_COMPONENT}")
			endforeach()
			
		elseif(${_dLength} GREATER 0)
		
			foreach(dir ${LIBRARY_${l}_DEBUG_DIRECTORIES})
				install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS "${LIBRARY_COMPONENT}")
			endforeach()
		
		else()
		
			INSTALLATION_NOTIFY(l "Library ${l} has no distributable directories to install")
			
		endif()
		
		
		#TODO - pliki wykonywalne s� nam niepotrzebne, praktycznie tylko aplikacje z QT si� pod to �api�
		
		if(UNIX)
		
			list(LENGTH LIBRARY_${l}_RELEASE_EXECUTABLES _rLength)
			list(LENGTH LIBRARY_${l}_DEBUG_EXECUTABLES _dLength)
			
			if(${_rLength} GREATER 0 AND ${_dLength} GREATER 0)
		
				foreach(app ${LIBRARY_${l}_RELEASE_EXECUTABLES})
					install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Release COMPONENT "${LIBRARY_COMPONENT}")
				endforeach()
			
				foreach(app ${LIBRARY_${l}_DEBUG_EXECUTABLES})
					install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Debug COMPONENT "${LIBRARY_COMPONENT}")
				endforeach()
			
			elseif(${_rLength} GREATER 0)
			
				foreach(app ${LIBRARY_${l}_RELEASE_EXECUTABLES})
					install(PROGRAMS ${${app}} DESTINATION bin COMPONENT "${LIBRARY_COMPONENT}")
				endforeach()
				
			elseif(${_dLength} GREATER 0)
			
				foreach(app ${LIBRARY_${l}_DEBUG_EXECUTABLES})
					install(PROGRAMS ${${app}} DESTINATION bin COMPONENT "${LIBRARY_COMPONENT}")
				endforeach()
			
			else()
			
				INSTALLATION_NOTIFY(l "Library ${l} has no distributable executables to install")
				
			endif()
		
			
		endif()
		
		list(LENGTH LIBRARY_${l}_RELEASE_TRANSLATIONS _rLength)
		list(LENGTH LIBRARY_${l}_DEBUG_TRANSLATIONS _dLength)
		_LIBRARY_TRANSLATION_COMPONENT_NAME(LIBRARY_TRANSLATIONS_COMPONENT "${l}" "product")
		
		if(${_rLength} GREATER 0 AND ${_dLength} GREATER 0)
		
			install(FILES ${LIBRARY_${l}_RELEASE_TRANSLATIONS} DESTINATION "bin/resources/lang" CONFIGURATIONS Release COMPONENT "${LIBRARY_TRANSLATIONS_COMPONENT}")
		
			install(FILES ${LIBRARY_${l}_DEBUG_TRANSLATIONS} DESTINATION "bin/resources/lang" CONFIGURATIONS Debug COMPONENT "${LIBRARY_TRANSLATIONS_COMPONENT}")
		
		elseif(${_rLength} GREATER 0)
		
			install(FILES ${LIBRARY_${l}_RELEASE_TRANSLATIONS} DESTINATION "bin/resources/lang" COMPONENT "${LIBRARY_TRANSLATIONS_COMPONENT}")
			
		elseif(${_dLength} GREATER 0)
		
			install(FILES ${LIBRARY_${l}_DEBUG_TRANSLATIONS} DESTINATION "bin/resources/lang" COMPONENT "${LIBRARY_TRANSLATIONS_COMPONENT}")
		
		else()
		
			INSTALLATION_NOTIFY(l "Library ${l} has no distributable translations to install")
			
		endif()		
	
	endforeach()
	
	_APPEND_INTERNAL_CACHE_VALUE(SOLUTION_INSTALLED_DEPENDENCIES "${LIBRARIES_TO_INSTALL}" "Already installed dependencies")

endmacro(_INSTALL_PROJECT_PRODUCT)

###############################################################################
# Sprawdza czy projekt jest bezposrednio instalowalna
#	Parametry:
# 			variable - zmienna kt�rej ustawiamy 0 lub 1 w zale�no�ci czy biblioteka dla danej konfiguracji jest instalowalna
#			type - typ instalacji dla kt�rego sprawdzamy czy biblioteka jest instalowalna
#			project - biblioteka kt�ra sprawdzamy		
macro(IS_PROJECT_INSTALLABLE variable type projectName)

	set(${variable} 0)

	if("${type}" STREQUAL "dev"
		OR "${PROJECT_${projectName}_TYPE}" STREQUAL "executable"
		OR "${PROJECT_${projectName}_TYPE}" STREQUAL "dynamic"
		OR "${PROJECT_${projectName}_TYPE}" STREQUAL "module")
		
		set(${variable} 1)
		
	else()
	
		set(_count 0)
	
		#if(DEFINED PROJECT_${projectName}_TRANSLATIONS)
		#	list(LENGTH PROJECT_${projectName}_TRANSLATIONS _l)
		#	math(EXPR _count "${_count} + ${_l}")
		#endif()
			
		if(DEFINED PROJECT_${projectName}_DEPLOY_RESOURCES)
			list(LENGTH PROJECT_${projectName}_DEPLOY_RESOURCES _l)
			math(EXPR _count "${_count} + ${_l}")
		endif()
		
		if(DEFINED PROJECT_${projectName}_DEPLOY_MODIFIABLE_RESOURCES)
			list(LENGTH PROJECT_${projectName}_DEPLOY_MODIFIABLE_RESOURCES _l)
			math(EXPR _count "${_count} - ${_l}")
		endif()
		
		if(${_count} GREATER 0)
			set(${variable} 1)
		endif()
	
	endif()
		
endmacro(IS_PROJECT_INSTALLABLE)