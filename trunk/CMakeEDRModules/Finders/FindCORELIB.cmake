# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(CORELIB corelib ${EDR_INCLUDE_ROOT} ${EDR_BUILD_ROOT})

# szukanie
FIND_STATIC(CORELIB "corelib")

# skopiowanie
FIND_FINISH(CORELIB)
