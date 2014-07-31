# przygotowanie do szukania
FIND_INIT(FFMPEG ffmpeg)

FIND_SHARED(FFMPEG_LIBAVCODEC "avcodec<-55,?>" "avcodec-55")
FIND_SHARED(FFMPEG_LIBAVDEVICE "avdevice<-55,?>" "avdevice-55")
FIND_SHARED(FFMPEG_LIBAVFILTER "avfilter<-4,?>" "avfilter-4")
FIND_SHARED(FFMPEG_LIBAVFORMAT "avformat<-55,?>" "avformat-55")
FIND_SHARED(FFMPEG_LIBAVUTIL "avutil<-52,?>" "avutil-52")
FIND_SHARED(FFMPEG_LIBSWRESAMPLE "swresample<-0,?>" "swresample-0")
FIND_SHARED(FFMPEG_LIBSWSCALE "swscale<-2,?>" "swscale-2")

if(UNIX)
	FIND_DEPENDENCIES(FFMPEG "OPENSSL;FREETYPE")
endif()

# skopiowanie
FIND_FINISH(FFMPEG)