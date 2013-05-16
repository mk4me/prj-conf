###############################################################################
# Instalacje realizowane sa w oparciu o CPack i NSIS (windows) oraz dep (linux)
###############################################################################
# Zbi�r makr u�atwiaj�cych instalacj� projekt�w oraz generowanie instalator�w.
# Wyr�niamy nast�puj�ce typy instalacji:
#	product - exe + dlls + resources + dependency
#	libraries_api - exe + dlls + resources + dependency + public headers + import libs [where phisible]
#
###############################################################################

# Makro weryfikuj�ce typ instalacji
# type - Typ instalacji:
# product - instalacja na potrzeby instalatora, gotowy produkt do testowania i u�ytkowania, bez mo�liwo�ci rozwoju aplikacji (brak lib�w i nag��k�w)
# libraries_api - instalacja na potrzeby rozwijania aplikacji (dll + libs + publiczne nag��wki), realizowana wg schematu bibliotek zale�nych
macro(__VERIFY_INSTALLATION_TYPE type)

	if(NOT (${type} STREQUAL "product" OR ${type} STREQUAL "libraries_api") )
		message(SEND_ERROR "Nieznany typ instalacji dla ${PROJECT_NAME}. W�a�ciwa warto�� to: product, libraries_api")
	endif()

endmacro(__VERIFY_INSTALLATION_TYPE)

# Makro rozpoczynaj�ce blok generowania instalacji
macro(_BEGIN_INSTALLATION)

	# zapami�tuj� typ instalacji
	set(SOLUTION_INSTALLATION_TYPE "libraries_api" CACHE STRING "Typ generowanej instalacji")

	__VERIFY_INSTALLATION_TYPE(${SOLUTION_INSTALLATION_TYPE})	

	# generowanie instalacji
	CONFIG_OPTION(CREATE_INSTALLATION "Czy konfigurowa� instalacj�?" OFF)
	
	if(CREATE_INSTALLATION)		
		set(CMAKE_INSTALL_PREFIX "${SOLUTION_LIBRARIES_ROOT}" CACHE PATH "Solution installation path.")
	endif()
	
	set(SOLUTION_INSTALLED_DEPENDENCIES "")

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
# Makro rozpoczynaj�ce blok generowania instalatora
# Parametry:
#		name - Nazwa instalatora
#		outputName - Plik wyj�ciowy instalatora
macro(BEGIN_INSTALLER name outputName)

	# je�eli ju� generowa�em instalacj� to zg�aszam b��d
	if(DEFINED SOLUTION_INSTALLER_STARTED)
		message(FATAL_ERROR "Instalation was already configured, can not generate new instalation")
	endif()
	
	# zapami�tuj� �e ju� rozpoczalem konfiguracj� instalacji
	set(SOLUTION_INSTALLER_STARTED 1)
	# ustawiam typy instalacji
	set(SOLUTION_INSTALLER_INSTALLATION_TYPES "" CACHE INTERNAL "Typy instalacji jakie wyst�pi� w instalatorze" FORCE)	
	
	# generowanie instalatora
	CONFIG_DEPENDENT_OPTION(GENERATE_INSTALLER "Czy generowa� instalator?" OFF "CREATE_INSTALLATION" OFF)
	
	# zapami�tuj� list� projekt�w do instalacji
	set(SOLUTION_INSTALLER_PROJECTS ${SOLUTION_PROJECTS} CACHE INTERNAL "Wszystkie projekty kt�re musza by� skonfigurowane na potrzeby instalatora" FORCE)
	# zeruj� list� grup komponent�w instalacji
	set(SOLUTION_INSTALLER_GROUPS "" CACHE INTERNAL "Grupy element�w instalatora" FORCE)
	
	set(SOLUTION_INSTALLER_NAME "${name}" CACHE INTERNAL "Nazwa instalatora" FORCE)
	
	set(SOLUTION_INSTALLER_OUTPUT_FILE_NAME "${outputName}" CACHE INTERNAL "Nazwa pliku wyj�ciowego instalatora" FORCE)
	
	set(SOLUTION_INSTALLER_VENDOR "PJWSTK" CACHE INTERNAL "Nazwa dostawcy/producenta oprogramowania" FORCE)
	
endmacro(BEGIN_INSTALLER)

###############################################################################
# Makro ustawia producenta produktu
# Parametry:
#		vendor - nazwa producenta
macro(SET_INSTALLER_VENDOR vendor)
	
	set(SOLUTION_INSTALLER_VENDOR "${vendor}" CACHE INTERNAL "Nazwa dostawcy/producenta oprogramowania" FORCE)
	
endmacro(SET_INSTALLER_VENDOR)

