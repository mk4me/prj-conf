# przygotowanie do szukania
FIND_INIT(LIBPNG libpng)

# szukanie
FIND_SHARED(LIBPNG "libpng15<lib,?>" "libpng15<lib,?>")

# skopiowanie
FIND_FINISH(LIBPNG)

