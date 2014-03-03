###############################################################################
# Makro pomagające ustawiać wartości zmiennych ze ścieżkami plików i katalogów
# gdy faktycznie istnieją
# Parametry:
#		path - bezwzględna ścieżka
#		variable - nazwa zmiennej którą należy ustawić jeśli ścieżka istnieje
macro(_SETUP_PATH_EXT variable path)

	string(LENGTH "${path}" _pathLength)
	
	if(_pathLength GREATER 0)
	
		if(IS_ABSOLUTE "${path}")
			
			if(EXISTS "${path}")
				set(${variable} "${path}")
			else()
				INSTALLER_NOTIFY(path "Ścieżka ${path} nie istnieje dla zmiennej ${variable}")
			endif()
			
		else()
			INSTALLER_NOTIFY(path "Ścieżka ${path} nie jest bezwzględna dla zmiennej ${variable}")
		endif()
	
	else()
		INSTALLER_NOTIFY(${variable} "Skiping empty path dla zmiennej ${variable}")
	endif()

endmacro(_SETUP_PATH_EXT)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych ze ścieżkami plików i katalogów
# na podstawie innej zmiennej jeśli jest ona faktycznie zdefiniowana
# Parametry:
#		varIn - nazwa zmiennej wejściowej
#		variable - nazwa zmiennej którą należy ustawić jeśli ścieżka istnieje
macro(_SETUP_PATH variable varIn)

	if(DEFINED ${varIn})
		_SETUP_PATH_EXT(${variable} ${${varIn}})
	else()
		INSTALLER_NOTIFY(${varIn} "Zmienna ${varIn} nie istnieje dla ustawienia ściezki ${variable}")
	endif()

endmacro(_SETUP_PATH)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		value - tekst
#		description - opis dla cachowanej wartosci
macro(_APPEND_INTERNAL_CACHE_VALUE variable value description)

	_APPEND_INTERNAL_CACHE_VALUE_EXT(${variable} "${value}" "${description}" ";")

endmacro(_APPEND_INTERNAL_CACHE_VALUE)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		value - tekst
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		description - opis dla cachowanej wartosci
#		join - ciąg znakó łączących wartości
macro(_APPEND_INTERNAL_CACHE_VALUE_EXT variable value description join)

	_SETUP_CACHE_VALUE_EXT(${variable} "${${variable}}${join}${value}" "internal" "${description}")

endmacro(_APPEND_INTERNAL_CACHE_VALUE_EXT)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		value - tekst
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		description - opis dla cachowanej wartosci
macro(_SETUP_INTERNAL_CACHE_VALUE variable value description)

	_SETUP_CACHE_VALUE_EXT(${variable} "${value}" "internal" "${description}")

endmacro(_SETUP_INTERNAL_CACHE_VALUE)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		value - tekst
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		type - typ zmiennej jaką ustawiamy: filepath, path, string, bool, internal
#		[force] - czy wymusić nadpisanie wartosci w cache
macro(_SETUP_CACHE_VALUE_EXT variable value type description)

	if(${type} STREQUAL "filepath")
	
		if(${ARGC} GREATER 4)
		
			if(${ARGV4} EQUAL 0)
		
				set(${variable} "${value}" CACHE FILEPATH "${description}")
				
			else()
			
				set(${variable} "${value}" CACHE FILEPATH "${description}" FORCE)
			
			endif()
		
		else()
		
			set(${variable} "${value}" CACHE FILEPATH "${description}")
		
		endif()
	
	elseif(${type} STREQUAL "path")
	
		if(${ARGC} GREATER 4)
		
			if(${ARGV4} EQUAL 0)
		
				set(${variable} "${value}" CACHE PATH "${description}")
				
			else()
			
				set(${variable} "${value}" CACHE PATH "${description}" FORCE)
			
			endif()
		
		else()
		
			set(${variable} "${value}" CACHE PATH "${description}")
		
		endif()
	
	elseif(${type} STREQUAL "string")
	
		if(${ARGC} GREATER 4)
		
			if(${ARGV4} EQUAL 0)
		
				set(${variable} "${value}" CACHE STRING "${description}")
				
			else()
			
				set(${variable} "${value}" CACHE STRING "${description}" FORCE)
			
			endif()
		
		else()
		
			set(${variable} "${value}" CACHE STRING "${description}")
		
		endif()
	
	elseif(${type} STREQUAL "bool")
	
		if(${ARGC} GREATER 4)
		
			if(${ARGV4} EQUAL 0)
		
				set(${variable} "${value}" CACHE BOOL "${description}")
				
			else()
			
				set(${variable} "${value}" CACHE BOOL "${description}" FORCE)
			
			endif()
		
		else()
		
			set(${variable} "${value}" CACHE BOOL "${description}")
		
		endif()
	
	elseif(${type} STREQUAL "internal")
	
		set(${variable} "${value}" CACHE INTERNAL "${description}")
	
	else()
	
		INSTALLER_NOTIFY(${variable} "Unrecognized variable type dla zmiennej ${variable}: ${type}")
	
	endif()
	
endmacro(_SETUP_CACHE_VALUE_EXT)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		value - tekst
#		[parentscope] - czy tworzymy zmienna w przestrzeni powyzej aktualnej
macro(_SETUP_VALUE_EXT variable value)

	string(LENGTH "${value}" _valueLength)
	if(_valueLength GREATER 0)
	
		if(${ARGC} GREATER 2)
		
			if(${ARGV2} EQUAL 0)
			
				set(${variable} ${value})
			
			else()
			
				set(${variable} ${value} PARENT_SCOPE)
			
			endif()
		
		else()
		
			set(${variable} ${value})
		
		endif()
	
	else()
	
		INSTALLER_NOTIFY(${variable} "Skiping empty value dla zmiennej ${variable}")
		
	endif()

endmacro(_SETUP_VALUE_EXT)

###############################################################################
# Makro pomagające ustawiać wartości zmiennych jeżeli nie są one puste
# Parametry:
#		variable - nazwa zmiennej którą należy ustawić jeśli tekst nie jest pusty
#		varIn - nazwa zmiennej wejsciowej

macro(_SETUP_VALUE variable varIn)

	if(DEFINED ${varIn})

		_SETUP_VALUE_EXT(${variable} "${${varIn}}")
	
	else()
	
		INSTALLER_NOTIFY(${varIn} "Zmienna ${varIn} nie istnieje dla ustawienia zmiennej ${variable}")
		
	endif()

endmacro(_SETUP_VALUE)

###############################################################################
# Makro czyści wszystkie zmienne
#	[variables] - nazwy zmiennych do wyczyszczenia
macro(_CLEAR_VARIABLES)

	foreach(v ${ARGN})
		unset(${v})
	endforeach()

endmacro(_CLEAR_VARIABLES)