###############################################################################
# Makro ustawia wersj� produktu
# Parametry:
#		version - wersja produktu
macro(SET_INSTALLER_VERSION version)
	
	set(SOLUTION_INSTALLER_VERSION "${version}" CACHE INTERNAL "Wersja oprogramowania" FORCE)	
	
endmacro(SET_INSTALLER_VERSION)

###############################################################################
# Makro ustawia licencj� produktu
# Parametry:
#		license - �cie�ka do pliku z licencj�
macro(SET_INSTALLER_LICENSE license)
	
	SET(SOLUTION_INSTALLER_LICENSE_FILE "${license}" CACHE INTERNAL "Plik z licencj� oprogramowania" FORCE)	
	
endmacro(SET_INSTALLER_LICENSE)

###############################################################################
# Makro ustawia powitanie instalatora produktu
# Parametry:
#		welcome - �cie�ka do pliku z powitaniem
macro(SET_INSTALLER_WELCOME welcome)

	SET(SOLUTION_INSTALLER_WELCOME_FILE "${license}" CACHE INTERNAL "Plik z tekstem powitalnym instalatora" FORCE)	
	
endmacro(SET_INSTALLER_WELCOME)

###############################################################################
# Makro ustawia kr�tki opis produktu po instalacji
# Parametry:
#		readme - �cie�ka do pliku z opisem
macro(SET_INSTALLER_README readme)

	SET(SOLUTION_INSTALLER_README_FILE "${readme}" CACHE INTERNAL "Plik z kr�tkim tekstem o aplikacji do przeczytania po instalacji" FORCE)		
	
endmacro(SET_INSTALLER_README)

###############################################################################
# Makro ustawia kr�tki opis produktu w trakcie instalacji
# Parametry:
#		readme - �cie�ka do pliku z opisem
macro(SET_INSTALLER_DESCRIPTION description)

	SET(SOLUTION_INSTALLER_DESCRIPTION_FILE "${description}" CACHE INTERNAL "Plik z tekstem opisu aplikacji pokazywanym w trakcie instalacji" FORCE)
	
endmacro(SET_INSTALLER_DESCRIPTION)


###############################################################################
# Makro ustawia ikony instalacji
# Parametry:
#		productIco - �cie�ka do ikony produktu
#		uninstallIco - �cie�ka do ikony wyinstalowuj�cej produkt
macro(SET_INSTALLER_ICONS productIco uninstallIco)

	set(SOLUTION_INSTALLER_PRODUCT_ICON "${productIco}" CACHE INTERNAL "Ikona produktu" FORCE)
	set(SOLUTION_INSTALLER_PRODUCT_UNINSTALL_ICON "${uninstallIco}" CACHE INTERNAL "Ikona wyinstalowywania produktu" FORCE)
	
endmacro(SET_INSTALLER_ICONS)

###############################################################################
# Makro ustawia dodatkowe informacje o produkcie
# Parametry:
#		helpLink - link do pomocy
#		aboutLink - link do strony produktu
#		vendorContact - kontakt do producenta
macro(SET_INSTALLER_ADDITIONAL_INFO helpLink aboutLink vendorContact)	

	set(SOLUTION_INSTALLER_ADDITIONAL_INFO_HELP_LINK "${helpLink}" CACHE INTERNAL "Link do strony z pomoc� produktu" FORCE)
	set(SOLUTION_INSTALLER_ADDITIONAL_INFO_ABOUT_LINK "${aboutLink}" CACHE INTERNAL "Link do strony z informacj� o produkcie" FORCE)
	set(SOLUTION_INSTALLER_ADDITIONAL_INFO_VENDOR_CONTACT "${vendorContact}" CACHE INTERNAL "Kontakt do producenta" FORCE)
	
endmacro(SET_INSTALLER_ADDITIONAL_INFO)

###############################################################################
# Makro pozwala uruchomi� aplikacj� po instalacji
# Parametry:
#		app - �cie�ka do aplikacji, kt�r� user b�dzie m�g� wystartowa� po zako�czeniu instalacji
macro(SET_INSTALLER_FINISH_RUN_APP app)	

	set(SOLUTION_INSTALLER_FINISH_RUN_APP "${app}" CACHE INTERNAL "Aplikacja do uruchomienia po zako�czeniu instalacji" FORCE)
	
endmacro(SET_INSTALLER_FINISH_RUN_APP)

