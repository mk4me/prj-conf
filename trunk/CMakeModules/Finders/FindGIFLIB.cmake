# przygotowanie do szukania
FIND_INIT(GIFLIB giflib)

# szukanie
FIND_SHARED(GIFLIB "giflib<4,?>" "giflib<4,?>")

# skopiowanie
FIND_FINISH(GIFLIB)

