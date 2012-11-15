# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(navlib "camera/navigation" ${MIS_INCLUDE_ROOT} ${MIS_BUILD_ROOT})

# szukanie
FIND_STATIC(navlib "navlib")

# skopiowanie
FIND_FINISH(navlib)