###############################################################################
# Makro pomocnicze przy dodawaniu typ�w instalacji
# Parametry:
#		name - nazwa typu instalacji
#		displayName - wy�wietlana nazwa
macro(ADD_INSTALLER_INSTALLATION_TYPE name displayName)

	# szukam typu instalacji
	list(FIND SOLUTION_INSTALLER_INSTALLATION_TYPES ${name} _listIDX)
	if(_listIDX GREATER -1)
		# znalaz�em - zg�aszam info o pomini�ciu
		INSTALL_NOTIFY(INSTALLATION_TYPE_${name}_DISPLAY "Instalation type ${name} already defined with display name : < ${INSTALLATION_TYPE_${name}_DISPLAY} >. Skipping...")
	else()
		# nie znalaz�em - dodaj�
		set(SOLUTION_INSTALLER_INSTALLATION_TYPES ${SOLUTION_INSTALLER_INSTALLATION_TYPES} ${name} CACHE INTERNAL "Typy instalacji jakie wyst�pi� w instalatorze" FORCE)		
		set(SOLUTION_INSTALLER_INSTALLATION_TYPE_${name}_DISPLAY ${displayName} CACHE INTERNAL "Nazwa wy�wietlana dla typu instalacji ${name}" FORCE)
	endif()
	
endmacro(ADD_INSTALLER_INSTALLATION_TYPE)

###############################################################################
# Makro otwieraj�ce grup� dla element�w instalacji
# Parametry:
#		name - nazwa grupy
#		displayName - wy�wietlana nazwa
#		description - opis
#		[expanded] - czy ma by� ga��� domy�lnie rozwini�ta
#		[bold] - czy tekst ma by� pogrubiony w instalatorze
macro(BEGIN_INSTALLER_GROUP name displayName description)

	list(FIND SOLUTION_INSTALLER_GROUPS ${name} _groupIDX)
	
	if(_groupIDX GREATER -1)
		message(FATAL_ERROR "Installation group with name ${name} already defined! Can not create two groups with the same name")
	else()
		set(SOLUTION_INSTALLER_GROUPS ${SOLUTION_INSTALLER_GROUPS} ${name} CACHE INTERNAL "Grupy element�w instalatora" FORCE)	
		set(SOLUTION_INSTALLER_GROUP_${name}_DISPLAY ${displayName} CACHE INTERNAL "Nazwa wy�wietlana dla grupy ${name}" FORCE)
		set(SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION ${description} CACHE INTERNAL "Opis wy�wietlany dla grupy ${name}" FORCE)
		
		# sprawdzam czy mam rodzica i ustawiam je�li trzeba
		list(LENGTH SOLUTION_INSTALLER_GROUPS _groupsLength)
		
		math(EXPR _groupsLength "${_groupsLength} - 2")
		
		if(_groupsLength GREATER -1)
			list(GET SOLUTION_INSTALLER_GROUPS ${_groupsLength} _PARENT)			
			set(SOLUTION_INSTALLER_GROUP_${name}_PARENT ${_PARENT} CACHE INTERNAL "Nadrz�dna grupa dla grupy ${name}" FORCE)
		endif()
		
		set(SOLUTION_INSTALLER_GROUP_${name}_EXPANDED 0)
		
		if(${ARGC} GREATER 1)
			set(SOLUTION_INSTALLER_GROUP_${name}_EXPANDED ${ARGV1})
		endif()
		
		set(SOLUTION_INSTALLER_GROUP_${name}_EXPANDED ${SOLUTION_INSTALLER_GROUP_${name}_EXPANDED} CACHE INTERNAL "Czy grypa ${name} ma by� domy�lnie rozwini�ta" FORCE)
		
		set(SOLUTION_INSTALLER_GROUP_${name}_BOLD 0)
		
		if(${ARGC} GREATER 2)
			set(SOLUTION_INSTALLER_GROUP_${name}_BOLD ${ARGV2})
		endif()
		
		set(SOLUTION_INSTALLER_GROUP_${name}_BOLD ${SOLUTION_INSTALLER_GROUP_${name}_BOLD} CACHE INTERNAL "Czy grypa ${name} ma by� domy�lnie pogrubiona" FORCE)
		
	endif()
	
endmacro(BEGIN_INSTALLER_GROUP)

###############################################################################
# Makro zamykaj�ce grup� dla element�w instalacji
macro(END_INSTALLER_GROUP)

	list(LENGTH SOLUTION_INSTALLER_GROUPS _groupsLength)
	
	if(_groupsLength GREATER 0)
		
		set(tmp_groups ${SOLUTION_INSTALLER_GROUPS})
		
		math(EXPR _groupsLength "${_groupsLength} - 1")
		
		list(REMOVE_AT tmp_groups ${_groupsLength})
		
		set(SOLUTION_INSTALLER_GROUPS ${tmp_groups} CACHE INTERNAL "Grupy element�w instalatora" FORCE)
		
	endif()
	
endmacro(END_INSTALLER_GROUP)

