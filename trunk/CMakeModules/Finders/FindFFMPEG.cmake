# przygotowanie do szukania
FIND_INIT(FFMPEG ffmpeg)

# szukanie
if (FFMPEG_ONLY_MODULES)
	unset(FFMPEG_INCLUDE_DIR CACHE)
	FIND_MODULE(FFMPEG_LIBAVCODEC FALSE "avcodec<-54,?>")
	FIND_MODULE(FFMPEG_LIBAVFORMAT FALSE "avformat<-54,?>")
	FIND_MODULE(FFMPEG_LIBAVDEVICE FALSE "avdevice<-54,?>")
	FIND_MODULE(FFMPEG_LIBAVUTIL FALSE "avutil<-52,?>")
	FIND_MODULE(FFMPEG_LIBSWSCALE FALSE "swscale<-2,?>")	
else()	
	FIND_SHARED(FFMPEG_LIBAVCODEC "avcodec<-54,?>" "avcodec-54")
	FIND_SHARED(FFMPEG_LIBAVFORMAT "avformat<-54,?>" "avformat-54")
	FIND_SHARED(FFMPEG_LIBAVDEVICE "avdevice<-53,?>" "avdevice-54")
	FIND_SHARED(FFMPEG_LIBAVUTIL "avutil<-52,?>" "avutil-52")
	FIND_SHARED(FFMPEG_LIBSWSCALE "swscale<-2,?>" "swscale-2")
endif()

# skopiowanie
FIND_FINISH(FFMPEG)

# sprawdzenie
if (LIBRARY_FFMPEG_LIBAVCODEC_FOUND AND
	LIBRARY_FFMPEG_LIBAVFORMAT_FOUND AND
	LIBRARY_FFMPEG_LIBAVDEVICE_FOUND AND
	LIBRARY_FFMPEG_LIBAVUTIL_FOUND AND
	LIBRARY_FFMPEG_LIBSWSCALE_FOUND)
	set(LIBRARY_FFMPEG_FOUND 1)
endif()

if(FFMPEG_FOUND AND UNIX)
	FIND_DEPENDENCIES(CURL LIBRARY_FFMPEG_FOUND "OPENSSL;FREETYPE")
endif()