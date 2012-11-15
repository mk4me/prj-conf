# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(MISUTILS utils ${MIS_INCLUDE_ROOT}/utils ${MIS_BUILD_ROOT})

# szukanie
FIND_STATIC(MISUTILS "utils")

# skopiowanie
FIND_FINISH(MISUTILS)