###############################################################################
# Makro dodaj�ce target/projekt do instalacji
# Parametry:
#		name - nazwa projektu
#		displayName - wy�wietlana nazwa
#		description - opis
#		[options] - opcje [HIDDEN - ukryty | REQUIRED - wymagany | DISABLED - domy�lnie wy��czony z instalacji]
#		[installTypes] - typy instalacji w jakich ma si� pojawi� ten projekt
macro(ADD_INSTALLER_GROUP_PROJECT name displayName description)

	list(FIND SOLUTION_INSTALLER_PROJECTS ${name} _projectIDX)	
	
	if(_projectIDX GREATER -1)
		# projekt jeszcze nie by� dodawany - moge konfigurowa�
		
		set(SOLUTION_INSTALLER_PROJECT_${name}_DISPLAY ${displayName} CACHE INTERNAL "Wy�wietlana nazwa dla projektu ${name}" FORCE)
		set(SOLUTION_INSTALLER_PROJECT_${name}_DESCRIPTION ${description} CACHE INTERNAL "Wy�wietlany opis dla projektu ${name}" FORCE)
		
		set(SOLUTION_INSTALLER_PROJECT_${name}_OPTIONS "")
		
		# ustawiam opcje je�li podano
		if(${ARGC} GREATER 3)
			set(SOLUTION_INSTALLER_PROJECT_${name}_OPTIONS ${ARGV3})
		endif()
		
		set(SOLUTION_INSTALLER_PROJECT_${name}_OPTIONS ${SOLUTION_INSTALLER_PROJECT_${name}_OPTIONS} CACHE INTERNAL "Dodatkowe opcje dla projektu ${name}" FORCE)
		
		# ustawiam typy instalacji jesli podano
		if(${ARGC} GREATER 4)
			set(SOLUTION_INSTALLER_PROJECT_${name}_INSTALLTYPES ${ARGV4} CACHE INTERNAL "Typy instalacji w kt�rych ma wystapi� projekt ${name}" FORCE)
		endif()
		
		# ustawiam grup� je�li zdefiniowano
		list(LENGTH SOLUTION_INSTALLER_GROUPS _groupsLength)
		
		math(EXPR _groupsLength "${_groupsLength} - 1")
		
		if(_groupsLength GREATER -1)
			list(GET SOLUTION_INSTALLER_GROUPS ${_groupsLength} _GROUP)
			set(SOLUTION_INSTALLER_PROJECT_${name}_GROUP ${_GROUP} CACHE INTERNAL "Grupa w kt�rej ma wystapi� projekt ${name}" FORCE)
		endif()
		
		set(tmp_projects ${SOLUTION_INSTALLER_PROJECTS})
		list(REMOVE_AT tmp_projects ${_projectIDX})
		
		set(SOLUTION_INSTALLER_PROJECTS ${tmp_projects} CACHE INTERNAL "Wszystkie projekty kt�re musza by� skonfigurowane na potrzeby instalatora" FORCE)		
	else()
		# projekt nie istnieje albo by� ju� dodany
		list(FIND SOLUTION_PROJECTS ${name} _projectIDX)
		
		if(_projectIDX GREATER -1)
			# projekt ju� dodany
			INSTALL_NOTIFY(name "Project ${name} already configured for installation. Skipping...")			
		else()
			# projekt nie istnieje
			INSTALL_NOTIFY(name "Project ${name} not defined in solution. Skipping...")
		endif()
	endif()
	
endmacro(ADD_INSTALLER_GROUP_PROJECT)

###############################################################################
# Makro ko�cz�ce blok konfigurowania instalacji
macro(END_INSTALLER)	

endmacro(END_INSTALLER)

###############################################################################
# Makro pomagaj�ce ustawia� warto�ci zmiennych ze �cie�kami plik�w i katalog�w
# gdy faktycznie istniej�
# Parametry:
#		path - bezwzgl�dna �cie�ka
#		variable - nazwa zmiennej kt�r� nale�y ustawi� je�li �cie�ka istnieje
macro(_SETUP_PATH_EXT path variable)

	string(LENGTH path _pathLength)
	
	if(_pathLength GREATER 0)
	
		if(IS_ABSOLUTE path)
			
			if(EXISTS path)
				set(${variable} "${path}")
			else()
				INSTALL_NOTIFY(path "�cie�ka ${path} nie istnieje dla zmiennej ${variable}")
			endif()
			
		else()
			INSTALL_NOTIFY(path "�cie�ka ${path} nie jest bezwzgl�dna dla zmiennej ${variable}")
		endif()
	
	else()
		INSTALL_NOTIFY(variable "Skiping empty path dla zmiennej ${variable}")
	endif()

endmacro(_SETUP_PATH_EXT)

