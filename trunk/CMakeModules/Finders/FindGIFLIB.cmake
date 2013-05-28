# przygotowanie do szukania
FIND_INIT(GIFLIB giflib)

# szukanie
if(WIN32)
	FIND_SHARED(GIFLIB "giflib<4,?>" "giflib<4,?>")
elseif(UNIX)
	FIND_SHARED(GIFLIB "libgif" "libgif")

# skopiowanie
FIND_FINISH(GIFLIB)

