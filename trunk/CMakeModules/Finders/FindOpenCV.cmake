# przygotowanie do szukania
FIND_INIT(OPENCV opencv)

# szukanie
# funkcja wykrywaj¹ce wersjê BOOST
function(OPENCV_FIND_VERSION path)    
	# inicjalizacja
	set(OPENCV_VERSION "Unknown" CACHE STRING "Unknown version")
	# próba odczytania wersji z pliku
	if (EXISTS ${path})
		file(READ "${path}" _opencv_Version_contents)
		string(REGEX REPLACE ".*#define [A-Z]+_MAJOR_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_major ${_opencv_Version_contents})
        string(REGEX REPLACE ".*#define [A-Z]+_MINOR_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_minor ${_opencv_Version_contents})
        string(REGEX REPLACE ".*#define [A-Z]+_SUBMINOR_VERSION[ \t]+([0-9]+).*"
            "\\1" _version_subminor ${_opencv_Version_contents})
		if (OPENCV_VERSION STREQUAL "Unknown")
			set(OPENCV_VERSION "${_version_major}${_version_minor}${_version_subminor}" CACHE STRING "The version of OSG_VERSION${suffix} which was detected" FORCE)
		endif()
    endif()
	# czy siê uda³o?
	if (OPENCV_VERSION STREQUAL "Unknown")
		message("Unknown version of OPENCV_VERSION. File ${path} could not be read. This may result in further errors.")
	endif()
endfunction(OPENCV_FIND_VERSION)

# wykrycie wersji osg
OPENCV_FIND_VERSION("${OPENCV_INCLUDE_DIR}/opencv2/core/version.hpp")

FIND_SHARED(OPENCV_CALIB3D "<lib,?>opencv_calib3d<${OPENCV_VERSION},?>" "<lib,?>opencv_calib3d<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_CONTRIB "<lib,?>opencv_contrib<${OPENCV_VERSION},?>" "<lib,?>opencv_contrib<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_CORE "<lib,?>opencv_core<${OPENCV_VERSION},?>" "<lib,?>opencv_core<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_FEATURES2D "<lib,?>opencv_features2d<${OPENCV_VERSION},?>" "<lib,?>opencv_features2d<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_FLANN "<lib,?>opencv_flann<${OPENCV_VERSION},?>" "<lib,?>opencv_flann<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_GPU "<lib,?>opencv_gpu<${OPENCV_VERSION},?>" "<lib,?>opencv_gpu<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_HIGHGUI "<lib,?>opencv_highgui<${OPENCV_VERSION},?>" "<lib,?>opencv_highgui<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_IMGPROC "<lib,?>opencv_imgproc<${OPENCV_VERSION},?>" "<lib,?>opencv_imgproc<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_LEGACY "<lib,?>opencv_legacy<${OPENCV_VERSION},?>" "<lib,?>opencv_legacy<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_ML "<lib,?>opencv_ml<${OPENCV_VERSION},?>" "<lib,?>opencv_ml<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_OBJDETECT "<lib,?>opencv_objdetect<${OPENCV_VERSION},?>" "<lib,?>opencv_objdetect<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_TS "<lib,?>opencv_ts<${OPENCV_VERSION},?>" "<lib,?>opencv_ts<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_VIDEO "<lib,?>opencv_video<${OPENCV_VERSION},?>" "<lib,?>opencv_video<${OPENCV_VERSION},?>")
FIND_SHARED(OPENCV_NONFREE "<lib,?>opencv_nonfree<${OPENCV_VERSION},?>" "<lib,?>opencv_nonfree<${OPENCV_VERSION},?>")

#opencv_ffmpeg nie ma liba, dlatego trzeba jedynie znalezc i skopiowac w odpowiednie miejsce dllki
# mozna to przeniesc do utilsow...
	if (NOT WIN32)
		# jeden plik
		ADD_LIBRARY_SINGLE(OPENCV_FFMPEG "opencv_ffmpeg${OPENCV_VERSION}" "opencv_ffmpeg${OPENCV_VERSION}" 0)
		# captain hack
		set(OPENCV_FFMPEG_FOUND 1)
	else()
		FIND_DLL(OPENCV_FFMPEG "opencv_ffmpeg${OPENCV_VERSION}" "opencv_ffmpeg${OPENCV_VERSION}")
	endif()

# koniec
FIND_FINISH(OPENCV)


# sprawdzenie
if (OPENCV_CALIB3D_FOUND AND 
    OPENCV_CONTRIB_FOUND AND
    OPENCV_CORE_FOUND AND
    OPENCV_FEATURES2D_FOUND AND
    OPENCV_FLANN_FOUND AND
    OPENCV_GPU_FOUND AND
    OPENCV_HIGHGUI_FOUND AND
    OPENCV_IMGPROC_FOUND AND
    OPENCV_LEGACY_FOUND AND
    OPENCV_ML_FOUND AND
    OPENCV_OBJDETECT_FOUND AND 
    OPENCV_TS_FOUND AND
    OPENCV_VIDEO_FOUND AND
	OPENCV_NONFREE_FOUND)
		set(OPENCV_FOUND 1)
else()
	set(OPENCV_FOUND 0)
	message("Nie znaleziono którejœ z bibliotek OPENCV (wersje ${OPENCV_VERSION})")
endif()