###############################################################################
# Makro pomagaj�ce ustawia� warto�ci zmiennych ze �cie�kami plik�w i katalog�w
# na podstawie innej zmiennej je�li jest ona faktycznie zdefiniowana
# Parametry:
#		varIn - nazwa zmiennej wej�ciowej
#		variable - nazwa zmiennej kt�r� nale�y ustawi� je�li �cie�ka istnieje
macro(_SETUP_PATH varIn variable)

	if(DEFINED ${varIn})
		_SETUP_PATH_EXT(${${varIn}} ${variable})
	else()
		INSTALL_NOTIFY(varIn "Zmienna ${varIn} nie istnieje dla ustawienia �ciezki ${variable}")
	endif()

endmacro(_SETUP_PATH)

###############################################################################
# Makro pomagaj�ce ustawia� warto�ci zmiennych je�eli nie s� one puste
# Parametry:
#		value - tekst
#		variable - nazwa zmiennej kt�r� nale�y ustawi� je�li tekst nie jest pusty
macro(_SETUP_VALUE_EXT value variable)

	string(LENGTH value _valueLength)
	if(_valueLength GREATER 0)
	
		set(${variable} "${value}")		
	
	else()
	
		INSTALL_NOTIFY(variable "Skiping empty value dla zmiennej ${variable}")
		
	endif()

endmacro(_SETUP_VALUE_EXT)

###############################################################################
# Makro pomagaj�ce ustawia� warto�ci zmiennych je�eli nie s� one puste
# Parametry:
#		value - tekst
#		variable - nazwa zmiennej kt�r� nale�y ustawi� je�li tekst nie jest pusty
macro(_SETUP_VALUE varIn variable)

	if(DEFINED ${varIn})

		_SETUP_VALUE_EXT(${${varIn}} ${variable})
	
	else()
	
		INSTALL_NOTIFY(varIn "Zmienna ${varIn} nie istnieje dla zmiennej ${variable}")
		
	endif()

endmacro(_SETUP_VALUE)

