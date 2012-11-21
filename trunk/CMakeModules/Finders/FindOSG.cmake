# przygotowanie do szukania
FIND_INIT(OSG osg)
FIND_INCLUDE_PLATFORM_HEADERS(OSG osg)

# funkcja wykrywaj¹ce wersjê OSG
function(OSG_FIND_VERSION path suffix)    
	# inicjalizacja
	set(OSG_VERSION${suffix} "Unknown" CACHE STRING "Unknown version")
	set(OSG_VERSION${suffix}_SO "Unknown" CACHE STRING "Unknown version")
	# próba odczytania wersji z pliku
	if (EXISTS ${path})
		file(READ "${path}" _osg_Version_contents)
		string(REGEX REPLACE ".*#define [A-Z]+_MAJOR_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_major ${_osg_Version_contents})
        string(REGEX REPLACE ".*#define [A-Z]+_MINOR_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_minor ${_osg_Version_contents})
        string(REGEX REPLACE ".*#define [A-Z]+_PATCH_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_patch ${_osg_Version_contents})
		string(REGEX REPLACE ".*#define [A-Z]+_SOVERSION[ \t]+([0-9]+).*"
            "\\1" _version_so ${_osg_Version_contents})	
		if (OSG_VERSION${suffix} STREQUAL "Unknown")
			set(OSG_VERSION${suffix} "${_version_major}.${_version_minor}.${_version_patch}" CACHE STRING "The version of OSG_VERSION${suffix} which was detected" FORCE)
		endif()
		if (OSG_VERSION${suffix}_SO STREQUAL "Unknown")
			set(OSG_VERSION${suffix}_SO "${_version_so}" CACHE STRING "The version of OSG_VERSION${suffix}_SO which was detected" FORCE)
		endif()
    endif()
	# czy siê uda³o?
	if (OSG_VERSION${suffix} STREQUAL "Unknown")
		message("Unknown version of OSG_VERSION${suffix}. File ${path} could not be read. This may result in further errors.")
	endif()
	if (OSG_VERSION${suffix}_SO STREQUAL "Unknown")
		message("Unknown interface version of OSG_VERSION${suffix}_SO. File ${path} could not be read. This may result in further errors.")
	endif()
endfunction(OSG_FIND_VERSION)

# wykrycie wersji osg
OSG_FIND_VERSION("${OSG_INCLUDE_DIR}/osg/Version"  "")
OSG_FIND_VERSION("${OSG_INCLUDE_DIR}/OpenThreads/Version" _OPENTHREADS)

# OSG
FIND_SHARED(OSG_LIBCORE osg "osg${OSG_VERSION_SO}-osg")
FIND_SHARED(OSG_LIBDB osgDB "osg${OSG_VERSION_SO}-osgDB")
FIND_SHARED(OSG_LIBUTIL osgUtil "osg${OSG_VERSION_SO}-osgUtil")
FIND_SHARED(OSG_LIBGA osgGA "osg${OSG_VERSION_SO}-osgGA")
FIND_SHARED(OSG_LIBVIEWER osgViewer "osg${OSG_VERSION_SO}-osgViewer")
FIND_SHARED(OSG_LIBTEXT osgText "osg${OSG_VERSION_SO}-osgText")
FIND_SHARED(OSG_LIBWIDGET osgWidget "osg${OSG_VERSION_SO}-osgWidget")
FIND_SHARED(OSG_LIBQT osgQt "osg${OSG_VERSION_SO}-osgQt")
FIND_SHARED(OSG_MANIPULATOR osgManipulator "osg${OSG_VERSION_SO}-osgManipulator")

# OpenThreads
#FIND_SHARED(OSG_LIBOPENTHREADS OpenThreads "ot${OSG_VERSION_OPENTHREADS_SO}-OpenThreads")

# pluginy
if ( WIN32 )
	file(COPY "${OSG_LIBRARY_DIR_DEBUG}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug")
	install(DIRECTORY "${OSG_LIBRARY_DIR_DEBUG}/osgPlugins-${OSG_VERSION}" DESTINATION bin CONFIGURATIONS "Debug")
	
	file(COPY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release")
	
	install(DIRECTORY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION bin CONFIGURATIONS "Release")
else()
	file(COPY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
	
	install(DIRECTORY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION bin CONFIGURATIONS "Release")
endif()

#set(FIND_DIR_DEBUG "${FIND_DIR_DEBUG}/osgPlugins-${OSG_VERSION}")
#set(FIND_DIR_RELEASE "${FIND_DIR_RELEASE}/osgPlugins-${OSG_VERSION}")
#FIND_MODULE(OSG_PLUGIN_PNG FALSE "osgdb_png")
#FIND_MODULE(OSG_PLUGIN_GLSL FALSE "osgdb_glsl")
#FIND_MODULE(OSG_PLUGIN_FREETYPE FALSE "osgdb_freetype")
#FIND_MODULE(OSG_PLUGIN_JPEG FALSE "osgdb_jpeg")

## poza znalezieniem trzeba jeszcze ustawiæ suffix œcie¿ki docelowej
## dla pluginów
# set(FIND_MODULE_PREFIX_osgdb_png "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_pngd "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_glsl "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_glsld "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_freetype "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_freetyped "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_jpeg "osgPlugins-${OSG_VERSION}/")
# set(FIND_MODULE_PREFIX_osgdb_jpegd "osgPlugins-${OSG_VERSION}/")

# skopiowanie
FIND_FINISH(OSG)

# sprawdzenie
if (OSG_LIBCORE_FOUND AND
	OSG_LIBDB_FOUND AND
	OSG_LIBOPENTHREADS_FOUND AND
	OSG_LIBUTIL_FOUND AND
	OSG_LIBGA_FOUND AND
	OSG_LIBVIEWER_FOUND AND
	OSG_LIBTEXT_FOUND AND
	OSG_LIBWIDGET_FOUND) # AND
	#OSG_PLUGIN_PNG_FOUND)
		set(OSG_FOUND 1)
		if ( WIN32 )
			file(COPY "${OSG_LIBRARY_DIR_DEBUG}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug")
			file(COPY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release")
		else()           
			file(COPY "${OSG_LIBRARY_DIR_RELEASE}/osgPlugins-${OSG_VERSION}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
		endif()
else()
	message("Nie znaleziono którejœ z bibliotek osg (wersje ${OSG_VERSION_SO}), OpenThreads(wersje ${OSG_VERSION_OPENTHREADS_SO}) lub pluginów (wersje ${OSG_VERSION})")
endif()
