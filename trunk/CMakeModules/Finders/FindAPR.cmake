FIND_INIT(APR apr)

# szukanie
FIND_SHARED(APR "libapr<-2,?>" "libapr<-2,?>")

# skopiowanie
FIND_FINISH(APR)

if(WIN32)
	message(WARNING "Library dedicated for linux platform. Are you shure you need it for windows?")
endif()