###############################################################################
# Makro ko�cz�ce blok konfigurowania instalacji
macro(_GENERATE_INSTALLER)
	
	if(CONFIG_GENERATE_INSTALLER)
	
		list(LENGTH SOLUTION_INSTALLER_PROJECTS _solutionsLeft)
		
		if(_solutionsLeft GREATER 0)
			INSTALL_NOTIFY(SOLUTION_INSTALLER_PROJECTS "Projects: ${SOLUTION_INSTALLER_PROJECTS} not configured for installer! Installer migth be incomplete")
		endif()
		
		set(CPACK_PACKAGE_NAME "${SOLUTION_INSTALLER_NAME}")
		set(CPACK_PACKAGE_INSTALL_DIRECTORY "${SOLUTION_INSTALLER_NAME}")
		set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${SOLUTION_INSTALLER_NAME}")
		
		SET(CPACK_PACKAGE_VENDOR "${SOLUTION_INSTALLER_VENDOR}")		
		SET(CPACK_PACKAGE_VERSION "${SOLUTION_INSTALLER_VERSION}")
		
		set(CPACK_PACKAGE_FILE_NAME "${SOLUTION_INSTALLER_OUTPUT_FILE_NAME}")
		
		_SETUP_PATH(SOLUTION_INSTALLER_LICENSE_FILE CPACK_RESOURCE_FILE_LICENSE)
		_SETUP_PATH(SOLUTION_INSTALLER_WELCOME_FILE CPACK_RESOURCE_FILE_WELCOME)
		_SETUP_PATH(SOLUTION_INSTALLER_README_FILE CPACK_RESOURCE_FILE_README)
		_SETUP_PATH(SOLUTION_INSTALLER_DESCRIPTION_FILE CPACK_PACKAGE_DESCRIPTION_FILE)
		
		set(CPACK_COMPONENTS_ALL_SET_BY_USER 1)

		# konfigurujemy grupy, typy instalacji, przynale�no�� do grup, zale�no�ci
		
		if(WIN32)
		
			set(CPACK_MONOLITHIC_INSTALL 0)
			set(CPACK_NSIS_COMPONENT_INSTALL ON)
		
			set(CPACK_NSIS_DISPLAY_NAME "${CPACK_PACKAGE_NAME}")
			set(CPACK_NSIS_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
			set(CPACK_NSIS_COMPRESSOR lzma)
			SET(CPACK_NSIS_MODIFY_PATH ON)
		
			_SETUP_PATH(SOLUTION_INSTALLER_PRODUCT_ICON CPACK_NSIS_INSTALLED_ICON_NAME)
			_SETUP_PATH(SOLUTION_INSTALLER_PRODUCT_ICON CPACK_NSIS_MUI_ICON)
			_SETUP_PATH(SOLUTION_INSTALLER_PRODUCT_UNINSTALL_ICON CPACK_NSIS_MUI_UNIICON)
			
			_SETUP_VALUE(SOLUTION_INSTALLER_ADDITIONAL_INFO_HELP_LINK CPACK_NSIS_HELP_LINK)
			_SETUP_VALUE(SOLUTION_INSTALLER_ADDITIONAL_INFO_ABOUT_LINK CPACK_NSIS_URL_INFO_ABOUT)
			_SETUP_VALUE(SOLUTION_INSTALLER_ADDITIONAL_INFO_VENDOR_CONTACT CPACK_NSIS_CONTACT)					
	
			_SETUP_VALUE(SOLUTION_INSTALLER_FINISH_RUN_APP CPACK_NSIS_MUI_FINISHPAGE_RUN)
		
			set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" ${CMAKE_MODULE_PATH})
			set(CMAKE_MODULE_PATH "${CPACK_INSTALLER_RESOURCES}" ${CMAKE_MODULE_PATH})
		else()
			set(CPACK_BINARY_DEB ON)
			set(CPACK_BINARY_RPM OFF)
			set(CPACK_BINARY_STGZ OFF)
			set(CPACK_BINARY_TBZ2 OFF)
			set(CPACK_BINARY_TGZ OFF)
			set(CPACK_BINARY_TZ OFF)
		endif()
		
		include(CPack)
		
		# typy instalacji
		foreach(installType ${SOLUTION_INSTALLER_INSTALLATION_TYPES})
			cpack_add_install_type(${installType} DISPLAY_NAME "${SOLUTION_INSTALLER_INSTALLATION_TYPE_${installType}_DISPLAY}")
		endforeach()
		
		# grupy
		foreach(group ${SOLUTION_INSTALLER_GROUPS})
			
			if(SOLUTION_INSTALLER_GROUP_${group}_EXPANDED)
				if(SOLUTION_INSTALLER_GROUP_${group}_BOLD)		
					if(DEFINED SOLUTION_INSTALLER_GROUP_${group}_PARENT)
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" PARENT_GROUP "${SOLUTION_INSTALLER_GROUP_${name}_PARENT}" EXPANDED BOLD_TITLE)
					else()
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" EXPANDED BOLD_TITLE)
					endif()
				else()
					if(DEFINED SOLUTION_INSTALLER_GROUP_${group}_PARENT)
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" PARENT_GROUP "${SOLUTION_INSTALLER_GROUP_${name}_PARENT}" EXPANDED)
					else()
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" EXPANDED)
					endif()
				endif()
			else()
				if(SOLUTION_INSTALLER_GROUP_${group}_BOLD)		
					if(DEFINED SOLUTION_INSTALLER_GROUP_${group}_PARENT)
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" PARENT_GROUP "${SOLUTION_INSTALLER_GROUP_${name}_PARENT}" BOLD_TITLE)
					else()
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" BOLD_TITLE)
					endif()
				else()
					if(DEFINED SOLUTION_INSTALLER_GROUP_${group}_PARENT)
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}" PARENT_GROUP "${SOLUTION_INSTALLER_GROUP_${name}_PARENT}")
					else()
						cpack_add_component_group(${group} DISPLAY_NAME "${SOLUTION_INSTALLER_GROUP_${name}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_GROUP_${name}_DESCRIPTION}")
					endif()
				endif()
			endif()		
			
		endforeach()
		
		set(SOLUTION_INSTALL_COMPONENTS "")
		
		# komponenty grup
		foreach(prj ${SOLUTION_PROJECTS})
		
			# ustawiam tylko te projekty kt�re podano
			list(FIND SOLUTION_INSTALLER_PROJECTS ${prj} _prjIDX)
			if(_prjIDX EQUAL -1)

				list(APPEND SOLUTION_INSTALL_COMPONENTS PROJECT_${prj}_COMPONENT)
				
				set(COMPONENT_DEPENDENCIES "")
				
				set(APPEND_PREREQUISITES 0)
				
				foreach(dep ${PROJECT_${prj}_DEPENDENCIES})
					
					list(FIND SOLUTION_PROJECTS ${dep} _depIDX)
					
					if(_depIDX GREATER -1)
						list(FIND SOLUTION_INSTALLER_PROJECTS ${dep} _installDepIDX)
						
						if(_installDepIDX EQUAL -1)
							list(APPEND COMPONENT_DEPENDENCIES PROJECT_${dep}_COMPONENT)
						endif()
						
					else()
						set(APPEND_PREREQUISITES 1)
					endif()
					
				endforeach()
				
				if(APPEND_PREREQUISITES)
					list(APPEND COMPONENT_DEPENDENCIES prerequisites_COMPONENT)
				endif()
				
				list(REMOVE_DUPLICATES COMPONENT_DEPENDENCIES)
				
				list(LENGTH COMPONENT_DEPENDENCIES _depSize)
				
				if(_depSize GREATER 0)
				
					if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES)
						
						if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_GROUP)
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} GROUP ${SOLUTION_INSTALLER_PROJECT_${prj}_GROUP} DEPENDS ${COMPONENT_DEPENDENCIES} INSTALL_TYPES ${SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES}) 
						else()
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} DEPENDS ${COMPONENT_DEPENDENCIES} INSTALL_TYPES ${SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES}) 
						endif()
					
					else()
						
						if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_GROUP)
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} GROUP ${SOLUTION_INSTALLER_PROJECT_${prj}_GROUP} DEPENDS ${COMPONENT_DEPENDENCIES}) 
						else()
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} DEPENDS ${COMPONENT_DEPENDENCIES}) 
						endif()
						
					endif()
					
				else()
					
					if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES)
						
						if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_GROUP)
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} GROUP ${SOLUTION_INSTALLER_PROJECT_${prj}_GROUP} INSTALL_TYPES ${SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES}) 
						else()
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} INSTALL_TYPES ${SOLUTION_INSTALLER_PROJECT_${prj}_INSTALLTYPES}) 
						endif()
					
					else()
						
						if(DEFINED SOLUTION_INSTALLER_PROJECT_${prj}_GROUP)
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS} GROUP ${SOLUTION_INSTALLER_PROJECT_${prj}_GROUP}) 
						else()
							cpack_add_component(PROJECT_${prj}_COMPONENT DISPLAY_NAME "${SOLUTION_INSTALLER_PROJECT_${prj}_DISPLAY}" DESCRIPTION "${SOLUTION_INSTALLER_PROJECT_${prj}_DESCRIPTION}" ${SOLUTION_INSTALLER_PROJECT_${prj}_OPTIONS}) 
						endif()
						
					endif()
					
				endif()
			
			endif()
			
		endforeach()
		
		set(CPACK_COMPONENTS_ALL ${SOLUTION_INSTALL_COMPONENTS})
		
	endif()
	
endmacro(_GENERATE_INSTALLER)

###############################################################################
# Makro generujace instalacj� zadanego projektu
# Parametry:
#		projectName Nazwa projektu dla kt�rego generujemy instalacje
macro(_INSTALL_PROJECT projectName)

	set(PROJECT_COMPONENT "PROJECT_${projectName}_COMPONENT")

	# sprawdzam typ instalacji
	if(${SOLUTION_INSTALLATION_TYPE} STREQUAL "libraries_api")
	
		set(ARTIFACTS_DEBUG_DESTINATION "lib/${SOLUTION_LIBRARIES_PLATFORM}/debug/${projectName}")
		set(ARTIFACTS_RELEASE_DESTINATION "lib/${SOLUTION_LIBRARIES_PLATFORM}/release/${projectName}")
	
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
		
		# instalujemy nag��wki - raczej powinny byc ale zawsze sprawdzamy
		
		list(LENGTH PROJECT_${projectName}_PUBLIC_HEADERS _publicHeadersSize)
		
		if(_publicHeadersSize GREATER 0)
				
			file(TO_CMAKE_PATH "${PROJECT_${projectName}_RELATIVE_PATH}" HEADER_INSTALL_PATH)
			string(FIND "${HEADER_INSTALL_PATH}" "/" _lastIDX REVERSE)
			
			if(_lastIDX EQUAL -1)
				set(HEADER_INSTALL_PATH "${HEADER_INSTALL_PATH}/${HEADER_INSTALL_PATH}")
			elseif()
				string(LENGTH "${HEADER_INSTALL_PATH}" _length)
				math(EXPR _startIDX "${_lastIDX} + 1")
				math(EXPR _length "${_length} - ${_startIDX}")
				string(SUBSTRING "${HEADER_INSTALL_PATH}" ${startIDX} ${length} _last)
				set(HEADER_INSTALL_PATH "${HEADER_INSTALL_PATH}/${_last}")
			endif()			
		
			foreach(f ${PROJECT_${projectName}_PUBLIC_HEADERS})
				#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
				file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_HEADER_PATH}" "${f}")
				get_filename_component(_f "${_relPath}" PATH)
				
				install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
			endforeach()
			
			foreach(f ${PROJECT_${projectName}_CONFIGURABLE_PUBLIC_HEADERS})
				#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
				file(RELATIVE_PATH _relPath "${PROJECT_PUBLIC_CONFIGURATION_INCLUDES_PATH}/${CURRENT_PROJECT_NAME}" "${f}")
				get_filename_component(_f "${_relPath}" PATH)
				
				install(FILES ${f} DESTINATION "include/${HEADER_INSTALL_PATH}/${_f}" COMPONENT ${PROJECT_COMPONENT})
			endforeach()
		endif()
		
	else()
	
		# wersja release
		# tylko runtime + resources + dependencies
		
		# t�umaczenia
		if(DEFINED QM_OUTPUTS)
			install(FILES ${QM_OUTPUTS} DESTINATION "bin/resources/langs" COMPONENT ${PROJECT_COMPONENT})
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
				
			endif()
			
			message("PROJECT_DEPLOY_RESOURCES_FILES_PATH : ${PROJECT_DEPLOY_RESOURCES_FILES_PATH}")
			
			foreach(f ${DEPLOY_RESOURCES_FILES})
				# musze najpierw do sciezki aboslutnej zeby dobrze wyznacza� wzgl�dn�
				get_filename_component(_f "${f}" ABSOLUTE)
				#musze odbudowa� �cie�k� w jakiej znajdzie si� ten plik
				file(RELATIVE_PATH _relPath "${PROJECT_DEPLOY_RESOURCES_FILES_PATH}" "${_f}")
				get_filename_component(_f "${_relPath}" PATH)				
				
				install(FILES ${f} DESTINATION "bin/resources/${_f}" COMPONENT ${PROJECT_COMPONENT})
			endforeach()
			
			# TODO
			# DEPLOY_MODIFIABLE_RESOURCES_FILES musz� by� instalowane inaczej - w docelowym miejscu
			# musi by� mozliwe ich edytowanie przez u�ytkownika - to ju� s0bie instalator musi obs�u�y�
			# powinni�my chyba sami konfigurowa� plik dla NSISa z tym
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
		
		set(PROJECT_INSTALLED_DEPENDENCIES "")		
		
		# teraz instaluj� dependencies je�li jeszcze nie by�y instalowane
		foreach(dep ${PROJECT_${projectName}_DEPENDENCIES})
		
			# sprawdzam czy zale�no�� nie jest projektem - jesli jest to pomija bo itak j� b�de instalowa� (przynajmniej powinienem)

			list(FIND SOLUTION_PROJECTS ${dep} _projectIDX)
			if(_projectIDX EQUAL -1)					
				# sprawdzam czy tej zale�no�ci juz nie instalowa�em
				list(FIND SOLUTION_INSTALLED_DEPENDENCIES ${dep} _depIDX)
				if(_depIDX EQUAL -1)					
				
					list(APPEND PROJECT_INSTALLED_DEPENDENCIES ${dep})					
					
					foreach(lib ${LIBRARY_${dep}_RELEASE_DLLS})
						install(FILES ${${lib}} DESTINATION bin CONFIGURATIONS Release COMPONENT prerequsites_COMPONENT)
					endforeach()
					
					foreach(lib ${LIBRARY_${dep}_DEBUG_DLLS})
						install(FILES ${${lib}} DESTINATION bin CONFIGURATIONS Debug COMPONENT prerequsites_COMPONENT)
					endforeach()
					
					foreach(dir ${LIBRARY_${dep}_RELEASE_DIRECTORIES})
						install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Release COMPONENT prerequsites_COMPONENT)
					endforeach()
					
					foreach(dir ${LIBRARY_${dep}_DEBUG_DIRECTORIES})
						install(DIRECTORY ${${dir}} DESTINATION bin CONFIGURATIONS Debug COMPONENT prerequsites_COMPONENT)
					endforeach()
					
					#TODO - pliki wykonywalne s� nam niepotrzebne, praktycznie tylko aplikacje z QT si� pod to �api�
					
					#foreach(app ${LIBRARY_${dep}_RELEASE_EXECUTABLES})
					#	install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Release COMPONENT prerequsites_COMPONENT)
					#endforeach()
					
					#foreach(app ${LIBRARY_${dep}_DEBUG_EXECUTABLES})
					#	install(PROGRAMS ${${app}} DESTINATION bin CONFIGURATIONS Release COMPONENT prerequsites_COMPONENT)
					#endforeach()
				endif()
			endif()
			
		endforeach()
		
		list(LENGTH PROJECT_INSTALLED_DEPENDENCIES _installedDeps)
		
		if(_installedDeps GREATER 0)
			list(APPEND SOLUTION_INSTALLED_DEPENDENCIES ${PROJECT_INSTALLED_DEPENDENCIES})
		endif()
	
	endif()

endmacro(_INSTALL_PROJECT)

###############################################################################
# Makro obs�uguj�ce generowanie komunikat�w diagnostycznych dla makr instalacji
# Parametry:
#		var - nazwa zmiennej
#		msg - wiadomo��
macro(INSTALL_NOTIFY var msg)
	if (INSTALL_VERBOSE)
		message(STATUS "INSTALL>${var}>${msg}")
	endif()
endmacro(INSTALL_NOTIFY)